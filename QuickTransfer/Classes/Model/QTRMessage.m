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
NSString *const QTRMessageTextKey = @"text";

@implementation QTRMessage

+ (instancetype)messageWithUser:(QTRUser *)sender file:(QTRFile *)file {
    QTRMessage *message = nil;

    message = [[[self class] alloc] init];

    [message setUser:sender];
    [message setFile:file];

    return message;
}

+ (instancetype)messageWithUser:(QTRUser *)sender text:(NSString *)text {
    QTRMessage *message = nil;

    message = [[[self class] alloc] init];

    [message setUser:sender];
    message->_text = text;
    [message setType:QTRMessageTypeText];

    return message;
}

#pragma mark - NSCoding methods

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self != nil) {
        _user = [aDecoder decodeObjectForKey:QTRMessageSenderKey];
        _file = [aDecoder decodeObjectForKey:QTRMessageFileKey];
        _type = [aDecoder decodeIntegerForKey:QTRMessageTypeKey];
        _text = [aDecoder decodeObjectForKey:QTRMessageTextKey];
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:_user forKey:QTRMessageSenderKey];
    [aCoder encodeObject:_file forKey:QTRMessageFileKey];
    [aCoder encodeInteger:_type forKey:QTRMessageTypeKey];
    [aCoder encodeObject:_text forKey:QTRMessageTextKey];
}

@end
