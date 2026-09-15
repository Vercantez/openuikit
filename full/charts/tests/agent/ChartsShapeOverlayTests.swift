import Foundation
@_spi(OpenUIKitHost) import Charts

// Identity Shape overlays on Charts-owned symbol shapes. Linux has no
// SwiftUI renderer; these calls pin the no-op identity behavior without
// inventing renderer output. `offset` and `layoutDirectionBehavior` share
// the existing View no-op stubs and are cited from
// `testViewOverlayBatch01`, which already calls those bases on both
// shapes; `fill` / `size` / `stroke` / `transform` resolve to the
// Shape-specific identity stubs in `ChartsShapeOverlay.swift`.

private func shapeOverlayRect() -> CGRect {
    CGRect(x: 0, y: 0, width: 10, height: 10)
}

func testShapeOverlayFill() {
    let erased = AnyChartSymbolShape(.circle)
    let concrete = BasicChartSymbolShape.circle
    _ = erased.fill()
    _ = concrete.fill()
    precondition(erased.fill().path(in: shapeOverlayRect()) == erased.path(in: shapeOverlayRect()))
    precondition(concrete.fill().path(in: shapeOverlayRect()) == concrete.path(in: shapeOverlayRect()))
}

func testShapeOverlaySize() {
    let erased = AnyChartSymbolShape(.square)
    let concrete = BasicChartSymbolShape.square
    _ = erased.size()
    _ = concrete.size()
    precondition(erased.size().path(in: shapeOverlayRect()) == erased.path(in: shapeOverlayRect()))
    precondition(concrete.size().path(in: shapeOverlayRect()) == concrete.path(in: shapeOverlayRect()))
}

func testShapeOverlayStroke() {
    let erased = AnyChartSymbolShape(.triangle)
    let concrete = BasicChartSymbolShape.triangle
    _ = erased.stroke()
    _ = concrete.stroke()
    precondition(erased.stroke().path(in: shapeOverlayRect()) == erased.path(in: shapeOverlayRect()))
    precondition(concrete.stroke().path(in: shapeOverlayRect()) == concrete.path(in: shapeOverlayRect()))
}

func testShapeOverlayTransform() {
    let erased = AnyChartSymbolShape(.diamond)
    let concrete = BasicChartSymbolShape.circle
    _ = erased.transform()
    _ = concrete.transform()
    precondition(erased.transform().path(in: shapeOverlayRect()) == erased.path(in: shapeOverlayRect()))
    precondition(concrete.transform().path(in: shapeOverlayRect()) == concrete.path(in: shapeOverlayRect()))
}

func testShapeOverlayBodyAndRole() {
    _ = AnyChartSymbolShape().body
    _ = BasicChartSymbolShape.circle.body
    precondition(AnyChartSymbolShape.role == ShapeRole.fill)
    precondition(BasicChartSymbolShape.role == ShapeRole.fill)
}
