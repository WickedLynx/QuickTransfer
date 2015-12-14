//
//  QTRRecentLogsViewController.h
//  QuickTransfer
//
//  Created by Tarun Yadav on 03/12/15.
//  Copyright © 2015 Laughing Buddha Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "QTRBonjourTransferDelegate.h"
#import "QTRTransfersStoreDelegate.h"

@interface QTRRecentLogsViewController : UIViewController

- (QTRTransfersStore *)transfersStore;

@end
