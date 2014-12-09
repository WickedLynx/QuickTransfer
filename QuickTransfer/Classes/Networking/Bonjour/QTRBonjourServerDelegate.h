//
//  QTRBonjourServerDelegate.h
//  QuickTransfer
//
//  Created by Harshad on 18/02/14.
//  Copyright (c) 2014 Laughing Buddha Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@class QTRBonjourServer;
@class QTRUser;
@class QTRFile;

/*!
 This protocol contains forwards file and connection related events of the server to interested delegates.
 */
@protocol QTRBonjourServerDelegate <NSObject>

/*!
 @methodgroup Required methods
 */
@required
/*!
 The user who is using this app.
 */
- (QTRUser *)localUser;

/*!
 The server asks its delegate for a file URL to which an incoming large file must be written to.
 @param file The file to be written.
 */
- (NSURL *)saveURLForFile:(QTRFile *)file;

/*!
 The server notifies its file delegate when it detects an incoming file transfer.

 The server will not accept or reject the file till the delegate explicitly asks it to.

 @param file The incoming file
 @param user The sender of the file
 */
- (void)server:(QTRBonjourServer *)server didDetectIncomingFile:(QTRFile *)file fromUser:(QTRUser *)user;

/*!
 The server notifies its delegate when a user rejects a file transfer.

 @param user The user who rejected the file
 @param file The file that was rejected
 */
- (void)user:(QTRUser *)user didRejectFile:(QTRFile *)file;

/*!
 @methodgroup Optional methods
 */
@optional

/*!
 The server calls this method whenever it connects to a new user.
 @param server The Bonjour server.
 @param user The user which was connected.
 */
- (void)server:(QTRBonjourServer *)server didConnectToUser:(QTRUser *)user;

/*!
 The server calls this method whenever it disconnects a previously connected user.
 @param server The Bonjour server.
 @param user The user which was disconnected.
 */
- (void)server:(QTRBonjourServer *)server didDisconnectUser:(QTRUser *)user;

/*!
 The server calls this method after it receives a file from a user.
 @param server The Bonjour server.
 @param file The file that was received.
 @param The user who sent the file.
 */
- (void)server:(QTRBonjourServer *)server didReceiveFile:(QTRFile *)file fromUser:(QTRUser *)user;

/*!
 The server calls this method when it has finished writing all parts of a multipart file transfer.
 @param server The Bonjour server.
 @param url The file URL where the file was saved.
 @param user The user who sent the file.
 */
- (void)server:(QTRBonjourServer *)server didSaveReceivedFileAtURL:(NSURL *)url fromUser:(QTRUser *)user;

/*!
 The server sends this message when it starts a file transfer to a user.
 
 @param server The server that started sending the file
 @param file The file that is being sent
 @param user The recipient of the file
 */
- (void)server:(QTRBonjourServer *)server didBeginSendingFile:(QTRFile *)file toUser:(QTRUser *)user;

/*!
 * Called when the server receives a text message from a user
 */
- (void)server:(QTRBonjourServer *)server didReiveTextMessage:(NSString *)messageText fromUser:(QTRUser *)user;


@end
