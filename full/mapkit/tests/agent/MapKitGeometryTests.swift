@_spi(MapKitHostTests) import MapKit
import Foundation

func testCoordinateSpanStorage() {
    let span = MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 1.25)
    precondition(span.latitudeDelta == 0.5)
    precondition(span.longitudeDelta == 1.25)
}

func testMapRectNullEmptyWorld() {
    let nullRect = MKMapRect.null
    precondition(nullRect.isNull)
    precondition(nullRect.isEmpty)
    precondition(nullRect.origin.x.isInfinite)
    precondition(nullRect.origin.y.isInfinite)
    precondition(nullRect.size.width == 0)
    precondition(nullRect.size.height == 0)

    let empty = MKMapRect(x: 10, y: 20, width: 0, height: 5)
    precondition(empty.isEmpty)
    precondition(!empty.isNull)

    let world = MKMapRect.world
    precondition(!world.isNull)
    precondition(!world.isEmpty)
    precondition(world.origin.x == 0)
    precondition(world.origin.y == 0)
    precondition(MKMapSizeEqualToSize(world.size, MKMapSize.world))
    precondition(MKMapSize.world.width == 268_435_456)
    precondition(MKMapSize.world.height == 268_435_456)
}

func testMapRectInitAndEdges() {
    let rect = MKMapRect(x: 10, y: 20, width: 30, height: 40)
    precondition(rect.origin.x == 10)
    precondition(rect.origin.y == 20)
    precondition(rect.size.width == 30)
    precondition(rect.size.height == 40)
    precondition(rect.minX == 10)
    precondition(rect.minY == 20)
    precondition(rect.maxX == 40)
    precondition(rect.maxY == 60)
    precondition(rect.midX == 25)
    precondition(rect.midY == 40)
    precondition(rect.width == 30)
    precondition(rect.height == 40)
    let made = MKMapRect(origin: MKMapPoint(x: 1, y: 2), size: MKMapSize(width: 3, height: 4))
    precondition(made.origin.x == 1)
    precondition(made.size.height == 4)
}

func testMapRectNegativeDimensions() {
    let rect = MKMapRect(x: 50, y: 50, width: -20, height: -10)
    precondition(rect.minX == 50)
    precondition(rect.maxX == 30)
    precondition(rect.minY == 50)
    precondition(rect.maxY == 40)
    precondition(rect.contains(MKMapPoint(x: 40, y: 45)))
    precondition(!rect.contains(MKMapPoint(x: 51, y: 45)))
}

func testMapRectIntersectionUnion() {
    let a = MKMapRect(x: 0, y: 0, width: 10, height: 10)
    let b = MKMapRect(x: 5, y: 5, width: 10, height: 10)
    let overlap = a.intersection(b)
    precondition(overlap.origin.x == 5)
    precondition(overlap.origin.y == 5)
    precondition(overlap.size.width == 5)
    precondition(overlap.size.height == 5)
    precondition(a.intersects(b))
    let combined = a.union(b)
    precondition(combined.origin.x == 0)
    precondition(combined.size.width == 15)
    precondition(combined.size.height == 15)

    let miss = MKMapRect(x: 100, y: 100, width: 1, height: 1)
    precondition(a.intersection(miss).isNull)
    precondition(!a.intersects(miss))
    precondition(MKMapRect.null.union(a).origin.x == 0)
    precondition(a.union(.null).size.width == 10)
    precondition(MKMapRect.null.intersection(a).isNull)
}

func testMapRectInsetOffset() {
    let rect = MKMapRect(x: 10, y: 10, width: 20, height: 20)
    let inset = rect.insetBy(dx: 2, dy: 3)
    precondition(inset.origin.x == 12)
    precondition(inset.origin.y == 13)
    precondition(inset.size.width == 16)
    precondition(inset.size.height == 14)
    let offset = rect.offsetBy(dx: 5, dy: -4)
    precondition(offset.origin.x == 15)
    precondition(offset.origin.y == 6)
    precondition(offset.size.width == 20)
    let overInset = rect.insetBy(dx: 30, dy: 0)
    precondition(overInset.size.width < 0)
    precondition(MKMapRect.null.insetBy(dx: 1, dy: 1).isNull)
    precondition(MKMapRect.null.offsetBy(dx: 1, dy: 1).isNull)
}

func testMapRectContains() {
    let rect = MKMapRect(x: 0, y: 0, width: 10, height: 10)
    precondition(rect.contains(MKMapPoint(x: 0, y: 0)))
    precondition(rect.contains(MKMapPoint(x: 10, y: 10)))
    precondition(rect.contains(MKMapPoint(x: 5, y: 5)))
    precondition(!rect.contains(MKMapPoint(x: -0.1, y: 5)))
    let inner = MKMapRect(x: 1, y: 1, width: 2, height: 2)
    precondition(rect.contains(inner))
    precondition(!inner.contains(rect))
    let empty = MKMapRect(x: 3, y: 3, width: 0, height: 0)
    precondition(rect.contains(empty))
}

func testMapRectSpans180thMeridian() {
    let world = MKMapRect.world
    precondition(!world.spans180thMeridian)
    precondition(world.remainder.isNull)
    let spanning = MKMapRect(
        x: MKMapSize.world.width - 10,
        y: 0,
        width: 25,
        height: 10
    )
    precondition(spanning.spans180thMeridian)
    let remainder = spanning.remainder
    precondition(!remainder.isNull)
    precondition(remainder.origin.x == 0)
    precondition(remainder.size.width == 15)
    let interior = MKMapRect(x: 10, y: 10, width: 20, height: 20)
    precondition(!interior.spans180thMeridian)
}

func testMapRectDivide() {
    var slice = MKMapRect.null
    var rest = MKMapRect.null
    let rect = MKMapRect(x: 0, y: 0, width: 10, height: 8)
    MKMapRectDivide(rect, &slice, &rest, 3, .minXEdge)
    precondition(slice.size.width == 3)
    precondition(rest.origin.x == 3)
    precondition(rest.size.width == 7)
    MKMapRectDivide(rect, &slice, &rest, 2, .maxYEdge)
    precondition(slice.origin.y == 6)
    precondition(slice.size.height == 2)
    precondition(rest.size.height == 6)
    MKMapRectDivide(.null, &slice, &rest, 1, .minYEdge)
    precondition(slice.isNull)
    precondition(rest.isNull)
}

func testMapPointAndSizeEquality() {
    let p1 = MKMapPoint(x: 1, y: 2)
    let p2 = MKMapPoint(x: 1, y: 2)
    let p3 = MKMapPoint(x: 1, y: 3)
    precondition(MKMapPointEqualToPoint(p1, p2))
    precondition(!MKMapPointEqualToPoint(p1, p3))
    precondition(MKMapSizeEqualToSize(MKMapSize(width: 4, height: 5), MKMapSize(width: 4, height: 5)))
    precondition(MKMapRectEqualToRect(MKMapRect.null, MKMapRect.null))
    let r = MKMapRect(x: 1, y: 2, width: 3, height: 4)
    precondition(MKMapRectEqualToRect(r, r))
    precondition(!MKMapRectEqualToRect(r, .world))
}

func testGeometryStrings() {
    let point = MKMapPoint(x: 1.5, y: 2.5)
    let rendered = MKStringFromMapPoint(point)
    precondition(rendered.contains("1.5"))
    precondition(rendered.contains("2.5"))
    let sizeText = MKStringFromMapSize(MKMapSize(width: 3, height: 4))
    precondition(sizeText.contains("3.0") || sizeText.contains("3"))
    let rectText = MKStringFromMapRect(MKMapRect(x: 0, y: 0, width: 1, height: 1))
    precondition(rectText.contains("{"))
}

func testProjectionRoundTrip() {
    let samples: [(Double, Double)] = [
        (0, 0),
        (37.3349, -122.0090),
        (-33.8688, 151.2093),
        (51.5074, -0.1278),
        (64.1466, -21.9426),
        (-45.0, 170.0),
        (0, 179.9),
        (0, -179.9)
    ]
    for (lat, lon) in samples {
        let point = MKMapProjection.point(latitude: lat, longitude: lon)
        let back = MKMapProjection.coordinate(for: point)
        precondition(abs(back.latitude - lat) < 1e-6, "lat round trip \(lat)")
        let lonError = min(abs(back.longitude - lon), 360 - abs(back.longitude - lon))
        precondition(lonError < 1e-6, "lon round trip \(lon)")
    }
}

func testDistanceSymmetryAndLatitudeScale() {
    let a = MKMapProjection.point(latitude: 0, longitude: 0)
    let b = MKMapProjection.point(latitude: 0, longitude: 1)
    let ab = a.distance(to: b)
    let ba = b.distance(to: a)
    precondition(ab.isFinite)
    precondition(abs(ab - ba) < 1e-6)
    let equator = MKMetersPerMapPointAtLatitude(0)
    let mid = MKMetersPerMapPointAtLatitude(60)
    precondition(equator > mid)
    precondition(abs(MKMapPointsPerMeterAtLatitude(0) * equator - 1) < 1e-9)
}

func testNaNInfinityPolicy() {
    let nanPoint = MKMapPoint(x: Double.nan, y: 0)
    precondition(nanPoint.distance(to: MKMapPoint(x: 1, y: 1)).isNaN)
    let infRect = MKMapRect(
        origin: MKMapPoint(x: Double.infinity, y: 0),
        size: MKMapSize(width: 1, height: 1)
    )
    precondition(infRect.isNull)
    precondition(infRect.isEmpty)
    let nanLat = MKMetersPerMapPointAtLatitude(Double.nan)
    precondition(nanLat.isNaN)
    let infInset = MKMapRect.world.insetBy(dx: Double.nan, dy: 0)
    precondition(infInset.isNull)
    precondition(!MKMapPointEqualToPoint(MKMapPoint(x: Double.nan, y: 0), MKMapPoint(x: Double.nan, y: 0)))
}
