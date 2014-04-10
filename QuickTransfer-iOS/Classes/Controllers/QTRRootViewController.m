//
//  QTRRootViewController.m
//  QuickTransfer
//
//  Created by Harshad on 09/04/14.
//  Copyright (c) 2014 Laughing Buddha Software. All rights reserved.
//

#import "QTRRootViewController.h"

#import "QTRConnectedDevicesViewController.h"
#import "QTRTransfersViewController.h"

#import "QTRTransfersStore.h"

@interface QTRRootViewController ()

@end

@implementation QTRRootViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.

    QTRTransfersViewController *transfersController = [QTRTransfersViewController new];

    QTRConnectedDevicesViewController *connectedDevicesController = [[QTRConnectedDevicesViewController alloc] initWithTransfersStore:[transfersController transfersStore]];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:connectedDevicesController];

    [navigationController.view setFrame:CGRectMake(0, 0, 320, 240)];
    [transfersController.view setFrame:CGRectMake(0, 240, 320, self.view.bounds.size.height - 240)];

    [self addChildViewController:navigationController];
    [self.view addSubview:navigationController.view];

    [self addChildViewController:transfersController];
    [self.view addSubview:transfersController.view];
}


@end
