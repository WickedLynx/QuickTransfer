//
//  QTRFileZipper.h
//  QuickTransfer
//
//  Created by Harshad on 25/11/15.
//  Copyright © 2015 Laughing Buddha Software. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 * Utility class to zip-unzip files
 */
@interface QTRFileZipper : NSObject

/*!
 Creates a zip archive of a directory to a particluar location
 
 @param directoryURL The file URL of the directory to zip
 @param completion The completion handler to be called after the zip operation is done. The handler is called on the main thread with the location of the zip archive (if successful) or a error (if the operation fails). Can be `nil`.
 */
+ (void)zipDirectoryAtURL:(NSURL *)directoryURL completion:(void (^)(NSURL *zippedURL, NSError *error))completion;

@end
