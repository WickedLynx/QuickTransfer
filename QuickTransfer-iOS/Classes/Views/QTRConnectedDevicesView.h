//
//  QTRConnectedDevicesView.h
//  QuickTransfer
//
//  Created by Harshad on 20/02/14.
//  Copyright (c) 2014 Laughing Buddha Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "QTRNoConnectedDeviceFoundView.h"

@interface QTRConnectedDevicesView : UIView

@property (nonatomic, strong) UISearchBar *searchBar;

@property (nonatomic, strong) UICollectionView *devicesCollectionView;
@property (nonatomic, strong) UIButton *sendButton;
@property (nonatomic, strong) UIRefreshControl *deviceRefreshControl;
@property (nonatomic, strong) UILabel *fetchDevicesLabel;
@property (nonatomic, strong) QTRNoConnectedDeviceFoundView *noConnectedDeviceFoundView;


- (void)animatePreviewLabel:(UILabel *)previewMessageLabel;


@end
