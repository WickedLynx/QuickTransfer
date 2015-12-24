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


CGFloat const QTRRootViewControllerXOffset = 50.0f;

@interface QTRRootViewController () <UIGestureRecognizerDelegate> {
    UINavigationController *_connectedDevicesNavigationController;
    UINavigationController *_transfersNavigationController;
}

- (void)handleSwipe:(UISwipeGestureRecognizer *)swipeGestureRecognizer;

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
                [self showDevices];
                returnValue = YES;
            }
        }
    }

    return returnValue;
}

- (void)showDevices {
    [UIView animateWithDuration:0.25f delay:0.0f options:UIViewAnimationOptionCurveLinear animations:^{
        [_transfersNavigationController.view setFrame:CGRectOffset(self.view.bounds, self.view.bounds.size.width - QTRRootViewControllerXOffset, 0.0f)];
    } completion:^(BOOL finished) {

    }];
}

- (void)hideDevices {
    [UIView animateWithDuration:0.25f delay:0.0f options:UIViewAnimationOptionCurveLinear animations:^{
        [_transfersNavigationController.view setFrame:self.view.bounds];
    } completion:^(BOOL finished) {

    }];
}

- (void)handleSwipe:(UISwipeGestureRecognizer *)swipeGestureRecognizer {
    switch (swipeGestureRecognizer.direction) {
        case UISwipeGestureRecognizerDirectionLeft:
            [self hideDevices];
            break;

        case UISwipeGestureRecognizerDirectionRight:
            [self showDevices];
            break;

        default:
            break;
    }
}



@end
