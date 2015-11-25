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
        [layout setMinimumInteritemSpacing:5.0f];
        [layout setMinimumLineSpacing:20.0f];
        layout.scrollDirection = UICollectionViewScrollDirectionVertical;
        
        UICollectionView *aCollectionView = [[UICollectionView alloc]initWithFrame:CGRectZero collectionViewLayout:layout];
        [aCollectionView setTranslatesAutoresizingMaskIntoConstraints:NO];
        
        [self addSubview:aCollectionView];
        _devicesCollectionView = aCollectionView;
        
//        UITableView *aTableView = [[UITableView alloc] initWithFrame:self.bounds];
//        
//        [aTableView setAutoresizingMask:(UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth)];
//        
//        
//        [self addSubview:aTableView];
//        _devicesTableView = aTableView;
        
        UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectZero];
        [searchBar setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self addSubview:searchBar];
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectZero;
        [button setTitle:@"Send" forState:UIControlStateNormal];
        [button setBackgroundColor:[UIColor purpleColor]];
        [button setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self addSubview:button];
        _sendButton = button;
        
        
        NSDictionary *views = NSDictionaryOfVariableBindings(button,aCollectionView,searchBar);
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[button]|" options:0 metrics:0 views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-5-[aCollectionView]-5-|" options:0 metrics:0 views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[searchBar]|" options:0 metrics:0 views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-200-[searchBar]-5-[aCollectionView]-5-[button]-0-|" options:0 metrics:0 views:views]];
        
        
        
        
        
        
    }

    return self;
}


@end
