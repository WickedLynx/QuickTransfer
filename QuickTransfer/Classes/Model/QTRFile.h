//
//  QTRFile.h
//  QuickTransfer
//
//  Created by Harshad on 19/02/14.
//  Copyright (c) 2014 Laughing Buddha Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface QTRFile : NSObject

- (instancetype)initWithName:(NSString *)fileName type:(NSString *)fileType data:(NSData *)data;
- (instancetype)initWithDictionary:(NSDictionary *)dictionary;
- (NSDictionary *)dictionaryRepresentation;
- (NSUInteger)length;

@property (copy) NSString *name;
@property (copy) NSString *type;
@property (strong) NSData *data;
@property (copy) NSURL *url;

@end
