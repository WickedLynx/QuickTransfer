//
//  QTRConnectedDevicesViewController.m
//  QuickTransfer
//
//  Created by Harshad on 20/02/14.
//  Copyright (c) 2014 Laughing Buddha Software. All rights reserved.
//

#import "QTRConnectedDevicesViewController.h"
#import "QTRConnectedDevicesView.h"

#import "QTRBonjourClient.h"
#import "QTRBonjourServer.h"
#import "QTRUser.h"
#import "QTRFile.h"
#import "QTRConstants.h"

@interface QTRConnectedDevicesViewController () <QTRBonjourClientDelegate, QTRBonjourServerDelegate, UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate> {

    __weak QTRConnectedDevicesView *_devicesView;

    QTRBonjourClient *_client;
    QTRBonjourServer *_server;
    NSMutableArray *_connectedServers;
    NSMutableArray *_connectedClients;
    QTRUser *_localUser;

    QTRUser *_selectedUser;
    NSMapTable *_alertToFileMapTable;
}

- (void)touchShare:(UIBarButtonItem *)barButton;
- (void)touchRefresh:(UIBarButtonItem *)barButton;
- (void)startServices;
- (void)showAlertForFile:(QTRFile *)file user:(QTRUser *)user;
- (void)saveFile:(QTRFile *)file;
- (BOOL)userConnected:(QTRUser *)user;
- (QTRUser *)userAtIndexPath:(NSIndexPath *)indexPath isServer:(BOOL *)isServer;

@end

@implementation QTRConnectedDevicesViewController

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

    _alertToFileMapTable = [NSMapTable weakToStrongObjectsMapTable];

    [self startServices];

    UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithTitle:@"Refresh" style:UIBarButtonItemStylePlain target:self action:@selector(touchRefresh:)];
    [self.navigationItem setRightBarButtonItem:barButton];
}


#pragma mark - Actions

- (void)touchRefresh:(UIBarButtonItem *)barButton {

    [_server setDelegate:nil];
    [_server stop];
    _server = nil;

    [_client setDelegate:nil];
    [_client stop];
    _client = nil;

    [_connectedClients removeAllObjects];

    [_connectedServers removeAllObjects];

    [[_devicesView devicesTableView] reloadData];

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

- (BOOL)userConnected:(QTRUser *)user {
    return [_connectedClients containsObject:user] || [_connectedServers containsObject:user] || [_localUser isEqual:user];
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

- (void)showAlertForFile:(QTRFile *)file user:(QTRUser *)user {

    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Received File" message:[NSString stringWithFormat:@"%@ sent you  a file: %@", user.name, file.name] delegate:self cancelButtonTitle:@"Save" otherButtonTitles:@"Discard", nil];
    [_alertToFileMapTable setObject:file forKey:alert];
    [alert show];
}

- (void)saveFile:(QTRFile *)file {
    UIImage *theImage = [[UIImage alloc] initWithData:file.data];

    if (theImage != nil) {
        UIImageWriteToSavedPhotosAlbum(theImage, nil, nil, nil);
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"The file doesn't appear to be an image" delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil, nil];
        [alert show];
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
    [self showAlertForFile:file user:user];
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
    [self showAlertForFile:file user:user];
}

#pragma mark - UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {

    if (buttonIndex == [alertView cancelButtonIndex]) {
        QTRFile *theFile = [_alertToFileMapTable objectForKey:alertView];
        [self saveFile:theFile];
    }

    [_alertToFileMapTable removeObjectForKey:alertView];
}

#pragma mark - UIImagePickerControllerDelegate methods

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {

    UIImage *image = info[UIImagePickerControllerOriginalImage];
    NSURL *referenceURL = info[UIImagePickerControllerReferenceURL];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSString *imageName = [[referenceURL path] lastPathComponent];
        if (imageName == nil) {
            imageName = @"Image.png";
        }

        NSData *imageData = [NSData dataWithContentsOfURL:referenceURL];
        if (imageData == nil) {
            imageData = UIImagePNGRepresentation(image);
        }

        QTRFile *file = [[QTRFile alloc] initWithName:imageName type:@"png" data:imageData];
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([_connectedClients containsObject:_selectedUser]) {
                [_server sendFile:file toUser:_selectedUser];
            } else if ([_connectedServers containsObject:_selectedUser]) {
                [_client sendFile:file toUser:_selectedUser];
            } else {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"%@ is not connected anymore", _selectedUser.name] delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil, nil];
                [alert show];
            }
        });

    });

    [self dismissViewControllerAnimated:YES completion:NULL];
}




@end
