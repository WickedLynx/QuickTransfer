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
- (instancetype)initWithName:(NSString *)fileName type:(NSString *)fileType partIndex:(NSUInteger)partIndex totalParts:(NSUInteger)totalParts totalSize:(long long)totalSize;
- (instancetype)initWithDictionary:(NSDictionary *)dictionary;
- (NSDictionary *)dictionaryRepresentation;
- (NSUInteger)length;
- (NSString *)multipartID;

@property (copy) NSString *name;
@property (copy) NSString *type;
@property (strong) NSData *data;
@property (copy) NSURL *url;
@property (nonatomic) NSUInteger partIndex;
@property (nonatomic) NSUInteger totalParts;
@property (nonatomic) long long totalSize;
@property (copy) NSString *multipartID;

@end
