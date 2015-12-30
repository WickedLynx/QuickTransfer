//
//  QTRPhotoLibraryController.h
//  QuickTransfer
//
//  Created by Tarun Yadav on 29/12/15.
//  Copyright © 2015 Laughing Buddha Software. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface QTRPhotoLibraryController : NSObject

- (BOOL)fetchAssetInformation;
- (NSInteger)fetchImageCount;

- (void)imageAtIndex:(NSUInteger)imageIndex imageWithFullSize:(BOOL)isFullSize imageSize:(CGSize)fetchImageSize completion:(void (^)(UIImage *image))completion;

@end

