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
#import "QTRBeaconHelper.h"
#import "QTRTransfersStore.h"
#import "QTRHelper.h"
#import "QTRConversationsController.h"

#include <stdlib.h>
#include <stdio.h>
#include <sys/types.h>
#include <sys/sysctl.h>

static char *computerModel = NULL;
int const QTRRootControllerSendMenuItemBaseTag = 1000;

NSString *const QTRDefaultsAutomaticallyAcceptFilesKey = @"automaticallyAcceptFiles";
NSString *const QTRDefaultsLaunchAtLoginKey = @"launchAtLogin";

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
    BOOL _shouldAutoAccept;
    QTRBeaconAdvertiser *_beaconAdvertiser;
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
@property (strong) IBOutlet NSWindow *preferencesWindow;
@property (weak) IBOutlet NSTextField *computerNameTextField;
@property (weak) IBOutlet NSButton *automaticallyAcceptCheckBox;
@property (weak) IBOutlet NSButton *launchAtLoginCheckBox;
@property (strong, nonatomic) QTRConversationsController *conversationsController;

- (IBAction)clickSavePreferences:(id)sender;
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
- (void)systemWillSleep:(NSNotification *)notification;
- (void)systemDidWakeUpFromSleep:(NSNotification *)notification;
- (IBAction)clickPreferences:(id)sender;

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

    _connectedServers = [NSMutableArray new];
    _connectedClients = [NSMutableArray new];

    _canRefresh = YES;

    NSURL *appSupportDirectoryURL = [QTRHelper applicationSupportDirectoryURL];
    NSString *archiveFilePath = [[appSupportDirectoryURL path] stringByAppendingPathComponent:@"Transfers"];

    QTRTransfersStore *transfersStore = [[QTRTransfersStore alloc] initWithArchiveLocation:archiveFilePath];
    [_transfersController setTransfersStore:transfersStore];

    [self startServices];

    [self refreshMenu];

    [self.devicesTableView registerForDraggedTypes:@[(NSString *)kUTTypeFileURL]];

    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(systemWillSleep:) name:NSWorkspaceWillSleepNotification object:nil];
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(systemDidWakeUpFromSleep:) name:NSWorkspaceDidWakeNotification object:nil];

    if ([QTRBeaconHelper isBLEAvailable]) {
        _beaconAdvertiser = [[QTRBeaconAdvertiser alloc] init];
    }

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

- (void)deleteSavedFileAtURL:(NSURL *)url {
    [[NSFileManager defaultManager] removeItemAtURL:url error:nil];
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

- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    if (contextInfo != NULL) {

        NSDictionary *fileInfo = CFBridgingRelease(contextInfo);

        QTRFile *file = fileInfo[@"file"];
        id receiver = fileInfo[@"receiver"];

        BOOL shouldAccept = NO;

        if (returnCode == NSAlertDefaultReturn) {
            shouldAccept = YES;
        }


        if ([receiver isEqual:_client]) {
            [_client acceptFile:file accept:shouldAccept fromUser:fileInfo[@"user"]];
        } else if ([receiver isEqual:_server]) {
            [_server acceptFile:file accept:shouldAccept fromUser:fileInfo[@"user"]];
        }

    }

}

- (void)preferencesAlertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    if (returnCode == NSAlertDefaultReturn) {
        if ([[self.computerNameTextField stringValue] length] > 0) {
            [[NSUserDefaults standardUserDefaults] setObject:[self.computerNameTextField stringValue] forKey:QTRBonjourTXTRecordNameKey];
        }

        BOOL shouldAutoAccept = (self.automaticallyAcceptCheckBox.state == NSOnState);
        [[NSUserDefaults standardUserDefaults] setBool:shouldAutoAccept forKey:QTRDefaultsAutomaticallyAcceptFilesKey];

        [[NSUserDefaults standardUserDefaults] synchronize];

        [self clickRefresh:nil];
    }

    [self.preferencesWindow close];
}

- (void)showAlertForFile:(QTRFile *)file user:(QTRUser *)user {
    [file.data writeToURL:[self saveURLForFile:file] atomically:YES];
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];

    NSAlert *alert = [NSAlert alertWithMessageText:[NSString stringWithFormat:@"%@ sent file: %@", user.name, file.name] defaultButton:@"Ok" alternateButton:nil otherButton:nil informativeTextWithFormat:@"The file was saved to your Downloads directory"];
    [[alert window] setTitle:@"QuickTransfer"];
    [alert beginSheetModalForWindow:[[NSApplication sharedApplication] keyWindow] modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}

- (void)showAlertForSavedFileAtURL:(NSURL *)url user:(QTRUser *)user {
    NSString *fileName = [[url path] lastPathComponent];

    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];

    NSAlert *alert = [NSAlert alertWithMessageText:[NSString stringWithFormat:@"%@ sent file: %@", user.name, fileName] defaultButton:@"Ok" alternateButton:nil otherButton:nil informativeTextWithFormat:@"The file was saved to your Downloads directory"];
    [[alert window] setTitle:@"QuickTransfer"];
    [alert beginSheetModalForWindow:[[NSApplication sharedApplication] keyWindow] modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:NULL];

}

- (void)sendFileAtURL:(NSURL *)url {
    if ([_connectedServers count] > _clickedRow) {

        QTRUser *theUser = _connectedServers[_clickedRow];
        [_client sendFileAtURL:url toUser:theUser];

    } else {

        QTRUser *theUser = _connectedClients[_clickedRow - [_connectedServers count]];
        [_server sendFileAtURL:url toUser:theUser];

    }

}

- (void)showOpenPanelForSelectedUser {

    NSOpenPanel *openPanel = [NSOpenPanel openPanel];

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

    NSPasteboard *thePasteboard = [info draggingPasteboard];
    NSArray *supportedURLs = @[(NSString *)kUTTypeItem];

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

    [_beaconAdvertiser stopAdvertisingBeaconRegion];

    [_connectedClients removeAllObjects];
    
    [_connectedServers removeAllObjects];
    
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
    NSString *userName = [[NSUserDefaults standardUserDefaults] stringForKey:QTRBonjourTXTRecordNameKey];
    if (userName == nil || [userName isKindOfClass:[NSNull class]] || userName.length == 0) {
        if (computerModel == NULL) {
            refreshComputerModel();
        }

        NSString *computerName = @"Mac";
        if (computerModel != NULL) {
            computerName = [NSString stringWithCString:computerModel encoding:NSUTF8StringEncoding];
        }
        userName = [NSString stringWithFormat:@"%@'s %@", NSUserName(), computerName];

        [[NSUserDefaults standardUserDefaults] setObject:userName forKey:QTRBonjourTXTRecordNameKey];
    }

    NSString *uuid = [[NSUserDefaults standardUserDefaults] stringForKey:QTRBonjourTXTRecordIdentifierKey];
    if ([uuid isKindOfClass:[NSNull class]] || uuid == nil) {
        uuid = [[NSUUID UUID] UUIDString];
        [[NSUserDefaults standardUserDefaults] setObject:uuid forKey:QTRBonjourTXTRecordIdentifierKey];
    }

    _shouldAutoAccept = [[NSUserDefaults standardUserDefaults] boolForKey:QTRDefaultsAutomaticallyAcceptFilesKey];

    _localUser = [[QTRUser alloc] initWithName:userName identifier:uuid platform:QTRUserPlatformMac];

    [[NSUserDefaults standardUserDefaults] synchronize];

    _server = [[QTRBonjourServer alloc] initWithFileDelegate:self];
    [_server setTransferDelegate:self.transfersController.transfersStore];

    if (![_server start]) {
        NSAlert *alert = [NSAlert alertWithMessageText:@"Could not start server" defaultButton:@"Ok" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Please make sure WiFi/Ethernet is enabled and connected"];
        [alert runModal];
    }

    _client = [[QTRBonjourClient alloc] initWithDelegate:self];
    [_client setTransferDelegate:self.transfersController.transfersStore];
    [_client start];

    [_beaconAdvertiser startAdvertisingRegionWithProximityUUID:QTRBeaconRegionProximityUUID identifier:QTRBeaconRegionIdentifier majorValue:0 minorValue:0];
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
//    [self.transfersPanel makeKeyAndOrderFront:self];
    [self.transfersPanel orderFront:self];
}

- (void)showConfirmationAlertForFile:(QTRFile *)file user:(QTRUser *)user receiver:(id)receiver {
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];

    NSAlert *alert = [NSAlert alertWithMessageText:[NSString stringWithFormat:@"%@ wants to send you a file: %@", user.name, file.name] defaultButton:@"Accept" alternateButton:@"Reject" otherButton:nil informativeTextWithFormat:@"Clicking Accept will save it to your Downloads directory"];
    [[alert window] setTitle:@"QuickTransfer"];
    [alert beginSheetModalForWindow:[[NSApplication sharedApplication] keyWindow] modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:(void *)CFBridgingRetain(@{@"file" : file, @"receiver" : receiver, @"user" : user})];
}

- (void)showAlertForRejectedFile:(QTRFile *)file receiver:(QTRUser *)receiver {
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];

    NSAlert *alert = [NSAlert alertWithMessageText:[NSString stringWithFormat:@"%@ rejected file: %@", receiver.name, file.name] defaultButton:@"Ok" alternateButton:nil otherButton:nil informativeTextWithFormat:@"The file will not be sent"];
    [[alert window] setTitle:@"QuickTransfer"];
    [alert beginSheetModalForWindow:[[NSApplication sharedApplication] keyWindow] modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}

- (void)showTextMessage:(NSString *)textMessage fromUser:(QTRUser *)user {
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];

    NSAlert *alert = [NSAlert alertWithMessageText:[NSString stringWithFormat:@"%@ says", user.name] defaultButton:@"Accept" alternateButton:@"Reject" otherButton:nil informativeTextWithFormat:@"%@", textMessage];
    [[alert window] setTitle:@"QuickTransfer"];
    [alert beginSheetModalForWindow:[[NSApplication sharedApplication] keyWindow] modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}

- (QTRConversationsController *)conversationsController {
    if (_conversationsController == nil) {
        _conversationsController = [[QTRConversationsController alloc] initWithWindowNibName:@"QTRConversationsController"];
    }
    return _conversationsController;
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

- (IBAction)clickSavePreferences:(id)sender {
    NSAlert *alert = [NSAlert alertWithMessageText:@"Save Preferences?" defaultButton:@"Save" alternateButton:@"Cancel" otherButton:nil informativeTextWithFormat:@"Clicking save will save your settings and restart services.\nAll active transfers will be cancelled."];
    [alert beginSheetModalForWindow:self.preferencesWindow modalDelegate:self didEndSelector:@selector(preferencesAlertDidEnd:returnCode:contextInfo:) contextInfo:NULL];
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

    [_beaconAdvertiser stopAdvertisingBeaconRegion];
    [_statusItem popUpStatusItemMenu:_statusItem.menu];

    __weak typeof(self) wSelf = self;
    double delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        if (wSelf != nil) {
            typeof(self) sSelf = wSelf;
            [sSelf->_beaconAdvertiser startAdvertisingRegionWithProximityUUID:QTRBeaconRegionProximityUUID identifier:QTRBeaconRegionIdentifier majorValue:0 minorValue:0];
        }

    });
}

- (void)clickTransfers:(id)sender {
    [self showTransfers];
}

- (IBAction)clickPreferences:(id)sender {
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
    [self.conversationsController showWindow:nil];
    return;
    [[self.computerNameTextField cell] setPlaceholderString:_localUser.name];
    if (_shouldAutoAccept) {
        [self.automaticallyAcceptCheckBox setState:NSOnState];
    } else {
        [self.automaticallyAcceptCheckBox setState:NSOffState];
    }
    [self.preferencesWindow makeKeyAndOrderFront:self];
}

- (IBAction)clickSendMessage:(id)sender {
    [self.conversationsController showWindow:nil];
//    
//    long clickedRow = [self.devicesTableView clickedRow];
//    if ([_connectedServers count] > clickedRow) {
//        QTRUser *theUser = _connectedServers[clickedRow];
//        [_client sendText:@"Test" toUser:theUser];
//    } else {
//        QTRUser *theUser = _connectedClients[clickedRow - [_connectedServers count]];
//        [_server sendText:@"Test" toUser:theUser];
//    }
}

#pragma mark - Notification handlers

- (void)systemWillSleep:(NSNotification *)notification {
    [self stopServices];
}

- (void)systemDidWakeUpFromSleep:(NSNotification *)notification {
    [self clickRefresh:nil];
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
    return [_connectedServers count] + [_connectedClients count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
    BOOL _isServer = NO;
    QTRUser *theUser = [self userAtRow:rowIndex isServer:&_isServer];
    NSString *name = [self styledDisplayNameForUser:theUser];
/*
 // For debugging connections
 
    if (_isServer) {
        name = [name stringByAppendingFormat:@" (server)"];
    } else {
        name = [name stringByAppendingFormat:@" (client)"];
    }
*/

    return  name;
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

- (void)server:(QTRBonjourServer *)server didSaveReceivedFileAtURL:(NSURL *)url fromUser:(QTRUser *)user {
    [self showAlertForSavedFileAtURL:url user:user];
}

- (void)server:(QTRBonjourServer *)server didDetectIncomingFile:(QTRFile *)file fromUser:(QTRUser *)user {
    if (_shouldAutoAccept) {
        [server acceptFile:file accept:YES fromUser:user];
    } else {
        [self showConfirmationAlertForFile:file user:user receiver:server];
    }

}

- (void)user:(QTRUser *)user didRejectFile:(QTRFile *)file {
    [self showAlertForRejectedFile:file receiver:user];
}

- (void)server:(QTRBonjourServer *)server didBeginSendingFile:(QTRFile *)file toUser:(QTRUser *)user {
    [self showTransfers];
}

- (void)server:(QTRBonjourServer *)server didReiveTextMessage:(NSString *)messageText fromUser:(QTRUser *)user {
    [self showTextMessage:messageText fromUser:user];
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

- (void)client:(QTRBonjourClient *)client didSaveReceivedFileAtURL:(NSURL *)url fromUser:(QTRUser *)user {
    [self showAlertForSavedFileAtURL:url user:user];
}

- (void)client:(QTRBonjourClient *)client didDetectIncomingFile:(QTRFile *)file fromUser:(QTRUser *)user {
    if (_shouldAutoAccept) {
        [client acceptFile:file accept:YES fromUser:user];
    } else {
        [self showConfirmationAlertForFile:file user:user receiver:client];
    }

}

- (void)client:(QTRBonjourClient *)client didBeginSendingFile:(QTRFile *)file toUser:(QTRUser *)user {
    [self showTransfers];
}

- (void)client:(QTRBonjourClient *)client didReiveTextMessage:(NSString *)messageText fromUser:(QTRUser *)user {
    [self showTextMessage:messageText fromUser:user];
}

#pragma mark - QTRStatusItemViewDelegate methods

- (void)statusItemViewDraggingEntered:(QTRStatusItemView *)view {
    [self showDevicesWindow];
}


@end
