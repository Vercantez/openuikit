#if canImport(Glibc)
import Glibc
#endif
import Foundation
@_spi(OpenUIKitHost) import Vision

func testPointGeometry() {
    let origin = VNPoint.zero
    let point = VNPoint(x: 3, y: 4)
    visionExpectEqual(origin.distance(point), 5, "3-4-5 distance")
    visionExpectEqual(VNPoint.distance(origin, point), 5, "class distance")
    visionExpectEqual(point.location, CGPoint(x: 3, y: 4), "location")
    let fromLocation = VNPoint(location: CGPoint(x: 1, y: 2))
    visionExpectEqual(fromLocation.x, 1, "from location x")
    visionExpectEqual(fromLocation.y, 2, "from location y")
    let applied = VNPoint.apply(VNVector(xComponent: 3, yComponent: 4), to: origin)
    visionExpectEqual(applied.x, 3, "apply x")
    visionExpect(origin.isEqual(VNPoint.zero), "point equal")
    let copy = origin.copy() as! VNPoint
    visionExpectEqual(copy.x, 0, "point copy")
    visionExpect(VNPoint.supportsSecureCoding, "point coding")
    let detected = VNDetectedPoint(x: 1, y: 2, confidence: 0.5)
    visionExpectEqual(detected.confidence, 0.5, "detected point confidence")
}

func testVectorGeometry() {
    let vector = VNVector(xComponent: 3, yComponent: 4)
    visionExpectEqual(vector.length, 5, "vector length")
    visionExpectEqual(vector.squaredLength, 25, "vector squared")
    visionExpectEqual(vector.r, 5, "vector r")
    visionExpectEqual(VNVector.dotProduct(of: vector, vector: vector), 25, "dot product")
    let unit = VNVector.unitVector(for: vector)
    visionExpectEqual(unit.length, 1, "unit length")
    visionExpectEqual(VNVector.unitVector(for: .zero).length, 0, "zero unit")
    let polar = VNVector(r: 2, theta: 0)
    visionExpectEqual(polar.x, 2, "polar x")
    visionExpect(abs(polar.y) < 1e-12, "polar y")
    let head = VNPoint(x: 5, y: 5)
    let tail = VNPoint(x: 2, y: 1)
    let fromPoints = VNVector(vectorHead: head, tail: tail)
    visionExpectEqual(fromPoints.x, 3, "head-tail x")
    visionExpectEqual(fromPoints.y, 4, "head-tail y")
    let sum = VNVector(byAdding: vector, to: vector)
    visionExpectEqual(sum.x, 6, "add x")
    let scaled = VNVector(byMultiplying: vector, byScalar: 2)
    visionExpectEqual(scaled.y, 8, "scale y")
    let subtracted = VNVector(bySubtracting: vector, from: scaled)
    visionExpectEqual(subtracted.x, 3, "subtract x")
    let alias = VNVector(XComponent: 1, yComponent: 2)
    visionExpectEqual(alias.x, 1, "XComponent alias")
    visionExpectEqual(VNVector(byAddingVector: vector, toVector: vector).x, 6, "add alias")
    visionExpectEqual(VNVector(byMultiplyingVector: vector, byScalar: 3).x, 9, "multiply alias")
    visionExpectEqual(VNVector(bySubtractingVector: vector, fromVector: scaled).x, 3, "subtract alias")
    visionExpect(abs(vector.theta - atan2(4.0, 3.0)) < 1e-12, "theta")
    visionExpect(VNVector.supportsSecureCoding, "vector coding")
}

func testCircleGeometry() {
    let origin = VNPoint.zero
    let point = VNPoint(x: 3, y: 4)
    let circle = VNCircle(center: origin, radius: 5)
    visionExpect(circle.contains(point), "contains hypotenuse")
    visionExpect(circle.contains(VNPoint(x: 5, y: 0)), "contains radius")
    visionExpect(!circle.contains(VNPoint(x: 5.1, y: 0)), "excludes outside")
    visionExpect(circle.contains(VNPoint(x: 5, y: 0), inCircumferentialRingOfWidth: 0.2), "ring on circumference")
    visionExpect(!circle.contains(VNPoint.zero, inCircumferentialRingOfWidth: 0.2), "ring excludes center")
    let diameterCircle = VNCircle(center: origin, diameter: 10)
    visionExpectEqual(diameterCircle.radius, 5, "diameter init")
    visionExpect(VNCircle.zero.contains(VNPoint.zero), "zero circle")
}

func testMinimumEnclosingCircle() {
    do {
        _ = try VNGeometryUtils.boundingCircle(for: [VNPoint]())
        visionExpect(false, "empty MEC")
    } catch {
        visionExpect(true, "empty throws")
    }

    let single = try! VNGeometryUtils.boundingCircle(for: [VNPoint(x: 1, y: 2)])
    visionExpectEqual(single.radius, 0, "singleton radius")
    visionExpectEqual(single.center.x, 1, "singleton x")

    let duplicates = try! VNGeometryUtils.boundingCircle(
        for: [VNPoint(x: 1, y: 1), VNPoint(x: 1, y: 1)]
    )
    visionExpectEqual(duplicates.radius, 0, "duplicate radius")

    let pair = try! VNGeometryUtils.boundingCircle(
        for: [VNPoint(x: 0, y: 0), VNPoint(x: 4, y: 0)]
    )
    visionExpectEqual(pair.radius, 2, "pair radius")
    visionExpectEqual(pair.center.x, 2, "pair center")

    let collinear = try! VNGeometryUtils.boundingCircle(
        for: [VNPoint(x: 0, y: 0), VNPoint(x: 1, y: 0), VNPoint(x: 4, y: 0)]
    )
    visionExpectEqual(collinear.radius, 2, "collinear radius")

    let obtuse = try! VNGeometryUtils.boundingCircle(
        for: [VNPoint(x: 0, y: 0), VNPoint(x: 4, y: 0), VNPoint(x: 0.1, y: 0.1)]
    )
    visionExpectEqual(obtuse.radius, 2, "obtuse uses longest side")

    let acute = [
        VNPoint(x: 0, y: 0),
        VNPoint(x: 2, y: 0),
        VNPoint(x: 1, y: sqrt(3)),
    ]
    let mec = try! VNGeometryUtils.boundingCircle(for: acute)
    visionExpect(abs(mec.radius - 2 / sqrt(3)) < 1e-9, "acute circumradius")
    for point in acute {
        visionExpect(mec.contains(point), "acute containment")
    }
    let boxRadius = hypot(1.0, sqrt(3) / 2)
    visionExpect(mec.radius < boxRadius - 1e-9, "smaller than bounding-box approximation")
    let reversed = try! VNGeometryUtils.boundingCircle(for: acute.reversed())
    visionExpect(abs(reversed.radius - mec.radius) < 1e-9, "order invariance radius")
    let simdPoints: [SIMD2<Float>] = [
        SIMD2<Float>(0, 0),
        SIMD2<Float>(2, 0),
        SIMD2<Float>(1, Float(sqrt(3))),
    ]
    let simdCircle = try! simdPoints.withUnsafeBufferPointer { buffer in
        try VNGeometryUtils.boundingCircle(
            forSIMDPoints: buffer.baseAddress!,
            pointCount: buffer.count
        )
    }
    visionExpect(abs(simdCircle.radius - mec.radius) < 1e-5, "simd MEC")
}

func testContourMetrics() {
    let square = VNContour(normalizedPoints: [
        SIMD2<Float>(0, 0),
        SIMD2<Float>(1, 0),
        SIMD2<Float>(1, 1),
        SIMD2<Float>(0, 1),
    ])
    visionExpectEqual(square.pointCount, 4, "point count")
    visionExpectEqual(square.aspectRatio, 1, "aspect")
    var area: Double = 0
    try! VNGeometryUtils.calculateArea(&area, for: square, orientedArea: false)
    visionExpectEqual(area, 1, "square area")
    var signed: Double = 0
    try! VNGeometryUtils.calculateArea(&signed, for: square, orientedArea: true)
    visionExpectEqual(signed, 1, "oriented ccw")
    var perimeter: Double = 0
    try! VNGeometryUtils.calculatePerimeter(&perimeter, for: square)
    visionExpectEqual(perimeter, 4, "square perimeter")
    let child = VNContour(normalizedPoints: [SIMD2<Float>(0.2, 0.2), SIMD2<Float>(0.3, 0.2)])
    let parent = VNContour(
        normalizedPoints: square.normalizedPoints,
        indexPath: IndexPath(index: 0),
        childContours: [child]
    )
    visionExpectEqual(parent.childContourCount, 1, "child count")
    visionExpectEqual(try! parent.childContour(at: 0).pointCount, 2, "child fetch")
    do {
        _ = try parent.childContour(at: 3)
        visionExpect(false, "child oob")
    } catch {
        visionExpect(true, "child oob throws")
    }
    let circle = try! VNGeometryUtils.boundingCircle(for: square)
    visionExpect(circle.contains(VNPoint(x: 0.5, y: 0.5)), "contour circle contains center")
    let jagged = VNContour(normalizedPoints: [
        SIMD2<Float>(0, 0),
        SIMD2<Float>(0.5, 0.0001),
        SIMD2<Float>(1, 0),
    ])
    let approx = try! jagged.polygonApproximation(epsilon: 0.01)
    visionExpectEqual(approx.pointCount, 2, "dp collapsed colinear")
}

func testCoordinateMapping() {
    visionExpect(VNNormalizedRectIsIdentityRect(VNNormalizedIdentityRect), "identity rect")
    visionExpect(!VNNormalizedRectIsIdentityRect(CGRect(x: 0, y: 0, width: 1, height: 0.5)), "not identity")
    let imagePoint = VNImagePointForNormalizedPoint(CGPoint(x: 0.25, y: 0.5), 200, 100)
    visionExpectEqual(imagePoint, CGPoint(x: 50, y: 50), "norm to image")
    let back = VNNormalizedPointForImagePoint(imagePoint, 200, 100)
    visionExpectEqual(back, CGPoint(x: 0.25, y: 0.5), "image to norm")
    let imageRect = VNImageRectForNormalizedRect(CGRect(x: 0.1, y: 0.2, width: 0.25, height: 0.5), 100, 200)
    visionExpectEqual(imageRect.origin, CGPoint(x: 10, y: 40), "rect origin")
    visionExpectEqual(imageRect.size, CGSize(width: 25, height: 100), "rect size")
    let normalizedBack = VNNormalizedRectForImageRect(imageRect, 100, 200)
    visionExpect(abs(normalizedBack.origin.x - 0.1) < 1e-9, "rect back x")
    let roiPoint = VNImagePointForNormalizedPointUsingRegionOfInterest(
        CGPoint(x: 0.5, y: 0.5),
        100,
        100,
        CGRect(x: 0.2, y: 0.2, width: 0.4, height: 0.4)
    )
    visionExpect(abs(roiPoint.x - 40) < 1e-9 && abs(roiPoint.y - 40) < 1e-9, "roi point")
    let landmark = VNImagePointForFaceLandmarkPoint(
        SIMD2<Float>(0.5, 0.25),
        CGRect(x: 0.2, y: 0.2, width: 0.4, height: 0.4),
        100,
        100
    )
    visionExpect(abs(landmark.x - 40) < 1e-9 && abs(landmark.y - 30) < 1e-9, "landmark")
    let roiRect = VNImageRectForNormalizedRectUsingRegionOfInterest(
        CGRect(x: 0, y: 0, width: 1, height: 1),
        100,
        100,
        CGRect(x: 0.25, y: 0.25, width: 0.5, height: 0.5)
    )
    visionExpect(abs(roiRect.origin.x - 25) < 1e-9, "roi rect")
    let backROI = VNNormalizedRectForImageRectUsingRegionOfInterest(roiRect, 100, 100, CGRect(x: 0.25, y: 0.25, width: 0.5, height: 0.5))
    visionExpect(abs(backROI.width - 1) < 1e-9, "roi rect back")
}
