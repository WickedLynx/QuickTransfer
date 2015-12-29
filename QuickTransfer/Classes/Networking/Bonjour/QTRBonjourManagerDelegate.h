//
//  QTRBonjourManagerDelegate.h
//  QuickTransfer
//
//  Created by Harshad on 14/12/15.
//  Copyright © 2015 Laughing Buddha Software. All rights reserved.
//

#import <Foundation/Foundation.h>
@class QTRBonjourManager;
@class QTRUser;
@class QTRFile;

@protocol QTRBonjourManagerDelegate <NSObject>

@required

- (NSURL *)bonjourManager:(QTRBonjourManager *)manager saveURLForFile:(QTRFile *)file;

@property (strong, nonatomic) NSString *computerName;

@optional

- (void)bonjourManagerDidStartServices:(QTRBonjourManager *)manager;
- (void)bonjourManagerDidStopServices:(QTRBonjourManager *)manager;
- (void)bonjourManager:(QTRBonjourManager *)manager didConnectToUser:(QTRUser *)remoteUser;
- (void)bonjourManager:(QTRBonjourManager *)manager didDisconnectFromUser:(QTRUser *)remoteUser;

- (void)bonjourManager:(QTRBonjourManager *)manager requiresUserConfirmationForFile:(QTRFile *)file fromUser:(QTRUser *)remoteUser context:(id)context;
- (void)bonjourManager:(QTRBonjourManager *)manager didReceiveFile:(QTRFile *)file fromUser:(QTRUser *)user;
- (void)bonjourManager:(QTRBonjourManager *)manager didSaveReceivedFileToURL:(NSURL *)url fromUser:(QTRUser *)user;
- (void)bonjourManager:(QTRBonjourManager *)manager remoteUser:(QTRUser *)remoteUser didRejectFile:(QTRFile *)file;
- (void)bonjourManager:(QTRBonjourManager *)manager didBeginFileTransfer:(QTRFile *)file toUser:(QTRUser *)remoteUser;




@end
