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
@class QTRStatusItemView;

@protocol QTRTransfersControllerDelegate;
@protocol QTRTransfersTableCellViewDelegate;
@protocol QTRTransfersTableViewEditingDelegate;
@protocol QTRStatusItemViewDelegate;
/*!
 This class drives the transfers view which displays the progress of transfers
 */
@interface QTRTransfersController : NSObject <NSTableViewDataSource, NSTableViewDelegate, QTRTransfersStoreDelegate, QTRTransfersTableCellViewDelegate, QTRTransfersTableViewEditingDelegate, QTRStatusItemViewDelegate>

@property (weak) IBOutlet NSWindow *window;

/*!
 The table view which displays the transfers and their progress
 */
@property (weak) IBOutlet NSTableView *transfersTableView;

/*!
 The transfers store of the receiver
 */
@property (strong, nonatomic) QTRTransfersStore *transfersStore;

@property (weak) IBOutlet NSButton *showDevicesButton;


/*!
 The delegate of the receiver
 */
@property (weak, nonatomic) id <QTRTransfersControllerDelegate> delegate;

@property (weak) IBOutlet QTRStatusItemView *dragView;

@end


@protocol QTRTransfersControllerDelegate <NSObject>

@optional

/*!
 * The TransfersController calls this method when the user wishes to resume a transfer
 */
- (BOOL)transfersController:(QTRTransfersController *)controller needsResumeTransfer:(QTRTransfer *)transfer;

- (BOOL)transfersController:(QTRTransfersController *)controller needsPauseTransfer:(QTRTransfer *)transfer;

- (void)transfersControllerNeedsToShowDevices:(QTRTransfersController *)controller;

@end
