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

@implementation QTRMessage


+ (instancetype)messageWithJSONData:(NSData *)data {

    NSError *jsonError = nil;
    QTRMessage *message = nil;
    NSDictionary *messageDictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&jsonError];

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


    } else {
        NSLog(@"QTRMessage: decoding error: %@", [jsonError localizedDescription]);
    }

    return message;
}

+ (instancetype)messageWithUser:(QTRUser *)sender file:(QTRFile *)file {
    QTRMessage *message = nil;

    message = [[[self class] alloc] init];

    [message setUser:sender];
    [message setFile:file];

    return message;
}

- (NSData *)JSONData {

    NSMutableDictionary *dictionaryRepresentation = [NSMutableDictionary new];

    NSDictionary *userInfo = [self.user dictionaryRepresentation];
    NSDictionary *fileInfo = [self.file dictionaryRepresentation];

    if (userInfo != nil) {
        dictionaryRepresentation[QTRMessageSenderKey] = userInfo;
    }

    if (fileInfo != nil) {
        dictionaryRepresentation[QTRMessageFileKey] = fileInfo;
    }

    NSError *jsonError = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dictionaryRepresentation options:NSJSONWritingPrettyPrinted error:&jsonError];

    if (jsonError != nil) {
        NSLog(@"QTRMessage: encoding error: %@", [jsonError localizedDescription]);
    }

    return jsonData;
}

@end
