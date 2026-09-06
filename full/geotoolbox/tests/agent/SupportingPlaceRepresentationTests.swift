import Foundation
import GeoToolbox

func testSupportingPlaceRepresentationType() {
    let supporting = PlaceDescriptor.SupportingPlaceRepresentation.serviceIdentifiers([:])
    require(
        type(of: supporting) == PlaceDescriptor.SupportingPlaceRepresentation.self,
        "enum type"
    )
}

func testSupportingPlaceRepresentationCases() {
    let identifiers = ["com.apple.maps": "IFC1B13F6FA980C8A", "com.example.maps": "xyz"]
    let supporting = PlaceDescriptor.SupportingPlaceRepresentation.serviceIdentifiers(identifiers)
    switch supporting {
    case .serviceIdentifiers(let stored):
        require(stored["com.apple.maps"] == "IFC1B13F6FA980C8A", "maps id")
        require(stored["com.example.maps"] == "xyz", "example id")
        require(stored.count == 2, "count")
    }
}

func testSupportingPlaceRepresentationEquality() {
    let a = PlaceDescriptor.SupportingPlaceRepresentation.serviceIdentifiers(
        ["com.apple.maps": "A"]
    )
    let b = PlaceDescriptor.SupportingPlaceRepresentation.serviceIdentifiers(
        ["com.apple.maps": "A"]
    )
    let c = PlaceDescriptor.SupportingPlaceRepresentation.serviceIdentifiers(
        ["com.apple.maps": "B"]
    )
    require(a == b, "equal dictionaries")
    require(!(a == c), "different identifiers")
}

func testSupportingPlaceRepresentationInequality() {
    let a = PlaceDescriptor.SupportingPlaceRepresentation.serviceIdentifiers(
        ["k": "1"]
    )
    let b = PlaceDescriptor.SupportingPlaceRepresentation.serviceIdentifiers(
        ["k": "1"]
    )
    let c = PlaceDescriptor.SupportingPlaceRepresentation.serviceIdentifiers(
        ["k": "2"]
    )
    require(!(a != b), "equal is not !=")
    require(a != c, "different")
}
