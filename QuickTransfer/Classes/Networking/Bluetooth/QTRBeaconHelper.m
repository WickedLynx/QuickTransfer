//
//  QTRBeaconAdvertiser.m
//  QuickTransfer
//
//  Created by Harshad on 18/03/14.
//  Copyright (c) 2014 Laughing Buddha Software. All rights reserved.
//

/*
 * This cluster has iBeacon implementations for both iOS and OS X
 * CLBeaconRegion and the corresponding CoreLocation APIs are not
 * available on OS X.
 * 
 * CLBeaconRanger isn't compiled for OS X
 */

#import <CoreLocation/CoreLocation.h>
#import "QTRBeaconHelper.h"
#import "QTRConstants.h"

#if TARGET_OS_IPHONE
#import <CoreBluetooth/CoreBluetooth.h>

#elif TARGET_OS_MAC
#import <IOBluetooth/IOBluetooth.h>

#endif

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

    BOOL _shouldAdvertisePrimaryBeacon;
    BOOL _shouldAdvertiseSecondaryBeacon;

    dispatch_queue_t _peripheralManagerQueue;

    NSDictionary *_primaryBeaconDictionary;
    NSDictionary *_secondaryBeaconDictionary;

    CBPeripheralManager *_primaryPeripheralManager;
    CBPeripheralManager *_secondaryPeripheralManager;
}

@end

@implementation QTRBeaconAdvertiser

#pragma mark - Initialisation

- (id)init {
    self = [super init];
    if (self != nil) {

        _peripheralManagerQueue = dispatch_queue_create("com.leftshift.QuickTransfer.beaconAdvertiser.peripheralQueue", DISPATCH_QUEUE_SERIAL);

        _primaryPeripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:_peripheralManagerQueue];
        _secondaryPeripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:_peripheralManagerQueue];

    }

    return self;
}

#pragma mark - Public methods

- (void)startAdvertisingPrimaryBeaconRegion {

    if (_primaryBeaconDictionary == nil) {
        _primaryBeaconDictionary = [self beaconDictionaryWithProximityUUIDString:QTRPrimaryBeaconRegionProximityUUID identifier:QTRBeaconRegionIdentifier];
    }

    _shouldAdvertisePrimaryBeacon = YES;

    [self advertiseBeacons];
}

- (void)startAdvertisingSecondaryBeaconRegion {

    if (_secondaryBeaconDictionary == nil) {
        _secondaryBeaconDictionary = [self beaconDictionaryWithProximityUUIDString:QTRSecondaryBeaconRegionProximityUUID identifier:QTRBeaconRegionIdentifier];
    }

    _shouldAdvertiseSecondaryBeacon = YES;

    [self advertiseBeacons];
}

- (void)stopAdvertisingPrimaryBeaconRegion {
    _shouldAdvertisePrimaryBeacon = NO;
    if ([_primaryPeripheralManager isAdvertising]) {
        [_primaryPeripheralManager stopAdvertising];
        NSLog(@"Stopped advertising primary beacon");
    }
}

- (void)stopAdvertisingSecondaryBeaconRegion {
    _shouldAdvertiseSecondaryBeacon = NO;
    if ([_secondaryPeripheralManager isAdvertising]) {
        [_secondaryPeripheralManager stopAdvertising];
        NSLog(@"Stopped advertising secondary beacon");
    }
}


- (void)stopAdvertisingBeaconRegions {
    _shouldAdvertiseSecondaryBeacon = NO;
    _shouldAdvertiseSecondaryBeacon = NO;

    [_primaryPeripheralManager stopAdvertising];
    [_secondaryPeripheralManager stopAdvertising];

    NSLog(@"Stopped advertising all beacons");
}

#pragma mark - Private methods

- (void)advertiseBeacons {
    if (_shouldAdvertisePrimaryBeacon && _primaryPeripheralManager.state == CBPeripheralManagerStatePoweredOn && ![_primaryPeripheralManager isAdvertising]) {
        [_primaryPeripheralManager startAdvertising:_primaryBeaconDictionary];
        NSLog(@"Started advertising primary beacon");
    }

    if (_shouldAdvertiseSecondaryBeacon && _secondaryPeripheralManager.state == CBPeripheralManagerStatePoweredOn && ![_secondaryPeripheralManager isAdvertising]) {
        [_secondaryPeripheralManager startAdvertising:_secondaryBeaconDictionary];
        NSLog(@"Started advertising secondary beacon");
    }
}

- (NSDictionary *)beaconDictionaryWithProximityUUIDString:(NSString *)proximityUUIDString identifier:(NSString *)identifier {

    NSDictionary *beaconDictionary = nil;
    NSUUID *proximityUUID = [[NSUUID alloc] initWithUUIDString:QTRPrimaryBeaconRegionProximityUUID];

#if TARGET_OS_IPHONE
    CLBeaconRegion *beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:proximityUUID identifier:QTRBeaconRegionIdentifier];
    beaconDictionary = [beaconRegion peripheralDataWithMeasuredPower:nil];

#elif TARGET_OS_MAC
    NSString *beaconKey = @"kCBAdvDataAppleBeaconKey";

    unsigned char advertisementBytes[21] = {0};
    [proximityUUID getUUIDBytes:(unsigned char *)&advertisementBytes];

    advertisementBytes[16] = (unsigned char)(0);
    advertisementBytes[17] = (unsigned char)(0);
    advertisementBytes[18] = (unsigned char)(0);
    advertisementBytes[19] = (unsigned char)(0);
    advertisementBytes[20] = 1;

    NSMutableData *advertisement = [NSMutableData dataWithBytes:advertisementBytes length:21];

    beaconDictionary = @{beaconKey : advertisement};

#endif

    return beaconDictionary;
}

#pragma mark - CBPeripheralManagerDelegate methods

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral {

    if (peripheral.state == CBPeripheralManagerStatePoweredOn) {
        [self advertiseBeacons];
    }
}

@end

#if TARGET_OS_IPHONE

@interface QTRBeaconRanger () <CLLocationManagerDelegate> {
    CLBeaconRegion *_primaryBeaconRegion;
    CLBeaconRegion *_secondaryBeaconRegion;
    CLLocationManager *_locationManager;
}

@end

@implementation QTRBeaconRanger

#pragma mark - Public methods

- (void)startMonitoringPrimaryAndSecondaryBeacons {

    if (_locationManager == nil) {
        _locationManager = [[CLLocationManager alloc] init];
        [_locationManager setDelegate:self];
    }
    
    _primaryBeaconRegion = [self beaconRegionWithProximityUUIDString:QTRPrimaryBeaconRegionProximityUUID identifier:QTRBeaconRegionIdentifier];
    [_locationManager startMonitoringForRegion:_primaryBeaconRegion];

    _secondaryBeaconRegion = [self beaconRegionWithProximityUUIDString:QTRSecondaryBeaconRegionProximityUUID identifier:QTRBeaconRegionIdentifier];
    [_locationManager startMonitoringForRegion:_secondaryBeaconRegion];
}

- (void)stopMonitoringBeaconRegions {
    [_locationManager stopMonitoringForRegion:_primaryBeaconRegion];
}

#pragma mark - Private methods

- (CLBeaconRegion *)beaconRegionWithProximityUUIDString:(NSString *)proximityUUIDString identifier:(NSString *)identifier {
    CLBeaconRegion *beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:[[NSUUID alloc] initWithUUIDString:proximityUUIDString] identifier:identifier];
    [beaconRegion setNotifyEntryStateOnDisplay:YES];
    [beaconRegion setNotifyOnEntry:YES];
    [beaconRegion setNotifyOnExit:YES];

    return beaconRegion;
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
