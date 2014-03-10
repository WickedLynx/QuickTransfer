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


@end
