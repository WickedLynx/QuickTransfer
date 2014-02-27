//
//  QTRBonjourClient.h
//  QuickTransfer
//
//  Created by Harshad on 18/02/14.
//  Copyright (c) 2014 Laughing Buddha Software. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "QTRBonjourClientDelegate.h"
#import "QTRBonjourTransferDelegate.h"

@interface QTRBonjourClient : NSObject

- (instancetype)initWithDelegate:(id <QTRBonjourClientDelegate>)delegate;

- (void)start;
- (void)stop;
- (void)sendFile:(QTRFile *)file toUser:(QTRUser *)user;

@property (weak) id <QTRBonjourClientDelegate> delegate;
@property (weak) id <QTRBonjourTransferDelegate> transferDelegate;


@end
