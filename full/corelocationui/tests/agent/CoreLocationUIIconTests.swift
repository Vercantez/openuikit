import Foundation
@_spi(OpenUIKitHost) import CoreLocationUI

/// Table-driven `CLLocationButtonIcon` cases and exact raw values from pinned
/// macios (`None = 0`, `ArrowFilled = 1`, `ArrowOutline = 2`).
func testIconCases() {
    let table: [(CLLocationButtonIcon, Int)] = [
        (.none, 0),
        (.arrowFilled, 1),
        (.arrowOutline, 2),
    ]
    precondition(Set(table.map(\.0)).count == 3)
    precondition(Set(table.map(\.1)).count == 3)
    for (value, raw) in table {
        precondition(value.rawValue == raw)
        precondition(CLLocationButtonIcon(rawValue: raw) == value)
    }
    typealias Raw = CLLocationButtonIcon.RawValue
    precondition((table[0].1 as Raw) == 0)
}

func testIconRawValueInit() {
    precondition(CLLocationButtonIcon(rawValue: 0) == CLLocationButtonIcon.none)
    precondition(CLLocationButtonIcon(rawValue: 1) == .arrowFilled)
    precondition(CLLocationButtonIcon(rawValue: 2) == .arrowOutline)
    precondition(CLLocationButtonIcon(rawValue: 3) == nil)
    precondition(CLLocationButtonIcon(rawValue: -1) == nil)
}

func testIconInequality() {
    precondition(CLLocationButtonIcon.none != .arrowFilled)
    precondition(CLLocationButtonIcon.arrowFilled != .arrowOutline)
    precondition(CLLocationButtonIcon.arrowOutline != .none)
    precondition(!(CLLocationButtonIcon.none != .none))
    precondition(CLLocationButtonIcon.arrowFilled == .arrowFilled)
}

func testIconHashValue() {
    precondition(CLLocationButtonIcon.none.hashValue == CLLocationButtonIcon.none.hashValue)
    precondition(CLLocationButtonIcon.arrowFilled.hashValue == CLLocationButtonIcon.arrowFilled.hashValue)
    var hasher = Hasher()
    CLLocationButtonIcon.none.hash(into: &hasher)
    CLLocationButtonIcon.arrowFilled.hash(into: &hasher)
    CLLocationButtonIcon.arrowOutline.hash(into: &hasher)
    _ = hasher.finalize()
    _ = CLLocationButtonIcon.none.hashValue
}

func testIconHashInto() {
    var first = Hasher()
    CLLocationButtonIcon.arrowOutline.hash(into: &first)
    let firstValue = first.finalize()

    var second = Hasher()
    CLLocationButtonIcon.arrowOutline.hash(into: &second)
    let secondValue = second.finalize()

    precondition(firstValue == secondValue)
}
