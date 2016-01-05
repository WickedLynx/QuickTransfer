//
//  QTRTransfersWindow.m
//  QuickTransfer
//
//  Created by Harshad on 05/01/16.
//  Copyright © 2016 Laughing Buddha Software. All rights reserved.
//

#import "QTRTransfersWindow.h"

@implementation QTRTransfersWindow

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setMovable:NO];
    [self setBackgroundColor:[NSColor clearColor]];
    if ([self.contentView isKindOfClass:[NSVisualEffectView class]]) {
        NSVisualEffectView *visualEffectView = self.contentView;
        [visualEffectView setState:NSVisualEffectStateActive];
        [visualEffectView setMaterial:NSVisualEffectMaterialDark];
        [visualEffectView setWantsLayer:YES];
    }
}

- (BOOL)canBecomeKeyWindow {
    return YES;
}

@end
