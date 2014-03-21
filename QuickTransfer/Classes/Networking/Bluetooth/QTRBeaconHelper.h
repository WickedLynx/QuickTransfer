//
//  QTRBeaconAdvertiser.h
//  QuickTransfer
//
//  Created by Harshad on 18/03/14.
//  Copyright (c) 2014 Laughing Buddha Software. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 This class has helper methods for BLE beacons
 */
@interface QTRBeaconHelper : NSObject

/*!
 This method is used to check if the device hardware allows creating and monitoring beacon regions.
 */
+ (BOOL)isBLEAvailable;

@end

/*!
 This class is used to advertise beacon regions.
 
 Only one beacon region can be advertised by one instance of this class.
 */
@interface QTRBeaconAdvertiser : NSObject

/*!
 Starts advertising the primary beacon region
 */
- (void)startAdvertisingPrimaryBeaconRegion;

/*!
 Starts advertising the secondary beacon region
 */
- (void)startAdvertisingSecondaryBeaconRegion;

/*!
 Stops advertising the primary beacon region
 */
- (void)stopAdvertisingPrimaryBeaconRegion;

/*!
 Stops advertising the secondary beacon region
 */
- (void)stopAdvertisingSecondaryBeaconRegion;

/*!
 Stops advertising all beacon regions.
 */
- (void)stopAdvertisingBeaconRegions;


@end

/*
 * iBeacon ranging is not supported on OS X
 */
#if TARGET_OS_IPHONE

@class QTRBeaconRanger;

/*!
 This protocol defines methods that notify interested delegates about beacon region enter/exit events.
 */
@protocol QTRBeaconRangerDelegate <NSObject>

@optional

/*!
 The beacon ranger calls this method when it enters the beacon region it is monitoring.
 
 @param beaconRanger The beacon ranger that entered the region.
 */
- (void)beaconRangerDidEnterRegion:(QTRBeaconRanger *)beaconRanger;

/*!
 The beacon ranger call this method when it ranges beacons in the region
 */
- (void)beaconRangerDidRangeBeacons:(QTRBeaconRanger *)beaconRanger;

/*!
 The beacon ranger calls this method when it exists the beacon region it is monotoring.
 
 @param beaconRanger The beacon ranger that exit the region.
 */
- (void)beaconRangerDidExitRegion:(QTRBeaconRanger *)beaconRanger;

@end

/*!
 This class ranges and monitors bluetooth beacon regions
 */
@interface QTRBeaconRanger : NSObject

/*!
 Starts monitoring the primary and secondary beacon regions
 */
- (void)startMonitoringPrimaryAndSecondaryBeacons;

/*!
 Stops monitoring the beacon region.
 */
- (void)stopMonitoringBeaconRegions;

/*!
 The delegate of the receiver.
 */
@property (weak) id <QTRBeaconRangerDelegate> delegate;

@end

#endif