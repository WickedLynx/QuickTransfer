//
//  QTRTransfersTableView.h
//  QuickTransfer
//
//  Created by Harshad on 22/12/15.
//  Copyright © 2015 Laughing Buddha Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@protocol QTRTransfersTableViewEditingDelegate;

@interface QTRTransfersTableView : NSTableView

@property (weak) IBOutlet id <QTRTransfersTableViewEditingDelegate> editingDelegate;

@end

@protocol QTRTransfersTableViewEditingDelegate <NSObject>

@optional

- (void)transfersTableViewDidDetectDeleteKeyDown:(QTRTransfersTableView *)tableView;

@end
