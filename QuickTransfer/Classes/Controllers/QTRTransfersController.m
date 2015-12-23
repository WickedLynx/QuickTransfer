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
    
    [self.window setMovableByWindowBackground:YES];
    NSVisualEffectView *view = (NSVisualEffectView *)self.window.contentView;
    [view setState:NSVisualEffectStateActive];
    [view setMaterial:NSVisualEffectMaterialDark];

    [self.transfersTableView setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleNone];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillTerminate:) name:NSApplicationWillTerminateNotification object:nil];
}

#pragma mark - Actions

- (IBAction)clickClearCompleted:(id)sender {

    [self.transfersStore removeCompletedTransfers];
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
        } else if (theTransfer.state == QTRTransferStateFailed) {
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
        }
    }
}

#pragma mark - Notification callbacks

- (void)appWillTerminate:(NSNotification *)aNotification {
    [self.transfersStore archiveTransfers];
}




@end
