import Foundation
import XCTest
@testable import OpenUIKit

#if canImport(ObjectiveC)
@objc(OpenUIKitTestCopyingUnknownEffect)
#endif
#if !os(Linux)
@MainActor
#endif
private final class CopyingUnknownEffect: UIVisualEffect {
    static var copyCallCount = 0
    override class var supportsSecureCoding: Bool { true }
    let token: Int

    init(token: Int) {
        self.token = token
        super.init()
    }

    required init?(coder: NSCoder) {
        token = coder.allowsKeyedCoding
            ? coder.decodeInteger(forKey: "token") : 0
        super.init(coder: coder)
    }

    override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(token, forKey: "token")
    }

    override func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        Self.copyCallCount += 1
        return CopyingUnknownEffect(token: token + 1)
    }
}

#if canImport(ObjectiveC)
@objc(OpenUIKitTestCopyingBlurEffect)
#endif
#if !os(Linux)
@MainActor
#endif
private final class CopyingBlurEffect: UIBlurEffect {
    static var copyCallCount = 0
    override class var supportsSecureCoding: Bool { true }
    let token: Int

    init(token: Int) {
        self.token = token
        super.init()
    }

    required init?(coder: NSCoder) {
        token = coder.allowsKeyedCoding
            ? coder.decodeInteger(forKey: "token") : 0
        super.init(coder: coder)
    }

    override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(token, forKey: "token")
    }

    override func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        Self.copyCallCount += 1
        return CopyingBlurEffect(token: token + 1)
    }
}

#if !os(Linux)
@MainActor
#endif
private final class OverridingVisualEffectView: UIVisualEffectView {
    override var contentView: UIView { super.contentView }
    override var effect: UIVisualEffect? {
        get { super.effect }
        set { super.effect = newValue }
    }

    override init(effect: UIVisualEffect?) {
        super.init(effect: effect)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}

final class UIVisualEffectTests: XCTestCase {
    #if !os(Linux)
    @MainActor
    #endif
    private func requireEffectFoundationContracts<Effect: UIVisualEffect>(
        _ effect: Effect
    ) where Effect: NSCopying & NSSecureCoding {
        let object: NSObject = effect
        XCTAssertTrue(object === effect)
    }

    #if !os(Linux)
    @MainActor
    #endif
    private func requireViewFoundationContract<View: UIVisualEffectView>(
        _ view: View
    ) where View: NSSecureCoding {
        _ = view
    }

    #if !os(Linux)
    @MainActor
    #endif
    private func archiveRoundTrip(
        _ effect: UIVisualEffect
    ) throws -> UIVisualEffect {
        let data = try NSKeyedArchiver.archivedData(
            withRootObject: effect, requiringSecureCoding: true)
        return try XCTUnwrap(NSKeyedUnarchiver.unarchivedObject(
            ofClass: UIVisualEffect.self, from: data))
    }

    #if !os(Linux)
    @MainActor
    #endif
    func testRawValuesDefaultsAndRendererDescriptorsMatchIOS26() {
        let blurValues: [(UIBlurEffect.Style, Int)] = [
            (.extraLight, 0), (.light, 1), (.dark, 2),
            (.regular, 4), (.prominent, 5),
            (.systemUltraThinMaterial, 6), (.systemThinMaterial, 7),
            (.systemMaterial, 8), (.systemThickMaterial, 9),
            (.systemChromeMaterial, 10),
            (.systemUltraThinMaterialLight, 11),
            (.systemThinMaterialLight, 12), (.systemMaterialLight, 13),
            (.systemThickMaterialLight, 14),
            (.systemChromeMaterialLight, 15),
            (.systemUltraThinMaterialDark, 16),
            (.systemThinMaterialDark, 17), (.systemMaterialDark, 18),
            (.systemThickMaterialDark, 19),
            (.systemChromeMaterialDark, 20),
        ]
        for (style, raw) in blurValues {
            XCTAssertEqual(style.rawValue, raw)
            XCTAssertEqual(UIBlurEffect.Style(rawValue: raw), style)
        }
        XCTAssertEqual(UIBlurEffect.Style(rawValue: 3)?.rawValue, 3)
        XCTAssertEqual(UIBlurEffect.Style(rawValue: 21)?.rawValue, 21)
        XCTAssertNil(UIBlurEffect.Style(rawValue: -1))
        XCTAssertNil(UIBlurEffect.Style(rawValue: 22))
        XCTAssertNil(UIBlurEffect.Style(rawValue: 100))

        let vibrancyValues: [(UIVibrancyEffectStyle, Int)] = [
            (.label, 0), (.secondaryLabel, 1), (.tertiaryLabel, 2),
            (.quaternaryLabel, 3), (.fill, 4), (.secondaryFill, 5),
            (.tertiaryFill, 6), (.separator, 7),
        ]
        for (style, raw) in vibrancyValues {
            XCTAssertEqual(style.rawValue, raw)
            XCTAssertEqual(UIVibrancyEffectStyle(rawValue: raw), style)
        }
        XCTAssertEqual(UIVisualEffect()._descriptor, .unsupported)
        XCTAssertEqual(UIBlurEffect()._descriptor, .blur(style: nil))
        XCTAssertEqual(UIBlurEffect(style: .regular)._descriptor,
                       .blur(style: .regular))
        XCTAssertEqual(UIVibrancyEffect()._descriptor,
                       .vibrancy(blurStyle: nil, style: nil))
        XCTAssertEqual(
            UIVibrancyEffect(
                blurEffect: UIBlurEffect(style: .systemMaterial))._descriptor,
            .vibrancy(blurStyle: .systemMaterial, style: nil))
        XCTAssertEqual(
            UIVibrancyEffect(
                blurEffect: UIBlurEffect(style: .systemMaterial),
                style: .secondaryLabel)._descriptor,
            .vibrancy(blurStyle: .systemMaterial,
                      style: .secondaryLabel))
    }

    #if !os(Linux)
    @MainActor
    #endif
    func testEffectsHaveExactFoundationContractsAndImmutableIdentityCopy() {
        let effects: [UIVisualEffect] = [
            UIVisualEffect(),
            UIBlurEffect(),
            UIBlurEffect(style: .regular),
            UIVibrancyEffect(),
            UIVibrancyEffect(
                blurEffect: UIBlurEffect(style: .systemMaterial)),
            UIVibrancyEffect(
                blurEffect: UIBlurEffect(style: .systemMaterial),
                style: .label),
        ]
        XCTAssertTrue(UIVisualEffect.supportsSecureCoding)
        for effect in effects {
            requireEffectFoundationContracts(effect)
            XCTAssertTrue((effect.copy(with: nil) as AnyObject) === effect)
        }
    }

    #if !os(Linux)
    @MainActor
    #endif
    func testSecureArchivesCreateFreshEffectsAndPreserveDescriptors() throws {
        let privateBlur3 = UIBlurEffect(style: try XCTUnwrap(
            UIBlurEffect.Style(rawValue: 3)))
        let privateBlur21 = UIBlurEffect(style: try XCTUnwrap(
            UIBlurEffect.Style(rawValue: 21)))
        let effects: [UIVisualEffect] = [
            UIVisualEffect(),
            UIBlurEffect(),
            privateBlur3,
            UIBlurEffect(style: .systemThickMaterialDark),
            privateBlur21,
            UIVibrancyEffect(),
            UIVibrancyEffect(blurEffect: UIBlurEffect()),
            UIVibrancyEffect(
                blurEffect: UIBlurEffect(style: .regular)),
            UIVibrancyEffect(
                blurEffect: UIBlurEffect(style: .systemMaterial),
                style: .tertiaryFill),
        ]
        for effect in effects {
            let decoded = try archiveRoundTrip(effect)
            XCTAssertFalse(decoded === effect)
            XCTAssertTrue(type(of: decoded) == type(of: effect))
            XCTAssertEqual(decoded._descriptor, effect._descriptor)
            if effect is UIBlurEffect || effect is UIVibrancyEffect {
                XCTAssertTrue(effect.isEqual(decoded))
                XCTAssertEqual(effect.hash, decoded.hash)
            }
        }
    }

    #if !os(Linux)
    @MainActor
    #endif
    func testBuiltInEffectNSObjectEqualityAndHashMatchIOS26() throws {
        let inertBlur = UIBlurEffect()
        let lightA = UIBlurEffect(style: .light)
        let lightB = UIBlurEffect(style: .light)
        let dark = UIBlurEffect(style: .dark)
        let regular = UIBlurEffect(style: .regular)

        XCTAssertFalse(lightA === lightB)
        XCTAssertTrue(lightA.isEqual(lightB))
        XCTAssertFalse(lightA.isEqual(dark))
        XCTAssertFalse(inertBlur.isEqual(lightA))
        XCTAssertEqual(inertBlur.hash, 0)
        XCTAssertEqual(lightA.hash, 1)
        XCTAssertEqual(dark.hash, 2)
        XCTAssertEqual(regular.hash, 4)

        let labelA = UIVibrancyEffect(
            blurEffect: lightA, style: .label)
        let labelB = UIVibrancyEffect(
            blurEffect: lightB, style: .label)
        let secondary = UIVibrancyEffect(
            blurEffect: lightB, style: .secondaryLabel)
        let darkLabel = UIVibrancyEffect(
            blurEffect: dark, style: .label)
        let inertA = UIVibrancyEffect()
        let inertB = UIVibrancyEffect()
        let explicitInert = UIVibrancyEffect(blurEffect: inertBlur)

        XCTAssertTrue(labelA.isEqual(labelB))
        XCTAssertTrue(labelA.isEqual(secondary),
                      "native equality ignores vibrancy style")
        XCTAssertFalse(labelA.isEqual(darkLabel))
        XCTAssertTrue(inertA.isEqual(inertB))
        XCTAssertFalse(inertA.isEqual(explicitInert))
        XCTAssertFalse(inertA.isEqual(labelA))
        XCTAssertEqual(inertA.hash, 7_502_673_159_197_000_442)
        XCTAssertEqual(explicitInert.hash, 24)
        XCTAssertEqual(labelA.hash, 1)
        XCTAssertEqual(darkLabel.hash, 2)

        for effect in [lightA, labelA, inertA, explicitInert] {
            let decoded = try archiveRoundTrip(effect)
            XCTAssertFalse(decoded === effect)
            XCTAssertTrue(effect.isEqual(decoded))
            XCTAssertEqual(effect.hash, decoded.hash)
        }
    }

    #if !os(Linux)
    @MainActor
    #endif
    func testOpenUIKitMatchesCheckedInIOS26SemanticOracle() throws {
        func oracleRect(_ value: CGRect) -> String {
            "(\(value.minX),\(value.minY),\(value.width),\(value.height))"
        }
        func equality(
            _ name: String,
            _ lhs: UIVisualEffect,
            _ rhs: UIVisualEffect
        ) -> String {
            "\(name) identity=\(lhs === rhs) equal=\(lhs.isEqual(rhs)) "
                + "hashes=\(lhs.hash),\(rhs.hash)"
        }

        let inertBlur = UIBlurEffect()
        let lightA = UIBlurEffect(style: .light)
        let lightB = UIBlurEffect(style: .light)
        let dark = UIBlurEffect(style: .dark)
        let regular = UIBlurEffect(style: .regular)
        let archivedLight = try archiveRoundTrip(lightA)
        let labelA = UIVibrancyEffect(
            blurEffect: lightA, style: .label)
        let labelB = UIVibrancyEffect(
            blurEffect: lightB, style: .label)
        let secondary = UIVibrancyEffect(
            blurEffect: lightB, style: .secondaryLabel)
        let darkLabel = UIVibrancyEffect(
            blurEffect: dark, style: .label)
        let inertVibrancyA = UIVibrancyEffect()
        let inertVibrancyB = UIVibrancyEffect()
        let inertBlurVibrancy = UIVibrancyEffect(blurEffect: inertBlur)
        let archivedLabel = try archiveRoundTrip(labelA)

        let baseAppearance = UIBarAppearance()
        let toolbarAppearance = UIToolbarAppearance()
        let tabAppearance = UITabBarAppearance()
        let oldDefaultEffect = baseAppearance.backgroundEffect
        let freshBaseToolbar = baseAppearance.backgroundEffect
            === toolbarAppearance.backgroundEffect
        let freshBaseTab = baseAppearance.backgroundEffect
            === tabAppearance.backgroundEffect
        baseAppearance.configureWithDefaultBackground()
        let chromeFactoryA = UIBlurEffect(style: .systemChromeMaterial)
        let chromeFactoryB = UIBlurEffect(style: .systemChromeMaterial)
        let baseAppearanceCopy = UIBarAppearance(
            barAppearance: baseAppearance)

        var lines = [
            "fresh.base-toolbar=\(freshBaseToolbar)",
            "fresh.base-tab=\(freshBaseTab)",
            "reset.same-old=\(baseAppearance.backgroundEffect === oldDefaultEffect)",
            "reset.same-toolbar=\(baseAppearance.backgroundEffect === toolbarAppearance.backgroundEffect)",
            "factory.same=\(chromeFactoryA === chromeFactoryB)",
            "fresh.base-factory=\(baseAppearance.backgroundEffect === chromeFactoryA)",
            "copy.same=\(baseAppearanceCopy.backgroundEffect === baseAppearance.backgroundEffect)",
            equality("blur.same", lightA, lightB),
            equality("blur.cross-style", lightA, dark),
            equality("blur.inert-vs-light", inertBlur, lightA),
            equality("blur.archive", lightA, archivedLight),
            "blur.hashes inert=\(inertBlur.hash) light=\(lightA.hash) "
                + "dark=\(dark.hash) regular=\(regular.hash)",
            equality("vibrancy.same", labelA, labelB),
            equality("vibrancy.cross-style", labelA, secondary),
            equality("vibrancy.cross-blur", labelA, darkLabel),
            equality("vibrancy.inert", inertVibrancyA, inertVibrancyB),
            equality("vibrancy.nil-vs-inert-blur",
                     inertVibrancyA, inertBlurVibrancy),
            equality("vibrancy.inert-vs-light", inertVibrancyA, labelA),
            equality("vibrancy.archive", labelA, archivedLabel),
            "vibrancy.hashes inert=\(inertVibrancyA.hash) "
                + "inertBlur=\(inertBlurVibrancy.hash) "
                + "light=\(labelA.hash) dark=\(darkLabel.hash)",
        ]

        func appendCombined(
            _ name: String,
            _ effect: UIVisualEffect?,
            accessFirst: Bool
        ) {
            let view = UIVisualEffectView(effect: effect)
            view.frame = CGRect(x: 10, y: 20, width: 120, height: 80)
            var saved: UIView?
            if accessFirst {
                saved = view.contentView
            }
            view.bounds = CGRect(x: 7, y: 9, width: 200, height: 110)
            let content = saved ?? view.contentView
            lines.append(
                "\(name) accessFirst=\(accessFirst) "
                    + "content=\(oracleRect(content.frame))")
        }
        appendCombined("nil", nil, accessFirst: false)
        appendCombined("nil", nil, accessFirst: true)
        appendCombined("base", UIVisualEffect(), accessFirst: false)
        appendCombined("base", UIVisualEffect(), accessFirst: true)
        appendCombined("blur", UIBlurEffect(style: .regular),
                       accessFirst: false)
        appendCombined("blur", UIBlurEffect(style: .regular),
                       accessFirst: true)
        appendCombined("vibrancy", UIVibrancyEffect(), accessFirst: false)
        appendCombined("vibrancy", UIVibrancyEffect(), accessFirst: true)

        let nilOrigin = UIVisualEffectView(effect: nil)
        nilOrigin.frame = CGRect(x: 10, y: 20, width: 120, height: 80)
        let nilOriginContent = nilOrigin.contentView
        nilOrigin.bounds.origin = CGPoint(x: 7, y: 9)
        nilOrigin.layoutIfNeeded()
        lines.append("nil-origin-after-access content="
                     + oracleRect(nilOriginContent.frame))

        let lateBlur = UIVisualEffectView(
            frame: CGRect(x: 10, y: 20, width: 120, height: 80))
        let lateBlurContent = lateBlur.contentView
        lateBlur.effect = UIBlurEffect(style: .regular)
        lateBlur.bounds = CGRect(x: 7, y: 9, width: 200, height: 110)
        lateBlur.layoutIfNeeded()
        lines.append("frame-access-blur-combined content="
                     + oracleRect(lateBlurContent.frame))

        let toggle = UIVisualEffectView(
            effect: UIBlurEffect(style: .regular))
        toggle.frame = CGRect(x: 10, y: 20, width: 120, height: 80)
        let toggleContent = toggle.contentView
        toggle.bounds.origin = CGPoint(x: 7, y: 9)
        toggle.layoutIfNeeded()
        toggle.effect = nil
        lines.append("blur-to-nil-immediate content="
                     + oracleRect(toggleContent.frame))

        func appendAssignment(
            _ name: String,
            initial: UIVisualEffect?,
            replacement: (UIVisualEffect?) -> UIVisualEffect?
        ) {
            let view = UIVisualEffectView(effect: initial)
            view.frame = CGRect(x: 10, y: 20, width: 120, height: 80)
            let content = view.contentView
            view.bounds.origin = CGPoint(x: 7, y: 9)
            view.layoutIfNeeded()
            view.effect = replacement(view.effect)
            lines.append("\(name)=\(oracleRect(content.frame))")
        }
        appendAssignment("blur-to-nil",
                         initial: UIBlurEffect(style: .regular)) { _ in nil }
        appendAssignment("blur-to-base",
                         initial: UIBlurEffect(style: .regular)) {
            _ in UIVisualEffect()
        }
        appendAssignment("blur-to-vibrancy",
                         initial: UIBlurEffect(style: .regular)) {
            _ in UIVibrancyEffect()
        }
        appendAssignment("blur-to-blur",
                         initial: UIBlurEffect(style: .regular)) {
            _ in UIBlurEffect(style: .dark)
        }
        appendAssignment("blur-to-same",
                         initial: UIBlurEffect(style: .regular)) { $0 }
        appendAssignment("blur-to-equal",
                         initial: UIBlurEffect(style: .regular)) {
            _ in UIBlurEffect(style: .regular)
        }
        appendAssignment("nil-to-nil", initial: nil) { _ in nil }
        appendAssignment("nil-to-base", initial: nil) {
            _ in UIVisualEffect()
        }
        appendAssignment("nil-to-blur", initial: nil) {
            _ in UIBlurEffect(style: .regular)
        }
        appendAssignment("nil-to-vibrancy", initial: nil) {
            _ in UIVibrancyEffect()
        }
        appendAssignment("base-to-nil", initial: UIVisualEffect()) {
            _ in nil
        }
        appendAssignment("base-to-base", initial: UIVisualEffect()) {
            _ in UIVisualEffect()
        }
        appendAssignment("vibrancy-to-nil", initial: UIVibrancyEffect()) {
            _ in nil
        }
        appendAssignment("vibrancy-to-blur", initial: UIVibrancyEffect()) {
            _ in UIBlurEffect(style: .regular)
        }
        appendAssignment(
            "vibrancy-equal-style",
            initial: UIVibrancyEffect(
                blurEffect: UIBlurEffect(style: .light), style: .label)
        ) { _ in
            UIVibrancyEffect(
                blurEffect: UIBlurEffect(style: .light),
                style: .secondaryLabel)
        }
        appendAssignment(
            "vibrancy-different-blur",
            initial: UIVibrancyEffect(
                blurEffect: UIBlurEffect(style: .light), style: .label)
        ) { _ in
            UIVibrancyEffect(
                blurEffect: UIBlurEffect(style: .dark), style: .label)
        }
        appendAssignment("vibrancy-inert-equal",
                         initial: UIVibrancyEffect()) {
            _ in UIVibrancyEffect()
        }
        appendAssignment("vibrancy-inert-explicit",
                         initial: UIVibrancyEffect()) {
            _ in UIVibrancyEffect(blurEffect: UIBlurEffect())
        }

        func appendLazyAssignment(
            _ name: String,
            initial: UIVisualEffect?,
            replacement: UIVisualEffect?
        ) {
            let view = UIVisualEffectView(effect: initial)
            view.frame = CGRect(x: 10, y: 20, width: 120, height: 80)
            view.bounds = CGRect(x: 7, y: 9, width: 200, height: 110)
            view.effect = replacement
            lines.append("\(name)=\(oracleRect(view.contentView.frame))")
        }
        appendLazyAssignment("lazy-nil-to-vibrancy", initial: nil,
                             replacement: UIVibrancyEffect())
        appendLazyAssignment("lazy-blur-to-vibrancy",
                             initial: UIBlurEffect(style: .regular),
                             replacement: UIVibrancyEffect())
        appendLazyAssignment("lazy-base-to-vibrancy",
                             initial: UIVisualEffect(),
                             replacement: UIVibrancyEffect())
        appendLazyAssignment("lazy-nil-to-blur", initial: nil,
                             replacement: UIBlurEffect(style: .regular))
        appendLazyAssignment("lazy-nil-to-base", initial: nil,
                             replacement: UIVisualEffect())

        let testFile = URL(fileURLWithPath: #filePath)
        let repoRoot = testFile.deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let goldenURL = repoRoot.appendingPathComponent(
            "fixtures/realapp/visual_effect_semantics_ios26.1.txt")
        let golden = try String(contentsOf: goldenURL, encoding: .utf8)
        XCTAssertEqual(lines.joined(separator: "\n") + "\n", golden)
    }

    #if !os(Linux)
    @MainActor
    #endif
    func testViewInitializersOpenPropertiesAndStableContentIdentity() throws {
        let zero = UIVisualEffectView()
        let frame = CGRect(x: 10, y: 20, width: 120, height: 80)
        let framed = UIVisualEffectView(frame: frame)
        let blur = UIBlurEffect(style: .regular)
        let effected = UIVisualEffectView(effect: blur)
        let subclass = OverridingVisualEffectView(effect: blur)
        let decodedDefaults = try XCTUnwrap(UIVisualEffectView(coder: NSCoder()))

        XCTAssertEqual(zero.frame, .zero)
        XCTAssertEqual(framed.frame, frame)
        XCTAssertEqual(effected.frame, .zero)
        XCTAssertTrue(effected.effect === blur)
        XCTAssertTrue(subclass.effect === blur)
        XCTAssertTrue(subclass.contentView === superContent(of: subclass))
        XCTAssertEqual(decodedDefaults.frame, .zero)
        XCTAssertNil(decodedDefaults.effect)
        requireViewFoundationContract(effected)
        XCTAssertTrue(UIVisualEffectView.supportsSecureCoding)

        let first = framed.contentView
        XCTAssertTrue(first === framed.contentView)
        XCTAssertTrue(first.superview === framed)
        XCTAssertEqual(first.frame,
                       CGRect(x: 0, y: 0, width: 120, height: 80))
        XCTAssertEqual(first.autoresizingMask,
                       [.flexibleWidth, .flexibleHeight])
        XCTAssertTrue(first.isOpaque)
        XCTAssertTrue(first.isUserInteractionEnabled)
        XCTAssertFalse(framed.clipsToBounds)
    }

    #if !os(Linux)
    @MainActor
    #endif
    func testEffectViewHierarchyPolicyPointsAppsAtContentView() {
        let view = UIVisualEffectView(
            effect: UIBlurEffect(style: .regular))
        XCTAssertEqual(
            view._directSubviewInsertionFailureMessage,
            "UIVisualEffectView does not accept direct subviews; "
                + "add the view to contentView instead"
        )
        let child = UIView(frame: .zero)
        view.contentView.addSubview(child)
        XCTAssertTrue(child.superview === view.contentView)
        XCTAssertFalse(view.subviews.contains { $0 === child })
    }

    #if !os(Linux)
    @MainActor
    #endif
    func testEffectInitializerCopiesHostileEffectExactlyOnce() throws {
        CopyingUnknownEffect.copyCallCount = 0
        let source = CopyingUnknownEffect(token: 70)
        let view = UIVisualEffectView(effect: source)
        let stored = try XCTUnwrap(view.effect as? CopyingUnknownEffect)

        XCTAssertEqual(CopyingUnknownEffect.copyCallCount, 1)
        XCTAssertFalse(stored === source)
        XCTAssertEqual(stored.token, 71)
        XCTAssertEqual(view._visualEffectDescriptor, .unsupported)
        XCTAssertTrue(view.subviews.isEmpty,
                      "base/unknown effects keep contentView lazy")
        let content = view.contentView
        XCTAssertEqual(view.subviews, [content])

        CopyingBlurEffect.copyCallCount = 0
        let blur = CopyingBlurEffect(token: 80)
        let blurView = UIVisualEffectView(effect: blur)
        let storedBlur = try XCTUnwrap(
            blurView.effect as? CopyingBlurEffect)
        XCTAssertEqual(CopyingBlurEffect.copyCallCount, 1)
        XCTAssertFalse(storedBlur === blur)
        XCTAssertEqual(storedBlur.token, 81)
        XCTAssertEqual(blurView.subviews.filter {
            $0 is _UIVisualEffectBackdropView
        }.count, 1)
    }

    #if !os(Linux)
    @MainActor
    #endif
    func testCoderInitializerCopiesDecodedHostileEffectExactlyOnce() throws {
        let source = CopyingUnknownEffect(token: 75)
        let archiver = NSKeyedArchiver(requiringSecureCoding: true)
        archiver.encode(source,
                        forKey: "OpenUIKit.UIVisualEffectView.effect")
        archiver.finishEncoding()

        CopyingUnknownEffect.copyCallCount = 0
        let unarchiver = try NSKeyedUnarchiver(
            forReadingFrom: archiver.encodedData)
        unarchiver.requiresSecureCoding = true
        let view = try XCTUnwrap(UIVisualEffectView(coder: unarchiver))
        unarchiver.finishDecoding()
        let stored = try XCTUnwrap(view.effect as? CopyingUnknownEffect)

        XCTAssertEqual(CopyingUnknownEffect.copyCallCount, 1)
        XCTAssertEqual(stored.token, 76)
        XCTAssertEqual(view.subviews, [view.contentView])
    }

    /// Reading through the base type proves the open getter dynamically
    /// dispatches without exposing the test subclass's implementation detail
    /// in the assertion above.
    #if !os(Linux)
    @MainActor
    #endif
    private func superContent(of view: UIVisualEffectView) -> UIView {
        view.contentView
    }

    #if !os(Linux)
    @MainActor
    #endif
    func testDetachedContentGeometryMatchesIOS26AccessOrder() {
        let initialFrame = CGRect(x: 10, y: 20, width: 120, height: 80)
        let shiftedBounds = CGRect(x: 7, y: 9, width: 200, height: 110)
        let zeroFill = CGRect(x: 0, y: 0, width: 200, height: 110)

        let effects: [(String, UIVisualEffect?, Bool)] = [
            ("nil", nil, false),
            ("base", UIVisualEffect(), false),
            ("blur", UIBlurEffect(style: .regular), false),
            ("vibrancy", UIVibrancyEffect(), true),
        ]
        for (name, effect, eagerlyMaterialized) in effects {
            for accessFirst in [false, true] {
                let view = UIVisualEffectView(effect: effect)
                view.frame = initialFrame
                var saved: UIView?
                if accessFirst {
                    saved = view.contentView
                }
                let contentWasPresent = view.subviews.contains {
                    $0 is _UIVisualEffectContentView
                }
                XCTAssertEqual(contentWasPresent,
                               accessFirst || eagerlyMaterialized,
                               "\(name), accessFirst=\(accessFirst)")
                view.bounds = shiftedBounds
                let content = saved ?? view.contentView
                let expected = accessFirst || eagerlyMaterialized
                    ? zeroFill : shiftedBounds
                XCTAssertEqual(content.frame, expected,
                               "\(name), accessFirst=\(accessFirst)")
                view.layoutIfNeeded()
                XCTAssertEqual(content.frame, expected,
                               "\(name), accessFirst=\(accessFirst), layout")
                XCTAssertTrue(view.subviews.last === content)
                if effect is UIBlurEffect {
                    let backdrop = view.subviews.first {
                        $0 is _UIVisualEffectBackdropView
                    }
                    XCTAssertEqual(backdrop?.frame, content.frame)
                }
            }
        }

        // Accessing a nil-effect view before an origin-only mutation pins its
        // detached content at zero, even across an explicit layout pass.
        let nilOrigin = UIVisualEffectView(frame: initialFrame)
        let nilOriginContent = nilOrigin.contentView
        nilOrigin.bounds.origin = shiftedBounds.origin
        nilOrigin.layoutIfNeeded()
        XCTAssertEqual(nilOriginContent.frame,
                       CGRect(x: 0, y: 0, width: 120, height: 80))

        // Frame -> access -> blur -> combined bounds remains zero-origin.
        let lateBlur = UIVisualEffectView(frame: initialFrame)
        let lateBlurContent = lateBlur.contentView
        lateBlur.effect = UIBlurEffect(style: .regular)
        lateBlur.bounds = shiftedBounds
        lateBlur.layoutIfNeeded()
        XCTAssertEqual(lateBlurContent.frame, zeroFill)

        // This is one member of the full semantic-assignment matrix below:
        // blur -> nil immediately adopts the current bounds origin.
        let toggle = UIVisualEffectView(
            effect: UIBlurEffect(style: .regular))
        toggle.frame = initialFrame
        let toggleContent = toggle.contentView
        toggle.bounds.origin = shiftedBounds.origin
        toggle.layoutIfNeeded()
        XCTAssertEqual(toggleContent.frame,
                       CGRect(x: 0, y: 0, width: 120, height: 80))
        toggle.effect = nil
        XCTAssertEqual(toggleContent.frame,
                       CGRect(x: 7, y: 9, width: 120, height: 80))
    }

    #if !os(Linux)
    @MainActor
    #endif
    func testEffectAssignmentGeometryUsesNSObjectSemanticChange() {
        let initialFrame = CGRect(x: 10, y: 20, width: 120, height: 80)
        let shiftedOrigin = CGPoint(x: 7, y: 9)
        let zeroFrame = CGRect(x: 0, y: 0, width: 120, height: 80)
        let shiftedFrame = CGRect(x: 7, y: 9, width: 120, height: 80)

        func check(
            _ name: String,
            initial: UIVisualEffect?,
            replacement: (UIVisualEffect?) -> UIVisualEffect?,
            changesSemantically: Bool
        ) {
            let view = UIVisualEffectView(effect: initial)
            view.frame = initialFrame
            let content = view.contentView
            view.bounds.origin = shiftedOrigin
            view.layoutIfNeeded()
            XCTAssertEqual(content.frame, zeroFrame, "\(name), staged")
            view.effect = replacement(view.effect)
            XCTAssertEqual(
                content.frame,
                changesSemantically ? shiftedFrame : zeroFrame,
                name)
            if view.effect is UIBlurEffect {
                let backdrop = view.subviews.first {
                    $0 is _UIVisualEffectBackdropView
                }
                XCTAssertEqual(backdrop?.frame, content.frame, name)
            }
        }

        check("blur-to-nil", initial: UIBlurEffect(style: .regular),
              replacement: { _ in nil }, changesSemantically: true)
        check("blur-to-base", initial: UIBlurEffect(style: .regular),
              replacement: { _ in UIVisualEffect() },
              changesSemantically: true)
        check("blur-to-vibrancy", initial: UIBlurEffect(style: .regular),
              replacement: { _ in UIVibrancyEffect() },
              changesSemantically: true)
        check("blur-to-blur", initial: UIBlurEffect(style: .regular),
              replacement: { _ in UIBlurEffect(style: .dark) },
              changesSemantically: true)
        check("blur-to-same", initial: UIBlurEffect(style: .regular),
              replacement: { $0 }, changesSemantically: false)
        check("blur-to-equal", initial: UIBlurEffect(style: .regular),
              replacement: { _ in UIBlurEffect(style: .regular) },
              changesSemantically: false)
        check("nil-to-nil", initial: nil, replacement: { _ in nil },
              changesSemantically: false)
        check("nil-to-base", initial: nil,
              replacement: { _ in UIVisualEffect() },
              changesSemantically: true)
        check("nil-to-blur", initial: nil,
              replacement: { _ in UIBlurEffect(style: .regular) },
              changesSemantically: true)
        check("nil-to-vibrancy", initial: nil,
              replacement: { _ in UIVibrancyEffect() },
              changesSemantically: true)
        check("base-to-nil", initial: UIVisualEffect(),
              replacement: { _ in nil }, changesSemantically: true)
        check("base-to-base", initial: UIVisualEffect(),
              replacement: { _ in UIVisualEffect() },
              changesSemantically: true)
        check("vibrancy-to-nil", initial: UIVibrancyEffect(),
              replacement: { _ in nil }, changesSemantically: true)
        check("vibrancy-to-blur", initial: UIVibrancyEffect(),
              replacement: { _ in UIBlurEffect(style: .regular) },
              changesSemantically: true)
        check(
            "vibrancy-equal-style",
            initial: UIVibrancyEffect(
                blurEffect: UIBlurEffect(style: .light), style: .label),
            replacement: { _ in
                UIVibrancyEffect(
                    blurEffect: UIBlurEffect(style: .light),
                    style: .secondaryLabel)
            },
            changesSemantically: false)
        check(
            "vibrancy-different-blur",
            initial: UIVibrancyEffect(
                blurEffect: UIBlurEffect(style: .light), style: .label),
            replacement: { _ in
                UIVibrancyEffect(
                    blurEffect: UIBlurEffect(style: .dark), style: .label)
            },
            changesSemantically: true)
        check("vibrancy-inert-equal", initial: UIVibrancyEffect(),
              replacement: { _ in UIVibrancyEffect() },
              changesSemantically: false)
        check("vibrancy-inert-explicit", initial: UIVibrancyEffect(),
              replacement: {
                  _ in UIVibrancyEffect(blurEffect: UIBlurEffect())
              },
              changesSemantically: true)

        func checkLazyVibrancy(
            _ name: String,
            initial: UIVisualEffect?
        ) {
            let view = UIVisualEffectView(effect: initial)
            view.frame = initialFrame
            view.bounds = CGRect(x: 7, y: 9, width: 200, height: 110)
            view.effect = UIVibrancyEffect()
            XCTAssertEqual(
                view.contentView.frame,
                CGRect(x: 7, y: 9, width: 200, height: 110),
                name)
        }
        checkLazyVibrancy("lazy-nil-to-vibrancy", initial: nil)
        checkLazyVibrancy("lazy-blur-to-vibrancy",
                          initial: UIBlurEffect(style: .regular))
        checkLazyVibrancy("lazy-base-to-vibrancy",
                          initial: UIVisualEffect())
    }

    #if !os(Linux)
    @MainActor
    #endif
    func testHostedContentGeometryUsesBoundsOriginForBothSetupOrders() {
        let window = UIWindow(
            frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let initialFrame = CGRect(x: 10, y: 20, width: 120, height: 80)
        let shiftedBounds = CGRect(x: 7, y: 9, width: 200, height: 110)

        // Unlike detached effect-present views, a hosted origin-only change
        // adopts the bounds origin immediately for both setup orders.
        let effectThenFrame = UIVisualEffectView(
            effect: UIBlurEffect(style: .regular))
        window.addSubview(effectThenFrame)
        effectThenFrame.frame = initialFrame
        effectThenFrame.bounds.origin = shiftedBounds.origin

        let frameThenEffect = UIVisualEffectView(frame: initialFrame)
        window.addSubview(frameThenEffect)
        frameThenEffect.effect = UIBlurEffect(style: .regular)
        frameThenEffect.bounds.origin = shiftedBounds.origin

        for view in [effectThenFrame, frameThenEffect] {
            XCTAssertEqual(view.contentView.frame,
                           CGRect(x: 7, y: 9, width: 120, height: 80))
        }

        window.layoutIfNeeded()
        effectThenFrame.layoutIfNeeded()
        frameThenEffect.layoutIfNeeded()

        for view in [effectThenFrame, frameThenEffect] {
            XCTAssertEqual(view.contentView.frame,
                           CGRect(x: 7, y: 9, width: 120, height: 80))
            view.bounds.size = shiftedBounds.size
            view.layoutIfNeeded()
        }

        for view in [effectThenFrame, frameThenEffect] {
            XCTAssertEqual(view.contentView.frame, shiftedBounds)
            XCTAssertEqual(view.contentView.bounds,
                           CGRect(x: 0, y: 0, width: 200, height: 110))
            XCTAssertTrue(view.subviews.last === view.contentView)
            let backdrop = view.subviews.first {
                $0 is _UIVisualEffectBackdropView
            }
            XCTAssertEqual(backdrop?.frame, shiftedBounds)
        }
    }

    #if !os(Linux)
    @MainActor
    #endif
    func testEffectMutationCopiesAndOnlyBlurInstallsBackdrop() throws {
        let view = UIVisualEffectView(
            frame: CGRect(x: 0, y: 0, width: 100, height: 60))
        let content = view.contentView
        XCTAssertEqual(view.subviews.count, 1)

        let blur = UIBlurEffect(style: .systemMaterial)
        view.effect = blur
        XCTAssertTrue(view.effect === blur,
                      "immutable UIKit effects return identity from copy")
        XCTAssertEqual(view._visualEffectDescriptor,
                       .blur(style: .systemMaterial))
        XCTAssertEqual(view.subviews.filter {
            $0 is _UIVisualEffectBackdropView
        }.count, 1)
        XCTAssertTrue(view.subviews.last === content)

        let unknown = CopyingUnknownEffect(token: 40)
        CopyingUnknownEffect.copyCallCount = 0
        view.effect = unknown
        let stored = try XCTUnwrap(view.effect as? CopyingUnknownEffect)
        XCTAssertEqual(CopyingUnknownEffect.copyCallCount, 1)
        XCTAssertFalse(stored === unknown)
        XCTAssertEqual(stored.token, 41)
        XCTAssertEqual(view._visualEffectDescriptor, .unsupported)
        XCTAssertFalse(view.subviews.contains {
            $0 is _UIVisualEffectBackdropView
        })
        XCTAssertEqual(view.subviews.count, 1)
        XCTAssertTrue(view.subviews.first === content)

        view.effect = UIVisualEffect()
        XCTAssertEqual(view._visualEffectDescriptor, .unsupported)
        XCTAssertEqual(view.subviews, [content])

        view.effect = UIVibrancyEffect()
        XCTAssertEqual(view._visualEffectDescriptor,
                       .vibrancy(blurStyle: nil, style: nil))
        XCTAssertEqual(view.subviews, [content])

        view.effect = UIVibrancyEffect(
            blurEffect: UIBlurEffect(style: .regular))
        XCTAssertEqual(view._visualEffectDescriptor,
                       .vibrancy(blurStyle: .regular, style: nil))
        XCTAssertEqual(view.subviews, [content])

        view.effect = nil
        XCTAssertNil(view._visualEffectDescriptor)
        XCTAssertNil(view.effect)
        XCTAssertTrue(view.contentView === content)
        XCTAssertEqual(view.subviews, [content])
    }

#if canImport(Foundation) && canImport(ObjectiveC)
    #if !os(Linux)
    @MainActor
    #endif
    func testDarwinBaseViewArchiveSnapshotPreservesGeometryAndEffect() throws {
        let view = UIVisualEffectView(
            effect: UIBlurEffect(style: .systemThinMaterialDark))
        view.frame = CGRect(x: -30, y: 5, width: 200, height: 110)
        view.bounds.origin = CGPoint(x: 7, y: 9)
        let originalContent = view.contentView

        let data = try NSKeyedArchiver.archivedData(
            withRootObject: view, requiringSecureCoding: true)
        let unarchiver = try NSKeyedUnarchiver(forReadingFrom: data)
        unarchiver.requiresSecureCoding = true
        unarchiver.decodingFailurePolicy = .setErrorAndReturn
        let decodedObject = unarchiver.decodeObject(
            of: [_UIVisualEffectViewArchiveProxy.self,
                 UIVisualEffect.self, UIBlurEffect.self],
            forKey: NSKeyedArchiveRootObjectKey)
        let decoded = try XCTUnwrap(
            decodedObject as? UIVisualEffectView,
            "decode error: \(String(describing: unarchiver.error)); "
                + "object: \(String(describing: decodedObject))")
        unarchiver.finishDecoding()
        let decodedContentFrameBeforeLayout = decoded.contentView.frame
        decoded.layoutIfNeeded()

        // A normal client cannot name the private bridge in a secure
        // allowed-class list while UIView remains outside NSObject, but the
        // public top-level decoder still exercises the same archive payload.
        let publicUnarchiver = try NSKeyedUnarchiver(forReadingFrom: data)
        publicUnarchiver.requiresSecureCoding = false
        let publicDecoded = try XCTUnwrap(publicUnarchiver.decodeObject(
            forKey: NSKeyedArchiveRootObjectKey) as? UIVisualEffectView)
        publicUnarchiver.finishDecoding()

        XCTAssertFalse(decoded === view)
        XCTAssertEqual(decoded.frame,
                       CGRect(x: -30, y: 5, width: 200, height: 110))
        XCTAssertEqual(decoded.bounds,
                       CGRect(x: 7, y: 9, width: 200, height: 110))
        XCTAssertEqual(decoded._visualEffectDescriptor,
                       .blur(style: .systemThinMaterialDark))
        XCTAssertFalse(decoded.contentView === originalContent)
        XCTAssertTrue(decoded.contentView === decoded.contentView)
        XCTAssertEqual(decodedContentFrameBeforeLayout,
                       CGRect(x: 7, y: 9, width: 200, height: 110))
        XCTAssertEqual(decoded.contentView.frame,
                       CGRect(x: 7, y: 9, width: 200, height: 110))
        XCTAssertTrue(decoded.subviews.last === decoded.contentView)
        XCTAssertEqual(decoded.subviews.filter {
            $0 is _UIVisualEffectBackdropView
        }.count, 1)
        XCTAssertEqual(publicDecoded.frame, decoded.frame)
        XCTAssertEqual(publicDecoded.bounds, decoded.bounds)
        XCTAssertEqual(publicDecoded.contentView.frame,
                       CGRect(x: 7, y: 9, width: 200, height: 110))
        XCTAssertTrue(publicDecoded.contentView === publicDecoded.contentView)
    }
#endif

    #if !os(Linux)
    @MainActor
    #endif
    func testBarAppearanceBackgroundEffectFamilyMatrixMatchesIOS26() {
        let base = UIBarAppearance()
        let navigation = UINavigationBarAppearance()
        let toolbar = UIToolbarAppearance()
        let tab = UITabBarAppearance()
        let appearances: [UIBarAppearance] = [
            base, navigation, toolbar, tab,
        ]
        let defaultsHaveChrome = [true, false, true, true]

        let sharedChrome = base.backgroundEffect
        XCTAssertNotNil(sharedChrome)
        XCTAssertTrue(toolbar.backgroundEffect === sharedChrome)
        XCTAssertTrue(tab.backgroundEffect === sharedChrome)
        XCTAssertNil(navigation.backgroundEffect)

        let factoryA = UIBlurEffect(style: .systemChromeMaterial)
        let factoryB = UIBlurEffect(style: .systemChromeMaterial)
        XCTAssertFalse(factoryA === factoryB)
        XCTAssertFalse(factoryA === sharedChrome)

        for (appearance, hasChrome) in zip(
            appearances, defaultsHaveChrome
        ) {
            if hasChrome {
                XCTAssertEqual(appearance.backgroundEffect?._descriptor,
                               .blur(style: .systemChromeMaterial))
            } else {
                XCTAssertNil(appearance.backgroundEffect)
            }

            appearance.backgroundEffect = UIBlurEffect(style: .dark)
            appearance.configureWithDefaultBackground()
            if hasChrome {
                XCTAssertEqual(appearance.backgroundEffect?._descriptor,
                               .blur(style: .systemChromeMaterial))
                XCTAssertTrue(appearance.backgroundEffect === sharedChrome)
            } else {
                XCTAssertNil(appearance.backgroundEffect)
            }

            appearance.backgroundEffect = UIBlurEffect(style: .dark)
            appearance.configureWithOpaqueBackground()
            XCTAssertNil(appearance.backgroundEffect)

            appearance.backgroundEffect = UIBlurEffect(style: .dark)
            appearance.configureWithTransparentBackground()
            XCTAssertNil(appearance.backgroundEffect)
        }
    }

    #if !os(Linux)
    @MainActor
    #endif
    func testBarAppearanceBackgroundEffectUsesMeasuredStrongIdentityStorage() {
        let sources: [UIBarAppearance] = [
            UIBarAppearance(),
            UINavigationBarAppearance(),
            UIToolbarAppearance(),
            UITabBarAppearance(),
        ]
        let hostile = CopyingBlurEffect(token: 90)
        CopyingBlurEffect.copyCallCount = 0

        for source in sources {
            source.backgroundEffect = hostile
            XCTAssertTrue(source.backgroundEffect === hostile)
        }
        XCTAssertEqual(CopyingBlurEffect.copyCallCount, 0)

        let copies: [UIBarAppearance] = [
            UIBarAppearance(barAppearance: sources[0]),
            UINavigationBarAppearance(barAppearance: sources[1]),
            UIToolbarAppearance(barAppearance: sources[2]),
            UITabBarAppearance(barAppearance: sources[3]),
        ]
        for copy in copies {
            XCTAssertTrue(copy.backgroundEffect === hostile)
        }
        XCTAssertEqual(CopyingBlurEffect.copyCallCount, 0)

        let builtIn = UIBlurEffect(style: .systemMaterial)
        sources[0].backgroundEffect = builtIn
        XCTAssertTrue(sources[0].backgroundEffect === builtIn)
        let builtInCopy = UIBarAppearance(barAppearance: sources[0])
        XCTAssertTrue(builtInCopy.backgroundEffect === builtIn)
    }
}
