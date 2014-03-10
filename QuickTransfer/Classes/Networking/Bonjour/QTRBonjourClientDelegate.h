//
//  QTRBonjourClientDelegate.h
//  QuickTransfer
//
//  Created by Harshad on 18/02/14.
//  Copyright (c) 2014 Laughing Buddha Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@class QTRBonjourClient;
@class QTRUser;
@class QTRFile;

/*!
 This protocol defines methods for file and connection related events of a Bonjour client.
 */
@protocol QTRBonjourClientDelegate <NSObject>

/*!
 @methodgroup Required methods
 */
@required

/*!
 The user who is currently usng the application.
 */
- (QTRUser *)localUser;

/*!
 When a client discovers a Bonjour server, it asks its delegate if it should connect to it.
 
 The Bonjour client will always avoid connecting to a server instance belonging to the local user.

 @param client The Bonjour client.
 @param user The user who is running the server instance.
 */
- (BOOL)client:(QTRBonjourClient *)client shouldConnectToUser:(QTRUser *)user;

/*!
 The client asks its delegate for a file URL where a multipart file transfer must be written to
 
 @param file The file that is to be saved
 */
- (NSURL *)saveURLForFile:(QTRFile *)file;

/*!
 The client notifies its delegate when it detects an incoming file transfer.
 
 The client will not accept or reject the file till the delegate explicitly asks it to.
 
 @param file The incoming file
 @param user The sender of the file
 */
- (void)client:(QTRBonjourClient *)client didDetectIncomingFile:(QTRFile *)file fromUser:(QTRUser *)user;

/*!
 The client notifies its delegate when a user rejects a file transfer.
 
 @param user The user who rejected the file
 @param file The file that was rejected
 */
- (void)user:(QTRUser *)user didRejectFile:(QTRFile *)file;

@optional

- (void)client:(QTRBonjourClient *)client didConnectToServerForUser:(QTRUser *)user;
- (void)client:(QTRBonjourClient *)client didDisconnectFromServerForUser:(QTRUser *)user;
- (void)client:(QTRBonjourClient *)client didReceiveFile:(QTRFile *)file fromUser:(QTRUser *)user;
- (void)client:(QTRBonjourClient *)client didSaveReceivedFileAtURL:(NSURL *)url fromUser:(QTRUser *)user;

/*!
 The client sends this message when it starts a file transfer to a user.

 @param server The client that started sending the file
 @param file The file that is being sent
 @param user The recipient of the file
 */
- (void)client:(QTRBonjourClient *)client didBeginSendingFile:(QTRFile *)file toUser:(QTRUser *)user;

@end
