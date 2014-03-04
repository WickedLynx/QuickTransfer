//
//  QTRMultipartWriter.h
//  QuickTransfer
//
//  Created by Harshad on 04/03/14.
//  Copyright (c) 2014 Laughing Buddha Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@class QTRFile;
@class QTRUser;

@interface QTRMultipartWriter : NSObject

- (instancetype)initWithFilePart:(QTRFile *)filePart sender:(QTRUser *)user saveURL:(NSURL *)url;

- (void)writeFilePart:(QTRFile *)filePart completion:(void (^)())completionBlock;
- (void)closeFile;

@property (copy, nonatomic) NSURL *saveURL;
@property (strong) QTRUser *user;
@property (copy) NSString *fileName;

@end
