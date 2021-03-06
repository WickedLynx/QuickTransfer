//
//  QTRUser.m
//  QuickTransfer
//
//  Created by Harshad on 18/02/14.
//  Copyright (c) 2014 Laughing Buddha Software. All rights reserved.
//

#import "QTRUser.h"
#import "QTRConstants.h"

NSString *const QTRUserPlatformAndroid = @"Android";
NSString *const QTRUserPlatformIOS = @"iOS";
NSString *const QTRUserPlatformLinux = @"Linux";
NSString *const QTRUserPlatformMac = @"Mac";
NSString *const QTRUserPlatformWindows = @"Windows";

@implementation QTRUser

#pragma mark - Initialisation

- (instancetype)initWithName:(NSString *)name identifier:(NSString *)identifier platform:(NSString *)platform {
    self = [super init];

    if (self != nil) {
        _name = [name copy];
        _identifier = [identifier copy];
        _platform = [platform copy];
    }

    return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {

    self = [super init];

    if (self != nil) {
        id name = dictionary[QTRBonjourTXTRecordNameKey];
        if ([name isKindOfClass:[NSData class]]) {
            name = [[NSString alloc] initWithData:name encoding:NSUTF8StringEncoding];
        }
        _name = name;

        id identifier = dictionary[QTRBonjourTXTRecordIdentifierKey];
        if ([identifier isKindOfClass:[NSData class]]) {
            identifier = [[NSString alloc] initWithData:identifier encoding:NSUTF8StringEncoding];
        }
        _identifier = identifier;

        id platform = dictionary[QTRBonjourTXTRecordPlatformKey];
        if ([platform isKindOfClass:[NSData class]]) {
            platform = [[NSString alloc] initWithData:platform encoding:NSUTF8StringEncoding];
        }

        _platform = [platform copy];
    }

    return self;
}

#pragma mark - Public methods

- (BOOL)isEqual:(id)object {
    BOOL isEqual = NO;

    if ([object isKindOfClass:[QTRUser class]]) {
        
        isEqual = [self.identifier isEqualToString:[object identifier]];
    }

    return isEqual;
}

- (NSDictionary *)dictionaryRepresentation {
    NSMutableDictionary *dictionary = [NSMutableDictionary new];

    if (self.name != nil) {
        dictionary[QTRBonjourTXTRecordNameKey] = self.name;
    }

    if (self.identifier != nil) {
        dictionary[QTRBonjourTXTRecordIdentifierKey] = self.identifier;
    }

    if (self.platform != nil) {
        dictionary[QTRBonjourTXTRecordPlatformKey] = self.platform;
    }

    return dictionary;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ {\nname: %@,\nidentifier: %@,\nplatform: %@\n}", [super description], self.name, self.identifier, self.platform];
}

#pragma mark - NSCoding methods

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];

    if (self != nil) {
        _name = [aDecoder decodeObjectForKey:QTRBonjourTXTRecordNameKey];
        _identifier = [aDecoder decodeObjectForKey:QTRBonjourTXTRecordIdentifierKey];
        _platform = [aDecoder decodeObjectForKey:QTRBonjourTXTRecordPlatformKey];
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {

    [aCoder encodeObject:self.name forKey:QTRBonjourTXTRecordNameKey];
    [aCoder encodeObject:self.identifier forKey:QTRBonjourTXTRecordIdentifierKey];
    [aCoder encodeObject:self.platform forKey:QTRBonjourTXTRecordPlatformKey];
}



@end
