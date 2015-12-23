//
//  QTRTransfer.m
//  QuickTransfer
//
//  Created by Harshad on 27/02/14.
//  Copyright (c) 2014 Laughing Buddha Software. All rights reserved.
//

#import "QTRTransfer.h"

NSString *const QTRTransferProgressKey = @"QTRTransferProgress";
NSString *const QTRTransferUserKey = @"QTRTransferUser";
NSString *const QTRTransferFileURLKey = @"QTRTransferFileURL";
NSString *const QTRTransferFileSizeKey = @"QTRTransferFileSize";
NSString *const QTRTransferTimestampKey = @"QTRTransferTimestamp";
NSString *const QTRTransferTotalPartsKey = @"QTRTransferTotalParts";
NSString *const QTRTransferTransferedChunksKey = @"QTRTransferTransferedChunks";
NSString *const QTRTransferCurrentChunkProgressKey = @"QTRTransferCurrentChunkProgress";
NSString *const QTRTransferStateKey = @"QTRTransferState";
NSString *const QTRTransferSentBytesKey = @"QTRTransferSentBytes";
NSString *const QTRTransferFileIdentifierKey = @"QTRTransferFileIdentifier";
NSString *const QTRTransferIsIncomingKey = @"QTRTransferIsIncoming";

@implementation QTRTransfer

#pragma mark - Public methods

- (float)progress {
    
    if (self.totalParts > 1) {
        _progress = (float)(self.transferedChunks + self.currentChunkProgress) / (float)self.totalParts;
    }

    return _progress;
}

#pragma mark - NSCoding methods

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self != nil) {
        _progress = [aDecoder decodeFloatForKey:QTRTransferProgressKey];
        _user = [aDecoder decodeObjectForKey:QTRTransferUserKey];
        _fileURL = [aDecoder decodeObjectForKey:QTRTransferFileURLKey];
        _fileSize = [[aDecoder decodeObjectForKey:QTRTransferFileSizeKey] longLongValue];
        _timestamp = [aDecoder decodeObjectForKey:QTRTransferTimestampKey];
        _totalParts = [aDecoder decodeIntegerForKey:QTRTransferTotalPartsKey];
        _transferedChunks = [aDecoder decodeIntegerForKey:QTRTransferTransferedChunksKey];
        _currentChunkProgress = [aDecoder decodeFloatForKey:QTRTransferCurrentChunkProgressKey];
        _state = [aDecoder decodeIntegerForKey:QTRTransferStateKey];
        _sentBytes = [aDecoder decodeIntegerForKey:QTRTransferSentBytesKey];
        _fileIdentifier = [aDecoder decodeObjectForKey:QTRTransferFileIdentifierKey];
        _isIncoming = [aDecoder decodeBoolForKey:QTRTransferIsIncomingKey];
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {

    [aCoder encodeFloat:self.progress forKey:QTRTransferProgressKey];
    [aCoder encodeObject:self.user forKey:QTRTransferUserKey];
    [aCoder encodeObject:self.fileURL forKey:QTRTransferFileURLKey];
    [aCoder encodeObject:@(self.fileSize) forKey:QTRTransferFileSizeKey];
    [aCoder encodeObject:self.timestamp forKey:QTRTransferTimestampKey];
    [aCoder encodeInteger:self.totalParts forKey:QTRTransferTotalPartsKey];
    [aCoder encodeInteger:self.transferedChunks forKey:QTRTransferTransferedChunksKey];
    [aCoder encodeFloat:self.currentChunkProgress forKey:QTRTransferCurrentChunkProgressKey];
    [aCoder encodeInteger:self.state forKey:QTRTransferStateKey];
    [aCoder encodeInteger:self.sentBytes forKey:QTRTransferSentBytesKey];
    [aCoder encodeObject:_fileIdentifier forKey:QTRTransferFileIdentifierKey];
    [aCoder encodeBool:_isIncoming forKey:QTRTransferIsIncomingKey];
}

#pragma mark - QLPreviewItem methods

- (NSURL *)previewItemURL {
    return self.fileURL;
}

@end
