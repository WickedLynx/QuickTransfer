//
//  QTRConnectedDevicesView.m
//  QuickTransfer
//
//  Created by Harshad on 20/02/14.
//  Copyright (c) 2014 Laughing Buddha Software. All rights reserved.
//

#import "QTRConnectedDevicesView.h"

@implementation QTRConnectedDevicesView

- (id)initWithFrame:(CGRect)frame {

    self = [super initWithFrame:frame];

    if (self != nil) {
        
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        [layout setMinimumInteritemSpacing:1.0f];
        [layout setMinimumLineSpacing:20.0f];
        layout.scrollDirection = UICollectionViewScrollDirectionVertical;
        
        UICollectionView *deviceCollectionView = [[UICollectionView alloc]initWithFrame:CGRectZero collectionViewLayout:layout];
        [deviceCollectionView setTranslatesAutoresizingMaskIntoConstraints:NO];
        
        [self addSubview:deviceCollectionView];
        _devicesCollectionView = deviceCollectionView;
       
        UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectZero];
        [searchBar setTranslatesAutoresizingMaskIntoConstraints:NO];
        searchBar.layer.borderWidth = 0.0f;
        searchBar.placeholder = @"Search";
        [searchBar setBackgroundColor:[UIColor colorWithRed:55.f/255.f green:55.f/255.f blue:55.f/255.f alpha:1.00f]];
        [searchBar setBarTintColor:[UIColor colorWithRed:55.f/255.f green:55.f/255.f blue:55.f/255.f alpha:1.00f]];
        [self addSubview:searchBar];
        _searchBar =searchBar;
        
       
        UIButton *sendButton = [UIButton buttonWithType:UIButtonTypeCustom];
        sendButton.frame = CGRectZero;
        [[sendButton layer]setCornerRadius:7.0f];
        [[sendButton layer]setBorderWidth:1.0f];
        [[sendButton layer]setBorderColor:[UIColor whiteColor].CGColor];
        [[sendButton layer]setMasksToBounds:TRUE];
        sendButton.clipsToBounds = YES;
        [sendButton setTitle:@"Next" forState:UIControlStateNormal];
        [sendButton setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self addSubview:sendButton];
        _sendButton = sendButton;
        
        UIRefreshControl *deviceRefreshControl = [[UIRefreshControl alloc]init];
        [deviceRefreshControl setHidden:YES];
        [deviceCollectionView addSubview:deviceRefreshControl];
        _deviceRefreshControl = deviceRefreshControl;
        
        UILabel *fetchDevicesLabel = [[UILabel alloc]initWithFrame:CGRectZero];
        [fetchDevicesLabel setText:@""];
        [fetchDevicesLabel setTextAlignment:NSTextAlignmentCenter];
        [fetchDevicesLabel setTextColor:[UIColor whiteColor]];
        [fetchDevicesLabel setBackgroundColor:[UIColor clearColor]];
        [fetchDevicesLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self addSubview:fetchDevicesLabel];
        _fetchDevicesLabel = fetchDevicesLabel;
        
        QTRNoConnectedDeviceFoundView *noConnectedDeviceFoundView = [[QTRNoConnectedDeviceFoundView alloc]initWithFrame:self.bounds];
        [noConnectedDeviceFoundView setTranslatesAutoresizingMaskIntoConstraints:NO];
        [noConnectedDeviceFoundView setHidden:YES];
        [self addSubview:noConnectedDeviceFoundView];
        _noConnectedDeviceFoundView = noConnectedDeviceFoundView;
        
        NSDictionary *views = NSDictionaryOfVariableBindings(sendButton, deviceCollectionView, searchBar, fetchDevicesLabel, noConnectedDeviceFoundView);
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-7-[sendButton]-7-|" options:0 metrics:0 views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[deviceCollectionView]|" options:0 metrics:0 views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[searchBar]|" options:0 metrics:0 views:views]];
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-64-[searchBar]-0-[deviceCollectionView]-5-[sendButton(==44)]-5-|" options:0 metrics:0 views:views]];
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-50-[fetchDevicesLabel]-50-|" options:0 metrics:0 views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-200-[fetchDevicesLabel(==44)]" options:0 metrics:0 views:views]];
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[noConnectedDeviceFoundView]-0-|" options:0 metrics:0 views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[noConnectedDeviceFoundView]-0-|" options:0 metrics:0 views:views]];
        
    }

    return self;
}

- (void)animatePreviewLabel:(UILabel *)previewMessageLabel {
    CATransition *animation = [CATransition animation];
    animation.duration = 1.2;
    animation.type = kCATransitionReveal;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [previewMessageLabel.layer addAnimation:animation forKey:@"changeTextTransition"];
    
}



@end
