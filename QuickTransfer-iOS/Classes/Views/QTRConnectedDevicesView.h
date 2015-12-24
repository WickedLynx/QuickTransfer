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

@property (retain, nonatomic) UISearchBar *searchBar;

@property (retain, nonatomic) UICollectionView *devicesCollectionView;
@property (retain, nonatomic) UIButton *sendButton;
@property (retain, nonatomic) UIRefreshControl *deviceRefreshControl;
@property (retain, nonatomic) UILabel *fetchingDevicesLabel;
@property (retain, nonatomic) QTRNoConnectedDeviceFoundView *noConnectedDeviceFoundView;


- (void)animatePreviewLabel:(UILabel *)previewMessageLabel;


@end
