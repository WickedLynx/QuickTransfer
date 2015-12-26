//
//  QTRShowGalleryViewController.h
//  QuickTransfer
//
//  Created by Tarun Yadav on 26/11/15.
//  Copyright © 2015 Laughing Buddha Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "QTRImagesInfoData.h"

@class QTRShowGalleryViewController;
@protocol TRShowGalleryCustomDelegate <NSObject>

- (void)showGalleryViewController:(QTRShowGalleryViewController *)showGalleryCustomDelegate selectedImages:(NSArray *)sendingImagesData;

@end

@interface QTRShowGalleryViewController : UIViewController 


@property (nonatomic, weak) id <TRShowGalleryCustomDelegate> delegate;
@property (nonatomic, retain) NSMutableDictionary *selectedImages;
@property (nonatomic, retain) NSMutableArray *fetchingImageArray;




@end
