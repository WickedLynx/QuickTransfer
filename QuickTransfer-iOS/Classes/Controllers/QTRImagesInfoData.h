//
//  QTRImagesInfoData.h
//  QuickTransfer
//
//  Created by Tarun Yadav on 03/12/15.
//  Copyright © 2015 Laughing Buddha Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface QTRImagesInfoData : NSObject

@property (nonatomic, retain) UIImage *finalImage;
@property (nonatomic, retain) NSDictionary *imageInfo;
@property (nonatomic, retain) NSString *imageIdentifier;
@property (nonatomic, retain) NSData *imageBinData;
@property (nonatomic, retain) ALAsset *imageAsset;

@end
