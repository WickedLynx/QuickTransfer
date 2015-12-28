//
//  QTRTransfersStore.m
//  QuickTransfer
//
//  Created by Harshad on 09/04/14.
//  Copyright (c) 2014 Laughing Buddha Software. All rights reserved.
//

#import "QTRTransfersStore.h"
#import "QTRTransfer.h"
#import "QTRFile.h"
#import "QTRUser.h"
#import "DTBonjourDataChunk.h"

float QTRTransfersControllerProgressThreshold = 0.02f;

@implementation QTRTransfersStore {

    NSMapTable *_dataChunksToTransfers;
    NSMutableArray *_allTransfers;
    NSMutableDictionary *_fileIdentifierToTransfers;
    NSString *_archivedTransfersFilePath;
}

#pragma mark - Initialisation

- (instancetype)initWithArchiveLocation:(NSString *)archiveLocation {
    self = [super init];

    if (self != nil) {
        _archivedTransfersFilePath = [archiveLocation copy];

        _dataChunksToTransfers = [NSMapTable strongToStrongObjectsMapTable];

        NSArray *array = [NSKeyedUnarchiver unarchiveObjectWithFile:_archivedTransfersFilePath];
        if (array != nil) {
            _allTransfers = [array mutableCopy];
            NSArray *fileIdentifiers = [_allTransfers valueForKey:@"fileIdentifier"];
            _fileIdentifierToTransfers = [NSMutableDictionary dictionaryWithObjects:_allTransfers forKeys:fileIdentifiers];
            [_allTransfers enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                QTRTransfer *transfer = (QTRTransfer *)obj;
                if (transfer.state == QTRTransferStateInProgress || transfer.state == QTRTransferStatePaused) {
                    [transfer setState:QTRTransferStateFailed];
                }
            }];
        } else {
            _allTransfers = [NSMutableArray new];
            _fileIdentifierToTransfers = [NSMutableDictionary new];
        }

#if TARGET_OS_IPHONE
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillTerminate:) name:UIApplicationWillTerminateNotification object:nil];

#else
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillTerminate:) name:NSApplicationWillTerminateNotification object:nil];
#endif
    }

    return self;
}

#pragma mark - Public methods

- (NSArray *)transfers {
    return [NSArray arrayWithArray:_allTransfers];
}

- (void)deleteTransfer:(id)transfer {
    [_allTransfers removeObject:transfer];
    [self archiveTransfers];
}

- (void)removeAllTransfers {

    NSIndexSet *deletedIndices = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [_allTransfers count])];

    [_dataChunksToTransfers removeAllObjects];
    [_allTransfers removeAllObjects];
    [_fileIdentifierToTransfers removeAllObjects];

    if ([self.delegate respondsToSelector:@selector(transfersStore:didDeleteTransfersAtIndices:)]) {
        [self.delegate transfersStore:self didDeleteTransfersAtIndices:deletedIndices];
    }

    [self archiveTransfers];
}

- (void)removeCompletedTransfers {

    NSIndexSet *indicesToDelete = [_allTransfers indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        BOOL pass = NO;

        QTRTransfer *transfer = (QTRTransfer *)obj;
        if (transfer.state == QTRTransferStateCompleted || transfer.state == QTRTransferStateFailed) {
            pass = YES;
        }
        return pass;
    }];

    [_allTransfers removeObjectsAtIndexes:indicesToDelete];

    if ([self.delegate respondsToSelector:@selector(transfersStore:didDeleteTransfersAtIndices:)]) {
        [self.delegate transfersStore:self didDeleteTransfersAtIndices:indicesToDelete];
    }

    [self archiveTransfers];
}

- (void)deleteTransfersAtIndexes:(NSIndexSet *)indexes {
    if (indexes.count > 0) {
        [_allTransfers removeObjectsAtIndexes:indexes];
        [self archiveTransfers];
        if ([self.delegate respondsToSelector:@selector(transfersStore:didDeleteTransfersAtIndices:)]) {
            [self.delegate transfersStore:self didDeleteTransfersAtIndices:indexes];
        }
    }
}

- (void)archiveTransfers {
    [NSKeyedArchiver archiveRootObject:_allTransfers toFile:_archivedTransfersFilePath];
}

#pragma mark - QTRBonjourTransferDelegate method

- (void)addTransferForUser:(QTRUser *)user file:(QTRFile *)file chunk:(DTBonjourDataChunk *)chunk {
    if (file != nil) {
        QTRTransfer *transfer = [QTRTransfer new];
        [transfer setUser:user];
        [transfer setFileURL:file.url];
        [transfer setTimestamp:[NSDate date]];
        [transfer setTotalParts:file.totalParts];
        [transfer setState:QTRTransferStateInProgress];
        [transfer setFileIdentifier:file.identifier];
        if (file.totalParts > 1) {
            [transfer setFileSize:file.totalSize];
        } else {
            [transfer setFileSize:[file length]];
        }
        [_allTransfers insertObject:transfer atIndex:0];
        [_dataChunksToTransfers setObject:transfer forKey:chunk];

        if ([self.delegate respondsToSelector:@selector(transfersStore:didAddTransfersAtIndices:)]) {
            [self.delegate transfersStore:self didAddTransfersAtIndices:[NSIndexSet indexSetWithIndex:0]];
        }
    }
}

- (void)resumeTransferForUser:(QTRUser *)user file:(QTRFile *)file chunk:(DTBonjourDataChunk *)chunk {
    if (file != nil) {
        QTRTransfer *transfer = [self transferForFileID:file.identifier];
        if (transfer != nil) {
            _fileIdentifierToTransfers[file.identifier] = transfer;
            [transfer setState:QTRTransferStateInProgress];
            [self archiveTransfers];
            NSInteger index = [_allTransfers indexOfObject:transfer];
            if ([self.delegate respondsToSelector:@selector(transfersStore:didUpdateTransfersAtIndices:)]) {
                [self.delegate transfersStore:self didUpdateTransfersAtIndices:[NSIndexSet indexSetWithIndex:index]];
            }
            if (chunk != nil) {
                [_dataChunksToTransfers setObject:transfer forKey:chunk];
            }
        }
    }
}

- (void)updateTransferForChunk:(DTBonjourDataChunk *)chunk {

    QTRTransfer *theTransfer = [_dataChunksToTransfers objectForKey:chunk];
    if (theTransfer != nil) {

        BOOL isSignificantUpdate = NO;
        BOOL transferComplete = NO;

        float progress = (double)(chunk.numberOfTransferredBytes) / (double)(chunk.totalBytes);

        if (theTransfer.totalParts == 1) {

            if (progress - theTransfer.progress > QTRTransfersControllerProgressThreshold) {
                [theTransfer setProgress:progress];
                isSignificantUpdate = YES;
            }

            if ([chunk isTransmissionComplete]) {
                [_dataChunksToTransfers removeObjectForKey:chunk];
                [theTransfer setState:QTRTransferStateCompleted];
                [theTransfer setProgress:1.0f];
                transferComplete = YES;
                [self archiveTransfers];
            }

        } else {

            if (progress == 1.0f || (progress - theTransfer.currentChunkProgress > QTRTransfersControllerProgressThreshold * 8)) {
                
                [theTransfer setCurrentChunkProgress:progress];

                isSignificantUpdate = YES;
            }

            if (theTransfer.progress == 1.0f) {
                [theTransfer setState:QTRTransferStateCompleted];
                [theTransfer setCurrentChunkProgress:1.0f];
                [_dataChunksToTransfers removeObjectForKey:chunk];
                transferComplete = YES;
                [self archiveTransfers];
            }

        }
        NSInteger index = [_allTransfers indexOfObject:theTransfer];

        if (transferComplete) {

            if ([self.delegate respondsToSelector:@selector(transfersStore:didUpdateTransfersAtIndices:)]) {
                [self.delegate transfersStore:self didUpdateTransfersAtIndices:[NSIndexSet indexSetWithIndex:index]];
            }

        } else if (isSignificantUpdate) {

            if ([self.delegate respondsToSelector:@selector(transfersStore:didUpdateProgressOfTransferAtIndex:)]) {
                [self.delegate transfersStore:self didUpdateProgressOfTransferAtIndex:index];
            }

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
    NSMutableIndexSet *modifiedIndices = [NSMutableIndexSet indexSet];
    int index = 0;
    for (QTRTransfer *aTransfer in _allTransfers) {
        if (aTransfer.progress < 1.0f && [aTransfer.user isEqual:user]) {
            [aTransfer setState:QTRTransferStateFailed];
            [modifiedIndices addIndex:index];
        }
        ++index;
    }

    if ([self.delegate respondsToSelector:@selector(transfersStore:didUpdateTransfersAtIndices:)]) {
        [self.delegate transfersStore:self didUpdateTransfersAtIndices:modifiedIndices];
    }

    [self archiveTransfers];

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
    [transfer setFileIdentifier:file.identifier];
    [transfer setIsIncoming:YES];
    [_allTransfers insertObject:transfer atIndex:0];
    _fileIdentifierToTransfers[file.identifier] = transfer;

    if (file.totalParts == (file.partIndex + 1)) {
        [transfer setProgress:1.0f];
        [transfer setState:QTRTransferStateCompleted];

        [self archiveTransfers];
    }

    if ([self.delegate respondsToSelector:@selector(transfersStore:didAddTransfersAtIndices:)]) {
        [self.delegate transfersStore:self didAddTransfersAtIndices:[NSIndexSet indexSetWithIndex:0]];
    }
}

- (void)updateTransferForFile:(QTRFile *)file {

    QTRTransfer *theTransfer = _fileIdentifierToTransfers[file.identifier];
    if (theTransfer.state != QTRTransferStatePaused) {
        theTransfer.state = QTRTransferStateInProgress;
    }
    if (theTransfer != nil && ![theTransfer isKindOfClass:[NSNull class]]) {
        [theTransfer setTransferedChunks:(file.partIndex + 1)];

        NSInteger transferIndex = [_allTransfers indexOfObject:theTransfer];

        if (theTransfer.progress == 1) {
            [theTransfer setState:QTRTransferStateCompleted];
            [self archiveTransfers];
            if ([self.delegate respondsToSelector:@selector(transfersStore:didUpdateTransfersAtIndices:)]) {
                [self.delegate transfersStore:self didUpdateTransfersAtIndices:[NSIndexSet indexSetWithIndex:transferIndex]];
            }
        } else {
            if ([self.delegate respondsToSelector:@selector(transfersStore:didUpdateProgressOfTransferAtIndex:)]) {
                [self.delegate transfersStore:self didUpdateProgressOfTransferAtIndex:transferIndex];
            }
        }

    }
}

- (void)updateSentBytes:(long long)sentBytes forFileID:(NSString *)fileID {
    QTRTransfer *theTransfer = [self transferForFileID:fileID];
    [theTransfer setSentBytes:sentBytes];
    [self archiveTransfers];
}

- (BOOL)canResumeTransferForFile:(QTRFile *)file {
    BOOL canResume = NO;
    QTRTransfer *transferToResume = [self transferForFileID:file.identifier];
    if (transferToResume.fileURL != nil) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if ([fileManager fileExistsAtPath:transferToResume.fileURL.path isDirectory:nil]) {
            NSDictionary *attributes = [fileManager attributesOfItemAtPath:transferToResume.fileURL.path error:nil];
            long long fileSize = [attributes[NSFileSize] longLongValue];
            if (fileSize == file.offset) {
                canResume = YES;
            }
        }
    }

    return canResume;
}

- (void)transferDidPause:(QTRTransfer *)transfer {
    [transfer setState:QTRTransferStatePaused];
    if ([_allTransfers containsObject:transfer]) {
        if ([self.delegate respondsToSelector:@selector(transfersStore:didUpdateTransfersAtIndices:)]) {
            [self.delegate transfersStore:self didUpdateTransfersAtIndices:[NSIndexSet indexSetWithIndex:[_allTransfers indexOfObject:transfer]]];
        }
    }
}

- (QTRTransfer *)transferForFileID:(NSString *)fileIdentifier {
    QTRTransfer *transfer = nil;
    for (QTRTransfer *aTransfer in _allTransfers) {
        if ([aTransfer.fileIdentifier isEqualToString:fileIdentifier]) {
            transfer = aTransfer;
            break;
        }
    }
    return transfer;
}

- (NSURL *)saveURLForResumedFile:(QTRFile *)file {
    return [[self transferForFileID:file.identifier] fileURL];
}

- (void)appWillTerminate:(NSNotification *)notification {
    for (QTRTransfer *transfer in _allTransfers) {
        if (transfer.state != QTRTransferStateCompleted) {
            [transfer setState:QTRTransferStateFailed];
        }
    }
    [self archiveTransfers];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
