//
//  QTRBeaconAdvertiser.m
//  QuickTransfer
//
//  Created by Harshad on 18/03/14.
//  Copyright (c) 2014 Laughing Buddha Software. All rights reserved.
//

#import "QTRBeaconHelper.h"

/*!
 Set this to 1 to compile QTRBeaconHelper and QTRBeaconRanger for OS X targets.
 This requires the Mac to have CoreBluetooth.framework installed.
 
 For iOS targets, QTRBeaconHelper and QTRBeaconRanger are always compiled.
 */
#define QTRCompileBeacons   0

@implementation QTRBeaconHelper

+ (BOOL)isBLEAvailable {
    BOOL isAvailable = NO;

    Class CBPeripheralClass = NSClassFromString(@"CBPeripheral");
    if (CBPeripheralClass != nil) {
        isAvailable = YES;
    }

    return isAvailable;
}

@end

#if (QTRCompileBeacons || TARGET_OS_IPHONE)

#import <CoreBluetooth/CoreBluetooth.h>
#import <CoreLocation/CoreLocation.h>

@interface QTRBeaconAdvertiser () <CBPeripheralManagerDelegate> {
    BOOL _bluetoothConnected;
    BOOL _isAdvertising;
    dispatch_queue_t _peripheralManagerQueue;
    CLBeaconRegion *_beaconRegion;
    CBPeripheralManager *_peripheralManager;
}

@end

@implementation QTRBeaconAdvertiser

#pragma mark - Initialisation

- (id)init {
    self = [super init];
    if (self != nil) {

        _peripheralManagerQueue = dispatch_queue_create("com.leftshift.QuickTransfer.beaconAdvertiser.peripheralQueue", DISPATCH_QUEUE_SERIAL);

        _peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:_peripheralManagerQueue];
    }

    return self;
}

#pragma mark - Public methods

- (void)startAdvertisingRegionWithProximityUUID:(NSString *)proximityUUID identifier:(NSString *)identifier majorValue:(uint16_t )majorValue minorValue:(uint16_t)minorValue {

    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:proximityUUID];
    _beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:uuid major:majorValue minor:minorValue identifier:identifier];

    [self advertiseBeacon];
}

- (void)stopAdvertisingBeaconRegion {
    if (_isAdvertising) {
        [_peripheralManager stopAdvertising];
    }
}

#pragma mark - Private methods

- (void)advertiseBeacon {
    if (!_isAdvertising && _bluetoothConnected && _beaconRegion != nil) {
        NSDictionary *beaconData = [_beaconRegion peripheralDataWithMeasuredPower:nil];
        [_peripheralManager startAdvertising:beaconData];
        _isAdvertising = YES;
    }
}

#pragma mark - CBPeripheralManagerDelegate methods

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral {
    if (peripheral.state == CBPeripheralManagerStatePoweredOn) {
        _bluetoothConnected = YES;
        [self advertiseBeacon];
    } else {
        _bluetoothConnected = NO;
    }
}

@end

@interface QTRBeaconRanger () <CLLocationManagerDelegate> {
    CLBeaconRegion *_beaconRegion;
    CLLocationManager *_locationManager;
}

@end

@implementation QTRBeaconRanger

#pragma mark - Public methods

- (void)startRangingBeaconsWithProximityUUID:(NSString *)proximityUUID identifier:(NSString *)identifier majorValue:(uint16_t)majorValue minorValue:(uint16_t)minorValue {

    if (_locationManager == nil) {
        _locationManager = [[CLLocationManager alloc] init];
        [_locationManager setDelegate:self];
    }

    _beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:[[NSUUID alloc] initWithUUIDString:proximityUUID] major:majorValue minor:minorValue identifier:identifier];
    [_locationManager startMonitoringForRegion:_beaconRegion];

}

- (void)stopRangingBeacons {
    [_locationManager stopMonitoringForRegion:_beaconRegion];
}

#pragma mark - CLLocationManagerDelegate methods

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {
    if ([self.delegate respondsToSelector:@selector(beaconRangerDidEnterRegion:)]) {
        [self.delegate beaconRangerDidEnterRegion:self];
    }
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
    if ([self.delegate respondsToSelector:@selector(beaconRangerDidExitRegion:)]) {
        [self.delegate beaconRangerDidExitRegion:self];
    }
}

@end

#else

@implementation QTRBeaconAdvertiser

- (void)startAdvertisingRegionWithProximityUUID:(NSString *)proximityUUID identifier:(NSString *)identifier majorValue:(uint16_t)majorValue minorValue:(uint16_t)minorValue {
    NSLog(@"%s\nWarning: %@ is compiled as a dummy class. Instances of %@ are not functional.\nTo fix this, recompile setting QTRCompileBeacons=1 and link with the CoreBluetooth framework.", __PRETTY_FUNCTION__, NSStringFromClass([self class]), NSStringFromClass([self class]));
}

- (void)stopAdvertisingBeaconRegion {
    NSLog(@"%s\nWarning: %@ is compiled as a dummy class. Instances of %@ are not functional.\nTo fix this, recompile setting QTRCompileBeacons=1 and link with the CoreBluetooth framework.", __PRETTY_FUNCTION__, NSStringFromClass([self class]), NSStringFromClass([self class]));
}

@end

@implementation QTRBeaconRanger

- (void)startRangingBeaconsWithProximityUUID:(NSString *)proximityUUID identifier:(NSString *)identifier majorValue:(uint16_t)majorValue minorValue:(uint16_t)minorValue {
    NSLog(@"%s\nWarning: %@ is compiled as a dummy class. Instances of %@ are not functional.\nTo fix this, recompile setting QTRCompileBeacons=1 and link with the CoreBluetooth framework.", __PRETTY_FUNCTION__, NSStringFromClass([self class]), NSStringFromClass([self class]));
}

- (void)stopRangingBeacons {
    NSLog(@"%s\nWarning: %@ is compiled as a dummy class. Instances of %@ are not functional.\nTo fix this, recompile setting QTRCompileBeacons=1 and link with the CoreBluetooth framework.", __PRETTY_FUNCTION__, NSStringFromClass([self class]), NSStringFromClass([self class]));
}


@end

#endif