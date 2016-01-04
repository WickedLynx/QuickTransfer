//
//  QTRTransfersTableRowView.m
//  QuickTransfer
//
//  Created by Harshad on 22/12/15.
//  Copyright © 2015 Laughing Buddha Software. All rights reserved.
//

#import "QTRTransfersTableRowView.h"

@implementation QTRTransfersTableRowView {
    NSTrackingArea *trackingArea;
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    if (selected) {
        [self setBackgroundColor:[NSColor colorWithWhite:0.0 alpha:0.5]];
    } else {
        [self setBackgroundColor:[NSColor clearColor]];
    }
}


@end
