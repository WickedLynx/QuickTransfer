//
//  QTRCustomAlertView.m
//  QuickTransfer
//
//  Created by Tarun Yadav on 07/12/15.
//  Copyright © 2015 Laughing Buddha Software. All rights reserved.
//

#import "QTRCustomAlertView.h"

@implementation QTRCustomAlertView

static float screenHeight;

- (id)initWithFrame:(CGRect)aRect
{
    if ((self = [super initWithFrame:aRect])) {
        

        screenHeight = [UIScreen mainScreen].bounds.size.height;
        
        UIView *galleryUIView = [[UIView alloc]initWithFrame:CGRectZero];
        [galleryUIView setTranslatesAutoresizingMaskIntoConstraints:NO];
        [galleryUIView setBackgroundColor:[UIColor whiteColor]];
        [[galleryUIView layer]setCornerRadius:7.0f];
        galleryUIView.clipsToBounds = YES;
        [self addSubview:galleryUIView];
        _galleryUIView = galleryUIView;
        
        UIView *galleryCollectionView = [[UIView alloc]initWithFrame:CGRectZero];
        [galleryCollectionView setTranslatesAutoresizingMaskIntoConstraints:NO];
        [galleryCollectionView setBackgroundColor:[UIColor yellowColor]];
        [galleryUIView addSubview:galleryCollectionView];
        _galleryCollectionView = galleryCollectionView;
        
        UILabel *alertTitleLabel = [[UILabel alloc]initWithFrame:CGRectZero];
        [alertTitleLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
        [alertTitleLabel setText:@"Select Source"];
        [alertTitleLabel setTextColor:[UIColor grayColor]];
        alertTitleLabel.textAlignment = NSTextAlignmentCenter;
        [alertTitleLabel setBackgroundColor:[UIColor whiteColor]];
        [galleryUIView addSubview:alertTitleLabel];
        _alertTitleLabel = alertTitleLabel;
        
        
        UIButton *iCloudButton = [UIButton buttonWithType:UIButtonTypeCustom];
        iCloudButton.frame = CGRectZero;
        //[[iCloudButton layer]setCornerRadius:7.0f];
        [[iCloudButton layer]setBorderWidth:0.5f];
        [[iCloudButton layer]setBorderColor:[UIColor grayColor].CGColor];
        [[iCloudButton layer]setMasksToBounds:TRUE];
        [iCloudButton setBackgroundColor:[UIColor whiteColor]];
        //iCloudButton.clipsToBounds = YES;
        [iCloudButton setTitle:@"iCloud" forState:UIControlStateNormal];
        [iCloudButton setTitleColor:[UIColor colorWithRed:32.f/255.f green:149.f/255.f blue:242.f/255.f alpha:1.00f] forState:UIControlStateNormal];
        [iCloudButton setTranslatesAutoresizingMaskIntoConstraints:NO];
        [galleryUIView addSubview:iCloudButton];
        _iCloudButton = iCloudButton;

        UIButton *takePhotoButton = [UIButton buttonWithType:UIButtonTypeCustom];
        takePhotoButton.frame = CGRectZero;
        //[[takePhotoButton layer]setCornerRadius:7.0f];
        [[takePhotoButton layer]setBorderWidth:0.5f];
        [[takePhotoButton layer]setBorderColor:[UIColor grayColor].CGColor];
        [[takePhotoButton layer]setMasksToBounds:TRUE];
        [takePhotoButton setBackgroundColor:[UIColor whiteColor]];
        //takePhotoButton.clipsToBounds = YES;
        [takePhotoButton setTitle:@"Take a Photo" forState:UIControlStateNormal];
        [takePhotoButton setTitleColor:[UIColor colorWithRed:32.f/255.f green:149.f/255.f blue:242.f/255.f alpha:1.00f] forState:UIControlStateNormal];
        [takePhotoButton setTranslatesAutoresizingMaskIntoConstraints:NO];
        [galleryUIView addSubview:takePhotoButton];
        _takePhotoButton = takePhotoButton;
        

        UIButton *cameraRollButton = [UIButton buttonWithType:UIButtonTypeCustom];
        cameraRollButton.frame = CGRectZero;
        //[[cameraRollButton layer]setCornerRadius:7.0f];
        [[cameraRollButton layer]setBorderWidth:0.5f];
        [[cameraRollButton layer]setBorderColor:[UIColor grayColor].CGColor];
        [[cameraRollButton layer]setMasksToBounds:TRUE];
        [cameraRollButton setBackgroundColor:[UIColor whiteColor]];
        //cameraRollButton.clipsToBounds = YES;
        [cameraRollButton setTitle:@"Camera Roll" forState:UIControlStateNormal];
        [cameraRollButton setTitleColor:[UIColor colorWithRed:32.f/255.f green:149.f/255.f blue:242.f/255.f alpha:1.00f] forState:UIControlStateNormal];
        [cameraRollButton setTranslatesAutoresizingMaskIntoConstraints:NO];
        [galleryUIView addSubview:cameraRollButton];
        _cameraRollButton = cameraRollButton;
        
        
        UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
        cancelButton.frame = CGRectZero;
        [[cancelButton layer]setCornerRadius:7.0f];
        //[[cancelButton layer]setBorderWidth:1.0f];
        [[cancelButton layer]setBorderColor:[UIColor grayColor].CGColor];
        [[cancelButton layer]setMasksToBounds:TRUE];
        [cancelButton setBackgroundColor:[UIColor whiteColor]];
        cancelButton.clipsToBounds = YES;
        [cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
        [cancelButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        [cancelButton setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self addSubview:cancelButton];
        _cancelButton = cancelButton;
        
        
        NSDictionary *views = NSDictionaryOfVariableBindings(galleryUIView ,alertTitleLabel, galleryCollectionView, takePhotoButton, cameraRollButton, iCloudButton, cancelButton);
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-7-[galleryUIView]-7-|" options:0 metrics:0 views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[alertTitleLabel]-0-|" options:0 metrics:0 views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[galleryCollectionView]-0-|" options:0 metrics:0 views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[takePhotoButton]-0-|" options:0 metrics:0 views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[cameraRollButton]-0-|" options:0 metrics:0 views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[iCloudButton]-0-|" options:0 metrics:0 views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-7-[cancelButton]-7-|" options:0 metrics:0 views:views]];
        
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:[galleryUIView(==231)]-5-[cancelButton(==44)]-5-|"] options:0 metrics:0 views:views]];
        
//        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[alertTitleLabel]-10-[takePhotoButton]-0-[cameraRollButton]-0-[iCloudButton]|" options:0 metrics:0 views:views]];
        
       
        
                [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[alertTitleLabel(==33)]-0-[galleryCollectionView(==66)]-0-[takePhotoButton(==44)]-0-[cameraRollButton(==44)]-0-[iCloudButton(==44)]-0-|" options:0 metrics:0 views:views]];

        
        
        
        //NSLog(@" height: %f", screenHeight); // = 368.0
        
        
    }
    return self;
}

-(CGSize)intrinsicContentSize {
    
    return CGSizeMake(screenHeight, UIViewNoIntrinsicMetric);
}

@end
