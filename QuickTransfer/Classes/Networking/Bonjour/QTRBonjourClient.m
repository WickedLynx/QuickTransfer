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

@interface QTRBonjourClient () <DTBonjourDataConnectionDelegate, NSNetServiceBrowserDelegate, NSNetServiceDelegate>

- (QTRUser *)userForConnection:(DTBonjourDataConnection *)connection;
- (DTBonjourDataConnection *)connectionForUser:(QTRUser *)user;

@property (strong) NSNetServiceBrowser *netServicesBrowser;
@property (strong) NSMapTable *discoveredServices;
@property (strong) NSMutableArray *foundServices;
@property (strong) QTRUser *localUser;

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


    [self.discoveredServices removeAllObjects];

}

- (void)sendFile:(QTRFile *)file toUser:(QTRUser *)user {

    QTRMessage *message = [QTRMessage messageWithUser:_localUser file:file];
    NSData *jsonData = [message JSONData];
    DTBonjourDataChunk *chunk = nil;
    [[self connectionForUser:user] sendObject:jsonData error:nil dataChunk:&chunk];

    if ([self.transferDelegate respondsToSelector:@selector(addTransferForUser:file:chunk:)]) {
        [self.transferDelegate addTransferForUser:user file:file chunk:chunk];
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
    return [self.discoveredServices objectForKey:user];
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
    [connection sendObject:[userInfoMessage JSONData] error:nil dataChunk:nil];

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
    [self.discoveredServices removeObjectForKey:user];
}

- (void)connection:(DTBonjourDataConnection *)connection didReceiveObject:(id)object {

    if ([object isKindOfClass:[NSData class]]) {
        QTRMessage *theMessage = [QTRMessage messageWithJSONData:object];
        QTRUser *user = theMessage.user;

        if (user.name != nil && user.identifier != nil) {
            if ([self.delegate respondsToSelector:@selector(client:didReceiveFile:fromUser:)]) {
                [self.delegate client:self didReceiveFile:theMessage.file fromUser:user];
            }
        }
    }
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
