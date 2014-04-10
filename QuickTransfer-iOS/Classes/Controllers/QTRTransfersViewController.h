//
//  QTRTransfersViewController.h
//  QuickTransfer
//
//  Created by Harshad on 04/04/14.
//  Copyright (c) 2014 Laughing Buddha Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "QTRBonjourTransferDelegate.h"
#import "QTRTransfersStoreDelegate.h"

@interface QTRTransfersViewController : UIViewController <QTRTransfersStoreDelegate>

- (QTRTransfersStore *)transfersStore;

@end
