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
        
        self.loadDeviceView = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        [aCollectionView addSubview:self.loadDeviceView];

       
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
        
        NSDictionary *views = NSDictionaryOfVariableBindings(button,aCollectionView,searchBar);
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-7-[button]-7-|" options:0 metrics:0 views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[aCollectionView]|" options:0 metrics:0 views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[searchBar]|" options:0 metrics:0 views:views]];
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-64-[searchBar]-0-[aCollectionView]-5-[button(==44)]-5-|" options:0 metrics:0 views:views]];
            
        
    }

    return self;
}



@end
