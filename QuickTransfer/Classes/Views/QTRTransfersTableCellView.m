//
//  QTRTransfersTableCellView.m
//  QuickTransfer
//
//  Created by Harshad on 28/02/14.
//  Copyright (c) 2014 Laughing Buddha Software. All rights reserved.
//

#import "QTRTransfersTableCellView.h"
#import "QTRTransfer.h"
#import "QTRUser.h"
#import "QTRFile.h"
@implementation QTRTransfersTableCellView

- (void)awakeFromNib {
    NSProgressIndicator *progressIndicator = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(self.fileNameField.frame.origin.x + 5, self.fileNameField.frame.origin.y + 23, self.bounds.size.width - 10, 10)];
    [progressIndicator setIndeterminate:NO];
    [progressIndicator setUsesThreadedAnimation:YES];
    [progressIndicator setMaxValue:1.0f];
    [progressIndicator setMinValue:0.0f];
    [progressIndicator setDoubleValue:0.0f];
    [progressIndicator setAutoresizingMask:(NSViewWidthSizable | NSViewMaxXMargin)];
    [self addSubview:progressIndicator];
    self.progressIndicator = progressIndicator;

}

- (void)setObjectValue:(id)objectValue {
    if ([objectValue isKindOfClass:[QTRTransfer class]]) {
        QTRTransfer *transfer = (QTRTransfer *)objectValue;

        [self.recipientNameField setStringValue:transfer.user.name];
        [self.fileSizeField setIntegerValue:transfer.fileSize];
        [self.fileNameField setStringValue:[[transfer.fileURL path] lastPathComponent]];
        [self.timestampField setObjectValue:transfer.timestamp];
        [self.progressIndicator setDoubleValue:transfer.progress];

    }
}

@end
