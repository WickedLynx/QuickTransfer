//
//  QTRFileZipper.m
//  QuickTransfer
//
//  Created by Harshad on 25/11/15.
//  Copyright © 2015 Laughing Buddha Software. All rights reserved.
//

#import "QTRFileZipper.h"

@implementation QTRFileZipper

+ (NSURL *)temporaryFileURLForFile:(NSURL *)file {

    return nil;
}

+ (void)zipDirectoryAtURL:(NSURL *)directoryURL completion:(void (^)(NSURL *, NSError *))completion {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDirectory = NO;
    if (directoryURL == nil || !([fileManager fileExistsAtPath:directoryURL.path isDirectory:&isDirectory] && isDirectory)) {
        if (completion != nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil, [NSError errorWithDomain:@"com.lbs.QuickTransfer" code:-122 userInfo:@{NSLocalizedDescriptionKey : @"The file does not exist/is empty or is not a directory"}]);
            });
        }
        return;
    }
    NSError *zipError = nil;
    NSFileCoordinator *fileCoordinater = [[NSFileCoordinator alloc] init];
    [fileCoordinater coordinateReadingItemAtURL:directoryURL options:NSFileCoordinatorReadingForUploading error:&zipError byAccessor:^(NSURL * _Nonnull newURL) {
        NSURL *copiedFile = nil;
        NSError *fileManagerError = nil;
        if ([fileManager fileExistsAtPath:[newURL path]]) {
            NSString *tmpPath = [NSTemporaryDirectory() stringByAppendingPathComponent:newURL.path.lastPathComponent];
            NSString *fileName = [tmpPath lastPathComponent];
            while ([fileManager fileExistsAtPath:tmpPath]) {
                fileName = [NSString stringWithFormat:@"%ld-%@", (long)[[NSDate date] timeIntervalSince1970], fileName];
                tmpPath = [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];
            }
            copiedFile = [NSURL fileURLWithPath:tmpPath];
            [fileManager moveItemAtPath:newURL.path toPath:tmpPath error:&fileManagerError];
        }
        if (completion != nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(copiedFile, fileManagerError);
            });
        }
    }];
    if (zipError != nil) {
        if (completion != nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil, zipError);
            });
        }
    }
}

+ (void)unzipDirectoryAtURL:(NSURL *)directoryURL completion:(void (^)(NSURL *, NSError *))completion {

}

@end
