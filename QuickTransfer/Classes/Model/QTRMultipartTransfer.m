//
//  QTRMultipartTransfer.m
//  QuickTransfer
//
//  Created by Harshad on 03/03/14.
//  Copyright (c) 2014 Laughing Buddha Software. All rights reserved.
//

#import "QTRMultipartTransfer.h"

#import "QTRFile.h"
#import "QTRUser.h"

long long const QTRMultipartTransferMaximumPartSize = 10 * 1024 * 1024;   // 10 MB

@implementation QTRMultipartTransfer {
    NSFileHandle *_fileHandle;
    NSURL *_fileURL;
    int _currentPart;
    long long _totalBytes;
    int _totalParts;
}

- (instancetype)initWithFileURL:(NSURL *)fileURL user:(QTRUser *)user fileIdentifier:(NSString *)fileIdentifier {
    self = [super init];
    if (self != nil) {
        if (fileURL != nil) {

            _fileURL = [fileURL copy];
            _fileName = [[_fileURL path] lastPathComponent];

            _user = user;

            _fileIdentifier = [fileIdentifier copy];

            NSFileManager *fileManager = [NSFileManager defaultManager];
            NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:[_fileURL path] error:nil];
            if (![fileAttributes[NSFileSize] isKindOfClass:[NSNull class]]) {
                _totalBytes = [fileAttributes[NSFileSize] longLongValue];
                _totalParts = (int)(_totalBytes / QTRMultipartTransferMaximumPartSize);
                if (_totalBytes % QTRMultipartTransferMaximumPartSize != 0) {
                    ++_totalParts;
                }

            }

            NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingFromURL:_fileURL error:nil];
            _fileHandle = fileHandle;
        }
    }

    return self;
}

- (instancetype)initWithPartiallyTransferredFile:(QTRFile *)file user:(QTRUser *)user {
    self = [super init];
    if (self != nil) {
        _fileURL = file.url;
        _fileName = [[_fileURL path] lastPathComponent];
        _user = user;
        _fileIdentifier = [file.identifier copy];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:[_fileURL path] error:nil];
        if (![fileAttributes[NSFileSize] isKindOfClass:[NSNull class]]) {
            _totalBytes = [fileAttributes[NSFileSize] longLongValue];
            _totalParts = (int)(_totalBytes / QTRMultipartTransferMaximumPartSize);
            if (_totalBytes % QTRMultipartTransferMaximumPartSize != 0) {
                ++_totalParts;
            }

        }

        NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingFromURL:_fileURL error:nil];
        _fileHandle = fileHandle;
        [_fileHandle seekToFileOffset:file.offset];
        _currentPart = (int)(file.partIndex);
    }

    return self;
}

- (void)readNextPartForTransmission:(void (^)(QTRFile *file, BOOL isLastPart, long long offsetInFile))dataReadCompletion {
    __weak typeof(self) wSelf = self;

    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        if (wSelf != nil) {

            typeof(self) sSelf = wSelf;
            long long currentOffset = [sSelf->_fileHandle offsetInFile];
            long long targetPosition = [sSelf->_fileHandle offsetInFile] + QTRMultipartTransferMaximumPartSize;

            NSData *fileData = [sSelf->_fileHandle readDataOfLength:QTRMultipartTransferMaximumPartSize];
            BOOL isLastPart = NO;
            if (targetPosition <= sSelf->_totalBytes) {
                [sSelf->_fileHandle seekToFileOffset:targetPosition];
            } else {
                isLastPart = YES;
            }

            QTRFile *file = [[QTRFile alloc] initWithName:sSelf->_fileName type:@"dmg" partIndex:sSelf->_currentPart totalParts:sSelf->_totalParts totalSize:sSelf->_totalBytes];
            [file setUrl:sSelf->_fileURL];
            [file setData:fileData];
            [file setIdentifier:sSelf->_fileIdentifier];

            ++sSelf->_currentPart;

            dataReadCompletion(file, isLastPart, currentOffset);
        }
    });
}


+ (BOOL)canResumeReadingFile:(QTRFile *)file {
    BOOL canResume = NO;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:file.url.path isDirectory:NULL]) {
        NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:file.url.path error:nil];
        NSNumber *fileSize = fileAttributes[NSFileSize];
        if (file.offset < fileSize.longLongValue) {
            canResume = YES;
        }
    }
    return canResume;
}

- (long long)currentOffset {
    return [_fileHandle offsetInFile];
}

- (void)dealloc {
    [_fileHandle closeFile];
}




@end
