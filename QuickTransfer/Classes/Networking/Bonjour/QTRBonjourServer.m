//
//  QTRBonjourServer.m
//  QuickTransfer
//
//  Created by Harshad on 18/02/14.
//  Copyright (c) 2014 Laughing Buddha Software. All rights reserved.
//

#import "QTRBonjourServer.h"
#import "QTRConstants.h"
#import "QTRMessage.h"
#import "QTRUser.h"
#import "QTRFile.h"
#import "QTRTransfersController.h"
#import "DTBonjourDataChunk.h"
#import "QTRMultipartWriter.h"
#import "QTRMultipartTransfer.h"

@interface QTRBonjourServer ()

@property (strong) NSMapTable *mappedConnections;
@property (strong) QTRUser *localUser;
@property (strong) NSMutableDictionary *receivedFileParts;
@property (strong) NSMapTable *dataChunksToMultipartTransfers;
@property (strong) NSMutableArray *pendingTransfers;

- (DTBonjourDataConnection *)connectionForUser:(QTRUser *)user;

@end

@implementation QTRBonjourServer

@synthesize mappedConnections = _mappedConnections;
@synthesize localUser = _localUser;

- (instancetype)initWithFileDelegate:(id<QTRBonjourServerDelegate>)fileDelegate {

    self = [super initWithBonjourType:QTRBonjourServiceType];

    if (self != nil) {
        [self setFileDelegate:fileDelegate];

        _localUser = [_fileDelegate localUser];
        
        self.TXTRecord = @{QTRBonjourTXTRecordIdentifierKey : [_localUser.identifier dataUsingEncoding:NSUTF8StringEncoding], QTRBonjourTXTRecordNameKey : [_localUser.name dataUsingEncoding:NSUTF8StringEncoding], QTRBonjourTXTRecordPlatformKey : _localUser.platform};

        _mappedConnections = [NSMapTable weakToStrongObjectsMapTable];
        _receivedFileParts = [NSMutableDictionary new];
        _dataChunksToMultipartTransfers = [NSMapTable strongToStrongObjectsMapTable];
        _pendingTransfers = [NSMutableArray new];
    }

    return self;
}

#pragma mark - Public methods

- (void)sendFile:(QTRFile *)file toUser:(QTRUser *)user {
    __weak typeof(self) wSelf = self;

    dispatch_async(dispatch_get_main_queue(), ^{
        if (wSelf != nil) {
            typeof(self) sSelf = wSelf;
            DTBonjourDataConnection *connection = [sSelf connectionForUser:user];
            if (connection != nil) {
                QTRMessage *message = [QTRMessage messageWithUser:sSelf->_localUser file:file];
                [message setType:QTRMessageTypeFileTransfer];
                dispatch_async(dispatch_get_main_queue(), ^{
                    DTBonjourDataChunk *dataChunk = nil;
                    [connection sendObject:[message JSONData] error:nil dataChunk:&dataChunk];
                    if ([sSelf.transferDelegate respondsToSelector:@selector(addTransferForUser:file:chunk:)]) {
                        [sSelf.transferDelegate addTransferForUser:user file:file chunk:dataChunk];
                    }
                });

            }
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
    [connectionForUser sendObject:[confirmationMessage JSONData] error:nil dataChunk:nil];
}

- (void)stop {
    [self.mappedConnections removeAllObjects];
    [self.receivedFileParts removeAllObjects];
    [self.dataChunksToMultipartTransfers removeAllObjects];
    [self.pendingTransfers removeAllObjects];
    [self setFileDelegate:nil];
    [self setTransferDelegate:nil];
    
    [super stop];
}

- (void)acceptFile:(QTRFile *)file accept:(BOOL)shouldAccept fromUser:(QTRUser *)user {
    QTRMessageType messageType = QTRMessageTypeRejectFileTransfer;
    if (shouldAccept) {
        messageType = QTRMessageTypeAcceptFileTransfer;
    }

    QTRMessage *message = [QTRMessage messageWithUser:_localUser file:file];
    [message setType:messageType];

    [[self connectionForUser:user] sendObject:[message JSONData] error:nil dataChunk:nil];
}

#pragma mark - Private methods

- (DTBonjourDataConnection *)connectionForUser:(QTRUser *)user {
    DTBonjourDataConnection *connection = nil;

    NSEnumerator *enumerator = [_mappedConnections keyEnumerator];
    id key = nil;
    while (key = [enumerator nextObject]) {
        if ([[_mappedConnections objectForKey:key] isEqual:user]) {
            connection = key;
            break;
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
                        NSData *jsonData = [message JSONData];

                        dispatch_async(dispatch_get_main_queue(), ^{
                            DTBonjourDataChunk *chunk = nil;
                            [[sSelf connectionForUser:user] sendObject:jsonData error:nil dataChunk:&chunk];
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

#pragma mark - DTBonjourDataConnectionDelegate methods

- (void)connection:(DTBonjourDataConnection *)connection didReceiveObject:(id)object {

    [super connection:connection didReceiveObject:object];

    __weak typeof(self) wSelf = self;

    dispatch_async(dispatch_get_global_queue(0, 0), ^{

        if (wSelf != nil) {
            typeof(self) sSelf = wSelf;
            if ([object isKindOfClass:[NSData class]]) {
                QTRMessage *theMessage = [QTRMessage messageWithJSONData:object];
                QTRUser *user = theMessage.user;

                dispatch_async(dispatch_get_main_queue(), ^{
                    [sSelf.mappedConnections setObject:user forKey:connection];

                    switch (theMessage.type) {
                        case QTRMessageTypeUserInfo: {
                            if ([sSelf.fileDelegate respondsToSelector:@selector(server:didConnectToUser:)]) {
                                [sSelf.fileDelegate server:sSelf didConnectToUser:user];
                            }

                            break;
                        }

                        case QTRMessageTypeConfirmFileTransfer: {

                            if ([sSelf.fileDelegate respondsToSelector:@selector(server:didDetectIncomingFile:fromUser:)]) {
                                [sSelf.fileDelegate server:sSelf didDetectIncomingFile:theMessage.file fromUser:user];
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
                            if ([sSelf.fileDelegate respondsToSelector:@selector(user:didRejectFile:)]) {
                                [sSelf.fileDelegate user:user didRejectFile:theMessage.file];
                            }

                            [sSelf.pendingTransfers removeObject:pendingFile];

                            break;
                        }

                        case QTRMessageTypeAcceptFileTransfer: {
                            if ([sSelf.fileDelegate respondsToSelector:@selector(server:didBeginSendingFile:toUser:)]) {
                                [sSelf.fileDelegate server:sSelf didBeginSendingFile:theMessage.file toUser:user];
                            }

                            [sSelf sendFileWithIdentifier:theMessage.file.identifier toUser:user];

                            break;
                        }

                        case QTRMessageTypeFileTransfer: {

                            if (theMessage.file.totalParts > 1) {
                                QTRMultipartWriter *writer = sSelf.receivedFileParts[theMessage.file.identifier];
                                if (writer != nil) {
                                    [writer writeFilePart:theMessage.file completion:^{
                                        if (theMessage.file.partIndex == (theMessage.file.totalParts - 1)) {
                                            [writer closeFile];
                                            if ([sSelf.fileDelegate respondsToSelector:@selector(server:didSaveReceivedFileAtURL:fromUser:)]) {
                                                [sSelf.fileDelegate server:sSelf didSaveReceivedFileAtURL:writer.saveURL fromUser:writer.user];
                                            }
                                            [sSelf.receivedFileParts removeObjectForKey:theMessage.file.identifier];
                                        }
                                    }];
                                } else {
                                    writer = [[QTRMultipartWriter alloc] initWithFilePart:theMessage.file sender:user saveURL:[sSelf.fileDelegate saveURLForFile:theMessage.file]];
                                    sSelf.receivedFileParts[theMessage.file.identifier] = writer;
                                }
                            } else {
                                if ([sSelf.fileDelegate respondsToSelector:@selector(server:didReceiveFile:fromUser:)]) {
                                    [sSelf.fileDelegate server:sSelf didReceiveFile:theMessage.file fromUser:user];
                                }
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

- (void)connectionDidClose:(DTBonjourDataConnection *)connection {

    QTRUser *user = [self.mappedConnections objectForKey:connection];
    if ([self.fileDelegate respondsToSelector:@selector(server:didDisconnectUser:)]) {
        [self.fileDelegate server:self didDisconnectUser:user];
    }

    [self.transferDelegate failAllTransfersForUser:user];
    
    [self.mappedConnections removeObjectForKey:connection];

    [super connectionDidClose:connection];
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
                NSData *jsonData = [message JSONData];

                dispatch_async(dispatch_get_main_queue(), ^{
                    DTBonjourDataChunk *dataChunk = nil;
                    [[sSelf connectionForUser:transfer.user] sendObject:jsonData error:nil dataChunk:&dataChunk];
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
