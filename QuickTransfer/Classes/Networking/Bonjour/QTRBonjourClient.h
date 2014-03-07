//
//  QTRBonjourClient.h
//  QuickTransfer
//
//  Created by Harshad on 18/02/14.
//  Copyright (c) 2014 Laughing Buddha Software. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "QTRBonjourClientDelegate.h"
#import "QTRBonjourTransferDelegate.h"

/*!
 The Bonjour client is responsible for browsing and connecting to Bonjour servers and exchanging files with them
 */
@interface QTRBonjourClient : NSObject

/*!
 Creates a bonjour client.
 @param delegate An object interesting in getting notified about cnnection and file transfer related events
 */
- (instancetype)initWithDelegate:(id <QTRBonjourClientDelegate>)delegate;

/*!
 Start browsing for servers
 */
- (void)start;

/*!
 Stop browsing for servers and disconnect from existing servers
 */
- (void)stop;

/*!
 Send a file to a user.
 
 The receiver processes and send the file asynchronously.

 @param fileURL The file URL where the file is located
 @param user The user to whom the file must be sent
 */
- (void)sendFileAtURL:(NSURL *)fileURL toUser:(QTRUser *)user;

/*!
 The delegate of the receiver to  whom connection and file related events are sent
 */
@property (weak) id <QTRBonjourClientDelegate> delegate;

/*!
 An object interested in knowing about the progress of a file transfer
 */
@property (weak) id <QTRBonjourTransferDelegate> transferDelegate;


@end
