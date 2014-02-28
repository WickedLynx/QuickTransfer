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

    QTRTransfer *transfer = [QTRTransfer new];
    [transfer setUser:user];
    [transfer setFileURL:file.url];
    [transfer setFileSize:[file length]];
    [transfer setTimestamp:[NSDate date]];
    [_allTransfers insertObject:transfer atIndex:0];
    [_transfers setObject:transfer forKey:chunk];

    [self.transfersTableView reloadData];
}

- (void)updateTransferForChunk:(DTBonjourDataChunk *)chunk {

    QTRTransfer *theTransfer = [_transfers objectForKey:chunk];
    float progress = (double)(chunk.numberOfTransferredBytes) / (double)(chunk.totalBytes);
    [theTransfer setProgress:progress];

//    NSLog(@"Progress for file: %@ -- %f", theTransfer.file.name, progress);

    if ([chunk isTransmissionComplete]) {
        [_transfers removeObjectForKey:chunk];
        [theTransfer setProgress:1.0f];
    }

    [self.transfersTableView reloadData];

}

#pragma mark - NSTableViewDataSource methods

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [_allTransfers count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
    return _allTransfers[rowIndex];

}


@end
