//
//  QTRBonjourServer.h
//  QuickTransfer
//
//  Created by Harshad on 18/02/14.
//  Copyright (c) 2014 Laughing Buddha Software. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "DTBonjourServer.h"
#import "QTRBonjourServerDelegate.h"
#import "QTRBonjourTransferDelegate.h"

@class QTRFile;
@class QTRTransfersController;
@class QTRTransfer;

/*!
 This class is the server that implements the Bonjour protocol and allows remote clients to connect to it.
 */
@interface QTRBonjourServer : DTBonjourServer

/*!
 Creates a server
 @param fileDelegate An object that confirms to QTRBonjourServerDelegate protocol
 */
- (instancetype)initWithFileDelegate:(id <QTRBonjourServerDelegate>)fileDelegate;

/*!
 Send a file to a user
 @param fileURL The file URL indicating where the file is located at
 @param user The recipient of the file
 */
- (void)sendFileAtURL:(NSURL *)fileURL toUser:(QTRUser *)user;

/*!
 Accept/reject a file transfer.

 @param file The file to accept.
 @param shouldAccept A boolen indicating if the file should be accepted
 */
- (void)acceptFile:(QTRFile *)file accept:(BOOL)shouldAccept fromUser:(QTRUser *)user;

- (BOOL)resumeTransfer:(QTRTransfer *)transfer;

/*!
 The object which is interested in getting notified of connection and file related events
 */
@property (weak) id <QTRBonjourServerDelegate> fileDelegate;

/*!
 The obect which is interested in getting notified about the progres of file transfers
 */
@property (weak) id <QTRBonjourTransferDelegate> transferDelegate;

@end
