//
//  QTRShowGalleryViewController.h
//  QuickTransfer
//
//  Created by Tarun Yadav on 26/11/15.
//  Copyright © 2015 Laughing Buddha Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "QTRBonjourClient.h"
#import "QTRBonjourServer.h"
#import "QTRSelectedUserInfo.h"

@import Photos;
@import PhotosUI;

@interface QTRShowGalleryViewController : UIViewController 

@property (nonatomic, retain) PHCachingImageManager *imageManager;
@property (nonatomic, retain) PHImageRequestOptions *requestOptions;

@property (nonatomic, retain) NSMutableDictionary *selectedImages;
@property (nonatomic, retain) NSArray *sectionFetchResults;
@property (nonatomic, retain) NSArray *sectionLocalizedTitles;

@property (nonatomic, retain) QTRSelectedUserInfo *reciversInfo;


@end