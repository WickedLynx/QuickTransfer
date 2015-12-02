//
//  QTRShowGalleryViewController.m
//  QuickTransfer
//
//  Created by Tarun Yadav on 26/11/15.
//  Copyright © 2015 Laughing Buddha Software. All rights reserved.
//

#import "QTRShowGalleryViewController.h"
#import "QTRGalleryCollectionViewCell.h"
#import "QTRRightBarButtonView.h"

@interface QTRShowGalleryViewController () <UICollectionViewDataSource,UICollectionViewDelegate,UICollectionViewDelegateFlowLayout,PHPhotoLibraryChangeObserver> {

    UICollectionView *galleryCollectionView;
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
int totalImages;


@implementation QTRShowGalleryViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.selectedImages = [[NSMutableDictionary alloc]init];
    
    [self.view setBackgroundColor:[UIColor colorWithRed:76.f/255.f green:76.f/255.f blue:76.f/255.f alpha:1.00f]];
    [self setTitle:@"Camera Roll"];
    
    [self.navigationController.navigationBar setBarTintColor:[UIColor colorWithRed:85.f/255.f green:85.f/255.f blue:85.f/255.f alpha:1.00f]];
    
    
    UIBarButtonItem *leftBarButton = [[UIBarButtonItem alloc] initWithTitle:@"< Back" style:UIBarButtonItemStylePlain target:self action:@selector(homeButton)];
    
    [leftBarButton setTintColor:[UIColor colorWithRed:32.f/255.f green:149.f/255.f blue:242.f/255.f alpha:1.00f]];
    [self.navigationItem setLeftBarButtonItem:leftBarButton];
    
    QTRRightBarButtonView *customRightBarButton = [[QTRRightBarButtonView alloc]initWithFrame:CGRectZero];
    [customRightBarButton setUserInteractionEnabled:NO];
    
    UIButton *barButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [barButton addTarget:self action:@selector(logsBarButton) forControlEvents:UIControlEventTouchUpInside];
    barButton.frame = customRightBarButton.frame;
    [customRightBarButton addSubview:barButton];
    
    UIBarButtonItem *rightBarButton = [[UIBarButtonItem alloc] initWithCustomView:customRightBarButton];
    [self.navigationItem setRightBarButtonItem:rightBarButton];
    
   
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    [layout setMinimumInteritemSpacing:2.0f];
    [layout setMinimumLineSpacing:2.0f];
    layout.scrollDirection = UICollectionViewScrollDirectionVertical;
    
    galleryCollectionView = [[UICollectionView alloc]initWithFrame:CGRectZero collectionViewLayout:layout];
    galleryCollectionView.delegate = self;
    galleryCollectionView.dataSource = self;
    galleryCollectionView.allowsMultipleSelection = YES;
    [galleryCollectionView setBackgroundColor:[UIColor colorWithRed:76.f/255.f green:76.f/255.f blue:76.f/255.f alpha:1.00f]];
    [galleryCollectionView setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    [self.view addSubview:galleryCollectionView];
    
    [galleryCollectionView registerClass:[QTRGalleryCollectionViewCell class] forCellWithReuseIdentifier:@"cellIdentifier"];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectZero;
    [[button layer]setCornerRadius:7.0f];
    [[button layer]setBorderWidth:1.0f];
    [[button layer]setBorderColor:[UIColor whiteColor].CGColor];
    [[button layer]setMasksToBounds:TRUE];
    button.clipsToBounds = YES;
    [button setTitle:@"Send" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(sendData) forControlEvents:UIControlEventTouchUpInside];
    [button setBackgroundColor:[UIColor colorWithRed:76.f/255.f green:76.f/255.f blue:76.f/255.f alpha:1.00f]];
    [button setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.view addSubview:button];


    NSDictionary *views = NSDictionaryOfVariableBindings(galleryCollectionView, button);
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-2-[galleryCollectionView]-2-|" options:0 metrics:0 views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-7-[button]-7-|" options:0 metrics:0 views:views]];

    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-2-[galleryCollectionView]-5-[button]-5-|" options:0 metrics:0 views:views]];

    [self getMedia];
    
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
    
    //[[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
    
    [self getPhotos];
}

-(void)homeButton {
    
    [self.navigationController popToRootViewControllerAnimated:YES];

}

-(void)getPhotos {

    
    self.requestOptions = [[PHImageRequestOptions alloc] init];
    self.requestOptions.resizeMode   = PHImageRequestOptionsResizeModeExact;
    self.requestOptions.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    
    self.requestOptions.synchronous = true;
    
    
    
    // this one is key
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
                            //[galleryCollectionView reloadData];
                        }];

        if (ima != nil) {
            [images addObject:ima];
        }
    }
}

#pragma mark - Button Action methods

-(void)logsBarButton {
    
    NSLog(@"Show Logs..");
    
}

-(void)sendData {
    
    if ([self.selectedImages count] > 0) {
        NSLog(@"Total Images: %lu", [self.selectedImages count]);

    } else {
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Message" message:@"First Select Atleast One Image" preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
        [alertController addAction:ok];
        
        [self presentViewController:alertController animated:YES completion:nil];
    }


 
}

#pragma mark - UICollectionViewDataSource methods

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
    
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    
    return [images count];
    
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    QTRGalleryCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    
    cell.backgroundColor = [UIColor greenColor];
    cell.backgroundView = [[UIImageView alloc] initWithImage:[ (UIImage *) [images objectAtIndex:indexPath.row] stretchableImageWithLeftCapWidth:0.0 topCapHeight:5.0] ];
 
    return cell;
    
}


- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(77.5f, 77.5f);
}


#pragma mark - UICollectionViewDelegate methods

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    //QTRHomeCollectionViewCell *cell = (QTRHomeCollectionViewCell *)[[_devicesView devicesCollectionView] cellForItemAtIndexPath:indexPath];
    //cell.connectedDeviceName.textColor = [UIColor colorWithRed:32.f/255.f green:149.f/255.f blue:242.f/255.f alpha:1.00f];
    
    UIImage *im = [images objectAtIndex:indexPath.row];
    
    [self.selectedImages setObject:im forKey:[NSString stringWithFormat:@"%@",im.imageAsset]];
    
    
    NSString *temp = [NSString stringWithFormat:@"%@",im.imageAsset];
    
    NSLog(@" %@ ",temp);
    
    NSLog(@"Cell Selected..");
    
}



- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
//    QTRHomeCollectionViewCell *cell = (QTRHomeCollectionViewCell *)[[_devicesView devicesCollectionView] cellForItemAtIndexPath:indexPath];
//    cell.connectedDeviceName.textColor = [UIColor whiteColor];
    
    UIImage *im = [images objectAtIndex:indexPath.row];
    
    if ([self.selectedImages count] > 0) {
        [self.selectedImages removeObjectForKey:[NSString stringWithFormat:@"%@",im.imageAsset]];
    }
    

    
    NSLog(@"Cell deselected..");
    
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
            [self getImages];
//            [galleryCollectionView reloadData];
            
        }];
        
        NSLog(@"hello : %@",[_sectionFetchResults objectAtIndex:0]);
        
    });
}

-(void)getImages {
    
    self.requestOptions = [[PHImageRequestOptions alloc] init];
    self.requestOptions.resizeMode   = PHImageRequestOptionsResizeModeExact;
    self.requestOptions.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    
    self.requestOptions.synchronous = true;
    
    
    
    // this one is key
    self.requestOptions.synchronous = true;
    
    NSLog(@"hello _sectionFetchResults: %@",_sectionFetchResults);
    PHFetchResult *fetchResult = self.sectionFetchResults[0];
    NSLog(@"hello fetchResult: %@",fetchResult);
    
    PHCollection *collection = fetchResult[0];
    NSLog(@"hello collection: %@",collection);
    
    //PHAssetCollection *assetCollection = (PHAssetCollection *)collection;
    //PHFetchResult *assetsFetchResult = [PHAsset fetchAssetsInAssetCollection:assetCollection options:nil];
    PHFetchResult *assetsFetchResult = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:nil];
    
    PHAsset *asset = [assetsFetchResult objectAtIndex:0];
    
    NSLog(@"Asset Object %@",asset);
    
    //assets = [NSMutableArray arrayWithArray:assets];
    PHImageManager *manager = [PHImageManager defaultManager];
    images= [NSMutableArray arrayWithCapacity:[assetsFetchResult count]];
    
    // assets contains PHAsset objects.
    __block UIImage *ima;
    
    for (PHAsset *asset in assetsFetchResult) {
        // Do something with the asset
        
        [manager requestImageForAsset:asset
                           targetSize:PHImageManagerMaximumSize
                          contentMode:PHImageContentModeDefault
                              options:self.requestOptions
                        resultHandler:^void(UIImage *image, NSDictionary *info) {
                            ima = image;
                            //[galleryCollectionView reloadData];
                        }];
        
        [images addObject:ima];
        
        NSLog(@"Image: %@",ima);
        
    }

}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
