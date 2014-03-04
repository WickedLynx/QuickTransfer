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

long long const QTRMultipartTransferMaximumPartSize = 50 * 1024 * 1024;   // 50 MB

@implementation QTRMultipartTransfer {
    NSFileHandle *_fileHandle;
    NSURL *_fileURL;
    int _currentPart;
    long long _totalBytes;
    int _totalParts;
    NSString *_multipartFileTransferID;
}

- (instancetype)initWithFileURL:(NSURL *)fileURL user:(QTRUser *)user {
    self = [super init];
    if (self != nil) {
        if (fileURL != nil) {

            _fileURL = [fileURL copy];
            _fileName = [[_fileURL path] lastPathComponent];

            _user = user;

            _multipartFileTransferID = [NSString stringWithFormat:@"%@%@%f", _fileName, _user.name, [[NSDate date] timeIntervalSince1970]];

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

- (void)dealloc {
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (void)readNextPartForTransmission:(void (^)(QTRFile *file, BOOL isLastPart))dataReadCompletion {
    __weak typeof(self) wSelf = self;

    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        if (wSelf != nil) {

            typeof(self) sSelf = wSelf;

            long long targetPosition = [sSelf->_fileHandle offsetInFile] + QTRMultipartTransferMaximumPartSize;

            NSData *fileData = [sSelf->_fileHandle readDataOfLength:QTRMultipartTransferMaximumPartSize];
            BOOL isLastPart = NO;
            if (targetPosition <= sSelf->_totalBytes) {
                [sSelf->_fileHandle seekToFileOffset:targetPosition];
                NSLog(@"Read part");
            } else {
                isLastPart = YES;
                NSLog(@"Read last part");
            }

            QTRFile *file = [[QTRFile alloc] initWithName:sSelf->_fileName type:@"dmg" partIndex:sSelf->_currentPart totalParts:sSelf->_totalParts totalSize:sSelf->_totalBytes];
            [file setUrl:sSelf->_fileURL];
            [file setData:fileData];
            [file setMultipartID:sSelf->_multipartFileTransferID];

            ++sSelf->_currentPart;

            dataReadCompletion(file, isLastPart);
        }
    });
}

@end
