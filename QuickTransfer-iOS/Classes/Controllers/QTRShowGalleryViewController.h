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

@import Photos;
@import PhotosUI;

@interface QTRShowGalleryViewController : UIViewController 

@property (nonatomic, strong) PHCachingImageManager *imageManager;
@property (nonatomic, strong) PHImageRequestOptions *requestOptions;

@property (nonatomic, retain) NSMutableDictionary *selectedImages;

@property (nonatomic, retain) QTRBonjourClient *client;
@property (nonatomic, retain) QTRBonjourServer *server;
@property (nonatomic, retain) NSMutableArray *connectedServers;
@property (nonatomic, retain) NSMutableArray *connectedClients;
@property (nonatomic, retain) NSMutableDictionary *selectedRecivers;
@property (nonatomic, retain) QTRUser *localUser;

@property (nonatomic, retain) QTRUser *selectedUser;


@end
