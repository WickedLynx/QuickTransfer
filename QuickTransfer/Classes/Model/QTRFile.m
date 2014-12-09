//
//  QTRFile.m
//  QuickTransfer
//
//  Created by Harshad on 19/02/14.
//  Copyright (c) 2014 Laughing Buddha Software. All rights reserved.
//

#import "QTRFile.h"

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

#pragma mark - NSCoding methods

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];

    if (self != nil) {
        _name = [aDecoder decodeObjectForKey:QTRFileNameKey];
        _type = [aDecoder decodeObjectForKey:QTRFileTypeKey];
        _data = [aDecoder decodeObjectForKey:QTRFileDataKey];
        _partIndex = [aDecoder decodeIntegerForKey:QTRFilePartIndexKey];
        _totalParts = [aDecoder decodeIntegerForKey:QTRFileTotalPartsKey];
        NSNumber *sizeAsNumber = [aDecoder decodeObjectForKey:QTRFileTotalSizeKey];
        _totalSize = [sizeAsNumber longLongValue];
        _identifier = [aDecoder decodeObjectForKey:QTRFileIdentifierKey];
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:_name forKey:QTRFileNameKey];
    [aCoder encodeObject:_type forKey:QTRFileTypeKey];
    [aCoder encodeObject:_data forKey:QTRFileDataKey];
    [aCoder encodeInteger:_partIndex forKey:QTRFilePartIndexKey];
    [aCoder encodeInteger:_totalParts forKey:QTRFileTotalPartsKey];
    NSNumber *sizeAsNumber = @(_totalSize);
    [aCoder encodeObject:sizeAsNumber forKey:QTRFileTotalSizeKey];
    [aCoder encodeObject:_identifier forKey:QTRFileIdentifierKey];
}

@end
