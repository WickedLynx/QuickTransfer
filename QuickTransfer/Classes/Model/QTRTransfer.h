//
//  QTRTransfer.h
//  QuickTransfer
//
//  Created by Harshad on 27/02/14.
//  Copyright (c) 2014 Laughing Buddha Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@class QTRUser;
@class QTRFile;
@class DTBonjourDataChunk;

/*!
 This class tracks the progress of a file transfer
 */
@interface QTRTransfer : NSObject

/*!
 The progress of the transfer
 */
@property (nonatomic) float progress;

/*!
 The recepient of the transfer
 */
@property (strong) QTRUser *user;

/*!
 The file URL from which the file data of the transfer was loaded
 */
@property (copy) NSURL *fileURL;

/*!
 The total file size of the transfer in bytes
 */
@property (nonatomic) long long fileSize;

/*!
 The date when the transfer was started
 */
@property (strong) NSDate *timestamp;

/*!
 The total file parts in the transfer
 */
@property (nonatomic) NSUInteger totalParts;

/*!
 The total file parts that were successfully transfered
 */
@property (nonatomic) int transferedChunks;

/*!
 The progress of the file part that is currently being sent
 */
@property (nonatomic) float currentChunkProgress;

@end
