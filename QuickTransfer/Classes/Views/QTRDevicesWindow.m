//
//  QTRDevicesWindow.m
//  QuickTransfer
//
//  Created by Harshad on 18/12/15.
//  Copyright © 2015 Laughing Buddha Software. All rights reserved.
//

#import "QTRDevicesWindow.h"

@implementation QTRDevicesWindow

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
