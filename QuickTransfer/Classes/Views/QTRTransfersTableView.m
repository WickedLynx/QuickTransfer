//
//  QTRTransfersTableView.m
//  QuickTransfer
//
//  Created by Harshad on 22/12/15.
//  Copyright © 2015 Laughing Buddha Software. All rights reserved.
//

#import "QTRTransfersTableView.h"
#import "QTRTransfersTableCellView.h"

@implementation QTRTransfersTableView

- (void)keyDown:(NSEvent *)theEvent {
    [super keyDown:theEvent];

    unichar key = [[theEvent charactersIgnoringModifiers] characterAtIndex:0];
    if (key == NSBackspaceCharacter || key == NSDeleteCharacter) {
        if ([self.editingDelegate respondsToSelector:@selector(transfersTableViewDidDetectDeleteKeyDown:)]) {
            [self.editingDelegate transfersTableViewDidDetectDeleteKeyDown:self];
        }
    }
}

@end
