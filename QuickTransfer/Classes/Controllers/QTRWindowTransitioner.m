//
//  QTRWindowTransitioner.m
//  QuickTransfer
//
//  Created by Harshad on 05/01/16.
//  Copyright © 2016 Laughing Buddha Software. All rights reserved.
//

#import "QTRWindowTransitioner.h"
#import <QuartzCore/QuartzCore.h>

@interface QTRWindowTransitionerAnimationContext : NSObject

@property (weak, nonatomic) NSWindow *inWindow;
@property (weak, nonatomic) NSWindow *outWindow;
@property (assign) BOOL secondTransition;

@end

@implementation QTRWindowTransitionerAnimationContext

@end



@interface QTRWindowTransitioner () {
    NSMapTable *_outAnimationIdentifiersToInWindows;
}

@property (weak, nonatomic) NSWindow *visibleWindow;

@end

@implementation QTRWindowTransitioner

- (instancetype)init {
    self = [super init];
    if (self != nil) {
        _outAnimationIdentifiersToInWindows = [NSMapTable strongToStrongObjectsMapTable];
    }

    return self;
}

- (void)transitionFromWindow:(NSWindow *)fromWindow toWindow:(NSWindow *)toWindow relativeToStatusItem:(NSView *)statusItem animated:(BOOL)animated {
    toWindow.alphaValue = 0.0f;
    [toWindow orderFront:nil];
    NSRect windowRect = [statusItem.window convertRectToScreen:statusItem.frame];
    NSPoint desiredWindowOrigin = NSMakePoint(windowRect.origin.x - toWindow.frame.size.width / 2, windowRect.origin.y);
    if (desiredWindowOrigin.x + toWindow.frame.size.width > [[NSScreen mainScreen] frame].size.width - 20) {
        desiredWindowOrigin.x = windowRect.origin.x - toWindow.frame.size.width - 20;
    }
    [toWindow setFrameOrigin:desiredWindowOrigin];
    [fromWindow setFrameOrigin:desiredWindowOrigin];
    [fromWindow makeKeyAndOrderFront:nil];
    toWindow.alphaValue = 1.0f;

    if ([toWindow isEqual:self.visibleWindow]) {
        return;
    }

    CALayer *inLayer = toWindow.contentView.layer;
    CATransform3D inInitialRotation = CATransform3DMakeRotation(-M_PI / 2, 0, 1.0, 0);
    CATransform3D inInitialTranslation = CATransform3DMakeTranslation(inLayer.bounds.size.width / 2, 0, 0);
    [inLayer setTransform:CATransform3DConcat(inInitialRotation, inInitialTranslation)];

    CALayer *outLayer = fromWindow.contentView.layer;
    CATransform3D outRotation = CATransform3DMakeRotation(-M_PI / 2, 0, 1.0, 0);
    CATransform3D outTranslation = CATransform3DMakeTranslation(outLayer.bounds.size.width / 2, 0, 0);
    CATransform3D outTransform = CATransform3DConcat(outRotation, outTranslation);

    CABasicAnimation *outAnimation = [CABasicAnimation animationWithKeyPath:@"transform"];
    outAnimation.fromValue = [NSValue valueWithCATransform3D:CATransform3DIdentity];
    outAnimation.toValue = [NSValue valueWithCATransform3D:outTransform];
    outAnimation.duration = 0.25;
    outAnimation.fillMode = kCAFillModeForwards;
    outAnimation.autoreverses = NO;
    outAnimation.removedOnCompletion = NO;
    [outAnimation setDelegate:self];
    NSString *uniqueID = [NSString stringWithFormat:@"%f", [[NSDate date] timeIntervalSinceReferenceDate]];
    [outAnimation setValue:uniqueID forKey:@"identifier"];
    QTRWindowTransitionerAnimationContext *context = [[QTRWindowTransitionerAnimationContext alloc] init];
    [context setInWindow:toWindow];
    [context setOutWindow:fromWindow];
    [_outAnimationIdentifiersToInWindows setObject:context forKey:uniqueID];
    [outLayer addAnimation:outAnimation forKey:@"transform"];

}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    NSString *animationIdentifier = [anim valueForKey:@"identifier"];
    NSString *key = nil;
    NSEnumerator *keyEnumerator = [_outAnimationIdentifiersToInWindows keyEnumerator];
    while (key = [keyEnumerator nextObject]) {
        if ([key isEqualToString:animationIdentifier]) {
            QTRWindowTransitionerAnimationContext *context = [_outAnimationIdentifiersToInWindows objectForKey:animationIdentifier];
            NSWindow *toWindow = context.inWindow;
            if (context.secondTransition) {
                [toWindow.contentView.layer setTransform:CATransform3DIdentity];
                [_outAnimationIdentifiersToInWindows removeObjectForKey:animationIdentifier];
                [self setVisibleWindow: context.inWindow];

            } else {
                [context setSecondTransition:YES];
                CABasicAnimation *animation = (CABasicAnimation *)anim;
                [context.outWindow.contentView.layer setTransform:[animation.toValue CATransform3DValue]];
                [toWindow makeKeyAndOrderFront:nil];
                CALayer *inLayer = toWindow.contentView.layer;
                if (inLayer != nil) {
                    CABasicAnimation *inAnimation = [CABasicAnimation animationWithKeyPath:@"transform"];
                    inAnimation.toValue = [NSValue valueWithCATransform3D:CATransform3DIdentity];
                    inAnimation.fromValue = [NSValue valueWithCATransform3D:inLayer.transform];
                    inAnimation.duration = 0.25;
                    inAnimation.fillMode = kCAFillModeForwards;
                    inAnimation.autoreverses = NO;
                    inAnimation.removedOnCompletion = NO;
                    [inAnimation setValue:animationIdentifier forKey:@"identifier"];
                    [inAnimation setDelegate:self];
                    [inLayer addAnimation:inAnimation forKey:@"transform"];
                }
            }

            break;
        }
    }
}

- (void)activateVisibleWindowRelativeToStatusItemView:(NSView *)statusItemView {
    NSRect windowRect = [statusItemView.window convertRectToScreen:statusItemView.frame];
    NSPoint desiredWindowOrigin = NSMakePoint(windowRect.origin.x - self.visibleWindow.frame.size.width / 2, windowRect.origin.y);
    if (desiredWindowOrigin.x + self.visibleWindow.frame.size.width > [[NSScreen mainScreen] frame].size.width - 20) {
        desiredWindowOrigin.x = windowRect.origin.x - self.visibleWindow.frame.size.width - 20;
    }
    [self.visibleWindow setFrameOrigin:desiredWindowOrigin];
    [self.visibleWindow makeKeyAndOrderFront:nil];
}

- (void)setInitialVisibleWindow:(NSWindow *)window {
    [self setVisibleWindow:window];
}


@end
