//
//  QTRStatusItemButton.h
//  QuickTransfer
//
//  Created by Harshad on 18/12/15.
//  Copyright © 2015 Laughing Buddha Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface QTRStatusItemButton : NSButton

- (void)setTarget:(id)target forRightClickAction:(SEL)action;

@end
