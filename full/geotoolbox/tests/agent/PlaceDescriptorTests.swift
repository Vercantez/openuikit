import Foundation
import GeoToolbox

func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else {
        fatalError(message)
    }
}

func testPlaceDescriptorType() {
    let descriptor = PlaceDescriptor(
        representations: [.address("1 Infinite Loop, Cupertino, CA")],
        commonName: "Apple Park"
    )
    require(type(of: descriptor) == PlaceDescriptor.self, "PlaceDescriptor type")
}

func testPlaceDescriptorInit() {
    let descriptor = PlaceDescriptor(
        representations: [
            .address("121-122 James's St"),
            .coordinate(CLLocationCoordinate2D(latitude: 53.3431, longitude: -6.2675))
        ],
        commonName: "Obelisk Fountain"
    )
    require(descriptor.representations.count == 2, "two representations")
    require(descriptor.commonName == "Obelisk Fountain", "commonName stored")
    require(descriptor.supportingRepresentations.isEmpty, "default supporting empty")
}

func testPlaceDescriptorCommonName() {
    let named = PlaceDescriptor(
        representations: [.address("Yosemite")],
        commonName: "Yosemite National Park"
    )
    require(named.commonName == "Yosemite National Park", "named")
    let unnamed = PlaceDescriptor(
        representations: [.address("private residence")],
        commonName: nil
    )
    require(unnamed.commonName == nil, "nil commonName")
}

func testPlaceDescriptorRepresentations() {
    let first = PlaceDescriptor.PlaceRepresentation.coordinate(
        CLLocationCoordinate2D(latitude: 37.3349, longitude: -122.0090)
    )
    let second = PlaceDescriptor.PlaceRepresentation.address("1 Infinite Loop")
    let descriptor = PlaceDescriptor(
        representations: [first, second],
        commonName: "Apple Park"
    )
    require(descriptor.representations.count == 2, "count")
    require(descriptor.representations[0] == first, "order preserved first")
    require(descriptor.representations[1] == second, "order preserved second")
}

func testPlaceDescriptorSupportingRepresentations() {
    let supporting = PlaceDescriptor.SupportingPlaceRepresentation.serviceIdentifiers(
        ["com.apple.maps": "IFC1B13F6FA980C8A"]
    )
    let descriptor = PlaceDescriptor(
        representations: [.address("Dublin")],
        commonName: "Obelisk Fountain",
        supportingRepresentations: [supporting]
    )
    require(descriptor.supportingRepresentations.count == 1, "one supporting")
    require(descriptor.supportingRepresentations[0] == supporting, "stored")
}

func testPlaceDescriptorAddress() {
    let onlyCoordinate = PlaceDescriptor(
        representations: [.coordinate(CLLocationCoordinate2D(latitude: 1, longitude: 2))],
        commonName: nil
    )
    require(onlyCoordinate.address == nil, "no address")

    let mixed = PlaceDescriptor(
        representations: [
            .coordinate(CLLocationCoordinate2D(latitude: 1, longitude: 2)),
            .address("first address"),
            .address("second address")
        ],
        commonName: nil
    )
    require(mixed.address == "first address", "first address in order")
}

func testPlaceDescriptorCoordinate() {
    let onlyAddress = PlaceDescriptor(
        representations: [.address("no coords")],
        commonName: nil
    )
    require(onlyAddress.coordinate == nil, "no coordinate")

    let fromCoordinate = PlaceDescriptor(
        representations: [
            .address("hint"),
            .coordinate(CLLocationCoordinate2D(latitude: 37.33, longitude: -122.03))
        ],
        commonName: nil
    )
    require(fromCoordinate.coordinate?.latitude == 37.33, "from coordinate case")
    require(fromCoordinate.coordinate?.longitude == -122.03, "longitude")

    let timestamp = Date(timeIntervalSince1970: 100)
    let location = CLLocation(
        coordinate: CLLocationCoordinate2D(latitude: 53.34, longitude: -6.26),
        altitude: 0,
        horizontalAccuracy: 10,
        verticalAccuracy: -1,
        timestamp: timestamp
    )
    let fromDevice = PlaceDescriptor(
        representations: [.deviceLocation(location)],
        commonName: nil
    )
    require(fromDevice.coordinate?.latitude == 53.34, "from deviceLocation")
    require(fromDevice.coordinate?.longitude == -6.26, "device longitude")
}

func testServiceIdentifierFor() {
    let descriptor = PlaceDescriptor(
        representations: [.address("Dublin")],
        commonName: "Obelisk Fountain",
        supportingRepresentations: [
            .serviceIdentifiers(["com.apple.maps": "AAA", "com.example.maps": "BBB"]),
            .serviceIdentifiers(["com.apple.maps": "CCC"])
        ]
    )
    require(descriptor.serviceIdentifier(for: "com.apple.maps") == "AAA", "first match")
    require(descriptor.serviceIdentifier(for: "com.example.maps") == "BBB", "other provider")
    require(descriptor.serviceIdentifier(for: "com.missing.maps") == nil, "missing")
}

func testPersistentIdentifier() {
    require(PlaceDescriptor.persistentIdentifier == "PlaceDescriptor", "Linux type name")
    require(PlaceDescriptor.persistentIdentifier.isEmpty == false, "nonempty")
}
