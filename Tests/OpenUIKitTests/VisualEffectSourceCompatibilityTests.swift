// Deliberately not @testable: unavailable private runtime tags must not make
// a normal app's exhaustive switches handle extra OpenUIKit-only cases.
import Foundation
import OpenUIKit
import XCTest

// These free functions are deliberately outside any actor. They are a
// normal-import source gate for NSObject's nonisolated equality/hash surface,
// matching code that compiles against UIKit under strict Swift 6.
private func compareBlurOutsideMainActor(
    _ lhs: UIBlurEffect,
    _ rhs: UIBlurEffect
) -> Bool {
    lhs.isEqual(rhs) && lhs.hash == rhs.hash
}

private func compareVibrancyOutsideMainActor(
    _ lhs: UIVibrancyEffect,
    _ rhs: UIVibrancyEffect
) -> Bool {
    lhs.isEqual(rhs) && lhs.hash == rhs.hash
}

@MainActor
private final class SourceEffect: UIVisualEffect {}

@MainActor
private final class SourceBlurEffect: UIBlurEffect {}

@MainActor
private final class SourceVibrancyEffect: UIVibrancyEffect {}

#if canImport(ObjectiveC)
@objc(OpenUIKitSourceCopyingEffect)
#endif
@MainActor
private final class SourceCopyingEffect: UIVisualEffect {
    static var copyCallCount = 0
    override class var supportsSecureCoding: Bool { true }
    let token: Int

    init(token: Int) {
        self.token = token
        super.init()
    }

    required init?(coder: NSCoder) {
        token = coder.decodeInteger(forKey: "token")
        super.init(coder: coder)
    }

    override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(token, forKey: "token")
    }

    override func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        Self.copyCallCount += 1
        return SourceCopyingEffect(token: token + 1)
    }
}

#if canImport(ObjectiveC)
@objc(OpenUIKitSourceCopyingBlurEffect)
#endif
@MainActor
private final class SourceCopyingBlurEffect: UIBlurEffect {
    static var copyCallCount = 0
    override class var supportsSecureCoding: Bool { true }
    let token: Int

    init(token: Int) {
        self.token = token
        super.init(style: .dark)
    }

    required init?(coder: NSCoder) {
        token = coder.decodeInteger(forKey: "token")
        super.init(coder: coder)
    }

    override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(token, forKey: "token")
    }

    override func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        Self.copyCallCount += 1
        return SourceCopyingBlurEffect(token: token + 1)
    }
}

@MainActor
private final class SourceEffectView: UIVisualEffectView {
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

/// OpenUIKit's UIView root is not NSObject, so Darwin root archives use an
/// internal base-view snapshot. This external subclass deliberately proves
/// what that snapshot does not claim to preserve.
@MainActor
private final class SourceArchivedEffectView: UIVisualEffectView {
    static var encodeCallCount = 0
    let token: Int

    init(effect: UIVisualEffect?, token: Int) {
        self.token = token
        super.init(effect: effect)
    }

    required init?(coder: NSCoder) {
        token = coder.decodeInteger(forKey: "SourceArchivedEffectView.token")
        super.init(coder: coder)
    }

    override func encode(with coder: NSCoder) {
        Self.encodeCallCount += 1
        super.encode(with: coder)
        coder.encode(token, forKey: "SourceArchivedEffectView.token")
    }
}

private func publicBlurCase(_ style: UIBlurEffect.Style) -> Int {
    switch style {
    case .extraLight: 0
    case .light: 1
    case .dark: 2
    case .regular: 4
    case .prominent: 5
    case .systemUltraThinMaterial: 6
    case .systemThinMaterial: 7
    case .systemMaterial: 8
    case .systemThickMaterial: 9
    case .systemChromeMaterial: 10
    case .systemUltraThinMaterialLight: 11
    case .systemThinMaterialLight: 12
    case .systemMaterialLight: 13
    case .systemThickMaterialLight: 14
    case .systemChromeMaterialLight: 15
    case .systemUltraThinMaterialDark: 16
    case .systemThinMaterialDark: 17
    case .systemMaterialDark: 18
    case .systemThickMaterialDark: 19
    case .systemChromeMaterialDark: 20
    @unknown default: -1
    }
}

private func publicVibrancyCase(_ style: UIVibrancyEffectStyle) -> Int {
    switch style {
    case .label: 0
    case .secondaryLabel: 1
    case .tertiaryLabel: 2
    case .quaternaryLabel: 3
    case .fill: 4
    case .secondaryFill: 5
    case .tertiaryFill: 6
    case .separator: 7
    @unknown default: -1
    }
}

final class VisualEffectSourceCompatibilityTests: XCTestCase {
    private func requireEffectContracts<Effect: UIVisualEffect>(
        _ effect: Effect
    ) where Effect: NSObjectProtocol & NSCopying & NSSecureCoding {
        _ = effect
    }

    private func requireViewContract<View: UIVisualEffectView>(
        _ view: View
    ) where View: NSSecureCoding {
        _ = view
    }

    @MainActor
    func testExternalEnumSwitchesSeeOnlyPublicUIKitCases() throws {
        XCTAssertEqual(publicBlurCase(.systemChromeMaterialDark), 20)
        XCTAssertEqual(UIBlurEffect.Style(rawValue: 20)?.rawValue, 20)
        let hidden3 = try XCTUnwrap(UIBlurEffect.Style(rawValue: 3))
        let hidden21 = try XCTUnwrap(UIBlurEffect.Style(rawValue: 21))
        XCTAssertEqual(hidden3.rawValue, 3)
        XCTAssertEqual(hidden21.rawValue, 21)
        XCTAssertEqual(publicBlurCase(hidden3), -1)
        XCTAssertEqual(publicBlurCase(hidden21), -1)
        // Deliberate pure-Swift-enum compromise: UIKit's imported extensible
        // enum accepts these too, but doing so would destroy this exhaustive
        // 20-public-case source shape.
        XCTAssertNil(UIBlurEffect.Style(rawValue: -1))
        XCTAssertNil(UIBlurEffect.Style(rawValue: 22))
        XCTAssertNil(UIBlurEffect.Style(rawValue: 100))
        XCTAssertEqual(publicVibrancyCase(.separator), 7)
        XCTAssertEqual(UIVibrancyEffectStyle(rawValue: 7)?.rawValue, 7)
    }

    @MainActor
    func testExternalNSObjectSemanticsRemainCallableOutsideMainActor() {
        XCTAssertTrue(compareBlurOutsideMainActor(
            UIBlurEffect(style: .light),
            UIBlurEffect(style: .light)))
        XCTAssertTrue(compareVibrancyOutsideMainActor(
            UIVibrancyEffect(), UIVibrancyEffect()))
    }

    @MainActor
    func testExternalHostileCopyContractsMatchIOS26() throws {
        SourceCopyingEffect.copyCallCount = 0
        let source = SourceCopyingEffect(token: 30)
        let view = UIVisualEffectView(effect: source)
        let stored = try XCTUnwrap(view.effect as? SourceCopyingEffect)
        XCTAssertEqual(SourceCopyingEffect.copyCallCount, 1)
        XCTAssertFalse(stored === source)
        XCTAssertEqual(stored.token, 31)

        SourceCopyingEffect.copyCallCount = 0
        let assigned = SourceCopyingEffect(token: 35)
        view.effect = assigned
        let assignedStored = try XCTUnwrap(
            view.effect as? SourceCopyingEffect)
        XCTAssertEqual(SourceCopyingEffect.copyCallCount, 1)
        XCTAssertFalse(assignedStored === assigned)
        XCTAssertEqual(assignedStored.token, 36)

        let hostileBlur = SourceCopyingBlurEffect(token: 40)
        SourceCopyingBlurEffect.copyCallCount = 0
        let appearances: [UIBarAppearance] = [
            UIBarAppearance(), UINavigationBarAppearance(),
            UIToolbarAppearance(), UITabBarAppearance(),
        ]
        for appearance in appearances {
            appearance.backgroundEffect = hostileBlur
            XCTAssertTrue(appearance.backgroundEffect === hostileBlur)
        }
        let copies: [UIBarAppearance] = [
            UIBarAppearance(barAppearance: appearances[0]),
            UINavigationBarAppearance(barAppearance: appearances[1]),
            UIToolbarAppearance(barAppearance: appearances[2]),
            UITabBarAppearance(barAppearance: appearances[3]),
        ]
        for copy in copies {
            XCTAssertTrue(copy.backgroundEffect === hostileBlur)
        }
        XCTAssertEqual(SourceCopyingBlurEffect.copyCallCount, 0)
    }

    @MainActor
    func testExternalDetachedAndHostedGeometryAccessOrderMatrix() {
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
                view.bounds = shiftedBounds
                let content = saved ?? view.contentView
                let expected = accessFirst || eagerlyMaterialized
                    ? zeroFill : shiftedBounds
                XCTAssertEqual(content.frame, expected,
                               "\(name), accessFirst=\(accessFirst)")
                view.layoutIfNeeded()
                XCTAssertEqual(content.frame, expected)
                XCTAssertTrue(view.contentView === content)
            }
        }

        let nilOrigin = UIVisualEffectView(frame: initialFrame)
        let nilOriginContent = nilOrigin.contentView
        nilOrigin.bounds.origin = shiftedBounds.origin
        nilOrigin.layoutIfNeeded()
        XCTAssertEqual(nilOriginContent.frame,
                       CGRect(x: 0, y: 0, width: 120, height: 80))

        let lateBlur = UIVisualEffectView(frame: initialFrame)
        let lateBlurContent = lateBlur.contentView
        lateBlur.effect = UIBlurEffect(style: .regular)
        lateBlur.bounds = shiftedBounds
        lateBlur.layoutIfNeeded()
        XCTAssertEqual(lateBlurContent.frame, zeroFill)

        let toggle = UIVisualEffectView(
            effect: UIBlurEffect(style: .regular))
        toggle.frame = initialFrame
        let toggleContent = toggle.contentView
        toggle.bounds.origin = shiftedBounds.origin
        toggle.layoutIfNeeded()
        toggle.effect = nil
        XCTAssertEqual(toggleContent.frame,
                       CGRect(x: 7, y: 9, width: 120, height: 80))

        let window = UIWindow(
            frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let hostedEffectFirst = UIVisualEffectView(
            effect: UIBlurEffect(style: .regular))
        window.addSubview(hostedEffectFirst)
        hostedEffectFirst.frame = initialFrame
        hostedEffectFirst.bounds.origin = shiftedBounds.origin

        let hostedFrameFirst = UIVisualEffectView(frame: initialFrame)
        window.addSubview(hostedFrameFirst)
        hostedFrameFirst.effect = UIBlurEffect(style: .regular)
        hostedFrameFirst.bounds.origin = shiftedBounds.origin
        for view in [hostedEffectFirst, hostedFrameFirst] {
            XCTAssertEqual(view.contentView.frame,
                           CGRect(x: 7, y: 9, width: 120, height: 80))
        }
        window.layoutIfNeeded()
        hostedEffectFirst.layoutIfNeeded()
        hostedFrameFirst.layoutIfNeeded()

        for view in [hostedEffectFirst, hostedFrameFirst] {
            XCTAssertEqual(view.contentView.frame,
                           CGRect(x: 7, y: 9, width: 120, height: 80))
            view.bounds.size = shiftedBounds.size
            view.layoutIfNeeded()
            XCTAssertEqual(view.contentView.frame, shiftedBounds)
            XCTAssertEqual(view.contentView.bounds,
                           CGRect(x: 0, y: 0, width: 200, height: 110))
            XCTAssertTrue(view.subviews.last === view.contentView)
        }
    }

    @MainActor
    func testExternalInitializersInheritanceAndOpenSurfaceCompile() {
        let base = UIVisualEffect()
        let sourceBase = SourceEffect()
        let blur = UIBlurEffect(style: .regular)
        let sourceBlurDefault = SourceBlurEffect()
        let sourceBlurStyled = SourceBlurEffect(style: .systemMaterial)
        let vibrancy = UIVibrancyEffect(blurEffect: blur)
        let styledVibrancy = UIVibrancyEffect(
            blurEffect: blur, style: .label)
        let sourceVibrancyDefault = SourceVibrancyEffect()
        let sourceVibrancy = SourceVibrancyEffect(blurEffect: blur)
        let sourceStyledVibrancy = SourceVibrancyEffect(
            blurEffect: blur, style: .secondaryLabel)
        let view = UIVisualEffectView()
        let frameView = UIVisualEffectView(frame: .zero)
        let effectView = UIVisualEffectView(effect: blur)
        let sourceView = SourceEffectView(effect: blur)
        let inheritedFrameView = SourceEffectView(frame: .zero)
        let inheritedZeroView = SourceEffectView()
        let appearance = UIBarAppearance()
        appearance.backgroundEffect = blur

        requireEffectContracts(base)
        requireEffectContracts(sourceBase)
        requireEffectContracts(blur)
        requireEffectContracts(sourceBlurDefault)
        requireEffectContracts(sourceBlurStyled)
        requireEffectContracts(vibrancy)
        requireEffectContracts(styledVibrancy)
        requireEffectContracts(sourceVibrancyDefault)
        requireEffectContracts(sourceVibrancy)
        requireEffectContracts(sourceStyledVibrancy)
        requireViewContract(view)
        requireViewContract(frameView)
        requireViewContract(effectView)
        requireViewContract(sourceView)
        requireViewContract(inheritedFrameView)
        requireViewContract(inheritedZeroView)
        XCTAssertTrue(sourceView.effect === blur)
        XCTAssertTrue(sourceView.contentView === sourceView.contentView)
        let typedBackgroundEffect: UIBlurEffect? = appearance.backgroundEffect
        XCTAssertTrue(typedBackgroundEffect === blur)
    }

#if canImport(Foundation) && canImport(ObjectiveC)
    @MainActor
    func testExternalViewArchiveIsExplicitlyABaseSnapshot() throws {
        SourceArchivedEffectView.encodeCallCount = 0
        let source = SourceArchivedEffectView(
            effect: UIBlurEffect(style: .dark), token: 73)
        source.frame = CGRect(x: 4, y: 5, width: 90, height: 40)
        source.bounds.origin = CGPoint(x: 7, y: 9)
        source.alpha = 0.25
        source.tag = 81
        source.isHidden = true
        source.backgroundColor = .systemRed
        source.contentView.addSubview(UIView(
            frame: CGRect(x: 1, y: 2, width: 3, height: 4)))

        let data = try NSKeyedArchiver.archivedData(
            withRootObject: source, requiringSecureCoding: true)
        let unarchiver = try NSKeyedUnarchiver(forReadingFrom: data)
        unarchiver.requiresSecureCoding = false
        let decoded = try XCTUnwrap(unarchiver.decodeObject(
            forKey: NSKeyedArchiveRootObjectKey) as? UIVisualEffectView)
        unarchiver.finishDecoding()

        XCTAssertEqual(SourceArchivedEffectView.encodeCallCount, 0)
        XCTAssertTrue(type(of: decoded) == UIVisualEffectView.self)
        XCTAssertEqual(decoded.frame,
                       CGRect(x: 4, y: 5, width: 90, height: 40))
        XCTAssertEqual(decoded.bounds,
                       CGRect(x: 7, y: 9, width: 90, height: 40))
        XCTAssertTrue(decoded.effect is UIBlurEffect)

        // Subclass payload, content children, and unrelated inherited UIView
        // state are intentionally outside the portable snapshot contract.
        XCTAssertTrue(decoded.contentView.subviews.isEmpty)
        XCTAssertEqual(decoded.alpha, 1)
        XCTAssertEqual(decoded.tag, 0)
        XCTAssertFalse(decoded.isHidden)
        XCTAssertNil(decoded.backgroundColor)

        // The view still sends exactly one hostile-effect copy while
        // decoding. OpenUIKit deliberately preserves the custom secure-coder
        // payload before that copy; KNOWN_GAPS records UIKit's divergent
        // zero-argument reconstruction behavior.
        SourceCopyingEffect.copyCallCount = 0
        let hostileSource = UIVisualEffectView(
            effect: SourceCopyingEffect(token: 90))
        XCTAssertEqual(SourceCopyingEffect.copyCallCount, 1)
        hostileSource.frame = CGRect(x: 4, y: 5, width: 90, height: 40)
        hostileSource.bounds.origin = CGPoint(x: 7, y: 9)
        SourceCopyingEffect.copyCallCount = 0
        let hostileData = try NSKeyedArchiver.archivedData(
            withRootObject: hostileSource, requiringSecureCoding: true)
        XCTAssertEqual(SourceCopyingEffect.copyCallCount, 0)
        SourceCopyingEffect.copyCallCount = 0
        let hostileDecoder = try NSKeyedUnarchiver(
            forReadingFrom: hostileData)
        hostileDecoder.requiresSecureCoding = false
        let hostileDecoded = try XCTUnwrap(hostileDecoder.decodeObject(
            forKey: NSKeyedArchiveRootObjectKey) as? UIVisualEffectView)
        hostileDecoder.finishDecoding()
        let decodedEffect = try XCTUnwrap(
            hostileDecoded.effect as? SourceCopyingEffect)
        XCTAssertEqual(SourceCopyingEffect.copyCallCount, 1)
        XCTAssertEqual(decodedEffect.token, 92)
        XCTAssertEqual(hostileDecoded.contentView.frame,
                       CGRect(x: 7, y: 9, width: 90, height: 40))
    }
#endif
}
