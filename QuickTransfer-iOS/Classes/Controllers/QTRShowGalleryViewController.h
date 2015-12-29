//
//  QTRShowGalleryViewController.h
//  QuickTransfer
//
//  Created by Tarun Yadav on 26/11/15.
//  Copyright © 2015 Laughing Buddha Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "QTRImagesInfoData.h"
#import "QTRPhotoLibraryController.h"

@class QTRShowGalleryViewController;
@protocol TRShowGalleryCustomDelegate <NSObject>

- (void)showGalleryViewController:(QTRShowGalleryViewController *)showGalleryCustomDelegate selectedImages:(NSArray *)sendingImagesData;

@end

@interface QTRShowGalleryViewController : UIViewController 


@property (nonatomic, weak) id <TRShowGalleryCustomDelegate> delegate;
@property (nonatomic, strong) NSArray *fetchImageArray;
@property (nonatomic, strong) QTRPhotoLibraryController *fetchPhotoLibrary;



@end
