//
//  QTRGalleryImagesView.h
//  QuickTransfer
//
//  Created by Tarun Yadav on 26/11/15.
//  Copyright © 2015 Laughing Buddha Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface QTRGalleryImagesView : UIView

@property (weak, nonatomic) UITableView *devicesTableView;

@property(nonatomic,retain) UIProgressView *sendingProgressView;
@property (weak, nonatomic) UISearchBar *searchBar;

@property (weak, nonatomic) UICollectionView *devicesCollectionView;
@property (weak, nonatomic) UIButton *sendButton;

@end
