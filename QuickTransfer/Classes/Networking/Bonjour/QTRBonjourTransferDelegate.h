//
//  QTRBonjourTransferDelegate.h
//  QuickTransfer
//
//  Created by Harshad on 27/02/14.
//  Copyright (c) 2014 Laughing Buddha Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@class QTRUser;
@class QTRFile;
@class DTBonjourDataChunk;
@class QTRTransfer;

/*!
 The Bonjour client/server notifies interested delegates about the the transfer progress and state through this protocol
 */
@protocol QTRBonjourTransferDelegate <NSObject>

@optional

/*!
 Add a new transfer.
 
 @param user The remote user
 @param file The file being sent
 @param chunk The data chunk that is currently being sent
 */
- (void)addTransferForUser:(QTRUser *)user file:(QTRFile *)file chunk:(DTBonjourDataChunk *)chunk;

/*!
 Called after bytes are read/written for a transfer.
 
 @param chunk The chunk that is currently being sent/received
 */
- (void)updateTransferForChunk:(DTBonjourDataChunk *)chunk;

/*!
 Called after the transmission of the current chunk is over and a new chunk is prepared for transmitting.
 
 @param oldChunk The chunk that was previously transmitted
 @param newChunk The chunk that will be sent next
 */
- (void)replaceChunk:(DTBonjourDataChunk *)oldChunk withChunk:(DTBonjourDataChunk *)newChunk;

/*!
 Marks all transfers for the particular user as failed
 
 @param user The sender or receipient of the transfers
 */
- (void)failAllTransfersForUser:(QTRUser *)user;

/*!
 Add a new incoming transfer.
 
 @param user The sender of the file
 @param file The file being received
 */
- (void)addTransferFromUser:(QTRUser *)user file:(QTRFile *)file;

/*!
 Resume a transfer
 */
- (void)resumeTransferForUser:(QTRUser *)user file:(QTRFile *)file chunk:(DTBonjourDataChunk *)chunk;

/*!
 Update the transfer of an incoming file
 
 @param file The file being received
 */
- (void)updateTransferForFile:(QTRFile *)file;

/*!
 Update the sent bytes of the multi-part transfer
 
 @param sentBytes The total bytes sent
 @param file The file to update
 */
- (void)updateSentBytes:(long long)sentBytes forFile:(QTRFile *)file;

/*!
 Check if a transfer can be resumed
 */
- (BOOL)canResumeTransferForFile:(QTRFile *)file;

/*!
 Returns the URL of a partially written file
 */
- (NSURL *)saveURLForResumedFile:(QTRFile *)file;

@end
