//
//  QTRSelectedUserInfo.h
//  QuickTransfer
//
//  Created by Tarun Yadav on 03/12/15.
//  Copyright © 2015 Laughing Buddha Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QTRBonjourClient.h"
#import "QTRBonjourServer.h"

@interface QTRSelectedUserInfo : NSObject


@property(nonatomic,retain) QTRBonjourClient *_client;
@property(nonatomic,retain) QTRBonjourServer *_server;

@property(nonatomic,retain) NSMutableArray *_connectedServers;
@property(nonatomic,retain) NSMutableArray *_connectedClients;
@property(nonatomic,retain) NSMutableDictionary *_selectedRecivers;

@property(nonatomic,retain) QTRUser *_localUser;
@property(nonatomic,retain) QTRUser *_selectedUser;

@end
