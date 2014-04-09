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

@protocol QTRBonjourTransferDelegate <NSObject>

@optional

- (void)addTransferForUser:(QTRUser *)user file:(QTRFile *)file chunk:(DTBonjourDataChunk *)chunk;
- (void)updateTransferForChunk:(DTBonjourDataChunk *)chunk;
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
 Update the transfer of an incoming file
 
 @param file The file being received
 */
- (void)updateTransferForFile:(QTRFile *)file;

/*!
 Saves meta of transfered files to disk.
 */
- (void)archiveTransfers;

@end
