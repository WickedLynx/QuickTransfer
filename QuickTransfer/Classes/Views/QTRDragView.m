//
//  QTRDragView.m
//  QuickTransfer
//
//  Created by Harshad on 17/12/15.
//  Copyright © 2015 Laughing Buddha Software. All rights reserved.
//

#import "QTRDragView.h"

@implementation QTRDragView

- (void)awakeFromNib {
    [super awakeFromNib];
    [self.imageView unregisterDraggedTypes];
    [self.descriptionField unregisterDraggedTypes];
    [self registerForDraggedTypes:@[(NSString *)kUTTypeFileURL]];
}

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender {
    return NSDragOperationLink;
}


- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender {
    BOOL dropAllowed = NO;
    if ([self.delegate respondsToSelector:@selector(dragView:didPerformDragOperation:)]) {
        NSString *highlightedText = [self.delegate dragView:self didPerformDragOperation:sender];
        if (highlightedText != nil) {
            dropAllowed = YES;
            [self.descriptionField setStringValue:highlightedText];
            [self.imageView setImage:[NSImage imageNamed:@"FilesDroppedIcon"]];
        } else {
            [self.descriptionField setStringValue:@"Drop files here"];
            [self.imageView setImage:[NSImage imageNamed:@"Drop File Icon"]];
        }
    }
    return dropAllowed;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];

    [[NSColor whiteColor] setStroke];
    NSBezierPath *path = [NSBezierPath bezierPathWithRect:NSMakeRect(10, 10, self.bounds.size.width - 20, self.bounds.size.height - 20)];
    CGFloat dashPattern = {4.0};
    [path setLineDash:&dashPattern count:1 phase:0];
    [path setLineWidth:1];
    [path stroke];
}

@end
