import Foundation

// Identity Shape overlays synthesized onto Charts-owned symbol shapes.
// Linux has no SwiftUI renderer; these compile as no-ops so the Shape
// census can be exercised without inventing renderer output.
// Compiled only when SwiftUI is absent (isolated host).

#if !canImport(SwiftUI)
extension AnyChartSymbolShape {
    public static let role = ShapeRole.fill

    public func fill(_ p0: Any? = nil) -> Self { self }
    public func size(_ p0: Any? = nil) -> Self { self }
    public func stroke(_ p0: Any? = nil) -> Self { self }
    public func transform(_ p0: Any? = nil) -> Self { self }
}

extension BasicChartSymbolShape {
    public func fill(_ p0: Any? = nil) -> Self { self }
    public func size(_ p0: Any? = nil) -> Self { self }
    public func stroke(_ p0: Any? = nil) -> Self { self }
    public func transform(_ p0: Any? = nil) -> Self { self }
}
#endif
