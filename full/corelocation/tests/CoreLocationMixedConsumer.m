#import <CoreLocation/CoreLocation.h>

double OpenCoreLocationMixedDistance(void) {
    CLLocationCoordinate2D source = CLLocationCoordinate2DMake(40.7128, -74.0060);
    CLLocationCoordinate2D destination = CLLocationCoordinate2DMake(51.5074, -0.1278);
    if (!CLLocationCoordinate2DIsValid(source)
        || !CLLocationCoordinate2DIsValid(destination)) {
        return -1.0;
    }
    CLLocation *sourceLocation = [[CLLocation alloc]
        initWithLatitude:source.latitude
               longitude:source.longitude];
    CLLocation *destinationLocation = [[CLLocation alloc]
        initWithLatitude:destination.latitude
               longitude:destination.longitude];
    return [sourceLocation distanceFromLocation:destinationLocation];
}
