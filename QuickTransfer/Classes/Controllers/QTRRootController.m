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
#import "QTRStatusItemView.h"
#import "QTRTransfersController.h"

#include <stdlib.h>
#include <stdio.h>
#include <sys/types.h>
#include <sys/sysctl.h>

static char *computerModel = NULL;
int const QTRRootControllerSendMenuItemBaseTag = 1000;

@interface QTRRootController () <NSTableViewDataSource, NSTableViewDelegate, QTRBonjourClientDelegate, QTRBonjourServerDelegate, QTRStatusItemViewDelegate> {
    NSStatusItem *_statusItem;
    QTRBonjourServer *_server;
    QTRBonjourClient *_client;
    NSMutableArray *_connectedServers;
    NSMutableArray *_connectedClients;
    QTRUser *_localUser;
    QTRUser *_selectedUser;
    NSString *_downloadsDirectory;
    long _clickedRow;
    BOOL _canRefresh;
}

@property (weak) IBOutlet NSTableView *devicesTableView;
@property (weak) IBOutlet NSMenuItem *localComputerNameItem;
@property (weak) IBOutlet NSMenuItem *sendFileSubMenuItem;
@property (weak) IBOutlet NSMenu *statusBarMenu;
@property (strong) IBOutlet NSWindow *mainWindow;
@property (weak) IBOutlet NSMenu *sendFileMenu;
@property (weak) IBOutlet QTRStatusItemView *statusItemView;
@property (strong) IBOutlet QTRTransfersController *transfersController;
@property (strong) IBOutlet NSWindow *transfersPanel;

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
- (void)refreshMenu;
- (void)clickSendMenuItem:(NSMenuItem *)menuItem;
- (IBAction)clickQuit:(id)sender;
- (void)showMenu:(id)sender;
- (IBAction)clickTransfers:(id)sender;

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

- (void)awakeFromNib {
    [super awakeFromNib];

    _statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
    [_statusItem setHighlightMode:YES];

    [_statusItem setMenu:self.statusBarMenu];
    [_statusItem setView:self.statusItemView];
    [self.statusItemView.button setTarget:self];
    [self.statusItemView.button setAction:@selector(showMenu:)];
    [self.statusItemView setDelegate:self];

    _canRefresh = YES;

    [self startServices];

    [self refreshMenu];

    [self.devicesTableView registerForDraggedTypes:@[(NSString *)kUTTypeFileURL]];

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
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];

    NSAlert *alert = [NSAlert alertWithMessageText:[NSString stringWithFormat:@"%@ sent file: %@", user.name, file.name] defaultButton:@"Save" alternateButton:@"Discard" otherButton:nil informativeTextWithFormat:@"Clicking save will save it to Downloads"];
    [[alert window] setTitle:@"QuickTransfer"];
    [alert beginSheetModalForWindow:[[NSApplication sharedApplication] keyWindow] modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:(void *)CFBridgingRetain(file)];
}

- (void)sendFileAtURL:(NSURL *)url {
    if ([_connectedServers count] > _clickedRow) {

        QTRUser *theUser = _connectedServers[_clickedRow];
        [_client sendFileAtURL:url toUser:theUser];

    } else {

//        QTRUser *theUser = _connectedClients[_clickedRow - [_connectedServers count]];

    }

    /*
    __weak typeof(self) wSelf = self;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        if (wSelf != nil) {
            typeof(self) sSelf = self;
            NSData *fileData = [NSData dataWithContentsOfURL:url];
            if ([fileData length] > 0) {

                if (sSelf->_clickedRow >= 0) {

                    NSFileManager *fileManager = [NSFileManager defaultManager];
                    NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:[url path] error:nil];
                    NSString *fileName = [[url path] lastPathComponent];
                    NSString *fileType = fileAttributes[NSFileType];

                    QTRFile *theFile = [[QTRFile alloc] initWithName:fileName type:fileType data:fileData];
                    [theFile setUrl:url];

                    dispatch_async(dispatch_get_main_queue(), ^{
                        if ([sSelf->_connectedServers count] > sSelf->_clickedRow) {

                            QTRUser *theUser = sSelf->_connectedServers[sSelf->_clickedRow];

                            [sSelf->_client sendFile:theFile toUser:theUser];

                        } else {

                            QTRUser *theUser = sSelf->_connectedClients[sSelf->_clickedRow - [sSelf->_connectedServers count]];
                            [sSelf->_server sendFile:theFile toUser:theUser];
                        }

                        [sSelf showTransfers];
                    });

                }
            }
        }
    });
    */

}

- (void)showOpenPanelForSelectedUser {
    QTRUser *theUser = [self userAtRow:_clickedRow isServer:NULL];

    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    if ([theUser.platform isEqualToString:QTRUserPlatformIOS] || [theUser.platform isEqualToString:QTRUserPlatformLinux]) {
        [openPanel setAllowedFileTypes:@[(NSString *)kUTTypeImage]];
    }
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setAllowsOtherFileTypes:NO];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setCanChooseDirectories:NO];

    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
    if ([[NSApplication sharedApplication] keyWindow] == nil) {
        [openPanel beginWithCompletionHandler:^(NSInteger result) {
            if (result == NSFileHandlingPanelOKButton && openPanel.URL != nil) {
                NSURL *url = openPanel.URL;
                [self sendFileAtURL:url];
            }
        }];
    } else {
        [openPanel beginSheetModalForWindow:self.mainWindow completionHandler:^(NSInteger result) {

            if (result == NSFileHandlingPanelOKButton && openPanel.URL != nil) {
                NSURL *url = openPanel.URL;
                [self sendFileAtURL:url];
            }

        }];
    }
}

- (NSURL *)validateDraggedFileURLOnRow:(NSInteger)row info:(id <NSDraggingInfo>)info {

    NSURL *validatedURL = nil;
    QTRUser *user = [self userAtRow:row isServer:NULL];

    NSPasteboard *thePasteboard = [info draggingPasteboard];
    NSArray *supportedURLs = nil;
    if ([user.platform isEqualToString:QTRUserPlatformIOS] || [user.platform isEqualToString:QTRUserPlatformAndroid]) {
        supportedURLs = @[(NSString *)kUTTypeImage];
    } else {
        supportedURLs = @[(NSString *)kUTTypeItem];
    }

    NSArray *draggedURLs = [thePasteboard readObjectsForClasses:@[[NSURL class]] options:@{NSPasteboardURLReadingFileURLsOnlyKey : @(YES), NSPasteboardURLReadingContentsConformToTypesKey : supportedURLs}];

    if ([draggedURLs count] == 1) {
        BOOL isDirectory = NO;
        if ([[NSFileManager defaultManager] fileExistsAtPath:[(NSURL *)[draggedURLs firstObject] path] isDirectory:&isDirectory]) {
            if (!isDirectory) {
                validatedURL = [draggedURLs firstObject];
            }
        }
    }

    return validatedURL;
}

- (void)stopServices {

    [_connectedClients removeAllObjects];
    
    [_connectedServers removeAllObjects];

    [self.transfersController removeAllTransfers];
    
    [self.devicesTableView reloadData];

    [self refreshMenu];
    
    [_server setDelegate:nil];
    [_server setTransferDelegate:nil];
    [_server stop];
    _server = nil;
    
    [_client setDelegate:nil];
    [_client setTransferDelegate:nil];
    [_client stop];
    _client = nil;
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
    [_server setTransferDelegate:self.transfersController];

    if (![_server start]) {
        NSAlert *alert = [NSAlert alertWithMessageText:@"Could not start server" defaultButton:@"Ok" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Please make sure WiFi/Ethernet is enabled and connected"];
        [alert runModal];
    }

    _client = [[QTRBonjourClient alloc] initWithDelegate:self];
    [_client setTransferDelegate:self.transfersController];
    [_client start];
}

- (void)refreshMenu {

    [self.localComputerNameItem setTitle:_localUser.name];

    [self.sendFileMenu removeAllItems];

    int totalConnectedUsers = (int)([_connectedServers count] + [_connectedClients count]);

    if (totalConnectedUsers == 0) {
        [self.sendFileSubMenuItem setEnabled:NO];

    } else {

        [self.sendFileSubMenuItem setEnabled:YES];

        @autoreleasepool {
            for (int userIndex = 0; userIndex != totalConnectedUsers; ++userIndex) {
                QTRUser *theUser = [self userAtRow:userIndex isServer:NULL];
                if (theUser != nil) {
                    NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:[self styledDisplayNameForUser:theUser] action:@selector(clickSendMenuItem:) keyEquivalent:@""];
                    [menuItem setTarget:self];
                    [menuItem setTag:(QTRRootControllerSendMenuItemBaseTag + userIndex)];
                    [menuItem setEnabled:YES];
                    [self.sendFileMenu addItem:menuItem];
                }
            }
        }
    }
}

- (NSString *)styledDisplayNameForUser:(QTRUser *)user {
    NSString *displayName = nil;

    if ([user.platform isEqualToString:QTRUserPlatformAndroid] || [user.platform isEqualToString:QTRUserPlatformIOS]) {
        displayName = [NSString stringWithFormat:@"📱 %@", user.name];
    } else {
        displayName = [NSString stringWithFormat:@"💻 %@", user.name];
    }

    return displayName;
}

- (void)showDevicesWindow {
    NSRect windowRect = [self.statusItemView.window convertRectToScreen:self.statusItemView.frame];
    NSPoint desiredWindowOrigin = NSMakePoint(windowRect.origin.x - self.mainWindow.frame.size.width / 2, windowRect.origin.y);
    if (desiredWindowOrigin.x + self.mainWindow.frame.size.width > [[NSScreen mainScreen] frame].size.width - 20) {
        desiredWindowOrigin.x = windowRect.origin.x - self.mainWindow.frame.size.width - 20;
    }
    [self.mainWindow setFrameOrigin:desiredWindowOrigin];
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
    [self.mainWindow makeKeyAndOrderFront:self];
}

- (void)showTransfers {
    [self.transfersPanel orderFront:self];

}

#pragma mark - Actions

- (IBAction)clickRefresh:(id)sender {

    if (_canRefresh) {

        _canRefresh = NO;

        [self stopServices];

        double delayInSeconds = 2.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self startServices];
            _canRefresh = YES;
        });
    }

}

- (IBAction)clickSendFile:(id)sender {

    _clickedRow = [self.devicesTableView clickedRow];

    [self showOpenPanelForSelectedUser];
}

- (IBAction)clickStopServices:(id)sender {
    [self stopServices];
}

- (IBAction)clickConnectedDevices:(id)sender {
    [self showDevicesWindow];
}

- (void)clickSendMenuItem:(NSMenuItem *)menuItem {
    int userIndex = (int)menuItem.tag - QTRRootControllerSendMenuItemBaseTag;
    _clickedRow = userIndex;

    [self showOpenPanelForSelectedUser];
}

- (IBAction)clickQuit:(id)sender {
    [[NSApplication sharedApplication] terminate:self];
}

- (void)showMenu:(id)sender {
    [_statusItem popUpStatusItemMenu:_statusItem.menu];
}

- (void)clickTransfers:(id)sender {
    [self showTransfers];
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
    return [_connectedServers count] + [_connectedClients count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
    QTRUser *theUser = [self userAtRow:rowIndex isServer:NULL];

    return  [self styledDisplayNameForUser:theUser];
}

- (NSDragOperation)tableView:(NSTableView *)aTableView validateDrop:(id < NSDraggingInfo >)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)operation {
    NSDragOperation dragOperation = NSDragOperationNone;

    if (operation == NSTableViewDropOn) {
        if ([self validateDraggedFileURLOnRow:row info:info] != nil) {
            dragOperation = NSDragOperationLink;
        }

    }

    return dragOperation;

}

- (BOOL)tableView:(NSTableView *)tableView acceptDrop:(id<NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)dropOperation {

    BOOL acceptDrop = NO;

    NSURL *fileURL = [self validateDraggedFileURLOnRow:row info:info];

    if (fileURL != nil) {

        acceptDrop = YES;
        _clickedRow = row;
        [self sendFileAtURL:fileURL];

    }

    return acceptDrop;
}

#pragma mark - QTRBonjourServerDelegate methods

- (void)server:(QTRBonjourServer *)server didConnectToUser:(QTRUser *)user {
    if (![self userConnected:user]) {
        [_connectedClients addObject:user];
        [self.devicesTableView reloadData];

        [self refreshMenu];
    }
}

- (void)server:(QTRBonjourServer *)server didDisconnectUser:(QTRUser *)user {
    [_connectedClients removeObject:user];
    [self.devicesTableView reloadData];

    [self refreshMenu];
}

- (void)server:(QTRBonjourServer *)server didReceiveFile:(QTRFile *)file fromUser:(QTRUser *)user {
    [self showAlertForFile:file user:user];
}

- (NSURL *)saveURLForFile:(QTRFile *)file {
    
    NSString *fileName = file.name;
    NSString *savePath = [[self downloadsDirectory] stringByAppendingPathComponent:fileName];
    if ([[NSFileManager defaultManager] fileExistsAtPath:savePath]) {
        fileName = [NSString stringWithFormat:@"%@ %@", [NSDate date], file.name];
        savePath = [[self downloadsDirectory] stringByAppendingPathComponent:fileName];
    }

    return [NSURL fileURLWithPath:savePath];
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

        [self refreshMenu];
    }
}

- (void)client:(QTRBonjourClient *)client didDisconnectFromServerForUser:(QTRUser *)user {
    [_connectedServers removeObject:user];

    [self.devicesTableView reloadData];

    [self refreshMenu];
}

- (void)client:(QTRBonjourClient *)client didReceiveFile:(QTRFile *)file fromUser:(QTRUser *)user {
    [self showAlertForFile:file user:user];
}

#pragma mark - QTRStatusItemViewDelegate methods

- (void)statusItemViewDraggingEntered:(QTRStatusItemView *)view {
    [self showDevicesWindow];
}


@end
