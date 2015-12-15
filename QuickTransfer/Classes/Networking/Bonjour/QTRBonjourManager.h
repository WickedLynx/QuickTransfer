//
//  QTRBonjourManager.h
//  QuickTransfer
//
//  Created by Harshad on 14/12/15.
//  Copyright © 2015 Laughing Buddha Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QTRBonjourManagerDelegate.h"
#import "QTRBonjourTransferDelegate.h"

@interface QTRBonjourManager : NSObject

- (NSError *)startServices;
- (void)stopServices;
- (void)refresh:(void (^)(void))completion;
- (NSArray *)remoteUsers;

- (void)accept:(BOOL)shouldAccept file:(QTRFile *)file fromUser:(QTRUser *)remoteUser context:(id)context;
- (void)sendFileAtURL:(NSURL *)fileURL toUser:(QTRUser *)user;
- (QTRUser *)userAtIndex:(NSInteger)index;

- (BOOL)resumeTransfer:(QTRTransfer *)transfer;

@property (weak, nonatomic) id <QTRBonjourManagerDelegate> delegate;
@property (weak, nonatomic) id <QTRBonjourTransferDelegate> transfersDelegate;
@property (nonatomic) BOOL shouldAutoAcceptFiles;

@end
