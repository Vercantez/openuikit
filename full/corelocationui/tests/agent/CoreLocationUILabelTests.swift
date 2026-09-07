import Foundation
@_spi(OpenUIKitHost) import CoreLocationUI

/// Table-driven `CLLocationButtonLabel` cases and exact raw values from pinned
/// macios (`None = 0`, then the five titles in declaration order).
func testLabelCases() {
    let table: [(CLLocationButtonLabel, Int)] = [
        (.none, 0),
        (.currentLocation, 1),
        (.sendCurrentLocation, 2),
        (.sendMyCurrentLocation, 3),
        (.shareCurrentLocation, 4),
        (.shareMyCurrentLocation, 5),
    ]
    precondition(Set(table.map(\.0)).count == 6)
    precondition(Set(table.map(\.1)).count == 6)
    for (value, raw) in table {
        precondition(value.rawValue == raw)
        precondition(CLLocationButtonLabel(rawValue: raw) == value)
    }
    typealias Raw = CLLocationButtonLabel.RawValue
    precondition((table[1].1 as Raw) == 1)
}

func testLabelRawValueInit() {
    precondition(CLLocationButtonLabel(rawValue: 0) == CLLocationButtonLabel.none)
    precondition(CLLocationButtonLabel(rawValue: 1) == .currentLocation)
    precondition(CLLocationButtonLabel(rawValue: 5) == .shareMyCurrentLocation)
    precondition(CLLocationButtonLabel(rawValue: 6) == nil)
    precondition(CLLocationButtonLabel(rawValue: -1) == nil)
}

func testLabelInequality() {
    precondition(CLLocationButtonLabel.none != .currentLocation)
    precondition(CLLocationButtonLabel.currentLocation != .sendCurrentLocation)
    precondition(CLLocationButtonLabel.sendCurrentLocation != .sendMyCurrentLocation)
    precondition(CLLocationButtonLabel.sendMyCurrentLocation != .shareCurrentLocation)
    precondition(CLLocationButtonLabel.shareCurrentLocation != .shareMyCurrentLocation)
    precondition(!(CLLocationButtonLabel.currentLocation != .currentLocation))
    precondition(CLLocationButtonLabel.shareMyCurrentLocation == .shareMyCurrentLocation)
}

func testLabelHashValue() {
    precondition(
        CLLocationButtonLabel.currentLocation.hashValue
            == CLLocationButtonLabel.currentLocation.hashValue
    )
    var hasher = Hasher()
    CLLocationButtonLabel.none.hash(into: &hasher)
    CLLocationButtonLabel.currentLocation.hash(into: &hasher)
    CLLocationButtonLabel.shareMyCurrentLocation.hash(into: &hasher)
    _ = hasher.finalize()
    _ = CLLocationButtonLabel.sendCurrentLocation.hashValue
}

func testLabelHashInto() {
    var first = Hasher()
    CLLocationButtonLabel.shareMyCurrentLocation.hash(into: &first)
    let firstValue = first.finalize()

    var second = Hasher()
    CLLocationButtonLabel.shareMyCurrentLocation.hash(into: &second)
    let secondValue = second.finalize()

    precondition(firstValue == secondValue)
}
