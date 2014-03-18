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

#import "QTRBonjourClient.h"
#import "QTRBonjourServer.h"
#import "QTRUser.h"
#import "QTRFile.h"
#import "QTRConstants.h"

#import "QTRBeaconHelper.h"




@interface QTRConnectedDevicesViewController () <QTRBonjourClientDelegate, QTRBonjourServerDelegate, UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, QTRBeaconRangerDelegate> {

    __weak QTRConnectedDevicesView *_devicesView;

    QTRBonjourClient *_client;
    QTRBonjourServer *_server;
    NSMutableArray *_connectedServers;
    NSMutableArray *_connectedClients;
    QTRUser *_localUser;

    QTRUser *_selectedUser;
    NSMapTable *_alertToFileMapTable;
    
    NSURL *_fileCacheDirectory;
    
    ALAssetsLibrary *_assetsLibrary;

    UIBackgroundTaskIdentifier _backgroundTaskIdentifier;
    NSDate *_killDate;

    QTRBeaconRanger *_beaconRanger;
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

@implementation QTRConnectedDevicesViewController

#pragma mark - Initialisation

- (id)init {
    self = [super init];
    if (self != nil) {

        if ([QTRBeaconHelper isBLEAvailable]) {
            _beaconRanger = [[QTRBeaconRanger alloc] init];
            [_beaconRanger setDelegate:self];
            [_beaconRanger startRangingBeaconsWithProximityUUID:QTRBeaconRegionProximityUUID identifier:QTRBeaconRegionProximityUUID majorValue:0 minorValue:0];
        }

        _assetsLibrary = [[ALAssetsLibrary alloc] init];

        _alertToFileMapTable = [NSMapTable weakToStrongObjectsMapTable];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];

        _backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
            [[UIApplication sharedApplication] endBackgroundTask:_backgroundTaskIdentifier];
            _backgroundTaskIdentifier = UIBackgroundTaskInvalid;
        }];

        [self startServices];
    }

    return self;
}

#pragma mark - View lifecycle

- (void)loadView {
    QTRConnectedDevicesView *view = [[QTRConnectedDevicesView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [view setAutoresizingMask:(UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth)];
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
	// Do any additional setup after loading the view.
    
    [self setTitle:@"Select Devices"];

    [[_devicesView devicesTableView] setDataSource:self];
    [[_devicesView devicesTableView] setDelegate:self];

    UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithTitle:@"Refresh" style:UIBarButtonItemStylePlain target:self action:@selector(touchRefresh:)];
    [self.navigationItem setRightBarButtonItem:barButton];
}

#pragma mark - Actions

- (void)stopServices {
    [_server setDelegate:nil];
    [_server stop];
    _server = nil;
    
    [_client setDelegate:nil];
    [_client stop];
    _client = nil;
    
    [_connectedClients removeAllObjects];
    
    [_connectedServers removeAllObjects];
    
    [[_devicesView devicesTableView] reloadData];
}

- (void)touchRefresh:(UIBarButtonItem *)barButton {

    [self stopServices];

    double delayInSeconds = 2.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self startServices];
    });
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

- (NSURL *)uniqueURLForFileWithName:(NSString *)fileName {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *cachesURL = [self fileCacheDirectory];
    
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

    if (![_server start]) {

        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Could not start server" message:@"Please check that Wifi is turned on" delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil, nil];
        [alert show];
    }

    _client = [[QTRBonjourClient alloc] initWithDelegate:self];
    [_client start];
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
    UIImage *theImage = [[UIImage alloc] initWithData:file.data];

    if (theImage != nil) {
        UIImageWriteToSavedPhotosAlbum(theImage, nil, nil, nil);
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"File Saved" message:[NSString stringWithFormat:@"Saved %@ to your photos album", file.name] delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil, nil];
        [alert show];
        
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"The file doesn't appear to be an image" delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil, nil];
        [alert show];
    }
}

#pragma mark - Notifications

- (void)applicationDidEnterBackground:(NSNotification *)notification {
    NSTimeInterval backgroundTimeRemaining = [[UIApplication sharedApplication] backgroundTimeRemaining];
    if (backgroundTimeRemaining > 25) {
        _killDate = [NSDate dateWithTimeIntervalSinceNow:backgroundTimeRemaining];
        backgroundTimeRemaining -= 20;
        UILocalNotification *localNotification = [[UILocalNotification alloc] init];
        [localNotification setFireDate:[NSDate dateWithTimeIntervalSinceNow:backgroundTimeRemaining]];
        [localNotification setAlertBody:@"You will be disconnected from other devices if you do not launch the app now."];
        [localNotification setSoundName:UILocalNotificationDefaultSoundName];
        [[UIApplication sharedApplication] cancelAllLocalNotifications];
        [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
    }
}

- (void)applicationDidEnterForeground:(NSNotification *)notification {
    if ([[NSDate date] compare:_killDate] == NSOrderedDescending) {

        [[UIApplication sharedApplication] endBackgroundTask:_backgroundTaskIdentifier];
        _backgroundTaskIdentifier = UIBackgroundTaskInvalid;

        [self touchRefresh:nil];
    }
}

#pragma mark - UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_connectedServers count] + [_connectedClients count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *ConnectedDevicesTableCellIdentifier = @"ConnectedDevicesTableCellIdentifier";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ConnectedDevicesTableCellIdentifier];

    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ConnectedDevicesTableCellIdentifier];
    }

    QTRUser *theUser = [self userAtIndexPath:indexPath isServer:NULL];

    [cell.textLabel setText:[theUser name]];

    return cell;
}

#pragma mark - UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    QTRUser *theUser = [self userAtIndexPath:indexPath isServer:NULL];
    _selectedUser = theUser;
    [self touchShare:nil];

    [tableView deselectRowAtIndexPath:indexPath animated:YES];

}

#pragma mark - QTRBonjourServerDelegate methods

- (void)server:(QTRBonjourServer *)server didConnectToUser:(QTRUser *)user {
    if (![self userConnected:user]) {

        [_connectedClients addObject:user];
        [[_devicesView devicesTableView] reloadData];

    }
}

- (void)server:(QTRBonjourServer *)server didDisconnectUser:(QTRUser *)user {
    [_connectedClients removeObject:user];
    [[_devicesView devicesTableView] reloadData];
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
        [[_devicesView devicesTableView] reloadData];

    }
}

- (void)client:(QTRBonjourClient *)client didDisconnectFromServerForUser:(QTRUser *)user {
    [_connectedServers removeObject:user];

    [[_devicesView devicesTableView] reloadData];
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

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {

    NSURL *referenceURL = info[UIImagePickerControllerReferenceURL];
    
    [_assetsLibrary assetForURL:referenceURL resultBlock:^(ALAsset *asset) {
        NSURL *localURL = [self uniqueURLForFileWithName:[referenceURL lastPathComponent]];
        ALAssetRepresentation *assetRepresentation = [asset defaultRepresentation];
        
        uint8_t *imageBytes = malloc((long)[assetRepresentation size]);
        [assetRepresentation getBytes:imageBytes fromOffset:0 length:(long)[assetRepresentation size] error:nil];
        
        NSData *imageData = [NSData dataWithBytes:imageBytes length:(long)[assetRepresentation size]];
        [imageData writeToURL:localURL atomically:YES];
        
        free(imageBytes);
        
        
        if ([_connectedClients containsObject:_selectedUser]) {
            [_server sendFileAtURL:localURL toUser:_selectedUser];
        } else if ([_connectedServers containsObject:_selectedUser]) {
            [_client sendFileAtURL:localURL toUser:_selectedUser];
        } else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"%@ is not connected anymore", _selectedUser.name] delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil, nil];
            [alert show];
        }
        
        _selectedUser = nil;
        
        
    } failureBlock:^(NSError *error) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Could not load file" delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil, nil];
        [alertView show];
    }];
    
    [self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - QTRBeaconRangerDelegate methods

- (void)beaconRangerDidEnterRegion:(QTRBeaconRanger *)beaconRanger {
    
    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
    [localNotification setFireDate:[NSDate date]];
    [localNotification setSoundName:UILocalNotificationDefaultSoundName];
    [localNotification setAlertBody:@"Entered beacon region!"];
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];

    [self touchRefresh:nil];
}


@end
