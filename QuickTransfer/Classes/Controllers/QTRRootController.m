//
//  QTRRootController.m
//  QuickTransfer
//
//  Created by Harshad on 18/02/14.
//  Copyright (c) 2014 Laughing Buddha Software. All rights reserved.
//

#import "QTRRootController.h"
#import "QTRBonjourClient.h"
#import "QTRBonjourServer.h"
#import "QTRUser.h"
#import "QTRConstants.h"
#import "QTRFile.h"
#include <stdlib.h>
#include <stdio.h>
#include <sys/types.h>
#include <sys/sysctl.h>

static char *computerModel = NULL;


@interface QTRRootController () <NSTableViewDataSource, NSTableViewDelegate, QTRBonjourClientDelegate, QTRBonjourServerDelegate, NSOpenSavePanelDelegate> {
    NSStatusItem *_statusItem;
    QTRBonjourServer *_server;
    QTRBonjourClient *_client;
    NSMutableArray *_connectedServers;
    NSMutableArray *_connectedClients;
    QTRUser *_localUser;
    QTRUser *_selectedUser;
    NSString *_downloadsDirectory;
    long _clickedRow;
}

@property (weak) IBOutlet NSTableView *devicesTableView;
@property (weak) IBOutlet NSMenuItem *localComputerNameItem;
@property (weak) IBOutlet NSMenuItem *sendFileSubMenuItem;
@property (weak) IBOutlet NSMenu *statusBarMenu;
@property (strong) IBOutlet NSWindow *mainWindow;

- (IBAction)clickSendFile:(id)sender;
- (NSString *)downloadsDirectory;
- (void)saveFile:(QTRFile *)file;
- (IBAction)clickRefresh:(id)sender;
- (void)showAlertForFile:(QTRFile *)file user:(QTRUser *)user;
- (void) alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;
- (QTRUser *)userAtRow:(long)row isServer:(BOOL *)isServer;
- (BOOL)userConnected:(QTRUser *)user;
- (IBAction)clickStopServices:(id)sender;
- (IBAction)clickConnectedDevices:(id)sender;

@end

@implementation QTRRootController

void refreshComputerModel() {
    size_t len = 0;
    sysctlbyname("hw.model", NULL, &len, NULL, 0);
    if (len) {
        char *model = malloc(len*sizeof(char));
        sysctlbyname("hw.model", model, &len, NULL, 0);
        computerModel = model;
    }
}

- (void)startServices {
    if (computerModel == NULL) {
        refreshComputerModel();
    }
    _connectedServers = [NSMutableArray new];
    _connectedClients = [NSMutableArray new];
    NSString *uuid = [[NSUserDefaults standardUserDefaults] stringForKey:QTRBonjourTXTRecordIdentifierKey];
    if ([uuid isKindOfClass:[NSNull class]] || uuid == nil) {
        uuid = [[NSUUID UUID] UUIDString];
        [[NSUserDefaults standardUserDefaults] setObject:uuid forKey:QTRBonjourTXTRecordIdentifierKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    NSString *computerName = @"Mac";
    if (computerModel != NULL) {
        computerName = [NSString stringWithCString:computerModel encoding:NSUTF8StringEncoding];
    }
    NSString *username = [NSString stringWithFormat:@"%@'s %@", NSUserName(), computerName];
    _localUser = [[QTRUser alloc] initWithName:username identifier:uuid platform:QTRUserPlatformMac];
    
    _server = [[QTRBonjourServer alloc] initWithFileDelegate:self];
    
    if (![_server start]) {
        NSAlert *alert = [NSAlert alertWithMessageText:@"Could not start server" defaultButton:@"Ok" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Please make sure WiFi/Ethernet is enabled and connected"];
        [alert runModal];
    }
    
    _client = [[QTRBonjourClient alloc] initWithDelegate:self];
    [_client start];
}

- (void)awakeFromNib {
    [super awakeFromNib];

    _statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [_statusItem setHighlightMode:YES];
    [_statusItem setTitle:@"QTR"];

    [_statusItem setMenu:self.statusBarMenu];

    [self startServices];

}

#pragma mark - Private methods

- (NSString *)downloadsDirectory {
    if (_downloadsDirectory == nil) {
        _downloadsDirectory = [NSSearchPathForDirectoriesInDomains(NSDownloadsDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    }

    return _downloadsDirectory;
}

- (BOOL)userConnected:(QTRUser *)user {
    return [_connectedClients containsObject:user] || [_connectedServers containsObject:user] || [_localUser isEqual:user];
}

- (QTRUser *)userAtRow:(long)row isServer:(BOOL *)isServer {

    QTRUser *theUser = nil;
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

- (void)saveFile:(QTRFile *)file {
    NSString *fileName = file.name;
    NSString *savePath = [[self downloadsDirectory] stringByAppendingPathComponent:fileName];
    if ([[NSFileManager defaultManager] fileExistsAtPath:savePath]) {
        fileName = [NSString stringWithFormat:@"%@ %@", [NSDate date], file.name];
        savePath = [[self downloadsDirectory] stringByAppendingPathComponent:fileName];
    }
    [file.data writeToFile:savePath atomically:YES];
}

- (void) alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    QTRFile *file = CFBridgingRelease(contextInfo);
    if (returnCode == NSAlertDefaultReturn) {
        [self saveFile:file];
    }
}

- (void)showAlertForFile:(QTRFile *)file user:(QTRUser *)user {
    NSAlert *alert = [NSAlert alertWithMessageText:[NSString stringWithFormat:@"%@ sent file: %@", user.name, file.name] defaultButton:@"Save" alternateButton:@"Discard" otherButton:nil informativeTextWithFormat:@"Clicking save will save it to Downloads"];
    [alert beginSheetModalForWindow:[[NSApplication sharedApplication] keyWindow] modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:(void *)CFBridgingRetain(file)];
}

- (IBAction)clickRefresh:(id)sender {

    [_connectedClients removeAllObjects];

    [_connectedServers removeAllObjects];

    [self.devicesTableView reloadData];

    [_server setDelegate:nil];
    [_server stop];
    _server = nil;

    [_client setDelegate:nil];
    [_client stop];
    _client = nil;

    double delayInSeconds = 2.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self startServices];
    });

}

- (IBAction)clickSendFile:(id)sender {

    _clickedRow = [self.devicesTableView clickedRow];
    QTRUser *theUser = [self userAtRow:_clickedRow isServer:NULL];

    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    if ([theUser.platform isEqualToString:QTRUserPlatformIOS] || [theUser.platform isEqualToString:QTRUserPlatformLinux]) {
        [openPanel setAllowedFileTypes:@[@"png", @"jpg", @"tiff", @"gif", @"jpeg"]];
    }
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setAllowsOtherFileTypes:NO];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setCanChooseDirectories:NO];

    [openPanel setDelegate:self];
    [openPanel runModal];
}

- (IBAction)clickStopServices:(id)sender {

}

- (IBAction)clickConnectedDevices:(id)sender {
    
    [self.mainWindow makeKeyAndOrderFront:self];
}


#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
    return [_connectedServers count] + [_connectedClients count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
    QTRUser *theUser = [self userAtRow:rowIndex isServer:NULL];

    return theUser.name;
}

#pragma mark - QTRBonjourServerDelegate methods

- (void)server:(QTRBonjourServer *)server didConnectToUser:(QTRUser *)user {
    if (![self userConnected:user]) {
        [_connectedClients addObject:user];
        [self.devicesTableView reloadData];
    }
}

- (void)server:(QTRBonjourServer *)server didDisconnectUser:(QTRUser *)user {
    [_connectedClients removeObject:user];
    [self.devicesTableView reloadData];
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
        [self.devicesTableView reloadData];
    }
}

- (void)client:(QTRBonjourClient *)client didDisconnectFromServerForUser:(QTRUser *)user {
    [_connectedServers removeObject:user];

    [self.devicesTableView reloadData];
}

- (void)client:(QTRBonjourClient *)client didReceiveFile:(QTRFile *)file fromUser:(QTRUser *)user {
    [self showAlertForFile:file user:user];
}

#pragma mark - NSOpenSavePanelDelegate methods

- (BOOL)panel:(id)sender validateURL:(NSURL *)url error:(NSError **)outError {
    BOOL valid = NO;
    NSData *fileData = [NSData dataWithContentsOfURL:url];
    if ([fileData length] > 0) {
        valid = YES;

        if (_clickedRow >= 0) {

            NSFileManager *fileManager = [NSFileManager defaultManager];
            NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:[url path] error:nil];
            NSString *fileName = [[url path] lastPathComponent];
            NSString *fileType = fileAttributes[NSFileType];

            QTRFile *theFile = [[QTRFile alloc] initWithName:fileName type:fileType data:fileData];

            if ([_connectedServers count] > _clickedRow) {

                QTRUser *theUser = _connectedServers[_clickedRow];

                [_client sendFile:theFile toUser:theUser];

            } else {

                QTRUser *theUser = _connectedClients[_clickedRow - [_connectedServers count]];
                [_server sendFile:theFile toUser:theUser];
            }
        }
    }
    return valid;
}

@end
