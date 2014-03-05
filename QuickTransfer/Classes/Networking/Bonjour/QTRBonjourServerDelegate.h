//
//  QTRBonjourServerDelegate.h
//  QuickTransfer
//
//  Created by Harshad on 18/02/14.
//  Copyright (c) 2014 Laughing Buddha Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@class QTRBonjourServer;
@class QTRUser;
@class QTRFile;

@protocol QTRBonjourServerDelegate <NSObject>

@required

- (QTRUser *)localUser;
- (NSURL *)saveURLForFile:(QTRFile *)file;

@optional

- (void)server:(QTRBonjourServer *)server didConnectToUser:(QTRUser *)user;
- (void)server:(QTRBonjourServer *)server didDisconnectUser:(QTRUser *)user;
- (void)server:(QTRBonjourServer *)server didReceiveFile:(QTRFile *)file fromUser:(QTRUser *)user;
- (void)server:(QTRBonjourServer *)server didSaveReceivedFileAtURL:(NSURL *)url fromUser:(QTRUser *)user;


@end
