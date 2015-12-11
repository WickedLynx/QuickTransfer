//
//  QTRNotificationsController.m
//  QuickTransfer
//
//  Created by Harshad on 30/11/15.
//  Copyright © 2015 Laughing Buddha Software. All rights reserved.
//

#import "QTRNotificationsController.h"
#import "QTRFile.h"
#import "QTRUser.h"

@implementation QTRNotificationsController {
}

- (void)showFileSavedNotificationForFileNamed:(NSString *)fileName fromUser:(QTRUser *)user {

    NSUserNotificationCenter *nc = [NSUserNotificationCenter defaultUserNotificationCenter];
    [nc removeAllDeliveredNotifications];
    [nc setDelegate:self];
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    [notification setTitle:@"File Saved"];
    [notification setInformativeText:[NSString stringWithFormat:@"%@ from %@", fileName, user.name]];
    [notification setHasActionButton:NO];
    [notification setHasReplyButton:NO];
    [notification setDeliveryDate:[NSDate date]];
    [nc scheduleNotification:notification];
}

- (void)showRejectionNotificationForFile:(QTRFile *)file toUser:(QTRUser *)user {
    NSUserNotificationCenter *nc = [NSUserNotificationCenter defaultUserNotificationCenter];
    [nc removeAllDeliveredNotifications];
    [nc setDelegate:self];
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    [notification setTitle:@"File Rejected"];
    [notification setInformativeText:[NSString stringWithFormat:@"%@ to %@", file.name, user.name]];
    [notification setHasActionButton:NO];
    [notification setHasReplyButton:NO];
    [notification setDeliveryDate:[NSDate date]];
    [nc scheduleNotification:notification];
}

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification {
    return YES;
}




@end
