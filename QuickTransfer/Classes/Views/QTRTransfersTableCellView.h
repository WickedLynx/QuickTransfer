//
//  QTRTransfersTableCellView.h
//  QuickTransfer
//
//  Created by Harshad on 28/02/14.
//  Copyright (c) 2014 Laughing Buddha Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface QTRTransfersTableCellView : NSTableCellView

@property (weak) IBOutlet NSTextField *recipientNameField;
@property (weak) IBOutlet NSTextField *timestampField;
@property (weak) IBOutlet NSTextField *fileNameField;
@property (weak) IBOutlet NSTextField *fileSizeField;
@property (weak) NSProgressIndicator *progressIndicator;

@end
