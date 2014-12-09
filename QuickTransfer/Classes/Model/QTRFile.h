//
//  QTRFile.h
//  QuickTransfer
//
//  Created by Harshad on 19/02/14.
//  Copyright (c) 2014 Laughing Buddha Software. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 This class represents the file object intended to be shared with users
 */
@interface QTRFile : NSObject <NSCoding>

/*!
 Creates a file with its data
 @param fileName The name of the file
 @param fileType The content type of the file
 @param data The contents of the file
 */
- (instancetype)initWithName:(NSString *)fileName type:(NSString *)fileType data:(NSData *)data;

/*!
 Creates a file intended to be a part of a multipart transfer
 @param fileName The name of the file
 @param fileType The content type of the file
 @param partIndex The sequential index of the file as a part of a multipart transfer
 @param totalParts The total parts of the multipart transfer
 @param totalSize The total size in bytes of the multipart transfer
 */
- (instancetype)initWithName:(NSString *)fileName type:(NSString *)fileType partIndex:(NSUInteger)partIndex totalParts:(NSUInteger)totalParts totalSize:(long long)totalSize;

/*!
 The length of the data of the receiver
 */
- (NSUInteger)length;

/*!
 The name of the receiver
 */
@property (copy) NSString *name;

/*!
 The content type of the receiver
 */
@property (copy) NSString *type;

/*!
 The contents of the receiver
 */
@property (strong) NSData *data;

/*!
 The file URL from which the data of receiver was loaded
 */
@property (copy) NSURL *url;

/*!
 The multipart transfer part index of the receiver
 */
@property (nonatomic) NSUInteger partIndex;

/*!
 The total parts in the multipart transfer, of which the receiver is a part
 */
@property (nonatomic) NSUInteger totalParts;

/*!
 The total multipart transfer size, of which the receiver is a part of
 */
@property (nonatomic) long long totalSize;

/*!
 The unique identifier of the file
 */
@property (copy) NSString *identifier;

@end
