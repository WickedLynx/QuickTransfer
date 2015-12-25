//
//  QTRActionSheetGalleryView.h
//  QuickTransfer
//
//  Created by Tarun Yadav on 27/11/15.
//  Copyright © 2015 Laughing Buddha Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "QTRAlertControllerCollectionViewCell.h"
#import "QTRImagesInfoData.h"

@import Photos;
@import PhotosUI;

@class QTRActionSheetGalleryView;
@protocol actionSheetGallaryDelegate <NSObject>

- (void)QTRActionSheetGalleryView:(QTRActionSheetGalleryView *)actionSheetGalleryView didCellSelected:(BOOL)selected withCollectionCell:(QTRAlertControllerCollectionViewCell *)alertControllerCollectionViewCell selectedImage:(QTRImagesInfoData *)sendingImage;

@end

@interface QTRActionSheetGalleryView : UIView  <UICollectionViewDelegate,UICollectionViewDataSource>


@property (weak, nonatomic) UICollectionView *actionControllerCollectionView;
@property (retain, nonatomic) UIActivityIndicatorView *actionCustomIndicatorView;

@property (nonatomic, weak) id <actionSheetGallaryDelegate> delegate;

@property (nonatomic, retain) NSMutableArray *fetchingImageArray;

- (void)stopIndicatorViewAnimation;

@end
