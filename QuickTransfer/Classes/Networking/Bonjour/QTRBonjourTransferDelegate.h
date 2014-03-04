//
//  QTRBonjourTransferDelegate.h
//  QuickTransfer
//
//  Created by Harshad on 27/02/14.
//  Copyright (c) 2014 Laughing Buddha Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@class QTRUser;
@class QTRFile;
@class DTBonjourDataChunk;

@protocol QTRBonjourTransferDelegate <NSObject>

@optional

- (void)addTransferForUser:(QTRUser *)user file:(QTRFile *)file chunk:(DTBonjourDataChunk *)chunk;
- (void)updateTransferForChunk:(DTBonjourDataChunk *)chunk;
- (void)replaceChunk:(DTBonjourDataChunk *)oldChunk withChunk:(DTBonjourDataChunk *)newChunk;

@end
