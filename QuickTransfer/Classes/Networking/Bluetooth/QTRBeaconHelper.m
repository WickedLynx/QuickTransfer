//
//  QTRBeaconAdvertiser.m
//  QuickTransfer
//
//  Created by Harshad on 18/03/14.
//  Copyright (c) 2014 Laughing Buddha Software. All rights reserved.
//

#import "QTRBeaconHelper.h"

#if TARGET_OS_IPHONE
#import <CoreBluetooth/CoreBluetooth.h>

#elif TARGET_OS_MAC
#import <IOBluetooth/IOBluetooth.h>

#endif

#import <CoreLocation/CoreLocation.h>

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

@interface QTRBeaconAdvertiser () <CBPeripheralManagerDelegate> {
    BOOL _bluetoothConnected;
    BOOL _isAdvertising;
    dispatch_queue_t _peripheralManagerQueue;
#if TARGET_OS_IPHONE
    CLBeaconRegion *_beaconRegion;
#elif TARGET_OS_MAC
    NSDictionary *_beaconDictionary;
#endif
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

#if TARGET_OS_IPHONE

    _beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:uuid major:majorValue minor:minorValue identifier:identifier];

#elif TARGET_OS_MAC
    NSString *beaconKey = @"kCBAdvDataAppleBeaconKey";

    unsigned char advertisementBytes[21] = {0};

    [uuid getUUIDBytes:(unsigned char *)&advertisementBytes];

    advertisementBytes[16] = (unsigned char)(majorValue >> 8);
    advertisementBytes[17] = (unsigned char)(majorValue & 255);

    advertisementBytes[18] = (unsigned char)(minorValue >> 8);
    advertisementBytes[19] = (unsigned char)(minorValue & 255);

    advertisementBytes[20] = 1;

    NSMutableData *advertisement = [NSMutableData dataWithBytes:advertisementBytes length:21];

    _beaconDictionary = @{beaconKey : advertisement};

#endif

    [self advertiseBeacon];
}

- (void)stopAdvertisingBeaconRegion {
    if (_isAdvertising) {
        [_peripheralManager stopAdvertising];
    }
}

#pragma mark - Private methods

- (void)advertiseBeacon {
    if (!_isAdvertising && _bluetoothConnected) {

#if TARGET_OS_IPHONE

        if (_beaconRegion != nil) {
            NSDictionary *beaconData = [_beaconRegion peripheralDataWithMeasuredPower:nil];
            [_peripheralManager startAdvertising:beaconData];
        }

#elif TARGET_OS_MAC

        if (_beaconDictionary != Nil) {
            [_peripheralManager startAdvertising:_beaconDictionary];
        }

#endif

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

#if TARGET_OS_IPHONE

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

    _beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:[[NSUUID alloc] initWithUUIDString:proximityUUID] identifier:identifier];
    [_beaconRegion setNotifyOnEntry:YES];
    [_beaconRegion setNotifyOnExit:YES];
    [_beaconRegion setNotifyEntryStateOnDisplay:YES];
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

- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region {
    if ([region isKindOfClass:[CLBeaconRegion class]]) {
        switch (state) {
            case CLRegionStateInside:

            case CLRegionStateUnknown:
                if ([self.delegate respondsToSelector:@selector(beaconRangerDidEnterRegion:)]) {
                    [self.delegate beaconRangerDidEnterRegion:self];
                }
                break;

            default:
                break;
        }
    }

}


@end

#endif
