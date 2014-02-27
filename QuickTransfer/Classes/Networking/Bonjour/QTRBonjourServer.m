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

@interface QTRBonjourServer () {

}

@property (strong) NSMapTable *mappedConnections;
@property (strong) QTRUser *localUser;

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
    }

    return self;
}

- (void)sendFile:(QTRFile *)file toUser:(QTRUser *)user {
    DTBonjourDataConnection *connection = [self connectionForUser:user];
    if (connection != nil) {
        QTRMessage *message = [QTRMessage messageWithUser:_localUser file:file];
        [connection sendObject:[message JSONData] error:nil];
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

    if ([object isKindOfClass:[NSData class]]) {
        QTRMessage *theMessage = [QTRMessage messageWithJSONData:object];
        QTRUser *user = theMessage.user;
        [self.mappedConnections setObject:user forKey:connection];

        if (user.name != nil && user.identifier != nil) {
            if (theMessage.file == nil) {
                if ([self.fileDelegate respondsToSelector:@selector(server:didConnectToUser:)]) {
                    [self.fileDelegate server:self didConnectToUser:user];
                }
            } else {
                if ([self.fileDelegate respondsToSelector:@selector(server:didReceiveFile:fromUser:)]) {
                    [self.fileDelegate server:self didReceiveFile:theMessage.file fromUser:user];
                }
            }
        }
    }
}

- (void)connectionDidClose:(DTBonjourDataConnection *)connection {

    if ([self.fileDelegate respondsToSelector:@selector(server:didDisconnectUser:)]) {
        [self.fileDelegate server:self didDisconnectUser:[self.mappedConnections objectForKey:connection]];
    }

    [self.mappedConnections removeObjectForKey:connection];

    [super connectionDidClose:connection];
}

- (void)connection:(DTBonjourDataConnection *)connection willStartSendingChunk:(DTBonjourDataChunk *)chunk {
    
}





@end
