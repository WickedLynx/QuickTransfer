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


@class QTRActionSheetGalleryView;
@protocol QTRActionSheetGallaryDelegate <NSObject>

- (void)actionSheetGalleryView:(QTRActionSheetGalleryView *)actionSheetGalleryView selectedImage:(QTRImagesInfoData *)sendingImage;

@end

@interface QTRActionSheetGalleryView : UIView  <UICollectionViewDelegate,UICollectionViewDataSource>


@property (nonatomic, weak) id <QTRActionSheetGallaryDelegate> delegate;
@property (nonatomic, retain) NSArray *fetchImageArray;

- (void)stopIndicatorViewAnimation;
- (void)startIndicatorViewAnimation;
- (void)reloadUICollectionView;

@end
