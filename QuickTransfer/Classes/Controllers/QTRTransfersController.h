//
//  QTRTransfersController.h
//  QuickTransfer
//
//  Created by Harshad on 27/02/14.
//  Copyright (c) 2014 Laughing Buddha Software. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "QTRBonjourTransferDelegate.h"

#import "QTRTransfersStore.h"

/*!
 This class drives the transfers view which displays the progress of transfers
 */
@interface QTRTransfersController : NSObject <NSTableViewDataSource, NSTableViewDelegate, QTRTransfersStoreDelegate>

- (IBAction)clickClearCompleted:(id)sender;

/*!
 The table view which displays the transfers and their progress
 */
@property (weak) IBOutlet NSTableView *transfersTableView;

/*!
 The transfers store of the receiver
 */
@property (strong, nonatomic) QTRTransfersStore *transfersStore;

@end
