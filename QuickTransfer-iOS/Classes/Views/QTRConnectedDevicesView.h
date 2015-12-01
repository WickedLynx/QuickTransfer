//
//  QTRConnectedDevicesView.h
//  QuickTransfer
//
//  Created by Harshad on 20/02/14.
//  Copyright (c) 2014 Laughing Buddha Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface QTRConnectedDevicesView : UIView

@property (weak, nonatomic) UITableView *devicesTableView;

@property(nonatomic,retain) UIProgressView *sendingProgressView;
@property (weak, nonatomic) UISearchBar *searchBar;

@property (weak, nonatomic) UICollectionView *devicesCollectionView;
@property (weak, nonatomic) UIButton *sendButton;
@property (nonatomic, strong) UIActivityIndicatorView *loadDeviceView;


@end
