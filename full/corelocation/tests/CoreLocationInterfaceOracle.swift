import CoreLocation
import Foundation

@main
struct CoreLocationInterfaceOracle {
  static func main() {
    print(
      "coordinate-layout=size:\(MemoryLayout<CLLocationCoordinate2D>.size),"
        + "stride:\(MemoryLayout<CLLocationCoordinate2D>.stride),"
        + "alignment:\(MemoryLayout<CLLocationCoordinate2D>.alignment)"
    )
    let coordinate = CLLocationCoordinate2DMake(12.5, -45.25)
    print(
      "coordinate=\(coordinate.latitude),\(coordinate.longitude) "
        + "valid=\(CLLocationCoordinate2DIsValid(coordinate)) "
        + "invalid=\(CLLocationCoordinate2DIsValid(kCLLocationCoordinate2DInvalid))"
    )
    print(
      "accuracy=nav:\(kCLLocationAccuracyBestForNavigation),"
        + "best:\(kCLLocationAccuracyBest),ten:\(kCLLocationAccuracyNearestTenMeters),"
        + "hundred:\(kCLLocationAccuracyHundredMeters),"
        + "kilometer:\(kCLLocationAccuracyKilometer),"
        + "three-kilometers:\(kCLLocationAccuracyThreeKilometers),"
        + "reduced:\(kCLLocationAccuracyReduced)"
    )
    print(
      "authorization=not-determined:\(CLAuthorizationStatus.notDetermined.rawValue),"
        + "restricted:\(CLAuthorizationStatus.restricted.rawValue),"
        + "denied:\(CLAuthorizationStatus.denied.rawValue),"
        + "always:\(CLAuthorizationStatus.authorizedAlways.rawValue)"
    )
    print(
      "state=unknown:\(CLRegionState.unknown.rawValue),"
        + "inside:\(CLRegionState.inside.rawValue),"
        + "outside:\(CLRegionState.outside.rawValue)"
    )
    let zero = CLLocation(latitude: 40.7128, longitude: -74.0060)
      .distance(from: CLLocation(latitude: 40.7128, longitude: -74.0060))
    let nycLondon = CLLocation(latitude: 40.7128, longitude: -74.0060)
      .distance(from: CLLocation(latitude: 51.5074, longitude: -0.1278))
    let equatorDegree = CLLocation(latitude: 0, longitude: 0)
      .distance(from: CLLocation(latitude: 0, longitude: 1))
    print(
      "distance=zero:\(Int(zero.rounded())),"
        + "nyc-london:\(Int(nycLondon.rounded())),"
        + "equator-degree:\(Int(equatorDegree.rounded()))"
    )
  }
}
