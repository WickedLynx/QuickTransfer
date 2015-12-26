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
@protocol showGalleryCustomDelegate <NSObject>

- (void)QTRShowGalleryViewController:(QTRShowGalleryViewController *)showGalleryCustomDelegate selectedImages:(NSArray *)sendingImagesData;

@end

@interface QTRShowGalleryViewController : UIViewController 


@property (nonatomic, weak) id <showGalleryCustomDelegate> delegate;
@property (nonatomic, retain) NSMutableDictionary *selectedImages;
@property (nonatomic, retain) NSMutableArray *fetchingImageArray;




@end
