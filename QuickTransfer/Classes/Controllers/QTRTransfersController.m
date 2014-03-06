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
    NSMapTable *_transfers;
    NSMutableArray *_allTransfers;
}

- (id)init {
    self = [super init];

    if (self != nil) {
        _transfers = [NSMapTable strongToStrongObjectsMapTable];
        _allTransfers = [NSMutableArray new];
    }

    return self;
}

#pragma mark - Actions

- (IBAction)clickClearCompleted:(id)sender {

    NSArray *completedTransfers = [_allTransfers filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"progress >= 1"]];
    NSInteger count = [completedTransfers count];
    for (NSInteger transferIndex = 0; transferIndex != count; ++transferIndex) {
        QTRTransfer *theTransfer = completedTransfers[transferIndex];
        [_allTransfers removeObject:theTransfer];
        [_transfers removeObjectForKey:theTransfer];
    }

    [self.transfersTableView reloadData];
}

#pragma mark - Public methods

- (NSArray *)transfers {

    return _allTransfers;
}

- (void)removeAllTransfers {
    [_transfers removeAllObjects];
    [_allTransfers removeAllObjects];

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
        if (file.totalParts > 1) {
            [transfer setFileSize:file.totalSize];
        } else {
            [transfer setFileSize:[file length]];
        }
        [_allTransfers insertObject:transfer atIndex:0];
        [_transfers setObject:transfer forKey:chunk];

        [self.transfersTableView reloadData];
    }

}

- (void)updateTransferForChunk:(DTBonjourDataChunk *)chunk {

    QTRTransfer *theTransfer = [_transfers objectForKey:chunk];
    if (theTransfer != nil) {

        BOOL shouldReload = NO;

        float progress = (double)(chunk.numberOfTransferredBytes) / (double)(chunk.totalBytes);

        if (theTransfer.totalParts == 1) {

            if (progress - theTransfer.progress > QTRTransfersControllerProgressThreshold) {
                [theTransfer setProgress:progress];
                shouldReload = YES;
            }

            if ([chunk isTransmissionComplete]) {
                [_transfers removeObjectForKey:chunk];
                [theTransfer setProgress:1.0f];
                shouldReload = YES;
            }

        } else {

            if (progress == 1.0f || (progress - theTransfer.currentChunkProgress > QTRTransfersControllerProgressThreshold * 2)) {
                [theTransfer setCurrentChunkProgress:progress];
                shouldReload = YES;
            }

            if (theTransfer.progress == 1.0f) {
                [theTransfer setCurrentChunkProgress:1.0f];
                [_transfers removeObjectForKey:chunk];
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
    QTRTransfer *transfer = [_transfers objectForKey:oldChunk];
    if (transfer != nil) {
        [_transfers removeObjectForKey:oldChunk];
        [transfer setCurrentChunkProgress:0.0f];
        ++transfer.transferedChunks;
        [_transfers setObject:transfer forKey:newChunk];
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
