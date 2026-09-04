@_spi(OpenUIKitHost) import Charts
import Foundation

/// Schema-v1-style local runtime probe. The sealed schema-v2 gate compiles
/// `*Tests.swift` plus generated load-smoke instead of this file.
func chartsRuntimeProbe() {
    precondition(ChartsPortable.renderingCapability == .basicMarks)
    let mark = LineMark(x: .value("x", 1), y: .value("y", 2))
    precondition(mark.x == 1)
    precondition(mark.y == 2)
    let proxy = ChartProxy()
    precondition(proxy.position(forX: 1) == nil)
    _ = InterpolationMethod.catmullRom
    _ = BasicChartSymbolShape.circle
}
