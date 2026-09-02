import XCTest
@testable import OpenCoreGraphics

private typealias CGFloat = OpenCoreGraphics.CGFloat
private typealias CGRect = OpenCoreGraphics.CGRect
private typealias CGAffineTransform = OpenCoreGraphics.CGAffineTransform

private struct Pixel: Equatable {
    let r: UInt8
    let g: UInt8
    let b: UInt8
    let a: UInt8

    init(_ r: UInt8, _ g: UInt8, _ b: UInt8, _ a: UInt8) {
        self.r = r
        self.g = g
        self.b = b
        self.a = a
    }
}

@MainActor
final class CanvasBackdropFilterTests: XCTestCase {
    private var savedBackend = CanvasBackendSelection.current

    override func setUp() {
        super.setUp()
        savedBackend = CanvasBackendSelection.current
    }

    override func tearDown() {
        CanvasBackendSelection.current = savedBackend
        super.tearDown()
    }

    private func pixel(_ bitmap: Bitmap, x: Int, y: Int)
        -> Pixel {
        let offset = (y * bitmap.width + x) * 4
        return Pixel(bitmap.pixels[offset], bitmap.pixels[offset + 1],
                     bitmap.pixels[offset + 2], bitmap.pixels[offset + 3])
    }

    private func setPixel(_ bitmap: Bitmap, x: Int, y: Int,
                          _ value: (UInt8, UInt8, UInt8, UInt8)) {
        let offset = (y * bitmap.width + x) * 4
        bitmap.pixels[offset] = value.0
        bitmap.pixels[offset + 1] = value.1
        bitmap.pixels[offset + 2] = value.2
        bitmap.pixels[offset + 3] = value.3
    }

    private func forEachBackend(_ body: (RenderBackend) -> Void) {
        for backend in [RenderBackend.swift, .quartz] {
            CanvasBackendSelection.current = backend
            body(backend)
        }
    }

    func testCheckerBlurHasExactDeterministicKernel() {
        forEachBackend { backend in
            let bitmap = Bitmap(width: 7, height: 1)
            for x in 0..<7 {
                let value: UInt8 = x.isMultiple(of: 2) ? 0 : 255
                setPixel(bitmap, x: x, y: 0, (value, value, value, 255))
            }
            let canvas = Canvas(bitmap: bitmap, scale: 1)
            canvas.applyBackdropFilter(
                CanvasBackdropFilterConfiguration(blurRadius: 1),
                in: CGRect(x: 0, y: 0, width: 7, height: 1))

            let expected: [UInt8] = [85, 85, 170, 85, 170, 85, 85]
            XCTAssertEqual((0..<7).map { pixel(bitmap, x: $0, y: 0).r },
                           expected, "\(backend)")
            XCTAssertTrue((0..<7).allSatisfy {
                let p = pixel(bitmap, x: $0, y: 0)
                return p.r == p.g && p.g == p.b && p.a == 255
            }, "\(backend)")
        }
    }

    func testVariableMaskSelectsSpatialRadiusRatherThanFilterOpacity() throws {
        forEachBackend { backend in
            let bitmap = Bitmap(width: 31, height: 1)
            for x in 0..<31 {
                let value: UInt8 = x.isMultiple(of: 2) ? 0 : 255
                setPixel(bitmap, x: x, y: 0, (value, value, value, 255))
            }
            let original = bitmap.pixels
            // A long zero plateau proves those pixels stay byte-identical;
            // the ramp then selects progressively larger convolution radii.
            let mask = try! XCTUnwrap(CanvasBackdropFilterMask(
                width: 5, height: 1, alpha: [0, 0, 64, 160, 255]))
            Canvas(bitmap: bitmap, scale: 1).applyBackdropFilter(
                CanvasBackdropFilterConfiguration(
                    blurRadius: 4,
                    blurMask: mask,
                    normalizesMaskEdges: true),
                in: CGRect(x: 0, y: 0, width: 31, height: 1))

            XCTAssertEqual(Array(bitmap.pixels[0..<(6 * 4)]),
                           Array(original[0..<(6 * 4)]), "\(backend)")
            let blurredTail = (24..<31).map { pixel(bitmap, x: $0, y: 0).r }
            XCTAssertTrue(blurredTail.allSatisfy { $0 > 0 && $0 < 255 },
                          "opaque mask edge must select a real blur (\(backend))")
            XCTAssertNotEqual(pixel(bitmap, x: 16, y: 0),
                              pixel(bitmap, x: 24, y: 0),
                              "different alpha values must select different radii (\(backend))")
        }
    }

    func testOpaqueVariableMaskIsExactlyUniformFastPath() throws {
        forEachBackend { backend in
            @MainActor func fixture() -> Bitmap {
                let bitmap = Bitmap(width: 17, height: 7)
                for y in 0..<7 { for x in 0..<17 {
                    setPixel(bitmap, x: x, y: y,
                             (UInt8((x * 53 + y * 11) % 256),
                              UInt8((x * 7 + y * 67) % 256),
                              UInt8((x * 31 + y * 29) % 256), 255))
                } }
                return bitmap
            }
            let expected = fixture()
            Canvas(bitmap: expected, scale: 1).applyBackdropFilter(
                CanvasBackdropFilterConfiguration(blurRadius: 3),
                in: CGRect(x: 2, y: 1, width: 13, height: 5))

            let actual = fixture()
            let opaque = try! XCTUnwrap(CanvasBackdropFilterMask(
                width: 2, height: 2, alpha: [255, 255, 255, 255]))
            Canvas(bitmap: actual, scale: 1).applyBackdropFilter(
                CanvasBackdropFilterConfiguration(
                    blurRadius: 3, blurMask: opaque),
                in: CGRect(x: 2, y: 1, width: 13, height: 5))
            XCTAssertEqual(actual.pixels, expected.pixels, "\(backend)")
        }
    }

    func testBlurReadsExpandedBackdropAndWritesOnlyRequestedRegion() {
        forEachBackend { backend in
            let bitmap = Bitmap(width: 5, height: 1)
            for x in 0..<5 { setPixel(bitmap, x: x, y: 0, (0, 0, 0, 255)) }
            setPixel(bitmap, x: 1, y: 0, (255, 0, 0, 255))
            setPixel(bitmap, x: 3, y: 0, (0, 0, 255, 255))
            let before = bitmap.pixels
            let canvas = Canvas(bitmap: bitmap, scale: 1)
            canvas.applyBackdropFilter(
                CanvasBackdropFilterConfiguration(blurRadius: 1),
                in: CGRect(x: 2, y: 0, width: 1, height: 1))

            XCTAssertEqual(pixel(bitmap, x: 2, y: 0), Pixel(85, 0, 85, 255),
                           "expanded samples must influence the target (\(backend))")
            XCTAssertEqual(Array(bitmap.pixels[0..<8]), Array(before[0..<8]), "\(backend)")
            XCTAssertEqual(Array(bitmap.pixels[12..<20]), Array(before[12..<20]), "\(backend)")
        }
    }

    func testBoundedMultiPassBlurMatchesFullSurfaceSamplesInsideTarget() {
        forEachBackend { backend in
            @MainActor func fixture() -> Bitmap {
                let bitmap = Bitmap(width: 13, height: 9)
                for y in 0..<9 { for x in 0..<13 {
                    setPixel(bitmap, x: x, y: y,
                             (UInt8((x * 71 + y * 19) % 256),
                              UInt8((x * 13 + y * 83) % 256),
                              UInt8((x * 37 + y * 29) % 256), 255))
                } }
                return bitmap
            }

            let full = fixture()
            Canvas(bitmap: full, scale: 1).applyBackdropFilter(
                CanvasBackdropFilterConfiguration(blurRadius: 2.5),
                in: CGRect(x: 0, y: 0, width: 13, height: 9))

            let bounded = fixture()
            let original = bounded.pixels
            Canvas(bitmap: bounded, scale: 1).applyBackdropFilter(
                CanvasBackdropFilterConfiguration(blurRadius: 2.5),
                in: CGRect(x: 5, y: 3, width: 3, height: 2))

            for y in 3..<5 { for x in 5..<8 {
                XCTAssertEqual(pixel(bounded, x: x, y: y),
                               pixel(full, x: x, y: y), "\(backend) at \(x),\(y)")
            } }
            XCTAssertEqual(Array(bounded.pixels[0..<(3 * 13 * 4)]),
                           Array(original[0..<(3 * 13 * 4)]), "\(backend)")
        }
    }

    func testTransparentRGBCannotBleedAcrossBlur() {
        forEachBackend { backend in
            let bitmap = Bitmap(width: 3, height: 1)
            setPixel(bitmap, x: 0, y: 0, (255, 0, 0, 255))
            // Deliberately invalid hidden straight RGB: a straight-alpha blur
            // would leak blue, while a premultiplied blur must discard it.
            setPixel(bitmap, x: 1, y: 0, (0, 0, 255, 0))
            setPixel(bitmap, x: 2, y: 0, (0, 255, 0, 0))
            let canvas = Canvas(bitmap: bitmap, scale: 1)
            canvas.applyBackdropFilter(
                CanvasBackdropFilterConfiguration(blurRadius: 1),
                in: CGRect(x: 0, y: 0, width: 3, height: 1))

            XCTAssertEqual(pixel(bitmap, x: 0, y: 0), Pixel(255, 0, 0, 170), "\(backend)")
            XCTAssertEqual(pixel(bitmap, x: 1, y: 0), Pixel(255, 0, 0, 85), "\(backend)")
            XCTAssertEqual(pixel(bitmap, x: 2, y: 0), Pixel(0, 0, 0, 0), "\(backend)")
        }
    }

    func testCanvasEdgeUsesReplicationRatherThanTransparentPadding() {
        forEachBackend { backend in
            let bitmap = Bitmap(width: 4, height: 3)
            for y in 0..<3 { for x in 0..<4 {
                setPixel(bitmap, x: x, y: y, (20, 120, 240, 255))
            } }
            let before = bitmap.pixels
            let canvas = Canvas(bitmap: bitmap, scale: 1)
            canvas.applyBackdropFilter(
                CanvasBackdropFilterConfiguration(blurRadius: 3),
                in: CGRect(x: 0, y: 0, width: 2, height: 2))
            XCTAssertEqual(bitmap.pixels, before, "uniform edge must remain uniform (\(backend))")
        }
    }

    func testNonzeroOriginAndCurrentClipBoundWrites() {
        forEachBackend { backend in
            let bitmap = Bitmap(width: 8, height: 6)
            for y in 0..<6 { for x in 0..<8 {
                setPixel(bitmap, x: x, y: y, (0, 0, 255, 255))
            } }
            let canvas = Canvas(bitmap: bitmap, scale: 1)
            canvas.save()
            canvas.translate(x: 3, y: 2)
            canvas.clip(to: CGRect(x: 1, y: 0, width: 2, height: 2))
            canvas.applyBackdropFilter(
                CanvasBackdropFilterConfiguration(
                    tintColor: CGColor(red: 1, green: 0, blue: 0, alpha: 1)),
                in: CGRect(x: 0, y: 0, width: 4, height: 2))
            canvas.restore()

            XCTAssertEqual(pixel(bitmap, x: 4, y: 2), Pixel(255, 0, 0, 255), "\(backend)")
            XCTAssertEqual(pixel(bitmap, x: 5, y: 3), Pixel(255, 0, 0, 255), "\(backend)")
            XCTAssertEqual(pixel(bitmap, x: 3, y: 2), Pixel(0, 0, 255, 255), "\(backend)")
            XCTAssertEqual(pixel(bitmap, x: 6, y: 3), Pixel(0, 0, 255, 255), "\(backend)")
            XCTAssertEqual(pixel(bitmap, x: 4, y: 1), Pixel(0, 0, 255, 255), "\(backend)")
        }
    }

    func testSparseRotatedRegionPreservesZeroCoverageBytesAndBackendParity() {
        let rect = CGRect(x: -2, y: -0.4, width: 4, height: 0.8)
        var results: [[UInt8]] = []

        for backend in [RenderBackend.swift, .quartz] {
            CanvasBackendSelection.current = backend
            let bitmap = Bitmap(width: 5, height: 5)
            for index in 0..<(5 * 5) {
                bitmap.pixels[index * 4] = 20
                bitmap.pixels[index * 4 + 1] = 120
                bitmap.pixels[index * 4 + 2] = 240
                bitmap.pixels[index * 4 + 3] = 128
            }
            let before = bitmap.pixels
            let canvas = Canvas(bitmap: bitmap, scale: 1)
            canvas.translate(x: 2.5, y: 2.5)
            canvas.concatenate(CGAffineTransform(rotationAngle: .pi / 4))
            guard let coverage = _BackdropFilterGeometry.coverage(
                of: rect, transform: canvas.ctm, width: 5, height: 5)
            else {
                XCTFail("rotated fixture must have coverage")
                continue
            }
            let zeroIndices = coverage.indices.filter { coverage[$0] == 0 }
            XCTAssertEqual(zeroIndices.count, 14, "fixture must stay sparse")

            canvas.applyBackdropFilter(
                CanvasBackdropFilterConfiguration(
                    tintColor: CGColor(red: 1, green: 0, blue: 0, alpha: 1)),
                in: rect)

            for index in zeroIndices {
                let bytes = (index * 4)..<(index * 4 + 4)
                XCTAssertEqual(Array(bitmap.pixels[bytes]), Array(before[bytes]),
                               "zero coverage byte mutation at \(index), \(backend)")
            }
            results.append(bitmap.pixels)
        }

        XCTAssertEqual(results[0], results[1])
    }

    func testSparseRotatedClippedMasksPreserveBytesAndMatchBackends() {
        let fixtures: [(CGFloat, CGFloat, CGFloat, CGRect, CGRect)] = [
            (4.1, 3.2, 0.61,
             CGRect(x: -1.8, y: -1.25, width: 3.6, height: 2.5),
             CGRect(x: -2.7, y: -0.45, width: 5.4, height: 0.9)),
            (3.4, 2.6, -0.47,
             CGRect(x: -1.15, y: -1.9, width: 2.3, height: 3.8),
             CGRect(x: -2.4, y: -0.6, width: 4.8, height: 1.2)),
        ]

        for (fixtureIndex, fixture) in fixtures.enumerated() {
            var results: [[UInt8]] = []
            for backend in [RenderBackend.swift, .quartz] {
                CanvasBackendSelection.current = backend
                let bitmap = Bitmap(width: 9, height: 7)
                for y in 0..<7 { for x in 0..<9 {
                    setPixel(bitmap, x: x, y: y,
                             (UInt8((x * 47 + y * 19 + 20) % 256),
                              UInt8((x * 13 + y * 71 + 120) % 256),
                              UInt8((x * 89 + y * 29 + 240) % 256),
                              UInt8((x * 37 + y * 53 + 31) % 254 + 1)))
                } }
                let before = bitmap.pixels
                let canvas = Canvas(bitmap: bitmap, scale: 1)
                canvas.translate(x: fixture.0, y: fixture.1)
                canvas.concatenate(CGAffineTransform(rotationAngle: fixture.2))
                canvas.clip(to: fixture.3)
                guard var coverage = _BackdropFilterGeometry.coverage(
                    of: fixture.4, transform: canvas.ctm,
                    width: bitmap.width, height: bitmap.height),
                      let clip = canvas.state.clipMask
                else {
                    XCTFail("fixture \(fixtureIndex) must have region and clip coverage")
                    continue
                }
                for index in coverage.indices {
                    coverage[index] = UInt8(
                        (Int(coverage[index]) * Int(clip[index]) + 127) / 255)
                }
                guard let bounds = _CanvasDeviceBounds.coverageBounds(
                    coverage, width: bitmap.width, height: bitmap.height)
                else {
                    XCTFail("fixture \(fixtureIndex) must have effective coverage")
                    continue
                }
                var interiorZeroCount = 0
                for y in bounds.y0..<bounds.y1 { for x in bounds.x0..<bounds.x1 {
                    if coverage[y * bitmap.width + x] == 0 {
                        interiorZeroCount += 1
                    }
                } }
                XCTAssertGreaterThan(interiorZeroCount, 0,
                                     "fixture \(fixtureIndex) must have bbox holes")

                canvas.applyBackdropFilter(
                    CanvasBackdropFilterConfiguration(
                        blurRadius: 0.8, saturation: 0.65,
                        tintColor: CGColor(red: 0.9, green: 0.15,
                                           blue: 0.35, alpha: 0.4),
                        intensity: 0.73),
                    in: fixture.4)

                for index in coverage.indices where coverage[index] == 0 {
                    let bytes = (index * 4)..<(index * 4 + 4)
                    XCTAssertEqual(Array(bitmap.pixels[bytes]), Array(before[bytes]),
                                   "fixture \(fixtureIndex), zero pixel \(index), \(backend)")
                }
                XCTAssertNotEqual(bitmap.pixels, before,
                                  "fixture \(fixtureIndex) must exercise filtering")
                results.append(bitmap.pixels)
            }
            XCTAssertEqual(results[0], results[1], "fixture \(fixtureIndex)")
        }
    }

    func testBlurRadiusTracksCanvasScale() {
        func render(scale: CGFloat, backend: RenderBackend) -> Bitmap {
            CanvasBackendSelection.current = backend
            let bitmap = Bitmap(width: 9, height: 1)
            for x in 0..<9 { setPixel(bitmap, x: x, y: 0, (0, 0, 0, 255)) }
            setPixel(bitmap, x: 4, y: 0, (255, 255, 255, 255))
            Canvas(bitmap: bitmap, scale: scale).applyBackdropFilter(
                CanvasBackdropFilterConfiguration(blurRadius: 1),
                in: CGRect(x: 0, y: 0, width: 9 / scale, height: 1 / scale))
            return bitmap
        }

        forEachBackend { backend in
            let oneX = render(scale: 1, backend: backend)
            let twoX = render(scale: 2, backend: backend)
            XCTAssertEqual(pixel(oneX, x: 2, y: 0).r, 0, "\(backend)")
            XCTAssertGreaterThan(pixel(twoX, x: 2, y: 0).r, 0, "\(backend)")
            XCTAssertLessThan(pixel(twoX, x: 4, y: 0).r,
                              pixel(oneX, x: 4, y: 0).r, "\(backend)")
        }
    }

    func testAreaEquivalentScaleSurvivesDeterminantUnderflowAndOverflow() {
        func render(transform: CGAffineTransform, rect: CGRect,
                    radius: CGFloat, backend: RenderBackend) -> [UInt8] {
            CanvasBackendSelection.current = backend
            let bitmap = Bitmap(width: 5, height: 1)
            for x in 0..<5 {
                let value: UInt8 = x.isMultiple(of: 2) ? 0 : 255
                setPixel(bitmap, x: x, y: 0, (value, value, value, 255))
            }
            let canvas = Canvas(bitmap: bitmap, scale: 1)
            canvas.concatenate(transform)
            canvas.applyBackdropFilter(
                CanvasBackdropFilterConfiguration(blurRadius: radius),
                in: rect)
            return (0..<5).map { pixel(bitmap, x: $0, y: 0).r }
        }

        // Both transforms describe identity device geometry and device sigma
        // one. Their exact determinants are 2^-1200 and 2^1200: outside the
        // representable binary64 determinant range even though sqrt(det) is
        // the exactly representable 2^-600 / 2^600 scale.
        let tiny = CGFloat(sign: .plus, exponent: -600, significand: 1)
        let huge = CGFloat(sign: .plus, exponent: 600, significand: 1)
        forEachBackend { backend in
            let oracle = render(
                transform: .identity,
                rect: CGRect(x: 0, y: 0, width: 5, height: 1),
                radius: 1, backend: backend)
            XCTAssertEqual(render(
                transform: CGAffineTransform(a: tiny, b: 0, c: 0, d: tiny,
                                             tx: 0, ty: 0),
                rect: CGRect(x: 0, y: 0, width: 5 * huge, height: huge),
                radius: huge, backend: backend), oracle, "underflow, \(backend)")
            XCTAssertEqual(render(
                transform: CGAffineTransform(a: huge, b: 0, c: 0, d: huge,
                                             tx: 0, ty: 0),
                rect: CGRect(x: 0, y: 0, width: 5 * tiny, height: tiny),
                radius: tiny, backend: backend), oracle, "overflow, \(backend)")
        }
    }

    func testAreaEquivalentScaleMatchesExactRationalSquareRootRounding() {
        // Independent arbitrary-precision rational products followed by an
        // exact squared-midpoint binary64 round-to-nearest/even oracle. The
        // first four cases are deliberate double-round counterexamples for
        // sqrt(RN(a*d-b*c)); the exact determinant must reach sqrt unrounded.
        let cases: [(UInt64, UInt64, UInt64, UInt64, UInt64)] = [
            (0x3ff7130f584df3c8, 0, 0, 0x3ffcad0a65be34ae,
             0x3ff9b921dc18f6aa),
            (0x3ff4fc7aab0654f4, 0, 0, 0x3ffa5813f9042008,
             0x3ff7835649d2711f),
            (0x3ff1dc1e9a913fac, 0x3ff7557eef7db25e,
             0x3ff6bdd35eb49113, 0x3ff837e0e24f1216,
             0x3fe3cf83d2d5cb2c),
            (0x3ffc27a01f42e05b, 0x3ffe1169e1d7fc62,
             0x3ffbf117e27529f3, 0x3ff9824267b114b5,
             0x3fe616419f2bebbd),
            (0x3ff4c9fa6d3c848f, 0x3ffa0b5ad6c23358,
             0x3ff7dfb73a998ea6, 0x3ff8ba06cd3f8920,
             0x3fe4c26699713a66),
            (0x3ffc9a4232ada7fb, 0x3ff2ff10607b5f3e,
             0x3ffa65007800e335, 0x3ff542d3b9187d0b,
             0x3fe4a9414e5586a4),
        ]
        for (a, b, c, d, expected) in cases {
            let result = _BackdropFilterGeometry.areaEquivalentScale(
                a: CGFloat(Double(bitPattern: a)),
                b: CGFloat(Double(bitPattern: b)),
                c: CGFloat(Double(bitPattern: c)),
                d: CGFloat(Double(bitPattern: d)))
            XCTAssertEqual(Double(result).bitPattern, expected,
                           "a=\(String(a, radix: 16)), d=\(String(d, radix: 16))")
        }

        let least = CGFloat.leastNonzeroMagnitude
        let greatest = CGFloat.greatestFiniteMagnitude
        XCTAssertEqual(_BackdropFilterGeometry.areaEquivalentScale(
            a: least, b: 0, c: 0, d: least), least)
        XCTAssertEqual(_BackdropFilterGeometry.areaEquivalentScale(
            a: greatest, b: 0, c: 0, d: greatest), greatest)
        XCTAssertEqual(_BackdropFilterGeometry.areaEquivalentScale(
            a: greatest, b: greatest, c: -greatest, d: greatest), greatest,
        "sqrt(2 * greatest^2) follows the finite-saturation policy")

        let halfULPAtOne = CGFloat(sign: .plus, exponent: -53, significand: 1)
        let one = CGFloat(1)
        XCTAssertEqual(_BackdropFilterGeometry.areaEquivalentScale(
            a: one, b: halfULPAtOne, c: -halfULPAtOne, d: one.nextUp),
            one,
        "exact sqrt midpoint chooses the even lower significand")
        XCTAssertEqual(_BackdropFilterGeometry.areaEquivalentScale(
            a: one, b: 3 * halfULPAtOne, c: -3 * halfULPAtOne,
            d: one.nextUp.nextUp.nextUp),
            one.nextUp.nextUp,
        "next exact sqrt midpoint chooses the even upper significand")
        XCTAssertEqual(_BackdropFilterGeometry.areaEquivalentScale(
            a: -one, b: halfULPAtOne, c: halfULPAtOne, d: one.nextUp),
            one,
        "determinant magnitude uses the same tie rule")

        let midpointM = CGFloat((UInt64(1) << 52) + 5)
        let midpointV = CGFloat(3_602_879_701_896_401 as UInt64)
        XCTAssertEqual(Double(_BackdropFilterGeometry.areaEquivalentScale(
            a: midpointM, b: 5, c: -midpointV, d: 4 * midpointM)).bitPattern,
            0x4340000000000006,
        "(2M+1)^2 midpoint chooses the upper even large integer")
    }

    func testSaturationAndIntensityOperateInPremultipliedSpace() {
        forEachBackend { backend in
            let bitmap = Bitmap(width: 2, height: 1)
            setPixel(bitmap, x: 0, y: 0, (255, 0, 0, 128))
            setPixel(bitmap, x: 1, y: 0, (0, 0, 0, 255))
            let canvas = Canvas(bitmap: bitmap, scale: 1)
            canvas.applyBackdropFilter(
                CanvasBackdropFilterConfiguration(saturation: 0),
                in: CGRect(x: 0, y: 0, width: 1, height: 1))
            XCTAssertEqual(pixel(bitmap, x: 0, y: 0), Pixel(54, 54, 54, 128), "\(backend)")

            canvas.applyBackdropFilter(
                CanvasBackdropFilterConfiguration(
                    tintColor: .white, intensity: 0.5),
                in: CGRect(x: 1, y: 0, width: 1, height: 1))
            XCTAssertEqual(pixel(bitmap, x: 1, y: 0), Pixel(128, 128, 128, 255), "\(backend)")
        }
    }

    func testNonfinitePublicGeometryIsAlwaysANoOp() {
        let invalidRects = [
            CGRect(x: CGFloat.nan, y: 0, width: 2, height: 2),
            CGRect(x: 0, y: CGFloat.infinity, width: 2, height: 2),
            CGRect(x: 0, y: 0, width: -CGFloat.infinity, height: 2),
            CGRect(x: 0, y: 0, width: 2, height: CGFloat.nan),
        ]
        let invalidTransforms = [
            CGAffineTransform(a: CGFloat.nan, b: 0, c: 0, d: 1, tx: 0, ty: 0),
            CGAffineTransform(a: 1, b: CGFloat.infinity, c: 0, d: 1, tx: 0, ty: 0),
            CGAffineTransform(a: 1, b: 0, c: -CGFloat.infinity, d: 1, tx: 0, ty: 0),
            CGAffineTransform(a: 1, b: 0, c: 0, d: 1, tx: CGFloat.nan, ty: 0),
        ]

        forEachBackend { backend in
            for rect in invalidRects {
                let bitmap = patternedBitmap(width: 4, height: 3)
                let before = bitmap.pixels
                Canvas(bitmap: bitmap, scale: 1).applyBackdropFilter(
                    CanvasBackdropFilterConfiguration(
                        blurRadius: 2,
                        tintColor: CGColor(red: 1, green: 0, blue: 0, alpha: 1)),
                    in: rect)
                XCTAssertEqual(bitmap.pixels, before, "\(backend), \(rect)")
            }
            for transform in invalidTransforms {
                let bitmap = patternedBitmap(width: 4, height: 3)
                let before = bitmap.pixels
                let canvas = Canvas(bitmap: bitmap, scale: 1)
                canvas.concatenate(transform)
                canvas.applyBackdropFilter(
                    CanvasBackdropFilterConfiguration(
                        tintColor: CGColor(red: 1, green: 0, blue: 0, alpha: 1)),
                    in: CGRect(x: 0, y: 0, width: 4, height: 3))
                XCTAssertEqual(bitmap.pixels, before, "\(backend), \(transform)")
            }
        }
    }

    func testEnormousFiniteGeometryClipsBeforeIntegerConversion() {
        let huge = CGFloat.greatestFiniteMagnitude
        forEachBackend { backend in
            let giantRectBitmap = patternedBitmap(width: 5, height: 4)
            Canvas(bitmap: giantRectBitmap, scale: 1).applyBackdropFilter(
                CanvasBackdropFilterConfiguration(
                    tintColor: CGColor(red: 1, green: 0, blue: 0, alpha: 1)),
                in: CGRect(x: -huge / 2, y: -huge / 2,
                           width: huge, height: huge))
            assertSolid(giantRectBitmap, Pixel(255, 0, 0, 255), "\(backend), huge rect")

            // Multiplying these finite rectangle corners by this finite CTM
            // overflows ordinary CGFloat products to +/-infinity.  The exact
            // transformed quadrilateral still contains the whole surface.
            let overflowProductBitmap = patternedBitmap(width: 5, height: 4)
            let overflowCanvas = Canvas(bitmap: overflowProductBitmap, scale: 1)
            overflowCanvas.concatenate(CGAffineTransform(
                a: huge, b: 0, c: 0, d: huge, tx: 0, ty: 0))
            overflowCanvas.applyBackdropFilter(
                CanvasBackdropFilterConfiguration(
                    tintColor: CGColor(red: 1, green: 0, blue: 0, alpha: 1)),
                in: CGRect(x: -2, y: -2, width: 4, height: 4))
            assertSolid(overflowProductBitmap, Pixel(255, 0, 0, 255),
                        "\(backend), overflowed affine products")

            let offscreenBitmap = patternedBitmap(width: 5, height: 4)
            let before = offscreenBitmap.pixels
            Canvas(bitmap: offscreenBitmap, scale: 1).applyBackdropFilter(
                CanvasBackdropFilterConfiguration(
                    tintColor: CGColor(red: 1, green: 0, blue: 0, alpha: 1)),
                in: CGRect(x: huge / 2, y: huge / 2,
                           width: huge / 4, height: huge / 4))
            XCTAssertEqual(offscreenBitmap.pixels, before,
                           "\(backend), wholly off-surface")
        }
    }

    func testCoverageAccumulatorClampsBeforeIntAndNormalizesHugeSegments() {
        let huge = CGFloat.greatestFiniteMagnitude
        var accumulator = _CoverageAccumulator(
            clippingBoxMinX: -CGFloat.infinity,
            minY: -CGFloat.infinity,
            maxX: CGFloat.infinity,
            maxY: CGFloat.infinity,
            limitWidth: 3,
            limitHeight: 2)!
        XCTAssertEqual(accumulator.originX, 0)
        XCTAssertEqual(accumulator.originY, 0)
        XCTAssertEqual(accumulator.width, 3)
        XCTAssertEqual(accumulator.height, 2)

        var giantRectangle = _Subpath()
        giantRectangle.points = [
            CGPoint(x: -huge, y: -huge), CGPoint(x: huge, y: -huge),
            CGPoint(x: huge, y: huge), CGPoint(x: -huge, y: huge),
        ]
        accumulator.add(subpaths: [giantRectangle], implicitClose: true)
        var bytes: [UInt8] = []
        accumulator.enumerateRows(evenOdd: false) { _, coverage in
            bytes.append(contentsOf: coverage.map { UInt8(($0 * 255).rounded()) })
        }
        XCTAssertEqual(bytes, Array(repeating: 255, count: 6))
    }

    func testHugeRadiusWorkIsIndependentOfRadiusAndPreservesUniformAxes() {
        let length = 2_048
        forEachBackend { backend in
            for dimensions in [(length, 1), (1, length)] {
                let bitmap = Bitmap(width: dimensions.0, height: dimensions.1)
                for y in 0..<bitmap.height { for x in 0..<bitmap.width {
                    setPixel(bitmap, x: x, y: y, (37, 149, 211, 255))
                } }
                Canvas(bitmap: bitmap, scale: 1).applyBackdropFilter(
                    CanvasBackdropFilterConfiguration(
                        blurRadius: CGFloat.greatestFiniteMagnitude),
                    in: CGRect(x: 0, y: 0,
                               width: CGFloat(bitmap.width),
                               height: CGFloat(bitmap.height)))
                assertSolid(bitmap, Pixel(37, 149, 211, 255),
                            "\(backend), \(dimensions.0)x\(dimensions.1)")
            }
        }
    }

    func testHugeSigmaBoxSizingDoesNotOverflowIntermediateIntArithmetic() {
        // A 400M x 1 RGBA8 surface is large but valid on a high-memory Linux
        // host. Its hostile-radius sigma cap is 1.6e9; squaring the resulting
        // 3.2e9 box width as Int traps even though every returned radius fits.
        // The exact lower-pass quotient is the nearest/away half-tie 1.5.
        XCTAssertEqual(
            _BackdropFilterCPU.boxRadii(forSigma: 1_600_000_000),
            [1_599_999_999, 1_599_999_999, 1_600_000_000])

        // First exact half-tie that the former Double polynomial rounded
        // downward at the public hostile cap sigma = 4 * surfaceSpan.
        XCTAssertEqual(
            _BackdropFilterCPU.boxRadii(forSigma: 54_794_160),
            [54_794_159, 54_794_159, 54_794_160])

        // The internal sizing primitive remains exact across binary64's
        // consecutive-integer boundary too, even though no allocated bitmap
        // can make such a sigma reachable through the public four-span cap.
        XCTAssertEqual(
            _BackdropFilterCPU.boxRadii(
                forSigma: Double(sign: .plus, exponent: 52,
                                 significand: 1).nextUp),
            [4_503_599_627_370_496,
             4_503_599_627_370_496,
             4_503_599_627_370_497])
    }

    func testExactAffineArithmeticPreservesResidualsAfterOverflowingProductsCancel() {
        let greatest = CGFloat.greatestFiniteMagnitude
        XCTAssertEqual(
            _BackdropFilterGeometry.saturatedLinearCombination(
                greatest, greatest, greatest, -greatest, 1),
            1)

        // Both individual products overflow, but the exact represented-input
        // result is the finite, exactly representable basis delta.
        let origin = CGFloat(sign: .plus, exponent: 475, significand: 1)
        let extent = origin.ulp
        let scale = CGFloat(sign: .plus, exponent: 600, significand: 1)
        XCTAssertEqual(
            _BackdropFilterGeometry.saturatedLinearCombination(
                origin + extent, scale, origin, -scale, 0),
            extent * scale)
    }

    func testExactAffineArithmeticRoundsAndSaturatesAtBinary64Boundaries() {
        let least = CGFloat.leastNonzeroMagnitude
        XCTAssertEqual(
            _BackdropFilterGeometry.saturatedLinearCombination(
                least, 0.5, 0, 0, 0),
            0,
            "half of the least subnormal ties to even zero")
        XCTAssertEqual(
            _BackdropFilterGeometry.saturatedLinearCombination(
                least, 0.75, 0, 0, 0),
            least)

        let halfULPAtOne = CGFloat(sign: .plus, exponent: -53, significand: 1)
        XCTAssertEqual(
            _BackdropFilterGeometry.saturatedLinearCombination(
                1, 1, halfULPAtOne, 1, 0),
            1,
            "normal midpoint also rounds to the even significand")
        XCTAssertEqual(
            _BackdropFilterGeometry.saturatedLinearCombination(
                1, 1, 3 * halfULPAtOne, 1, 0),
            CGFloat(1).nextUp.nextUp)

        let greatest = CGFloat.greatestFiniteMagnitude
        XCTAssertEqual(
            _BackdropFilterGeometry.saturatedLinearCombination(
                greatest, 1, greatest, 1, 0),
            greatest)
        XCTAssertEqual(
            _BackdropFilterGeometry.saturatedLinearCombination(
                -greatest, 1, -greatest, 1, 0),
            -greatest)
    }

    func testExactAffineArithmeticMatchesIndependentRationalOracleBitPatterns() {
        // Expected bits were generated independently with arbitrary-precision
        // rational arithmetic followed by binary64 round-to-nearest/even and
        // finite saturation.  The cases cover cancellation across thousands
        // of exponent steps, subnormal ties, and unrelated mixed-sign terms.
        let cases: [(UInt64, UInt64, UInt64, UInt64, UInt64, UInt64)] = [
            (0x7fefffffffffffff, 0x7fefffffffffffff, 0x7fefffffffffffff,
             0xffefffffffffffff, 0x3ff0000000000000, 0x3ff0000000000000),
            (0x0000000000000001, 0x3fe0000000000000, 0, 0, 0, 0),
            (0x0000000000000001, 0x3fe8000000000000, 0, 0, 0,
             0x0000000000000001),
            (0x3ff0000000000000, 0x3ff0000000000000, 0x3ca0000000000000,
             0x3ff0000000000000, 0, 0x3ff0000000000000),
            (0x3ff0000000000000, 0x3ff0000000000000, 0x3cb8000000000000,
             0x3ff0000000000000, 0, 0x3ff0000000000002),
            (0x7fefffffffffffff, 0x3ff0000000000000, 0x7fefffffffffffff,
             0x3ff0000000000000, 0, 0x7fefffffffffffff),
            (0xffefffffffffffff, 0x3ff0000000000000, 0xffefffffffffffff,
             0x3ff0000000000000, 0, 0xffefffffffffffff),
            (0x6570000000000001, 0x5da0000000000000, 0x6570000000000000,
             0xdda0000000000000, 0x7ca0000000000000, 0x7fe0000000000001),
            (0x7830000000000001, 0x4630000000000000, 0x7830000000000000,
             0xc630000000000000, 0x77f0000000000000, 0x7b30000000000001),
            (0x20b0000000000001, 0x20b0000000000000, 0x20b0000000000000,
             0xa0b0000000000000, 1, 0x0000000000400001),
            (0xc62239a2f4a7bf04, 0x62207fdefc0a9e33, 0x279eaed94b1a337a,
             0x735f6aa5fb4959a5, 0xea9a2b5f931bcff8, 0xea9a2b5f931cfcad),
            (0x9906ca2c38e5232e, 0xe149def6e586bfdd, 0x7a33257088d52ddb,
             0x478a6a71bbfc5553, 0x0983cc057a7c5931, 0x7fefffffffffffff),
            (0xc3180725924806b1, 0x8133631ffb90f5b9, 0x26ea8f80a0cdbd57,
             0x3099b4b5761ff699, 0x907d8dcbac6af2aa, 0x1795561a4ee480c4),
            (0x9c7202f45ccb5aab, 0xe400c014d3e84cae, 0xaa9c5db322820e73,
             0xfa6b673e27097461, 0x9d1cfcf3f1fecc99, 0x65184a93d5da7582),
            (0x82f7e1b7616d86db, 0xc99309cd2e444165, 0x7cd189121114c64a,
             0xb8b6b85b9b4195ae, 0x1c1fc720bd3f7735, 0xf598e6858cff809e),
            (0x42d53439275f3d10, 0x3394a4b234527a83, 0xae1a920d7d1488cb,
             0xa7b4babeb62438f2, 0xa4fb393140c041a0, 0x367b5b8ae55d7a4a),
        ]

        for (a, b, c, d, translation, expected) in cases {
            let result = _BackdropFilterGeometry.saturatedLinearCombination(
                CGFloat(Double(bitPattern: a)), CGFloat(Double(bitPattern: b)),
                CGFloat(Double(bitPattern: c)), CGFloat(Double(bitPattern: d)),
                CGFloat(Double(bitPattern: translation)))
            XCTAssertEqual(Double(result).bitPattern, expected)
        }
    }

    func testCancellationHeavyPublicTransformMatchesEquivalentFiniteBasisAndTranslation() {
        let origin = CGFloat(sign: .plus, exponent: 475, significand: 1)
        let extent = origin.ulp
        let a = CGFloat(sign: .plus, exponent: 600, significand: 1)
        let b = CGFloat(sign: .plus, exponent: 599, significand: 1)
        let epsilon = b.ulp
        let d = -b + epsilon
        let ty = -(epsilon * origin)

        func render(backend: RenderBackend, translationX: CGFloat,
                    reducedFiniteBasis: Bool) -> [UInt8] {
            CanvasBackendSelection.current = backend
            let bitmap = Bitmap(width: 4, height: 4)
            for pixel in 0..<(4 * 4) {
                bitmap.pixels[pixel * 4 + 2] = 255
                bitmap.pixels[pixel * 4 + 3] = 255
            }
            let canvas = Canvas(bitmap: bitmap, scale: 1)
            let rect: CGRect
            if reducedFiniteBasis {
                let xBasis = a * extent
                let yBasis = b * extent
                let residual = epsilon * extent
                canvas.concatenate(CGAffineTransform(
                    a: xBasis, b: yBasis,
                    c: -xBasis, d: -yBasis + residual,
                    tx: translationX, ty: 0))
                rect = CGRect(x: 0, y: 0, width: 1, height: 1)
            } else {
                canvas.concatenate(CGAffineTransform(
                    a: a, b: b, c: -a, d: d,
                    tx: translationX, ty: ty))
                rect = CGRect(x: origin, y: origin,
                              width: extent, height: extent)
            }
            canvas.applyBackdropFilter(
                CanvasBackdropFilterConfiguration(
                    tintColor: CGColor(red: 1, green: 0, blue: 0, alpha: 1)),
                in: rect)
            return bitmap.pixels
        }

        forEachBackend { backend in
            let hostileZero = render(
                backend: backend, translationX: 0, reducedFiniteBasis: false)
            let reducedZero = render(
                backend: backend, translationX: 0, reducedFiniteBasis: true)
            let hostileOne = render(
                backend: backend, translationX: 1, reducedFiniteBasis: false)
            let reducedOne = render(
                backend: backend, translationX: 1, reducedFiniteBasis: true)
            XCTAssertEqual(hostileZero, reducedZero, "tx=0, \(backend)")
            XCTAssertEqual(hostileOne, reducedOne, "tx=1, \(backend)")
            XCTAssertNotEqual(hostileZero, hostileOne,
                              "one-pixel translation must move coverage, \(backend)")
        }
    }

    func testUnequalOverflowingCornersPreserveExactPreclipGeometry() {
        func render(transform: CGAffineTransform, rect: CGRect,
                    backend: RenderBackend) -> [UInt8] {
            CanvasBackendSelection.current = backend
            let bitmap = Bitmap(width: 4, height: 4)
            for index in 0..<(4 * 4) {
                bitmap.pixels[index * 4 + 2] = 255
                bitmap.pixels[index * 4 + 3] = 255
            }
            let canvas = Canvas(bitmap: bitmap, scale: 1)
            canvas.concatenate(transform)
            canvas.applyBackdropFilter(
                CanvasBackdropFilterConfiguration(
                    tintColor: CGColor(red: 1, green: 0, blue: 0, alpha: 1)),
                in: rect)
            return bitmap.pixels
        }

        // The hostile and finite transforms describe the same device-space
        // parallelogram up to a positive homogeneous x scale. The hostile
        // exact corner x values are (-8H, +4H, -16H, -28H). Saturating those
        // unequal overflowing values independently moves the x=0 crossing
        // from y=8/3 to y=2 and incorrectly makes row two fully covered.
        let h = CGFloat(sign: .plus, exponent: 1022, significand: 1)
        let hostileRect = CGRect(x: h, y: h, width: h, height: h)
        let hostile = CGAffineTransform(
            a: 12, b: 4 / h, c: -20, d: 4 / h, tx: 0, ty: -8)
        let k = CGFloat(sign: .plus, exponent: 40, significand: 1)
        let finiteRect = CGRect(x: 1, y: 1, width: 1, height: 1)
        let finite = CGAffineTransform(
            a: 12 * k, b: 4, c: -20 * k, d: 4, tx: 0, ty: -8)

        forEachBackend { backend in
            let result = render(transform: hostile, rect: hostileRect,
                                backend: backend)
            XCTAssertEqual(result, render(transform: finite, rect: finiteRect,
                                          backend: backend), "\(backend)")
            XCTAssertEqual((0..<4).map { result[(2 * 4 + $0) * 4] },
                           [85, 85, 85, 85], "visible 1/3 row, \(backend)")
        }

        // A second independent ratio boundary: factor^2 is P + 1 where P is
        // representable but P + 1 is not. The x=0 intersection parameter is
        // 1 - 1/(P+1); discarding that residual moves the orthogonal crossing
        // from y=2 to y=1 even though all final coordinates are tiny.
        let factor = CGFloat((UInt64(1) << 52) + 1)
        let p = CGFloat(sign: .plus, exponent: 104, significand: 1)
            + CGFloat(sign: .plus, exponent: 53, significand: 1)
        let endpointHostile = CGAffineTransform(
            a: factor, b: -factor, c: 0, d: 4, tx: -p, ty: p)
        let endpointFinite = CGAffineTransform(
            a: 9, b: -9, c: 0, d: 4, tx: -8, ty: 8)
        forEachBackend { backend in
            let result = render(
                transform: endpointHostile,
                rect: CGRect(x: 0, y: 0.5, width: factor, height: 1),
                backend: backend)
            XCTAssertEqual(result, render(
                transform: endpointFinite,
                rect: CGRect(x: 0, y: 0.5, width: 1, height: 1),
                backend: backend), "near-endpoint ratio, \(backend)")
            XCTAssertEqual((0..<4).map { result[($0 * 4) * 4] },
                           [0, 128, 255, 255], "exact y=2 crossing, \(backend)")
        }
    }

    func testHugeFiniteDiagonalClipKeepsItsVisibleSlopeForBackdropWrites() {
        let greatest = CGFloat.greatestFiniteMagnitude
        let blue = Pixel(0, 0, 255, 255)
        let red = Pixel(255, 0, 0, 255)
        let half = Pixel(128, 0, 127, 255)
        let fixtures: [([CGPoint], [Pixel])] = [
            ([CGPoint(x: -greatest, y: -greatest),
              CGPoint(x: greatest, y: greatest),
              CGPoint(x: greatest, y: -greatest)],
             [half, red, red, red,
              blue, half, red, red,
              blue, blue, half, red,
              blue, blue, blue, half]),
            ([CGPoint(x: -greatest, y: -greatest),
              CGPoint(x: greatest, y: greatest),
              CGPoint(x: -greatest, y: greatest)],
             [half, blue, blue, blue,
              red, half, blue, blue,
              red, red, half, blue,
              red, red, red, half]),
        ]

        forEachBackend { backend in
            for (fixture, expected) in fixtures {
                for points in [fixture, Array(fixture.reversed())] {
                    let bitmap = Bitmap(width: 4, height: 4)
                    for y in 0..<4 { for x in 0..<4 {
                        setPixel(bitmap, x: x, y: y, (0, 0, 255, 255))
                    } }
                    var triangle = Path()
                    triangle.move(to: points[0])
                    triangle.addLine(to: points[1])
                    triangle.addLine(to: points[2])
                    triangle.close()

                    let canvas = Canvas(bitmap: bitmap, scale: 1)
                    canvas.clip(to: triangle)
                    canvas.applyBackdropFilter(
                        CanvasBackdropFilterConfiguration(tintColor: CGColor(
                            red: 1, green: 0, blue: 0, alpha: 1)),
                        in: CGRect(x: 0, y: 0, width: 4, height: 4))
                    XCTAssertEqual(pixels(bitmap), expected, "\(backend), \(points)")
                }
            }
        }
    }

    func testHugeFiniteDiagonalClipsMatchScaledFiniteOracles() {
        let greatest = CGFloat.greatestFiniteMagnitude
        let fixtures: [([CGPoint], [CGPoint])] = [
            ([CGPoint(x: -greatest, y: -greatest / 2),
              CGPoint(x: greatest, y: greatest / 2),
              CGPoint(x: greatest, y: -greatest / 2)],
             [CGPoint(x: -8, y: -4), CGPoint(x: 8, y: 4),
              CGPoint(x: 8, y: -4)]),
            ([CGPoint(x: -greatest / 2, y: -greatest),
              CGPoint(x: greatest / 2, y: greatest),
              CGPoint(x: greatest / 2, y: -greatest)],
             [CGPoint(x: -4, y: -8), CGPoint(x: 4, y: 8),
              CGPoint(x: 4, y: -8)]),
        ]

        func render(_ points: [CGPoint], backend: RenderBackend) -> [UInt8] {
            CanvasBackendSelection.current = backend
            let bitmap = Bitmap(width: 4, height: 4)
            var triangle = Path()
            triangle.move(to: points[0])
            triangle.addLine(to: points[1])
            triangle.addLine(to: points[2])
            triangle.close()
            let canvas = Canvas(bitmap: bitmap, scale: 1)
            canvas.clip(to: triangle)
            canvas.applyBackdropFilter(
                CanvasBackdropFilterConfiguration(
                    tintColor: CGColor(red: 1, green: 0, blue: 0, alpha: 1)),
                in: CGRect(x: 0, y: 0, width: 4, height: 4))
            return bitmap.pixels
        }

        forEachBackend { backend in
            for (huge, finite) in fixtures {
                XCTAssertEqual(render(huge, backend: backend),
                               render(finite, backend: backend), "\(backend)")
                XCTAssertEqual(render(Array(huge.reversed()), backend: backend),
                               render(Array(finite.reversed()), backend: backend),
                               "reversed, \(backend)")
            }
        }
    }

    func testHugeAngularClipLatticeMatchesScaledPublicOracles() {
        let coordinates: [CGFloat] = [-1, -0.5, 0.5, 1]
        let basis = coordinates.flatMap { y in
            coordinates.map { x in CGPoint(x: x, y: y) }
        }
        let huge = CGFloat(sign: .plus, exponent: 1023, significand: 1)
        let finite = CGFloat(sign: .plus, exponent: 40, significand: 1)

        func points(_ order: [Int], scale: CGFloat) -> [CGPoint] {
            order.map { CGPoint(x: basis[$0].x * scale,
                                y: basis[$0].y * scale) }
        }

        func path(_ points: [CGPoint]) -> Path {
            var result = Path()
            result.move(to: points[0])
            for point in points.dropFirst() { result.addLine(to: point) }
            result.close()
            return result
        }

        func clippedBackdrop(_ points: [CGPoint],
                             backend: RenderBackend) -> [UInt8] {
            CanvasBackendSelection.current = backend
            let bitmap = Bitmap(width: 4, height: 4)
            for index in 0..<16 {
                bitmap.pixels[index * 4 + 2] = 255
                bitmap.pixels[index * 4 + 3] = 255
            }
            let canvas = Canvas(bitmap: bitmap, scale: 1)
            canvas.clip(to: path(points))
            canvas.applyBackdropFilter(
                CanvasBackdropFilterConfiguration(
                    tintColor: CGColor(red: 1, green: 0, blue: 0, alpha: 1)),
                in: CGRect(x: 0, y: 0, width: 4, height: 4))
            return bitmap.pixels
        }

        func evenOddFill(_ points: [CGPoint]) -> [UInt8] {
            CanvasBackendSelection.current = .swift
            let bitmap = Bitmap(width: 4, height: 4)
            Canvas(bitmap: bitmap, scale: 1).fill(
                path(points), color: .white, evenOdd: true)
            return bitmap.pixels
        }

        // Every triangle, winding reversal, ordinary/multi-edge quad, and
        // selected self-intersection order over the dyadic lattice. Scaling
        // by 2^1023 makes opposite-sign edge deltas overflow ordinary
        // binary64 subtraction; 2^40 is the independent finite oracle.
        for backend in [RenderBackend.swift, .quartz] {
            for a in 0..<(basis.count - 2) {
                for b in (a + 1)..<(basis.count - 1) {
                    for c in (b + 1)..<basis.count {
                        for order in [[a, b, c], [c, b, a]] {
                            XCTAssertEqual(
                                clippedBackdrop(points(order, scale: huge),
                                                backend: backend),
                                clippedBackdrop(points(order, scale: finite),
                                                backend: backend),
                                "triangle \(backend), \(order)")
                        }
                    }
                }
            }

            for a in 0..<(basis.count - 3) {
                for b in (a + 1)..<(basis.count - 2) {
                    for c in (b + 1)..<(basis.count - 1) {
                        for d in (c + 1)..<basis.count {
                            let orders = [
                                [a, b, c, d], [a, c, b, d], [a, b, d, c],
                                [d, c, b, a], [d, b, c, a], [d, c, a, b],
                            ]
                            for order in orders {
                                XCTAssertEqual(
                                    clippedBackdrop(points(order, scale: huge),
                                                    backend: backend),
                                    clippedBackdrop(points(order, scale: finite),
                                                    backend: backend),
                                    "quad \(backend), \(order)")
                            }
                        }
                    }
                }
            }
        }

        for a in 0..<(basis.count - 3) {
            for b in (a + 1)..<(basis.count - 2) {
                for c in (b + 1)..<(basis.count - 1) {
                    for d in (c + 1)..<basis.count {
                        for order in [[a, c, b, d], [a, b, d, c],
                                      [d, b, c, a], [d, c, a, b]] {
                            XCTAssertEqual(
                                evenOddFill(points(order, scale: huge)),
                                evenOddFill(points(order, scale: finite)),
                                "even-odd \(order)")
                        }
                    }
                }
            }
        }
    }

    func testSwiftAndQuartzMatchOnColoredSaturatedClippedFixture() {
        var results: [[UInt8]] = []
        for backend in [RenderBackend.swift, .quartz] {
            CanvasBackendSelection.current = backend
            let bitmap = Bitmap(width: 18, height: 10)
            for y in 0..<10 { for x in 0..<18 {
                let alpha: UInt8 = (x + y).isMultiple(of: 5) ? 96 : 255
                setPixel(bitmap, x: x, y: y,
                         (UInt8((x * 43 + y * 11) % 256),
                          UInt8((x * 7 + y * 67) % 256),
                          UInt8((x * 97 + y * 3) % 256), alpha))
            } }
            let canvas = Canvas(bitmap: bitmap, scale: 2)
            canvas.save()
            canvas.clip(to: CGRect(x: 1.5, y: 1, width: 6, height: 3))
            canvas.applyBackdropFilter(
                CanvasBackdropFilterConfiguration(
                    blurRadius: 1.25, saturation: 1.8,
                    tintColor: CGColor(red: 0.9, green: 0.95, blue: 1, alpha: 0.22),
                    intensity: 0.73),
                in: CGRect(x: 0.5, y: 0.5, width: 8, height: 4))
            canvas.restore()
            results.append(bitmap.pixels)
        }
        XCTAssertEqual(results[0], results[1])
    }

    func testFilterTargetsCurrentTransparencyBufferOnBothBackends() {
        var results: [[UInt8]] = []
        for backend in [RenderBackend.swift, .quartz] {
            CanvasBackendSelection.current = backend
            let bitmap = Bitmap(width: 5, height: 1)
            let canvas = Canvas(bitmap: bitmap, scale: 1)
            canvas.fill(rect: CGRect(x: 0, y: 0, width: 5, height: 1), color: .white)
            canvas.beginTransparencyLayer(alpha: 0.5)
            canvas.fill(rect: CGRect(x: 0, y: 0, width: 2, height: 1),
                        color: CGColor(red: 1, green: 0, blue: 0, alpha: 1))
            canvas.fill(rect: CGRect(x: 2, y: 0, width: 3, height: 1),
                        color: CGColor(red: 0, green: 0, blue: 1, alpha: 1))
            canvas.applyBackdropFilter(
                CanvasBackdropFilterConfiguration(blurRadius: 1),
                in: CGRect(x: 0, y: 0, width: 5, height: 1))
            canvas.endTransparencyLayer()
            results.append(bitmap.pixels)
        }
        // The shared filter bytes are exact; the two pre-existing group-alpha
        // compositors round 0.5 source-over in opposite directions by one.
        XCTAssertEqual(results[0].count, results[1].count)
        XCTAssertLessThanOrEqual(zip(results[0], results[1]).map {
            abs(Int($0) - Int($1))
        }.max() ?? 0, 1)
        let middle = (0 * 5 + 2) * 4
        XCTAssertGreaterThan(results[0][middle], 127)
        XCTAssertGreaterThan(results[0][middle + 2], 127)
    }

    func testHighSaturationHonestlyExposesFullPostCompositorParityRange() {
        func render(backend: RenderBackend, saturation: CGFloat) -> [UInt8] {
            CanvasBackendSelection.current = backend
            let bitmap = Bitmap(width: 1, height: 1)
            let canvas = Canvas(bitmap: bitmap, scale: 1)
            canvas.fill(
                rect: CGRect(x: 0, y: 0, width: 1, height: 1),
                color: CGColor(red: 200 / 255, green: 113 / 255,
                               blue: 76 / 255, alpha: 1))
            canvas.beginTransparencyLayer(alpha: 157 / 255)
            canvas.fill(
                rect: CGRect(x: 0, y: 0, width: 1, height: 1),
                color: CGColor(red: 48 / 255, green: 112 / 255,
                               blue: 42 / 255, alpha: 1))
            canvas.endTransparencyLayer()
            if saturation != 1 {
                canvas.applyBackdropFilter(
                    CanvasBackdropFilterConfiguration(saturation: saturation),
                    in: CGRect(x: 0, y: 0, width: 1, height: 1))
            }
            return bitmap.pixels
        }

        let swiftBefore = render(backend: .swift, saturation: 1)
        let quartzBefore = render(backend: .quartz, saturation: 1)
        XCTAssertEqual(swiftBefore, [106, 112, 55, 255])
        XCTAssertEqual(quartzBefore, [107, 112, 55, 255])
        XCTAssertEqual(zip(swiftBefore, quartzBefore).map {
            abs(Int($0) - Int($1))
        }.max(), 1, "the compositor input differs by only one count")

        let swiftAfter = render(backend: .swift, saturation: 1_000)
        let quartzAfter = render(backend: .quartz, saturation: 1_000)
        XCTAssertEqual(swiftAfter, [0, 255, 0, 255])
        XCTAssertEqual(quartzAfter, [255, 255, 0, 255])
        XCTAssertEqual(zip(swiftAfter, quartzAfter).map {
            abs(Int($0) - Int($1))
        }.max(), 255,
        "the honest post-filter parity bound is the full 0...255 channel range")
    }

    func testTranslucentBlurThenTintHasIndependentPixelGolden() {
        // Outside pixels participate in expanded blur sampling but remain
        // untinted and unwritten, distinguishing blur-then-tint from tinting
        // the source before sampling.
        let expected = [Pixel(240, 20, 10, 255), Pixel(88, 90, 140, 186),
                        Pixel(23, 119, 195, 131), Pixel(97, 134, 158, 158),
                        Pixel(75, 156, 166, 200), Pixel(0, 190, 210, 255)]
        forEachBackend { backend in
            let bitmap = Bitmap(width: 6, height: 1)
            setPixel(bitmap, x: 0, y: 0, (240, 20, 10, 255))
            setPixel(bitmap, x: 1, y: 0, (20, 220, 60, 128))
            setPixel(bitmap, x: 2, y: 0, (10, 30, 240, 64))
            setPixel(bitmap, x: 3, y: 0, (255, 0, 255, 0))
            setPixel(bitmap, x: 4, y: 0, (230, 210, 20, 255))
            setPixel(bitmap, x: 5, y: 0, (0, 190, 210, 255))
            Canvas(bitmap: bitmap, scale: 1).applyBackdropFilter(
                CanvasBackdropFilterConfiguration(
                    blurRadius: 1,
                    tintColor: CGColor(red: 0.1, green: 0.4, blue: 0.9, alpha: 0.35)),
                in: CGRect(x: 1, y: 0, width: 4, height: 1))
            XCTAssertEqual(pixels(bitmap), expected, "\(backend)")
        }
    }

    func testNestedMaskedTransparencyHasBackendSpecificPixelGoldens() {
        forEachBackend { backend in
            let bitmap = Bitmap(width: 4, height: 2)
            let canvas = Canvas(bitmap: bitmap, scale: 1)
            canvas.fill(rect: CGRect(x: 0, y: 0, width: 4, height: 2),
                        color: CGColor(red: 0.12, green: 0.18, blue: 0.25, alpha: 1))
            canvas.beginTransparencyLayer(alpha: 0.75)
            canvas.fill(rect: CGRect(x: 0, y: 0, width: 4, height: 2),
                        color: CGColor(red: 0.1, green: 0.75, blue: 0.2, alpha: 1))
            canvas.beginMaskedTransparencyLayer(
                alpha: 0.6,
                mask: .rect(CGRect(x: 0.5, y: 0.25, width: 3, height: 1.5)))
            canvas.fill(rect: CGRect(x: 0, y: 0, width: 2, height: 2),
                        color: CGColor(red: 0.9, green: 0.1, blue: 0.05, alpha: 0.8))
            canvas.fill(rect: CGRect(x: 2, y: 0, width: 2, height: 2),
                        color: CGColor(red: 0.05, green: 0.2, blue: 0.95, alpha: 1))
            canvas.fill(rect: CGRect(x: 0, y: 0, width: 4, height: 1),
                        color: CGColor(red: 1, green: 1, blue: 1, alpha: 0.25))
            canvas.applyBackdropFilter(
                CanvasBackdropFilterConfiguration(
                    blurRadius: 1,
                    tintColor: CGColor(red: 1, green: 0.8, blue: 0.2, alpha: 0.2)),
                in: CGRect(x: 0, y: 0, width: 4, height: 2))
            canvas.endTransparencyLayer()
            canvas.endTransparencyLayer()

            let expected: [Pixel]
            switch backend {
            case .swift:
                expected = [Pixel(58, 142, 56, 255), Pixel(77, 128, 73, 255),
                            Pixel(63, 128, 90, 255), Pixel(39, 141, 80, 255),
                            Pixel(58, 140, 53, 255), Pixel(74, 124, 69, 255),
                            Pixel(60, 123, 88, 255), Pixel(36, 139, 80, 255)]
            case .quartz:
                expected = [Pixel(58, 142, 55, 255), Pixel(76, 128, 73, 255),
                            Pixel(64, 128, 89, 255), Pixel(39, 141, 80, 255),
                            Pixel(57, 139, 53, 255), Pixel(74, 124, 69, 255),
                            Pixel(60, 124, 88, 255), Pixel(36, 139, 80, 255)]
            }
            XCTAssertEqual(pixels(bitmap), expected, "\(backend)")
        }
    }

    func testFractionalRotatedClipHasIndependentPixelGolden() {
        let b = Pixel(0, 40, 220, 255)
        let expected = [
            b, Pixel(3, 40, 217, 255), b, b, b,
            b, Pixel(206, 8, 42, 255), Pixel(171, 13, 72, 255),
            Pixel(78, 28, 153, 255), Pixel(4, 39, 217, 255),
            Pixel(33, 35, 192, 255), Pixel(255, 0, 0, 255),
            Pixel(255, 0, 0, 255), Pixel(255, 0, 0, 255),
            Pixel(33, 35, 192, 255), Pixel(4, 39, 217, 255),
            Pixel(78, 28, 153, 255), Pixel(171, 13, 72, 255),
            Pixel(206, 8, 42, 255), b,
            b, b, b, Pixel(3, 40, 217, 255), b,
        ]
        forEachBackend { backend in
            let bitmap = Bitmap(width: 5, height: 5)
            for y in 0..<5 { for x in 0..<5 {
                setPixel(bitmap, x: x, y: y, (0, 40, 220, 255))
            } }
            let canvas = Canvas(bitmap: bitmap, scale: 1)
            canvas.translate(x: 2.5, y: 2.5)
            canvas.concatenate(CGAffineTransform(rotationAngle: 0.35))
            canvas.clip(to: CGRect(x: -1.6, y: -1.1, width: 3.2, height: 2.2))
            canvas.applyBackdropFilter(
                CanvasBackdropFilterConfiguration(
                    tintColor: CGColor(red: 1, green: 0, blue: 0, alpha: 1)),
                in: CGRect(x: -2, y: -2, width: 4, height: 4))
            XCTAssertEqual(pixels(bitmap), expected, "\(backend)")
        }
    }

    func testHugeRadiusHasIndependentExactAxisGolden() {
        let expected = Array(repeating: Pixel(126, 126, 126, 255), count: 5)
        forEachBackend { backend in
            for vertical in [false, true] {
                let bitmap = Bitmap(width: vertical ? 1 : 5, height: vertical ? 5 : 1)
                for (index, value) in [UInt8(0), 40, 100, 180, 255].enumerated() {
                    setPixel(bitmap, x: vertical ? 0 : index,
                             y: vertical ? index : 0,
                             (value, value, value, 255))
                }
                Canvas(bitmap: bitmap, scale: 1).applyBackdropFilter(
                    CanvasBackdropFilterConfiguration(
                        blurRadius: CGFloat.greatestFiniteMagnitude),
                    in: CGRect(x: 0, y: 0,
                               width: CGFloat(bitmap.width),
                               height: CGFloat(bitmap.height)))
                XCTAssertEqual(pixels(bitmap), expected, "\(backend), vertical=\(vertical)")

                let capped = Bitmap(width: vertical ? 1 : 5,
                                    height: vertical ? 5 : 1)
                for (index, value) in [UInt8(0), 40, 100, 180, 255].enumerated() {
                    setPixel(capped, x: vertical ? 0 : index,
                             y: vertical ? index : 0,
                             (value, value, value, 255))
                }
                Canvas(bitmap: capped, scale: 1).applyBackdropFilter(
                    CanvasBackdropFilterConfiguration(blurRadius: 20),
                    in: CGRect(x: 0, y: 0,
                               width: CGFloat(capped.width),
                               height: CGFloat(capped.height)))
                XCTAssertEqual(capped.pixels, bitmap.pixels,
                               "documented 4 * max-axis sigma cap, \(backend)")
            }
        }
    }

    private func patternedBitmap(width: Int, height: Int) -> Bitmap {
        let bitmap = Bitmap(width: width, height: height)
        for y in 0..<height { for x in 0..<width {
            setPixel(bitmap, x: x, y: y,
                     (UInt8((x * 47 + y * 19 + 3) % 256),
                      UInt8((x * 11 + y * 73 + 5) % 256),
                      UInt8((x * 89 + y * 31 + 7) % 256), 255))
        } }
        return bitmap
    }

    private func pixels(_ bitmap: Bitmap) -> [Pixel] {
        (0..<bitmap.height).flatMap { y in
            (0..<bitmap.width).map { x in pixel(bitmap, x: x, y: y) }
        }
    }

    private func assertSolid(_ bitmap: Bitmap, _ expected: Pixel,
                             _ message: String,
                             file: StaticString = #filePath, line: UInt = #line) {
        for y in 0..<bitmap.height { for x in 0..<bitmap.width {
            XCTAssertEqual(pixel(bitmap, x: x, y: y), expected,
                           "\(message) at \(x),\(y)", file: file, line: line)
        } }
    }
}
