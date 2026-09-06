import Foundation
import GeoToolbox

func testPlaceDescriptorEquality() {
    let a = PlaceDescriptor(
        representations: [.address("same")],
        commonName: "Name",
        supportingRepresentations: [
            .serviceIdentifiers(["com.apple.maps": "1"])
        ]
    )
    let b = PlaceDescriptor(
        representations: [.address("same")],
        commonName: "Name",
        supportingRepresentations: [
            .serviceIdentifiers(["com.apple.maps": "1"])
        ]
    )
    let c = PlaceDescriptor(
        representations: [.address("other")],
        commonName: "Name"
    )
    require(a == b, "equal descriptors")
    require(!(a == c), "different representations")
    let renamed = PlaceDescriptor(
        representations: [.address("same")],
        commonName: "Other"
    )
    require(!(a == renamed), "different commonName")
}

func testPlaceDescriptorInequality() {
    let a = PlaceDescriptor(representations: [.address("a")], commonName: nil)
    let b = PlaceDescriptor(representations: [.address("a")], commonName: nil)
    let c = PlaceDescriptor(representations: [.address("b")], commonName: nil)
    require(!(a != b), "equal is not !=")
    require(a != c, "different")
}
