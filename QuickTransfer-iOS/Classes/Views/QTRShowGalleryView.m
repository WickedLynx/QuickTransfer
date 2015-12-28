//
//  QTRShowGalleryView.m
//  QuickTransfer
//
//  Created by Tarun Yadav on 28/12/15.
//  Copyright © 2015 Laughing Buddha Software. All rights reserved.
//

#import "QTRShowGalleryView.h"

@implementation QTRShowGalleryView

- (id)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    
    if (self != nil) {
        
        UICollectionViewFlowLayout *galleryCollectionViewLayout;
        galleryCollectionViewLayout = [[UICollectionViewFlowLayout alloc] init];
        [galleryCollectionViewLayout setMinimumInteritemSpacing:0.0f];
        [galleryCollectionViewLayout setMinimumLineSpacing:0.0f];
        galleryCollectionViewLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
        _galleryCollectionViewLayout = galleryCollectionViewLayout;
        
        UICollectionView *galleryCollectionView;
        galleryCollectionView = [[UICollectionView alloc]initWithFrame:CGRectZero collectionViewLayout:galleryCollectionViewLayout];
        galleryCollectionView.allowsMultipleSelection = YES;
        [galleryCollectionView setBackgroundColor:[UIColor colorWithRed:76.f/255.f green:76.f/255.f blue:76.f/255.f alpha:1.00f]];
        [galleryCollectionView setTranslatesAutoresizingMaskIntoConstraints:NO];
        
        [self addSubview:galleryCollectionView];
        _galleryCollectionView = galleryCollectionView;
        
        UIButton *sendButton = [UIButton buttonWithType:UIButtonTypeCustom];
        sendButton.frame = CGRectZero;
        [[sendButton layer]setCornerRadius:7.0f];
        [[sendButton layer]setBorderWidth:1.0f];
        [[sendButton layer]setBorderColor:[UIColor whiteColor].CGColor];
        [[sendButton layer]setMasksToBounds:TRUE];
        sendButton.clipsToBounds = YES;
        [sendButton setTitle:@"Send" forState:UIControlStateNormal];
        [sendButton setBackgroundColor:[UIColor colorWithRed:76.f/255.f green:76.f/255.f blue:76.f/255.f alpha:1.00f]];
        [sendButton setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self addSubview:sendButton];
        _sendButton = sendButton;
        
        
        NSDictionary *views = NSDictionaryOfVariableBindings(galleryCollectionView, sendButton);
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[galleryCollectionView]|" options:0 metrics:0 views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-7-[sendButton]-7-|" options:0 metrics:0 views:views]];
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[galleryCollectionView]-5-[sendButton(==44)]-5-|" options:0 metrics:0 views:views]];
        

        
    }
    
    return self;
}


@end
