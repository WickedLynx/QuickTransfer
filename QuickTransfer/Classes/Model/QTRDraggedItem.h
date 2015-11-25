//
//  QTRDraggedItem.h
//  QuickTransfer
//
//  Created by Harshad on 25/11/15.
//  Copyright © 2015 Laughing Buddha Software. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 * An item dragged into the app from another app/system
 */
@interface QTRDraggedItem : NSObject

- (instancetype)initWithFileURL:(NSURL *)fileURL isDirectory:(BOOL)isDirectory;

/*!
 * The file URL of the receiver
 */
@property (readonly, nonatomic) NSURL *fileURL;

/*!
 * Indicates if the receiver is a directory
 */
@property (readonly, nonatomic) BOOL isDirectory;

@end
