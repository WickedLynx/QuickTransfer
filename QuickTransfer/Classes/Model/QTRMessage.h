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
 This enum defines the various types of messages
 */
typedef NS_ENUM(NSInteger, QTRMessageType) {
    /*!
     The message contains the userinfo of the sender
     */
    QTRMessageTypeUserInfo = 0,

    /*!
     The sender is requesting the userinfo of the receiver.
     
     The reciver will respond to this message with a QTRMessageTypeUserInfo message.
     */
    QTRMessageTypeGetUserInfo,

    /*!
     The sender is asking the receiver if it wishes to accept a file transfer.
     
     The message must contain a File object (without actual file data) representing
     the file that will be sent.
     */
    QTRMessageTypeConfirmFileTransfer,

    /*!
     The sender rejected the file transfer.
     
     The message must contain a File object (without actual file data) representing
     the file which the sender does not wish to accept.
     */
    QTRMessageTypeRejectFileTransfer,

    /*!
     The sender accepted the file transfer.
     
     The message must contain a File object (without actual file data) representing
     the file which the sender wishes to accept.
     */
    QTRMessageTypeAcceptFileTransfer,

    /*!
     The sender is sending a file.
     
     The message must contain a File object with its data. The file can be a single
     part or a multipart transfer.
     */
    QTRMessageTypeFileTransfer,

    /*!
     The sender is asking the receiver if a file transfer should/can be resumed
     */
    QTRMessageTypeRequestResumeTransfer,

    /*!
     The sender confirmed that the file transer can be resumed
     */
    QTRMessageTypeAcceptResumeTransfer,

    /*!
     The sender rejected the request to resume the file transfer
     */
    QTRMessageTypeRejectResumeTransfer,

    /*!
     The sender paused the file transfer. The message will contian a file object (without data) to identify the transfer.
     */
    QTRMessageTypePauseTransfer

};

/*!
 This class represents the messages that are sent between users
 */
@interface QTRMessage : NSObject <NSCoding>

/*!
 Creates a message with a sender and a file
 @param sender The sender of the message
 @param file The file to be sent
 */
+ (instancetype)messageWithUser:(QTRUser *)sender file:(QTRFile *)file;

/*!
 The user/sender of the receiver
 */
@property (strong) QTRUser *user;

/*!
 The file contained in the receiver
 */
@property (strong) QTRFile *file;

/*!
 The type of the message
 */
@property (nonatomic) QTRMessageType type;

@end
