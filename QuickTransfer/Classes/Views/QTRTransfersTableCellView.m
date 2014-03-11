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
@implementation QTRTransfersTableCellView {
    NSColor *_backgroundColor;
}

- (void)awakeFromNib {
    NSProgressIndicator *progressIndicator = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(self.fileNameField.frame.origin.x + 5, self.fileNameField.frame.origin.y + 24, self.bounds.size.width - 10, 6)];
    [progressIndicator setIndeterminate:NO];
    [progressIndicator setUsesThreadedAnimation:YES];
    [progressIndicator setMaxValue:1.0f];
    [progressIndicator setMinValue:0.0f];
    [progressIndicator setDoubleValue:0.0f];
    [progressIndicator setAutoresizingMask:(NSViewWidthSizable | NSViewMaxXMargin)];
    [progressIndicator setBezeled:NO];
    [progressIndicator setDisplayedWhenStopped:NO];

    [self addSubview:progressIndicator];
    self.progressIndicator = progressIndicator;

    _backgroundColor = [NSColor whiteColor];

}

- (void)setObjectValue:(id)objectValue {
    if ([objectValue isKindOfClass:[QTRTransfer class]]) {
        QTRTransfer *transfer = (QTRTransfer *)objectValue;

        [self.recipientNameField setStringValue:transfer.user.name];
        [self.fileSizeField setIntegerValue:transfer.fileSize];
        [self.fileNameField setStringValue:[[transfer.fileURL path] lastPathComponent]];
        [self.timestampField setObjectValue:transfer.timestamp];
        [self.progressIndicator setDoubleValue:transfer.progress];

        switch (transfer.state) {
            case QTRTransferStateInProgress:
                _backgroundColor = [NSColor whiteColor];
                [self.progressIndicator setHidden:NO];
                break;

            case QTRTransferStateCompleted:
                _backgroundColor = [NSColor colorWithCalibratedRed:0.76f green:0.99f blue:0.80f alpha:1.00f];
                break;

            case QTRTransferStateFailed:
                _backgroundColor = [NSColor colorWithCalibratedRed:1.00f green:0.90f blue:0.89f alpha:1.00f];
                [self.progressIndicator setHidden:YES];
                break;

            default:
                break;
        }

        [self setNeedsDisplay:YES];

    }
}

- (void)drawRect:(NSRect)dirtyRect {
    [_backgroundColor setFill];
    NSRectFill(dirtyRect);
}

@end
