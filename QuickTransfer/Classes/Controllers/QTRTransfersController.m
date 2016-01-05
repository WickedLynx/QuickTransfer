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
#import "QTRTransfersTableCellView.h"
#import "QTRTransfersTableRowView.h"
#import "QTRTransfersTableView.h"

NSString *const QTRTransfersTableRowViewIdentifier = @"QTRTransfersTableRowViewIdentifier";

@implementation QTRTransfersController

#pragma mark - Initialisation

- (void)awakeFromNib {
    [super awakeFromNib];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillTerminate:) name:NSApplicationWillTerminateNotification object:nil];
    [self.showDevicesButton setAttributedTitle:[[NSAttributedString alloc] initWithString:self.showDevicesButton.title attributes:@{NSForegroundColorAttributeName : [NSColor whiteColor], NSFontAttributeName : [NSFont systemFontOfSize:10.0f]}]];
}

#pragma mark - Public methods

- (void)setTransfersStore:(QTRTransfersStore *)transfersStore {
    _transfersStore = transfersStore;
    [_transfersStore setDelegate:self];

    [self.transfersTableView reloadData];
}

- (IBAction)showDevices:(id)sender {
    if ([self.delegate respondsToSelector:@selector(transfersControllerNeedsToShowDevices:)]) {
        [self.delegate transfersControllerNeedsToShowDevices:self];
    }
}


#pragma mark - NSTableViewDataSource methods

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [[self.transfersStore transfers] count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
    return [[self.transfersStore transfers] objectAtIndex:rowIndex];
}

#pragma mark - NSTableViewDelegate methods

- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row {
    QTRTransfer *transfer = [[self.transfersStore transfers] objectAtIndex:row];
    return transfer.state != QTRTransferStateInProgress;
}

- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row {
    NSTableRowView *rowView = [tableView makeViewWithIdentifier:QTRTransfersTableRowViewIdentifier owner:self];
    if (rowView == nil) {
        rowView = [[QTRTransfersTableRowView alloc] initWithFrame:NSZeroRect];
        [rowView setIdentifier:QTRTransfersTableRowViewIdentifier];
    }
    return rowView;
}

#pragma mark - QTRTransfersTableViewDelegate methods

- (void)transfersTableViewDidDetectDeleteKeyDown:(QTRTransfersTableView *)tableView {
    [self.transfersStore deleteTransfersAtIndexes:tableView.selectedRowIndexes];
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

#pragma mark - QTRTransfersTableCellView delgate methods

- (void)transfersTableCellViewDidClickPrimaryButton:(QTRTransfersTableCellView *)cellView {
    NSUInteger clickedRow = [self.transfersTableView rowForView:cellView];
    if (clickedRow < [[self.transfersStore transfers] count]) {
        QTRTransfer *theTransfer = [[self.transfersStore transfers] objectAtIndex:clickedRow];
        if (theTransfer.progress == 1.0f) {
            [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:@[theTransfer.fileURL]];
        } else if (theTransfer.state == QTRTransferStateFailed || theTransfer.state == QTRTransferStatePaused) {
            BOOL canResume = NO;
            if ([self.delegate respondsToSelector:@selector(transfersController:needsResumeTransfer:)]) {
                if ([self.delegate transfersController:self needsResumeTransfer:theTransfer]) {
                    canResume = YES;
                }
            }
            if (!canResume) {
                NSAlert *alert = [[NSAlert alloc] init];
                [alert setMessageText:@"This transfer cannot be resumed. Try re-sending the file."];
                [alert.window setTitle:@"Cannot resume transfer"];
                [alert addButtonWithTitle:@"Okay"];
                [alert beginSheetModalForWindow:self.window completionHandler:nil];
            }
        } else if (![theTransfer isIncoming]) {
            if ([self.delegate respondsToSelector:@selector(transfersController:needsPauseTransfer:)]) {
                [self.delegate transfersController:self needsPauseTransfer:theTransfer];
            }
        }
    }
}

- (QTRTransfer *)transferForCellView:(QTRTransfersTableCellView *)cellView {
    QTRTransfer *transfer = nil;
    NSUInteger index = [self.transfersTableView rowForView:cellView];
    NSArray *transfers = [_transfersStore transfers];
    if (index < transfers.count) {
        transfer = transfers[index];
    }

    return transfer;
}

#pragma mark - Notification callbacks

- (void)appWillTerminate:(NSNotification *)aNotification {
    [self.transfersStore archiveTransfers];
}




@end
