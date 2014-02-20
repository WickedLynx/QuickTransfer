//
//  QTRMessage.h
//  QuickTransfer
//
//  Created by Harshad on 18/02/14.
//  Copyright (c) 2014 Laughing Buddha Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@class QTRFile;
@class QTRUser;

@interface QTRMessage : NSObject

+ (instancetype)messageWithUser:(QTRUser *)sender file:(QTRFile *)file;
+ (instancetype)messageWithJSONData:(NSData *)data;

- (NSData *)JSONData;

@property (strong) QTRUser *user;
@property (strong) QTRFile *file;

@end
