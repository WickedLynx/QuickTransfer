//
//  QTRTransfer.m
//  QuickTransfer
//
//  Created by Harshad on 27/02/14.
//  Copyright (c) 2014 Laughing Buddha Software. All rights reserved.
//

#import "QTRTransfer.h"

@implementation QTRTransfer


- (float)progress {
    
    if (self.totalParts > 1) {
        _progress = (float)(self.transferedChunks + self.currentChunkProgress) / (float)self.totalParts;
    }

    return _progress;
}

@end
