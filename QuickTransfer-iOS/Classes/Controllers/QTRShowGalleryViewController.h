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

@interface QTRShowGalleryViewController : UIViewController 

@property (nonatomic, retain) NSMutableDictionary *selectedImages;


@property (nonatomic, retain) QTRSelectedUserInfo *reciversInfo;

@property (nonatomic, retain) NSMutableArray *fetchingImageArray;


@end
