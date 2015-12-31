//
//  QTRCustomAlertView.h
//  QuickTransfer
//
//  Created by Tarun Yadav on 07/12/15.
//  Copyright © 2015 Laughing Buddha Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface QTRCustomAlertView : UIView

@property (nonatomic, strong) UIButton *cancelButton;
@property (nonatomic, strong) UIButton *iCloudButton;
@property (nonatomic, strong) UIButton *takePhotoButton;
@property (nonatomic, strong) UIButton *cameraRollButton;
@property (nonatomic, strong) UIView *galleryUIView;
@property (nonatomic, strong) UIView *galleryCollectionView;
@property (nonatomic, strong) UILabel *alertTitleLabel;

@end
