//
//  QTRScroller.m
//  QuickTransfer
//
//  Created by Harshad on 21/12/15.
//  Copyright © 2015 Laughing Buddha Software. All rights reserved.
//

#import "QTRScroller.h"

@implementation QTRScroller

+ (BOOL)isCompatibleWithOverlayScrollers {
    return  self == [QTRScroller class];
}

- (void)drawRect:(NSRect)dirtyRect {
    [self drawKnob];
}

@end
