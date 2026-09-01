@_spi(OpenUIKitHost) import CoreLocation
import Foundation

private final class LocationDelegate: NSObject, CLLocationManagerDelegate {
  var authorizations: [CLAuthorizationStatus] = []
  var locations: [CLLocation] = []
  var headings: [CLHeading] = []
  var errors: [CLError.Code] = []
  var regionStates: [CLRegionState] = []

  func locationManager(
    _ manager: CLLocationManager,
    didChangeAuthorization status: CLAuthorizationStatus
  ) {
    _ = manager
    authorizations.append(status)
  }

  func locationManager(
    _ manager: CLLocationManager,
    didUpdateLocations locations: [CLLocation]
  ) {
    _ = manager
    self.locations.append(contentsOf: locations)
  }

  func locationManager(
    _ manager: CLLocationManager,
    didUpdateHeading newHeading: CLHeading
  ) {
    _ = manager
    headings.append(newHeading)
  }

  func locationManager(
    _ manager: CLLocationManager,
    didFailWithError error: Error
  ) {
    _ = manager
    if let error = error as? CLError {
      errors.append(error.code)
    }
  }

  func locationManager(
    _ manager: CLLocationManager,
    didDetermineState state: CLRegionState,
    for region: CLRegion
  ) {
    _ = manager
    _ = region
    regionStates.append(state)
  }
}

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
  if !condition() {
    fatalError(message)
  }
}

@main
struct CoreLocationGuestRuntime {
  static func main() {
    let invalid = CLLocationCoordinate2D(latitude: 91, longitude: 0)
    require(!CLLocationCoordinate2DIsValid(invalid), "invalid coordinate accepted")

    let origin = CLLocation(latitude: 40.7128, longitude: -74.0060)
    let destination = CLLocation(latitude: 51.5074, longitude: -0.1278)
    let transatlantic = origin.distance(from: destination)
    require((5_500_000...5_650_000).contains(transatlantic), "distance drifted")
    let region = CLCircularRegion(
      center: origin.coordinate,
      radius: 100,
      identifier: "downtown"
    )
    require(region.contains(origin.coordinate), "region rejected center")
    require(!region.contains(destination.coordinate), "region accepted distant point")

    let denied = CLLocationManager()
    let deniedDelegate = LocationDelegate()
    denied.delegate = deniedDelegate
    denied.requestWhenInUseAuthorization()
    denied.requestLocation()
    require(denied.authorizationStatus == .denied, "authorization did not fail closed")
    require(deniedDelegate.authorizations == [.denied], "denied callback drifted")
    require(deniedDelegate.errors == [.denied], "denied request did not fail")

    let manager = CLLocationManager()
    let delegate = LocationDelegate()
    manager.delegate = delegate
    manager._portableSetAuthorization(.authorizedWhenInUse)
    manager.startUpdatingLocation()
    manager.startUpdatingHeading()
    manager.startMonitoring(for: region)
    manager._portableInject(locations: [origin])
    manager._portableInject(
      heading: CLHeading(
        magneticHeading: 14,
        trueHeading: 12,
        headingAccuracy: 1
      )
    )
    require(delegate.locations == [origin], "location injection was not deterministic")
    require(delegate.headings.count == 1, "heading injection was not delivered")
    require(delegate.regionStates == [.inside], "region state was not delivered")
    manager.stopUpdatingLocation()
    manager._portableInject(locations: [destination])
    require(delegate.locations == [origin], "stopped manager delivered a location")
    require(manager.location == destination, "latest location was not cached")
    manager.requestLocation()
    require(delegate.locations == [origin, destination], "one-shot cached location failed")

    let geocoder = CLGeocoder()
    var failClosed: CLError.Code?
    geocoder.reverseGeocodeLocation(origin) { placemarks, error in
      require(placemarks == nil, "fail-closed geocoder invented a placemark")
      failClosed = (error as? CLError)?.code
    }
    require(failClosed == .geocodeFoundNoResult, "geocoder error drifted")
    let placemark = CLPlacemark(
      location: origin,
      locality: "New York",
      isoCountryCode: "US",
      country: "United States"
    )
    geocoder._portableSetReverseGeocodeHandler { _ in .success([placemark]) }
    var hostLocality: String?
    geocoder.reverseGeocodeLocation(origin) { placemarks, error in
      require(error == nil, "host geocoder returned an error")
      hostLocality = placemarks?.first?.locality
    }
    require(hostLocality == "New York", "host geocoder injection failed")

    print(
      "CORELOCATION_GUEST_OK geometry=coordinate,distance,region "
        + "authorization=fail-closed,host-driven "
        + "delivery=location,heading,region,deterministic "
        + "geocoder=fail-closed,host-driven"
    )
  }
}
