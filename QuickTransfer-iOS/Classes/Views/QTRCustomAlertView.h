//
//  QTRCustomAlertView.h
//  QuickTransfer
//
//  Created by Tarun Yadav on 07/12/15.
//  Copyright © 2015 Laughing Buddha Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface QTRCustomAlertView : UIView

@property (retain, nonatomic) UIButton *cancelButton;
@property (retain, nonatomic) UIButton *iCloudButton;
@property (retain, nonatomic) UIButton *takePhotoButton;
@property (retain, nonatomic) UIButton *cameraRollButton;
@property (retain, nonatomic) UIView *galleryUIView;
@property (retain, nonatomic) UIView *galleryCollectionView;
@property (retain, nonatomic) UILabel *alertTitleLabel;

@end
