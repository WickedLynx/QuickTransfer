//
//  QTRFile.m
//  QuickTransfer
//
//  Created by Harshad on 19/02/14.
//  Copyright (c) 2014 Laughing Buddha Software. All rights reserved.
//

#import "QTRFile.h"
#import "Base64.h"

NSString *const QTRFileNameKey = @"name";
NSString *const QTRFileTypeKey = @"type";
NSString *const QTRFileDataKey = @"data";
NSString *const QTRFilePartIndexKey = @"partIndex";
NSString *const QTRFileTotalPartsKey = @"totalParts";
NSString *const QTRFileTotalSizeKey = @"totalSize";
NSString *const QTRFileIdentifierKey = @"identifier";

@implementation QTRFile

- (instancetype)initWithName:(NSString *)fileName type:(NSString *)fileType data:(NSData *)data {
    self = [super init];

    if (self != nil) {
        _name = [fileName copy];
        _type = [fileType copy];
        _data = data;
        _totalParts = 1;
        _partIndex = 0;
        _totalSize = [data length];
        _identifier = @"1";
    }

    return self;
}

- (instancetype)initWithName:(NSString *)fileName type:(NSString *)fileType partIndex:(NSUInteger)partIndex totalParts:(NSUInteger)totalParts totalSize:(long long)totalSize {
    self = [super init];
    if (self != nil) {
        _name = [fileName copy];
        _type = [fileType copy];
        _partIndex = partIndex;
        _totalParts = totalParts;
        _totalSize = totalSize;
    }

    return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    if (self != nil) {
        _name = dictionary[QTRFileNameKey];
        _type = dictionary[QTRFileTypeKey];

        NSString *encodedData = dictionary[QTRFileDataKey];
        if (encodedData.length > 0) {
            @autoreleasepool {
                _data = [NSData dataWithBase64EncodedString:encodedData];
            }

        }

        NSNumber *partIndex = dictionary[QTRFilePartIndexKey];
        if (![partIndex isKindOfClass:[NSNull class]]) {
            _partIndex = [partIndex integerValue];
        }

        NSNumber *totalParts = dictionary[QTRFileTotalPartsKey];
        if (![totalParts isKindOfClass:[NSNull class]]) {
            _totalParts = [totalParts integerValue];
        }

        NSNumber *totalSizeKey = dictionary[QTRFileTotalSizeKey];
        if (![totalSizeKey isKindOfClass:[NSNull class]]) {
            _totalSize = [totalParts longLongValue];
        }

        _identifier = dictionary[QTRFileIdentifierKey];
    }

    return self;
}

- (NSDictionary *)dictionaryRepresentation {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithCapacity:6];

    if (_name != nil) {
        dictionary[QTRFileNameKey] = _name;
    }

    if (_type != nil) {
        dictionary[QTRFileTypeKey] = _type;
    }
    @autoreleasepool {
        if (_data != nil) {

            NSString *encodedData = [_data base64EncodedString];
            if (encodedData != nil) {
                dictionary[QTRFileDataKey] = encodedData;
            }
        }
    }


    dictionary[QTRFilePartIndexKey] = @(_partIndex);
    dictionary[QTRFileTotalPartsKey] = @(_totalParts);
    dictionary[QTRFileTotalSizeKey] = @(_totalSize);

    if (_identifier != nil) {
        dictionary[QTRFileIdentifierKey] = _identifier;
    }

    return dictionary;
}

- (NSUInteger)length {
    return self.data.length;
}

- (BOOL)isEqual:(id)object {
    BOOL isEqual = NO;
    if ([object isKindOfClass:[QTRFile class]]) {
        QTRFile *otherFile = (QTRFile *)object;

        if ([otherFile.name isEqualToString:self.name] && [otherFile length] == [self length] && [otherFile.type isEqualToString:self.type]) {
            isEqual = YES;
        }
    }

    return isEqual;
}

@end
