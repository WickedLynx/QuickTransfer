//
//  QTRBonjourServer.h
//  QuickTransfer
//
//  Created by Harshad on 18/02/14.
//  Copyright (c) 2014 Laughing Buddha Software. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "DTBonjourServer.h"
#import "QTRBonjourServerDelegate.h"
#import "QTRBonjourTransferDelegate.h"

@class QTRFile;
@class QTRTransfersController;

@interface QTRBonjourServer : DTBonjourServer

- (instancetype)initWithFileDelegate:(id <QTRBonjourServerDelegate>)fileDelegate;

- (void)sendFile:(QTRFile *)file toUser:(QTRUser *)user;

@property (weak) id <QTRBonjourServerDelegate> fileDelegate;
@property (weak) id <QTRBonjourTransferDelegate> transferDelegate;

@end
