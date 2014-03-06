//
//  QTRMessage.h
//  QuickTransfer
//
//  Created by Harshad on 18/02/14.
//  Copyright (c) 2014 Laughing Buddha Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@class QTRFile;
@class QTRUser;

/*!
 This class represents the messages that are sent between users
 */
@interface QTRMessage : NSObject

/*!
 Creates a message with a sender and a file
 @param sender The sender of the message
 @param file The file to be sent
 */
+ (instancetype)messageWithUser:(QTRUser *)sender file:(QTRFile *)file;

/*!
 Creates a message by reading the key value pairs specified in the json data
 @param data The json encoded binary data which contains the key-value pairs of a message
 */
+ (instancetype)messageWithJSONData:(NSData *)data;

/*!
 Returns json encoded data with the properties of the receiver as key-value pairs
 */
- (NSData *)JSONData;

/*!
 The user/sender of the receiver
 */
@property (strong) QTRUser *user;

/*!
 The file contained in the receiver
 */
@property (strong) QTRFile *file;

@end
