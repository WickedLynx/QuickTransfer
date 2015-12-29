//
//  QTRPhotoLibraryController.h
//  QuickTransfer
//
//  Created by Tarun Yadav on 29/12/15.
//  Copyright © 2015 Laughing Buddha Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PhotosUI/PhotosUI.h>

@interface QTRPhotoLibraryController : NSObject

- (void)imageAtIndex:(NSInteger)imageIndex completion: (void(^)(UIImage *image))completion;
- (void)originalImageAtIndex:(NSInteger)imageIndex completion: (void(^)(PHAsset *asset, NSDictionary *info))completion;
- (void)fetchAssetInformation;
- (NSInteger)fetchImageCount;

@end



//- (void)setup
//{
//    self.recentsDataSource = [[NSMutableOrderedSet alloc]init];
//    self.favoritesDataSource = [[NSMutableOrderedSet alloc]init];
//    
//    PHFetchResult *assetCollection = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum | PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAny options:nil];
//    
//    PHFetchResult *favoriteCollection = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumFavorites options:nil];
//    
//    for (PHAssetCollection *sub in assetCollection)
//    {
//        PHFetchResult *assetsInCollection = [PHAsset fetchAssetsInAssetCollection:sub options:nil];
//        
//        for (PHAsset *asset in assetsInCollection)
//        {
//            [self.recentsDataSource addObject:asset];
//        }
//    }
//    
//    if (self.recentsDataSource.count > 0)
//    {
//        NSArray *array = [self.recentsDataSource sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]]];
//        
//        self.recentsDataSource = [[NSMutableOrderedSet alloc]initWithArray:array];
//    }
//    
//    for (PHAssetCollection *sub in favoriteCollection)
//    {
//        PHFetchResult *assetsInCollection = [PHAsset fetchAssetsInAssetCollection:sub options:nil];
//        
//        for (PHAsset *asset in assetsInCollection)
//        {
//            [self.favoritesDataSource addObject:asset];
//        }
//    }
//    
//    if (self.favoritesDataSource.count > 0)
//    {
//        NSArray *array = [self.favoritesDataSource sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]]];
//        
//        self.favoritesDataSource = [[NSMutableOrderedSet alloc]initWithArray:array];
//    }
//}