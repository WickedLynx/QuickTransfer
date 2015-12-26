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

@property (nonatomic, retain) NSMutableDictionary *selectedImages;

- (NSMutableArray *)fetchMediaImages;
- (void)downloadMedia;

@end
