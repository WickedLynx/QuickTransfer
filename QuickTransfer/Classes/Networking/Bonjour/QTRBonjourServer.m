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

@interface QTRBonjourServer () {

}

@property (strong) NSMapTable *mappedConnections;
@property (strong) QTRUser *localUser;
@property (strong) NSMutableDictionary *receivedFileParts;

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

                            if (theMessage.file.totalParts > 0) {
                                QTRMultipartWriter *writer = sSelf.receivedFileParts[theMessage.file.multipartID];
                                if (writer != nil) {
                                    [writer writeFilePart:theMessage.file completion:^{
                                        if (theMessage.file.partIndex == (theMessage.file.totalParts - 1)) {
                                            [writer closeFile];
                                            NSLog(@"finished writing file");
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
    if ([self.transferDelegate respondsToSelector:@selector(updateTransferForChunk:)]) {
        [self.transferDelegate updateTransferForChunk:chunk];
    }
}




@end
