// Members of types OpenUIKit already exports that real apps expect.
// Owner: view module (M14).
//
// docs/APP_COMPAT.md calls this the under-measured gap: "we may export
// UIView while missing members a given app needs". Everything here came out
// of compiling UNMODIFIED source from a shipping app (Sources/RealAppProbe,
// docs/REAL_APP_TEST.md) — each declaration below is a line the real app
// wrote that did not compile.

// MARK: - Identity comparison
//
// Real UIKit's views are NSObjects, so `viewA != viewB` is pointer identity
// and app code writes it freely (`if previousView != label { ... }`).
// OpenUIKit's UIView is a plain class, so `!=` did not exist at all.

// `nonisolated`: both are pure IDENTITY comparisons that read no isolated
// state, and Hashable/Equatable are nonisolated protocols. Without it the
// conformance of a `@MainActor` class "crosses into main-actor-isolated
// code" -- a warning today and an error in Swift 6 language mode.
extension UIView: Equatable {
    nonisolated public static func == (lhs: UIView, rhs: UIView) -> Bool { lhs === rhs }
}

extension UIView: Hashable {
    nonisolated public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}

// MARK: - Accessibility
//
// OpenUIKit has no assistive technology to drive, and there is no oracle for
// something with no pixels. These are STORAGE ONLY: they let a real app's
// accessibility configuration compile and be read back (which is what a UI
// test asserting `accessibilityLabel` needs), and nothing in the renderer
// consults them. Stated as a divergence in docs/KNOWN_GAPS.md.

public struct UIAccessibilityTraits: OptionSet, Sendable {
    public let rawValue: UInt64
    public init(rawValue: UInt64) { self.rawValue = rawValue }
    public static let none = UIAccessibilityTraits([])
    public static let button = UIAccessibilityTraits(rawValue: 1 << 0)
    public static let link = UIAccessibilityTraits(rawValue: 1 << 1)
    public static let header = UIAccessibilityTraits(rawValue: 1 << 2)
    public static let searchField = UIAccessibilityTraits(rawValue: 1 << 3)
    public static let image = UIAccessibilityTraits(rawValue: 1 << 4)
    public static let selected = UIAccessibilityTraits(rawValue: 1 << 5)
    public static let playsSound = UIAccessibilityTraits(rawValue: 1 << 6)
    public static let keyboardKey = UIAccessibilityTraits(rawValue: 1 << 7)
    public static let staticText = UIAccessibilityTraits(rawValue: 1 << 8)
    public static let summaryElement = UIAccessibilityTraits(rawValue: 1 << 9)
    public static let notEnabled = UIAccessibilityTraits(rawValue: 1 << 10)
    public static let updatesFrequently = UIAccessibilityTraits(rawValue: 1 << 11)
    public static let startsMediaSession = UIAccessibilityTraits(rawValue: 1 << 12)
    public static let adjustable = UIAccessibilityTraits(rawValue: 1 << 13)
    public static let allowsDirectInteraction = UIAccessibilityTraits(rawValue: 1 << 14)
    public static let causesPageTurn = UIAccessibilityTraits(rawValue: 1 << 15)
    public static let tabBar = UIAccessibilityTraits(rawValue: 1 << 16)
}

extension UIResponder {
    public var isAccessibilityElement: Bool {
        get { _accessibility.isElement }
        set { _accessibility.isElement = newValue }
    }
    public var accessibilityLabel: String? {
        get { _accessibility.label }
        set { _accessibility.label = newValue }
    }
    public var accessibilityValue: String? {
        get { _accessibility.value }
        set { _accessibility.value = newValue }
    }
    public var accessibilityHint: String? {
        get { _accessibility.hint }
        set { _accessibility.hint = newValue }
    }
    public var accessibilityIdentifier: String? {
        get { _accessibility.identifier }
        set { _accessibility.identifier = newValue }
    }
    public var accessibilityTraits: UIAccessibilityTraits {
        get { _accessibility.traits }
        set { _accessibility.traits = newValue }
    }
}

struct AccessibilityState {
    var isElement = false
    var label: String?
    var value: String?
    var hint: String?
    var identifier: String?
    var traits: UIAccessibilityTraits = .none
}

// MARK: - Fitting sizes
//
// Real UIKit re-solves the constraint system with the target size installed
// at the given priority. OpenUIKit measures instead: it lays the subtree out,
// then takes the union of the laid-out subviews (plus `sizeThatFits`, which
// is what a leaf like UILabel answers with). For a view whose height is
// determined by its own subviews — the case every "how tall is this sheet"
// call site is asking about — the two agree; for one whose constraints would
// COMPRESS differently at the target width they do not. Divergence recorded
// in docs/KNOWN_GAPS.md.

extension UIView {
    public static let layoutFittingCompressedSize = CGSize(width: 0, height: 0)
    public static let layoutFittingExpandedSize = CGSize(width: 10_000, height: 10_000)

    public func systemLayoutSizeFitting(_ targetSize: CGSize) -> CGSize {
        systemLayoutSizeFitting(targetSize,
                                withHorizontalFittingPriority: .fittingSizeLevel,
                                verticalFittingPriority: .fittingSizeLevel)
    }

    public func systemLayoutSizeFitting(
        _ targetSize: CGSize,
        withHorizontalFittingPriority horizontal: UILayoutPriority,
        verticalFittingPriority vertical: UILayoutPriority) -> CGSize {
        layoutIfNeeded()
        var w: CGFloat = 0
        var h: CGFloat = 0
        for s in subviews where !s.isHidden {
            w = max(w, s.frame.maxX)
            h = max(h, s.frame.maxY)
        }
        let fits = sizeThatFits(targetSize)
        w = max(w, fits.width)
        h = max(h, fits.height)
        let intrinsic = intrinsicContentSize
        if intrinsic.width != UIView.noIntrinsicMetric { w = max(w, intrinsic.width) }
        if intrinsic.height != UIView.noIntrinsicMetric { h = max(h, intrinsic.height) }
        return CGSize(width: horizontal == .required ? targetSize.width : w,
                      height: vertical == .required ? targetSize.height : h)
    }
}

// MARK: - Trait change registration (iOS 17's replacement for
// traitCollectionDidChange)
//
// `registerForTraitChanges(_:handler:)` is how modern app code reacts to a
// Dynamic Type or appearance change. OpenUIKit stores the registrations and
// fires them when `UITraitCollection.current` is changed through
// `UIView._traitsDidChange()`; there is no system settings change to observe,
// so in practice a host drives it. The API exists so the source compiles and
// so a test can drive a trait change deliberately.

/// A trait "definition" — real UIKit passes metatypes like
/// `UITraitPreferredContentSizeCategory.self`.
public protocol UITraitDefinition {
    static var name: String { get }
}

public enum UITraitPreferredContentSizeCategory: UITraitDefinition {
    public static var name: String { "preferredContentSizeCategory" }
}
public enum UITraitUserInterfaceStyle: UITraitDefinition {
    public static var name: String { "userInterfaceStyle" }
}
public enum UITraitDisplayScale: UITraitDefinition {
    public static var name: String { "displayScale" }
}
public enum UITraitVerticalSizeClass: UITraitDefinition {
    public static var name: String { "verticalSizeClass" }
}
public enum UITraitHorizontalSizeClass: UITraitDefinition {
    public static var name: String { "horizontalSizeClass" }
}

/// The opaque token UIKit hands back so a registration can be dropped.
@preconcurrency @MainActor
public final class UITraitChangeRegistration {
    let traits: [String]
    let fire: (UITraitCollection) -> Void
    init(traits: [String], fire: @escaping (UITraitCollection) -> Void) {
        self.traits = traits
        self.fire = fire
    }
}

extension UIView {
    @discardableResult
    public func registerForTraitChanges<Target: UIView>(
        _ traits: [any UITraitDefinition.Type],
        handler: @escaping (Target, UITraitCollection) -> Void
    ) -> UITraitChangeRegistration {
        let names = traits.map { $0.name }
        let reg = UITraitChangeRegistration(traits: names) { [weak self] previous in
            guard let target = self as? Target else { return }
            handler(target, previous)
        }
        _traitRegistrations.append(reg)
        return reg
    }

    public func unregisterForTraitChanges(_ registration: UITraitChangeRegistration) {
        _traitRegistrations.removeAll { $0 === registration }
    }

    /// Fire every registration on this view and, recursively, its subviews.
    /// Hosts call this after changing `UITraitCollection.current`.
    public func _traitsDidChange(previous: UITraitCollection) {
        // UIViewController's legacy callback is attached to its root view in
        // UIKit. Deliver it once at that boundary; child-controller roots are
        // reached naturally by the subtree walk below.
        if let controller = _managingViewController,
           controller.viewIfLoaded === self {
            controller.traitCollectionDidChange(previous)
        }
        for r in _traitRegistrations { r.fire(previous) }
        for s in subviews { s._traitsDidChange(previous: previous) }
    }
}
