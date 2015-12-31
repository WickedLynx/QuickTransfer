//
//  QTRActionSheetGalleryView.m
//  QuickTransfer
//
//  Created by Tarun Yadav on 27/11/15.
//  Copyright © 2015 Laughing Buddha Software. All rights reserved.
//

#import "QTRActionSheetGalleryView.h"
#import "QTRAlertControllerCollectionViewCell.h"

@interface QTRActionSheetGalleryView() {

    UIActivityIndicatorView *actionCustomIndicatorView;
    UICollectionView *actionControllerCollectionView;
}


@end


static NSString *cellIdentifier = @"CellIdentifier";


@implementation QTRActionSheetGalleryView

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame])) {
        
        self.backgroundColor = [UIColor whiteColor];        
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        [layout setMinimumInteritemSpacing:NO];
        [layout setMinimumLineSpacing:1.0f];
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        
        actionControllerCollectionView = [[UICollectionView alloc]initWithFrame:self.frame collectionViewLayout:layout];
        [actionControllerCollectionView setTranslatesAutoresizingMaskIntoConstraints:NO];
        [actionControllerCollectionView setShowsHorizontalScrollIndicator:NO];
        actionControllerCollectionView.backgroundColor = [UIColor whiteColor];
        [actionControllerCollectionView registerClass:[QTRAlertControllerCollectionViewCell class] forCellWithReuseIdentifier:cellIdentifier];
        [actionControllerCollectionView setDataSource:self];
        [actionControllerCollectionView setDelegate:self];
        [self addSubview:actionControllerCollectionView];
        
        actionCustomIndicatorView = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        actionCustomIndicatorView.frame = CGRectZero;
        [actionCustomIndicatorView setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self addSubview: actionCustomIndicatorView];
       
        
        NSDictionary *views = NSDictionaryOfVariableBindings(actionControllerCollectionView, actionCustomIndicatorView);
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[actionControllerCollectionView]-0-|" options:0 metrics:0 views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[actionControllerCollectionView]-0-|" options:0 metrics:0 views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[actionCustomIndicatorView]-0-|" options:0 metrics:0 views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[actionCustomIndicatorView]-0-|" options:0 metrics:0 views:views]];
        
    }
    return self;
}


#pragma mark - UICollectionViewDataSource methods

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
    
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    
    return 20;
    
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    QTRAlertControllerCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    
    __weak QTRAlertControllerCollectionViewCell *weakCell = cell;
    
    CGSize fetchImageSize = CGSizeMake(600.0, 600.0);
    
    [_fetchPhotoLibrary imageAtIndex:indexPath.row imageWithFullSize:NO imageSize:fetchImageSize completion:^(UIImage * image) {
        weakCell.backgroundView = [[UIImageView alloc] initWithImage:image ];
    }];

    return cell;
    
}


- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(66.0f, 66.0f);
}

#pragma mark - UIActivityIndicator Action methods

- (void)stopIndicatorViewAnimation {

    [actionCustomIndicatorView stopAnimating];

}

- (void)startIndicatorViewAnimation {
    
    [actionCustomIndicatorView startAnimating];
    
}

#pragma mark - UICollectionView Action methods

- (void)reloadUICollectionView {

    [actionControllerCollectionView reloadData];
}


#pragma mark - UICollectionViewDelegate methods

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{


}




@end
