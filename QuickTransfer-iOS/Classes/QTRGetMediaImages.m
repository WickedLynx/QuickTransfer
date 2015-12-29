//
//  QTRGetMediaImages.m
//  QuickTransfer
//
//  Created by Tarun Yadav on 25/12/15.
//  Copyright © 2015 Laughing Buddha Software. All rights reserved.
//

#import "QTRGetMediaImages.h"
#import "QTRImagesInfoData.h"



@interface QTRGetMediaImages() {


    UICollectionView *galleryCollectionView;
    NSMutableArray *fetchImagesArray;
    NSArray *sectionFetchResults;
    NSArray *sectionLocalizedTitles;
    PHFetchResult *assetsFetchResult;

}

@end


@implementation QTRGetMediaImages


- (void)fetchPhotosWithLimit:(NSInteger)fetchLimit completion:(void (^)(NSArray *))completion {
    
    assetsFetchResult = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:nil];

    if (fetchLimit == 0) {
        if (fetchImagesArray.count < assetsFetchResult.count) {
            
            [self getPhotosfromMediaWith:fetchLimit];
        }
        
    }else if (fetchImagesArray.count < fetchLimit) {
        
        [self getPhotosfromMediaWith:fetchLimit];
    }
    
    if (completion != nil) {
        completion(fetchImagesArray);
        
    }

}


-(void)getPhotosfromMediaWith:(NSInteger)fetchImagesLimit {
        
    PHImageRequestOptions *requestOptions;
    requestOptions = [[PHImageRequestOptions alloc] init];
    requestOptions.resizeMode   = PHImageRequestOptionsResizeModeExact;
    requestOptions.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    requestOptions.synchronous = YES;
    
    PHImageManager *manager = [PHImageManager defaultManager];
    NSArray *assetsForFetchLimit;
    
    if (fetchImagesLimit == 0) {
        assetsForFetchLimit = [assetsFetchResult objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, assetsFetchResult.count)]];
        
        fetchImagesArray= [NSMutableArray arrayWithCapacity:assetsFetchResult.count];
        
    } else {
        
        assetsForFetchLimit = [assetsFetchResult objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, fetchImagesLimit)]];
        
        fetchImagesArray= [NSMutableArray arrayWithCapacity:assetsFetchResult.count];
    }
    
    
    for (PHAsset *asset in assetsForFetchLimit) {
        
        [manager requestImageForAsset:asset
                           targetSize:CGSizeMake(160, 160)
                          contentMode:PHImageContentModeDefault
                              options:requestOptions
         
                        resultHandler:^void(UIImage *image, NSDictionary *info) {
                            
                            QTRImagesInfoData *imageInfoData = [[QTRImagesInfoData alloc]init];
                            imageInfoData.finalImage = image;
                            imageInfoData.imageInfo = info;
                            imageInfoData.imageAsset = asset;

                            
                            if (imageInfoData != nil) {
                                [fetchImagesArray addObject:imageInfoData];
                            }
                        }];
    }
}




@end
