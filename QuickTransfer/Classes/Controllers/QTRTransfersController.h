//
//  QTRTransfersController.h
//  QuickTransfer
//
//  Created by Harshad on 27/02/14.
//  Copyright (c) 2014 Laughing Buddha Software. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "QTRBonjourTransferDelegate.h"


/*!
 This class updates the progress of ongoing and completed file transfers
 */
@interface QTRTransfersController : NSObject <QTRBonjourTransferDelegate, NSTableViewDataSource, NSTableViewDelegate>

/*!
 Removes all transfers currently being tracked by the receiver.
 
 This does not stop ongoing transfers from being transmitted
 */
- (void)removeAllTransfers;

- (IBAction)clickClearCompleted:(id)sender;

/*!
 The table view which displays the transfers and their progress
 */
@property (weak) IBOutlet NSTableView *transfersTableView;

@end
