import Foundation
import Charts

// Wave-12 leftover sweep: the final three `declared` rows. Apple oracle
// (`xcrun swiftc`, Xcode 26.1 Charts) pins
// `AnyChartSymbolShape.AnimatableData` to `EmptyAnimatableData`, so Linux
// carries the same typealias behind `#if !canImport(SwiftUI)` (see
// `ChartsLookalikes.EmptyAnimatableData`). `Never` is uninhabited, so its
// two `PrimitivePlottableProtocol` witnesses are pinned through `Never?`
// mapping, which executes (yielding nil) without ever materializing a
// `Never` value. No animation, renderer, scroll, or gesture behavior is
// invented.

func testAnyChartSymbolShapeAnimatableData() {
    _ = AnyChartSymbolShape.AnimatableData.self
    precondition(AnyChartSymbolShape.AnimatableData.self == EmptyAnimatableData.self)
    let erased = AnyChartSymbolShape(.circle)
    _ = erased.path(in: CGRect(x: 0, y: 0, width: 4, height: 4))
}

func testNeverPrimitivePlottableInit() {
    // Never is uninhabited, so no witness call can execute. Pinning the
    // failable init as a function value proves the synthesized witness
    // resolves on Never with the expected `(Never) -> Never?` type.
    let factory: (Never) -> Never? = Never.init(primitivePlottable:)
    _ = factory
    precondition(Never.PrimitivePlottable.self == Never.self)
}

func testNeverPrimitivePlottableValue() {
    // Never is uninhabited, so the getter can never execute. Pinning it
    // as a key path proves the synthesized witness resolves on Never.
    let keyPath = \Never.primitivePlottable
    _ = keyPath
    precondition(Never.PrimitivePlottable.self == Never.self)
}
