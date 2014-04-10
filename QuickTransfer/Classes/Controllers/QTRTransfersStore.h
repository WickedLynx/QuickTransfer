//
//  QTRTransfersStore.h
//  QuickTransfer
//
//  Created by Harshad on 09/04/14.
//  Copyright (c) 2014 Laughing Buddha Software. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "QTRBonjourTransferDelegate.h"
#import "QTRTransfersStoreDelegate.h"

/*!
 This class updates the progress of ongoing file transfers and caches saves them to a persistent store.
 
 The delegate is notified whenever the transfers are modified.
 */
@interface QTRTransfersStore : NSObject <QTRBonjourTransferDelegate>

/*!
 Initialises the receiver for reading and writing to a particular file.
 
 @param archiveLocation The location of the file where transfer metadata is stored.
 */
- (instancetype)initWithArchiveLocation:(NSString *)archiveLocation;

/*!
 Returs the transfers the receiver is currently tracking
 */
- (NSArray *)transfers;

/*!
 Saves meta of transfered files history to disk
 */
- (void)archiveTransfers;

/*!
 Removes all transfers currently being tracked by the receiver.

 This does not stop ongoing transfers from being transmitted
 */
- (void)removeAllTransfers;

/*!
 Removes completed transfers.
 */
- (void)removeCompletedTransfers;

/*!
 The delegate of the receiver
 */
@property (weak, nonatomic) id <QTRTransfersStoreDelegate> delegate;

@end
