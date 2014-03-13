//
//  QTRTransfersController.m
//  QuickTransfer
//
//  Created by Harshad on 27/02/14.
//  Copyright (c) 2014 Laughing Buddha Software. All rights reserved.
//

#import "QTRTransfersController.h"
#import "QTRUser.h"
#import "QTRFile.h"
#import "QTRTransfer.h"
#import "DTBonjourDataChunk.h"

float QTRTransfersControllerProgressThreshold = 0.02f;

@implementation QTRTransfersController {
    NSMapTable *_dataChunksToTransfers;
    NSMutableArray *_allTransfers;
    NSMutableDictionary *_fileIdentifierToTransfers;
}

- (id)init {
    self = [super init];

    if (self != nil) {
        _dataChunksToTransfers = [NSMapTable strongToStrongObjectsMapTable];
        _allTransfers = [NSMutableArray new];
        _fileIdentifierToTransfers = [NSMutableDictionary new];
    }

    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self.transfersTableView setTarget:self];
    [self.transfersTableView setDoubleAction:@selector(clickTransfer:)];
}

#pragma mark - Actions

- (IBAction)clickClearCompleted:(id)sender {

    NSArray *completedTransfers = [_allTransfers filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"state == %d OR state == %d", QTRTransferStateCompleted, QTRTransferStateFailed]];
    NSInteger count = [completedTransfers count];
    for (NSInteger transferIndex = 0; transferIndex != count; ++transferIndex) {
        QTRTransfer *theTransfer = completedTransfers[transferIndex];
        [_allTransfers removeObject:theTransfer];
    }

    [self.transfersTableView reloadData];
}

- (void)clickTransfer:(id)sender {
    NSUInteger clickedRow = [self.transfersTableView clickedRow];
    if (clickedRow < _allTransfers.count) {
        QTRTransfer *theTransfer = _allTransfers[clickedRow];
        if (theTransfer.progress == 1.0f) {
            [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:@[theTransfer.fileURL]];
        }
    }
}

#pragma mark - Public methods

- (void)removeAllTransfers {
    [_dataChunksToTransfers removeAllObjects];
    [_allTransfers removeAllObjects];
    [_fileIdentifierToTransfers removeAllObjects];

    [self.transfersTableView reloadData];
}

#pragma mark - QTRBonjourTransferDelegate methods

- (void)addTransferForUser:(QTRUser *)user file:(QTRFile *)file chunk:(DTBonjourDataChunk *)chunk {
    if (file != nil) {
        QTRTransfer *transfer = [QTRTransfer new];
        [transfer setUser:user];
        [transfer setFileURL:file.url];
        [transfer setTimestamp:[NSDate date]];
        [transfer setTotalParts:file.totalParts];
        [transfer setState:QTRTransferStateInProgress];
        if (file.totalParts > 1) {
            [transfer setFileSize:file.totalSize];
        } else {
            [transfer setFileSize:[file length]];
        }
        [_allTransfers insertObject:transfer atIndex:0];
        [_dataChunksToTransfers setObject:transfer forKey:chunk];

        [self.transfersTableView reloadData];
    }

}

- (void)updateTransferForChunk:(DTBonjourDataChunk *)chunk {

    QTRTransfer *theTransfer = [_dataChunksToTransfers objectForKey:chunk];
    if (theTransfer != nil) {

        BOOL shouldReload = NO;

        float progress = (double)(chunk.numberOfTransferredBytes) / (double)(chunk.totalBytes);

        if (theTransfer.totalParts == 1) {

            if (progress - theTransfer.progress > QTRTransfersControllerProgressThreshold) {
                [theTransfer setProgress:progress];
                shouldReload = YES;
            }

            if ([chunk isTransmissionComplete]) {
                [_dataChunksToTransfers removeObjectForKey:chunk];
                [theTransfer setState:QTRTransferStateCompleted];
                [theTransfer setProgress:1.0f];
                shouldReload = YES;
            }

        } else {

            if (progress == 1.0f || (progress - theTransfer.currentChunkProgress > QTRTransfersControllerProgressThreshold * 2)) {
                [theTransfer setCurrentChunkProgress:progress];
                shouldReload = YES;
            }

            if (theTransfer.progress == 1.0f) {
                [theTransfer setState:QTRTransferStateCompleted];
                [theTransfer setCurrentChunkProgress:1.0f];
                [_dataChunksToTransfers removeObjectForKey:chunk];
                shouldReload = YES;
            }

        }

        if (shouldReload) {

            NSInteger row = [_allTransfers indexOfObject:theTransfer];
            [self.transfersTableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:row] columnIndexes:[NSIndexSet indexSetWithIndex:0]];
        }
    }
}

- (void)replaceChunk:(DTBonjourDataChunk *)oldChunk withChunk:(DTBonjourDataChunk *)newChunk {
    QTRTransfer *transfer = [_dataChunksToTransfers objectForKey:oldChunk];
    if (transfer != nil) {
        [_dataChunksToTransfers removeObjectForKey:oldChunk];
        [transfer setCurrentChunkProgress:0.0f];
        ++transfer.transferedChunks;
        [_dataChunksToTransfers setObject:transfer forKey:newChunk];
    }
}

- (void)failAllTransfersForUser:(QTRUser *)user {

    for (QTRTransfer *aTransfer in _allTransfers) {
        if (aTransfer.progress < 1.0f && [aTransfer.user isEqual:user]) {
            [aTransfer setState:QTRTransferStateFailed];
        }
    }

    [self.transfersTableView reloadData];
}

- (void)addTransferFromUser:(QTRUser *)user file:(QTRFile *)file {

    QTRTransfer *transfer = [QTRTransfer new];
    [transfer setUser:user];
    [transfer setTimestamp:[NSDate date]];
    [transfer setTotalParts:file.totalParts];
    [transfer setState:QTRTransferStateInProgress];
    [transfer setTransferedChunks:(file.partIndex + 1)];
    [transfer setFileSize:file.totalSize];
    [transfer setFileURL:file.url];
    [_allTransfers insertObject:transfer atIndex:0];
    _fileIdentifierToTransfers[file.identifier] = transfer;

    if (file.totalParts == (file.partIndex + 1)) {
        [transfer setProgress:1.0f];
        [transfer setState:QTRTransferStateCompleted];
    }

    [self.transfersTableView reloadData];
}

- (void)updateTransferForFile:(QTRFile *)file {
    QTRTransfer *theTransfer = _fileIdentifierToTransfers[file.identifier];
    if (theTransfer != nil && ![theTransfer isKindOfClass:[NSNull class]]) {
        [theTransfer setTransferedChunks:(file.partIndex + 1)];
        if (theTransfer.progress == 1) {
            [theTransfer setState:QTRTransferStateCompleted];
        }

        NSInteger cellIndex = [_allTransfers indexOfObject:theTransfer];
        [self.transfersTableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:cellIndex] columnIndexes:[NSIndexSet indexSetWithIndex:0]];
    }


}

#pragma mark - NSTableViewDataSource methods

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [_allTransfers count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
    return _allTransfers[rowIndex];

}




@end
