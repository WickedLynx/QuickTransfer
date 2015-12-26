//
//  QTRConnectedDevicesViewController.h
//  QuickTransfer
//
//  Created by Harshad on 20/02/14.
//  Copyright (c) 2014 Laughing Buddha Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "QTRBonjourTransferDelegate.h"
#import "QTRGetMediaImages.h"


@interface QTRConnectedDevicesViewController : UIViewController <UINavigationControllerDelegate, UISearchBarDelegate>


@property (nonatomic, assign) BOOL isFiltered;
@property (nonatomic, strong) QTRGetMediaImages *getMediaImages;

/*!
 Initialises the receiver.
 
 @param transfersController An object confirming to QTRBonjourTransferDelegate protocol. The receiver weakly retains this controller.
 */
- (instancetype)initWithTransfersStore:(id <QTRBonjourTransferDelegate>)transfersStore;

- (void)setImportedFile:(NSURL *)fileURL;

@end
