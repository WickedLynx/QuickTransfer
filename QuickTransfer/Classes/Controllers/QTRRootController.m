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
#import "QTRDragView.h"

#include <stdlib.h>
#include <stdio.h>
#include <sys/types.h>
#include <sys/sysctl.h>

static char *computerModel = NULL;
int const QTRRootControllerSendMenuItemBaseTag = 1000;

NSString *const QTRDefaultsAutomaticallyAcceptFilesKey = @"automaticallyAcceptFiles";
NSString *const QTRDefaultsLaunchAtLoginKey = @"launchAtLogin";

@interface QTRRootController () <QTRStatusItemViewDelegate, QTRTransfersControllerDelegate, QTRBonjourManagerDelegate, NSCollectionViewDelegate, QTRDragViewDelegate, NSSearchFieldDelegate> {
    QTRBonjourManager *_bonjourManager;
    NSStatusItem *_statusItem;
    QTRUser *_selectedUser;
    NSString *_downloadsDirectory;
    long _clickedRow;
    BOOL _shouldAutoAccept;
    QTRNotificationsController *_notificationsController;
}

@property (weak) IBOutlet QTRDragView *headerView;
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
@property (strong, nonatomic) NSArray *users;
@property (weak, nonatomic) IBOutlet NSCollectionView *collectionView;
@property (strong) IBOutlet NSLayoutConstraint *sendButtonContainerBottomConstraint;
@property (strong) NSArray *droppedFiles;
@property (weak) IBOutlet NSSearchField *searchField;

- (IBAction)clickSavePreferences:(id)sender;
- (IBAction)clickRefresh:(id)sender;
- (IBAction)clickStopServices:(id)sender;
- (IBAction)clickQuit:(id)sender;
- (IBAction)clickTransfers:(id)sender;
- (IBAction)clickPreferences:(id)sender;

@end

@implementation QTRRootController

@synthesize computerName = _computerName;
@synthesize users = _users;
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

    [self setUsers:[[NSMutableArray alloc] init]];

    [self.mainWindow setBackgroundColor:[NSColor clearColor]];
    [self.mainWindow setMovableByWindowBackground:YES];

    if ([self.mainWindow.contentView isKindOfClass:[NSVisualEffectView class]]) {
        NSVisualEffectView *visualEffectView = self.mainWindow.contentView;
        [visualEffectView setState:NSVisualEffectStateActive];
        [visualEffectView setMaterial:NSVisualEffectMaterialDark];
    }

    _notificationsController = [[QTRNotificationsController alloc] init];

    _statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
    [_statusItem setHighlightMode:YES];

    [_statusItem setMenu:self.statusBarMenu];
    [_statusItem setView:self.statusItemView];
    [self.statusItemView.button setTarget:self];
    [self.statusItemView.button setAction:@selector(showDevicesWindow)];
    [self.statusItemView.button setTarget:self forRightClickAction:@selector(showMenu:)];
    [self.statusItemView setDelegate:self];

    NSURL *appSupportDirectoryURL = [QTRHelper applicationSupportDirectoryURL];
    NSString *archiveFilePath = [[appSupportDirectoryURL path] stringByAppendingPathComponent:@"Transfers"];

    QTRTransfersStore *transfersStore = [[QTRTransfersStore alloc] initWithArchiveLocation:archiveFilePath];
    [_transfersController setTransfersStore:transfersStore];
    [_transfersController setDelegate:self];

    _bonjourManager = [[QTRBonjourManager alloc] init];
    [_bonjourManager setDelegate:self];
    [_bonjourManager setTransfersDelegate:_transfersController.transfersStore];
    BOOL autoAccept = [[NSUserDefaults standardUserDefaults] boolForKey:QTRDefaultsAutomaticallyAcceptFilesKey];
    [_bonjourManager setShouldAutoAcceptFiles:autoAccept];
    NSError *serverError = [_bonjourManager startServices];
    if (serverError != nil) {
        NSAlert *alert = [NSAlert alertWithMessageText:@"Could not start server" defaultButton:@"Ok" alternateButton:nil otherButton:nil informativeTextWithFormat:@"%@",[serverError localizedDescription] ?: @"Unknown Error occured"];
        [alert runModal];
    }

    [self refreshMenu];

    [self.collectionView registerForDraggedTypes:@[(NSString *)kUTTypeFileURL]];

    [self.headerView setDelegate:self];

    [self.collectionView addObserver:self forKeyPath:@"selectionIndexes" options:(NSKeyValueObservingOptionNew) context:NULL];
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
        [_bonjourManager setShouldAutoAcceptFiles:shouldAutoAccept];
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

    [openPanel setAllowsMultipleSelection:YES];
    [openPanel setAllowsOtherFileTypes:NO];
    [openPanel setCanChooseDirectories:YES];

    __weak typeof(self) wself = self;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    void (^openPanelCompletionHandler)(NSInteger) = ^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton && openPanel.URLs != nil) {
            for (NSURL *url in openPanel.URLs) {
                BOOL directory = NO;
                if ([fileManager fileExistsAtPath:url.path isDirectory:&directory]) {
                    if (directory) {
                        [wself sendDirectoryAtURL:url];
                    } else {
                        [wself sendFileAtURL:url];
                    }
                }

            }
        }
    };

    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
    if ([[NSApplication sharedApplication] keyWindow] == nil) {
        [openPanel beginWithCompletionHandler:openPanelCompletionHandler];
    } else {
        [openPanel beginSheetModalForWindow:self.mainWindow completionHandler:openPanelCompletionHandler];
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

    NSInteger totalConnectedUsers = [self.users count];

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

    [_bonjourManager refresh:nil];

}

- (IBAction)clickSavePreferences:(id)sender {
    NSAlert *alert = [NSAlert alertWithMessageText:@"Save Preferences?" defaultButton:@"Save" alternateButton:@"Cancel" otherButton:nil informativeTextWithFormat:@"Clicking save will save your settings and restart services.\nAll active transfers will be cancelled."];
    [alert beginSheetModalForWindow:self.preferencesWindow modalDelegate:self didEndSelector:@selector(preferencesAlertDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}

- (IBAction)clickStopServices:(id)sender {
    [_bonjourManager stopServices];
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

- (IBAction)clickSend:(id)sender {
    if (self.droppedFiles.count > 0) {
        if (self.collectionView.selectionIndexes.count > 0) {
            NSArray *users = [self.users objectsAtIndexes:self.collectionView.selectionIndexes];
            for (QTRDraggedItem *item in self.droppedFiles) {
                if (![item isDirectory]) {
                    for (QTRUser *user in users) {
                        [_bonjourManager sendFileAtURL:item.fileURL toUser:user];
                    }
                } else {
                    __weak typeof(self) wself = self;
                    void (^zipCompletion)(NSURL *, NSError *) = ^(NSURL *zipURL, NSError *zipError) {
                        if (wself != nil) {
                            typeof(self) sself = wself;
                            if (zipError == nil) {
                                for (QTRUser *user in users) {
                                    [sself->_bonjourManager sendFileAtURL:zipURL toUser:user];
                                }
                            }
                        }
                    };
                    
                    [QTRFileZipper zipDirectoryAtURL:item.fileURL completion:zipCompletion];
                }
            }
        }
    }
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    if ([object isEqual:self.collectionView]) {
        NSIndexSet *indexset = change[@"new"];
        BOOL showSendButton = NO;
        if (indexset.count > 0) {
            if (self.droppedFiles.count > 0) {
                showSendButton = YES;
            }
        }
        if (showSendButton) {
            self.sendButtonContainerBottomConstraint.constant = 0;
        } else {
            self.sendButtonContainerBottomConstraint.constant = -40;
        }
    }
}

#pragma mark - Notification Observers

- (void)controlTextDidChange:(NSNotification *)obj {
    if (obj.object == self.searchField) {
        if (self.searchField.stringValue.length == 0) {
            [self setUsers:[_bonjourManager remoteUsers]];
        } else {
            NSArray *filteredUsers = [[_bonjourManager remoteUsers] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id  _Nonnull evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
                QTRUser *user = (QTRUser *)evaluatedObject;
                return [user.name.lowercaseString containsString:self.searchField.stringValue.lowercaseString];
            }]];
            [self setUsers:filteredUsers];
        }
    }
}

#pragma mark - NSCollectionViewDelegate methods

- (NSDragOperation)collectionView:(NSCollectionView *)collectionView validateDrop:(id<NSDraggingInfo>)draggingInfo proposedIndex:(NSInteger *)proposedDropIndex dropOperation:(NSCollectionViewDropOperation *)proposedDropOperation {

    NSDragOperation dragOperation = NSDragOperationNone;
    if (*proposedDropOperation == NSCollectionViewDropOn) {
        if ([self validateDraggedFileURLOnRow:*proposedDropIndex info:draggingInfo] != nil) {
            dragOperation = NSDragOperationLink;
        }
    }

    return dragOperation;
}

- (BOOL)collectionView:(NSCollectionView *)collectionView acceptDrop:(id<NSDraggingInfo>)draggingInfo index:(NSInteger)index dropOperation:(NSCollectionViewDropOperation)dropOperation {
    BOOL acceptDrop = NO;
    NSArray *files = [self validateDraggedFileURLOnRow:index info:draggingInfo];
    if (files.count > 0) {

        acceptDrop = YES;
        _clickedRow = index;
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
    [self.searchField setStringValue:@""];
    [self setUsers:nil];
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
    [self.searchField setStringValue:@""];
    [self setUsers:[_bonjourManager remoteUsers]];
    [self refreshMenu];
}

- (void)bonjourManager:(QTRBonjourManager *)manager didDisconnectFromUser:(QTRUser *)remoteUser {
    [self.searchField setStringValue:@""];
    [self setUsers:[_bonjourManager remoteUsers]];
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

- (BOOL)transfersController:(QTRTransfersController *)controller needsPauseTransfer:(QTRTransfer *)transfer {
    return [_bonjourManager pauseTransfer:transfer];
}

#pragma mark - QTRStatusItemViewDelegate methods

- (void)statusItemViewDraggingEntered:(QTRStatusItemView *)view {
    [self showDevicesWindow];
}

#pragma mark - QTRDragViewDelegate methods

- (NSString *)dragView:(QTRDragView *)dragView didPerformDragOperation:(id<NSDraggingInfo>)draggingInfo {
    NSString *statusText = nil;
    NSArray *draggedFiles = [self validateDraggedFileURLOnRow:0 info:draggingInfo];
    BOOL showSendButton = NO;
    if (draggedFiles.count > 0) {
        [self setDroppedFiles:draggedFiles];
        QTRDraggedItem *file = [draggedFiles firstObject];
        NSString *fileName = [file.fileURL lastPathComponent];
        if (draggedFiles.count == 2) {
            statusText = [NSString stringWithFormat:@"%@ and %ld more file", fileName, (draggedFiles.count - 1)];
        } else if (draggedFiles.count > 2) {
            statusText = [NSString stringWithFormat:@"%@ and %ld more files", fileName, (draggedFiles.count - 1)];
        } else {
            statusText = fileName;
        }
        if (self.collectionView.selectionIndexes.count > 0) {
            showSendButton = YES;
        }
    }

    if (showSendButton) {
        self.sendButtonContainerBottomConstraint.constant = 0;
    } else {
        self.sendButtonContainerBottomConstraint.constant = -40;
    }

    return statusText;
}

#pragma mark - NSSearchFieldDelegate methods

- (void)searchFieldDidEndSearching:(NSSearchField *)sender {
    [self setUsers:[_bonjourManager remoteUsers]];
}

@end
