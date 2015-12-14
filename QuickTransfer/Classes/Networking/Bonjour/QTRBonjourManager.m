//
//  QTRBonjourManager.m
//  QuickTransfer
//
//  Created by Harshad on 14/12/15.
//  Copyright © 2015 Laughing Buddha Software. All rights reserved.
//

#import "QTRBonjourManager.h"
#import "QTRBonjourServer.h"
#import "QTRBonjourClient.h"
#import "QTRUser.h"
#import "QTRConstants.h"
#import "QTRFile.h"
#import "QTRTransfersStore.h"

@interface QTRBonjourManager () <QTRBonjourClientDelegate, QTRBonjourServerDelegate> {
    QTRBonjourServer *_server;
    QTRBonjourClient *_client;
    NSMutableArray *_connectedServers;
    NSMutableArray *_connectedClients;
    NSMutableOrderedSet *_remoteUsers;
    QTRUser *_localUser;
    BOOL _canRefresh;
}

@end

@implementation QTRBonjourManager

#pragma mark - Start/Stop services

- (void)startServices {
    if (_remoteUsers == nil) {
        _remoteUsers = [[NSMutableOrderedSet alloc] init];
    }
    if (_connectedServers == nil) {
        _connectedServers = [[NSMutableArray alloc] init];
    }
    if (_connectedClients == nil) {
        _connectedClients = [[NSMutableArray alloc] init];
    }
    NSString *userName = self.delegate.computerName ?: @"Unknown Device";

    NSString *uuid = [[NSUserDefaults standardUserDefaults] stringForKey:QTRBonjourTXTRecordIdentifierKey];
    if ([uuid isKindOfClass:[NSNull class]] || uuid == nil) {
        uuid = [[NSUUID UUID] UUIDString];
        [[NSUserDefaults standardUserDefaults] setObject:uuid forKey:QTRBonjourTXTRecordIdentifierKey];
    }

    _localUser = [[QTRUser alloc] initWithName:userName identifier:uuid platform:QTRUserPlatformMac];

    [[NSUserDefaults standardUserDefaults] synchronize];

    _server = [[QTRBonjourServer alloc] initWithFileDelegate:self];
    [_server setTransferDelegate:self.transfersDelegate];

    if (![_server start]) {
        // TODO: Notify the delegate that the server failed to start
//        NSAlert *alert = [NSAlert alertWithMessageText:@"Could not start server" defaultButton:@"Ok" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Please make sure WiFi/Ethernet is enabled and connected"];
//        [alert runModal];
    }

    _client = [[QTRBonjourClient alloc] initWithDelegate:self];
    [_client setTransferDelegate:self.transfersDelegate];
    [_client start];

    if ([self.delegate respondsToSelector:@selector(bonjourManagerDidStartServices:)]) {
        [self.delegate bonjourManagerDidStartServices:self];
    }
}

- (void)stopServices {
    [_remoteUsers removeAllObjects];
    [_connectedClients removeAllObjects];
    [_connectedServers removeAllObjects];

    [_server setDelegate:nil];
    [_server setTransferDelegate:nil];
    [_server stop];
    _server = nil;

    [_client setDelegate:nil];
    [_client setTransferDelegate:nil];
    [_client stop];
    _client = nil;

    if ([self.delegate respondsToSelector:@selector(bonjourManagerDidStopServices:)]) {
        [self.delegate bonjourManagerDidStopServices:self];
    }
    
}

#pragma mark - Public methods

- (void)refresh:(void (^)(void))completion {
    if (_canRefresh) {
        _canRefresh = NO;
        [self stopServices];
        double delayInSeconds = 2.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self startServices];
            _canRefresh = YES;
            if (completion != nil) {
                completion();
            }
        });
    }

}

- (NSArray *)remoteUsers {
    return _remoteUsers.array;
}

- (void)accept:(BOOL)shouldAccept file:(QTRFile *)file fromUser:(QTRUser *)remoteUser context:(id)context {
    if ([_connectedClients containsObject:remoteUser]) {
        [_server acceptFile:file accept:shouldAccept fromUser:remoteUser];
    } else if ([_connectedServers containsObject:remoteUser]) {
        [_client acceptFile:file accept:shouldAccept fromUser:remoteUser];
    }
}


- (void)sendFileAtURL:(NSURL *)fileURL toUser:(QTRUser *)user {
    if ([_connectedClients containsObject:user]) {
        [_server sendFileAtURL:fileURL toUser:user];
    } else if ([_connectedServers containsObject:user]) {
        [_client sendFileAtURL:fileURL toUser:user];
    }
}

- (QTRUser *)userAtIndex:(NSInteger)index {
    QTRUser *user = nil;
    NSArray *users = [self remoteUsers];
    if (index >= 0 && index < users.count) {
        user = users[index];
    }
    return user;
}

- (BOOL)resumeTransfer:(QTRTransfer *)transfer {
    return ([_server resumeTransfer:transfer] || [_client resumeTransfer:transfer]);
}


#pragma mark - Private methods

- (BOOL)userConnected:(QTRUser *)user {
    return [_connectedClients containsObject:user] || [_connectedServers containsObject:user] || [_localUser isEqual:user];
}

- (void)userDidConnect:(QTRUser *)user {
    if ([self.delegate respondsToSelector:@selector(bonjourManager:didConnectToUser:)]) {
        [self.delegate bonjourManager:self didConnectToUser:user];
    }
}

- (void)userDidDisconnect:(QTRUser *)user {
    if ([self.delegate respondsToSelector:@selector(bonjourManager:didDisconnectFromUser:)]) {
        [self.delegate bonjourManager:self didDisconnectFromUser:user];
    }
}

#pragma mark - QTRBonjourServerDelegate methods

- (void)server:(QTRBonjourServer *)server didConnectToUser:(QTRUser *)user {
    if (![self userConnected:user]) {
        [_connectedClients addObject:user];
        [_remoteUsers addObject:user];
        [self userDidConnect:user];
    }
}

- (void)server:(QTRBonjourServer *)server didDisconnectUser:(QTRUser *)user {
    [_connectedClients removeObject:user];
    [_remoteUsers removeObject:user];
    [self userDidDisconnect:user];
}

- (void)server:(QTRBonjourServer *)server didReceiveFile:(QTRFile *)file fromUser:(QTRUser *)user {
    if ([self.delegate respondsToSelector:@selector(bonjourManager:didReceiveFile:fromUser:)]) {
        [self.delegate bonjourManager:self didReceiveFile:file fromUser:user];
    }
}

- (NSURL *)saveURLForFile:(QTRFile *)file {
    return [self.delegate bonjourManager:self saveURLForFile:file];
}

- (void)server:(QTRBonjourServer *)server didSaveReceivedFileAtURL:(NSURL *)url fromUser:(QTRUser *)user {
    if ([self.delegate respondsToSelector:@selector(bonjourManager:didSaveReceivedFileToURL:fromUser:)]) {
        [self.delegate bonjourManager:self didSaveReceivedFileToURL:url fromUser:user];
    }
}

- (void)server:(QTRBonjourServer *)server didDetectIncomingFile:(QTRFile *)file fromUser:(QTRUser *)user {
    if (_shouldAutoAcceptFiles) {
        [server acceptFile:file accept:YES fromUser:user];
    } else {
        if ([self.delegate respondsToSelector:@selector(bonjourManager:requiresUserConfirmationForFile:fromUser:context:)]) {
            [self.delegate bonjourManager:self requiresUserConfirmationForFile:file fromUser:user context:@YES];
        }
    }
}

- (void)user:(QTRUser *)user didRejectFile:(QTRFile *)file {
    if ([self.delegate respondsToSelector:@selector(bonjourManager:remoteUser:didRejectFile:)]) {
        [self.delegate bonjourManager:self remoteUser:user didRejectFile:file];
    }
}

- (void)server:(QTRBonjourServer *)server didBeginSendingFile:(QTRFile *)file toUser:(QTRUser *)user {
    if ([self.delegate respondsToSelector:@selector(bonjourManager:didBeginFileTransfer:toUser:)]) {
        [self.delegate bonjourManager:self didBeginFileTransfer:file toUser:user];
    }
}

#pragma mark - QTRBonjourClientDelegate methods

- (QTRUser *)localUser {
    return _localUser;
}

- (BOOL)client:(QTRBonjourClient *)client shouldConnectToUser:(QTRUser *)user {

    return ![self userConnected:user];
}

- (void)client:(QTRBonjourClient *)client didConnectToServerForUser:(QTRUser *)user {
    if (![self userConnected:user]) {
        [_connectedServers addObject:user];
        [_remoteUsers addObject:user];
        [self userDidConnect:user];
    }
}

- (void)client:(QTRBonjourClient *)client didDisconnectFromServerForUser:(QTRUser *)user {
    [_connectedServers removeObject:user];
    [_remoteUsers removeObject:user];
    [self userDidDisconnect:user];
}

- (void)client:(QTRBonjourClient *)client didReceiveFile:(QTRFile *)file fromUser:(QTRUser *)user {
    if ([self.delegate respondsToSelector:@selector(bonjourManager:didReceiveFile:fromUser:)]) {
        [self.delegate bonjourManager:self didReceiveFile:file fromUser:user];
    }
}

- (void)client:(QTRBonjourClient *)client didSaveReceivedFileAtURL:(NSURL *)url fromUser:(QTRUser *)user {
    if ([self.delegate respondsToSelector:@selector(bonjourManager:didSaveReceivedFileToURL:fromUser:)]) {
        [self.delegate bonjourManager:self didSaveReceivedFileToURL:url fromUser:user];
    }
}

- (void)client:(QTRBonjourClient *)client didDetectIncomingFile:(QTRFile *)file fromUser:(QTRUser *)user {
    if (_shouldAutoAcceptFiles) {
        [client acceptFile:file accept:YES fromUser:user];
    } else {
        if ([self.delegate respondsToSelector:@selector(bonjourManager:requiresUserConfirmationForFile:fromUser:context:)]) {
            [self.delegate bonjourManager:self requiresUserConfirmationForFile:file fromUser:user context:@YES];
        }
    }
}

- (void)client:(QTRBonjourClient *)client didBeginSendingFile:(QTRFile *)file toUser:(QTRUser *)user {
    if ([self.delegate respondsToSelector:@selector(bonjourManager:didBeginFileTransfer:toUser:)]) {
        [self.delegate bonjourManager:self didBeginFileTransfer:file toUser:user];
    }
}


@end
