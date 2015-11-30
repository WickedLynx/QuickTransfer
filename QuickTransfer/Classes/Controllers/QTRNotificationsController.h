//
//  QTRNotificationsController.h
//  QuickTransfer
//
//  Created by Harshad on 30/11/15.
//  Copyright © 2015 Laughing Buddha Software. All rights reserved.
//

#import <Foundation/Foundation.h>
@class QTRFile;
@class QTRUser;

@interface QTRNotificationsController : NSObject <NSUserNotificationCenterDelegate>

- (void)showRejectionNotificationForFile:(QTRFile *)file toUser:(QTRUser *)user;
- (void)showFileSavedNotificationForFileNamed:(NSString *)fileName fromUser:(QTRUser *)user;

@end
