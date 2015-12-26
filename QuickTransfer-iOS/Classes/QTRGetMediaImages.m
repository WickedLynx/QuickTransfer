//
//  QTRGetMediaImages.m
//  QuickTransfer
//
//  Created by Tarun Yadav on 25/12/15.
//  Copyright © 2015 Laughing Buddha Software. All rights reserved.
//

#import "QTRGetMediaImages.h"
#import "QTRImagesInfoData.h"



    UICollectionView *galleryCollectionView;
    NSMutableArray *fetchImagesArray;
    NSArray *sectionFetchResults;
    NSArray *sectionLocalizedTitles;




@implementation QTRGetMediaImages 


- (NSMutableArray *)fetchMediaImages {
    
    if (fetchImagesArray.count >1 ) {
        return fetchImagesArray;
    }
    
    else {
        return nil;
    }
    

}

- (void)downloadMedia {
    [self getMedia];

}



- (void)getMedia {
    
    PHFetchOptions *allPhotosOptions = [[PHFetchOptions alloc] init];
    allPhotosOptions.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]];
    
    PHFetchResult *allPhotos = [PHAsset fetchAssetsWithOptions:allPhotosOptions];
    
    PHFetchResult *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    
    PHFetchResult *topLevelUserCollections = [PHCollectionList fetchTopLevelUserCollectionsWithOptions:nil];
    
    sectionFetchResults = @[allPhotos, smartAlbums, topLevelUserCollections];
    sectionLocalizedTitles = @[@"", NSLocalizedString(@"Smart Albums", @""), NSLocalizedString(@"Albums", @"")];
    
    [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
    
    [self getPhotos];
}

-(void)getPhotos {
        
    PHImageRequestOptions *requestOptions;
    requestOptions = [[PHImageRequestOptions alloc] init];
    requestOptions.resizeMode   = PHImageRequestOptionsResizeModeExact;
    requestOptions.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    
    requestOptions.synchronous = false;
    
    PHFetchResult *assetsFetchResult = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:nil];
    PHImageManager *manager = [PHImageManager defaultManager];
    
    fetchImagesArray= [NSMutableArray arrayWithCapacity:10];

    __block QTRImagesInfoData *imageInfoData;
    
    
    for (PHAsset *asset in assetsFetchResult) {
        [manager requestImageForAsset:asset
                           targetSize:CGSizeMake(160, 160)
                          contentMode:PHImageContentModeDefault
                              options:requestOptions
                        resultHandler:^void(UIImage *image, NSDictionary *info) {
                            
                            imageInfoData = [[QTRImagesInfoData alloc]init];
                            imageInfoData.finalImage = image;
                            imageInfoData.imageInfo = info;
                            imageInfoData.imageAsset = asset;
                            
                            if (imageInfoData != nil) {
                                [fetchImagesArray addObject:imageInfoData];
                            }
                        }];
    }
}

- (void)photoLibraryDidChange:(PHChange *)changeInstance {
    /*
     Change notifications may be made on a background queue. Re-dispatch to the
     main queue before acting on the change as we'll be updating the UI.
     */
    dispatch_async(dispatch_get_main_queue(), ^{
        // Loop through the section fetch results, replacing any fetch results that have been updated.
        NSMutableArray *updatedSectionFetchResults = [sectionFetchResults mutableCopy];
        __block BOOL reloadRequired = NO;
        
        [sectionFetchResults enumerateObjectsUsingBlock:^(PHFetchResult *collectionsFetchResult, NSUInteger index, BOOL *stop) {
            PHFetchResultChangeDetails *changeDetails = [changeInstance changeDetailsForFetchResult:collectionsFetchResult];
            
            if (changeDetails != nil) {
                [updatedSectionFetchResults replaceObjectAtIndex:index withObject:[changeDetails fetchResultAfterChanges]];
                reloadRequired = YES;
            }

            [self getPhotos];
            
        }];
        
    });
}


- (void)dealloc {
    
    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];

}


@end
