//
//  QTRConnectedDevicesViewController.m
//  QuickTransfer
//
//  Created by Harshad on 20/02/14.
//  Copyright (c) 2014 Laughing Buddha Software. All rights reserved.
//

#import <MobileCoreServices/MobileCoreServices.h>
#import <AssetsLibrary/AssetsLibrary.h>

#import "QTRConnectedDevicesViewController.h"
#import "QTRConnectedDevicesView.h"
#import "QTRTransfersViewController.h"

#import "QTRHomeCollectionViewCell.h"
#import "QTRShowGalleryViewController.h"
#import "QTRRightBarButtonView.h"
#import "QTRActionSheetGalleryView.h"

#import "QTRBonjourClient.h"
#import "QTRBonjourServer.h"
#import "QTRUser.h"
#import "QTRFile.h"
#import "QTRConstants.h"

#import "QTRBeaconHelper.h"
#import "QTRHelper.h"
#import "QTRSelectedUserInfo.h"
#import "QTRRecentLogsViewController.h"
#import "QTRCustomAlertView.h"


@interface QTRConnectedDevicesViewController () <QTRBonjourClientDelegate, QTRBonjourServerDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UIAlertViewDelegate, UINavigationControllerDelegate, QTRBeaconRangerDelegate,UICollectionViewDelegateFlowLayout, actionSheetGallaryDelegate, UIImagePickerControllerDelegate> {

    __weak QTRConnectedDevicesView *_devicesView;
    
    QTRBonjourClient *_client;
    QTRBonjourServer *_server;
    
    NSMutableArray *_connectedServers;
    NSMutableArray *_connectedClients;
    NSMutableDictionary *_selectedRecivers;
    
    QTRUser *_localUser;
    QTRUser *_selectedUser;
    
    UIRefreshControl *refreshControl;

    NSMapTable *_alertToFileMapTable;
    
    NSURL *_fileCacheDirectory;
    
    ALAssetsLibrary *_assetsLibrary;

    UIBackgroundTaskIdentifier _backgroundTaskIdentifier;
    NSDate *_killDate;

    QTRBeaconRanger *_beaconRanger;
    QTRBeaconAdvertiser *_beaconAdvertiser;
    
    QTRActionSheetGalleryView *customView;

    __weak id <QTRBonjourTransferDelegate> _transfersController;

    NSURL *_importedFileURL;
    
    UIImage *image;
    NSURL *path;
    UILabel *fetchingDevicesLabel;
    
    UIDynamicAnimator* _animator;
    UIGravityBehavior* _gravity;
    UICollisionBehavior* _collision;
    
    QTRCustomAlertView *cac;
    
    
}


- (void)touchShare:(UIBarButtonItem *)barButton;
- (void)touchRefresh:(UIBarButtonItem *)barButton;
- (void)startServices;
- (void)showAlertForFile:(QTRFile *)file user:(QTRUser *)user receiver:(id)receiver;
- (void)saveFile:(QTRFile *)file;
- (BOOL)userConnected:(QTRUser *)user;
- (QTRUser *)userAtIndexPath:(NSIndexPath *)indexPath isServer:(BOOL *)isServer;
- (NSURL *)fileCacheDirectory;
- (NSURL *)uniqueURLForFileWithName:(NSString *)fileName;
- (void)applicationDidEnterForeground:(NSNotification *)notification;
- (void)applicationDidEnterBackground:(NSNotification *)notification;

@end

static NSString *cellIdentifier = @"cellIdentifier";


@implementation QTRConnectedDevicesViewController

#pragma mark - Initialisation

- (instancetype)initWithTransfersStore:(id<QTRBonjourTransferDelegate>)transfersStore {
    self = [super init];
    if (self != nil) {

        _transfersController = transfersStore;

        _assetsLibrary = [[ALAssetsLibrary alloc] init];

        _alertToFileMapTable = [NSMapTable weakToStrongObjectsMapTable];

        if ([QTRBeaconHelper isBLEAvailable]) {
            _beaconAdvertiser = [[QTRBeaconAdvertiser alloc] init];
            _beaconRanger = [[QTRBeaconRanger alloc] init];
        }

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];

        _backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
            [[UIApplication sharedApplication] endBackgroundTask:_backgroundTaskIdentifier];
            _backgroundTaskIdentifier = UIBackgroundTaskInvalid;
        }];

        [self startServices];

        _killDate = [NSDate date];
    }
    
    return self;

}

#pragma mark - View lifecycle

- (void)loadView {
    QTRConnectedDevicesView *view = [[QTRConnectedDevicesView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    //[view setAutoresizingMask:(UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth)];
    [self setView:view];
}

- (void)setView:(UIView *)view {

    if (![view isKindOfClass:[QTRConnectedDevicesView class]]) {
        [NSException raise:NSInternalInconsistencyException format:@"%@ must associated only with %@", NSStringFromClass([self class]), NSStringFromClass([QTRConnectedDevicesView class])];
    }

    [super setView:view];

    _devicesView = (QTRConnectedDevicesView *)view;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    //[_selectedRecivers removeAllObjects];
    [[_devicesView devicesCollectionView] reloadData];
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [self animatePreviewLabel:fetchingDevicesLabel];
    [fetchingDevicesLabel setText:@"Fetching Devices"];
    [self updateTitle];


}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSURL *ubiq = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil];
    if (ubiq) {
        NSLog(@"iCloud access at %@", ubiq);
        // TODO: Load document...
    } else {
        NSLog(@"No iCloud access");
    }
    

    NSLog(@"%f   %f ",self.view.frame.size.width ,self.view.frame.size.height);
    
    fetchingDevicesLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 220, 40)];
    fetchingDevicesLabel.center = self.view.center;
    [fetchingDevicesLabel setText:@""];
    [fetchingDevicesLabel setTextAlignment:NSTextAlignmentCenter];
    [fetchingDevicesLabel setTextColor:[UIColor whiteColor]];
    [self.view addSubview:fetchingDevicesLabel];
    
    _selectedRecivers = [[NSMutableDictionary alloc]init];
    
    [self.view setBackgroundColor:[UIColor colorWithRed:55.f/255.f green:55.f/255.f blue:55.f/255.f alpha:1.00f]];
    [[_devicesView devicesCollectionView] setBackgroundColor:[UIColor colorWithRed:76.f/255.f green:76.f/255.f blue:76.f/255.f alpha:1.00f]];
    [[_devicesView devicesCollectionView] setBackgroundColor:[UIColor clearColor]];
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    [self setTitle:@"Devices"];
    
    [self.navigationController.navigationBar setBarTintColor:[UIColor colorWithRed:85.f/255.f green:85.f/255.f blue:85.f/255.f alpha:1.00f]];
    
    [[_devicesView devicesCollectionView] registerClass:[QTRHomeCollectionViewCell class] forCellWithReuseIdentifier:@"cellIdentifier"];

    [[_devicesView devicesCollectionView] setDataSource:self];
    [[_devicesView devicesCollectionView] setDelegate:self];
    [_devicesView devicesCollectionView].allowsMultipleSelection = YES;
   

    [[_devicesView devicesCollectionView] reloadData];
    
    refreshControl = [[UIRefreshControl alloc]init];
    [refreshControl setHidden:YES];
    [[_devicesView devicesCollectionView] addSubview:refreshControl];
    [refreshControl addTarget:self action:@selector(refreshConnectedDevices) forControlEvents:UIControlEventValueChanged];

    [[_devicesView devicesCollectionView] setScrollEnabled:YES];
    [_devicesView devicesCollectionView].alwaysBounceVertical = YES;
    
    QTRRightBarButtonView *customRightBarButton = [[QTRRightBarButtonView alloc]initWithFrame:CGRectZero];
    [customRightBarButton setUserInteractionEnabled:NO];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button addTarget:self action:@selector(logsBarButton:) forControlEvents:UIControlEventTouchUpInside];
    button.frame = customRightBarButton.frame;
    [customRightBarButton addSubview:button];
    
    UIBarButtonItem *rightBarButton = [[UIBarButtonItem alloc] initWithCustomView:customRightBarButton];
    [self.navigationItem setRightBarButtonItem:rightBarButton];
    
    UIBarButtonItem *leftBarButton = [[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"settingIcon"] style:UIBarButtonItemStylePlain target:self action:@selector(settingBarButton:)];
    [self.navigationItem setLeftBarButtonItem:leftBarButton];
    
    [[_devicesView sendButton] addTarget:self action:@selector(nextButtonClicked) forControlEvents:UIControlEventTouchUpInside];

    [self.navigationController.navigationBar setTitleTextAttributes:
     @{NSForegroundColorAttributeName:[UIColor whiteColor]}];
   
    [_devicesView searchBar].delegate = self;

}

#pragma mark - Public methods

- (void)setImportedFile:(NSURL *)fileURL {
    _importedFileURL = [fileURL copy];

    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Select User" message:@"Select the user to whom you want to send the file" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
    [alertView show];
}

#pragma mark - Actions

-(void) refreshConnectedDevices {
    
    [self animatePreviewLabel:fetchingDevicesLabel];
    [fetchingDevicesLabel setText:@"Fetching Devices"];
    
    [self refresh];

}

- (void)settingBarButton:(UIBarButtonItem *)barButton {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];

}

- (void)logsBarButton:(UIBarButtonItem *)barButton {
    QTRRecentLogsViewController *recentLogs = [[QTRRecentLogsViewController alloc]init];
    [self.navigationController pushViewController:recentLogs animated:YES];
    
}


- (void)touchRefresh:(UIBarButtonItem *)barButton {
    [self refresh];
}

-(void) userProfile {

    NSLog(@"Custom button");
}

-(void)nextButtonClicked{

    if ([_selectedRecivers count] > 0) {
    
        cac = [[QTRCustomAlertView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
        [self.view addSubview:cac];
    
    
        customView = [[QTRActionSheetGalleryView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.view.frame.size.width, 66.0f)];
        [customView setUserInteractionEnabled:YES];
        customView.delegate = self;
        customView.actionControllerCollectionView.backgroundColor = [UIColor whiteColor];
    
        [customView.actionControllerCollectionView registerClass:[QTRAlertControllerCollectionViewCell class] forCellWithReuseIdentifier:@"cellIdentifier"];
    
        [customView.actionControllerCollectionView setDataSource:customView];
        [customView.actionControllerCollectionView setDelegate:customView];
        customView.actionControllerCollectionView.allowsMultipleSelection = YES;
        [cac.galleryCollectionView addSubview:customView];

        [cac.cancelButton addTarget: self action: @selector(actionViewCancelButton) forControlEvents: UIControlEventTouchUpInside];
        [cac.iCloudButton addTarget: self action: @selector(actioniCloudButton) forControlEvents: UIControlEventTouchUpInside];
        [cac.cameraRollButton addTarget: self action: @selector(actionCameraRoll) forControlEvents: UIControlEventTouchUpInside];
        [cac.takePhotoButton addTarget: self action: @selector(actionTakePhoto) forControlEvents: UIControlEventTouchUpInside];

    }
    
    else {
    
        UIAlertView *alertNextButton = [[UIAlertView alloc]initWithTitle:@"Warnig" message:@"First Select Atlest One Device" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
        [alertNextButton show];
        
    }
    
}


-(void) actionViewCancelButton {
    [cac removeFromSuperview];

}

-(void) actioniCloudButton {
    [cac removeFromSuperview];

}

-(void) actionCameraRoll {
    
    [cac removeFromSuperview];
    [customView removeFromSuperview];
    
    QTRSelectedUserInfo *usersInfo = [[QTRSelectedUserInfo alloc]init];
    usersInfo._client = _client;
    usersInfo._server = _server;
    usersInfo._connectedServers = _connectedServers;
    usersInfo._connectedClients = _connectedClients;
    usersInfo._selectedRecivers = _selectedRecivers;
    usersInfo._localUser = _localUser;
    usersInfo._selectedUser = _selectedUser;

    QTRShowGalleryViewController *showGallery = [[QTRShowGalleryViewController alloc] init];
    showGallery.reciversInfo = usersInfo;
    [self.navigationController pushViewController:showGallery animated:YES];

}
-(void) actionTakePhoto {
    [cac removeFromSuperview];
    
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = YES;
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    
    [self presentViewController:picker animated:YES completion:NULL];
}

- (void)touchShare:(UIBarButtonItem *)barButton {
    if (_selectedUser != nil) {
        
    }
}

#pragma mark - Private methods

- (void)animatePreviewLabel:(UILabel *)previewMessageLabel {
    CATransition *animation = [CATransition animation];
    animation.duration = 3.0;
    animation.type = kCATransitionReveal;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [previewMessageLabel.layer addAnimation:animation forKey:@"changeTextTransition"];

}


- (void)stopServices {
    [_server setDelegate:nil];
    [_server setTransferDelegate:nil];
    [_server stop];
    _server = nil;

    [_client setDelegate:nil];
    [_client setTransferDelegate:nil];
    [_client stop];
    _client = nil;

    [_connectedClients removeAllObjects];
    [_connectedServers removeAllObjects];

    [[_devicesView devicesCollectionView] reloadData];

    [_beaconAdvertiser stopAdvertisingBeaconRegion];
    [_beaconRanger stopRangingBeacons];

    _importedFileURL = nil;
}

- (void)startServices {

    _connectedServers = [NSMutableArray new];
    _connectedClients = [NSMutableArray new];
    NSString *uuid = [[NSUserDefaults standardUserDefaults] stringForKey:QTRBonjourTXTRecordIdentifierKey];
    if ([uuid isKindOfClass:[NSNull class]] || uuid == nil) {
        uuid = [[NSUUID UUID] UUIDString];
        [[NSUserDefaults standardUserDefaults] setObject:uuid forKey:QTRBonjourTXTRecordIdentifierKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }

    _localUser = [[QTRUser alloc] initWithName:[[UIDevice currentDevice] name] identifier:uuid platform:QTRUserPlatformIOS];

    _server = [[QTRBonjourServer alloc] initWithFileDelegate:self];
    [_server setTransferDelegate:_transfersController];

    if (![_server start]) {

        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Could not start server" message:@"Please check that Wifi is turned on" delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil, nil];
        [alert show];
    }

    _client = [[QTRBonjourClient alloc] initWithDelegate:self];
    [_client setTransferDelegate:_transfersController];
    [_client start];
    
    [self refreshBeacons];
}

- (void)refresh {
    [self stopServices];

    double delayInSeconds = 2.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self startServices];
    });
}

- (void)refreshBeacons {
    if ([QTRBeaconHelper isBLEAvailable]) {
        if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive) {

            [_beaconRanger stopRangingBeacons];

            [_beaconAdvertiser startAdvertisingRegionWithProximityUUID:QTRBeaconRegionProximityUUID identifier:QTRBeaconRegionIdentifier majorValue:0 minorValue:0];

        } else {

            [_beaconAdvertiser stopAdvertisingBeaconRegion];

            [_beaconRanger setDelegate:self];
            [_beaconRanger startRangingBeaconsWithProximityUUID:QTRBeaconRegionProximityUUID identifier:QTRBeaconRegionIdentifier majorValue:0 minorValue:0];
        }
    }
}

- (NSURL *)uniqueURLForFileWithName:(NSString *)fileName {
    NSFileManager *fileManager = [NSFileManager defaultManager];

    NSURL *cachesURL = [QTRHelper fileCacheDirectory];
    
    NSString *filePath = [[cachesURL path] stringByAppendingPathComponent:fileName];
    
    if ([fileManager fileExistsAtPath:filePath]) {
        NSString *name = [[filePath lastPathComponent] stringByDeletingPathExtension];
        NSString *extension = [filePath pathExtension];
        NSString *nameWithExtension = [name stringByAppendingPathExtension:extension];
        NSString *tempName = name;
        int fileCount = 0;
        while ([fileManager fileExistsAtPath:filePath]) {
            ++fileCount;
            tempName = [name stringByAppendingFormat:@"%d", fileCount];
            nameWithExtension = [tempName stringByAppendingPathExtension:extension];
            filePath = [[cachesURL path] stringByAppendingPathComponent:nameWithExtension];
        }
    }
    
    
    return [NSURL fileURLWithPath:filePath];
}

- (BOOL)userConnected:(QTRUser *)user {
    return [_connectedClients containsObject:user] || [_connectedServers containsObject:user] || [_localUser isEqual:user];
}

- (NSURL *)fileCacheDirectory {
    if (_fileCacheDirectory == nil) {
        NSString *directoryName = @"FileCache";
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *cachesPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
        BOOL isDirectory = NO;
        cachesPath = [cachesPath stringByAppendingPathComponent:directoryName];
        
        if ([fileManager fileExistsAtPath:cachesPath isDirectory:&isDirectory]) {
            [fileManager removeItemAtPath:cachesPath error:nil];
        }
        
        [fileManager createDirectoryAtPath:cachesPath withIntermediateDirectories:YES attributes:nil error:nil];
        
        _fileCacheDirectory = [NSURL fileURLWithPath:cachesPath];
    }
    
    return _fileCacheDirectory;
}

- (QTRUser *)userAtIndexPath:(NSIndexPath *)indexPath isServer:(BOOL *)isServer {
    QTRUser *theUser = nil;

    long row = indexPath.row;

    if ([_connectedServers count] > row) {
        theUser = _connectedServers[row];
        if (isServer != NULL) {
            *isServer = YES;
        }
    } else {
        row -= [_connectedServers count];
        if ([_connectedClients count] > row) {
            theUser = _connectedClients[row];
            if (isServer != NULL) {
                *isServer = NO;
            }
        }
    }

    return theUser;
}

- (void)showNotificationIfRequiredWithMessage:(NSString *)message {

    if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground) {
        UILocalNotification *localNotification = [[UILocalNotification alloc] init];
        [localNotification setFireDate:[NSDate date]];
        [localNotification setHasAction:NO];
        [localNotification setSoundName:UILocalNotificationDefaultSoundName];
        [localNotification setAlertBody:message];

        [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
    }

}

- (void)showAlertForFile:(QTRFile *)file user:(QTRUser *)user receiver:(id)receiver {

    NSString *alertMessage = [NSString stringWithFormat:@"%@ wants to send you a file: %@", user.name, file.name];

    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Accept File?" message:alertMessage delegate:self cancelButtonTitle:@"Accept" otherButtonTitles:@"Reject", nil];
    [_alertToFileMapTable setObject:@{@"file" : file, @"receiver" : receiver, @"user" : user} forKey:alert];
    [alert show];

    [self showNotificationIfRequiredWithMessage:alertMessage];
}

- (void)saveFile:(QTRFile *)file {
    [file.data writeToURL:[self uniqueURLForFileWithName:file.name] atomically:YES];

}

- (void)updateTitle {
    unsigned long totalUsers = [_connectedClients count] + [_connectedServers count];
    [self setTitle:[NSString stringWithFormat:@"Devices (%lu)", totalUsers]];
    
    if (totalUsers > 0) {
        //[[_devicesView loadDeviceView] stopAnimating];
        [refreshControl endRefreshing];
        [self animatePreviewLabel:fetchingDevicesLabel];
        [fetchingDevicesLabel setText:@""];
        
    } else {
        //[[_devicesView loadDeviceView] startAnimating];
        [self animatePreviewLabel:fetchingDevicesLabel];
        [fetchingDevicesLabel setText:@"Fetching Devices"];

    }
}

#pragma mark - Notifications

- (void)applicationDidEnterBackground:(NSNotification *)notification {
    [self refreshBeacons];
}

- (void)applicationDidEnterForeground:(NSNotification *)notification {
    [self refreshBeacons];

    if (_backgroundTaskIdentifier == UIBackgroundTaskInvalid) {
        _backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
            [[UIApplication sharedApplication] endBackgroundTask:_backgroundTaskIdentifier];
            _backgroundTaskIdentifier = UIBackgroundTaskInvalid;
        }];

        [self refresh];
    }
}

#pragma mark - UICollectionViewDataSource methods

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    
    int noOfItems = (self.view.frame.size.width - 20) / 100;
    int totalRemSpace = self.view.frame.size.width - (noOfItems * 100);
    
    CGFloat gap = (CGFloat)totalRemSpace / (CGFloat)(noOfItems + 1);
    
    
    return UIEdgeInsetsMake(5.0f, gap, 0.0f, gap);
}

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {

    if (self.isFiltered) {
        return [self.filteredUserData count];
    }
    else {
        return [_connectedServers count] + [_connectedClients count];
    }
    
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {

    QTRHomeCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    
    CGRect finalCellFrame = cell.frame;
    //check the scrolling direction to verify from which side of the screen the cell should come.
    CGPoint translation = [collectionView.panGestureRecognizer translationInView:collectionView.superview];
    
           if (translation.y < 0) {
            cell.frame = CGRectMake( (self.view.frame.size.width / 2.0f), finalCellFrame.origin.y + 1000, 0, 0);
        } else {
            cell.frame = CGRectMake( (self.view.frame.size.width / 2.0f), finalCellFrame.origin.y + 1000, 0, 0);
        }
    
    [UIView animateWithDuration:2.0f animations:^(void){
        cell.frame = finalCellFrame;

    }];
    
    QTRUser *theUser;
    
    
    
    if (self.isFiltered) {
        theUser = [self.filteredUserData objectAtIndex:indexPath.row];
        }
    else {
        theUser = [self userAtIndexPath:indexPath isServer:NULL];
        }
    
    [cell.connectedDeviceName setText:[theUser name]];
    [cell setIconImage:theUser.platform];
    
    if ([_selectedRecivers count] > 0) {
        
        if ([_selectedRecivers objectForKey:theUser.identifier] != NULL) {
            NSLog(@"Selected %@", theUser.name);
            cell.connectedDeviceName.textColor = [UIColor colorWithRed:32.f/255.f green:149.f/255.f blue:242.f/255.f alpha:1.00f];
        }
    }
    
    [cell setIconImage:theUser.platform];
    return cell;
    
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(100.0f, 120.0f);
}


#pragma mark - UICollectionViewDelegate methods

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    QTRUser *theUser;
    
    if (self.isFiltered) {
        theUser = [self.filteredUserData objectAtIndex:indexPath.row];

    } else {
        theUser = [self userAtIndexPath:indexPath isServer:NULL];

    }
    
    [_selectedRecivers removeObjectForKey:theUser.identifier];
    
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL isServer = NO;

    QTRUser *theUser = [self userAtIndexPath:indexPath isServer:&isServer];
    
    if (_importedFileURL == nil) {
        
        _selectedUser = theUser;
        [self touchShare:nil];
        
    } else {
        
        if (isServer) {
            [_client sendFileAtURL:_importedFileURL toUser:theUser];
        } else {
            [_server sendFileAtURL:_importedFileURL toUser:theUser];
        }
        
        _importedFileURL = nil;
    }

    
    if (self.isFiltered) {
        theUser = [self.filteredUserData objectAtIndex:indexPath.row];

    } else {
        theUser = [self userAtIndexPath:indexPath isServer:NULL];
    }
    
    [_selectedRecivers setObject:theUser forKey:theUser.identifier];
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    
    QTRUser *theUser;
    
    if (self.isFiltered) {
        theUser = [self.filteredUserData objectAtIndex:indexPath.row];
    }
    else {
        theUser = [self userAtIndexPath:indexPath isServer:NULL];
    }
    
    if ([_selectedRecivers count] > 0) {
        if ([_selectedRecivers objectForKey:theUser.identifier] != NULL) {
            
            
            dispatch_after(0.1, dispatch_get_main_queue(), ^{
                [collectionView selectItemAtIndexPath:indexPath animated:YES scrollPosition:UICollectionViewScrollPositionCenteredHorizontally];
            });
        }
    }
    
}

#pragma mark - QTRBonjourServerDelegate methods

- (void)server:(QTRBonjourServer *)server didConnectToUser:(QTRUser *)user {
    if (![self userConnected:user]) {
        
        [_connectedClients addObject:user];
        [self updateTitle];
        [[_devicesView devicesCollectionView] reloadData];
        
    }
}

- (void)server:(QTRBonjourServer *)server didDisconnectUser:(QTRUser *)user {
    [_connectedClients removeObject:user];
    [self updateTitle];
    [[_devicesView devicesCollectionView] reloadData];
}

- (void)server:(QTRBonjourServer *)server didReceiveFile:(QTRFile *)file fromUser:(QTRUser *)user {
    [self saveFile:file];
}

- (void)user:(QTRUser *)user didRejectFile:(QTRFile *)file {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"File Rejected" message:[NSString stringWithFormat:@"%@ rejected file: %@", user.name, file.name] delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil, nil];
    [alert show];
}

- (void)server:(QTRBonjourServer *)server didDetectIncomingFile:(QTRFile *)file fromUser:(QTRUser *)user {
    [self showAlertForFile:file user:user receiver:server];
}

- (NSURL *)saveURLForFile:(QTRFile *)file {
    return [self uniqueURLForFileWithName:file.name];
}

#pragma mark - QTRBonjourClientDelegate methods

- (QTRUser *)localUser {
    return _localUser;
}

- (BOOL)client:(QTRBonjourClient *)client shouldConnectToUser:(QTRUser *)user {
    return ![self userConnected:user];
}

- (void)client:(QTRBonjourClient *)client didConnectToServerForUser:(QTRUser *)user {
    
    if (![self userConnected:user]) {
        
        [_connectedServers addObject:user];
        [self updateTitle];
        [[_devicesView devicesCollectionView] reloadData];
        
    }
}

- (void)client:(QTRBonjourClient *)client didDisconnectFromServerForUser:(QTRUser *)user {
    [_connectedServers removeObject:user];
    [self updateTitle];
    [[_devicesView devicesCollectionView] reloadData];
}

- (void)client:(QTRBonjourClient *)client didReceiveFile:(QTRFile *)file fromUser:(QTRUser *)user {
    [self saveFile:file];
}

- (void)client:(QTRBonjourClient *)client didDetectIncomingFile:(QTRFile *)file fromUser:(QTRUser *)user {
    [self showAlertForFile:file user:user receiver:client];
}


#pragma mark - UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    
    NSDictionary *context = [_alertToFileMapTable objectForKey:alertView];
    QTRFile *theFile = context[@"file"];
    id receiver = context[@"receiver"];
    QTRUser *theUser = context[@"user"];
    
    BOOL shouldAccept = NO;

    if (buttonIndex == [alertView cancelButtonIndex]) {
        shouldAccept = YES;
    }
    
    if (receiver == _client) {
        [_client acceptFile:theFile accept:shouldAccept fromUser:theUser];
    } else {
        [_server acceptFile:theFile accept:shouldAccept fromUser:theUser];
    }

    [_alertToFileMapTable removeObjectForKey:alertView];
}

#pragma mark - QTRBeaconRangerDelegate methods

- (void)beaconRangerDidEnterRegion:(QTRBeaconRanger *)beaconRanger {
    if ([[UIApplication sharedApplication] applicationState] != UIApplicationStateActive) {
        if (_backgroundTaskIdentifier == UIBackgroundTaskInvalid) {

            _backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
                [[UIApplication sharedApplication] endBackgroundTask:_backgroundTaskIdentifier];
                _backgroundTaskIdentifier = UIBackgroundTaskInvalid;
            }];

            [self stopServices];

            [NSThread sleepForTimeInterval:2];

            [self startServices];
        }

    }
}

#pragma mark - ActionSheetGallaryDelegate methods

//- (void) QTRActionSheetGalleryView:(QTRActionSheetGalleryView *)QTRActionSheetGalleryView didCellSelected:(BOOL)selected withCollectionCell:(QTRAlertControllerCollectionViewCell *)alertControllerCollectionViewCell {
//    if (selected) {
//        
//        
//        
//        
//        [cac removeFromSuperview];
//        
//        
//        //[self dismissViewControllerAnimated:YES completion:nil];
//    }
//}


- (void)QTRActionSheetGalleryView:(QTRActionSheetGalleryView *)actionSheetGalleryView didCellSelected:(BOOL)selected withCollectionCell:(QTRAlertControllerCollectionViewCell *)alertControllerCollectionViewCell selectedImage:(QTRImagesInfoData *)sendingImage {
    
    [cac removeFromSuperview];

    NSLog(@"Delegation %@",alertControllerCollectionViewCell);
    
    
    NSLog(@"Sending Image Data:%@", sendingImage.description);

    [self sendDataToSelectedUser:sendingImage];

}

#pragma mark - Sending Data



- (void)sendDataToSelectedUser:(QTRImagesInfoData *)sendingImage {
    
    self.requestOptions = [[PHImageRequestOptions alloc] init];
    self.requestOptions.resizeMode   = PHImageRequestOptionsResizeModeExact;
    self.requestOptions.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    
    self.requestOptions.synchronous = true;
    NSURL *referenceURL = [sendingImage.imageInfo objectForKey:@"PHImageFileURLKey"];
    
    
    [[PHImageManager defaultManager] requestImageDataForAsset:sendingImage.imageAsset
                                                      options:self.requestOptions
                                                resultHandler:
     ^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info) {
         
         NSURL *localURL = [self uniqueURLForFileWithName:[referenceURL lastPathComponent]];
         
         [imageData writeToURL:localURL atomically:YES];
         
         NSArray *totalRecivers = [_selectedRecivers allValues];
         _selectedUser = nil;
         
         for (QTRUser *currentUser in totalRecivers) {
             
             _selectedUser = currentUser;
             
             if ([_connectedClients containsObject:_selectedUser]) {
                 [_server sendFileAtURL:localURL toUser:_selectedUser];
                 
             } else if ([_connectedServers containsObject:_selectedUser]) {
                 [_client sendFileAtURL:localURL toUser:_selectedUser];
                 
             } else {
                 UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@" is not connected anymore"] delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil, nil];
                 [alert show];
             }
             
             _selectedUser = nil;
         }
         
         
     }];
    
}



#pragma mark - Search Bar methods


-(void)searchBar:(UISearchBar*)searchBar textDidChange:(NSString*)text
{
    if(text.length == 0)
    {
        self.isFiltered = FALSE;
        [searchBar resignFirstResponder];
    }
    else
    {
        self.isFiltered = true;
        self.filteredUserData = [[NSMutableArray alloc] init];
        
        for (QTRUser *theUser in _connectedServers)
        {
            //case insensative search - way cool
            if ([theUser.name rangeOfString:text options:NSCaseInsensitiveSearch].location != NSNotFound)
            {
                [self.filteredUserData addObject:theUser];
            }
        }
        
        for (QTRUser *theUser in _connectedClients)
        {
            if ([theUser.name rangeOfString:text options:NSCaseInsensitiveSearch].location != NSNotFound)
            {
                [self.filteredUserData addObject:theUser];
            }
            
        }
    }
        
    [[_devicesView devicesCollectionView] reloadData];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    [searchBar setShowsCancelButton:YES animated:YES];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    searchBar.text=@"";
    
    [searchBar setShowsCancelButton:NO animated:YES];
    [searchBar resignFirstResponder];
    
    self.isFiltered = FALSE;
    [[_devicesView devicesCollectionView] reloadData];
}

#pragma mark - Image Picker Controller delegate methods

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    NSURL *referenceURL = info[UIImagePickerControllerReferenceURL];
    
    [_assetsLibrary assetForURL:referenceURL resultBlock:^(ALAsset *asset) {
        
        NSURL *localURL = [self uniqueURLForFileWithName:[referenceURL lastPathComponent]];
        UIImage *chosenImage = info[UIImagePickerControllerEditedImage];
        NSData *imageData = UIImageJPEGRepresentation(chosenImage, 1.0);
        [imageData writeToURL:localURL atomically:YES];
        
        
        NSArray *totalRecivers = [_selectedRecivers allValues];
        _selectedUser = nil;
        
        for (QTRUser *currentUser in totalRecivers) {
            
            _selectedUser = currentUser;
            
            if ([_connectedClients containsObject:_selectedUser]) {
                [_server sendFileAtURL:localURL toUser:_selectedUser];
                
            } else if ([_connectedServers containsObject:_selectedUser]) {
                [_client sendFileAtURL:localURL toUser:_selectedUser];
                
            } else {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@" is not connected anymore"] delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil, nil];
                [alert show];
            }
            
            _selectedUser = nil;
        }

        
    
        
//        if ([_connectedClients containsObject:_selectedUser]) {
//            [_server sendFileAtURL:localURL toUser:_selectedUser];
//        } else if ([_connectedServers containsObject:_selectedUser]) {
//            [_client sendFileAtURL:localURL toUser:_selectedUser];
//        } else {
//            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"%@ is not connected anymore", _selectedUser.name] delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil, nil];
//            [alert show];
//        }
//        
//        _selectedUser = nil;
        
        
        
        
        
    } failureBlock:^(NSError *error) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Could not load file" delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil, nil];
        [alertView show];
    }];
    
    [picker dismissViewControllerAnimated:YES completion:NULL];
    
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    
    [picker dismissViewControllerAnimated:YES completion:NULL];
    
}

@end
