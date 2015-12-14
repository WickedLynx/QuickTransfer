//
//  QTRRootController.m
//  QuickTransfer
//
//  Created by Harshad on 18/02/14.
//  Copyright (c) 2014 Laughing Buddha Software. All rights reserved.
//

#import "QTRRootController.h"
#import "QTRUser.h"
#import "QTRConstants.h"
#import "QTRFile.h"
#import "QTRStatusItemView.h"
#import "QTRTransfersController.h"
#import "QTRTransfersStore.h"
#import "QTRHelper.h"
#import "QTRFileZipper.h"
#import "QTRDraggedItem.h"
#import "QTRNotificationsController.h"
#import "QTRBonjourManager.h"

#include <stdlib.h>
#include <stdio.h>
#include <sys/types.h>
#include <sys/sysctl.h>

static char *computerModel = NULL;
int const QTRRootControllerSendMenuItemBaseTag = 1000;

NSString *const QTRDefaultsAutomaticallyAcceptFilesKey = @"automaticallyAcceptFiles";
NSString *const QTRDefaultsLaunchAtLoginKey = @"launchAtLogin";

@interface QTRRootController () <NSTableViewDataSource, NSTableViewDelegate, QTRStatusItemViewDelegate, QTRTransfersControllerDelegate, QTRBonjourManagerDelegate> {
    QTRBonjourManager *_bonjourManager;
    NSStatusItem *_statusItem;
    QTRUser *_selectedUser;
    NSString *_downloadsDirectory;
    long _clickedRow;
    BOOL _shouldAutoAccept;
    QTRNotificationsController *_notificationsController;
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

- (IBAction)clickSavePreferences:(id)sender;
- (IBAction)clickSendFile:(id)sender;
- (IBAction)clickRefresh:(id)sender;
- (IBAction)clickStopServices:(id)sender;
- (IBAction)clickConnectedDevices:(id)sender;
- (IBAction)clickQuit:(id)sender;
- (IBAction)clickTransfers:(id)sender;
- (IBAction)clickPreferences:(id)sender;

@end

@implementation QTRRootController

@synthesize computerName = _computerName;

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

    _notificationsController = [[QTRNotificationsController alloc] init];

    _statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
    [_statusItem setHighlightMode:YES];

    [_statusItem setMenu:self.statusBarMenu];
    [_statusItem setView:self.statusItemView];
    [self.statusItemView.button setTarget:self];
    [self.statusItemView.button setAction:@selector(showMenu:)];
    [self.statusItemView setDelegate:self];

    NSURL *appSupportDirectoryURL = [QTRHelper applicationSupportDirectoryURL];
    NSString *archiveFilePath = [[appSupportDirectoryURL path] stringByAppendingPathComponent:@"Transfers"];

    QTRTransfersStore *transfersStore = [[QTRTransfersStore alloc] initWithArchiveLocation:archiveFilePath];
    [_transfersController setTransfersStore:transfersStore];
    [_transfersController setDelegate:self];

    _bonjourManager = [[QTRBonjourManager alloc] init];
    [_bonjourManager setDelegate:self];
    [_bonjourManager setTransfersDelegate:_transfersController.transfersStore];
    [_bonjourManager startServices];

    [self refreshMenu];

    [self.devicesTableView registerForDraggedTypes:@[(NSString *)kUTTypeFileURL]];

    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(systemWillSleep:) name:NSWorkspaceWillSleepNotification object:nil];
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(systemDidWakeUpFromSleep:) name:NSWorkspaceDidWakeNotification object:nil];
}

#pragma mark - Private methods

- (NSString *)downloadsDirectory {
    if (_downloadsDirectory == nil) {
        _downloadsDirectory = [NSSearchPathForDirectoriesInDomains(NSDownloadsDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    }

    return _downloadsDirectory;
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

        [_bonjourManager accept:shouldAccept file:file fromUser:fileInfo[@"user"] context:receiver];
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

        [_bonjourManager refresh:nil];
    }

    [self.preferencesWindow close];
}

- (void)showAlertForFile:(QTRFile *)file user:(QTRUser *)user {
    [file.data writeToURL:[self bonjourManager:nil saveURLForFile:file] atomically:YES];

    NSString *fileName = file.name;
    [_notificationsController showFileSavedNotificationForFileNamed:fileName fromUser:user];
}

- (void)showAlertForSavedFileAtURL:(NSURL *)url user:(QTRUser *)user {
    NSString *fileName = [[url path] lastPathComponent];
    [_notificationsController showFileSavedNotificationForFileNamed:fileName fromUser:user];
}

- (void)sendFileAtURL:(NSURL *)url {
    [_bonjourManager sendFileAtURL:url toUser:[_bonjourManager userAtIndex:_clickedRow]];
}

- (void)sendDirectoryAtURL:(NSURL *)url {
    QTRUser *user = [_bonjourManager userAtIndex:_clickedRow];

    if (user != nil) {
        __weak typeof(self) wself = self;
        void (^zipCompletion)(NSURL *, NSError *) = ^(NSURL *zipURL, NSError *zipError) {
            if (wself != nil) {
                typeof(self) sself = wself;
                if (zipError == nil) {
                    if (user != nil) {
                        [sself->_bonjourManager sendFileAtURL:zipURL toUser:user];
                    }
                }
            }
        };

        [QTRFileZipper zipDirectoryAtURL:url completion:zipCompletion];

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

- (NSArray *)validateDraggedFileURLOnRow:(NSInteger)row info:(id <NSDraggingInfo>)info {

    NSPasteboard *thePasteboard = [info draggingPasteboard];
    NSArray *supportedURLs = @[(NSString *)kUTTypeItem];

    NSArray *draggedURLs = [thePasteboard readObjectsForClasses:@[[NSURL class]] options:@{NSPasteboardURLReadingFileURLsOnlyKey : @(YES), NSPasteboardURLReadingContentsConformToTypesKey : supportedURLs}];

    NSMutableArray *validatedURLs = nil;
    if ([draggedURLs count] >= 1) {
        validatedURLs = [[NSMutableArray alloc] initWithCapacity:[draggedURLs count]];
        BOOL isDirectory = NO;
        for (NSURL *url in draggedURLs) {
            if ([[NSFileManager defaultManager] fileExistsAtPath:[url path] isDirectory:&isDirectory]) {
                [validatedURLs addObject:[[QTRDraggedItem alloc] initWithFileURL:url isDirectory:isDirectory]];
            }
        }
    }

    return validatedURLs;
}

- (void)refreshMenu {

    [self.localComputerNameItem setTitle:self.computerName];

    [self.sendFileMenu removeAllItems];

    NSInteger totalConnectedUsers = [[_bonjourManager remoteUsers] count];

    if (totalConnectedUsers == 0) {
        [self.sendFileSubMenuItem setEnabled:NO];

    } else {

        [self.sendFileSubMenuItem setEnabled:YES];

        @autoreleasepool {
            for (int userIndex = 0; userIndex != totalConnectedUsers; ++userIndex) {
                QTRUser *theUser = [_bonjourManager userAtIndex:userIndex];
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
    [_notificationsController showRejectionNotificationForFile:file toUser:receiver];
}

#pragma mark - Actions

- (IBAction)clickRefresh:(id)sender {

    // TODO: Refresh

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
    [_bonjourManager stopServices];
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

- (IBAction)clickPreferences:(id)sender {
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
    [[self.computerNameTextField cell] setPlaceholderString:self.computerName];
    if (_shouldAutoAccept) {
        [self.automaticallyAcceptCheckBox setState:NSOnState];
    } else {
        [self.automaticallyAcceptCheckBox setState:NSOffState];
    }
    [self.preferencesWindow makeKeyAndOrderFront:self];
}

#pragma mark - Notification handlers

- (void)systemWillSleep:(NSNotification *)notification {
    [_bonjourManager stopServices];
}

- (void)systemDidWakeUpFromSleep:(NSNotification *)notification {
    [self clickRefresh:nil];
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
    return [[_bonjourManager remoteUsers] count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
    QTRUser *theUser = [_bonjourManager userAtIndex:rowIndex];
    NSString *name = [self styledDisplayNameForUser:theUser];

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

    NSArray *files = [self validateDraggedFileURLOnRow:row info:info];

    if (files.count > 0) {

        acceptDrop = YES;
        _clickedRow = row;
        for (QTRDraggedItem *file in files) {
            if ([file isDirectory]) {
                [self sendDirectoryAtURL:file.fileURL];
            } else {
                [self sendFileAtURL:file.fileURL];
            }
        }
    }

    return acceptDrop;
}

#pragma mark - QTRBonjourManagerDelegate methods

- (void)bonjourManagerDidStartServices:(QTRBonjourManager *)manager {

}

- (void)bonjourManagerDidStopServices:(QTRBonjourManager *)manager {
    [self.devicesTableView reloadData];
    [self refreshMenu];
}

- (NSString *)computerName {
    if (_computerName == nil) {
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
        _computerName = userName;
    }
    return _computerName;
}

- (NSURL *)bonjourManager:(QTRBonjourManager *)manager saveURLForFile:(QTRFile *)file {
    NSString *fileName = file.name;
    NSString *savePath = [[self downloadsDirectory] stringByAppendingPathComponent:fileName];
    if ([[NSFileManager defaultManager] fileExistsAtPath:savePath]) {
        fileName = [NSString stringWithFormat:@"%@ %@", [NSDate date], file.name];
        savePath = [[self downloadsDirectory] stringByAppendingPathComponent:fileName];
    }

    return [NSURL fileURLWithPath:savePath];
}

- (void)bonjourManager:(QTRBonjourManager *)manager requiresUserConfirmationForFile:(QTRFile *)file fromUser:(QTRUser *)remoteUser context:(id)context {
    [self showConfirmationAlertForFile:file user:remoteUser receiver:context];
}

- (void)bonjourManager:(QTRBonjourManager *)manager didConnectToUser:(QTRUser *)remoteUser {
    [self.devicesTableView reloadData];
    [self refreshMenu];
}

- (void)bonjourManager:(QTRBonjourManager *)manager didDisconnectFromUser:(QTRUser *)remoteUser {
    [self.devicesTableView reloadData];
    [self refreshMenu];
}

- (void)bonjourManager:(QTRBonjourManager *)manager didReceiveFile:(QTRFile *)file fromUser:(QTRUser *)user {
    [self showAlertForFile:file user:user];
}

- (void)bonjourManager:(QTRBonjourManager *)manager didSaveReceivedFileToURL:(NSURL *)url fromUser:(QTRUser *)user {
    [self showAlertForSavedFileAtURL:url user:user];
}

- (void)bonjourManager:(QTRBonjourManager *)manager remoteUser:(QTRUser *)remoteUser didRejectFile:(QTRFile *)file {
    [self showAlertForRejectedFile:file receiver:remoteUser];
}

- (void)bonjourManager:(QTRBonjourManager *)manager didBeginFileTransfer:(QTRFile *)file toUser:(QTRUser *)remoteUser {
    [self showTransfers];
}

#pragma mark - QTRTransfersControllerDelegate methods

- (BOOL)transfersController:(QTRTransfersController *)controller needsResumeTransfer:(QTRTransfer *)transfer {
    return [_bonjourManager resumeTransfer:transfer];
}

#pragma mark - QTRStatusItemViewDelegate methods

- (void)statusItemViewDraggingEntered:(QTRStatusItemView *)view {
    [self showDevicesWindow];
}


@end
