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

@interface QTRConnectedDevicesViewController () <QTRBonjourClientDelegate, QTRBonjourServerDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UIAlertViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, QTRBeaconRangerDelegate,UICollectionViewDelegateFlowLayout, actionSheetGallaryDelegate> {

    __weak QTRConnectedDevicesView *_devicesView;
    
    UIRefreshControl *refreshControl;

    QTRBonjourClient *_client;
    QTRBonjourServer *_server;
    NSMutableArray *_connectedServers;
    NSMutableArray *_connectedClients;
    NSMutableDictionary *_selectedRecivers;
    QTRUser *_localUser;

    QTRUser *_selectedUser;
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

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //self.view.frame = [[UIScreen mainScreen] bounds];
    
    NSURL *ubiq = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil];
    if (ubiq) {
        NSLog(@"iCloud access at %@", ubiq);
        // TODO: Load document...
    } else {
        NSLog(@"No iCloud access");
    }
    
    _selectedRecivers = [[NSMutableDictionary alloc]init];
    
    self.imagePicker = [[UIImagePickerController alloc] init];
    self.imagePicker.allowsEditing = YES;
    self.imagePicker.delegate = self;
    self.imagePicker.allowsEditing = YES;
    self.imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    
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
    NSLog(@"Reconnecting Devices..");
    [refreshControl endRefreshing];
    //[[_devicesView devicesCollectionView] reloadData];
    [[_devicesView loadDeviceView] startAnimating];
    [self refresh];

}

- (void)settingBarButton:(UIBarButtonItem *)barButton {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];

}

- (void)logsBarButton:(UIBarButtonItem *)barButton {
    NSLog(@"Logs");
    
    NSLog(@"\n_selectedRecivers: %@ ",_selectedRecivers);
    
    
}


- (void)touchRefresh:(UIBarButtonItem *)barButton {
    [self refresh];
}

-(void) userProfile {

    NSLog(@"Custom button");
}

-(void)nextButtonClicked{

    if ([_selectedRecivers count] > 0) {
     
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Select Source" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
            alertController.modalPresentationStyle = UIModalPresentationPopover;
            [alertController sizeForChildContentContainer:self withParentContainerSize:CGSizeMake(200, 200)];
            
            //CGFloat margin = 8.0F;
            //QTRActionControllerGalleryDelegate *delegateObject = [QTRActionControllerGalleryDelegate new];
            
            customView = [[QTRActionSheetGalleryView alloc] init];
            [customView setUserInteractionEnabled:YES];
            customView.delegate = self;
            customView.actionControllerCollectionView.backgroundColor = [UIColor whiteColor];
    
            [customView.actionControllerCollectionView registerClass:[QTRAlertControllerCollectionViewCell class] forCellWithReuseIdentifier:@"cellIdentifier"];
    
            [customView.actionControllerCollectionView setDataSource:customView];
            [customView.actionControllerCollectionView setDelegate:customView];
            customView.actionControllerCollectionView.allowsMultipleSelection = YES;
    
    
            //customView.backgroundColor = [UIColor greenColor];
            [alertController.view addSubview:customView];
    
            UIAlertAction *takePhotoAction2 = [UIAlertAction actionWithTitle:@"Show Gallery" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {   }];
    
            UIAlertAction *takePhotoAction1 = [UIAlertAction actionWithTitle:@"Take a photo" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) { [self takePhoto]; }];
    
            UIAlertAction *cameraAction = [UIAlertAction actionWithTitle:@"Camera Roll" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
    
                QTRShowGalleryViewController * vc = [[QTRShowGalleryViewController alloc] init];
        
                [self.navigationController pushViewController:vc animated:YES];
        

            }];
    
            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {}];
    
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
    
    NSLog(@"Exit");
    
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
    if (_selectedUser != nil) {

        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {

            UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
            [imagePicker setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
            [imagePicker setDelegate:self];

            [self presentViewController:imagePicker animated:YES completion:NULL];
        }
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
        //return 25;
    
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
    
    if ([_selectedRecivers count] > 0) {
        
        if ([_selectedRecivers objectForKey:theUser.identifier] != NULL) {
            NSLog(@"Selected %@", theUser.name);
            cell.connectedDeviceName.textColor = [UIColor colorWithRed:32.f/255.f green:149.f/255.f blue:242.f/255.f alpha:1.00f];
        }
        
       //[_selectedRecivers objectForKey:theUser.identifier]);
        
    }
    
    //[cell setIconImage:@"Demo"];
    //cell.connectedDeviceName.text = @"Demo device Connected";
    //[cell setImage:[UIImage imageNamed:@"loadBtnCloud.png"]];
    
    return cell;
    
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(100, 100);
}


#pragma mark - UICollectionViewDelegate methods
//
//
- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
//    QTRHomeCollectionViewCell *cell = (QTRHomeCollectionViewCell *)[[_devicesView devicesCollectionView] cellForItemAtIndexPath:indexPath];
//    cell.connectedDeviceName.textColor = [UIColor whiteColor];
    
    //QTRUser *theUser = [self userAtIndexPath:indexPath isServer:NULL];
    
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
//    QTRHomeCollectionViewCell *cell = (QTRHomeCollectionViewCell *)[[_devicesView devicesCollectionView] cellForItemAtIndexPath:indexPath];
//    cell.connectedDeviceName.textColor = [UIColor colorWithRed:32.f/255.f green:149.f/255.f blue:242.f/255.f alpha:1.00f];
    
//    BOOL isServer = NO;
//    
//    QTRUser *theUser = [self userAtIndexPath:indexPath isServer:&isServer];
//    
//    if (_importedFileURL == nil) {
//        
//        _selectedUser = theUser;
//        [self touchShare:nil];
//        
//    } else {
//        
//        if (isServer) {
//            [_client sendFileAtURL:_importedFileURL toUser:theUser];
//        } else {
//            [_server sendFileAtURL:_importedFileURL toUser:theUser];
//        }
//        
//        _importedFileURL = nil;
//    }
    
    
    
    QTRUser *theUser;
    
    if (self.isFiltered) {
        theUser = [self.filteredUserData objectAtIndex:indexPath.row];

    } else {
        theUser = [self userAtIndexPath:indexPath isServer:NULL];
    }
    
    //QTRUser *theUser = [self userAtIndexPath:indexPath isServer:NULL];
    [_selectedRecivers setObject:theUser forKey:theUser.identifier];

    NSLog(@"User %lu  Selected..",[_selectedRecivers count]);
    

    
}
//
//
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

#pragma mark - UIImagePickerControllerDelegate methods

//- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
//
//    NSURL *referenceURL = info[UIImagePickerControllerReferenceURL];
//    
//    [_assetsLibrary assetForURL:referenceURL resultBlock:^(ALAsset *asset) {
//        NSURL *localURL = [self uniqueURLForFileWithName:[referenceURL lastPathComponent]];
//        ALAssetRepresentation *assetRepresentation = [asset defaultRepresentation];
//        
//        uint8_t *imageBytes = malloc((long)[assetRepresentation size]);
//        [assetRepresentation getBytes:imageBytes fromOffset:0 length:(long)[assetRepresentation size] error:nil];
//        
//        NSData *imageData = [NSData dataWithBytes:imageBytes length:(long)[assetRepresentation size]];
//        [imageData writeToURL:localURL atomically:YES];
//        
//        free(imageBytes);
//        
//        
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
//        
//        
//    } failureBlock:^(NSError *error) {
//        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Could not load file" delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil, nil];
//        [alertView show];
//    }];
//    
//    [self dismissViewControllerAnimated:YES completion:NULL];
//}

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
    
    // Set source to the camera
    self.imagePicker.sourceType =  UIImagePickerControllerSourceTypeCamera;
    
    // Delegate is self
    self.imagePicker.delegate = self;
    
    // Allow editing of image ?
    self.imagePicker.allowsEditing = NO;
    
    // Show image picker
    [self presentViewController:self.imagePicker animated:YES completion:nil];

}

#pragma mark - Search Bar methods


-(void)searchBar:(UISearchBar*)searchBar textDidChange:(NSString*)text
{
    //NSLog(@"searchBar ... text.length: %d", text.length);
    
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
                NSLog(@"Found Server: %@",theUser.name);
                [self.filteredUserData addObject:theUser];
            }
            
        }
        
        for (QTRUser *theUser in _connectedClients)
        {
            //case insensative search - way cool
            if ([theUser.name rangeOfString:text options:NSCaseInsensitiveSearch].location != NSNotFound)
            {
                [self.filteredUserData addObject:theUser];
                NSLog(@"Found Client: %@",theUser.name);
            }
            
        }
        
        
    }//end if-else
    
    NSLog(@"\n text:%@ ",text);
//    NSLog(@"Connected Client: %@",_connectedClients);
//    NSLog(@"Connected Servers: %@",_connectedServers);
    

    [[_devicesView devicesCollectionView] reloadData];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    //User hit Search button on Keyboard
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
