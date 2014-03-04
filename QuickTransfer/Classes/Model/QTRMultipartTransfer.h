//
//  QTRMultipartTransfer.h
//  QuickTransfer
//
//  Created by Harshad on 03/03/14.
//  Copyright (c) 2014 Laughing Buddha Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@class QTRUser;
@class QTRFile;

FOUNDATION_EXPORT long long const QTRMultipartTransferMaximumPartSize;

@interface QTRMultipartTransfer : NSObject

- (instancetype)initWithFileURL:(NSURL *)fileURL user:(QTRUser *)user;

- (void)readNextPartForTransmission:(void (^)(QTRFile *file, BOOL isLastPart))dataReadCompletion;

@property (copy) NSString *fileName;
@property (strong) QTRUser *user;

@end
