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
        
        UICollectionView *aCollectionView = [[UICollectionView alloc]initWithFrame:CGRectZero collectionViewLayout:layout];
        [aCollectionView setTranslatesAutoresizingMaskIntoConstraints:NO];
        
        [self addSubview:aCollectionView];
        _devicesCollectionView = aCollectionView;
       
        UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectZero];
        [searchBar setTranslatesAutoresizingMaskIntoConstraints:NO];
        searchBar.layer.borderWidth = 0.0f;
        searchBar.placeholder = @"Search";
        [searchBar setBackgroundColor:[UIColor colorWithRed:55.f/255.f green:55.f/255.f blue:55.f/255.f alpha:1.00f]];
        [searchBar setBarTintColor:[UIColor colorWithRed:55.f/255.f green:55.f/255.f blue:55.f/255.f alpha:1.00f]];
        [self addSubview:searchBar];
        _searchBar =searchBar;
        
       
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectZero;
        [[button layer]setCornerRadius:7.0f];
        [[button layer]setBorderWidth:1.0f];
        [[button layer]setBorderColor:[UIColor whiteColor].CGColor];
        [[button layer]setMasksToBounds:TRUE];
        button.clipsToBounds = YES;
        [button setTitle:@"Next" forState:UIControlStateNormal];
        [button setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self addSubview:button];
        _sendButton = button;
        
        UIRefreshControl *refreshControl = [[UIRefreshControl alloc]init];
        [refreshControl setHidden:YES];
        [aCollectionView addSubview:refreshControl];
        _deviceRefreshControl = refreshControl;
        
        UILabel *fetchDevice = [[UILabel alloc]initWithFrame:CGRectZero];
        [fetchDevice setText:@""];
        [fetchDevice setTextAlignment:NSTextAlignmentCenter];
        [fetchDevice setTextColor:[UIColor whiteColor]];
        [fetchDevice setBackgroundColor:[UIColor clearColor]];
        [fetchDevice setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self addSubview:fetchDevice];
        _fetchingDevicesLabel = fetchDevice;
        
        QTRNoConnectedDeviceFoundView *noConnectedDeviceFoundView = [[QTRNoConnectedDeviceFoundView alloc]initWithFrame:self.bounds];
        [noConnectedDeviceFoundView setTranslatesAutoresizingMaskIntoConstraints:NO];
        [noConnectedDeviceFoundView setHidden:YES];
        [self addSubview:noConnectedDeviceFoundView];
        _noConnectedDeviceFoundView = noConnectedDeviceFoundView;
        
        NSDictionary *views = NSDictionaryOfVariableBindings(button, aCollectionView, searchBar, fetchDevice, noConnectedDeviceFoundView);
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-7-[button]-7-|" options:0 metrics:0 views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[aCollectionView]|" options:0 metrics:0 views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[searchBar]|" options:0 metrics:0 views:views]];
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-64-[searchBar]-0-[aCollectionView]-5-[button(==44)]-5-|" options:0 metrics:0 views:views]];
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-50-[fetchDevice]-50-|" options:0 metrics:0 views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-200-[fetchDevice(==44)]" options:0 metrics:0 views:views]];
        
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
