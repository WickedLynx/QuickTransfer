//
//  QTRImagesInfoData.h
//  QuickTransfer
//
//  Created by Tarun Yadav on 03/12/15.
//  Copyright © 2015 Laughing Buddha Software. All rights reserved.
//

#import <PhotosUI/PhotosUI.h>
#import <Foundation/Foundation.h>

@interface QTRImagesInfoData : NSObject

@property (nonatomic, retain) UIImage *finalImage;
@property (nonatomic, retain) NSDictionary *imageInfo;
@property (nonatomic, retain) NSString *imageIdentifier;
@property (nonatomic, retain) PHAsset *imageAsset;

@end
