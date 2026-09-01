#import "CoreLocation.h"

#include <float.h>
#include <math.h>

const CLLocationDistance CLLocationDistanceMax = DBL_MAX;
const CLLocationDistance kCLDistanceFilterNone = -1.0;
const CLLocationAccuracy kCLLocationAccuracyBestForNavigation = -2.0;
const CLLocationAccuracy kCLLocationAccuracyBest = -1.0;
const CLLocationAccuracy kCLLocationAccuracyNearestTenMeters = 10.0;
const CLLocationAccuracy kCLLocationAccuracyHundredMeters = 100.0;
const CLLocationAccuracy kCLLocationAccuracyKilometer = 1000.0;
const CLLocationAccuracy kCLLocationAccuracyThreeKilometers = 3000.0;
const CLLocationAccuracy kCLLocationAccuracyReduced = 6380000.0;
const CLLocationCoordinate2D kCLLocationCoordinate2DInvalid = {
    INFINITY,
    INFINITY,
};
// The Swift module vends the canonical string. The Clang boundary keeps the
// data symbol available but fails closed rather than embedding a
// __CFConstantStringClassReference that the guest Foundation runtime cannot
// currently resolve during cold loading.
NSErrorDomain const kCLErrorDomain = nil;

CLLocationCoordinate2D CLLocationCoordinate2DMake(
    CLLocationDegrees latitude,
    CLLocationDegrees longitude
) {
    return (CLLocationCoordinate2D){latitude, longitude};
}

BOOL CLLocationCoordinate2DIsValid(CLLocationCoordinate2D coordinate) {
    return isfinite(coordinate.latitude) && isfinite(coordinate.longitude)
        && coordinate.latitude >= -90.0 && coordinate.latitude <= 90.0
        && coordinate.longitude >= -180.0 && coordinate.longitude <= 180.0;
}

@interface CLLocation (OpenCoreLocationCoordinateBridge)
@property(nonatomic, readonly) CLLocationDegrees _openLatitude;
@property(nonatomic, readonly) CLLocationDegrees _openLongitude;
@end

@implementation CLLocation (OpenCoreLocationCoordinateABI)
- (CLLocationCoordinate2D)coordinate {
    return CLLocationCoordinate2DMake(self._openLatitude, self._openLongitude);
}
@end

@interface CLCircularRegion (OpenCoreLocationCoordinateBridge)
@property(nonatomic, readonly) CLLocationDegrees _openCenterLatitude;
@property(nonatomic, readonly) CLLocationDegrees _openCenterLongitude;
- (BOOL)_openContainsLatitude:(CLLocationDegrees)latitude
                    longitude:(CLLocationDegrees)longitude;
@end

@implementation CLCircularRegion (OpenCoreLocationCoordinateABI)
- (CLLocationCoordinate2D)center {
    return CLLocationCoordinate2DMake(
        self._openCenterLatitude,
        self._openCenterLongitude
    );
}

- (BOOL)containsCoordinate:(CLLocationCoordinate2D)coordinate {
    return [self _openContainsLatitude:coordinate.latitude
                             longitude:coordinate.longitude];
}
@end

@interface CLVisit (OpenCoreLocationCoordinateBridge)
@property(nonatomic, readonly) CLLocationDegrees _openLatitude;
@property(nonatomic, readonly) CLLocationDegrees _openLongitude;
@end

@implementation CLVisit (OpenCoreLocationCoordinateABI)
- (CLLocationCoordinate2D)coordinate {
    return CLLocationCoordinate2DMake(self._openLatitude, self._openLongitude);
}
@end
