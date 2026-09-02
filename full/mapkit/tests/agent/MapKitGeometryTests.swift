@_spi(MapKitHostTests) import MapKit
import Foundation
#if canImport(CoreLocation)
import CoreLocation
#endif

private func oracleClose(_ actual: Double, _ expected: Double, tolerance: Double = 1e-9) {
    precondition(abs(actual - expected) <= tolerance, "\(actual) != \(expected)")
}

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
    precondition(nullRect.minX == Double.infinity)
    precondition(nullRect.midX == Double.infinity)
    precondition(nullRect.maxX == Double.infinity)
    precondition(!nullRect.spans180thMeridian)

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

    let nanOrigin = MKMapRect(x: Double.nan, y: 20, width: 30, height: 40)
    let nanSize = MKMapRect(x: 10, y: 20, width: Double.nan, height: 40)
    let infiniteOrigin = MKMapRect(x: Double.infinity, y: 20, width: 30, height: 40)
    for unusual in [nanOrigin, nanSize, infiniteOrigin] {
        precondition(!unusual.isNull)
        precondition(!unusual.isEmpty)
    }
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

    let negative = MKMapRect(x: 40, y: 60, width: -30, height: -40)
    precondition(negative.minX == 40)
    precondition(negative.midX == 25)
    precondition(negative.maxX == 10)
    precondition(negative.minY == 60)
    precondition(negative.midY == 40)
    precondition(negative.maxY == 20)
    precondition(!negative.isNull)
    precondition(!negative.isEmpty)
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

    let edgeTouch = MKMapRect(x: 10, y: 2, width: 4, height: 6)
    precondition(!a.intersects(edgeTouch))
    let edgeIntersection = a.intersection(edgeTouch)
    precondition(!edgeIntersection.isNull)
    precondition(edgeIntersection.isEmpty)
    precondition(edgeIntersection.origin.x == 10)
    precondition(edgeIntersection.origin.y == 2)
    precondition(edgeIntersection.size.width == 0)
    precondition(edgeIntersection.size.height == 6)

    let ordinary = MKMapRect(x: 10, y: 20, width: 30, height: 40)
    let negativeWidth = MKMapRect(x: 40, y: 20, width: -30, height: 40)
    let interior = MKMapRect(x: 15, y: 30, width: 10, height: 10)
    precondition(!negativeWidth.intersects(interior))
    precondition(negativeWidth.intersection(interior).isNull)
    precondition(MKMapRectEqualToRect(ordinary.union(negativeWidth), ordinary))
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

    let negativeWidth = MKMapRect(x: 40, y: 20, width: -30, height: 40)
    precondition(!negativeWidth.contains(MKMapPoint(x: 25, y: 40)))
    precondition(!negativeWidth.contains(MKMapPoint(x: 40, y: 20)))
    precondition(!negativeWidth.contains(MKMapPoint(x: 10, y: 60)))
    precondition(!negativeWidth.contains(MKMapRect(x: 15, y: 30, width: 10, height: 10)))
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
    let leftSpanning = MKMapRect(x: -5, y: 0, width: 10, height: 10)
    precondition(leftSpanning.spans180thMeridian)
    let leftRemainder = leftSpanning.remainder
    precondition(leftRemainder.origin.x == 268_435_451)
    precondition(leftRemainder.origin.y == 0)
    precondition(leftRemainder.size.width == 5)
    precondition(leftRemainder.size.height == 10)
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

    let oracleRect = MKMapRect(x: 10, y: 20, width: 30, height: 40)
    MKMapRectDivide(oracleRect, &slice, &rest, -1, .minXEdge)
    precondition(MKMapRectEqualToRect(slice, MKMapRect(x: 10, y: 20, width: 0, height: 40)))
    precondition(MKMapRectEqualToRect(rest, oracleRect))
    MKMapRectDivide(oracleRect, &slice, &rest, Double.infinity, .maxXEdge)
    precondition(MKMapRectEqualToRect(slice, oracleRect))
    precondition(MKMapRectEqualToRect(rest, MKMapRect(x: 10, y: 20, width: 0, height: 40)))
    MKMapRectDivide(oracleRect, &slice, &rest, 300, .minYEdge)
    precondition(MKMapRectEqualToRect(slice, oracleRect))
    precondition(MKMapRectEqualToRect(rest, MKMapRect(x: 10, y: 60, width: 30, height: 0)))

    MKMapRectDivide(oracleRect, &slice, &rest, Double.nan, .minXEdge)
    precondition(slice.origin.x == 10 && slice.origin.y == 20)
    precondition(slice.size.width.isNaN && slice.size.height == 40)
    precondition(rest.origin.x.isNaN && rest.origin.y == 20)
    precondition(rest.size.width.isNaN && rest.size.height == 40)
    MKMapRectDivide(oracleRect, &slice, &rest, Double.nan, .maxXEdge)
    precondition(slice.origin.x.isNaN && slice.origin.y == 20)
    precondition(slice.size.width.isNaN && slice.size.height == 40)
    precondition(rest.origin.x == 10 && rest.origin.y == 20)
    precondition(rest.size.width.isNaN && rest.size.height == 40)
    MKMapRectDivide(oracleRect, &slice, &rest, Double.nan, .minYEdge)
    precondition(slice.origin.x == 10 && slice.origin.y == 20)
    precondition(slice.size.width == 30 && slice.size.height.isNaN)
    precondition(rest.origin.x == 10 && rest.origin.y.isNaN)
    precondition(rest.size.width == 30 && rest.size.height.isNaN)
    MKMapRectDivide(oracleRect, &slice, &rest, Double.nan, .maxYEdge)
    precondition(slice.origin.x == 10 && slice.origin.y.isNaN)
    precondition(slice.size.width == 30 && slice.size.height.isNaN)
    precondition(rest.origin.x == 10 && rest.origin.y == 20)
    precondition(rest.size.width == 30 && rest.size.height.isNaN)
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

private func assertProjectionOracle() {
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

    let equator = MKMapProjection.point(latitude: 0, longitude: 0)
    precondition(equator.x == 134_217_728)
    precondition(equator.y == 134_217_728)
    let north85 = MKMapProjection.point(latitude: 85, longitude: 0)
    let south85 = MKMapProjection.point(latitude: -85, longitude: 0)
    oracleClose(north85.y, 439_674.402_483_537_79, tolerance: 1e-6)
    oracleClose(south85.y, 267_995_781.597_516_48, tolerance: 1e-6)
    precondition(MKMapPointEqualToPoint(MKMapProjection.point(latitude: 90, longitude: 0), north85))
    precondition(MKMapPointEqualToPoint(MKMapProjection.point(latitude: -90, longitude: 0), south85))
    precondition(MKMapProjection.point(latitude: 0, longitude: -180).x == 0)
    precondition(MKMapProjection.point(latitude: 0, longitude: 180).x == 268_435_456)
    precondition(MKMapPointEqualToPoint(
        MKMapProjection.point(latitude: 0, longitude: 360),
        MKMapPoint(x: -1, y: -1)
    ))
    precondition(MKMapPointEqualToPoint(
        MKMapProjection.point(latitude: Double.nan, longitude: 0),
        MKMapPoint(x: -1, y: -1)
    ))
    let invalidBack = MKMapProjection.coordinate(for: MKMapPoint(x: -1, y: -1))
    oracleClose(invalidBack.latitude, 85.051_128_895_499_303, tolerance: 1e-12)
    oracleClose(invalidBack.longitude, 179.999_998_658_895_49, tolerance: 1e-12)
}

func testDistanceSymmetryAndLatitudeScale() {
    assertProjectionOracle()
    let a = MKMapProjection.point(latitude: 0, longitude: 0)
    let b = MKMapPoint(x: a.x + 1, y: a.y)
    let ab = a.distance(to: b)
    let ba = b.distance(to: a)
    precondition(ab.isFinite)
    precondition(abs(ab - ba) < 1e-6)
    oracleClose(ab, 0.149_291_609_223_338_03, tolerance: 1e-6)

    let equatorMeters = MKMetersPerMapPointAtLatitude(0)
    let midMeters = MKMetersPerMapPointAtLatitude(60)
    oracleClose(equatorMeters, 0.148_289_773_337_725_44, tolerance: 1e-15)
    oracleClose(midMeters, 0.074_701_090_708_174_683, tolerance: 1e-15)
    oracleClose(MKMapPointsPerMeterAtLatitude(0), 6.743_553_365_089_650_4, tolerance: 1e-12)
    oracleClose(MKMapPointsPerMeterAtLatitude(60), 13.386_685_395_352_174, tolerance: 1e-12)
    oracleClose(MKMetersPerMapPointAtLatitude(90), 0.254_037_220_797_636_08, tolerance: 1e-15)
    oracleClose(MKMapPointsPerMeterAtLatitude(90), 3.936_431_035_027_704_1, tolerance: 1e-12)
    oracleClose(MKMetersPerMapPointAtLatitude(-90), 0.000_416_774_906_744_502_91, tolerance: 1e-18)
    oracleClose(MKMapPointsPerMeterAtLatitude(-90), 2_399.376_699_070_402_1, tolerance: 1e-9)
    precondition(MKMetersPerMapPointAtLatitude(Double.nan).isNaN)
    precondition(MKMetersPerMapPointAtLatitude(Double.infinity).isNaN)
    precondition(MKMapPoint(x: Double.nan, y: 0).distance(to: b).isNaN)
}
