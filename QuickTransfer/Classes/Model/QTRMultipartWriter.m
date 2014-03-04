//
//  QTRMultipartWriter.m
//  QuickTransfer
//
//  Created by Harshad on 04/03/14.
//  Copyright (c) 2014 Laughing Buddha Software. All rights reserved.
//

#import "QTRMultipartWriter.h"
#import "QTRFile.h"

@implementation QTRMultipartWriter {
    NSFileHandle *_fileHandle;
}

- (instancetype)initWithFilePart:(QTRFile *)filePart sender:(QTRUser *)user saveURL:(NSURL *)url {
    self = [super init];

    if (self != nil) {

        NSFileManager *fileManager = [NSFileManager defaultManager];
        [fileManager createFileAtPath:[url path] contents:filePart.data attributes:nil];

        _fileHandle = [NSFileHandle fileHandleForWritingToURL:url error:nil];
        [_fileHandle seekToEndOfFile];
    }

    return self;
}

- (void)writeFilePart:(QTRFile *)filePart completion:(void (^)())completionBlock {
    __weak typeof(self) wSelf = self;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        if (wSelf != nil) {
            typeof(self) sSelf = wSelf;
            [sSelf->_fileHandle writeData:filePart.data];
            completionBlock();
        }
    });
}

- (void)closeFile {
    [_fileHandle closeFile];
}

@end
