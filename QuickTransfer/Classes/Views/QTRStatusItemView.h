//
//  QTRStatusItemView.h
//  QuickTransfer
//
//  Created by Harshad on 26/02/14.
//  Copyright (c) 2014 Laughing Buddha Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class QTRStatusItemView;

/*!
 Protocol to forward user interaction events to the delegate of the view
 */
@protocol QTRStatusItemViewDelegate <NSObject>

@optional
/*!
 This method is called when the view detects a mouse drag entered event
 */
- (void)statusItemViewDraggingEntered:(QTRStatusItemView *)view;

@end

/*!
 This view is displayed in the menubar of the application
 */
@interface QTRStatusItemView : NSView

/*!
 The frontmost view of the reciver, which receives click actions
 */
@property (weak, nonatomic) IBOutlet NSButton *button;

/*!
 The delegate of the receiver
 */
@property (weak, nonatomic) id <QTRStatusItemViewDelegate> delegate;

@end
