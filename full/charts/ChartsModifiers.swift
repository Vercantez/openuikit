#if canImport(SwiftUI)
import SwiftUI
#endif
import Foundation

/// Charts-owned View modifiers from the Xcode 26.1 overlay. Layout,
/// selection, 3D pose, and scroll interaction stay fail-closed; the
/// names compile so the census can be declared without inventing UI.
public extension View {
    func chartZAxis<T0>(content: T0) -> Self { self }
    func chartZAxis<T0>(_ p0: T0) -> Self { self }
    func chart3DPose<T0>(_ p0: T0) -> Self { self }
    func chartLegend<T0, T1, T2, T3>(position: T0, alignment: T1, spacing: T2, content: T3) -> Self { self }
    func chartLegend<T0, T1, T2>(position: T0, alignment: T1, spacing: T2) -> Self { self }
    func chartXScale<T0>(type: T0) -> Self { self }
    func chartXScale<T0, T1>(range: T0, type: T1) -> Self { self }
    func chartXScale<T0, T1>(domain: T0, type: T1) -> Self { self }
    func chartXScale<T0, T1, T2>(domain: T0, range: T1, type: T2) -> Self { self }
    func chartYScale<T0>(type: T0) -> Self { self }
    func chartYScale<T0, T1>(range: T0, type: T1) -> Self { self }
    func chartYScale<T0, T1>(domain: T0, type: T1) -> Self { self }
    func chartYScale<T0, T1, T2>(domain: T0, range: T1, type: T2) -> Self { self }
    func chartZScale<T0, T1>(range: T0, type: T1) -> Self { self }
    func chartZScale<T0, T1>(domain: T0, type: T1) -> Self { self }
    func chartZScale<T0, T1, T2>(domain: T0, range: T1, type: T2) -> Self { self }
    func chartGesture<T0>(_ p0: T0) -> Self { self }
    func chartOverlay<T0, T1>(alignment: T0, content: T1) -> Self { self }
    func chartPlotStyle<T0>(content: T0) -> Self { self }
    func chartBackground<T0, T1>(alignment: T0, content: T1) -> Self { self }
    func chartXAxisLabel<T0, T1, T2, T3>(position: T0, alignment: T1, spacing: T2, content: T3) -> Self { self }
    func chartXAxisLabel<T0, T1, T2, T3>(_ p0: T0, position: T1, alignment: T2, spacing: T3) -> Self { self }
    func chartXAxisStyle<T0>(content: T0) -> Self { self }
    func chartXSelection<T0>(range: T0) -> Self { self }
    func chartYAxisLabel<T0, T1, T2, T3>(position: T0, alignment: T1, spacing: T2, content: T3) -> Self { self }
    func chartYAxisLabel<T0, T1, T2, T3>(_ p0: T0, position: T1, alignment: T2, spacing: T3) -> Self { self }
    func chartYAxisStyle<T0>(content: T0) -> Self { self }
    func chartYSelection<T0>(range: T0) -> Self { self }
    func chartYSelection<T0>(value: T0) -> Self { self }
    func chartZAxisLabel<T0, T1, T2, T3>(_ p0: T0, position: T1, alignment: T2, spacing: T3) -> Self { self }
    func chartZSelection<T0>(range: T0) -> Self { self }
    func chartZSelection<T0>(value: T0) -> Self { self }
    func chartSymbolScale<T0>(range: T0) -> Self { self }
    func chartSymbolScale<T0, T1>(domain: T0, range: T1) -> Self { self }
    func chartSymbolScale<T0, T1>(domain: T0, mapping: T1) -> Self { self }
    func chartSymbolScale<T0>(domain: T0) -> Self { self }
    func chartSymbolScale<T0>(mapping: T0) -> Self { self }
    func chartSymbolScale<T0>(_ p0: T0) -> Self { self }
    func chartAngleSelection<T0>(value: T0) -> Self { self }
    func chartLineStyleScale<T0>(range: T0) -> Self { self }
    func chartLineStyleScale<T0, T1>(domain: T0, range: T1) -> Self { self }
    func chartLineStyleScale<T0, T1>(domain: T0, mapping: T1) -> Self { self }
    func chartLineStyleScale<T0>(domain: T0) -> Self { self }
    func chartLineStyleScale<T0>(mapping: T0) -> Self { self }
    func chartLineStyleScale<T0>(_ p0: T0) -> Self { self }
    func chartScrollPosition<T0>(x: T0) -> Self { self }
    func chartScrollPosition<T0>(y: T0) -> Self { self }
    func chartScrollPosition<T0>(initialX: T0) -> Self { self }
    func chartScrollPosition<T0>(initialY: T0) -> Self { self }
    func chartScrollableAxes<T0>(_ p0: T0) -> Self { self }
    func chartXVisibleDomain<T0>(length: T0) -> Self { self }
    func chartYVisibleDomain<T0>(length: T0) -> Self { self }
    func chartSymbolSizeScale<T0>(type: T0) -> Self { self }
    func chartSymbolSizeScale<T0, T1>(range: T0, type: T1) -> Self { self }
    func chartSymbolSizeScale<T0, T1>(domain: T0, type: T1) -> Self { self }
    func chartSymbolSizeScale<T0, T1, T2>(domain: T0, range: T1, type: T2) -> Self { self }
    func chartSymbolSizeScale<T0, T1>(domain: T0, mapping: T1) -> Self { self }
    func chartSymbolSizeScale<T0>(mapping: T0) -> Self { self }
    func chartSymbolSizeScale<T0>(_ p0: T0) -> Self { self }
    func chart3DCameraProjection<T0>(_ p0: T0) -> Self { self }
    func chartForegroundStyleScale<T0>(type: T0) -> Self { self }
    func chartForegroundStyleScale<T0, T1>(range: T0, type: T1) -> Self { self }
    func chartForegroundStyleScale<T0, T1>(domain: T0, type: T1) -> Self { self }
    func chartForegroundStyleScale<T0, T1, T2>(domain: T0, range: T1, type: T2) -> Self { self }
    func chartForegroundStyleScale<T0, T1>(domain: T0, mapping: T1) -> Self { self }
    func chartForegroundStyleScale<T0>(mapping: T0) -> Self { self }
    func chartForegroundStyleScale<T0>(_ p0: T0) -> Self { self }
    func chartScrollTargetBehavior<T0>(_ p0: T0) -> Self { self }
}
