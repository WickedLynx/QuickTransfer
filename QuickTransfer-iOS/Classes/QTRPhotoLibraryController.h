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

