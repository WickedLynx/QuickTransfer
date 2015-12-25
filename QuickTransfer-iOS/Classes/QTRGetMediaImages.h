//
//  QTRGetMediaImages.h
//  QuickTransfer
//
//  Created by Tarun Yadav on 25/12/15.
//  Copyright © 2015 Laughing Buddha Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PhotosUI/PhotosUI.h>

@interface QTRGetMediaImages : NSObject <PHPhotoLibraryChangeObserver>

- (NSMutableArray *)fetchMediaImages;
- (void)downloadMedia;

@property (nonatomic, retain) PHCachingImageManager *imageManager;
@property (nonatomic, retain) PHImageRequestOptions *requestOptions;

@property (nonatomic, retain) NSMutableDictionary *selectedImages;
@property (nonatomic, retain) NSArray *sectionFetchResults;
@property (nonatomic, retain) NSArray *sectionLocalizedTitles;


@end
