//
//  QTRStatusItemView.m
//  QuickTransfer
//
//  Created by Harshad on 26/02/14.
//  Copyright (c) 2014 Laughing Buddha Software. All rights reserved.
//

#import "QTRStatusItemView.h"

@implementation QTRStatusItemView


- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
        [self registerForDraggedTypes:@[(NSString *)kUTTypeURL]];
    }
    return self;
}


- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender {
    [self.delegate statusItemViewDraggingEntered:self];
    return NSDragOperationLink;
}




@end
