//
//  QTRUser.h
//  QuickTransfer
//
//  Created by Harshad on 18/02/14.
//  Copyright (c) 2014 Laughing Buddha Software. All rights reserved.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString *const QTRUserPlatformAndroid;
FOUNDATION_EXPORT NSString *const QTRUserPlatformIOS;
FOUNDATION_EXPORT NSString *const QTRUserPlatformLinux;
FOUNDATION_EXPORT NSString *const QTRUserPlatformMac;
FOUNDATION_EXPORT NSString *const QTRUserPlatformWindows;

@interface QTRUser : NSObject

- (instancetype)initWithName:(NSString *)name identifier:(NSString *)identifier platform:(NSString *)platform;
- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

- (NSDictionary *)dictionaryRepresentation;

@property (copy) NSString *name;
@property (copy) NSString *identifier;
@property (copy) NSString *platform;

@end
