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
@protocol actionSheetGallaryDelegate <NSObject>

- (void)QTRActionSheetGalleryView:(QTRActionSheetGalleryView *)actionSheetGalleryView didCellSelected:(BOOL)selected withCollectionCell:(QTRAlertControllerCollectionViewCell *)alertControllerCollectionViewCell selectedImage:(QTRImagesInfoData *)sendingImage;

@end

@interface QTRActionSheetGalleryView : UIView  <UICollectionViewDelegate,UICollectionViewDataSource>


@property (nonatomic, weak) id <actionSheetGallaryDelegate> delegate;
@property (nonatomic, retain) NSMutableArray *fetchingImageArray;

- (void)stopIndicatorViewAnimation;
- (void)startIndicatorViewAnimation;

@end
