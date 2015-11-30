//
//  QTRActionSheetGalleryView.h
//  QuickTransfer
//
//  Created by Tarun Yadav on 27/11/15.
//  Copyright © 2015 Laughing Buddha Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "QTRAlertControllerCollectionViewCell.h"

@class QTRActionSheetGalleryView;
@protocol actionSheetGallaryDelegate <NSObject>

- (void)QTRActionSheetGalleryView:(QTRActionSheetGalleryView *)actionSheetGalleryView didCellSelected:(BOOL)selected withCollectionCell:(QTRAlertControllerCollectionViewCell *)alertControllerCollectionViewCell;

@end

@interface QTRActionSheetGalleryView : UIView  <UICollectionViewDelegate,UICollectionViewDataSource>
{
    ALAssetsLibrary *library;
    NSArray *imageArray;
    NSMutableArray *mutableArray;
    UICollectionView *aCollectionView;
    UIActivityIndicatorView *customIndicatorView;
}

-(void)allPhotosCollected:(NSArray*)imgArray;

@property (weak, nonatomic) UICollectionView *actionControllerCollectionView;
@property (retain, nonatomic) UIActivityIndicatorView *actionCustomIndicatorView;

@property (nonatomic, weak) id <actionSheetGallaryDelegate> delegate;

@end
