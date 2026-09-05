@_spi(OpenUIKitHost) import VisionKit
import Foundation

/// Table-driven Linux-local bits for `ImageAnalyzer.AnalysisTypes`.
/// Darwin numeric ABI is unobserved (see oracle-questions.tsv).
func testAnalysisTypesBits() {
    typealias Types = ImageAnalyzer.AnalysisTypes
    let catalog: [(Types, UInt)] = [
        (.text, 1 << 0),
        (.visualLookUp, 1 << 1),
        (.machineReadableCode, 1 << 2),
    ]
    for (flag, bit) in catalog {
        precondition(flag.rawValue == bit)
        precondition(Types(rawValue: bit) == flag)
        precondition(Types(rawValue: bit).contains(flag))
    }
    precondition(Types.text != .visualLookUp)
    precondition(Types.text != .machineReadableCode)
    precondition(Types.visualLookUp != .machineReadableCode)
    precondition(Types.Element.self == Types.self)
    precondition(Types.ArrayLiteralElement.self == Types.self)
    precondition(Types.RawValue.self == UInt.self)
    let passthrough = Types(rawValue: 0b101)
    precondition(passthrough.rawValue == 0b101)
    precondition(passthrough.contains(.text))
    precondition(!passthrough.contains(.visualLookUp))
    precondition(passthrough.contains(.machineReadableCode))
}

func testAnalysisTypesAlgebra() {
    typealias Types = ImageAnalyzer.AnalysisTypes
    var empty = Types()
    precondition(empty.isEmpty)
    precondition(!empty.contains(.text))
    empty.insert(.text)
    precondition(empty.contains(.text))
    precondition(!empty.contains(.visualLookUp))

    let combined: Types = [.text, .visualLookUp]
    precondition(combined.contains(.text))
    precondition(combined.contains(.visualLookUp))
    precondition(!combined.contains(.machineReadableCode))
    precondition(combined != .text)
    precondition(combined.intersection(.text) == .text)
    precondition(combined.union(.machineReadableCode).contains(.machineReadableCode))
    precondition(combined.subtracting(.text).contains(.visualLookUp))
    precondition(!combined.subtracting(.text).contains(.text))
    precondition(combined.isSuperset(of: .text))
    precondition(!combined.isSubset(of: .text))
    precondition(combined.isStrictSuperset(of: .text))
    precondition(Types.text.isStrictSubset(of: combined))
    precondition(!combined.isDisjoint(with: .text))
    precondition(Types().isDisjoint(with: .text))

    var mutable = combined
    mutable.formUnion(.machineReadableCode)
    mutable.formIntersection([.text, .machineReadableCode])
    precondition(mutable.contains(.text))
    precondition(!mutable.contains(.visualLookUp))
    _ = mutable.remove(.text)
    precondition(!mutable.contains(.text))
    _ = mutable.update(with: .visualLookUp)
    mutable.formSymmetricDifference(.visualLookUp)
    precondition(!mutable.contains(.visualLookUp))
    mutable.subtract(.machineReadableCode)
    precondition(mutable.isEmpty)

    let fromSequence = Types([.text, .text])
    precondition(fromSequence.contains(.text))
    precondition(.text != Types(rawValue: 0))
    let symmetric = Types.text.symmetricDifference(.visualLookUp)
    precondition(symmetric.contains(.text))
    precondition(symmetric.contains(.visualLookUp))
}
