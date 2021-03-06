//
//  QTRTransfer.h
//  QuickTransfer
//
//  Created by Harshad on 27/02/14.
//  Copyright (c) 2014 Laughing Buddha Software. All rights reserved.
//

#import <Foundation/Foundation.h>

#if TARGET_OS_IPHONE
#import <QuickLook/QuickLook.h>

#elif TARGET_OS_MAC
#import <Quartz/Quartz.h>

#endif

@class QTRUser;

/*!
 The current state of the transfer.
 */
typedef NS_ENUM(NSInteger, QTRTransferState) {
    /*!
     The transfer is in progress
     */
    QTRTransferStateInProgress = 0,

    /*!
     The transfer is complete
     */
    QTRTransferStateCompleted,

    /*!
     The transfer has failed
     */
    QTRTransferStateFailed,

    /*!
     The transfer has been paused
     */
    QTRTransferStatePaused
};

/*!
 This class tracks the progress of a file transfer
 */
@interface QTRTransfer : NSObject <NSCoding, QLPreviewItem>

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
 * The identifier of the file
 */
@property (copy) NSString *fileIdentifier;

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
@property (nonatomic) NSUInteger transferedChunks;

/*!
 The progress of the file part that is currently being sent
 */
@property (nonatomic) float currentChunkProgress;

/*!
 * The number of bytes that were successfully sent
 */
@property (nonatomic) long long sentBytes;

@property (nonatomic) BOOL isIncoming;

/*!
 The state of the transfer
 */
@property (nonatomic) QTRTransferState state;


@end
