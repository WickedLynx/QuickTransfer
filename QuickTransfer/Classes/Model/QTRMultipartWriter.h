//
//  QTRMultipartWriter.h
//  QuickTransfer
//
//  Created by Harshad on 04/03/14.
//  Copyright (c) 2014 Laughing Buddha Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@class QTRFile;
@class QTRUser;

/*!
 This class writes the individual data parts of a multipart transfer to disk as they are received
 */
@interface QTRMultipartWriter : NSObject

/*!
 Creates a writer for writing a multipart transfer
 @param filePart    The first part of the transfer
 @param sender      The sender of the transfer
 @param saveURL     The file URL where the file is to be written
 */
- (instancetype)initWithFilePart:(QTRFile *)filePart sender:(QTRUser *)user saveURL:(NSURL *)url;

- (instancetype)initWithResumedTransferForFile:(QTRFile *)file sender:(QTRUser *)user saveURL:(NSURL *)url;


/*!
 Appends data passed in filePart to the file at saveURL of the receiver.

 The receiver calls the completionBlock once it has finished writing the part.

 @param filePart The file part to write
 @param queue The queue to write the file part in. If nil, uses the main queue.
 @param completionBlock The block called after writing the file part. The completion block is called in the writing queue.

 */
- (void)writeFilePart:(QTRFile *)filePart queue:(dispatch_queue_t)queue completion:(void (^)())completionBlock;

/*!
 Closes the file and prevents further write operations to it.
 
 This method must only be called after all parts of the multipart transfer
 have been received and written to disk.
 */
- (void)closeFile;

/*!
 The file URL where the multipart transfer is saved.
 */
@property (copy, nonatomic) NSURL *saveURL;

/*!
 The sender of the file
 */
@property (strong) QTRUser *user;

/*!
 The name of the file with its extension
 */
@property (copy) NSString *fileName;

@end
