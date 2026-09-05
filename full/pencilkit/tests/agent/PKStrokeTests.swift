import PencilKit
import Foundation

func pkMakePoint(_ x: CGFloat, _ y: CGFloat, time: TimeInterval = 0, size: CGFloat = 4) -> PKStrokePoint {
    PKStrokePoint(
        location: CGPoint(x: x, y: y),
        timeOffset: time,
        size: CGSize(width: size, height: size),
        opacity: 1,
        force: 0.5,
        azimuth: 0,
        altitude: 0.5
    )
}

func testPKStrokePointDefaultsAndLerp() {
    let short = PKStrokePoint(
        location: CGPoint(x: 1, y: 2),
        timeOffset: 0.1,
        size: CGSize(width: 3, height: 4),
        opacity: 0.5,
        force: 0.2,
        azimuth: 0.3,
        altitude: 0.4
    )
    pkExpectEqual(short.secondaryScale, 1, "default secondary")
    pkExpectEqual(short.threshold, 0, "default threshold")
    let mid = PKStrokePoint(
        location: CGPoint(x: 1, y: 2),
        timeOffset: 0.1,
        size: CGSize(width: 3, height: 4),
        opacity: 0.5,
        force: 0.2,
        azimuth: 0.3,
        altitude: 0.4,
        secondaryScale: 2
    )
    pkExpectEqual(mid.threshold, 0, "threshold default")
    pkExpectEqual(mid.secondaryScale, 2, "secondary")
    let full = PKStrokePoint(
        location: .zero,
        timeOffset: 0,
        size: .zero,
        opacity: 1,
        force: 0,
        azimuth: 0,
        altitude: 0,
        secondaryScale: 1,
        threshold: 0.25
    )
    pkExpectEqual(full.threshold, 0.25, "threshold")
    let reference = PKStrokePointReference(
        location: CGPoint(x: 8, y: 9),
        timeOffset: 1,
        size: CGSize(width: 2, height: 3),
        opacity: 1,
        force: 1,
        azimuth: 0,
        altitude: 1,
        secondaryScale: 1,
        threshold: 0
    )
    pkExpectEqual(reference.location.x, 8, "ref x")
    pkExpectEqual(reference.timeOffset, 1, "ref time")
    _ = reference.altitude
    _ = reference.azimuth
    _ = reference.force
    _ = reference.opacity
    _ = reference.secondaryScale
    _ = reference.size
    _ = reference.threshold
}

func testPKStrokePathInterpolation() {
    let date = Date(timeIntervalSince1970: 42)
    let path = PKStrokePath(
        controlPoints: [pkMakePoint(0, 0), pkMakePoint(10, 0)],
        creationDate: date
    )
    pkExpectEqual(path.count, 2, "count")
    pkExpectEqual(path.creationDate, date, "date")
    pkExpectEqual(path.startIndex, 0, "start")
    pkExpectEqual(path.endIndex, 2, "end")
    pkExpectEqual(path[0].location.x, 0, "subscript")
    pkExpectEqual(path.point(at: 1).location.x, 10, "point(at:)")
    let mid = path.interpolatedPoint(at: 0.5)
    pkExpectEqual(mid.location.x, 5, "lerp x")
    pkExpectEqual(path.interpolatedLocation(at: 0.5).x, 5, "location")
    let empty = PKStrokePath()
    pkExpect(empty.isEmpty, "empty")
    pkExpectEqual(empty.interpolatedLocation(at: 0), .zero, "empty location")
}

func testPKStrokePathDistanceAndTimeOffset() {
    let path = PKStrokePath(
        controlPoints: [
            pkMakePoint(0, 0, time: 0),
            pkMakePoint(10, 0, time: 1),
        ],
        creationDate: Date(timeIntervalSince1970: 0)
    )
    let halfDistance = path.parametricValue(0, offsetByDistance: 5)
    pkExpect(abs(halfDistance - 0.5) < 0.001, "distance 5 -> 0.5, got \(halfDistance)")
    let halfTime = path.parametricValue(0, offsetByTime: 0.5)
    pkExpect(abs(halfTime - 0.5) < 0.001, "time 0.5 -> 0.5, got \(halfTime)")
    let stepped = path.parametricValue(0, offsetBy: .parametricStep(0.25))
    pkExpectEqual(stepped, 0.25, "parametric step")
}

func testPKStrokePathEnumerationStop() {
    let path = PKStrokePath(
        controlPoints: [pkMakePoint(0, 0), pkMakePoint(4, 0), pkMakePoint(8, 0)],
        creationDate: Date(timeIntervalSince1970: 0)
    )
    var seen = 0
    path.enumerateInterpolatedPoints(
        in: __PKFloatRange(location: 0, length: 2),
        strideByParametricStep: 1
    ) { _, stop in
        seen += 1
        stop.pointee = true
    }
    pkExpectEqual(seen, 1, "stop after first")
    var distanceCount = 0
    path.enumerateInterpolatedPoints(
        in: __PKFloatRange(closedRange: 0...2),
        strideByDistance: 4
    ) { _, _ in
        distanceCount += 1
    }
    pkExpect(distanceCount >= 1, "distance enumerate")
    var timeCount = 0
    path.enumerateInterpolatedPoints(
        in: __PKFloatRange(location: 0, length: 1),
        strideByTime: 10
    ) { _, _ in
        timeCount += 1
    }
    pkExpect(timeCount >= 1, "time enumerate")
}

func testPKStrokeRenderBoundsAndTransform() {
    let ink = PKInk(.pen, color: .black)
    let path = PKStrokePath(
        controlPoints: [pkMakePoint(10, 20, size: 4), pkMakePoint(30, 20, size: 4)],
        creationDate: Date(timeIntervalSince1970: 0)
    )
    let stroke = PKStroke(ink: ink, path: path, randomSeed: 7)
    pkExpectEqual(stroke.randomSeed, 7, "seed")
    pkExpectEqual(stroke.requiredContentVersion, .version1, "version")
    pkExpect(stroke.maskedPathRanges.isEmpty, "no mask ranges")
    pkExpect(stroke.renderBounds.width > 0, "bounds width")
    let translated = PKStroke(
        ink: ink,
        path: path,
        transform: PencilKitTransform(a: 1, b: 0, c: 0, d: 1, tx: 5, ty: 0)
    )
    pkExpect(translated.renderBounds.minX > stroke.renderBounds.minX - 0.01, "translated")
    pkExpect(stroke.mask == nil, "mask")
}

func testPKStrokeReferenceMembers() {
    let ink = PKInk(.pencil)
    let path = PKStrokePath(controlPoints: [pkMakePoint(0, 0)], creationDate: Date(timeIntervalSince1970: 1))
    let reference = PKStrokeReference(
        ink: ink,
        strokePath: path,
        transform: .identity,
        mask: nil,
        randomSeed: 3
    )
    pkExpectEqual(reference.randomSeed, 3, "seed")
    pkExpectEqual(reference.path.count, 1, "path")
    pkExpect(reference.mask == nil, "mask")
    pkExpect(reference.maskedPathRanges.isEmpty, "ranges")
    _ = reference.renderBounds
    _ = reference.requiredContentVersion
    _ = reference.transform
    _ = reference.ink
    let shorter = PKStrokeReference(
        ink: ink,
        strokePath: path,
        transform: .identity,
        mask: nil
    )
    pkExpectEqual(shorter.randomSeed, 0, "default seed")
}

func testPKStrokePathReference() {
    let points = [pkMakePoint(0, 0), pkMakePoint(2, 0)]
    let reference = PKStrokePathReference(
        controlPoints: points,
        creationDate: Date(timeIntervalSince1970: 9)
    )
    pkExpectEqual(reference.count, 2, "count")
    pkExpectEqual(reference.creationDate.timeIntervalSince1970, 9, "date")
    pkExpectEqual(reference[1].location.x, 2, "subscript")
    pkExpectEqual(reference.point(at: 0).location.x, 0, "point")
    pkExpectEqual(reference.interpolatedLocation(at: 0.5).x, 1, "interp")
    _ = reference.interpolatedPoint(at: 0)
    _ = reference.parametricValue(0, offsetByDistance: 1)
    _ = reference.parametricValue(0, offsetByTime: 1)
}
