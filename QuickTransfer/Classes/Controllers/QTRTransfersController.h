//
//  QTRTransfersController.h
//  QuickTransfer
//
//  Created by Harshad on 27/02/14.
//  Copyright (c) 2014 Laughing Buddha Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@class QTRTransfer;
@class QTRUser;
@class DTBonjourDataChunk;
@class QTRFile;

@interface QTRTransfersController : NSObject

- (NSArray *)transfers;
- (void)addTransferForUser:(QTRUser *)user file:(QTRFile *)file chunk:(DTBonjourDataChunk *)chunk;
- (void)updateTransferForChunk:(DTBonjourDataChunk *)chunk;
- (void)removeAllTransfers;


@end
