//
//  QTRConversationsController.m
//  QuickTransfer
//
//  Created by Harshad on 10/12/14.
//  Copyright (c) 2014 Laughing Buddha Software. All rights reserved.
//

#import "QTRConversationsController.h"

@interface QTRConversationsController ()

@end

@implementation QTRConversationsController

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (IBAction)clickSend:(NSButton *)sender {
}

// MARK: NSOutlineViewDataSource methods

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    BOOL isExpandable = NO;
    if (item == nil) {
        isExpandable = YES;
    }
    return isExpandable;
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
    NSInteger numberOfChildren = 1;
    if (item != nil) {
        numberOfChildren = 5;
    }
    return numberOfChildren;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
    id child = @"Root";
    if (item != nil) {
        child = [NSString stringWithFormat:@"child %ld", (long)item];
    }
    return child;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
    return @"test";
}

// MARK: NSOutlineViewDelegate methods

- (id)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    NSTableCellView *cellView = [outlineView makeViewWithIdentifier:@"DeviceCell" owner:self];
    [cellView.textField setStringValue:@"Test"];
    return cellView;
}





@end
