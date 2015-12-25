//
//  QTRActionSheetGalleryView.m
//  QuickTransfer
//
//  Created by Tarun Yadav on 27/11/15.
//  Copyright © 2015 Laughing Buddha Software. All rights reserved.
//

#import "QTRActionSheetGalleryView.h"
#import "QTRAlertControllerCollectionViewCell.h"

@interface QTRActionSheetGalleryView()<PHPhotoLibraryChangeObserver> {
    
    UICollectionView *aCollectionView;
    UIActivityIndicatorView *customIndicatorView;
}


@end



static NSString * const AllPhotosReuseIdentifier = @"AllPhotosCell";
static NSString * const CollectionCellReuseIdentifier = @"CollectionCell";

static NSString * const AllPhotosSegue = @"showAllPhotos";
static NSString * const CollectionSegue = @"showCollection";
static NSString *cellIdentifier = @"CellIdentifier";


@implementation QTRActionSheetGalleryView

- (id)initWithFrame:(CGRect)aRect
{
    if ((self = [super initWithFrame:aRect])) {
        
        self.backgroundColor = [UIColor whiteColor];        
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        [layout setMinimumInteritemSpacing:NO];
        [layout setMinimumLineSpacing:1.0f];
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        
        aCollectionView = [[UICollectionView alloc]initWithFrame:CGRectZero collectionViewLayout:layout];
        [aCollectionView setTranslatesAutoresizingMaskIntoConstraints:NO];
        [aCollectionView setShowsHorizontalScrollIndicator:NO];
        aCollectionView.frame = self.frame;
        
        [self addSubview:aCollectionView];
        _actionControllerCollectionView = aCollectionView;
                
        customIndicatorView = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        customIndicatorView.frame = CGRectZero;
        [customIndicatorView setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self addSubview: customIndicatorView];
        _actionCustomIndicatorView = customIndicatorView;
        
        [_actionCustomIndicatorView startAnimating];
                
        NSDictionary *views = NSDictionaryOfVariableBindings(aCollectionView, customIndicatorView);
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[aCollectionView]-0-|" options:0 metrics:0 views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[aCollectionView]-0-|" options:0 metrics:0 views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[customIndicatorView]-0-|" options:0 metrics:0 views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[customIndicatorView]-0-|" options:0 metrics:0 views:views]];
        
    }
    return self;
}


#pragma mark - UICollectionViewDataSource methods

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
    
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    
    return [_fetchingImageArray count];
    
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    QTRAlertControllerCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    
    QTRImagesInfoData *imageData = [_fetchingImageArray objectAtIndex:indexPath.row ];
    cell.backgroundView = [[UIImageView alloc] initWithImage:[ (UIImage *) imageData.finalImage stretchableImageWithLeftCapWidth:0.0 topCapHeight:5.0] ];
    
    return cell;
    
}


- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(66.0f, 66.0f);
}

- (void)stopIndicatorViewAnimation {

    [_actionCustomIndicatorView stopAnimating];

}


#pragma mark - UICollectionViewDelegate methods

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    QTRAlertControllerCollectionViewCell *cell = (QTRAlertControllerCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    
    QTRImagesInfoData *imageData = [_fetchingImageArray objectAtIndex:indexPath.row ];
    [self.delegate QTRActionSheetGalleryView:self didCellSelected:YES withCollectionCell:cell selectedImage:imageData];
   
    
}



@end
