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

@implementation QTRFile

- (instancetype)initWithName:(NSString *)fileName type:(NSString *)fileType data:(NSData *)data {
    self = [super init];

    if (self != nil) {
        _name = [fileName copy];
        _type = [fileType copy];
        _data = data;
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

            _data = [NSData dataWithBase64EncodedString:encodedData];
        }
    }

    return self;
}

- (NSDictionary *)dictionaryRepresentation {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithCapacity:3];

    if (_name != nil) {
        dictionary[QTRFileNameKey] = _name;
    }

    if (_type != nil) {
        dictionary[QTRFileTypeKey] = _type;
    }

    if (_data != nil) {

        NSString *encodedData = [_data base64EncodedString];
        if (encodedData != nil) {
            dictionary[QTRFileDataKey] = encodedData;
        }
    }

    return dictionary;
}

- (NSUInteger)length {
    return self.data.length;
}

@end
