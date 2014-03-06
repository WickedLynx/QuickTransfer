//
//  QTRConstants.h
//  QuickTransfer
//
//  Created by Harshad on 18/02/14.
//  Copyright (c) 2014 Laughing Buddha Software. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 The Bonjour service type of the application
 */
FOUNDATION_EXPORT NSString *const QTRBonjourServiceType;

/*!
 The key in the TXT record dictionary representing the user identifier of the server
 */
FOUNDATION_EXPORT NSString *const QTRBonjourTXTRecordIdentifierKey;

/*!
 The key in the TXT record dictioary representing the display name of the user
 */
FOUNDATION_EXPORT NSString *const QTRBonjourTXTRecordNameKey;

/*!
 The key in the TXT record dictionary representing the platform of the user
 */
FOUNDATION_EXPORT NSString *const QTRBonjourTXTRecordPlatformKey;
