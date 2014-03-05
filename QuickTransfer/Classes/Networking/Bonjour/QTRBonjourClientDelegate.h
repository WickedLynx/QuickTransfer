//
//  QTRBonjourClientDelegate.h
//  QuickTransfer
//
//  Created by Harshad on 18/02/14.
//  Copyright (c) 2014 Laughing Buddha Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@class QTRBonjourClient;
@class QTRUser;
@class QTRFile;

@protocol QTRBonjourClientDelegate <NSObject>

@required

- (QTRUser *)localUser;
- (BOOL)client:(QTRBonjourClient *)client shouldConnectToUser:(QTRUser *)user;
- (NSURL *)saveURLForFile:(QTRFile *)file;

@optional

- (void)client:(QTRBonjourClient *)client didConnectToServerForUser:(QTRUser *)user;
- (void)client:(QTRBonjourClient *)client didDisconnectFromServerForUser:(QTRUser *)user;
- (void)client:(QTRBonjourClient *)client didReceiveFile:(QTRFile *)file fromUser:(QTRUser *)user;
- (void)client:(QTRBonjourClient *)client didSaveReceivedFileAtURL:(NSURL *)url fromUser:(QTRUser *)user;

@end
