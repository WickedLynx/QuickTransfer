//
//  QTRStatusItemView.h
//  QuickTransfer
//
//  Created by Harshad on 26/02/14.
//  Copyright (c) 2014 Laughing Buddha Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class QTRStatusItemView;

@protocol QTRStatusItemViewDelegate <NSObject>

@optional

- (void)statusItemViewDraggingEntered:(QTRStatusItemView *)view;

@end

@interface QTRStatusItemView : NSView

@property (weak, nonatomic) IBOutlet NSButton *button;
@property (weak, nonatomic) id <QTRStatusItemViewDelegate> delegate;

@end
