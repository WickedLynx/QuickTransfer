//
//  QTRWindowTransitioner.h
//  QuickTransfer
//
//  Created by Harshad on 05/01/16.
//  Copyright © 2016 Laughing Buddha Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface QTRWindowTransitioner : NSObject

- (void)transitionFromWindow:(NSWindow *)fromWindow toWindow:(NSWindow *)toWindow relativeToStatusItem:(NSView *)statusItem animated:(BOOL)animated;
- (void)activateVisibleWindowRelativeToStatusItemView:(NSView *)statusItemView;
- (void)setInitialVisibleWindow:(NSWindow *)window;
- (void)setInitialHiddenWindow:(NSWindow *)window;
@end
