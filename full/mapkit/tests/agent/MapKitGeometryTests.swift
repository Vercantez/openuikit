import MapKit

func testMapPointSizeEquality() {
    let a = MKMapPoint(x: 10, y: 20)
    let b = MKMapPoint(x: 10, y: 20)
    let c = MKMapPoint(x: 11, y: 20)
    precondition(a.x == 10 && a.y == 20)
    precondition(MKMapPointEqualToPoint(a, b))
    precondition(!MKMapPointEqualToPoint(a, c))
    precondition(a == b)
    precondition(a != c)
    _ = MKMapPoint()
    var hasher = Hasher()
    a.hash(into: &hasher)
    _ = hasher.finalize()
}

func testMapSizeWorld() {
    let world = MKMapSize.world
    precondition(world.width == 0x10000000)
    precondition(world.height == 0x10000000)
    let other = MKMapSize(width: 0x10000000, height: 0x10000000)
    precondition(MKMapSizeEqualToSize(world, other))
    precondition(MKMapSize() == MKMapSize(width: 0, height: 0))
    var hasher = Hasher()
    world.hash(into: &hasher)
    _ = hasher.finalize()
}

func testMapRectAlgebra() {
    let rect = MKMapRect(x: 10, y: 20, width: 30, height: 40)
    precondition(rect.minX == 10)
    precondition(rect.minY == 20)
    precondition(rect.midX == 25)
    precondition(rect.midY == 40)
    precondition(rect.maxX == 40)
    precondition(rect.maxY == 60)
    precondition(rect.width == 30)
    precondition(rect.height == 40)
    precondition(!rect.isEmpty)
    precondition(!rect.isNull)
    precondition(MKMapRect.null.isNull)
    precondition(MKMapRect.null.isEmpty)
    precondition(MKMapRect.world.width == 0x10000000)
    precondition(rect.contains(MKMapPoint(x: 10, y: 20)))
    precondition(!rect.contains(MKMapPoint(x: 40, y: 20)))
    let inner = MKMapRect(x: 12, y: 22, width: 8, height: 8)
    precondition(rect.contains(inner))
    precondition(rect.intersects(MKMapRect(x: 35, y: 55, width: 10, height: 10)))
    let overlap = rect.intersection(MKMapRect(x: 30, y: 50, width: 20, height: 20))
    precondition(!overlap.isNull)
    precondition(overlap.minX == 30)
    let united = rect.union(MKMapRect(x: 0, y: 0, width: 5, height: 5))
    precondition(united.minX == 0)
    let inset = rect.insetBy(dx: 2, dy: 3)
    precondition(inset.minX == 12)
    precondition(inset.width == 26)
    let offset = rect.offsetBy(dx: 5, dy: -5)
    precondition(offset.minX == 15)
    precondition(offset.minY == 15)
    precondition(MKMapRectEqualToRect(rect, MKMapRect(origin: MKMapPoint(x: 10, y: 20), size: MKMapSize(width: 30, height: 40))))
    precondition(!rect.spans180thMeridian)
    precondition(rect.remainder.isNull)
    let wrapping = MKMapRect(x: 0x10000000 - 10, y: 0, width: 20, height: 10)
    precondition(wrapping.spans180thMeridian)
    precondition(wrapping.remainder.minX == -10)
    var hasher = Hasher()
    rect.hash(into: &hasher)
    _ = hasher.finalize()
}

func testMapStringConversions() {
    let point = MKMapPoint(x: 1, y: 2)
    precondition(MKStringFromMapPoint(point) == "{1.0, 2.0}" || MKStringFromMapPoint(point).contains("1"))
    precondition(MKStringFromMapSize(MKMapSize(width: 3, height: 4)).contains("3"))
    precondition(MKStringFromMapRect(MKMapRect(x: 1, y: 2, width: 3, height: 4)).contains("1"))
}

func testMetersPerMapPoint() {
    let equator = MKMetersPerMapPointAtLatitude(0)
    let mid = MKMetersPerMapPointAtLatitude(60)
    precondition(equator > mid)
    precondition(equator > 0)
    let inverse = MKMapPointsPerMeterAtLatitude(0)
    precondition(abs(inverse * equator - 1) < 1e-9)
    let origin = MKMapPoint(x: 0, y: 0)
    let east = MKMapPoint(x: 1, y: 0)
    precondition(origin.distance(to: east) > 0)
}

func testCoordinateSpanAndTilePath() {
    let span = MKCoordinateSpan(latitudeDelta: 1.5, longitudeDelta: 2.5)
    precondition(span.latitudeDelta == 1.5)
    precondition(span.longitudeDelta == 2.5)
    precondition(MKCoordinateSpan() == MKCoordinateSpan(latitudeDelta: 0, longitudeDelta: 0))
    let path = MKTileOverlayPath(x: 3, y: 4, z: 5, contentScaleFactor: 2)
    precondition(path.x == 3 && path.y == 4 && path.z == 5)
    precondition(path.contentScaleFactor == 2)
    precondition(MKTileOverlayPath().contentScaleFactor == 1)
    var hasher = Hasher()
    span.hash(into: &hasher)
    path.hash(into: &hasher)
    _ = hasher.finalize()
}

func testRoadWidth() {
    let width = MKRoadWidthAtZoomScale(1)
    precondition(width == 2)
    precondition(MKRoadWidthAtZoomScale(0) == 0)
    let _: MKZoomScale = 1
}
