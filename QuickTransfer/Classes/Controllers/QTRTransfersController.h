//
//  QTRTransfersController.h
//  QuickTransfer
//
//  Created by Harshad on 27/02/14.
//  Copyright (c) 2014 Laughing Buddha Software. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "QTRBonjourTransferDelegate.h"

@interface QTRTransfersController : NSObject <QTRBonjourTransferDelegate, NSTableViewDataSource, NSTableViewDelegate>

- (NSArray *)transfers;
- (void)removeAllTransfers;

- (IBAction)clickClearCompleted:(id)sender;

@property (weak) IBOutlet NSTableView *transfersTableView;

@end
