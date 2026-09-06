import Foundation
import GeoToolbox

func testPlaceRepresentationType() {
    let representation = PlaceDescriptor.PlaceRepresentation.address("x")
    require(type(of: representation) == PlaceDescriptor.PlaceRepresentation.self, "enum type")
}

func testPlaceRepresentationCases() {
    let address = PlaceDescriptor.PlaceRepresentation.address("1 Infinite Loop")
    switch address {
    case .address(let value):
        require(value == "1 Infinite Loop", "address payload")
    case .coordinate, .deviceLocation:
        fatalError("expected address")
    }

    let coordinate = PlaceDescriptor.PlaceRepresentation.coordinate(
        CLLocationCoordinate2D(latitude: 37.3349, longitude: -122.0090)
    )
    switch coordinate {
    case .coordinate(let value):
        require(value.latitude == 37.3349, "coordinate latitude")
        require(value.longitude == -122.0090, "coordinate longitude")
    case .address, .deviceLocation:
        fatalError("expected coordinate")
    }

    let timestamp = Date(timeIntervalSince1970: 1_234)
    let location = CLLocation(
        coordinate: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),
        altitude: 10,
        horizontalAccuracy: 5,
        verticalAccuracy: 8,
        timestamp: timestamp
    )
    let device = PlaceDescriptor.PlaceRepresentation.deviceLocation(location)
    switch device {
    case .deviceLocation(let stored):
        require(stored.coordinate.latitude == 40.7128, "device latitude")
        require(stored.coordinate.longitude == -74.0060, "device longitude")
        require(stored.altitude == 10, "altitude")
        require(stored.horizontalAccuracy == 5, "hAcc")
        require(stored.verticalAccuracy == 8, "vAcc")
        require(stored.timestamp == timestamp, "timestamp")
    case .address, .coordinate:
        fatalError("expected deviceLocation")
    }
}

func testPlaceRepresentationEquality() {
    let a = PlaceDescriptor.PlaceRepresentation.address("same")
    let b = PlaceDescriptor.PlaceRepresentation.address("same")
    let c = PlaceDescriptor.PlaceRepresentation.address("other")
    require(a == b, "equal addresses")
    require(!(a == c), "unequal addresses")

    let c1 = PlaceDescriptor.PlaceRepresentation.coordinate(
        CLLocationCoordinate2D(latitude: 1, longitude: 2)
    )
    let c2 = PlaceDescriptor.PlaceRepresentation.coordinate(
        CLLocationCoordinate2D(latitude: 1, longitude: 2)
    )
    let c3 = PlaceDescriptor.PlaceRepresentation.coordinate(
        CLLocationCoordinate2D(latitude: 1, longitude: 3)
    )
    require(c1 == c2, "equal coordinates")
    require(!(c1 == c3), "unequal coordinates")
    require(!(a == c1), "address != coordinate")

    let t = Date(timeIntervalSince1970: 50)
    let loc1 = CLLocation(
        coordinate: CLLocationCoordinate2D(latitude: 1, longitude: 2),
        altitude: 0,
        horizontalAccuracy: -1,
        verticalAccuracy: -1,
        timestamp: t
    )
    let loc2 = CLLocation(
        coordinate: CLLocationCoordinate2D(latitude: 1, longitude: 2),
        altitude: 0,
        horizontalAccuracy: -1,
        verticalAccuracy: -1,
        timestamp: t
    )
    require(
        PlaceDescriptor.PlaceRepresentation.deviceLocation(loc1)
            == PlaceDescriptor.PlaceRepresentation.deviceLocation(loc2),
        "equal device snapshots"
    )
}

func testPlaceRepresentationInequality() {
    let a = PlaceDescriptor.PlaceRepresentation.address("same")
    let b = PlaceDescriptor.PlaceRepresentation.address("same")
    let c = PlaceDescriptor.PlaceRepresentation.address("other")
    require(!(a != b), "equal is not !=")
    require(a != c, "unequal addresses")
    let coord = PlaceDescriptor.PlaceRepresentation.coordinate(
        CLLocationCoordinate2D(latitude: 0, longitude: 0)
    )
    require(a != coord, "address != coordinate")
}

func testUnwrappedTypeAlias() {
    require(
        PlaceDescriptor.UnwrappedType.self == PlaceDescriptor.self,
        "UnwrappedType"
    )
}

func testValueTypeAlias() {
    require(PlaceDescriptor.ValueType.self == PlaceDescriptor.self, "ValueType")
    let value: PlaceDescriptor.ValueType = PlaceDescriptor(
        representations: [.address("alias")],
        commonName: nil
    )
    require(value.address == "alias", "aliased value")
}
