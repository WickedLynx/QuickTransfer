//
//  QTRTransfersTableCell.h
//  QuickTransfer
//
//  Created by Harshad on 27/02/14.
//  Copyright (c) 2014 Laughing Buddha Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface QTRTransfersTableCell : NSView

@property (strong) IBOutlet NSTextField *nameField;
@property (strong) IBOutlet NSTextField *timestampField;
@property (strong) IBOutlet NSTextField *fileNameField;
@property (strong) IBOutlet NSTextField *fileSizeField;


@end
