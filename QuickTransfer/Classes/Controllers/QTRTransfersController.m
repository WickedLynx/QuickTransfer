//
//  QTRTransfersController.m
//  QuickTransfer
//
//  Created by Harshad on 27/02/14.
//  Copyright (c) 2014 Laughing Buddha Software. All rights reserved.
//

#import "QTRTransfersController.h"
#import "QTRTransfer.h"
#import "QTRTransfersStore.h"

@implementation QTRTransfersController

#pragma mark - Initialisation

- (void)awakeFromNib {
    [super awakeFromNib];

    [self.transfersTableView setTarget:self];
    [self.transfersTableView setDoubleAction:@selector(clickTransfer:)];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillTerminate:) name:NSApplicationWillTerminateNotification object:nil];
}

#pragma mark - Actions

- (IBAction)clickClearCompleted:(id)sender {

    [self.transfersStore removeCompletedTransfers];
}

- (void)clickTransfer:(id)sender {
    NSUInteger clickedRow = [self.transfersTableView clickedRow];
    if (clickedRow < [[self.transfersStore transfers] count]) {
        QTRTransfer *theTransfer = [[self.transfersStore transfers] objectAtIndex:clickedRow];
        if (theTransfer.progress == 1.0f) {
            [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:@[theTransfer.fileURL]];
        } else if (theTransfer.state == QTRTransferStateFailed) {
            BOOL canResume = NO;
            if ([self.delegate respondsToSelector:@selector(transfersController:needsResumeTransfer:)]) {
                if ([self.delegate transfersController:self needsResumeTransfer:theTransfer]) {
                    canResume = YES;
                }
            }
            if (!canResume) {
                // TODO: Show alert
            }
        }
    }
}

#pragma mark - Public methods

- (void)setTransfersStore:(QTRTransfersStore *)transfersStore {
    _transfersStore = transfersStore;
    [_transfersStore setDelegate:self];

    [self.transfersTableView reloadData];
}


#pragma mark - NSTableViewDataSource methods

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [[self.transfersStore transfers] count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
    return [[self.transfersStore transfers] objectAtIndex:rowIndex];
}

#pragma mark - QTRTransfersStoreDelegate methods

- (void)transfersStore:(QTRTransfersStore *)transfersStore didAddTransfersAtIndices:(NSIndexSet *)addedIndices {
    [self.transfersTableView insertRowsAtIndexes:addedIndices withAnimation:NSTableViewAnimationSlideDown];
}

- (void)transfersStore:(QTRTransfersStore *)transfersStore didDeleteTransfersAtIndices:(NSIndexSet *)deletedIndices {
    [self.transfersTableView removeRowsAtIndexes:deletedIndices withAnimation:NSTableViewAnimationSlideUp];
}

- (void)transfersStore:(QTRTransfersStore *)transfersStore didUpdateTransfersAtIndices:(NSIndexSet *)updatedIndices {
    [self.transfersTableView reloadDataForRowIndexes:updatedIndices columnIndexes:[NSIndexSet indexSetWithIndex:0]];
}

- (void)transfersStore:(QTRTransfersStore *)transfersStore didUpdateProgressOfTransferAtIndex:(NSUInteger)transferIndex {
    [self.transfersTableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:transferIndex] columnIndexes:[NSIndexSet indexSetWithIndex:0]];
}

#pragma mark - Notification callbacks

- (void)appWillTerminate:(NSNotification *)aNotification {
    [self.transfersStore archiveTransfers];
}




@end
