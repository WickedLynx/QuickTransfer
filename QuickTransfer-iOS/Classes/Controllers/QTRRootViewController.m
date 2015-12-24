//
//  QTRRootViewController.m
//  QuickTransfer
//
//  Created by Harshad on 09/04/14.
//  Copyright (c) 2014 Laughing Buddha Software. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "QTRRootViewController.h"
#import "QTRTransfersViewController.h"
#import "QTRConnectedDevicesViewController.h"
#import "QTRTransfersStore.h"
#import "QTRConnectedDevicesView.h"
#import "QTRShowGalleryViewController.h"


@interface QTRRootViewController () <UIGestureRecognizerDelegate> {
    UINavigationController *_connectedDevicesNavigationController;
    UINavigationController *_transfersNavigationController;
}


@end

@implementation QTRRootViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    QTRTransfersViewController *transfersController = [QTRTransfersViewController new];
    UINavigationController *transfersNavigationController = [[UINavigationController alloc] initWithRootViewController:transfersController];
    _transfersNavigationController = transfersNavigationController;
    
    QTRConnectedDevicesViewController *connectedDevicesController = [[QTRConnectedDevicesViewController alloc] initWithTransfersStore:[transfersController transfersStore]];
    UINavigationController *devicesNavigationController = [[UINavigationController alloc] initWithRootViewController:connectedDevicesController];
    _connectedDevicesNavigationController = devicesNavigationController;
    
    [self addChildViewController:devicesNavigationController];
    [self.view addSubview:devicesNavigationController.view];

}

- (BOOL)importFileAtURL:(NSURL *)fileURL {
    BOOL returnValue = NO;

    if ([fileURL isFileURL]) {
        BOOL isDirectory = NO;
        BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:[fileURL path] isDirectory:&isDirectory];

        if (fileExists) {
            if (isDirectory) {
                [[NSFileManager defaultManager] removeItemAtURL:fileURL error:nil];
            } else {
                [(QTRConnectedDevicesViewController *)[[_connectedDevicesNavigationController viewControllers] objectAtIndex:0] setImportedFile:fileURL];
                returnValue = YES;
            }
        }
    }

    return returnValue;
}


@end
