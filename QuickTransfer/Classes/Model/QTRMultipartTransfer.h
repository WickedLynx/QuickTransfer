//
//  QTRMultipartTransfer.h
//  QuickTransfer
//
//  Created by Harshad on 03/03/14.
//  Copyright (c) 2014 Laughing Buddha Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@class QTRUser;
@class QTRFile;

/*!
 The maximum file size in bytes for a single file part
 */
FOUNDATION_EXPORT long long const QTRMultipartTransferMaximumPartSize;

/*!
 This class represents a multipart file transfer.
 It is responsible for sequentially reading a large file and creating multiple parts from it for transmission
 */
@interface QTRMultipartTransfer : NSObject

/*!
 Creates a multipart transfer for transmission
 @param fileURL The file URL from which the data for the transfer is read
 @param user The receipient of the transfer
 */
- (instancetype)initWithFileURL:(NSURL *)fileURL user:(QTRUser *)user;

/*!
 Reads the next file part for the multipart transfer.
 
 This method is asynchronous and returns immediately. 
 When the file part is read, the receiver calls the dataReadCompletion block passing the data read as a file object
 and a boolean indicating if it is the last part of the transfer.

 @param dataReadCompletion The block to call when the part is read from disk.
                            The block is not called on the main thread.
 */
- (void)readNextPartForTransmission:(void (^)(QTRFile *file, BOOL isLastPart))dataReadCompletion;

/*!
 The name of the file of the transfer
 */
@property (copy) NSString *fileName;

/*!
 The recipient of the file
 */
@property (strong) QTRUser *user;

@end
