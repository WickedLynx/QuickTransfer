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

    NSMutableArray *images;


}

@property (nonatomic, strong) NSArray *sectionFetchResults;
@property (nonatomic, strong) NSArray *sectionLocalizedTitles;


@end



static NSString * const AllPhotosReuseIdentifier = @"AllPhotosCell";
static NSString * const CollectionCellReuseIdentifier = @"CollectionCell";

static NSString * const AllPhotosSegue = @"showAllPhotos";
static NSString * const CollectionSegue = @"showCollection";
static NSString *cellIdentifier = @"cellIdentifier";


@implementation QTRActionSheetGalleryView

- (id)initWithFrame:(CGRect)aRect
{
    if ((self = [super initWithFrame:aRect])) {
        
        //self.frame = CGRectMake(0.0f, 0.0f, 320.0f, 66.0f);
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
        //customIndicatorView.center = aCollectionView.center;
        [self addSubview: customIndicatorView];
        _actionCustomIndicatorView = customIndicatorView;
        
        [_actionCustomIndicatorView startAnimating];
                
        NSDictionary *views = NSDictionaryOfVariableBindings(aCollectionView, customIndicatorView);
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[aCollectionView]-0-|" options:0 metrics:0 views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[aCollectionView]-0-|" options:0 metrics:0 views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[customIndicatorView]-0-|" options:0 metrics:0 views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[customIndicatorView]-0-|" options:0 metrics:0 views:views]];
        
        [self getMedia];
        
    }
    return self;
}


#pragma mark - UICollectionViewDataSource methods

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
    
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    
    //    return [_connectedServers count] + [_connectedClients count];
    return [images count];
    //return 3;
    
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    QTRAlertControllerCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    
    //QTRUser *theUser = [self userAtIndexPath:indexPath isServer:NULL];
    
    //    [cell.connectedDeviceName setText:[theUser name]];
    
    
    //cell.backgroundColor = [UIColor redColor];
    //NSLog(@"Cell: %@",cell.description);
    
    cell.backgroundView = [[UIImageView alloc] initWithImage:[ (UIImage *) [images objectAtIndex:indexPath.row] stretchableImageWithLeftCapWidth:0.0 topCapHeight:5.0] ];
    
    
    
    
    
    return cell;
    
}




- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(66.0f, 66.0f);
}


#pragma mark - UICollectionViewDelegate methods


//- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
//{
//    QTRAlertControllerCollectionViewCell *cell = (QTRAlertControllerCollectionViewCell *)[[_devicesView devicesCollectionView] cellForItemAtIndexPath:indexPath];
//    cell.connectedDeviceName.textColor = [UIColor whiteColor];
//
//}
//

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Cell %ld Selected",(long)indexPath.row);
    QTRAlertControllerCollectionViewCell *cell = (QTRAlertControllerCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    [self.delegate QTRActionSheetGalleryView:self didCellSelected:YES withCollectionCell:cell];
}


-(void)getMedia {
    PHFetchOptions *allPhotosOptions = [[PHFetchOptions alloc] init];
    allPhotosOptions.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]];
    
    PHFetchResult *allPhotos = [PHAsset fetchAssetsWithOptions:allPhotosOptions];
    
    PHFetchResult *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    
    PHFetchResult *topLevelUserCollections = [PHCollectionList fetchTopLevelUserCollectionsWithOptions:nil];
    
    // Store the PHFetchResult objects and localized titles for each section.
    self.sectionFetchResults = @[allPhotos, smartAlbums, topLevelUserCollections];
    self.sectionLocalizedTitles = @[@"", NSLocalizedString(@"Smart Albums", @""), NSLocalizedString(@"Albums", @"")];
    
    [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
    
    [self getPhotos];
}

-(void)getPhotos {
    
    
    self.requestOptions = [[PHImageRequestOptions alloc] init];
    self.requestOptions.resizeMode   = PHImageRequestOptionsResizeModeExact;
    self.requestOptions.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    
    self.requestOptions.synchronous = true;
    
    PHFetchResult *assetsFetchResult = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:nil];
    PHImageManager *manager = [PHImageManager defaultManager];
    images= [NSMutableArray arrayWithCapacity:[assetsFetchResult count]];
    
    __block UIImage *ima;
    
    for (PHAsset *asset in assetsFetchResult) {
        // Do something with the asset
        
        [manager requestImageForAsset:asset
                           targetSize:PHImageManagerMaximumSize
                          contentMode:PHImageContentModeDefault
                              options:self.requestOptions
                        resultHandler:^void(UIImage *image, NSDictionary *info) {
                            ima = image;
                            

                        }];
        
        if (ima != nil) {
            [images addObject:ima];
        }
    }
    [aCollectionView reloadData];
    [_actionCustomIndicatorView stopAnimating];

    
}

- (void)photoLibraryDidChange:(PHChange *)changeInstance {
    /*
     Change notifications may be made on a background queue. Re-dispatch to the
     main queue before acting on the change as we'll be updating the UI.
     */
    dispatch_async(dispatch_get_main_queue(), ^{
        // Loop through the section fetch results, replacing any fetch results that have been updated.
        NSMutableArray *updatedSectionFetchResults = [self.sectionFetchResults mutableCopy];
        __block BOOL reloadRequired = NO;
        
        [self.sectionFetchResults enumerateObjectsUsingBlock:^(PHFetchResult *collectionsFetchResult, NSUInteger index, BOOL *stop) {
            PHFetchResultChangeDetails *changeDetails = [changeInstance changeDetailsForFetchResult:collectionsFetchResult];
            
            if (changeDetails != nil) {
                [updatedSectionFetchResults replaceObjectAtIndex:index withObject:[changeDetails fetchResultAfterChanges]];
                reloadRequired = YES;
            }
            [self getPhotos];
            [aCollectionView reloadData];
            
        }];
        
    });
}


@end
