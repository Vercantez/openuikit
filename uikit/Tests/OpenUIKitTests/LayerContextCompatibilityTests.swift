// Focus UIHelpers compatibility: explicit CALayer trees, CAGradientLayer,
// CALayer.render(in:), and the legacy UIGraphics image-context stack.
import XCTest
@testable import OpenUIKit

private typealias PortableLayer = OpenUIKit.CALayer
private typealias PortableGradientLayer = OpenUIKit.CAGradientLayer
private typealias PortableColor = OpenUIKit.CGColor

#if !os(Linux)
@MainActor
#endif
private final class LayerLayoutDelegateProbe: OpenUIKit.CALayerDelegate {
    private(set) var layers: [PortableLayer] = []

    func layoutSublayers(of layer: PortableLayer) {
        layers.append(layer)
    }
}

#if !os(Linux)
@MainActor
#endif
private final class LayerLayoutViewProbe: UIView {
    let gradient = PortableGradientLayer()
    private(set) var callbacks: [String] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.insertSublayer(gradient, at: 0)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        callbacks.append("layoutSubviews")
        super.layoutSubviews()
    }

    override func layoutSublayers(of layer: PortableLayer) {
        callbacks.append("layoutSublayers.begin")
        super.layoutSublayers(of: layer)
        gradient.frame = bounds
        callbacks.append("layoutSublayers.end")
    }
}

#if !os(Linux)
@MainActor
#endif
final class LayerContextCompatibilityTests: XCTestCase {
    private var savedBackend: RenderBackend = CanvasBackendSelection.current
    private var savedCompositor: RenderCompositor = OpenUIKitRuntime.compositor
    private var savedScale: CGFloat = OpenUIKitRuntime.imageScreenScale

    override func setUp() {
        super.setUp()
        TextTestSupport.configureResourceRoot()
        savedBackend = CanvasBackendSelection.current
        savedCompositor = OpenUIKitRuntime.compositor
        savedScale = OpenUIKitRuntime.imageScreenScale
        XCTAssertNil(UIGraphicsGetCurrentContext())
    }

    override func tearDown() {
        CanvasBackendSelection.current = savedBackend
        OpenUIKitRuntime.compositor = savedCompositor
        OpenUIKitRuntime.imageScreenScale = savedScale
        while UIGraphicsGetCurrentContext() != nil { UIGraphicsEndImageContext() }
        super.tearDown()
    }

    private func pixel(_ bitmap: Bitmap, x: Int, y: Int) -> [UInt8] {
        let offset = (y * bitmap.width + x) * 4
        return Array(bitmap.pixels[offset..<(offset + 4)])
    }

    func testFilterStorageOpacityAndBoundedKeyValueCompatibility() throws {
        struct FilterToken: CustomStringConvertible {
            let description: String
        }

        let layer = PortableLayer()
        let gaussian = FilterToken(description: "gaussianBlur")
        layer.filters = [gaussian]
        layer.isOpaque = false
        layer.contentsScale = 3
        layer.setValue(CGFloat(2.5), forKey: "scale")
        layer.setValue(
            NSNumber(value: 18.25),
            forKeyPath: "filters.gaussianBlur.inputRadius"
        )

        XCTAssertEqual(layer.filters?.count, 1)
        XCTAssertEqual("\(try XCTUnwrap(layer.filters?.first))", "gaussianBlur")
        XCTAssertFalse(layer.isOpaque)
        XCTAssertEqual(layer.value(forKey: "contentsScale") as? CGFloat, 3)
        XCTAssertEqual(layer.value(forKey: "scale") as? CGFloat, 2.5)
        XCTAssertEqual(
            layer.value(forKeyPath: "filters.gaussianBlur.inputRadius") as? CGFloat,
            18.25
        )

        layer.setValue(nil, forKeyPath: "filters.gaussianBlur.inputRadius")
        XCTAssertNil(layer.value(forKeyPath: "filters.gaussianBlur.inputRadius"))
    }

    func testBlurEffectPublishesCanonicalGaussianFilterLayer() throws {
        let effectView = UIVisualEffectView(effect: UIBlurEffect(style: .regular))
        effectView.frame = CGRect(x: 0, y: 0, width: 100, height: 40)

        let filterLayer = try XCTUnwrap(effectView.layer.sublayers?.first)
        let filter = try XCTUnwrap(filterLayer.filters?.first)
        XCTAssertEqual("\(filter)", "gaussianBlur")
        XCTAssertFalse(filterLayer.isOpaque)
        XCTAssertEqual(filterLayer.frame, effectView.bounds)

        let backdrop = try XCTUnwrap(effectView.subviews.first)
        XCTAssertEqual("\(try XCTUnwrap(backdrop.layer.filters?.first))", "gaussianBlur")
    }

    func testUIViewDescriptionCarriesDynamicClassIdentityAndGeometry() {
        let view = LayerLayoutViewProbe(
            frame: CGRect(x: 3, y: 4, width: 50, height: 20))
        XCTAssertTrue(view.description.hasPrefix("<LayerLayoutViewProbe:"))
        XCTAssertTrue(view.description.contains("frame ="))
        XCTAssertTrue(view.description.contains("bounds ="))
        XCTAssertTrue(view.description.contains("0x"))
    }

    func testCAFilterRuntimeMetadataAndBoundedInputsFailClosed() throws {
#if canImport(ObjectiveC)
        XCTAssertEqual(NSStringFromClass(_OpenCAFilter.self), "CAFilter")
        XCTAssertTrue(_OpenCAFilter.responds(
            to: NSSelectorFromString("filterWithType:")))
#endif
        XCTAssertNil(_OpenCAFilter.filter(withType: "unknownFilter"))

        let filter = try XCTUnwrap(
            _OpenCAFilter.filter(withType: "variableBlur"))
        XCTAssertEqual(filter.description, "variableBlur")
        let mask = Bitmap(width: 2, height: 1)
        mask.pixels = [0, 0, 0, 0, 0, 0, 0, 255]
        filter.setValue(CGFloat(12), forKey: "inputRadius")
        filter.setValue(mask, forKey: "inputMaskImage")
        filter.setValue(true, forKey: "inputNormalizeEdges")
        filter.setValue("must-not-be-retained", forKey: "unknownInput")

        let configuration = try XCTUnwrap(filter._canvasConfiguration)
        XCTAssertEqual(configuration.blurRadius, 12)
        XCTAssertEqual(configuration.blurMask?.alpha, [0, 255])
        XCTAssertTrue(configuration.normalizesMaskEdges)
        XCTAssertNil(filter.value(forKey: "unknownInput"))
    }

    func testVariableCAFilterRunsThroughBackdropRendererInBothBackends() throws {
        for backend in [RenderBackend.swift, .quartz] {
            CanvasBackendSelection.current = backend
            OpenUIKitRuntime.compositor = .layers
            let root = UIView(frame: CGRect(x: 0, y: 0, width: 31, height: 5))
            for x in 0..<31 {
                let stripe = UIView(frame: CGRect(x: CGFloat(x), y: 0,
                                                  width: 1, height: 5))
                stripe.backgroundColor = x.isMultiple(of: 2) ? .black : .white
                root.addSubview(stripe)
            }

            let effect = UIVisualEffectView(
                effect: UIBlurEffect(style: .regular))
            effect.frame = root.bounds
            root.addSubview(effect)
            root.layoutIfNeeded()
            let backdrop = try XCTUnwrap(
                effect.subviews.first as? _UIVisualEffectBackdropView)
            let filter = try XCTUnwrap(
                _OpenCAFilter.filter(withType: "variableBlur"))
            let mask = Bitmap(width: 5, height: 1)
            mask.pixels = [
                0, 0, 0, 0,
                0, 0, 0, 0,
                0, 0, 0, 64,
                0, 0, 0, 160,
                0, 0, 0, 255,
            ]
            filter.setValue(CGFloat(4), forKey: "inputRadius")
            filter.setValue(mask, forKey: "inputMaskImage")
            filter.setValue(true, forKey: "inputNormalizeEdges")
            backdrop.layer.filters = [filter]

            let rendered = UIRenderer.render(root, scale: 1)
            for x in 0..<6 {
                let expected: UInt8 = x.isMultiple(of: 2) ? 0 : 255
                XCTAssertEqual(pixel(rendered, x: x, y: 2),
                               [expected, expected, expected, 255],
                               "zero-radius edge changed for \(backend) at \(x)")
            }
            for x in 25..<31 {
                let value = pixel(rendered, x: x, y: 2)[0]
                XCTAssertTrue(value > 0 && value < 255,
                              "opaque-radius edge did not blur for \(backend) at \(x)")
            }
        }
    }

    func testVariableCAFilterMapsBothCoreImageDirectionsIntoOffsetViewSpace() throws {
        // These are the exact asymmetric alpha progressions produced by the
        // untouched package's two VariableBlurDirection cases. CI/CGImage
        // rows are bottom-to-top; UIView rows are top-to-bottom. A 3x5 mask
        // and an offset 9x31 effect catch both a superficial reversal and an
        // implementation accidentally sampling in root rather than view space.
        let directions: [(name: String, ciRows: [UInt8], blurredTop: Bool)] = [
            ("blurredTopClearBottom", [0, 0, 64, 160, 255], true),
            ("blurredBottomClearTop", [255, 160, 64, 0, 0], false),
        ]
        for backend in [RenderBackend.swift, .quartz] {
            for direction in directions {
                CanvasBackendSelection.current = backend
                OpenUIKitRuntime.compositor = .layers
                let root = UIView(
                    frame: CGRect(x: 0, y: 0, width: 17, height: 39))
                for y in 0..<39 {
                    let stripe = UIView(frame: CGRect(
                        x: 0, y: CGFloat(y), width: 17, height: 1))
                    stripe.backgroundColor = y.isMultiple(of: 2) ? .black : .white
                    root.addSubview(stripe)
                }

                let effect = UIVisualEffectView(
                    effect: UIBlurEffect(style: .regular))
                effect.frame = CGRect(x: 4, y: 3, width: 9, height: 31)
                root.addSubview(effect)
                let backdrop = try XCTUnwrap(
                    effect.subviews.first as? _UIVisualEffectBackdropView)
                let filter = try XCTUnwrap(
                    _OpenCAFilter.filter(withType: "variableBlur"))
                let mask = Bitmap(width: 3, height: 5)
                mask.pixels = direction.ciRows.flatMap { alpha in
                    Array(repeating: [UInt8(0), 0, 0, alpha], count: 3)
                        .flatMap { $0 }
                }
                filter.setValue(CGFloat(4), forKey: "inputRadius")
                filter.setValue(mask, forKey: "inputMaskImage")
                filter.setValue(true, forKey: "inputNormalizeEdges")
                backdrop.layer.filters = [filter]

                let rendered = UIRenderer.render(root, scale: 1)
                let topY = 5
                let bottomY = 31
                let top = pixel(rendered, x: 8, y: topY)[0]
                let bottom = pixel(rendered, x: 8, y: bottomY)[0]
                let originalTop: UInt8 = topY.isMultiple(of: 2) ? 0 : 255
                let originalBottom: UInt8 = bottomY.isMultiple(of: 2) ? 0 : 255
                if direction.blurredTop {
                    XCTAssertTrue(top > 0 && top < 255,
                                  "top did not blur: \(backend)/\(direction.name)")
                    XCTAssertEqual(bottom, originalBottom,
                                   "bottom changed: \(backend)/\(direction.name)")
                } else {
                    XCTAssertEqual(top, originalTop,
                                   "top changed: \(backend)/\(direction.name)")
                    XCTAssertTrue(bottom > 0 && bottom < 255,
                                  "bottom did not blur: \(backend)/\(direction.name)")
                }
            }
        }
    }

    func testGaussianCompatibilityRadiusRunsThroughBackdropRenderer() throws {
        for backend in [RenderBackend.swift, .quartz] {
            CanvasBackendSelection.current = backend
            OpenUIKitRuntime.compositor = .layers
            let root = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: 3))
            for x in 0..<15 {
                let stripe = UIView(frame: CGRect(x: CGFloat(x), y: 0,
                                                  width: 1, height: 3))
                stripe.backgroundColor = x.isMultiple(of: 2) ? .black : .white
                root.addSubview(stripe)
            }

            let effect = UIVisualEffectView(
                effect: UIBlurEffect(style: .regular))
            effect.frame = root.bounds
            root.addSubview(effect)
            let filterLayer = try XCTUnwrap(effect.layer.sublayers?.first)
            filterLayer.setValue(
                NSNumber(value: 3),
                forKeyPath: "filters.gaussianBlur.inputRadius")

            let rendered = UIRenderer.render(root, scale: 1)
            for x in 2..<13 {
                let value = pixel(rendered, x: x, y: 1)[0]
                XCTAssertTrue(value > 0 && value < 255,
                              "KVC radius did not blur for \(backend) at \(x)")
            }
        }
    }

    func testStandaloneLayerLayoutDelegateRunsOnlyWhenInvalidated() {
        let root = PortableLayer()
        let child = PortableLayer()
        let probe = LayerLayoutDelegateProbe()
        root.delegate = probe

        XCTAssertTrue(root.needsLayout())
        root.layoutIfNeeded()
        XCTAssertEqual(probe.layers.count, 1)
        XCTAssertTrue(probe.layers.first === root)
        XCTAssertFalse(root.needsLayout())

        root.layoutIfNeeded()
        XCTAssertEqual(probe.layers.count, 1, "a clean layer does not relayout")

        root.addSublayer(child)
        XCTAssertTrue(root.needsLayout())
        root.layoutIfNeeded()
        XCTAssertEqual(probe.layers.count, 2)

        child.frame = CGRect(x: 1, y: 2, width: 3, height: 4)
        XCTAssertTrue(root.needsLayout(), "child geometry invalidates its parent")
        root.layoutIfNeeded()
        XCTAssertEqual(probe.layers.count, 3)
    }

    func testUIViewBackingLayerRoutesLayoutThroughDelegateAndSuper() {
        let view = LayerLayoutViewProbe(
            frame: CGRect(x: 0, y: 0, width: 40, height: 20))
        XCTAssertTrue(view.layer.delegate === view)

        view.layoutIfNeeded()
        XCTAssertEqual(view.callbacks, [
            "layoutSublayers.begin", "layoutSubviews", "layoutSublayers.end",
        ])
        XCTAssertEqual(view.gradient.frame, view.bounds)

        view.layoutIfNeeded()
        XCTAssertEqual(view.callbacks.count, 3, "a clean view does not relayout")

        view.frame = CGRect(x: 5, y: 6, width: 80, height: 30)
        view.layoutIfNeeded()
        XCTAssertEqual(view.callbacks.suffix(3), [
            "layoutSublayers.begin", "layoutSubviews", "layoutSublayers.end",
        ])
        XCTAssertEqual(view.gradient.frame, CGRect(x: 0, y: 0, width: 80, height: 30))

        view.layer.setNeedsLayout()
        view.layoutIfNeeded()
        XCTAssertEqual(view.callbacks.count, 9,
                       "backing-layer invalidation also schedules view layout")
    }

    func testExplicitLayerHierarchyPreservesOrderAndRemoval() {
        CanvasBackendSelection.current = .swift
        let root = PortableLayer()
        root.bounds = CGRect(x: 0, y: 0, width: 20, height: 20)

        let front = PortableLayer()
        front.frame = root.bounds
        front.backgroundColor = PortableColor(red: 1, green: 0, blue: 0, alpha: 1)
        root.addSublayer(front)

        let back = PortableLayer()
        back.frame = root.bounds
        back.backgroundColor = PortableColor(red: 0, green: 0, blue: 1, alpha: 1)
        root.insertSublayer(back, at: 0)

        XCTAssertEqual(root.sublayers?.count, 2)
        XCTAssertTrue(root.sublayers?[0] === back)
        XCTAssertTrue(root.sublayers?[1] === front)
        XCTAssertTrue(back.superlayer === root)

        let bitmap = Bitmap(width: 20, height: 20)
        root.render(in: Canvas(bitmap: bitmap, scale: 1))
        XCTAssertEqual(pixel(bitmap, x: 10, y: 10), [255, 0, 0, 255],
                       "later sublayers composite in front")

        front.removeFromSuperlayer()
        XCTAssertNil(front.superlayer)
        XCTAssertEqual(root.sublayers?.count, 1)
        let afterRemoval = Bitmap(width: 20, height: 20)
        root.render(in: Canvas(bitmap: afterRemoval, scale: 1))
        XCTAssertEqual(pixel(afterRemoval, x: 10, y: 10), [0, 0, 255, 255])

        back.removeFromSuperlayer()
        XCTAssertNil(root.sublayers, "UIKit represents an empty layer list as nil")

        // A parent cannot be inserted below one of its own descendants.
        root.addSublayer(front)
        front.addSublayer(root)
        XCTAssertNil(root.superlayer)
        XCTAssertNil(front.sublayers)
    }

    func testBackingLayerVisualStateForwardsToItsView() {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
        let color = PortableColor(red: 0.2, green: 0.4, blue: 0.6, alpha: 0.8)
        view.layer.backgroundColor = color
        XCTAssertEqual(view.backgroundColor?.cgColor, color)
        XCTAssertEqual(view.layer.backgroundColor, color)

        view.layer.opacity = 0.375
        XCTAssertEqual(view.alpha, 0.375)
        view.alpha = 0.75
        XCTAssertEqual(view.layer.opacity, 0.75)

        view.layer.isHidden = true
        XCTAssertTrue(view.isHidden)
        view.isHidden = false
        XCTAssertFalse(view.layer.isHidden)
    }

    func testInsertedGradientRendersBehindViewChildrenInBothCompositors() {
        for (backend, compositor) in [(RenderBackend.swift, RenderCompositor.renderPass),
                                      (.quartz, .layers)] {
            CanvasBackendSelection.current = backend
            OpenUIKitRuntime.compositor = compositor

            let root = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 12))
            root.backgroundColor = .white
            let gradient = PortableGradientLayer()
            gradient.frame = root.bounds
            gradient.colors = [PortableColor(red: 1, green: 0, blue: 0, alpha: 1),
                               PortableColor(red: 0, green: 0, blue: 1, alpha: 1)]
            gradient.startPoint = CGPoint(x: 0, y: 0.5)
            gradient.endPoint = CGPoint(x: 1, y: 0.5)
            root.layer.insertSublayer(gradient, at: 0)

            let child = UIView(frame: CGRect(x: 15, y: 2, width: 10, height: 8))
            child.backgroundColor = .green
            root.addSubview(child)

            let rendered = UIRenderer.render(root, scale: 1)
            let left = pixel(rendered, x: 1, y: 6)
            let right = pixel(rendered, x: 38, y: 6)
            XCTAssertGreaterThan(left[0], left[2], "\(backend)/\(compositor): red start")
            XCTAssertGreaterThan(right[2], right[0], "\(backend)/\(compositor): blue end")
            XCTAssertEqual(pixel(rendered, x: 20, y: 6), [0, 255, 0, 255],
                           "\(backend)/\(compositor): UIView child remains above gradient")

            gradient.removeFromSuperlayer()
            let cleared = UIRenderer.render(root, scale: 1)
            XCTAssertEqual(pixel(cleared, x: 1, y: 6), [255, 255, 255, 255],
                           "\(backend)/\(compositor): removal changes rendered output")
        }
    }

    func testLegacyImageContextUsesScreenScaleForZeroAndSnapshotsPixels() {
        CanvasBackendSelection.current = .swift
        OpenUIKitRuntime.imageScreenScale = 3
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 4, height: 2), false, 0)
        guard let context = UIGraphicsGetCurrentContext() else {
            return XCTFail("begin must install a current context")
        }
        XCTAssertEqual(context.scale, 3)
        context.fill(rect: CGRect(x: 0, y: 0, width: 4, height: 2),
                     color: PortableColor(red: 1, green: 0, blue: 0, alpha: 1))

        let first = UIGraphicsGetImageFromCurrentImageContext()
        XCTAssertEqual(first?.scale, 3)
        XCTAssertEqual(first?.bitmap.width, 12)
        XCTAssertEqual(first?.bitmap.height, 6)
        XCTAssertEqual(first.map { pixel($0.bitmap, x: 6, y: 3) }, [255, 0, 0, 255])

        // Returned images are snapshots, not aliases of the mutable context.
        context.fill(rect: CGRect(x: 0, y: 0, width: 4, height: 2),
                     color: PortableColor(red: 0, green: 0, blue: 1, alpha: 1))
        XCTAssertEqual(first.map { pixel($0.bitmap, x: 6, y: 3) }, [255, 0, 0, 255])
        XCTAssertEqual(UIGraphicsGetImageFromCurrentImageContext().map {
            pixel($0.bitmap, x: 6, y: 3)
        }, [0, 0, 255, 255])

        UIGraphicsEndImageContext()
        XCTAssertNil(UIGraphicsGetCurrentContext())
        XCTAssertNil(UIGraphicsGetImageFromCurrentImageContext())
    }

    func testNestedLegacyImageContextsRestoreTheOuterContext() {
        CanvasBackendSelection.current = .swift
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 3, height: 3), false, 1)
        let outer = try! XCTUnwrap(UIGraphicsGetCurrentContext())
        outer.fill(rect: CGRect(x: 0, y: 0, width: 3, height: 3),
                   color: PortableColor(red: 1, green: 0, blue: 0, alpha: 1))

        UIGraphicsBeginImageContextWithOptions(CGSize(width: 2, height: 2), true, 2)
        let inner = try! XCTUnwrap(UIGraphicsGetCurrentContext())
        XCTAssertFalse(inner === outer)
        XCTAssertEqual(inner.scale, 2)
        XCTAssertEqual(UIGraphicsGetImageFromCurrentImageContext().map {
            pixel($0.bitmap, x: 0, y: 0)[3]
        }, 255, "opaque contexts begin with opaque pixels")
        inner.fill(rect: CGRect(x: 0, y: 0, width: 2, height: 2),
                   color: PortableColor(red: 0, green: 0, blue: 1, alpha: 1))
        XCTAssertEqual(UIGraphicsGetImageFromCurrentImageContext().map {
            pixel($0.bitmap, x: 2, y: 2)
        }, [0, 0, 255, 255])

        UIGraphicsEndImageContext()
        XCTAssertTrue(UIGraphicsGetCurrentContext() === outer)
        XCTAssertEqual(UIGraphicsGetImageFromCurrentImageContext().map {
            pixel($0.bitmap, x: 1, y: 1)
        }, [255, 0, 0, 255])
        UIGraphicsEndImageContext()
        XCTAssertNil(UIGraphicsGetCurrentContext())
    }

    func testLayerRenderProducesFocusStyleFaviconPixels() {
        CanvasBackendSelection.current = .swift
        OpenUIKitRuntime.imageScreenScale = 2
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
        label.backgroundColor = UIColor(red: 0.35, green: 0.12, blue: 0.7, alpha: 1)
        label.text = "F"
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 40)
        label.textColor = .white

        UIGraphicsBeginImageContextWithOptions(label.bounds.size, false, 0)
        UIGraphicsGetCurrentContext().map(label.layer.render(in:))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        let bitmap = try! XCTUnwrap(image?.bitmap)
        XCTAssertEqual(bitmap.width, 120)
        XCTAssertEqual(bitmap.height, 120)
        XCTAssertEqual(pixel(bitmap, x: 4, y: 4), [89, 31, 179, 255],
                       "the backing layer background is painted")
        var lightInkPixels = 0
        var offset = 0
        while offset + 3 < bitmap.pixels.count {
            if bitmap.pixels[offset] > 180,
               bitmap.pixels[offset + 1] > 180,
               bitmap.pixels[offset + 2] > 180,
               bitmap.pixels[offset + 3] > 0 {
                lightInkPixels += 1
            }
            offset += 4
        }
        XCTAssertGreaterThan(lightInkPixels, 40,
                             "UILabel.layer.render(in:) must rasterize glyph pixels")
    }
}
