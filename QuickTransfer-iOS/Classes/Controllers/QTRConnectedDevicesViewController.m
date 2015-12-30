//
//  QTRConnectedDevicesViewController.m
//  QuickTransfer
//
//  Created by Harshad on 20/02/14.
//  Copyright (c) 2014 Laughing Buddha Software. All rights reserved.
//

#import <MobileCoreServices/MobileCoreServices.h>
#import "QTRConnectedDevicesViewController.h"
#import "QTRConnectedDevicesView.h"
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
#import "QTRCustomAlertView.h"
#import "QTRTransfersViewController.h"
#import "QTRPhotoLibraryController.h"


@interface QTRConnectedDevicesViewController () <QTRBonjourClientDelegate, QTRBonjourServerDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UIAlertViewDelegate, UINavigationControllerDelegate, QTRBeaconRangerDelegate,UICollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate> {

    __weak QTRConnectedDevicesView *_devicesView;
    
    QTRBonjourClient *_client;
    QTRBonjourServer *_server;
    
    NSMutableArray *_connectedServers;
    NSMutableArray *_connectedClients;
    NSMutableDictionary *_selectedRecivers;
    
    QTRUser *_localUser;
    QTRUser *_selectedUser;
    
    NSMapTable *_alertToFileMapTable;
    NSURL *_fileCacheDirectory;

    UIBackgroundTaskIdentifier _backgroundTaskIdentifier;
    NSDate *_killDate;

    QTRBeaconRanger *_beaconRanger;
    QTRBeaconAdvertiser *_beaconAdvertiser;
    
    QTRActionSheetGalleryView *customActionSheetGalleryView;
    QTRCustomAlertView *customAlertView;


    __weak id <QTRBonjourTransferDelegate> _transfersController;

    NSURL *_importedFileURL;
    NSTimer *_timer;

    NSMutableArray* filteredUserData;
    
    QTRShowGalleryViewController *showGallery;
    
    BOOL photoLibraryAuthorizationStatus;
}

@property (nonatomic, strong) QTRPhotoLibraryController *fetchPhotoLibrary;

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

NSString * const cellIdentifier = @"CellIdentifier";


@implementation QTRConnectedDevicesViewController

#pragma mark - Initialisation

- (instancetype)initWithTransfersStore:(id<QTRBonjourTransferDelegate>)transfersStore {
    self = [super init];
    if (self != nil) {

        _transfersController = transfersStore;
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
    [self setView:view];
}

- (void)setView:(UIView *)view {

    if (![view isKindOfClass:[QTRConnectedDevicesView class]]) {
        [NSException raise:NSInternalInconsistencyException format:@"%@ must associated only with %@", NSStringFromClass([self class]), NSStringFromClass([QTRConnectedDevicesView class])];
    }

    [super setView:view];

    _devicesView = (QTRConnectedDevicesView *)view;
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [self stopTimer];
    
    
    [_devicesView animatePreviewLabel:[_devicesView fetchingDevicesLabel]];
    
    
    [[_devicesView fetchingDevicesLabel] setText:@"Fetching Devices"];
    [[_devicesView deviceRefreshControl] beginRefreshing];
    [self startTimer];
    [self updateTitle];



}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    [self startTimer];
    
    _selectedRecivers = [[NSMutableDictionary alloc] init];
    
    _fetchPhotoLibrary = [[QTRPhotoLibraryController alloc] init];
    photoLibraryAuthorizationStatus = [_fetchPhotoLibrary fetchAssetInformation];
    
    showGallery = [[QTRShowGalleryViewController alloc] init];
    
    customAlertView = [[QTRCustomAlertView alloc] init];
    [customAlertView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.view addSubview:customAlertView];
    
    customActionSheetGalleryView = [[QTRActionSheetGalleryView alloc] init];
    [customActionSheetGalleryView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [customAlertView.galleryCollectionView addSubview:customActionSheetGalleryView];
    
    
    NSDictionary *views = NSDictionaryOfVariableBindings(customAlertView, customActionSheetGalleryView);
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[customAlertView]-0-|" options:0 metrics:0 views:views]];
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[customAlertView]-0-|" options:0 metrics:0 views:views]];
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[customActionSheetGalleryView]-0-|" options:0 metrics:0 views:views]];
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[customActionSheetGalleryView(==66)]" options:0 metrics:0 views:views]];
    
    
    [customActionSheetGalleryView setUserInteractionEnabled:YES];
    customActionSheetGalleryView.fetchPhotoLibrary = _fetchPhotoLibrary;
    
    
    
    [customAlertView.cancelButton addTarget: self action: @selector(touchAlertViewCancel) forControlEvents: UIControlEventTouchUpInside];
    [customAlertView.iCloudButton addTarget: self action: @selector(touchOpeniCloud) forControlEvents: UIControlEventTouchUpInside];
    [customAlertView.cameraRollButton addTarget: self action: @selector(touchOpenCameraRoll) forControlEvents: UIControlEventTouchUpInside];
    [customAlertView.takePhotoButton addTarget: self action: @selector(touchOpenCamera) forControlEvents: UIControlEventTouchUpInside];
    
    [customAlertView setHidden:YES];
    
    
    [[[_devicesView noConnectedDeviceFoundView] refreshButton] addTarget:self action:@selector(noConnectedDeviceFoundAction) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view setBackgroundColor:[UIColor colorWithRed:55.f/255.f green:55.f/255.f blue:55.f/255.f alpha:1.00f]];
    [[_devicesView devicesCollectionView] setBackgroundColor:[UIColor colorWithRed:76.f/255.f green:76.f/255.f blue:76.f/255.f alpha:1.00f]];
    [[_devicesView devicesCollectionView] setBackgroundColor:[UIColor clearColor]];
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    [self setTitle:@"Devices"];
    
    [self.navigationController.navigationBar setBarTintColor:[UIColor colorWithRed:85.f/255.f green:85.f/255.f blue:85.f/255.f alpha:1.00f]];
    
    [[_devicesView devicesCollectionView] registerClass:[QTRHomeCollectionViewCell class] forCellWithReuseIdentifier:cellIdentifier];

    [[_devicesView devicesCollectionView] setDataSource:self];
    [[_devicesView devicesCollectionView] setDelegate:self];
    [_devicesView devicesCollectionView].allowsMultipleSelection = YES;
   

    [[_devicesView devicesCollectionView] reloadData];
    
   
    [[_devicesView deviceRefreshControl] addTarget:self action:@selector(refreshConnectedDevices) forControlEvents:UIControlEventValueChanged];

    [[_devicesView devicesCollectionView] setScrollEnabled:YES];
    [_devicesView devicesCollectionView].alwaysBounceVertical = YES;
    
    QTRRightBarButtonView *customRightBarButton = [[QTRRightBarButtonView alloc]initWithFrame:CGRectZero];
    [customRightBarButton setUserInteractionEnabled:NO];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button addTarget:self action:@selector(RightBarButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    button.frame = customRightBarButton.frame;
    [customRightBarButton addSubview:button];
    
    UIBarButtonItem *rightBarButton = [[UIBarButtonItem alloc] initWithCustomView:customRightBarButton];
    [self.navigationItem setRightBarButtonItem:rightBarButton];
    
    UIBarButtonItem *leftBarButton = [[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"settingIcon"] style:UIBarButtonItemStylePlain target:self action:@selector(setLeftBarButtonAction:)];
    [self.navigationItem setLeftBarButtonItem:leftBarButton];
    
    [[_devicesView sendButton] addTarget:self action:@selector(nextButtonClicked) forControlEvents:UIControlEventTouchUpInside];

    [self.navigationController.navigationBar setTitleTextAttributes:
     @{NSForegroundColorAttributeName:[UIColor whiteColor]}];
   
    [_devicesView searchBar].delegate = self;
    [[_devicesView deviceRefreshControl] beginRefreshing];

}

#pragma mark - Public methods

- (void)setImportedFile:(NSURL *)fileURL {
    _importedFileURL = [fileURL copy];
    
    UIAlertController *alertView = [UIAlertController
                                    alertControllerWithTitle:@"Select User"
                                    message:@"Select the user to whom you want to send the file"
                                    preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* okButton = [UIAlertAction
                                actionWithTitle:@"Ok"
                                style:UIAlertActionStyleDefault
                                handler:^(UIAlertAction * action)
                                {
                                    [alertView dismissViewControllerAnimated:YES completion:nil];
                                    
                                }];
    
    [alertView addAction:okButton];
    [self presentViewController:alertView animated:YES completion:nil];

}

#pragma mark - Actions

- (void)noConnectedDeviceFoundAction {
    
    [[_devicesView noConnectedDeviceFoundView] setHidden:YES];
    [self refreshConnectedDevices];
}

- (void)refreshConnectedDevices {
    [self stopTimer];

    [_devicesView animatePreviewLabel:[_devicesView fetchingDevicesLabel]];
    [[_devicesView fetchingDevicesLabel] setText:@"Fetching Devices"];
    [[_devicesView devicesCollectionView] reloadData];
    [self refresh];
    [self startTimer];

}

- (void)setLeftBarButtonAction:(UIBarButtonItem *)barButton {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];

}

- (void)RightBarButtonAction:(UIBarButtonItem *)barButton {
    QTRTransfersViewController *filestransferViewController = [[QTRTransfersViewController alloc]init];
    [self.navigationController pushViewController:filestransferViewController animated:YES];
    
    
}


-(void)nextButtonClicked{
    
    if (photoLibraryAuthorizationStatus == NO) {
        UIAlertController *alertView = [UIAlertController
                                        alertControllerWithTitle:@"Attention"
                                        message:@"Please give this app permission to access your photo library in your settings app!"
                                        preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* okButton = [UIAlertAction
                                   actionWithTitle:@"Ok"
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction * action)
                                   {
                                       [alertView dismissViewControllerAnimated:YES completion:nil];
                                       
                                   }];
        
        [alertView addAction:okButton];
        [self presentViewController:alertView animated:NO completion:nil];
        
    }else if ([_selectedRecivers count] > 0) {
        
        [customAlertView setHidden:NO];
    }
    
    else {
        
        UIAlertController *alertNextButton = [UIAlertController
                                        alertControllerWithTitle:@"Warning"
                                        message:@"Please Select Atlest One Device"
                                        preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* okButton = [UIAlertAction
                                   actionWithTitle:@"Ok"
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction * action)
                                   {
                                       [alertNextButton dismissViewControllerAnimated:YES completion:nil];
                                       
                                   }];
        
        [alertNextButton addAction:okButton];
        [self presentViewController:alertNextButton animated:YES completion:nil];
    }
    
}


-(void) touchAlertViewCancel {
    [customAlertView setHidden:YES];

}

-(void) touchOpeniCloud {
    [customAlertView setHidden:YES];
}

-(void) touchOpenCameraRoll {
    
    [customAlertView setHidden:YES];
    __weak QTRPhotoLibraryController *weakFetchPhotoLibrary = _fetchPhotoLibrary;
    showGallery.fetchPhotoLibrary = weakFetchPhotoLibrary;
    
    [self.navigationController pushViewController:showGallery animated:YES];

}

-(void) touchOpenCamera {
    
    BOOL isCameraAvailable = [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera];
    
    if (!isCameraAvailable) {
        
        UIAlertController *alertView = [UIAlertController
                                        alertControllerWithTitle:@"Attention"
                                        message:@"Your device does't support this feature!"
                                        preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* okButton = [UIAlertAction
                                   actionWithTitle:@"Ok"
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction * action)
                                   {
                                       [alertView dismissViewControllerAnimated:YES completion:nil];
                                       
                                   }];
        
        [alertView addAction:okButton];
        [self presentViewController:alertView animated:YES completion:nil];
        
    } else {
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.delegate = self;
        picker.allowsEditing = YES;
        picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    
        [self presentViewController:picker animated:YES completion:NULL];
    }
}

#pragma mark - Private methods

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
        
        UIAlertController *alertView = [UIAlertController
                                        alertControllerWithTitle:@"Could not start server"
                                        message:@"Please check that Wifi is turned on"
                                        preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* okButton = [UIAlertAction
                                   actionWithTitle:@"Dismiss"
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction * action)
                                   {
                                       [alertView dismissViewControllerAnimated:YES completion:nil];
                                       
                                   }];
        
        [alertView addAction:okButton];
        [self presentViewController:alertView animated:YES completion:nil];
    }

    _client = [[QTRBonjourClient alloc] initWithDelegate:self];
    [_client setTransferDelegate:_transfersController];
    [_client start];
    
    [self refreshBeacons];
}

- (void)refresh {
    [self stopServices];
    
    __weak QTRConnectedDevicesViewController *weakSelf = self;

    double delayInSeconds = 2.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [weakSelf startServices];
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
    
    UIAlertController *alertView = [UIAlertController
                                    alertControllerWithTitle:@"Accept File?"
                                    message:alertMessage
                                    preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* okButton = [UIAlertAction
                               actionWithTitle:@"Accept"
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction * action)
                               {
                                   NSDictionary *context = [_alertToFileMapTable objectForKey:alertView];
                                   QTRFile *theFile = context[@"file"];
                                   id receiver = context[@"receiver"];
                                   QTRUser *theUser = context[@"user"];
                                   
                                   BOOL shouldAccept = NO;
                                   
                                   shouldAccept = YES;
                                   
                                   if (receiver == _client) {
                                       [_client acceptFile:theFile accept:shouldAccept fromUser:theUser];
                                   } else {
                                       [_server acceptFile:theFile accept:shouldAccept fromUser:theUser];
                                   }
                                   
                                   [_alertToFileMapTable removeObjectForKey:alertView];

                                   [alertView dismissViewControllerAnimated:YES completion:nil];
                                   
                               }];
    
    UIAlertAction* cancelButton = [UIAlertAction
                               actionWithTitle:@"Reject"
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction * action)
                               {
                                   NSDictionary *context = [_alertToFileMapTable objectForKey:alertView];
                                   QTRFile *theFile = context[@"file"];
                                   id receiver = context[@"receiver"];
                                   QTRUser *theUser = context[@"user"];
                                   
                                   BOOL shouldAccept = NO;
                                   
                                   if (receiver == _client) {
                                       [_client acceptFile:theFile accept:shouldAccept fromUser:theUser];
                                   } else {
                                       [_server acceptFile:theFile accept:shouldAccept fromUser:theUser];
                                   }
                                   
                                   [_alertToFileMapTable removeObjectForKey:alertView];
                                   
                                   [alertView dismissViewControllerAnimated:YES completion:nil];

                                   [alertView dismissViewControllerAnimated:YES completion:nil];
                                   
                               }];
    
    [alertView addAction:okButton];
    [alertView addAction:cancelButton];
    
    [_alertToFileMapTable setObject:@{@"file" : file, @"receiver" : receiver, @"user" : user} forKey:alertView];
    [self presentViewController:alertView animated:YES completion:nil];
    
    [self showNotificationIfRequiredWithMessage:alertMessage];
}

- (void)saveFile:(QTRFile *)file {
    [file.data writeToURL:[self uniqueURLForFileWithName:file.name] atomically:YES];

}

- (void)updateTitle {
    unsigned long totalUsers = [_connectedClients count] + [_connectedServers count];
    [self setTitle:[NSString stringWithFormat:@"Devices (%lu)", totalUsers]];
    
    
    
    if (totalUsers > 0) {
        [[_devicesView deviceRefreshControl] endRefreshing];
        [_devicesView animatePreviewLabel:[_devicesView fetchingDevicesLabel]];
        [[_devicesView fetchingDevicesLabel] setText:@""];
        
    } else {
        [[_devicesView deviceRefreshControl] beginRefreshing];
        [_devicesView animatePreviewLabel:[_devicesView fetchingDevicesLabel]];
        [[_devicesView fetchingDevicesLabel] setText:@"Fetching Devices"];

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
         
            [[UIApplication sharedApplication] endBackgroundTask: _backgroundTaskIdentifier];
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
        return [filteredUserData count];
    }
    else {
        return [_connectedServers count] + [_connectedClients count];
    }
    
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {

    QTRHomeCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    QTRUser *theUser;

    if (self.isFiltered) {
        theUser = [filteredUserData objectAtIndex:indexPath.row];
        }
    else {
        theUser = [self userAtIndexPath:indexPath isServer:NULL];
        }
    
    [cell.connectedDeviceName setText:[theUser name]];
    [cell setIconImageByName:theUser.platform];
    
    if ([_selectedRecivers count] > 0) {
        
        if ([_selectedRecivers objectForKey:theUser.identifier] != NULL) {
            cell.connectedDeviceName.textColor = [UIColor colorWithRed:32.f/255.f green:149.f/255.f blue:242.f/255.f alpha:1.00f];
        }
    }
    
    
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
        theUser = [filteredUserData objectAtIndex:indexPath.row];

    } else {
        theUser = [self userAtIndexPath:indexPath isServer:NULL];

    }
    
    if (theUser != nil) {
        [_selectedRecivers removeObjectForKey:theUser.identifier];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL isServer = NO;

    QTRUser *theUser = [self userAtIndexPath:indexPath isServer:&isServer];
    
    if (_importedFileURL == nil) {
        
        _selectedUser = theUser;
        
    } else {
        
        if (isServer) {
            [_client sendFileAtURL:_importedFileURL toUser:theUser];
        } else {
            [_server sendFileAtURL:_importedFileURL toUser:theUser];
        }
        
        _importedFileURL = nil;
    }

    
    if (self.isFiltered) {
        theUser = [filteredUserData objectAtIndex:indexPath.row];

    } else {
        theUser = [self userAtIndexPath:indexPath isServer:NULL];
    }
    
    if (theUser != nil) {
        [_selectedRecivers setObject:theUser forKey:theUser.identifier];
    }
    
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    
    QTRUser *theUser;
    
    if (self.isFiltered) {
        theUser = [filteredUserData objectAtIndex:indexPath.row];
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
    UIAlertController *alertView = [UIAlertController
                                    alertControllerWithTitle:@"File Rejected"
                                    message:[NSString stringWithFormat:@"%@ rejected file: %@", user.name, file.name]
                                    preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* okButton = [UIAlertAction
                               actionWithTitle:@"Dismiss"
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction * action)
                               {
                                   [alertView dismissViewControllerAnimated:YES completion:nil];
                                   
                               }];
    
    [alertView addAction:okButton];
    [self presentViewController:alertView animated:YES completion:nil];
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
        filteredUserData = [[NSMutableArray alloc] init];
        
        for (QTRUser *theUser in _connectedServers)
        {
            if ([theUser.name rangeOfString:text options:NSCaseInsensitiveSearch].location != NSNotFound)
            {
                [filteredUserData addObject:theUser];
            }
        }
        
        for (QTRUser *theUser in _connectedClients)
        {
            if ([theUser.name rangeOfString:text options:NSCaseInsensitiveSearch].location != NSNotFound)
            {
                [filteredUserData addObject:theUser];
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
                UIAlertController *alertView = [UIAlertController
                                                alertControllerWithTitle:@"Error"
                                                message:@"Device is not connected anymore"
                                                preferredStyle:UIAlertControllerStyleAlert];
                
                UIAlertAction* okButton = [UIAlertAction
                                           actionWithTitle:@"Ok"
                                           style:UIAlertActionStyleDefault
                                           handler:^(UIAlertAction * action)
                                           {
                                               [alertView dismissViewControllerAnimated:YES completion:nil];
                                               
                                           }];
                
                [alertView addAction:okButton];
                [self presentViewController:alertView animated:YES completion:nil];
                
            }
            
            _selectedUser = nil;
        }
    
        [picker dismissViewControllerAnimated:YES completion:NULL];
    
    
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    
    [picker dismissViewControllerAnimated:YES completion:NULL];
    
}



#pragma mark: NSTimer Controller

- (void)startTimer {
    if (!_timer) {
        _timer = [NSTimer scheduledTimerWithTimeInterval:5.0f
                                                  target:self
                                                selector:@selector(timerFired:)
                                                userInfo:nil
                                                 repeats:YES];
    }
}

- (void)stopTimer {
    if ([_timer isValid]) {
        [_timer invalidate];
    }
    _timer = nil;
}

- (void)timerFired:(NSTimer *)timer {

    if (([_connectedClients count] + [_connectedServers count]) < 1) {
        [_devicesView animatePreviewLabel:[_devicesView fetchingDevicesLabel]];
        
        [[_devicesView noConnectedDeviceFoundView] setHidden:false];

    }
}


@end
