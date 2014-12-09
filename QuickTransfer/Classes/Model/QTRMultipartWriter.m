//
//  QTRMultipartWriter.m
//  QuickTransfer
//
//  Created by Harshad on 04/03/14.
//  Copyright (c) 2014 Laughing Buddha Software. All rights reserved.
//

#import "QTRMultipartWriter.h"
#import "QTRFile.h"
#import "QTRUser.h"

@implementation QTRMultipartWriter {
    NSFileHandle *_fileHandle;
}

- (instancetype)initWithFilePart:(QTRFile *)filePart sender:(QTRUser *)user saveURL:(NSURL *)url {
    self = [super init];

    if (self != nil) {

        NSFileManager *fileManager = [NSFileManager defaultManager];
        [fileManager createFileAtPath:[url path] contents:filePart.data attributes:nil];

        _saveURL = [url copy];
        _user = user;

        _fileHandle = [NSFileHandle fileHandleForWritingToURL:url error:nil];
        [_fileHandle seekToEndOfFile];
    }

    return self;
}

- (void)writeFilePart:(QTRFile *)filePart queue:(dispatch_queue_t)queue completion:(void (^)())completionBlock {
    dispatch_queue_t writingQueue = queue;
    if (writingQueue == nil) {
        writingQueue = dispatch_get_main_queue();
    }
    __weak typeof(self) wSelf = self;
    dispatch_async(writingQueue, ^{
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
