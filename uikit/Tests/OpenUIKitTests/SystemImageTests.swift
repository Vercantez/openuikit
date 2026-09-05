import Foundation
import XCTest
@testable import OpenUIKit

#if !os(Linux)
@MainActor
#endif
final class SystemImageTests: XCTestCase {
    private var savedImageScale: CGFloat = 2
    private var savedBackend: RenderBackend = .quartz
    private var savedCompositor: RenderCompositor = .layers
    private var savedCaching = true
    private var savedResourceRoot = ""
    private var savedSearchPaths: [String] = []

    override func setUp() {
        super.setUp()
        savedImageScale = OpenUIKitRuntime.imageScreenScale
        savedBackend = OpenUIKitRuntime.renderBackend
        savedCompositor = OpenUIKitRuntime.compositor
        savedCaching = OpenUIKitRuntime.layerCaching
        savedResourceRoot = OpenUIKitRuntime.resourceRoot
        savedSearchPaths = OpenUIKitRuntime.imageSearchPaths
    }

    override func tearDown() {
        OpenUIKitRuntime.imageScreenScale = savedImageScale
        OpenUIKitRuntime.renderBackend = savedBackend
        OpenUIKitRuntime.compositor = savedCompositor
        OpenUIKitRuntime.layerCaching = savedCaching
        OpenUIKitRuntime.resourceRoot = savedResourceRoot
        OpenUIKitRuntime.imageSearchPaths = savedSearchPaths
        super.tearDown()
    }

    func testSymbolWeightRawValuesMatchUIKit26() {
        XCTAssertEqual(UIImage.SymbolWeight.unspecified.rawValue, 0)
        XCTAssertEqual(UIImage.SymbolWeight.ultraLight.rawValue, 1)
        XCTAssertEqual(UIImage.SymbolWeight.thin.rawValue, 2)
        XCTAssertEqual(UIImage.SymbolWeight.light.rawValue, 3)
        XCTAssertEqual(UIImage.SymbolWeight.regular.rawValue, 4)
        XCTAssertEqual(UIImage.SymbolWeight.medium.rawValue, 5)
        XCTAssertEqual(UIImage.SymbolWeight.semibold.rawValue, 6)
        XCTAssertEqual(UIImage.SymbolWeight.bold.rawValue, 7)
        XCTAssertEqual(UIImage.SymbolWeight.heavy.rawValue, 8)
        XCTAssertEqual(UIImage.SymbolWeight.black.rawValue, 9)
        XCTAssertEqual(UIImage.SymbolScale.unspecified.rawValue, 0)
        XCTAssertEqual(UIImage.SymbolScale.small.rawValue, 1)
        XCTAssertEqual(UIImage.SymbolScale.medium.rawValue, 2)
        XCTAssertEqual(UIImage.SymbolScale.large.rawValue, 3)
    }

    func testSixDefaultSystemImageSizesMatchNativeAtOneAndTwoX() throws {
        let expected: [(String, CGSize, CGSize)] = [
            ("calendar", CGSize(width: 21, height: 18),
             CGSize(width: 21, height: 17.5)),
            ("clock", CGSize(width: 19, height: 19),
             CGSize(width: 20, height: 19)),
            ("multiply", CGSize(width: 16, height: 14),
             CGSize(width: 15.5, height: 13.5)),
            ("plus.circle.fill", CGSize(width: 19, height: 19),
             CGSize(width: 20, height: 19)),
            ("circlebadge", CGSize(width: 15, height: 15),
             CGSize(width: 16, height: 15)),
            ("checkmark.circle.fill", CGSize(width: 19, height: 19),
             CGSize(width: 20, height: 19)),
        ]

        for (name, oneX, twoX) in expected {
            OpenUIKitRuntime.imageScreenScale = 1
            let one = try XCTUnwrap(UIImage(systemName: name))
            XCTAssertEqual(one.size, oneX, name)
            XCTAssertEqual(one.bitmap.width, Int(oneX.width), name)
            XCTAssertEqual(one.bitmap.height, Int(oneX.height), name)

            OpenUIKitRuntime.imageScreenScale = 2
            let two = try XCTUnwrap(UIImage(systemName: name))
            XCTAssertEqual(two.size, twoX, name)
            XCTAssertEqual(two.bitmap.width, Int(twoX.width * 2), name)
            XCTAssertEqual(two.bitmap.height, Int(twoX.height * 2), name)
        }
    }

    /// MEASURED Tabs probe, iPhone SE 2x / iOS 26.1: tab-bar
    /// preferredSymbolConfiguration is 18pt medium large; calendar is
    /// 29×25, clock / clock.fill / plus.circle.fill are 27.5×27.5.
    func testTabBarSymbolConfigurationSizesMatchIOS() throws {
        OpenUIKitRuntime.imageScreenScale = 2
        let configuration = UIImage.SymbolConfiguration(
            pointSize: 18, weight: .medium, scale: .large)
        let calendar = try XCTUnwrap(UIImage(systemName: "calendar",
                                              withConfiguration: configuration))
        XCTAssertEqual(calendar.size, CGSize(width: 29, height: 25))
        let clock = try XCTUnwrap(UIImage(systemName: "clock",
                                           withConfiguration: configuration))
        XCTAssertEqual(clock.size, CGSize(width: 27.5, height: 27.5))
        let clockFill = try XCTUnwrap(UIImage(systemName: "clock.fill",
                                               withConfiguration: configuration))
        XCTAssertEqual(clockFill.size, CGSize(width: 27.5, height: 27.5))
        XCTAssertNil(UIImage(systemName: "calendar.fill"))
        XCTAssertEqual(UITabBar.filledSymbolName("clock"), "clock.fill")
        XCTAssertEqual(UITabBar.filledSymbolName("calendar"), "calendar")
        XCTAssertEqual(UITabBar.filledSymbolName("plus.circle.fill"),
                       "plus.circle.fill")
        // MEASURED t2000 golden vs symbolinkprobe, SE 2x / iOS 26.1:
        // selected clock crop corr 0.999997 with outline `clock`, 0.34
        // with `clock.fill`. The bar tints the same name.
        let savedCut = OpenUIKitRuntime.systemFontCut
        OpenUIKitRuntime.systemFontCut = .iOS
        defer { OpenUIKitRuntime.systemFontCut = savedCut }
        let item = UITabBarItem(title: "Scroll",
                                image: UIImage(systemName: "clock"), tag: 0)
        let selected = try XCTUnwrap(UITabBar.resolvedItemImage(item, selected: true))
        let unselected = try XCTUnwrap(UITabBar.resolvedItemImage(item, selected: false))
        XCTAssertEqual(selected.bitmap.pixels, unselected.bitmap.pixels)
    }

    /// MEASURED symbolinkprobe, iPhone SE 2x / iOS 26.1: opaque-label
    /// coverage of calendar at 18 pt medium large sums to 243587 over the
    /// 46×42 ink box, padded to the 58×50 alignment image. iOS cut only.
    func testTabBarHarvestedSymbolInkMatchesProbe() throws {
        let savedCut = OpenUIKitRuntime.systemFontCut
        OpenUIKitRuntime.systemFontCut = .iOS
        OpenUIKitRuntime.imageScreenScale = 2
        defer { OpenUIKitRuntime.systemFontCut = savedCut }
        let configuration = UIImage.SymbolConfiguration(
            pointSize: 18, weight: .medium, scale: .large)
        let calendar = try XCTUnwrap(UIImage(systemName: "calendar",
                                              withConfiguration: configuration))
        XCTAssertEqual(calendar.size, CGSize(width: 29, height: 25))
        XCTAssertEqual(calendar.bitmap.width, 58)
        XCTAssertEqual(calendar.bitmap.height, 50)
        var inkSum = 0
        var inkPixels = 0
        var i = 3
        while i < calendar.bitmap.pixels.count {
            let a = Int(calendar.bitmap.pixels[i])
            if a > 0 { inkSum += a; inkPixels += 1 }
            i += 4
        }
        XCTAssertEqual(inkPixels, 1109)
        XCTAssertEqual(inkSum, 243587)

        let clockFill = try XCTUnwrap(UIImage(systemName: "clock.fill",
                                               withConfiguration: configuration))
        XCTAssertEqual(clockFill.size, CGSize(width: 27.5, height: 27.5))
        XCTAssertEqual(clockFill.bitmap.width, 55)
        var fillPixels = 0
        i = 3
        while i < clockFill.bitmap.pixels.count {
            if clockFill.bitmap.pixels[i] > 0 { fillPixels += 1 }
            i += 4
        }
        XCTAssertEqual(fillPixels, 1714)

        OpenUIKitRuntime.imageScreenScale = 3
        let clock3 = try XCTUnwrap(UIImage(systemName: "clock",
                                            withConfiguration: configuration))
        XCTAssertEqual(clock3.bitmap.width, 82)
        XCTAssertEqual(clock3.bitmap.height, 82)
        XCTAssertEqual(clock3.size.width, 82 / 3, accuracy: 0.001)

        // Names the table harvested but the procedural set does not carry.
        XCTAssertNotNil(UIImage(systemName: "house",
                                withConfiguration: configuration))
        OpenUIKitRuntime.systemFontCut = .macOS
        XCTAssertNil(UIImage(systemName: "house",
                             withConfiguration: configuration))
        XCTAssertNil(UIImage(systemName: "magnifyingglass"))
    }

    func testReminderConfiguredPlusSizeAndAutomaticMode() throws {
        OpenUIKitRuntime.imageScreenScale = 2
        let configuration = UIImage.SymbolConfiguration(pointSize: 56,
                                                          weight: .regular)
        let image = try XCTUnwrap(UIImage(systemName: "plus.circle.fill",
                                          withConfiguration: configuration))
        XCTAssertEqual(image.size, CGSize(width: 66, height: 64))
        XCTAssertEqual(image.bitmap.width, 132)
        XCTAssertEqual(image.bitmap.height, 128)
        if case .automatic = image.renderingMode {
            // Expected. XCTest cannot compare this non-Equatable compatibility
            // enum directly without widening the public API.
        } else {
            XCTFail("native system images start in automatic rendering mode")
        }
    }

    func testIsSymbolImageAndImmutableCopiesPreserveMetadata() throws {
        OpenUIKitRuntime.imageScreenScale = 2
        let system = try XCTUnwrap(UIImage(systemName: "calendar"))
        XCTAssertTrue(system.isSymbolImage)
        XCTAssertTrue(system.withRenderingMode(.alwaysOriginal).isSymbolImage)
        XCTAssertTrue(system.withRenderingMode(.alwaysTemplate).isSymbolImage)
        XCTAssertTrue(system.withTintColor(.red).isSymbolImage)
        XCTAssertTrue(system.withTintColor(.blue,
                                           renderingMode: .automatic).isSymbolImage)

        let ordinary = UIImage(bitmap: Bitmap(width: 2, height: 2), scale: 1)
        XCTAssertFalse(ordinary.isSymbolImage)
        XCTAssertFalse(ordinary.withRenderingMode(.alwaysTemplate).isSymbolImage)
        XCTAssertFalse(ordinary.withTintColor(.red).isSymbolImage)

        let tintedSystem = system.withTintColor(.red)
        if case .automatic = tintedSystem.renderingMode {} else {
            XCTFail("one-argument symbol tint preserves automatic mode")
        }
        assertHasColoredInk(rendered(tintedSystem, tint: .blue),
                            red: false, green: false, blue: true)
    }

    func testOneArgumentTintPreservesReceiverModeAndCopyChainSemantics() throws {
        OpenUIKitRuntime.imageScreenScale = 2
        let system = try XCTUnwrap(UIImage(systemName: "plus.circle.fill"))
        let bitmap = Bitmap(width: 4, height: 4)
        for index in stride(from: 0, to: bitmap.pixels.count, by: 4) {
            bitmap.pixels[index + 3] = 255
        }
        let ordinary = UIImage(bitmap: bitmap, scale: 1)

        let ordinaryTemplateTint = ordinary
            .withRenderingMode(.alwaysTemplate)
            .withTintColor(.red)
        XCTAssertEqual(ordinaryTemplateTint.renderingMode, .alwaysTemplate)
        assertHasColoredInk(rendered(ordinaryTemplateTint, tint: .blue),
                            red: false, green: false, blue: true)

        let systemOriginalTint = system
            .withRenderingMode(.alwaysOriginal)
            .withTintColor(.red)
        XCTAssertEqual(systemOriginalTint.renderingMode, .alwaysOriginal)
        XCTAssertTrue(systemOriginalTint.isSymbolImage)
        assertHasColoredInk(rendered(systemOriginalTint, tint: .blue),
                            red: true, green: false, blue: false)

        let ordinaryExplicitThenAutomatic = ordinary
            .withTintColor(.red, renderingMode: .alwaysTemplate)
            .withRenderingMode(.automatic)
        XCTAssertEqual(ordinaryExplicitThenAutomatic.renderingMode, .automatic)
        assertHasColoredInk(rendered(ordinaryExplicitThenAutomatic, tint: .blue),
                            red: true, green: false, blue: false)

        let systemExplicitThenAutomatic = system
            .withTintColor(.red, renderingMode: .alwaysTemplate)
            .withRenderingMode(.automatic)
        XCTAssertEqual(systemExplicitThenAutomatic.renderingMode, .automatic)
        XCTAssertTrue(systemExplicitThenAutomatic.isSymbolImage)
        assertHasColoredInk(rendered(systemExplicitThenAutomatic, tint: .blue),
                            red: false, green: false, blue: true)
    }

    func testUnknownAndNonCanonicalNamesFailClosed() {
        for name in ["", " ", "Calendar", " calendar", "calendar ",
                     "calendar/", "../calendar", "magnifyingglass",
                     "plus.circle"] {
            XCTAssertNil(UIImage(systemName: name), name)
        }
    }

    func testHostileConfigurationAndScaleInputsFailWithoutAllocation() {
        let hostile: [CGFloat] = [0, -1, .nan, .infinity, -.infinity, 513,
                                  CGFloat.greatestFiniteMagnitude]
        for pointSize in hostile {
            let configuration = UIImage.SymbolConfiguration(pointSize: pointSize,
                                                              weight: .regular)
            XCTAssertNil(UIImage(systemName: "plus.circle.fill",
                                 withConfiguration: configuration),
                         "pointSize=\(pointSize)")
        }

        for scale in [CGFloat(0), -1, .nan, .infinity, 5,
                      CGFloat.greatestFiniteMagnitude] {
            OpenUIKitRuntime.imageScreenScale = scale
            XCTAssertNil(UIImage(systemName: "calendar"), "scale=\(scale)")
        }
    }

    func testEveryProceduralMaskHasInkAndTransparency() throws {
        OpenUIKitRuntime.imageScreenScale = 2
        for name in ["calendar", "clock", "clock.fill", "multiply", "plus.circle.fill",
                     "circlebadge", "checkmark.circle.fill"] {
            let image = try XCTUnwrap(UIImage(systemName: name))
            let alpha = stride(from: 3, to: image.bitmap.pixels.count, by: 4)
                .map { image.bitmap.pixels[$0] }
            XCTAssertTrue(alpha.contains { $0 > 0 }, "\(name) has no ink")
            XCTAssertTrue(alpha.contains(0), "\(name) lost its transparent field")
            for i in stride(from: 0, to: image.bitmap.pixels.count, by: 4) {
                XCTAssertEqual(image.bitmap.pixels[i], 0, name)
                XCTAssertEqual(image.bitmap.pixels[i + 1], 0, name)
                XCTAssertEqual(image.bitmap.pixels[i + 2], 0, name)
            }
        }
    }

    func testProceduralPixelsDoNotDependOnResources() throws {
        OpenUIKitRuntime.imageScreenScale = 2
        let baseline = try XCTUnwrap(UIImage(systemName: "calendar")).bitmap.pixels
        OpenUIKitRuntime.resourceRoot = "/definitely/not/a/resource/root"
        OpenUIKitRuntime.imageSearchPaths = ["/also/missing"]
        UIImage.clearNamedCache()
        let isolated = try XCTUnwrap(UIImage(systemName: "calendar")).bitmap.pixels
        XCTAssertEqual(isolated, baseline)
    }

    func testBothBackendsProduceDeterministicNonemptySymbols() throws {
        OpenUIKitRuntime.imageScreenScale = 2
        for backend: RenderBackend in [.swift, .quartz] {
            OpenUIKitRuntime.renderBackend = backend
            let first = try XCTUnwrap(UIImage(systemName: "checkmark.circle.fill"))
            let second = try XCTUnwrap(UIImage(systemName: "checkmark.circle.fill"))
            XCTAssertEqual(first.bitmap.pixels, second.bitmap.pixels,
                           "backend=\(backend)")
            XCTAssertTrue(first.bitmap.pixels.contains { $0 != 0 })
        }
    }

    func testProceduralPixelFingerprintsAreClosed() throws {
        OpenUIKitRuntime.imageScreenScale = 2
        for backend: RenderBackend in [.swift, .quartz] {
            OpenUIKitRuntime.renderBackend = backend
            let expected: [String: UInt64]
            switch backend {
            case .swift:
                expected = [
                    "calendar": 17_688_738_542_957_584_656,
                    "clock": 11_422_362_519_469_204_408,
                    "multiply": 930_275_962_113_226_808,
                    "plus.circle.fill": 5_248_006_694_040_004_741,
                    "circlebadge": 1_384_709_250_049_653_253,
                    "checkmark.circle.fill": 9_384_873_863_741_001_018,
                    "plus.circle.fill@56.regular": 4_184_632_315_002_413_221,
                ]
            case .quartz:
                expected = [
                    "calendar": 12_281_659_517_316_363_357,
                    "clock": 15_692_902_194_808_184_169,
                    "multiply": 13_863_169_408_881_935_547,
                    "plus.circle.fill": 14_527_487_182_206_405_157,
                    "circlebadge": 9_138_136_936_328_476_613,
                    "checkmark.circle.fill": 15_130_345_711_117_002_272,
                    "plus.circle.fill@56.regular": 14_388_752_676_728_168_773,
                ]
            }
            for name in ["calendar", "clock", "multiply", "plus.circle.fill",
                         "circlebadge", "checkmark.circle.fill"] {
                let image = try XCTUnwrap(UIImage(systemName: name))
                XCTAssertEqual(fnv1a(image.bitmap.pixels), expected[name],
                               "backend=\(backend) name=\(name)")
            }
            let configuration = UIImage.SymbolConfiguration(pointSize: 56,
                                                              weight: .regular)
            let configured = try XCTUnwrap(UIImage(systemName: "plus.circle.fill",
                                                   withConfiguration: configuration))
            XCTAssertEqual(fnv1a(configured.bitmap.pixels),
                           expected["plus.circle.fill@56.regular"],
                           "backend=\(backend) configured plus")
        }
    }

    func testSystemSymbolAutomaticTemplateTintAndAlwaysOriginalOverride() throws {
        OpenUIKitRuntime.imageScreenScale = 2
        let symbol = try XCTUnwrap(UIImage(systemName: "plus.circle.fill"))

        let automatic = rendered(symbol, tint: .systemRed)
        assertHasColoredInk(automatic, red: true, green: false, blue: false)

        let original = rendered(symbol.withRenderingMode(.alwaysOriginal),
                                tint: .systemRed)
        assertHasColoredInk(original, red: false, green: false, blue: false)

        let template = rendered(symbol.withRenderingMode(.alwaysTemplate),
                                tint: .systemBlue)
        assertHasColoredInk(template, red: false, green: false, blue: true)
    }

    func testOrdinaryAutomaticRasterIsNotImplicitlyTinted() {
        let bitmap = Bitmap(width: 4, height: 4)
        for i in stride(from: 0, to: bitmap.pixels.count, by: 4) {
            bitmap.pixels[i] = 12
            bitmap.pixels[i + 1] = 34
            bitmap.pixels[i + 2] = 56
            bitmap.pixels[i + 3] = 255
        }
        let image = UIImage(bitmap: bitmap, scale: 1)
        let automaticRaster = rendered(image, tint: .systemRed)
        XCTAssertTrue(pixelTriples(automaticRaster).contains([12, 34, 56]))

        let explicitTemplate = rendered(image.withRenderingMode(.alwaysTemplate),
                                        tint: .systemRed)
        assertHasColoredInk(explicitTemplate, red: true, green: false, blue: false)
    }

    func testDynamicTintResolvesAgainstImageViewTraits() throws {
        OpenUIKitRuntime.imageScreenScale = 2
        let image = try XCTUnwrap(UIImage(systemName: "circlebadge"))
        let dynamic = UIColor(dynamicProvider: { traits in
            traits.userInterfaceStyle == .dark ? .green : .red
        })
        let view = UIImageView(image: image)
        view.tintColor = dynamic
        view.overrideUserInterfaceStyle = .dark
        let output = Bitmap(width: image.bitmap.width, height: image.bitmap.height)
        view.drawContent(in: Canvas(bitmap: output, scale: image.scale),
                         bounds: view.bounds)
        assertHasColoredInk(output, red: false, green: true, blue: false)
    }

    func testLayerCacheFingerprintIncludesTemplateTint() throws {
        guard OpenUIKitRuntime.compositor == .layers else { return }
        OpenUIKitRuntime.renderBackend = .quartz
        OpenUIKitRuntime.layerCaching = true
        OpenUIKitRuntime.imageScreenScale = 2

        let root = UIView(frame: CGRect(x: 0, y: 0, width: 48, height: 48))
        root.backgroundColor = .white
        let image = try XCTUnwrap(UIImage(systemName: "plus.circle.fill"))
        let imageView = UIImageView(image: image)
        imageView.center = CGPoint(x: 24, y: 24)
        imageView.tintColor = .red
        root.addSubview(imageView)

        for _ in 0..<4 { _ = UIRenderer.render(root, scale: 2) }
        let red = UIRenderer.render(root, scale: 2).pixels
        imageView.tintColor = .blue
        let cachedBlue = UIRenderer.render(root, scale: 2).pixels

        let wasCaching = OpenUIKitRuntime.layerCaching
        OpenUIKitRuntime.layerCaching = false
        let directBlue = UIRenderer.render(root, scale: 2).pixels
        OpenUIKitRuntime.layerCaching = wasCaching

        XCTAssertNotEqual(cachedBlue, red)
        XCTAssertEqual(cachedBlue, directBlue,
                       "warm image-content cache reused the prior tint")
    }

    func testDestinationPixelValidationRejectsHostileGeometry() {
        XCTAssertNil(_UIBitmapAllocation.checkedPixelSize(
            for: CGRect(x: 0, y: 0, width: CGFloat.nan, height: 10), scale: 2))
        XCTAssertNil(_UIBitmapAllocation.checkedPixelSize(
            for: CGRect(x: 0, y: 0, width: CGFloat.infinity, height: 10), scale: 2))
        XCTAssertNil(_UIBitmapAllocation.checkedPixelSize(
            for: CGRect(x: 0, y: 0, width: 9000, height: 10), scale: 1))
        XCTAssertNil(_UIBitmapAllocation.checkedPixelSize(
            for: CGRect(x: 0, y: 0, width: 5000, height: 5000), scale: 1))
        XCTAssertNil(_UIBitmapAllocation.checkedPixelSize(
            for: CGRect(x: CGFloat.infinity, y: 0, width: 10, height: 10), scale: 1))
        XCTAssertNil(_UIBitmapAllocation.checkedPixelSize(
            for: CGRect(x: 0, y: 0, width: 10, height: 10), scale: CGFloat.nan))
        XCTAssertNil(_UIBitmapAllocation.checkedPixelSize(
            for: CGRect(x: 0, y: 0, width: 1, height: 1), scale: 5))
        XCTAssertEqual(_UIBitmapAllocation.checkedPixelSize(
            for: CGRect(x: 0, y: 0, width: 20, height: 19), scale: 2)?.width, 40)
    }

    func testLayerBridgePublicEntryRejectsHostileRootWithoutTrap() {
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))

        root.bounds = CGRect(x: 0, y: 0, width: CGFloat.nan, height: 20)
        var output = LayerBridge.render(root, scale: 2)
        XCTAssertEqual(output.width, 0)
        XCTAssertEqual(output.height, 0)

        root.bounds = CGRect(x: 0, y: 0, width: 20, height: 20)
        output = LayerBridge.render(root, scale: CGFloat.infinity)
        XCTAssertEqual(output.width, 0)
        XCTAssertEqual(output.height, 0)

        root.bounds = CGRect(x: 0, y: 0, width: 5000, height: 5000)
        output = LayerBridge.render(root, scale: 1)
        XCTAssertEqual(output.width, 0)
        XCTAssertEqual(output.height, 0)
    }

    func testUIRendererPublicEntryRejectsHostileRootAcrossBothRoutes() {
        let routes: [(RenderBackend, RenderCompositor)] = [
            (.quartz, .layers),
            (.quartz, .renderPass),
            // A Swift backend always dispatches to the render pass, even if
            // the selected compositor is layers.
            (.swift, .layers),
            (.swift, .renderPass),
        ]
        for (backend, compositor) in routes {
            OpenUIKitRuntime.renderBackend = backend
            OpenUIKitRuntime.compositor = compositor
            let root = UIView(frame: CGRect(x: 0, y: 0,
                                            width: 20, height: 20))

            root.bounds = CGRect(x: 0, y: 0,
                                 width: CGFloat.nan, height: 20)
            var output = UIRenderer.render(root, scale: 2)
            XCTAssertEqual(output.width, 0,
                           "backend=\(backend) compositor=\(compositor)")
            XCTAssertEqual(output.height, 0,
                           "backend=\(backend) compositor=\(compositor)")

            root.bounds = CGRect(x: 0, y: 0, width: 20, height: 20)
            output = UIRenderer.render(root, scale: CGFloat.infinity)
            XCTAssertEqual(output.width, 0,
                           "backend=\(backend) compositor=\(compositor)")
            XCTAssertEqual(output.height, 0,
                           "backend=\(backend) compositor=\(compositor)")

            root.bounds = CGRect(x: 0, y: 0, width: 5000, height: 5000)
            output = UIRenderer.render(root, scale: 1)
            XCTAssertEqual(output.width, 0,
                           "backend=\(backend) compositor=\(compositor)")
            XCTAssertEqual(output.height, 0,
                           "backend=\(backend) compositor=\(compositor)")

            // A product-only guard is insufficient: tiny*huge can look like
            // a harmless four-pixel root while ordinary child shadow math
            // still multiplies by the hostile scale and traps downstream.
            let tiny = CGFloat.leastNormalMagnitude
            root.bounds = CGRect(x: 0, y: 0, width: tiny, height: tiny)
            let shadowed = UIView(frame: CGRect(x: 0, y: 0,
                                                width: 1, height: 1))
            shadowed.backgroundColor = .red
            shadowed.layer.shadowOpacity = 1
            shadowed.layer.shadowOffset = CGSize(width: 1, height: 1)
            shadowed.layer.shadowRadius = 1
            root.addSubview(shadowed)
            output = UIRenderer.render(root,
                                       scale: CGFloat.greatestFiniteMagnitude)
            XCTAssertEqual(output.width, 0,
                           "backend=\(backend) compositor=\(compositor)")
            XCTAssertEqual(output.height, 0,
                           "backend=\(backend) compositor=\(compositor)")
        }
    }

    func testHostileStableCompositeCandidateIsSkippedSafely() {
        OpenUIKitRuntime.renderBackend = .quartz
        OpenUIKitRuntime.layerCaching = true
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 64, height: 64))
        root.backgroundColor = .white
        let oversized = UIView(frame: CGRect(x: 0, y: 0,
                                             width: 5000, height: 5000))
        oversized.backgroundColor = .red
        oversized.addSubview(UIView(frame: CGRect(x: 0, y: 0,
                                                  width: 10, height: 10)))
        oversized.addSubview(UIView(frame: CGRect(x: 20, y: 20,
                                                  width: 10, height: 10)))
        root.addSubview(oversized)

        // Repeated frames make this subtree a stable composite candidate.
        // Its 25M-pixel extent must be rejected before conversion/allocation;
        // direct layer composition still produces the bounded root frame.
        for _ in 0..<4 {
            let output = LayerBridge.render(root, scale: 1)
            XCTAssertEqual(output.width, 64)
            XCTAssertEqual(output.height, 64)
        }
    }

#if canImport(Foundation)
    func testConfigurationCopiesAndSecureArchivesAsImmutableValue() throws {
        let configuration = UIImage.SymbolConfiguration(pointSize: 56,
                                                          weight: .regular)
        let copy = try XCTUnwrap(configuration.copy() as? UIImage.SymbolConfiguration)
        XCTAssertFalse(copy === configuration)
        XCTAssertEqual(copy, configuration)

        let data = try NSKeyedArchiver.archivedData(
            withRootObject: configuration,
            requiringSecureCoding: true
        )
        let decoded = try XCTUnwrap(NSKeyedUnarchiver.unarchivedObject(
            ofClass: UIImage.SymbolConfiguration.self,
            from: data
        ))
        XCTAssertFalse(decoded === configuration)
        XCTAssertEqual(decoded, configuration)
        XCTAssertEqual(decoded.hash, configuration.hash)
    }
#endif

    private func rendered(_ image: UIImage, tint: UIColor) -> Bitmap {
        let view = UIImageView(image: image)
        view.tintColor = tint
        let width = Swift.max(1, image.bitmap.width)
        let height = Swift.max(1, image.bitmap.height)
        let output = Bitmap(width: width, height: height)
        view.drawContent(in: Canvas(bitmap: output, scale: image.scale),
                         bounds: view.bounds)
        return output
    }

    private func pixelTriples(_ bitmap: Bitmap) -> [[UInt8]] {
        stride(from: 0, to: bitmap.pixels.count, by: 4).compactMap { index in
            guard bitmap.pixels[index + 3] > 200 else { return nil }
            return [bitmap.pixels[index], bitmap.pixels[index + 1],
                    bitmap.pixels[index + 2]]
        }
    }

    private func fnv1a(_ bytes: [UInt8]) -> UInt64 {
        var hash: UInt64 = 14_695_981_039_346_656_037
        for byte in bytes {
            hash ^= UInt64(byte)
            hash = hash &* 1_099_511_628_211
        }
        return hash
    }

    private func assertHasColoredInk(_ bitmap: Bitmap,
                                     red: Bool, green: Bool, blue: Bool,
                                     file: StaticString = #filePath,
                                     line: UInt = #line) {
        let triples = pixelTriples(bitmap)
        XCTAssertFalse(triples.isEmpty, file: file, line: line)
        XCTAssertTrue(triples.contains { components in
            let r = Int(components[0])
            let g = Int(components[1])
            let b = Int(components[2])
            let isRed = r > g + 50 && r > b + 50
            let isGreen = g > r + 50 && g > b + 50
            let isBlue = b > r + 50 && b > g + 50
            return isRed == red && isGreen == green && isBlue == blue
        }, "no expected colored ink in \(triples.prefix(8))", file: file, line: line)
    }
}
