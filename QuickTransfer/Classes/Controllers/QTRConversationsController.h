//
//  QTRConversationsController.h
//  QuickTransfer
//
//  Created by Harshad on 10/12/14.
//  Copyright (c) 2014 Laughing Buddha Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class QTRUser;

@interface QTRConversationsController : NSWindowController <NSOutlineViewDataSource, NSOutlineViewDelegate>

- (IBAction)clickSend:(NSButton *)sender;

- (void)userConnected:(QTRUser *)user;
- (void)userDisconnected:(QTRUser *)user;

@property (weak) IBOutlet NSOutlineView *usersOutlineView;
@property (strong) IBOutlet NSTextView *chatView;
@property (weak) IBOutlet NSTextField *composeField;
@property (weak) IBOutlet NSButton *sendButton;

@end
