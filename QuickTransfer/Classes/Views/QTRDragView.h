//
//  QTRDragView.h
//  QuickTransfer
//
//  Created by Harshad on 17/12/15.
//  Copyright © 2015 Laughing Buddha Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol QTRDragViewDelegate;

@interface QTRDragView : NSView

@property (weak) IBOutlet NSImageView *imageView;
@property (weak) IBOutlet NSTextField *descriptionField;
@property (weak) id <QTRDragViewDelegate> delegate;

@end

@protocol QTRDragViewDelegate <NSObject>

@optional

- (NSString *)dragView:(QTRDragView *)dragView didPerformDragOperation:(id <NSDraggingInfo>)draggingInfo;

@end
