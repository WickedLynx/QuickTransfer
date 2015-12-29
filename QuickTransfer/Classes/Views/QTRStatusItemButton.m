//
//  QTRStatusItemButton.m
//  QuickTransfer
//
//  Created by Harshad on 18/12/15.
//  Copyright © 2015 Laughing Buddha Software. All rights reserved.
//

#import "QTRStatusItemButton.h"

@implementation QTRStatusItemButton {
    SEL _rightClickAction;
    __weak id _rightClickTarget;
}

- (void)setTarget:(id)target forRightClickAction:(SEL)action {
    _rightClickTarget = target;
    _rightClickAction = action;
}

- (void)rightMouseDown:(NSEvent *)theEvent {
    [_rightClickTarget performSelector:_rightClickAction withObject:self];
}


@end
