//
//  QTRTransfersTableCellView.h
//  QuickTransfer
//
//  Created by Harshad on 28/02/14.
//  Copyright (c) 2014 Laughing Buddha Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/*!
 The table cell view which displays a file transfer
 */
@interface QTRTransfersTableCellView : NSTableCellView

/*!
 Displays the name of the recipient of the file
 */
@property (weak) IBOutlet NSTextField *recipientNameField;

/*!
 Displays the time when the file transfer was started
 */
@property (weak) IBOutlet NSTextField *timestampField;

/*!
 Displays the name of the file
 */
@property (weak) IBOutlet NSTextField *fileNameField;

/*!
 Displays the size of the file
 */
@property (weak) IBOutlet NSTextField *fileSizeField;

@property (weak) IBOutlet NSButton *leftButton;

@end
