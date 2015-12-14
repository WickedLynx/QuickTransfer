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
#import "QTRImagesInfoData.h"
#import "QTRRecentLogsViewController.h"
#import "QTRHelper.h"

#import <AssetsLibrary/AssetsLibrary.h>


@interface QTRShowGalleryViewController () <UICollectionViewDataSource,UICollectionViewDelegate,UICollectionViewDelegateFlowLayout,PHPhotoLibraryChangeObserver> {

    UICollectionView *galleryCollectionView;
    NSMutableArray *images;
    NSMutableArray *assets;
    NSArray *totalImages;
    UICollectionViewFlowLayout *layout;
    
    QTRBonjourClient *_client;
    QTRBonjourServer *_server;
    NSMutableArray *_connectedServers;
    NSMutableArray *_connectedClients;
    NSMutableDictionary *_selectedRecivers;
    QTRUser *_localUser;
    QTRUser *_selectedUser;
    
    ALAssetsLibrary *_assetsLibrary;
    

}



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
    
    _client = self.reciversInfo._client;
    _server = self.reciversInfo._server;
    _connectedServers = self.reciversInfo._connectedServers;
    _connectedClients = self.reciversInfo._connectedClients;
    _selectedRecivers = self.reciversInfo._selectedRecivers;
    _localUser = self.reciversInfo._localUser;
    _selectedUser = self.reciversInfo._selectedUser;
    _assetsLibrary = [[ALAssetsLibrary alloc] init];
    

    [self.view setBackgroundColor:[UIColor colorWithRed:76.f/255.f green:76.f/255.f blue:76.f/255.f alpha:1.00f]];
    [self setTitle:@"Camera Roll"];
    
    [self.navigationController.navigationBar setBarTintColor:[UIColor colorWithRed:85.f/255.f green:85.f/255.f blue:85.f/255.f alpha:1.00f]];
    
    
    UIButton *leftCustomButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [leftCustomButton setImage:[UIImage imageNamed:@"back_arrow"] forState:UIControlStateNormal];
    [leftCustomButton setTitle:@" Back" forState:UIControlStateNormal];
    [leftCustomButton setTitleColor:[UIColor colorWithRed:32.f/255.f green:149.f/255.f blue:242.f/255.f alpha:1.00f] forState:UIControlStateNormal];
    leftCustomButton.frame = CGRectMake(0.f, 0.f, 60.0f, 30.0f);
    [leftCustomButton addTarget:self action:@selector(backButtonAction) forControlEvents:UIControlEventTouchUpInside];

    
    UIBarButtonItem *leftBarButton = [[UIBarButtonItem alloc] init];
    [leftBarButton setCustomView:leftCustomButton];
    self.navigationItem.leftBarButtonItem=leftBarButton;
    
    QTRRightBarButtonView *customRightBarButton = [[QTRRightBarButtonView alloc]initWithFrame:CGRectZero];
    [customRightBarButton setUserInteractionEnabled:NO];
    
    UIButton *barButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [barButton addTarget:self action:@selector(logsBarButton) forControlEvents:UIControlEventTouchUpInside];
    barButton.frame = customRightBarButton.frame;
    [customRightBarButton addSubview:barButton];
    
    UIBarButtonItem *rightBarButton = [[UIBarButtonItem alloc] initWithCustomView:customRightBarButton];
    [self.navigationItem setRightBarButtonItem:rightBarButton];
    
   
    layout = [[UICollectionViewFlowLayout alloc] init];
    [layout setMinimumInteritemSpacing:0.0f];
    [layout setMinimumLineSpacing:0.0f];
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
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[galleryCollectionView]|" options:0 metrics:0 views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-7-[button]-7-|" options:0 metrics:0 views:views]];

    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[galleryCollectionView]-5-[button(==44)]-5-|" options:0 metrics:0 views:views]];

    [self getPhotos];
    
}

#pragma mark - Button Action methods

-(void)homeButton {
    
    [self.navigationController popToRootViewControllerAnimated:YES];
}

-(void)getPhotos {

    self.requestOptions = [[PHImageRequestOptions alloc] init];
    self.requestOptions.resizeMode   = PHImageRequestOptionsResizeModeExact;
    self.requestOptions.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    
    self.requestOptions.synchronous = false;
    
    PHFetchResult *assetsFetchResult = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:nil];
    PHImageManager *manager = [PHImageManager defaultManager];
    images = [NSMutableArray arrayWithCapacity:[assetsFetchResult count]];
    assets = [NSMutableArray arrayWithCapacity:[assetsFetchResult count]];
    
    __block QTRImagesInfoData *imageInfoData;
    //__block int i;
    
    for (PHAsset *asset in assetsFetchResult) {
        
        //for(i = 0; i < 10 ; i++) {
            
            //PHAsset *asset = [assetsFetchResult objectAtIndex:i];
        
        
        [manager requestImageForAsset:asset
                           targetSize:CGSizeMake(160, 160)
                          contentMode:PHImageContentModeDefault
                              options:self.requestOptions
                        resultHandler:^void(UIImage *image, NSDictionary *info) {
                            
                            imageInfoData = [[QTRImagesInfoData alloc]init];
                            imageInfoData.finalImage = image;
                            imageInfoData.imageInfo = info;
                            imageInfoData.imageAsset = asset;
                            
                            if (imageInfoData != nil) {
                                [images addObject:imageInfoData];
                                [galleryCollectionView reloadData];
                            }

                            
                        }];
        
            }
}



-(void)logsBarButton {
    
    QTRRecentLogsViewController *recentLogs = [[QTRRecentLogsViewController alloc]init];
    [self.navigationController pushViewController:recentLogs animated:YES];
    
}


-(void)sendData {
    
    if ([self.selectedImages count] > 0) {
        totalImages = [[NSArray alloc]initWithArray:[self.selectedImages allValues]];

        for (QTRImagesInfoData *selectedImage in totalImages) {
            [self sendDataToSelectedUser:selectedImage];
        }
        
        [self.selectedImages removeAllObjects];
        [galleryCollectionView reloadData];
        
    } else {
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Message" message:@"First Select Atleast One Image" preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
        [alertController addAction:ok];
        
        [self presentViewController:alertController animated:YES completion:nil];
    }

}

-(void)backButtonAction {

    [self.navigationController popToRootViewControllerAnimated:YES];

}

#pragma mark - UICollectionViewDataSource methods

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    
    int noOfItems = (self.view.frame.size.width) / 80;
    float totalRemSpace = self.view.frame.size.width - (noOfItems * 80);
    
    if (totalRemSpace == 0.0) {
        
        [layout setMinimumLineSpacing:0.0f];
        return UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 0.0f);

    }
    else {
        CGFloat gap = (CGFloat)totalRemSpace / (CGFloat)(noOfItems + 1);
        [layout setMinimumLineSpacing:gap];

    
    return UIEdgeInsetsMake( (gap * 2.0f), gap, (gap * 2.0f), gap);

    }
}
-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
    
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    
    return [images count];
    
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    QTRGalleryCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    
    QTRImagesInfoData *imageData = [images objectAtIndex:indexPath.row ];
    cell.backgroundView = [[UIImageView alloc] initWithImage:[ (UIImage *) imageData.finalImage stretchableImageWithLeftCapWidth:0.0 topCapHeight:5.0] ];
 
    return cell;
    
}


- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(80.0f, 80.0f);
}


#pragma mark - UICollectionView Delegate methods

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
 
    QTRImagesInfoData *imageData = [images objectAtIndex:indexPath.row ];
    UIImage *img = imageData.finalImage;
    
    [self.selectedImages setObject:imageData forKey:[NSString stringWithFormat:@"%@",img.imageAsset]];
    
}



- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    QTRImagesInfoData *imageData = [images objectAtIndex:indexPath.row ];
    UIImage *img = imageData.finalImage;
    
    if ([self.selectedImages count] > 0) {
        [self.selectedImages removeObjectForKey:[NSString stringWithFormat:@"%@",img.imageAsset]];
    }
    
}

#pragma mark - Transfer Selected files to selected user

- (void)sendDataToSelectedUser:(QTRImagesInfoData *)sendingImage {
    
    self.requestOptions = [[PHImageRequestOptions alloc] init];
    self.requestOptions.resizeMode   = PHImageRequestOptionsResizeModeExact;
    self.requestOptions.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    
    self.requestOptions.synchronous = true;
    NSURL *referenceURL = [sendingImage.imageInfo objectForKey:@"PHImageFileURLKey"];
    

    [[PHImageManager defaultManager] requestImageDataForAsset:sendingImage.imageAsset
                                                      options:self.requestOptions
                                                resultHandler:
     ^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info) {
         
         NSURL *localURL = [self uniqueURLForFileWithName:[referenceURL lastPathComponent]];
         
         [imageData writeToURL:localURL atomically:YES];
         
         NSArray *totalRecivers = [_selectedRecivers allValues];
         _selectedUser = nil;
         
         for (QTRUser *currentUser in totalRecivers) {
             
             _selectedUser = currentUser;
             
             if ([_connectedClients containsObject:_selectedUser]) {
                 [_server sendFileAtURL:localURL toUser:_selectedUser];
                 
             } else if ([_connectedServers containsObject:_selectedUser]) {
                 [_client sendFileAtURL:localURL toUser:_selectedUser];
                 
             } else {
                 UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@" is not connected anymore"] delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil, nil];
                 [alert show];
             }
             
             _selectedUser = nil;
         }
    
     }];
    
}



- (NSURL *)uniqueURLForFileWithName:(NSString *)fileName {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSURL *cachesURL = [QTRHelper fileCacheDirectory];
    
    NSString *filePath = [[cachesURL path] stringByAppendingPathComponent:fileName];
    
    if ([fileManager fileExistsAtPath:filePath]) {
        NSString *name = [[filePath lastPathComponent] stringByDeletingPathExtension];
        NSString *extension = [filePath pathExtension];
        NSString *nameWithExtension = [name stringByAppendingPathExtension:extension];
        NSString *tempName = name;
        int fileCount = 0;
        while ([fileManager fileExistsAtPath:filePath]) {
            ++fileCount;
            tempName = [name stringByAppendingFormat:@"%d", fileCount];
            nameWithExtension = [tempName stringByAppendingPathExtension:extension];
            filePath = [[cachesURL path] stringByAppendingPathComponent:nameWithExtension];
        }
    }
    
    
    return [NSURL fileURLWithPath:filePath];
}


#pragma mark - PHPhoto Observer

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
            [galleryCollectionView reloadData];
            
        }];
        
    });
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
