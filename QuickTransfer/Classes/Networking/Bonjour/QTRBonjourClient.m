//
//  QTRBonjourClient.m
//  QuickTransfer
//
//  Created by Harshad on 18/02/14.
//  Copyright (c) 2014 Laughing Buddha Software. All rights reserved.
//

#import "QTRBonjourClient.h"
#import "DTBonjourDataConnection.h"
#import "QTRConstants.h"
#import "QTRUser.h"
#import "QTRMessage.h"
#import "QTRFile.h"
#import "DTBonjourDataChunk.h"
#import "QTRMultipartTransfer.h"
#import "QTRMultipartWriter.h"

@interface QTRBonjourClient () <DTBonjourDataConnectionDelegate, NSNetServiceBrowserDelegate, NSNetServiceDelegate> {
    dispatch_queue_t _fileWritingQueue;
}

- (QTRUser *)userForConnection:(DTBonjourDataConnection *)connection;
- (DTBonjourDataConnection *)connectionForUser:(QTRUser *)user;

@property (strong) NSNetServiceBrowser *netServicesBrowser;
@property (strong) NSMapTable *discoveredServices;
@property (strong) NSMutableArray *foundServices;
@property (strong) QTRUser *localUser;
@property (strong) NSMapTable *dataChunksToMultipartTransfers;
@property (strong) NSMutableDictionary *receivedFileParts;
@property (strong) NSMutableArray *pendingTransfers;

@end

@implementation QTRBonjourClient

#pragma mark - Initialisation

- (instancetype)initWithDelegate:(id<QTRBonjourClientDelegate>)delegate {

    self = [super init];
    if (self != nil) {
        [self setDelegate:delegate];
        _localUser = [delegate localUser];
        _discoveredServices = [NSMapTable strongToStrongObjectsMapTable];
        _foundServices = [NSMutableArray new];
        _dataChunksToMultipartTransfers = [NSMapTable strongToStrongObjectsMapTable];
        _receivedFileParts = [NSMutableDictionary new];
        _pendingTransfers = [NSMutableArray new];
        _fileWritingQueue = dispatch_queue_create("com.lbs.fileWritingQueue", DISPATCH_QUEUE_SERIAL);
    }

    return self;
}

#pragma mark - Public methods

- (void)start {

    if (self.netServicesBrowser == nil) {
        self.netServicesBrowser = [[NSNetServiceBrowser alloc] init];
        [self.netServicesBrowser setDelegate:self];
        [self.netServicesBrowser searchForServicesOfType:QTRBonjourServiceType inDomain:@""];
    }
}

- (void)stop {
    [self.netServicesBrowser setDelegate:nil];
    [self.netServicesBrowser stop];

    [self.foundServices removeAllObjects];

    NSEnumerator *enumerator = [self.discoveredServices objectEnumerator];
    DTBonjourDataConnection *connection = nil;
    while (connection = [enumerator nextObject]) {
        [connection setDelegate:nil];
        [connection close];
    }

    [self.dataChunksToMultipartTransfers removeAllObjects];
    [self.pendingTransfers removeAllObjects];
    [self.receivedFileParts removeAllObjects];
    [self.foundServices removeAllObjects];
    [self setNetServicesBrowser:nil];
    [self.discoveredServices removeAllObjects];

}

- (void)sendFile:(QTRFile *)file toUser:(QTRUser *)user {
    __weak typeof(self) wSelf = self;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        if (wSelf != nil) {
            typeof(self) sSelf = wSelf;
            QTRMessage *message = [QTRMessage messageWithUser:sSelf->_localUser file:file];
            [message setType:QTRMessageTypeFileTransfer];

            dispatch_async(dispatch_get_main_queue(), ^{
                DTBonjourDataChunk *chunk = nil;
                [[sSelf connectionForUser:user] sendObject:message error:nil dataChunk:&chunk];
                if ([sSelf.transferDelegate respondsToSelector:@selector(addTransferForUser:file:chunk:)]) {
                    [sSelf.transferDelegate addTransferForUser:user file:file chunk:chunk];
                }

            });

        }
    });
}

- (void)sendFileAtURL:(NSURL *)fileURL toUser:(QTRUser *)user {
    NSString *fileName = [fileURL lastPathComponent];
    QTRFile *file = [[QTRFile alloc] initWithName:fileName type:@".." data:nil];
    [file setUrl:fileURL];
    [file setIdentifier:[[self class] identifierForFile:file]];
    [self.pendingTransfers addObject:file];

    QTRMessage *confirmationMessage = [QTRMessage messageWithUser:_localUser file:file];
    [confirmationMessage setType:QTRMessageTypeConfirmFileTransfer];

    DTBonjourDataConnection *connectionForUser = [self connectionForUser:user];
    [connectionForUser sendObject:confirmationMessage error:nil dataChunk:nil];
}

- (void)acceptFile:(QTRFile *)file accept:(BOOL)shouldAccept fromUser:(QTRUser *)user {
    QTRMessageType messageType = QTRMessageTypeRejectFileTransfer;
    if (shouldAccept) {
        messageType = QTRMessageTypeAcceptFileTransfer;
    }

    QTRMessage *message = [QTRMessage messageWithUser:_localUser file:file];
    [message setType:messageType];

    [[self connectionForUser:user] sendObject:message error:nil dataChunk:nil];
}

- (void)sendText:(NSString *)text toUser:(QTRUser *)user {
    DTBonjourDataConnection *connection = [self connectionForUser:user];
    if (connection != nil) {
        QTRMessage *message = [QTRMessage messageWithUser:_localUser text:text];
        [connection sendObject:message error:nil dataChunk:nil];
    }
}

#pragma mark - Private methods

- (QTRUser *)userForConnection:(DTBonjourDataConnection *)connection {
    QTRUser *user = nil;
    NSEnumerator *enumerator = [self.discoveredServices keyEnumerator];
    id key = nil;
    while (key = [enumerator nextObject]) {
        if ([[self.discoveredServices objectForKey:key] isEqual:connection]) {
            user = key;
            break;
        }
    }

    return user;
}

- (DTBonjourDataConnection *)connectionForUser:(QTRUser *)user {
    DTBonjourDataConnection *connection = [self.discoveredServices objectForKey:user];
    if (connection == nil) {
        NSEnumerator *enumerator = [self.discoveredServices keyEnumerator];
        QTRUser *theUser = nil;
        while (theUser = [enumerator nextObject]) {
            if ([user isEqual:theUser]) {
                connection = [self.discoveredServices objectForKey:theUser];
                break;
            }
        }
    }
    return connection;
}

- (void)sendFileWithIdentifier:(NSString *)fileIdentifier toUser:(QTRUser *)user {
    QTRFile *theFile = nil;
    for (QTRFile *aFile in self.pendingTransfers) {
        if ([aFile.identifier isEqualToString:fileIdentifier]) {
            theFile = aFile;
            break;
        }
    }

    if (theFile.url != nil) {
        NSURL *fileURL = theFile.url;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:[fileURL path] error:nil];
        if (fileAttributes != nil) {
            NSNumber *fileSizeNumber = fileAttributes[NSFileSize];
            long long totalBytes = [fileSizeNumber longLongValue];

            __weak typeof(self) wSelf = self;

            if (totalBytes <= QTRMultipartTransferMaximumPartSize) {

                dispatch_async(dispatch_get_global_queue(0, 0), ^{

                    if (wSelf != nil) {
                        typeof(self) sSelf = wSelf;
                        NSData *fileData = [NSData dataWithContentsOfFile:[fileURL path]];
                        NSString *fileName = [[fileURL path] lastPathComponent];
                        QTRFile *file = [[QTRFile alloc] initWithName:fileName type:@"foo" data:fileData];
                        [file setUrl:fileURL];
                        [file setIdentifier:theFile.identifier];

                        [sSelf sendFile:file toUser:user];
                    }

                });
            } else {

                QTRMultipartTransfer *transfer = [[QTRMultipartTransfer alloc] initWithFileURL:fileURL user:user fileIdentifier:theFile.identifier];

                [transfer readNextPartForTransmission:^(QTRFile *file, BOOL isLastPart) {
                    if (wSelf != nil) {

                        typeof(self) sSelf = wSelf;

                        QTRMessage *message = [QTRMessage messageWithUser:sSelf->_localUser file:file];
                        [message setType:QTRMessageTypeFileTransfer];

                        dispatch_async(dispatch_get_main_queue(), ^{
                            DTBonjourDataChunk *chunk = nil;
                            [[sSelf connectionForUser:user] sendObject:message error:nil dataChunk:&chunk];
                            [sSelf.dataChunksToMultipartTransfers setObject:transfer forKey:chunk];
                            if ([sSelf.transferDelegate respondsToSelector:@selector(addTransferForUser:file:chunk:)]) {
                                [sSelf.transferDelegate addTransferForUser:user file:file chunk:chunk];
                            }
                        });
                    }
                }];
                
            }
        }

        [self.pendingTransfers removeObject:theFile];
    }


}

+ (NSString *)identifierForFile:(QTRFile *)file {
    return [NSString stringWithFormat:@"%@-%f", file.name, [[NSDate date] timeIntervalSince1970]];
}

#pragma mark - NSNetServiceBrowserDelegate methods

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing {
    [self.foundServices addObject:aNetService];
    [aNetService setDelegate:self];
    [aNetService startMonitoring];

    if (!moreComing) {
        double delayInSeconds = 20.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [aNetServiceBrowser stop];
        });
    }
}

#pragma mark - NSNetServiceDelegate methods

- (void)netService:(NSNetService *)sender didUpdateTXTRecordData:(NSData *)data {

    NSDictionary *txtDictionary = [NSNetService dictionaryFromTXTRecordData:data];
    if (txtDictionary != nil) {
        QTRUser *theUser = [[QTRUser alloc] initWithDictionary:txtDictionary];

        if (![_localUser isEqual:theUser] && [self.delegate client:self shouldConnectToUser:theUser]) {
            DTBonjourDataConnection *connection = [[DTBonjourDataConnection alloc] initWithService:sender];
            [connection setDelegate:self];
            [connection open];
            [self.discoveredServices setObject:connection forKey:theUser];
            
        } else {
            [self.foundServices removeObject:sender];
        }
    }

    [sender stopMonitoring];
}

- (void)netService:(NSNetService *)sender didAcceptConnectionWithInputStream:(NSInputStream *)inputStream outputStream:(NSOutputStream *)outputStream {
    // Do not remove this.
}

#pragma mark - DTBonjourDataConnectionDelegate methods

- (void)connectionDidOpen:(DTBonjourDataConnection *)connection {

    QTRMessage *userInfoMessage = [QTRMessage messageWithUser:_localUser file:nil];
    [userInfoMessage setType:QTRMessageTypeUserInfo];
    [connection sendObject:userInfoMessage error:nil dataChunk:nil];

    if ([self.delegate respondsToSelector:@selector(client:didConnectToServerForUser:)]) {
        QTRUser *user = [self userForConnection:connection];
        [self.delegate client:self didConnectToServerForUser:user];
    }

}

- (void)connectionDidClose:(DTBonjourDataConnection *)connection {

    QTRUser *user = [self userForConnection:connection];
    if ([self.delegate respondsToSelector:@selector(client:didDisconnectFromServerForUser:)]) {
        [self.delegate client:self didDisconnectFromServerForUser:user];
    }
    [self.transferDelegate failAllTransfersForUser:user];
    [self.discoveredServices removeObjectForKey:user];
}

- (void)connection:(DTBonjourDataConnection *)connection didReceiveObject:(id)object {
    __weak typeof(self) wSelf = self;

    dispatch_async(dispatch_get_global_queue(0, 0), ^{

        if (wSelf != nil) {
            typeof(self) sSelf = wSelf;
            if ([object isKindOfClass:[QTRMessage class]]) {
                QTRMessage *theMessage = (QTRMessage *)object;
                QTRUser *user = theMessage.user;

                dispatch_async(dispatch_get_main_queue(), ^{

                    switch (theMessage.type) {

                        case QTRMessageTypeConfirmFileTransfer: {

                            if ([sSelf.delegate respondsToSelector:@selector(client:didDetectIncomingFile:fromUser:)]) {
                                [sSelf.delegate client:sSelf didDetectIncomingFile:theMessage.file fromUser:user];
                            }

                            break;
                        }


                        case QTRMessageTypeRejectFileTransfer: {
                            QTRFile *pendingFile = nil;
                            for (QTRFile *aFile in sSelf.pendingTransfers) {
                                if ([aFile.identifier isEqualToString:theMessage.file.identifier]) {
                                    pendingFile = aFile;
                                    break;
                                }
                            }
                            if ([sSelf.delegate respondsToSelector:@selector(user:didRejectFile:)]) {
                                [sSelf.delegate user:user didRejectFile:theMessage.file];
                            }

                            [sSelf.pendingTransfers removeObject:pendingFile];

                            break;
                        }

                        case QTRMessageTypeAcceptFileTransfer: {
                            if ([sSelf.delegate respondsToSelector:@selector(client:didBeginSendingFile:toUser:)]) {
                                [sSelf.delegate client:sSelf didBeginSendingFile:theMessage.file toUser:user];
                            }

                            [sSelf sendFileWithIdentifier:theMessage.file.identifier toUser:user];

                            break;
                        }

                        case QTRMessageTypeFileTransfer: {

                            if (theMessage.file.totalParts > 1) {
                                QTRMultipartWriter *writer = sSelf.receivedFileParts[theMessage.file.identifier];
                                if (writer != nil) {
                                    [writer writeFilePart:theMessage.file queue:sSelf->_fileWritingQueue completion:^{
                                        if ([sSelf.transferDelegate respondsToSelector:@selector(updateTransferForFile:)]) {
                                            dispatch_async(dispatch_get_main_queue(), ^{
                                                [sSelf.transferDelegate updateTransferForFile:theMessage.file];
                                            });
                                        }
                                        dispatch_async(dispatch_get_main_queue(), ^{

                                            if (theMessage.file.partIndex == (theMessage.file.totalParts - 1)) {
                                                [writer closeFile];
                                                if ([sSelf.delegate respondsToSelector:@selector(client:didSaveReceivedFileAtURL:fromUser:)]) {
                                                    [sSelf.delegate client:sSelf didSaveReceivedFileAtURL:writer.saveURL fromUser:writer.user];
                                                }

                                                [sSelf.receivedFileParts removeObjectForKey:theMessage.file.identifier];
                                            }
                                        });

                                    }];
                                } else {
                                    writer = [[QTRMultipartWriter alloc] initWithFilePart:theMessage.file sender:user saveURL:[sSelf.delegate saveURLForFile:theMessage.file]];
                                    sSelf.receivedFileParts[theMessage.file.identifier] = writer;
                                    if ([sSelf.transferDelegate respondsToSelector:@selector(addTransferFromUser:file:)]) {
                                        [theMessage.file setUrl:writer.saveURL];
                                        [sSelf.transferDelegate addTransferFromUser:theMessage.user file:theMessage.file];
                                    }
                                }
                            } else {
                                if ([sSelf.transferDelegate respondsToSelector:@selector(addTransferFromUser:file:)]) {
                                    NSURL *fileURL = [sSelf.delegate saveURLForFile:theMessage.file];
                                    [theMessage.file setUrl:fileURL];
                                    [sSelf.transferDelegate addTransferFromUser:theMessage.user file:theMessage.file];
                                }
                                if ([sSelf.delegate respondsToSelector:@selector(client:didReceiveFile:fromUser:)]) {
                                    [sSelf.delegate client:sSelf didReceiveFile:theMessage.file fromUser:user];
                                }
                            }
                            
                            break;
                        }

                        case QTRMessageTypeText: {
                            if ([sSelf.delegate respondsToSelector:@selector(client:didReiveTextMessage:fromUser:)]) {
                                [sSelf.delegate client:sSelf didReiveTextMessage:theMessage.text fromUser:user];
                            }
                            break;
                        }

                        default:
                            break;
                    }
                    
                });

            }
        }
        
    });

}

- (void)connection:(DTBonjourDataConnection *)connection didSendBytes:(NSUInteger)bytesSent ofChunk:(DTBonjourDataChunk *)chunk {
    if ([self.transferDelegate respondsToSelector:@selector(updateTransferForChunk:)]) {
        [self.transferDelegate updateTransferForChunk:chunk];
    }
}

- (void)connection:(DTBonjourDataConnection *)connection didFinishSendingChunk:(DTBonjourDataChunk *)chunk {
    QTRMultipartTransfer *transfer = [self.dataChunksToMultipartTransfers objectForKey:chunk];
    if (transfer != nil) {
        __weak typeof(self) wSelf = self;
        [transfer readNextPartForTransmission:^(QTRFile *file, BOOL isLastPart) {
            if (wSelf != nil) {
                typeof(self) sSelf = wSelf;

                QTRMessage *message = [QTRMessage messageWithUser:sSelf->_localUser file:file];
                [message setType:QTRMessageTypeFileTransfer];

                dispatch_async(dispatch_get_main_queue(), ^{
                    DTBonjourDataChunk *dataChunk = nil;
                    [[sSelf connectionForUser:transfer.user] sendObject:message error:nil dataChunk:&dataChunk];
                    [sSelf.transferDelegate replaceChunk:chunk withChunk:dataChunk];
                    [sSelf.dataChunksToMultipartTransfers removeObjectForKey:chunk];

                    if (!isLastPart) {
                        [sSelf.dataChunksToMultipartTransfers setObject:transfer forKey:dataChunk];
                    }
                });
            }
        }];
    }
}


@end
