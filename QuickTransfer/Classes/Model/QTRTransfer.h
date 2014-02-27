//
//  QTRTransfer.h
//  QuickTransfer
//
//  Created by Harshad on 27/02/14.
//  Copyright (c) 2014 Laughing Buddha Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@class QTRUser;
@class QTRFile;
@class DTBonjourDataChunk;

@interface QTRTransfer : NSObject

@property (nonatomic) float progress;
@property (strong) QTRUser *user;
@property (strong) QTRFile *file;

@end
