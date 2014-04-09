//
//  QTRHelper.h
//  QuickTransfer
//
//  Created by Harshad on 09/04/14.
//  Copyright (c) 2014 Laughing Buddha Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface QTRHelper : NSObject

/*!
 Returns the application support directory (~/Library/Quicktransfer).
 
 Creates the directory if it does not exist.
 
 @returns The application support directory for Mac targets
 */
+ (NSURL *)applicationSupportDirectoryURL NS_AVAILABLE_MAC(10_8);

/*!
 Returns the file cache directory (<App Sandbox>/Documents/Files).

 Creates the directory if it does not exist.

 @returns The file cache directory for iOS targets
 */
+ (NSURL *)fileCacheDirectory NS_AVAILABLE_IPHONE(6_0);


@end
