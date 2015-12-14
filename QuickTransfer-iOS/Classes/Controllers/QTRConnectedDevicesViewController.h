//
//  QTRConnectedDevicesViewController.h
//  QuickTransfer
//
//  Created by Harshad on 20/02/14.
//  Copyright (c) 2014 Laughing Buddha Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "QTRBonjourTransferDelegate.h"
@import Photos;
@import PhotosUI;

@interface QTRConnectedDevicesViewController : UIViewController <UINavigationControllerDelegate, UISearchBarDelegate>


@property (nonatomic, strong) NSIndexPath *selectedItemIndexPath;
@property (nonatomic, strong) NSMutableArray *photos;
@property (nonatomic, assign) bool isFiltered;
@property (strong, nonatomic) NSMutableArray* filteredUserData;
@property (nonatomic, retain) PHImageRequestOptions *requestOptions;

/*!
 Initialises the receiver.
 
 @param transfersController An object confirming to QTRBonjourTransferDelegate protocol. The receiver weakly retains this controller.
 */
- (instancetype)initWithTransfersStore:(id <QTRBonjourTransferDelegate>)transfersStore;

- (void)setImportedFile:(NSURL *)fileURL;

@end
