import Foundation
import GeoToolbox

// Future clean EC2 dependency-identity client. Isolated host-gate success
// against toolchain Foundation is not integrated guest-Foundation success.

private func assertNotGeoToolboxType<T>(_ value: T) {
    precondition(!String(reflecting: type(of: value)).hasPrefix("GeoToolbox."))
}

func geotoolboxDependencyIdentityProbe() {
    let commonName = String("Obelisk Fountain")
    assertNotGeoToolboxType(commonName)
    let address = String("121-122 James's St \n Dublin 8 \n D08 ET27 \n Ireland")
    assertNotGeoToolboxType(address)

    let descriptor = PlaceDescriptor(
        representations: [.address(address)],
        commonName: commonName
    )
    precondition(descriptor.commonName == commonName)
    precondition(descriptor.address == address)
    assertNotGeoToolboxType(descriptor.commonName as Any)
    assertNotGeoToolboxType(descriptor.address as Any)

    let timestamp = Date(timeIntervalSince1970: 1_700_000_000)
    assertNotGeoToolboxType(timestamp)
    let location = CLLocation(
        coordinate: CLLocationCoordinate2D(latitude: 53.343, longitude: -6.267),
        altitude: 8,
        horizontalAccuracy: 5,
        verticalAccuracy: -1,
        timestamp: timestamp
    )
    let located = PlaceDescriptor(
        representations: [.deviceLocation(location)],
        commonName: commonName,
        supportingRepresentations: [
            .serviceIdentifiers(["com.apple.maps": "IFC1B13F6FA980C8A"])
        ]
    )
    precondition(located.coordinate?.latitude == 53.343)
    precondition(located.serviceIdentifier(for: "com.apple.maps") == "IFC1B13F6FA980C8A")
    precondition(location.timestamp == timestamp)
    assertNotGeoToolboxType(location.timestamp)
}

#if GEOTOOLBOX_IDENTITY_MAIN
geotoolboxDependencyIdentityProbe()
print("GEOTOOLBOX_DEPENDENCY_IDENTITY_OK")
#endif
