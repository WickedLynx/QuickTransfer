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

/*!
 The proximity UUID for the primary iBeacon region.
 
 The Mac application always advertises the primary beacon.
 The iOS application only advertises the primary beacon when it is active.
 */
FOUNDATION_EXPORT NSString *const QTRPrimaryBeaconRegionProximityUUID;

/*!
 The proximity UUID for the secondary iBeacon region.
 
 The secondary beacon is advertised only for a specific duration when 
 the connections are refreshed. Its main purpose is to simulate a 
 beacon region entry.
 */
FOUNDATION_EXPORT NSString *const QTRSecondaryBeaconRegionProximityUUID;

/*!
 The identifier for the beacon region created by the Mac app
 */
FOUNDATION_EXPORT NSString *const QTRBeaconRegionIdentifier;
