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

@interface QTRBonjourServer () {

}

@property (strong) NSMapTable *mappedConnections;
@property (strong) QTRUser *localUser;
@property (strong) NSMutableDictionary *receivedFileParts;
@property (strong) NSMapTable *dataChunksToMultipartTransfers;

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
    }

    return self;
}

- (void)sendFile:(QTRFile *)file toUser:(QTRUser *)user {
    __weak typeof(self) wSelf = self;

    dispatch_async(dispatch_get_main_queue(), ^{
        if (wSelf != nil) {
            typeof(self) sSelf = wSelf;
            DTBonjourDataConnection *connection = [sSelf connectionForUser:user];
            if (connection != nil) {
                QTRMessage *message = [QTRMessage messageWithUser:sSelf->_localUser file:file];
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

                    [sSelf sendFile:file toUser:user];
                }

            });
        } else {

            QTRMultipartTransfer *transfer = [[QTRMultipartTransfer alloc] initWithFileURL:fileURL user:user];

            [transfer readNextPartForTransmission:^(QTRFile *file, BOOL isLastPart) {
                if (wSelf != nil) {

                    typeof(self) sSelf = wSelf;

                    QTRMessage *message = [QTRMessage messageWithUser:sSelf->_localUser file:file];
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
}

- (void)stop {
    [_mappedConnections removeAllObjects];
    
    [super stop];
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

                    if (user.name != nil && user.identifier != nil) {
                        if (theMessage.file == nil) {
                            if ([sSelf.fileDelegate respondsToSelector:@selector(server:didConnectToUser:)]) {
                                [sSelf.fileDelegate server:sSelf didConnectToUser:user];
                            }
                        } else {

                            if (theMessage.file.totalParts > 1) {
                                QTRMultipartWriter *writer = sSelf.receivedFileParts[theMessage.file.multipartID];
                                if (writer != nil) {
                                    [writer writeFilePart:theMessage.file completion:^{
                                        if (theMessage.file.partIndex == (theMessage.file.totalParts - 1)) {
                                            [writer closeFile];
                                            if ([self.fileDelegate respondsToSelector:@selector(server:didSaveReceivedFileAtURL:fromUser:)]) {
                                                [self.fileDelegate server:self didSaveReceivedFileAtURL:writer.saveURL fromUser:writer.user];
                                            }
                                            [sSelf.receivedFileParts removeObjectForKey:theMessage.file.multipartID];
                                        }
                                    }];
                                } else {
                                    writer = [[QTRMultipartWriter alloc] initWithFilePart:theMessage.file sender:user saveURL:[sSelf.fileDelegate saveURLForFile:theMessage.file]];
                                    sSelf.receivedFileParts[theMessage.file.multipartID] = writer;
                                }
                            } else {
                                if ([sSelf.fileDelegate respondsToSelector:@selector(server:didReceiveFile:fromUser:)]) {
                                    [sSelf.fileDelegate server:sSelf didReceiveFile:theMessage.file fromUser:user];
                                }
                            }
                        }
                    }
                });
                
            }
        }

    });
}

- (void)connectionDidClose:(DTBonjourDataConnection *)connection {

    if ([self.fileDelegate respondsToSelector:@selector(server:didDisconnectUser:)]) {
        [self.fileDelegate server:self didDisconnectUser:[self.mappedConnections objectForKey:connection]];
    }

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
