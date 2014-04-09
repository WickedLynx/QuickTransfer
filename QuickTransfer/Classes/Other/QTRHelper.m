//
//  QTRHelper.m
//  QuickTransfer
//
//  Created by Harshad on 09/04/14.
//  Copyright (c) 2014 Laughing Buddha Software. All rights reserved.
//

#import "QTRHelper.h"

@implementation QTRHelper

#pragma mark - Private methods

+ (NSURL *)createDirectoryAtPath:(NSString *)path {

    NSURL *urlToReturn = nil;

    BOOL isDirectory = NO;
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory];
    if (!fileExists || !isDirectory) {

        BOOL success = [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
        if (success) {
            urlToReturn = [NSURL fileURLWithPath:path];
        }

    } else {
        urlToReturn = [NSURL fileURLWithPath:path];
    }

    return urlToReturn;

}

#pragma mark - Public methods

+ (NSURL *)applicationSupportDirectoryURL {

    NSURL *urlToReturn = nil;

    NSString *directoryName = @"QuickTransfer";

    NSArray *validLibraryDirectories = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    if ([validLibraryDirectories count] > 0) {
        NSString *libraryDirectoryPath = validLibraryDirectories[0];
        NSString *supportDirectory = [libraryDirectoryPath stringByAppendingPathComponent:directoryName];

        urlToReturn = [self createDirectoryAtPath:supportDirectory];
        [urlToReturn setResourceValue: [NSNumber numberWithBool: YES] forKey: NSURLIsExcludedFromBackupKey error:nil];

    }

    return urlToReturn;
}

+ (NSURL *)fileCacheDirectory {

    NSURL *urlToReturn = nil;

    NSString *directoryName = @"Files";

    NSArray *validLibraryDirectories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    if ([validLibraryDirectories count] > 0) {
        NSString *libraryDirectoryPath = validLibraryDirectories[0];
        NSString *supportDirectory = [libraryDirectoryPath stringByAppendingPathComponent:directoryName];

        urlToReturn = [self createDirectoryAtPath:supportDirectory];
        [urlToReturn setResourceValue: [NSNumber numberWithBool: YES] forKey: NSURLIsExcludedFromBackupKey error:nil];
        
    }

    return urlToReturn;
}


@end
