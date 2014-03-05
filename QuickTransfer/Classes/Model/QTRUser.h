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

/**
 This class represents a user of the application
 */

@interface QTRUser : NSObject

/**
 Creates a user object with the information passed. This is the default way to create users.
 @param name The display name of the user.
 @param identifier The unique identifier of the user.
 @param platform The platform the user is currently running the application on.
 */
- (instancetype)initWithName:(NSString *)name identifier:(NSString *)identifier platform:(NSString *)platform;

/**
 Creates a new user object and sets its properties using key-value pairs
 @param dictionary The dictionary containing the properties of the user as key-value pairs
 */
- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

/**
 Returns a dictionary with the properties of the receiver as key-value pairs
 */
- (NSDictionary *)dictionaryRepresentation;

/**
 The name of the receiver
 */
@property (copy) NSString *name;

/**
 The unique identifier of the receiver
 */
@property (copy) NSString *identifier;

/**
 The platform of the receiver
 */
@property (copy) NSString *platform;

@end
