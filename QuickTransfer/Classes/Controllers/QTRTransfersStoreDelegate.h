//
//  QTRTransfersStoreDelegate.h
//  QuickTransfer
//
//  Created by Harshad on 09/04/14.
//  Copyright (c) 2014 Laughing Buddha Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@class QTRTransfersStore;

@protocol QTRTransfersStoreDelegate <NSObject>

@optional

- (void)transfersStore:(QTRTransfersStore *)transfersStore didAddTransfersAtIndices:(NSIndexSet *)addedIndices;
- (void)transfersStore:(QTRTransfersStore *)transfersStore didDeleteTransfersAtIndices:(NSIndexSet *)deletedIndices;
- (void)transfersStore:(QTRTransfersStore *)transfersStore didUpdateTransfersAtIndices:(NSIndexSet *)updatedIndices;


@end
