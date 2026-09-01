#ifndef OPEN_CORELOCATION_H
#define OPEN_CORELOCATION_H

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef double CLLocationDegrees;
typedef double CLLocationDistance;
typedef double CLLocationAccuracy;
typedef double CLLocationSpeed;
typedef double CLLocationDirection;
typedef double CLTimeInterval;
typedef uint16_t CLBeaconMajorValue;
typedef uint16_t CLBeaconMinorValue;

typedef struct CLLocationCoordinate2D {
    CLLocationDegrees latitude;
    CLLocationDegrees longitude;
} CLLocationCoordinate2D;

FOUNDATION_EXPORT const CLLocationDistance CLLocationDistanceMax;
FOUNDATION_EXPORT const CLLocationDistance kCLDistanceFilterNone;
FOUNDATION_EXPORT const CLLocationAccuracy kCLLocationAccuracyBestForNavigation;
FOUNDATION_EXPORT const CLLocationAccuracy kCLLocationAccuracyBest;
FOUNDATION_EXPORT const CLLocationAccuracy kCLLocationAccuracyNearestTenMeters;
FOUNDATION_EXPORT const CLLocationAccuracy kCLLocationAccuracyHundredMeters;
FOUNDATION_EXPORT const CLLocationAccuracy kCLLocationAccuracyKilometer;
FOUNDATION_EXPORT const CLLocationAccuracy kCLLocationAccuracyThreeKilometers;
FOUNDATION_EXPORT const CLLocationAccuracy kCLLocationAccuracyReduced;
FOUNDATION_EXPORT const CLLocationCoordinate2D kCLLocationCoordinate2DInvalid;
FOUNDATION_EXPORT NSErrorDomain const kCLErrorDomain;

FOUNDATION_EXPORT CLLocationCoordinate2D CLLocationCoordinate2DMake(
    CLLocationDegrees latitude,
    CLLocationDegrees longitude
);
FOUNDATION_EXPORT BOOL CLLocationCoordinate2DIsValid(
    CLLocationCoordinate2D coordinate
);

typedef NS_ENUM(NSInteger, CLAuthorizationStatus) {
    kCLAuthorizationStatusNotDetermined = 0,
    kCLAuthorizationStatusRestricted = 1,
    kCLAuthorizationStatusDenied = 2,
    kCLAuthorizationStatusAuthorizedAlways = 3,
    kCLAuthorizationStatusAuthorizedWhenInUse = 4,
};

typedef NS_ENUM(NSInteger, CLAccuracyAuthorization) {
    CLAccuracyAuthorizationFullAccuracy = 0,
    CLAccuracyAuthorizationReducedAccuracy = 1,
};

typedef NS_ENUM(NSInteger, CLActivityType) {
    CLActivityTypeOther = 1,
    CLActivityTypeAutomotiveNavigation = 2,
    CLActivityTypeFitness = 3,
    CLActivityTypeOtherNavigation = 4,
    CLActivityTypeAirborne = 5,
};

typedef NS_ENUM(NSInteger, CLDeviceOrientation) {
    CLDeviceOrientationUnknown = 0,
    CLDeviceOrientationPortrait = 1,
    CLDeviceOrientationPortraitUpsideDown = 2,
    CLDeviceOrientationLandscapeLeft = 3,
    CLDeviceOrientationLandscapeRight = 4,
    CLDeviceOrientationFaceUp = 5,
    CLDeviceOrientationFaceDown = 6,
};

typedef NS_ENUM(NSInteger, CLRegionState) {
    CLRegionStateUnknown = 0,
    CLRegionStateInside = 1,
    CLRegionStateOutside = 2,
};

typedef NS_ENUM(NSInteger, CLProximity) {
    CLProximityUnknown = 0,
    CLProximityImmediate = 1,
    CLProximityNear = 2,
    CLProximityFar = 3,
};

@class CLFloor;
@class CLLocation;
@class CLHeading;
@class CLRegion;
@class CLCircularRegion;
@class CLBeaconIdentityConstraint;
@class CLBeaconRegion;
@class CLBeacon;
@class CLVisit;
@class CLPlacemark;
@class CLLocationManager;
@class CLGeocoder;

@interface CLFloor : NSObject <NSCopying>
@property(nonatomic, readonly) NSInteger level;
@end

@interface CLLocation : NSObject <NSCopying>
@property(nonatomic, readonly) CLLocationCoordinate2D coordinate;
@property(nonatomic, readonly) CLLocationDistance altitude;
@property(nonatomic, readonly) CLLocationAccuracy horizontalAccuracy;
@property(nonatomic, readonly) CLLocationAccuracy verticalAccuracy;
@property(nonatomic, readonly) CLLocationDirection course;
@property(nonatomic, readonly) CLLocationDirection courseAccuracy;
@property(nonatomic, readonly) CLLocationSpeed speed;
@property(nonatomic, readonly) CLLocationSpeed speedAccuracy;
@property(nonatomic, readonly, copy) NSDate *timestamp;
@property(nonatomic, readonly, nullable, copy) CLFloor *floor;
- (instancetype)initWithLatitude:(CLLocationDegrees)latitude
                       longitude:(CLLocationDegrees)longitude;
- (CLLocationDistance)distanceFromLocation:(CLLocation *)location;
@end

@interface CLHeading : NSObject <NSCopying>
@property(nonatomic, readonly) CLLocationDirection magneticHeading;
@property(nonatomic, readonly) CLLocationDirection trueHeading;
@property(nonatomic, readonly) CLLocationDirection headingAccuracy;
@property(nonatomic, readonly) double x;
@property(nonatomic, readonly) double y;
@property(nonatomic, readonly) double z;
@property(nonatomic, readonly, copy) NSDate *timestamp;
@end

@interface CLRegion : NSObject <NSCopying>
@property(nonatomic, readonly, copy) NSString *identifier;
@property(nonatomic) BOOL notifyOnEntry;
@property(nonatomic) BOOL notifyOnExit;
- (BOOL)containsCoordinate:(CLLocationCoordinate2D)coordinate;
@end

@interface CLCircularRegion : CLRegion
@property(nonatomic, readonly) CLLocationCoordinate2D center;
@property(nonatomic, readonly) CLLocationDistance radius;
- (instancetype)initWithCenter:(CLLocationCoordinate2D)center
                         radius:(CLLocationDistance)radius
                     identifier:(NSString *)identifier;
@end

@interface CLBeaconIdentityConstraint : NSObject <NSCopying>
@property(nonatomic, readonly, copy) NSUUID *UUID;
@property(nonatomic, readonly, nullable, copy) NSNumber *major;
@property(nonatomic, readonly, nullable, copy) NSNumber *minor;
- (instancetype)initWithUUID:(NSUUID *)UUID;
- (instancetype)initWithUUID:(NSUUID *)UUID major:(CLBeaconMajorValue)major;
- (instancetype)initWithUUID:(NSUUID *)UUID
                       major:(CLBeaconMajorValue)major
                       minor:(CLBeaconMinorValue)minor;
@end

@interface CLBeaconRegion : CLRegion
@property(nonatomic, readonly, copy) NSUUID *UUID;
@property(nonatomic, readonly, nullable, copy) NSNumber *major;
@property(nonatomic, readonly, nullable, copy) NSNumber *minor;
@property(nonatomic) BOOL notifyEntryStateOnDisplay;
@end

@interface CLBeacon : NSObject
@property(nonatomic, readonly, copy) NSUUID *UUID;
@property(nonatomic, readonly, copy) NSNumber *major;
@property(nonatomic, readonly, copy) NSNumber *minor;
@property(nonatomic, readonly) CLProximity proximity;
@property(nonatomic, readonly) CLLocationAccuracy accuracy;
@property(nonatomic, readonly) NSInteger rssi;
@property(nonatomic, readonly, copy) NSDate *timestamp;
@end

@interface CLVisit : NSObject
@property(nonatomic, readonly) CLLocationCoordinate2D coordinate;
@property(nonatomic, readonly) CLLocationAccuracy horizontalAccuracy;
@property(nonatomic, readonly, copy) NSDate *arrivalDate;
@property(nonatomic, readonly, copy) NSDate *departureDate;
@end

@interface CLPlacemark : NSObject <NSCopying>
@property(nonatomic, readonly, nullable, copy) CLLocation *location;
@property(nonatomic, readonly, nullable, copy) CLRegion *region;
@property(nonatomic, readonly, nullable, copy) NSTimeZone *timeZone;
@property(nonatomic, readonly, nullable, copy) NSString *name;
@property(nonatomic, readonly, nullable, copy) NSString *thoroughfare;
@property(nonatomic, readonly, nullable, copy) NSString *subThoroughfare;
@property(nonatomic, readonly, nullable, copy) NSString *locality;
@property(nonatomic, readonly, nullable, copy) NSString *subLocality;
@property(nonatomic, readonly, nullable, copy) NSString *administrativeArea;
@property(nonatomic, readonly, nullable, copy) NSString *subAdministrativeArea;
@property(nonatomic, readonly, nullable, copy) NSString *postalCode;
@property(nonatomic, readonly, nullable, copy) NSString *ISOcountryCode;
@property(nonatomic, readonly, nullable, copy) NSString *country;
@property(nonatomic, readonly, nullable, copy) NSString *inlandWater;
@property(nonatomic, readonly, nullable, copy) NSString *ocean;
@property(nonatomic, readonly, nullable, copy) NSArray<NSString *> *areasOfInterest;
@end

@protocol CLLocationManagerDelegate <NSObject>
@optional
- (void)locationManager:(CLLocationManager *)manager
      didUpdateLocations:(NSArray<CLLocation *> *)locations;
- (void)locationManager:(CLLocationManager *)manager
        didUpdateHeading:(CLHeading *)newHeading;
- (void)locationManager:(CLLocationManager *)manager
        didFailWithError:(NSError *)error;
- (void)locationManagerDidChangeAuthorization:(CLLocationManager *)manager;
- (void)locationManager:(CLLocationManager *)manager
    didChangeAuthorizationStatus:(CLAuthorizationStatus)status;
- (void)locationManager:(CLLocationManager *)manager
          didEnterRegion:(CLRegion *)region;
- (void)locationManager:(CLLocationManager *)manager
           didExitRegion:(CLRegion *)region;
- (void)locationManager:(CLLocationManager *)manager
       didDetermineState:(CLRegionState)state
               forRegion:(CLRegion *)region;
@end

@interface CLLocationManager : NSObject
@property(nonatomic, weak, nullable) id<CLLocationManagerDelegate> delegate;
@property(nonatomic, readonly, nullable, copy) CLLocation *location;
@property(nonatomic, readonly, nullable, copy) CLHeading *heading;
@property(nonatomic, readonly) CLAuthorizationStatus authorizationStatus;
@property(nonatomic, readonly) CLAccuracyAuthorization accuracyAuthorization;
@property(nonatomic) CLLocationAccuracy desiredAccuracy;
@property(nonatomic) CLLocationDistance distanceFilter;
@property(nonatomic) CLActivityType activityType;
@property(nonatomic) BOOL pausesLocationUpdatesAutomatically;
@property(nonatomic) BOOL allowsBackgroundLocationUpdates;
@property(nonatomic) BOOL showsBackgroundLocationIndicator;
@property(nonatomic) CLLocationDegrees headingFilter;
@property(nonatomic) CLDeviceOrientation headingOrientation;
@property(nonatomic, readonly, copy) NSSet<CLRegion *> *monitoredRegions;
@property(nonatomic, readonly) CLLocationDistance maximumRegionMonitoringDistance;
+ (BOOL)locationServicesEnabled;
+ (BOOL)headingAvailable;
+ (BOOL)significantLocationChangeMonitoringAvailable;
+ (BOOL)regionMonitoringAvailable;
+ (BOOL)regionMonitoringEnabled;
+ (BOOL)isMonitoringAvailableForClass:(Class)regionClass;
+ (CLAuthorizationStatus)authorizationStatus;
- (void)startUpdatingLocation;
- (void)stopUpdatingLocation;
- (void)requestLocation;
- (void)startUpdatingHeading;
- (void)stopUpdatingHeading;
- (void)dismissHeadingCalibrationDisplay;
- (void)requestWhenInUseAuthorization;
- (void)requestAlwaysAuthorization;
- (void)startMonitoringSignificantLocationChanges;
- (void)stopMonitoringSignificantLocationChanges;
- (void)startMonitoringForRegion:(CLRegion *)region;
- (void)stopMonitoringForRegion:(CLRegion *)region;
- (void)requestStateForRegion:(CLRegion *)region;
@end

typedef void (^CLGeocodeCompletionHandler)(
    NSArray<CLPlacemark *> * _Nullable placemarks,
    NSError * _Nullable error
);

@interface CLGeocoder : NSObject
@property(nonatomic, readonly, getter=isGeocoding) BOOL geocoding;
- (void)reverseGeocodeLocation:(CLLocation *)location
             completionHandler:(CLGeocodeCompletionHandler)completionHandler;
- (void)geocodeAddressString:(NSString *)addressString
           completionHandler:(CLGeocodeCompletionHandler)completionHandler;
- (void)cancelGeocode;
@end

NS_ASSUME_NONNULL_END

#endif
