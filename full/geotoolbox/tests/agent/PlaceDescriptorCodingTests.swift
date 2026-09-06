import Foundation
import GeoToolbox

private func jsonEncoder() -> JSONEncoder {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    return encoder
}

private func jsonDecoder() -> JSONDecoder {
    JSONDecoder()
}

func testPlaceDescriptorEncode() {
    let descriptor = PlaceDescriptor(
        representations: [.address("121-122 James's St")],
        commonName: "Obelisk Fountain"
    )
    let data = try! jsonEncoder().encode(descriptor)
    let object = try! JSONSerialization.jsonObject(with: data) as! [String: Any]
    require(object["commonName"] as? String == "Obelisk Fountain", "commonName key")
    let representations = object["representations"] as! [[String: Any]]
    require(representations.count == 1, "one representation")
    require(representations[0]["address"] as? String == "121-122 James's St", "address")
}

func testPlaceDescriptorDecode() {
    let json = """
    {"commonName":"Apple Park","representations":[{"address":"1 Infinite Loop"}],"supportingRepresentations":[]}
    """.data(using: .utf8)!
    let descriptor = try! jsonDecoder().decode(PlaceDescriptor.self, from: json)
    require(descriptor.commonName == "Apple Park", "decoded name")
    require(descriptor.address == "1 Infinite Loop", "decoded address")
    require(descriptor.supportingRepresentations.isEmpty, "empty supporting")
}

func testPlaceRepresentationEncode() {
    let address = PlaceDescriptor.PlaceRepresentation.address("postal")
    let addressData = try! jsonEncoder().encode(address)
    let addressObject = try! JSONSerialization.jsonObject(with: addressData) as! [String: Any]
    require(addressObject["address"] as? String == "postal", "address encode")

    let coordinate = PlaceDescriptor.PlaceRepresentation.coordinate(
        CLLocationCoordinate2D(latitude: 10.5, longitude: -20.25)
    )
    let coordinateData = try! jsonEncoder().encode(coordinate)
    let coordinateObject = try! JSONSerialization.jsonObject(with: coordinateData) as! [String: Any]
    let payload = coordinateObject["coordinate"] as! [String: Any]
    require(payload["latitude"] as? Double == 10.5, "lat")
    require(payload["longitude"] as? Double == -20.25, "lon")
}

func testPlaceRepresentationDecode() {
    let addressJSON = """
    {"address":"postal"}
    """.data(using: .utf8)!
    let address = try! jsonDecoder().decode(
        PlaceDescriptor.PlaceRepresentation.self,
        from: addressJSON
    )
    require(address == .address("postal"), "decode address")

    let coordinateJSON = """
    {"coordinate":{"latitude":1.5,"longitude":2.5}}
    """.data(using: .utf8)!
    let coordinate = try! jsonDecoder().decode(
        PlaceDescriptor.PlaceRepresentation.self,
        from: coordinateJSON
    )
    guard case .coordinate(let value) = coordinate else {
        fatalError("expected coordinate")
    }
    require(value.latitude == 1.5, "lat")
    require(value.longitude == 2.5, "lon")

    let empty = "{}".data(using: .utf8)!
    var threw = false
    do {
        _ = try jsonDecoder().decode(PlaceDescriptor.PlaceRepresentation.self, from: empty)
    } catch {
        threw = true
    }
    require(threw, "empty payload fail-closed")
}

func testSupportingPlaceRepresentationEncode() {
    let supporting = PlaceDescriptor.SupportingPlaceRepresentation.serviceIdentifiers(
        ["com.apple.maps": "IFC1B13F6FA980C8A"]
    )
    let data = try! jsonEncoder().encode(supporting)
    let object = try! JSONSerialization.jsonObject(with: data) as! [String: Any]
    let ids = object["serviceIdentifiers"] as! [String: String]
    require(ids["com.apple.maps"] == "IFC1B13F6FA980C8A", "encoded id")
}

func testSupportingPlaceRepresentationDecode() {
    let json = """
    {"serviceIdentifiers":{"com.apple.maps":"IFC1B13F6FA980C8A"}}
    """.data(using: .utf8)!
    let supporting = try! jsonDecoder().decode(
        PlaceDescriptor.SupportingPlaceRepresentation.self,
        from: json
    )
    require(
        supporting == .serviceIdentifiers(["com.apple.maps": "IFC1B13F6FA980C8A"]),
        "decode supporting"
    )
}

func testPlaceDescriptorJSONRoundTrip() {
    let timestamp = Date(timeIntervalSince1970: 1_700_000_000)
    let location = CLLocation(
        coordinate: CLLocationCoordinate2D(latitude: 53.343, longitude: -6.267),
        altitude: 8,
        horizontalAccuracy: 5,
        verticalAccuracy: -1,
        timestamp: timestamp
    )
    let original = PlaceDescriptor(
        representations: [
            .address("121-122 James's St"),
            .coordinate(CLLocationCoordinate2D(latitude: 53.343, longitude: -6.267)),
            .deviceLocation(location)
        ],
        commonName: "Obelisk Fountain",
        supportingRepresentations: [
            .serviceIdentifiers(["com.apple.maps": "IFC1B13F6FA980C8A"])
        ]
    )
    let data = try! jsonEncoder().encode(original)
    let restored = try! jsonDecoder().decode(PlaceDescriptor.self, from: data)
    require(restored == original, "round trip")
    require(restored.serviceIdentifier(for: "com.apple.maps") == "IFC1B13F6FA980C8A", "id")
    require(restored.address == "121-122 James's St", "address")
    require(restored.coordinate?.latitude == 53.343, "coordinate")
}
