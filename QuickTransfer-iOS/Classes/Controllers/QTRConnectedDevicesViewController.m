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

@interface QTRConnectedDevicesViewController () <QTRBonjourClientDelegate, QTRBonjourServerDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UIAlertViewDelegate, UINavigationControllerDelegate, QTRBeaconRangerDelegate,UICollectionViewDelegateFlowLayout, actionSheetGallaryDelegate> {

    __weak QTRConnectedDevicesView *_devicesView;
    
    QTRSelectedUserInfo *_userInfo;
    
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

//- (UIStatusBarStyle)preferredStatusBarStyle
//{
//
//    return UIStatusBarStyleLightContent;
//}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSURL *ubiq = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil];
    if (ubiq) {
        NSLog(@"iCloud access at %@", ubiq);
        // TODO: Load document...
    } else {
        NSLog(@"No iCloud access");
    }
    
    _userInfo = [[QTRSelectedUserInfo alloc]init];
    _userInfo._selectedRecivers = [[NSMutableDictionary alloc]init];
    
    [self.view setBackgroundColor:[UIColor colorWithRed:76.f/255.f green:76.f/255.f blue:76.f/255.f alpha:1.00f]];
    [[_devicesView devicesCollectionView] setBackgroundColor:[UIColor colorWithRed:76.f/255.f green:76.f/255.f blue:76.f/255.f alpha:1.00f]];
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    [self setTitle:@"Devices"];
    
    [self.navigationController.navigationBar setBarTintColor:[UIColor colorWithRed:85.f/255.f green:85.f/255.f blue:85.f/255.f alpha:1.00f]];
    
    [[_devicesView devicesCollectionView] registerClass:[QTRHomeCollectionViewCell class] forCellWithReuseIdentifier:@"cellIdentifier"];

    [[_devicesView devicesCollectionView] setDataSource:self];
    [[_devicesView devicesCollectionView] setDelegate:self];
    [_devicesView devicesCollectionView].allowsMultipleSelection = YES;
   

    [[_devicesView devicesCollectionView] reloadData];
    
    refreshControl = [[UIRefreshControl alloc]init];
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
    [[_devicesView loadDeviceView] startAnimating];
    [_devicesView loadDeviceView].frame = self.view.frame;
    [_devicesView searchBar].delegate = self;
    [self refresh];

}

#pragma mark - Public methods

- (void)setImportedFile:(NSURL *)fileURL {
    _importedFileURL = [fileURL copy];

    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Select User" message:@"Select the user to whom you want to send the file" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
    [alertView show];
}

#pragma mark - Actions

-(void) refreshConnectedDevices {
    [refreshControl endRefreshing];
    [[_devicesView loadDeviceView] startAnimating];
    [self refresh];

}

- (void)settingBarButton:(UIBarButtonItem *)barButton {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];

}

- (void)logsBarButton:(UIBarButtonItem *)barButton {
    NSLog(@"\n_selectedRecivers: %@ ",_userInfo._selectedRecivers);
    
//    QTRTransfersViewController *tv = [QTRTransfersViewController new];
    
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

    if ([_userInfo._selectedRecivers count] > 0) {
     
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Select Source" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
            alertController.modalPresentationStyle = UIModalPresentationPopover;
            [alertController sizeForChildContentContainer:self withParentContainerSize:CGSizeMake(200, 200)];

            [customView setUserInteractionEnabled:YES];
            customView.delegate = self;
            customView.actionControllerCollectionView.backgroundColor = [UIColor whiteColor];
        
        
            customView = [[QTRActionSheetGalleryView alloc] init];
    
            [customView.actionControllerCollectionView registerClass:[QTRAlertControllerCollectionViewCell class] forCellWithReuseIdentifier:@"cellIdentifier"];
    
            [customView.actionControllerCollectionView setDataSource:customView];
            [customView.actionControllerCollectionView setDelegate:customView];
            customView.actionControllerCollectionView.allowsMultipleSelection = YES;
    
            [alertController.view addSubview:customView];
    
            UIAlertAction *takePhotoAction2 = [UIAlertAction actionWithTitle:@"Show Gallery" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {   }];
    
            UIAlertAction *takePhotoAction1 = [UIAlertAction actionWithTitle:@"Take a photo" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) { [self takePhoto]; }];
    
            UIAlertAction *cameraAction = [UIAlertAction actionWithTitle:@"Camera Roll" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                
                [customView removeFromSuperview];
                [alertController dismissViewControllerAnimated:YES completion:nil];
    
                QTRShowGalleryViewController *showGallery = [[QTRShowGalleryViewController alloc] init];
                showGallery.reciversInfo = _userInfo;
                [self.navigationController pushViewController:showGallery animated:YES];
        

            }];
    
            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                NSLog(@"%@", alertController.view.subviews);
            }];
    
            UIAlertAction *iCloudeAction = [UIAlertAction actionWithTitle:@"iCloud" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {}];
            [takePhotoAction2 setEnabled:NO];
    
            [alertController addAction:takePhotoAction2];
            [alertController addAction:takePhotoAction1];
            [alertController addAction:cameraAction];
            [alertController addAction:cancelAction];
            [alertController addAction:iCloudeAction];
        
   
            [self presentViewController:alertController animated:YES completion:^{}];
        

        }
        else {
        
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Message" message:@"First Select Atleast One Reciver" preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction* ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
            [alertController addAction:ok];
            
            [self presentViewController:alertController animated:YES completion:nil];
        }
    
    
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    //You can retrieve the actual UIImage
    image = [info valueForKey:UIImagePickerControllerOriginalImage];
    //Or you can get the image url from AssetsLibrary
    path = [info valueForKey:UIImagePickerControllerReferenceURL];
    
    NSLog(@"image:%@  path:%@",image.description, path.description);
    
    [picker dismissViewControllerAnimated:YES completion:^{
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {


 NSLog(@"image:%@  path:%@",image.description, path.description);
}




- (void)touchShare:(UIBarButtonItem *)barButton {
    if (_userInfo._selectedUser != nil) {

        NSLog(@"Sharing Files..");
//        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
//
//            UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
//            [imagePicker setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
//            [imagePicker setDelegate:self];
//
//            [self presentViewController:imagePicker animated:YES completion:NULL];
//        }
    }
}

#pragma mark - Private methods

- (void)stopServices {
    [_userInfo._server setDelegate:nil];
    [_userInfo._server setTransferDelegate:nil];
    [_userInfo._server stop];
    _userInfo._server = nil;

    [_userInfo._client setDelegate:nil];
    [_userInfo._client setTransferDelegate:nil];
    [_userInfo._client stop];
    _userInfo._client = nil;

    [_userInfo._connectedClients removeAllObjects];

    [_userInfo._connectedServers removeAllObjects];

    [[_devicesView devicesCollectionView] reloadData];

    [_beaconAdvertiser stopAdvertisingBeaconRegion];
    [_beaconRanger stopRangingBeacons];

    _importedFileURL = nil;
}

- (void)startServices {

    _userInfo._connectedServers = [NSMutableArray new];
    _userInfo._connectedClients = [NSMutableArray new];
    NSString *uuid = [[NSUserDefaults standardUserDefaults] stringForKey:QTRBonjourTXTRecordIdentifierKey];
    if ([uuid isKindOfClass:[NSNull class]] || uuid == nil) {
        uuid = [[NSUUID UUID] UUIDString];
        [[NSUserDefaults standardUserDefaults] setObject:uuid forKey:QTRBonjourTXTRecordIdentifierKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }

    _userInfo._localUser = [[QTRUser alloc] initWithName:[[UIDevice currentDevice] name] identifier:uuid platform:QTRUserPlatformIOS];

    _userInfo._server = [[QTRBonjourServer alloc] initWithFileDelegate:self];
    [_userInfo._server setTransferDelegate:_transfersController];

    if (![_userInfo._server start]) {

        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Could not start server" message:@"Please check that Wifi is turned on" delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil, nil];
        [alert show];
    }

    _userInfo._client = [[QTRBonjourClient alloc] initWithDelegate:self];
    [_userInfo._client setTransferDelegate:_transfersController];
    [_userInfo._client start];

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
    return [_userInfo._connectedClients containsObject:user] || [_userInfo._connectedServers containsObject:user] || [_userInfo._localUser isEqual:user];
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

    if ([_userInfo._connectedServers count] > row) {
        theUser = _userInfo._connectedServers[row];
        if (isServer != NULL) {
            *isServer = YES;
        }
    } else {
        row -= [_userInfo._connectedServers count];
        if ([_userInfo._connectedClients count] > row) {
            theUser = _userInfo._connectedClients[row];
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
    unsigned long totalUsers = [_userInfo._connectedClients count] + [_userInfo._connectedServers count];
    [self setTitle:[NSString stringWithFormat:@"Devices (%lu)", totalUsers]];
    
    if (totalUsers > 0) {
        [[_devicesView loadDeviceView] stopAnimating];
    } else {
        [[_devicesView loadDeviceView] startAnimating];
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
    
    int noOfItems = (self.view.frame.size.width - 6) / 100;
    int totalRemSpace = self.view.frame.size.width - (noOfItems * 100);
    
    CGFloat gap = (CGFloat)totalRemSpace / (CGFloat)(noOfItems + 1);
    
    return UIEdgeInsetsMake(0.0f, gap, 0.0f, gap);
}

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {

    if (self.isFiltered) {
        return [self.filteredUserData count];
    }
    else {
        return [_userInfo._connectedServers count] + [_userInfo._connectedClients count];
    }
    
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {

    QTRHomeCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    QTRUser *theUser;
    
    if (self.isFiltered) {
        theUser = [self.filteredUserData objectAtIndex:indexPath.row];
        [cell.connectedDeviceName setText:[theUser name]];
        
        [cell setIconImage:theUser.platform];

    }
    else {
        theUser = [self userAtIndexPath:indexPath isServer:NULL];
        [cell.connectedDeviceName setText:[theUser name]];
    
        [cell setIconImage:theUser.platform];
    }

    NSLog(@"Reloaded.. %@",theUser.name);
    
    if ([_userInfo._selectedRecivers count] > 0) {
        
        if ([_userInfo._selectedRecivers objectForKey:theUser.identifier] != NULL) {
            NSLog(@"Selected %@", theUser.name);
            cell.connectedDeviceName.textColor = [UIColor colorWithRed:32.f/255.f green:149.f/255.f blue:242.f/255.f alpha:1.00f];
        }
        
    }

    
    return cell;
    
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(100, 100);
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
    
    [_userInfo._selectedRecivers removeObjectForKey:theUser.identifier];
    
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL isServer = NO;

    QTRUser *theUser = [self userAtIndexPath:indexPath isServer:&isServer];
    
    if (_importedFileURL == nil) {
        
        _userInfo._selectedUser = theUser;
        [self touchShare:nil];
        
    } else {
        
        if (isServer) {
            [_userInfo._client sendFileAtURL:_importedFileURL toUser:theUser];
        } else {
            [_userInfo._server sendFileAtURL:_importedFileURL toUser:theUser];
        }
        
        _importedFileURL = nil;
    }

    
    if (self.isFiltered) {
        theUser = [self.filteredUserData objectAtIndex:indexPath.row];

    } else {
        theUser = [self userAtIndexPath:indexPath isServer:NULL];
    }
    
    //QTRUser *theUser = [self userAtIndexPath:indexPath isServer:NULL];
    [_userInfo._selectedRecivers setObject:theUser forKey:theUser.identifier];

    NSLog(@"User %lu  Selected..",[_userInfo._selectedRecivers count]);
    
}

#pragma mark - QTRBonjourServerDelegate methods

- (void)server:(QTRBonjourServer *)server didConnectToUser:(QTRUser *)user {
    if (![self userConnected:user]) {

        [_userInfo._connectedClients addObject:user];
        [self updateTitle];
        [[_devicesView devicesCollectionView] reloadData];

    }
}

- (void)server:(QTRBonjourServer *)server didDisconnectUser:(QTRUser *)user {
    [_userInfo._connectedClients removeObject:user];
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
    return _userInfo._localUser;
}

- (BOOL)client:(QTRBonjourClient *)client shouldConnectToUser:(QTRUser *)user {
    return ![self userConnected:user];
}

- (void)client:(QTRBonjourClient *)client didConnectToServerForUser:(QTRUser *)user {

    if (![self userConnected:user]) {

        [_userInfo._connectedServers addObject:user];
        [self updateTitle];
        [[_devicesView devicesCollectionView] reloadData];

    }
}

- (void)client:(QTRBonjourClient *)client didDisconnectFromServerForUser:(QTRUser *)user {
    [_userInfo._connectedServers removeObject:user];
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
    
    if (receiver == _userInfo._client) {
        [_userInfo._client acceptFile:theFile accept:shouldAccept fromUser:theUser];
    } else {
        [_userInfo._server acceptFile:theFile accept:shouldAccept fromUser:theUser];
    }

    [_alertToFileMapTable removeObjectForKey:alertView];
}

#pragma mark - QTRBeaconRangerDelegate methods

- (void)beaconRangerDidEnterRegion:(QTRBeaconRanger *)beaconRanger {
    if ([[UIApplication sharedApplication] applicationState] != UIApplicationStateActive) {
        NSLog(@"Did enter region");
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

- (void) QTRActionSheetGalleryView:(QTRActionSheetGalleryView *)QTRActionSheetGalleryView didCellSelected:(BOOL)selected withCollectionCell:(QTRAlertControllerCollectionViewCell *)alertControllerCollectionViewCell {
    if (selected) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}


-(void)takePhoto {

    NSLog(@"Finding Camera..");
    

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
        
        for (QTRUser *theUser in _userInfo._connectedServers)
        {
            //case insensative search - way cool
            if ([theUser.name rangeOfString:text options:NSCaseInsensitiveSearch].location != NSNotFound)
            {
                [self.filteredUserData addObject:theUser];
            }
        }
        
        for (QTRUser *theUser in _userInfo._connectedClients)
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



@end
