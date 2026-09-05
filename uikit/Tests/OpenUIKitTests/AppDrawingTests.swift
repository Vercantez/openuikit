// App-compat cluster tests: image loading/encoding, UIBezierPath geometry,
// UIView.draw(_:) support + its cache invalidation, UIGraphicsImageRenderer,
// and the new controls' layout math (the PIXELS of the controls are held to
// account by the oracle fixtures control_activity / control_slider /
// control_segmented / control_dark — these tests cover the geometry and the
// behavior around them).
import XCTest
import Foundation
@testable import OpenUIKit

/// A view that draws through the app-facing `draw(_ rect:)` hook.
#if !os(Linux)
@MainActor
#endif
private final class CustomDrawView: UIView {
    var fillColor: UIColor = .red
    var drawCount = 0
    override func draw(_ rect: CGRect) {
        drawCount += 1
        let path = UIBezierPath(rect: rect.insetBy(dx: 2, dy: 2))
        fillColor.setFill()
        path.fill()
    }
}

#if !os(Linux)
@MainActor
#endif
final class AppDrawingTests: XCTestCase {

    private var savedSearchPaths: [String] = []

    override func setUp() {
        super.setUp()
        TextTestSupport.configureResourceRoot()
        savedSearchPaths = OpenUIKitRuntime.imageSearchPaths
    }
    override func tearDown() {
        OpenUIKitRuntime.imageSearchPaths = savedSearchPaths
        UIImage.clearNamedCache()
        super.tearDown()
    }

    // MARK: - Image codec

    private func gradientBitmap(width: Int, height: Int, alpha: UInt8 = 255) -> Bitmap {
        let b = Bitmap(width: width, height: height)
        for y in 0..<height {
            for x in 0..<width {
                let o = (y * width + x) * 4
                b.pixels[o] = UInt8((x * 255) / Swift.max(1, width - 1))
                b.pixels[o + 1] = UInt8((y * 255) / Swift.max(1, height - 1))
                b.pixels[o + 2] = 128
                b.pixels[o + 3] = alpha
            }
        }
        return b
    }

    func testPNGRoundTripIsExact() {
        let src = gradientBitmap(width: 17, height: 9)
        guard let data = ImageCodec.encodePNG(src) else { return XCTFail("encode failed") }
        // PNG magic.
        XCTAssertEqual(Array(data.prefix(4)), [0x89, 0x50, 0x4E, 0x47])
        guard let back = ImageCodec.decode(data) else { return XCTFail("decode failed") }
        XCTAssertEqual(back.width, 17)
        XCTAssertEqual(back.height, 9)
        XCTAssertEqual(back.pixels, src.pixels, "PNG round trip must be lossless")
    }

    func testPNGRoundTripPreservesStraightAlpha() {
        // The whole reason the codec bypasses QZImage: premultiplied storage
        // would destroy the color of low-alpha pixels.
        let src = Bitmap(width: 2, height: 1)
        src.pixels = [200, 100, 50, 3, 10, 220, 30, 255]
        guard let data = ImageCodec.encodePNG(src),
              let back = ImageCodec.decode(data) else { return XCTFail("codec failed") }
        XCTAssertEqual(back.pixels, src.pixels)
    }

    func testJPEGEncodesAndDecodesApproximately() {
        let src = gradientBitmap(width: 24, height: 16)
        guard let data = ImageCodec.encodeJPEG(src, quality: 0.9) else {
            return XCTFail("jpeg encode failed")
        }
        XCTAssertEqual(Array(data.prefix(2)), [0xFF, 0xD8])
        guard let back = ImageCodec.decode(data) else { return XCTFail("jpeg decode failed") }
        XCTAssertEqual(back.width, 24)
        XCTAssertEqual(back.height, 16)
        // Lossy, but a smooth gradient must survive within a few counts.
        var maxDelta = 0
        for i in stride(from: 0, to: back.pixels.count, by: 4) {
            for c in 0..<3 {
                maxDelta = Swift.max(maxDelta,
                                     abs(Int(back.pixels[i + c]) - Int(src.pixels[i + c])))
            }
            XCTAssertEqual(back.pixels[i + 3], 255, "JPEG has no alpha channel")
        }
        XCTAssertLessThan(maxDelta, 24, "quality 0.9 JPEG drifted too far")
    }

    func testDecodeRejectsNonImageData() {
        XCTAssertNil(ImageCodec.decode([]))
        XCTAssertNil(ImageCodec.decode([0x00, 0x01, 0x02, 0x03, 0x04]))
        XCTAssertNil(UIImage(data: Array("not an image".utf8)))
    }

    func testUIImageDataRoundTripThroughPublicAPI() {
        let img = UIImage(bitmap: gradientBitmap(width: 8, height: 4), scale: 2)
        guard let png = img.pngData(), let back = UIImage(data: png, scale: 2) else {
            return XCTFail("pngData/UIImage(data:) failed")
        }
        XCTAssertEqual(back.size, img.size)
        XCTAssertEqual(back.bitmap.pixels, img.bitmap.pixels)
        XCTAssertNotNil(img.jpegData(compressionQuality: 0.5))
    }

    // MARK: - File / named loading

    private func withTempDir(_ body: (String) throws -> Void) rethrows {
        let dir = NSTemporaryDirectory() + "openuikit-imgtest-\(UInt32.random(in: 0...UInt32.max))"
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(atPath: dir) }
        try body(dir)
    }

    private func write(_ bitmap: Bitmap, to path: String) {
        let data = ImageCodec.encodePNG(bitmap)!
        FileManager.default.createFile(atPath: path, contents: Data(data))
    }

    func testContentsOfFileReadsScaleFromNameSuffix() {
        withTempDir { dir in
            write(gradientBitmap(width: 20, height: 10), to: dir + "/plain.png")
            write(gradientBitmap(width: 40, height: 20), to: dir + "/plain@2x.png")
            write(gradientBitmap(width: 60, height: 30), to: dir + "/plain@3x.png")

            let one = UIImage(contentsOfFile: dir + "/plain.png")
            XCTAssertEqual(one?.scale, 1)
            XCTAssertEqual(one?.size, CGSize(width: 20, height: 10))

            let two = UIImage(contentsOfFile: dir + "/plain@2x.png")
            XCTAssertEqual(two?.scale, 2)
            XCTAssertEqual(two?.size, CGSize(width: 20, height: 10))

            let three = UIImage(contentsOfFile: dir + "/plain@3x.png")
            XCTAssertEqual(three?.scale, 3)
            XCTAssertEqual(three?.size, CGSize(width: 20, height: 10))

            XCTAssertNil(UIImage(contentsOfFile: dir + "/missing.png"))
        }
    }

    func testNamedPrefersTheScreenScaleVariantAndFallsBack() {
        withTempDir { dir in
            write(gradientBitmap(width: 20, height: 10), to: dir + "/icon.png")
            write(gradientBitmap(width: 40, height: 20), to: dir + "/icon@2x.png")
            write(gradientBitmap(width: 12, height: 12), to: dir + "/only1x.png")
            write(gradientBitmap(width: 30, height: 30), to: dir + "/photo.jpg")

            // Empty search paths: the library resolves nothing by itself.
            OpenUIKitRuntime.imageSearchPaths = []
            UIImage.clearNamedCache()
            XCTAssertNil(UIImage.named("icon"))

            OpenUIKitRuntime.imageSearchPaths = [dir]
            UIImage.clearNamedCache()
            let saved = OpenUIKitRuntime.imageScreenScale
            defer { OpenUIKitRuntime.imageScreenScale = saved }

            OpenUIKitRuntime.imageScreenScale = 2
            XCTAssertEqual(UIImage.named("icon")?.scale, 2)
            UIImage.clearNamedCache()
            OpenUIKitRuntime.imageScreenScale = 1
            XCTAssertEqual(UIImage.named("icon")?.scale, 1)

            // No @2x variant: falls back to the 1x file even at scale 2.
            UIImage.clearNamedCache()
            OpenUIKitRuntime.imageScreenScale = 2
            XCTAssertEqual(UIImage.named("only1x")?.scale, 1)
            // Extension inferred (png, then jpg/jpeg) and explicit names work.
            XCTAssertNotNil(UIImage.named("photo"))
            XCTAssertNotNil(UIImage.named("photo.jpg"))
            XCTAssertNil(UIImage.named("nope"))
        }
    }

    func testSplitExtensionAndScaleFromFileName() {
        XCTAssertEqual(UIImage.scaleFromFileName("/a/b/c@2x.png"), 2)
        XCTAssertEqual(UIImage.scaleFromFileName("c@3x.jpg"), 3)
        XCTAssertEqual(UIImage.scaleFromFileName("c.png"), 1)
        XCTAssertEqual(UIImage.scaleFromFileName("/dir.with.dots/file"), 1)
        let (base, ext) = UIImage.splitExtension("/dir.with.dots/file")
        XCTAssertEqual(base, "/dir.with.dots/file")
        XCTAssertNil(ext)
        let (b2, e2) = UIImage.splitExtension("art/logo@2x.png")
        XCTAssertEqual(b2, "art/logo@2x")
        XCTAssertEqual(e2, "png")
    }

    func testWithTintColorAndRenderingMode() {
        let src = Bitmap(width: 2, height: 1)
        src.pixels = [10, 20, 30, 255, 40, 50, 60, 128]
        let img = UIImage(bitmap: src, scale: 2)
        XCTAssertEqual(img.renderingMode, .automatic)
        XCTAssertEqual(img.withRenderingMode(.alwaysTemplate).renderingMode, .alwaysTemplate)
        // Sharing the backing store is UIKit's behavior (images are immutable).
        XCTAssertTrue(img.withRenderingMode(.alwaysTemplate).bitmap === img.bitmap)

        let tinted = img.withTintColor(UIColor(red: 1, green: 0, blue: 0, alpha: 1))
        XCTAssertEqual(tinted.renderingMode, .automatic)
        XCTAssertEqual(Array(tinted.bitmap.pixels), [255, 0, 0, 255, 255, 0, 0, 128],
                       "tint replaces color, keeps per-pixel alpha")
        XCTAssertEqual(tinted.scale, img.scale)
    }

    // MARK: - UIBezierPath

    func testRectAndRoundedRectConstruction() {
        let r = CGRect(x: 10, y: 20, width: 100, height: 50)
        let rect = UIBezierPath(rect: r)
        XCTAssertEqual(rect.cgPath.elements.count, 5)  // move + 3 lines + close
        XCTAssertEqual(rect.bounds, r)
        XCTAssertTrue(rect.contains(CGPoint(x: 11, y: 21)))
        XCTAssertFalse(rect.contains(CGPoint(x: 9, y: 21)))

        let rounded = UIBezierPath(roundedRect: r, cornerRadius: 10)
        XCTAssertEqual(rounded.bounds.width, 100, accuracy: 0.01)
        XCTAssertEqual(rounded.bounds.height, 50, accuracy: 0.01)
        // Corners are cut away.
        XCTAssertFalse(rounded.contains(CGPoint(x: 10.2, y: 20.2)))
        XCTAssertTrue(rounded.contains(CGPoint(x: 60, y: 45)))
    }

    func testOvalMatchesTheKappaEllipse() {
        let r = CGRect(x: 0, y: 0, width: 40, height: 20)
        let oval = UIBezierPath(ovalIn: r)
        XCTAssertEqual(oval.bounds.minX, 0, accuracy: 0.05)
        XCTAssertEqual(oval.bounds.maxX, 40, accuracy: 0.05)
        XCTAssertEqual(oval.bounds.minY, 0, accuracy: 0.05)
        XCTAssertEqual(oval.bounds.maxY, 20, accuracy: 0.05)
        XCTAssertTrue(oval.contains(CGPoint(x: 20, y: 10)))
        XCTAssertFalse(oval.contains(CGPoint(x: 1, y: 1)))   // outside the ellipse
        // On-axis extremes are exactly on the ellipse.
        XCTAssertTrue(oval.contains(CGPoint(x: 39.5, y: 10)))
        XCTAssertFalse(oval.contains(CGPoint(x: 40.5, y: 10)))
    }

    func testRoundedRectByRoundingCorners() {
        let r = CGRect(x: 0, y: 0, width: 40, height: 40)
        let p = UIBezierPath(roundedRect: r, byRoundingCorners: [.topLeft, .bottomRight],
                             cornerRadii: CGSize(width: 10, height: 10))
        // Rounded corners are cut, the other two stay square.
        XCTAssertFalse(p.contains(CGPoint(x: 0.5, y: 0.5)))
        XCTAssertFalse(p.contains(CGPoint(x: 39.5, y: 39.5)))
        XCTAssertTrue(p.contains(CGPoint(x: 39.5, y: 0.5)))
        XCTAssertTrue(p.contains(CGPoint(x: 0.5, y: 39.5)))
    }

    func testArcGeometryAndCurrentPoint() {
        let p = UIBezierPath()
        p.addArc(withCenter: CGPoint(x: 50, y: 50), radius: 20,
                 startAngle: 0, endAngle: .pi, clockwise: true)
        // Starts at (70, 50); a clockwise (screen) half turn ends at (30, 50)
        // through the BOTTOM of the circle (y down).
        let cur = p.currentPoint
        XCTAssertEqual(cur?.x ?? 0, 30, accuracy: 0.01)
        XCTAssertEqual(cur?.y ?? 0, 50, accuracy: 0.01)
        XCTAssertEqual(p.bounds.maxY, 70, accuracy: 0.05)
        XCTAssertEqual(p.bounds.minY, 50, accuracy: 0.05)

        let full = UIBezierPath(arcCenter: .zero, radius: 10, startAngle: 0,
                                endAngle: 2 * .pi, clockwise: true)
        XCTAssertEqual(full.bounds.width, 20, accuracy: 0.05)
        XCTAssertEqual(full.bounds.height, 20, accuracy: 0.05)
    }

    func testAppendApplyAndEvenOddRule() {
        let outer = UIBezierPath(rect: CGRect(x: 0, y: 0, width: 40, height: 40))
        let inner = UIBezierPath(rect: CGRect(x: 10, y: 10, width: 20, height: 20))
        outer.append(inner)
        XCTAssertEqual(outer.cgPath.elements.count, 10)
        // Nonzero: both squares wind the same way, so the middle is filled.
        XCTAssertTrue(outer.contains(CGPoint(x: 20, y: 20)))
        outer.usesEvenOddFillRule = true
        XCTAssertFalse(outer.contains(CGPoint(x: 20, y: 20)), "even-odd punches a hole")

        let moved = UIBezierPath(rect: CGRect(x: 0, y: 0, width: 10, height: 10))
        moved.apply(CGAffineTransform(translationX: 5, y: 7))
        XCTAssertEqual(moved.bounds.minX, 5)
        XCTAssertEqual(moved.bounds.minY, 7)

        let empty = UIBezierPath()
        XCTAssertTrue(empty.isEmpty)
        XCTAssertNil(empty.currentPoint)
        moved.removeAllPoints()
        XCTAssertTrue(moved.isEmpty)
    }

    // MARK: - Current context + UIGraphicsImageRenderer

    func testImageRendererProducesScaledPixels() {
        let renderer = UIGraphicsImageRenderer(
            size: CGSize(width: 10, height: 6),
            format: UIGraphicsImageRendererFormat(scale: 2, opaque: false))
        let image = renderer.image { ctx in
            XCTAssertTrue(UIGraphicsGetCurrentContext() === ctx.cgContext)
            UIColor(red: 0, green: 0, blue: 1, alpha: 1).setFill()
            UIBezierPath(rect: CGRect(x: 0, y: 0, width: 10, height: 3)).fill()
        }
        XCTAssertEqual(image.scale, 2)
        XCTAssertEqual(image.bitmap.width, 20)
        XCTAssertEqual(image.bitmap.height, 12)
        XCTAssertEqual(image.size, CGSize(width: 10, height: 6))
        func px(_ x: Int, _ y: Int) -> [UInt8] {
            let o = (y * image.bitmap.width + x) * 4
            return Array(image.bitmap.pixels[o..<(o + 4)])
        }
        XCTAssertEqual(px(5, 2), [0, 0, 255, 255], "top half painted blue")
        XCTAssertEqual(px(5, 9), [0, 0, 0, 0], "bottom half untouched (transparent)")
        // The context stack is balanced again.
        XCTAssertNil(UIGraphicsGetCurrentContext())
    }

    func testOpaqueFormatStartsOpaque() {
        let r = UIGraphicsImageRenderer(size: CGSize(width: 4, height: 4),
                                        format: UIGraphicsImageRendererFormat(scale: 1,
                                                                              opaque: true))
        let image = r.image { _ in }
        XCTAssertEqual(image.bitmap.pixels[3], 255)
        XCTAssertNotNil(r.pngData { _ in }.first)
    }

    func testStrokeUsesTheCurrentStrokeColorAndLineWidth() {
        let renderer = UIGraphicsImageRenderer(
            size: CGSize(width: 20, height: 20),
            format: UIGraphicsImageRendererFormat(scale: 1, opaque: false))
        let image = renderer.image { _ in
            UIColor(red: 1, green: 0, blue: 0, alpha: 1).setStroke()
            let p = UIBezierPath()
            p.move(to: CGPoint(x: 0, y: 10))
            p.addLine(to: CGPoint(x: 20, y: 10))
            p.lineWidth = 4
            p.lineCapStyle = .round
            p.stroke()
        }
        let o = (10 * 20 + 10) * 4
        XCTAssertEqual(image.bitmap.pixels[o], 255)
        XCTAssertGreaterThan(image.bitmap.pixels[o + 3], 200, "stroke painted the mid line")
    }

    // MARK: - UIView.draw(_:) support and invalidation

    func testDrawOverrideRendersThroughTheContentPath() {
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        root.backgroundColor = .white
        let custom = CustomDrawView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        custom.fillColor = UIColor(red: 0, green: 0, blue: 1, alpha: 1)
        root.addSubview(custom)

        let bmp = UIRenderer.render(root, scale: 1)
        func px(_ x: Int, _ y: Int) -> [UInt8] {
            let o = (y * bmp.width + x) * 4
            return Array(bmp.pixels[o..<(o + 4)])
        }
        XCTAssertGreaterThan(custom.drawCount, 0, "draw(_:) was called")
        XCTAssertEqual(px(10, 10), [0, 0, 255, 255], "inset rect is painted")
        XCTAssertEqual(px(0, 0), [255, 255, 255, 255], "2pt inset stays background")
    }

    func testSetNeedsDisplayInvalidatesCachedContents() {
        let saved = OpenUIKitRuntime.layerCaching
        OpenUIKitRuntime.layerCaching = true
        defer { OpenUIKitRuntime.layerCaching = saved }

        let root = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        root.backgroundColor = .white
        let custom = CustomDrawView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        custom.fillColor = UIColor(red: 0, green: 0, blue: 1, alpha: 1)
        root.addSubview(custom)

        _ = UIRenderer.render(root, scale: 1)
        let drawsAfterFirst = custom.drawCount
        _ = UIRenderer.render(root, scale: 1)
        XCTAssertEqual(custom.drawCount, drawsAfterFirst,
                       "unchanged content must come from the cache")

        // Changing drawing state WITHOUT setNeedsDisplay keeps the cache
        // (UIKit's contract), calling it drops the cached image.
        custom.fillColor = UIColor(red: 0, green: 1, blue: 0, alpha: 1)
        var bmp = UIRenderer.render(root, scale: 1)
        var o = (10 * bmp.width + 10) * 4
        XCTAssertEqual(Array(bmp.pixels[o..<(o + 3)]), [0, 0, 255], "still the cached blue")

        custom.setNeedsDisplay()
        bmp = UIRenderer.render(root, scale: 1)
        o = (10 * bmp.width + 10) * 4
        XCTAssertEqual(Array(bmp.pixels[o..<(o + 3)]), [0, 255, 0], "redrawn after invalidation")
        XCTAssertGreaterThan(custom.drawCount, drawsAfterFirst)
    }

    // MARK: - Controls

    func testSliderGeometryMatchesTheOracleRules() {
        let s = UISlider(frame: CGRect(x: 0, y: 0, width: 280, height: 40))
        s.value = 0.35
        XCTAssertEqual(s.intrinsicContentSize.height, 34)
        XCTAssertEqual(s.intrinsicContentSize.width, UIView.noIntrinsicMetric)
        // Oracle dump: lens frame [85, 8, 37, 24] for value .35 of 280.
        XCTAssertEqual(s.thumbRect.minX, 85, accuracy: 0.001)
        XCTAssertEqual(s.thumbRect.minY, 8, accuracy: 0.001)
        XCTAssertEqual(s.thumbRect.width, 37)
        XCTAssertEqual(s.thumbRect.height, 24)
        // ... and the fill uses the UNROUNDED centre: 85.05 + 18.5.
        XCTAssertEqual(s.exactThumbOffsetX + 18.5, 103.55, accuracy: 0.001)
        // Track: 6pt, vertically centred.
        XCTAssertEqual(s.trackRect.minY, 17)
        XCTAssertEqual(s.trackRect.height, 6)
        // Origin rounds away from zero at the .5 tie (golden control_slider).
        s.value = 0.5
        XCTAssertEqual(s.thumbRect.minX, 122, accuracy: 0.001)
    }

    func testSliderClampsAndMapsCustomRanges() {
        let s = UISlider(frame: CGRect(x: 0, y: 0, width: 200, height: 34))
        s.minimumValue = 1
        s.maximumValue = 5
        s.value = 3
        XCTAssertEqual(s.fraction, 0.5, accuracy: 0.0001)
        s.value = 99
        XCTAssertEqual(s.value, 5)
        s.value = -4
        XCTAssertEqual(s.value, 1)
        XCTAssertEqual(s.value(forThumbOriginX: 0), 1)
        XCTAssertEqual(s.value(forThumbOriginX: 163), 5)
        XCTAssertEqual(s.value(forThumbOriginX: 81.5), 3, accuracy: 0.0001)
    }

    func testSliderDragUpdatesValueAndFiresValueChanged() {
        let s = UISlider(frame: CGRect(x: 0, y: 0, width: 200, height: 34))
        var changes = 0
        s.addTarget(for: .valueChanged) { _, _ in changes += 1 }
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 200, height: 100))
        window.addSubview(s)
        // Grab the thumb (starts at x 0..37) and drag it to the middle.
        window.sendTouch(.began, at: CGPoint(x: 18, y: 17), timestamp: 0, touchID: 0)
        window.sendTouch(.moved, at: CGPoint(x: 100, y: 17), timestamp: 0.1, touchID: 0)
        window.sendTouch(.ended, at: CGPoint(x: 100, y: 17), timestamp: 0.2, touchID: 0)
        XCTAssertEqual(s.value, Float((100 - 18) / 163.0), accuracy: 0.001)
        XCTAssertGreaterThan(changes, 0)
    }

    func testSegmentedControlSegmentsSplitWithIntegerFloorBoundaries() {
        let sc = UISegmentedControl(items: ["One", "Two", "Three"])
        sc.frame = CGRect(x: 0, y: 0, width: 280, height: 32)
        sc.selectedSegmentIndex = 1
        XCTAssertEqual(sc.numberOfSegments, 3)
        // Oracle dump: segments at 0/93/186 with widths 93/93/94.
        XCTAssertEqual(sc.segmentRect(at: 0), CGRect(x: 0, y: 0, width: 93, height: 32))
        XCTAssertEqual(sc.segmentRect(at: 1), CGRect(x: 93, y: 0, width: 93, height: 32))
        XCTAssertEqual(sc.segmentRect(at: 2), CGRect(x: 186, y: 0, width: 94, height: 32))
    }

    func testSegmentedControlLabelsAreCentredAndWeightedBySelection() {
        let sc = UISegmentedControl(items: ["One", "Two", "Three"])
        sc.frame = CGRect(x: 0, y: 0, width: 300, height: 32)
        sc.selectedSegmentIndex = 2
        sc.layoutIfNeeded()
        let labels = sc.subviews.compactMap { $0 as? UILabel }
        XCTAssertEqual(labels.count, 3)
        // Oracle dump (300 wide, "Three" selected) in SEGMENT-local
        // coordinates: 37 / 37.5 / 31.5 — i.e. 37 / 137.5 / 231.5 in the
        // control, all with y 8 and height 16.
        XCTAssertEqual(labels[0].frame.minX, 37, accuracy: 0.001)
        XCTAssertEqual(labels[1].frame.minX, 137.5, accuracy: 0.001)
        XCTAssertEqual(labels[2].frame.minX, 231.5, accuracy: 0.001)
        for l in labels {
            XCTAssertEqual(l.frame.minY, 8, accuracy: 0.001)
            XCTAssertEqual(l.frame.height, 16, accuracy: 0.001)
        }
        XCTAssertEqual(labels[2].font.weight, .medium, "the selected title is medium")
        XCTAssertEqual(labels[0].font.weight, .regular)
        XCTAssertEqual(labels[0].font.pointSize, 13)
    }

    func testSegmentedControlMutationAndSelection() {
        let sc = UISegmentedControl(items: ["A", "B"])
        sc.frame = CGRect(x: 0, y: 0, width: 100, height: 32)
        sc.insertSegment(withTitle: "C", at: 2)
        XCTAssertEqual(sc.numberOfSegments, 3)
        XCTAssertEqual(sc.titleForSegment(at: 2), "C")
        sc.setTitle("Z", forSegmentAt: 0)
        XCTAssertEqual(sc.titleForSegment(at: 0), "Z")
        sc.removeSegment(at: 1)
        XCTAssertEqual(sc.numberOfSegments, 2)
        XCTAssertEqual(sc.titleForSegment(at: 1), "C")

        var changes = 0
        sc.selectedSegmentIndex = 0
        sc.addTarget(for: .valueChanged) { _, _ in changes += 1 }
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        window.addSubview(sc)
        window.sendTouch(.began, at: CGPoint(x: 75, y: 16), timestamp: 0, touchID: 0)
        window.sendTouch(.ended, at: CGPoint(x: 75, y: 16), timestamp: 0.1, touchID: 0)
        XCTAssertEqual(sc.selectedSegmentIndex, 1)
        XCTAssertEqual(changes, 1)

        sc.removeAllSegments()
        XCTAssertEqual(sc.numberOfSegments, 0)
        XCTAssertEqual(sc.selectedSegmentIndex, UISegmentedControl.noSegment)
    }

    func testActivityIndicatorMetricsAndAnimationStepping() {
        let medium = UIActivityIndicatorView(style: .medium)
        XCTAssertEqual(medium.intrinsicContentSize, CGSize(width: 20, height: 20))
        let large = UIActivityIndicatorView(style: .large)
        XCTAssertEqual(large.intrinsicContentSize, CGSize(width: 37, height: 37))
        XCTAssertFalse(medium.isAnimating)

        let savedTime = OpenUIKitRuntime.animationTime
        let savedCut = OpenUIKitRuntime.systemFontCut
        defer {
            OpenUIKitRuntime.animationTime = savedTime
            OpenUIKitRuntime.systemFontCut = savedCut
        }
        OpenUIKitRuntime.animationTime = 10
        large.startAnimating()
        XCTAssertTrue(large.isAnimating)
        XCTAssertEqual(large.currentStep, 0)
        OpenUIKitRuntime.animationTime = 10 + 3.0 / 8.0 + 0.01
        XCTAssertEqual(large.currentStep, 3)
        OpenUIKitRuntime.animationTime = 10 + 1.0 + 0.01     // one full turn
        XCTAssertEqual(large.currentStep, 0)
        // Frozen SimScene pose is also step 0 under the iOS cut.
        OpenUIKitRuntime.systemFontCut = .iOS
        OpenUIKitRuntime.animationTime = 10
        XCTAssertEqual(large.currentStep, 0)
        // MEASURED spinnerprobe act_n0..24: 16 frames / 0.8 s → 0.1 s
        // per 45° spoke. Pager spinner-frame-9 is 0.15 s = step 1.
        large.startAnimating()
        OpenUIKitRuntime.animationTime = 10 + 0.15
        XCTAssertEqual(large.currentStep, 1)
        large.stopAnimating()
        XCTAssertEqual(large.currentStep, 0)

        // MEASURED Pager t200.dark, SE 2x: 9 o'clock core (120,120,125)
        // over black at blade α=217/255 inverts to (141,141,147).
        let savedTraits = UITraitCollection.current
        UITraitCollection.current = UITraitCollection(userInterfaceStyle: .dark,
                                                      displayScale: 2)
        let dark = UIActivityIndicatorView.defaultColor
            .resolvedCGColor(with: UITraitCollection.current)
        UITraitCollection.current = savedTraits
        XCTAssertEqual((dark.red * 255).rounded(), 141)
        XCTAssertEqual((dark.green * 255).rounded(), 141)
        XCTAssertEqual((dark.blue * 255).rounded(), 147)
        XCTAssertEqual(dark.alpha, 1, accuracy: 1e-9)
    }

    func testPageControlLayoutMatchesTheOracleRules() {
        let pc = UIPageControl(frame: CGRect(x: 0, y: 0, width: 280, height: 30))
        pc.numberOfPages = 4
        pc.currentPage = 1
        // Oracle dump: content view [94, 2, 92, 26] for 4 pages in 280 pt.
        XCTAssertEqual(pc.intrinsicContentSize, CGSize(width: 92, height: 26))
        XCTAssertEqual(pc.size(forNumberOfPages: 7), CGSize(width: 146, height: 26))
        // First dot centre: 94 + 14 + 5 (+ the fitted -0.19 symbol offset).
        let c0 = pc.indicatorCenter(at: 0)
        XCTAssertEqual(c0.x, 113 - 0.19, accuracy: 0.001)
        XCTAssertEqual(c0.y, 2 + 13 + 0.19, accuracy: 0.001)
        XCTAssertEqual(pc.indicatorCenter(at: 3).x - c0.x, 54, accuracy: 0.001)

        // currentPage clamps to the page count.
        pc.currentPage = 9
        XCTAssertEqual(pc.currentPage, 3)
        pc.numberOfPages = 2
        XCTAssertEqual(pc.currentPage, 1)

        // Tap on the trailing half advances one page and fires .valueChanged.
        var changes = 0
        pc.numberOfPages = 4
        pc.currentPage = 1
        pc.addTarget(for: .valueChanged) { _, _ in changes += 1 }
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 280, height: 60))
        window.addSubview(pc)
        window.sendTouch(.began, at: CGPoint(x: 200, y: 15), timestamp: 0, touchID: 0)
        window.sendTouch(.ended, at: CGPoint(x: 200, y: 15), timestamp: 0.1, touchID: 0)
        XCTAssertEqual(pc.currentPage, 2)
        XCTAssertEqual(changes, 1)
    }

    func testStoppedIndicatorDrawsNothingWhenItHidesWhenStopped() {
        func renderIndicator(_ configure: (UIActivityIndicatorView) -> Void) -> Bitmap {
            let root = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
            let a = UIActivityIndicatorView(style: .medium)
            a.frame = root.bounds
            configure(a)
            root.addSubview(a)
            return UIRenderer.render(root, scale: 1)
        }
        func inked(_ b: Bitmap) -> Int {
            var n = 0
            var i = 3
            while i < b.pixels.count { if b.pixels[i] != 0 { n += 1 }; i += 4 }
            return n
        }
        XCTAssertEqual(inked(renderIndicator { $0.stopAnimating() }), 0)
        XCTAssertGreaterThan(inked(renderIndicator { $0.startAnimating() }), 0)
        XCTAssertGreaterThan(inked(renderIndicator {
            $0.hidesWhenStopped = false
            $0.stopAnimating()
        }), 0)
    }
}
