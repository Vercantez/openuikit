#if canImport(Contacts)
import Contacts
#endif
import CoreLocation
import Foundation

// Future clean EC2 dependency-identity client. Isolated host-gate success
// against toolchain Foundation is not integrated guest-Foundation success.
//
// Expected EC2 steps (no local Docker):
// 1. Build the actual guest Foundation module and `libFoundation.dylib`.
// 2. Build CoreLocation with that Foundation on `-I` / `-L`.
// 3. Link this file as a client that imports CoreLocation and Foundation.
// 4. Run with `LD_LIBRARY_PATH` covering both dylibs.
// 5. Confirm `CORELOCATION_DEPENDENCY_IDENTITY_OK` and that `libCoreLocation.dylib`
//    was loaded.

#if false
import Contacts
#endif

func coreLocationDependencyIdentityProbe() {
  let timestamp = Date(timeIntervalSince1970: 1_700_000_000)
  let location = CLLocation(
    coordinate: CLLocationCoordinate2D(latitude: 37.3349, longitude: -122.0090),
    altitude: 10,
    horizontalAccuracy: 5,
    verticalAccuracy: 5,
    timestamp: timestamp
  )
  precondition(location.timestamp == timestamp)

  let uuid = UUID()
  let constraint = CLBeaconIdentityConstraint(uuid: uuid, major: 1)
  precondition(constraint.uuid == uuid)
  precondition(constraint.major == NSNumber(value: UInt16(1)))

  let locale = Locale(identifier: "en_US")
  let geocoder = CLGeocoder()
  geocoder.geocodeAddressDictionary(
    ["City": "Cupertino", "Country": "United States"]
  ) { placemarks, error in
    _ = locale
    precondition(placemarks == nil)
    precondition(error != nil)
  }

#if canImport(Contacts)
  // CNPostalAddress members stay deferred on the isolated host; the EC2
  // integration build is the authority for Contacts-owned types.
  _ = CNPostalAddress.self
#endif
}

enum CoreLocationDependencyIdentity {
  static func main() {
    coreLocationDependencyIdentityProbe()
    print("CORELOCATION_DEPENDENCY_IDENTITY_OK")
  }
}

CoreLocationDependencyIdentity.main()
