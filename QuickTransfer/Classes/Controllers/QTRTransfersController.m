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
}

- (id)init {
    self = [super init];

    if (self != nil) {
        _transfers = [NSMapTable strongToStrongObjectsMapTable];
    }

    return self;
}

- (void)addTransferForUser:(QTRUser *)user file:(QTRFile *)file chunk:(DTBonjourDataChunk *)chunk {

    QTRTransfer *transfer = [QTRTransfer new];
    [transfer setUser:user];
    [transfer setFile:file];

    [_transfers setObject:transfer forKey:chunk];
}

- (void)updateTransferForChunk:(DTBonjourDataChunk *)chunk {

    QTRTransfer *theTransfer = [_transfers objectForKey:chunk];
    float progress = chunk.numberOfTransferredBytes / chunk.totalBytes;
    [theTransfer setProgress:progress];

    if ([chunk isTransmissionComplete]) {
        [_transfers removeObjectForKey:chunk];
    }

    NSLog(@"Progress for file: %@ -- %f", theTransfer.file.name, progress);
}

- (NSArray *)transfers {
    NSMutableArray *transfers = [NSMutableArray arrayWithCapacity:[_transfers count]];
    NSEnumerator *objectEnumerator = [_transfers objectEnumerator];
    id object = nil;
    while (object = [objectEnumerator nextObject]) {
        [transfers addObject:object];
    }

    return transfers;
}

- (void)removeAllTransfers {
    [_transfers removeAllObjects];
}

@end
