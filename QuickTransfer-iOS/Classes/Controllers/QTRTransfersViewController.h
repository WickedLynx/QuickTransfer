//
//  QTRTransfersViewController.h
//  QuickTransfer
//
//  Created by Tarun Yadav on 24/12/15.
//  Copyright © 2015 Laughing Buddha Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "QTRBonjourTransferDelegate.h"
#import "QTRTransfersStoreDelegate.h"

@interface QTRTransfersViewController : UIViewController

- (QTRTransfersStore *)transfersStore;

@end
