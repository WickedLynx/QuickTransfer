//
//  QTRMessage.m
//  QuickTransfer
//
//  Created by Harshad on 18/02/14.
//  Copyright (c) 2014 Laughing Buddha Software. All rights reserved.
//

#import "QTRMessage.h"
#import "QTRUser.h"
#import "QTRFile.h"

NSString *const QTRMessageSenderKey = @"sender";
NSString *const QTRMessageFileKey = @"file";
NSString *const QTRMessageTypeKey = @"type";

@implementation QTRMessage

+ (instancetype)messageWithJSONData:(NSData *)data {

    NSError *jsonError = nil;
    QTRMessage *message = nil;
    NSDictionary *messageDictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&jsonError];

    @autoreleasepool {
        if (jsonError == nil) {

            message = [[[self class] alloc] init];

            NSDictionary *userInfo = messageDictionary[QTRMessageSenderKey];
            if (userInfo != nil) {
                [message setUser:[[QTRUser alloc] initWithDictionary:userInfo]];
            }

            NSDictionary *fileInfo = messageDictionary[QTRMessageFileKey];
            if (fileInfo != nil) {
                [message setFile:[[QTRFile alloc] initWithDictionary:fileInfo]];
            }

            NSString *type = messageDictionary[QTRMessageTypeKey];
            if (![type isKindOfClass:[NSNull class]]) {
                [message setType:[type intValue]];
            }


        } else {
            NSLog(@"QTRMessage: decoding error: %@", [jsonError localizedDescription]);
        }
        
        return message;
    }

}

+ (instancetype)messageWithUser:(QTRUser *)sender file:(QTRFile *)file {
    QTRMessage *message = nil;

    message = [[[self class] alloc] init];

    [message setUser:sender];
    [message setFile:file];

    return message;
}

- (NSData *)JSONData {
    @autoreleasepool {
        NSMutableDictionary *dictionaryRepresentation = [NSMutableDictionary new];

        NSDictionary *userInfo = [self.user dictionaryRepresentation];
        NSDictionary *fileInfo = [self.file dictionaryRepresentation];

        if (userInfo != nil) {
            dictionaryRepresentation[QTRMessageSenderKey] = userInfo;
        }

        if (fileInfo != nil) {
            dictionaryRepresentation[QTRMessageFileKey] = fileInfo;
        }

        dictionaryRepresentation[QTRMessageTypeKey] = @(self.type);

        NSError *jsonError = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dictionaryRepresentation options:NSJSONWritingPrettyPrinted error:&jsonError];

        if (jsonError != nil) {
            NSLog(@"QTRMessage: encoding error: %@", [jsonError localizedDescription]);
        }
        
        return jsonData;
    }

}

#pragma mark - NSCoding methods

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self != nil) {
        _user = [aDecoder decodeObjectForKey:QTRMessageSenderKey];
        _file = [aDecoder decodeObjectForKey:QTRMessageFileKey];
        _type = [aDecoder decodeIntegerForKey:QTRMessageTypeKey];
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:_user forKey:QTRMessageSenderKey];
    [aCoder encodeObject:_file forKey:QTRMessageFileKey];
    [aCoder encodeInteger:_type forKey:QTRMessageTypeKey];
}

@end
