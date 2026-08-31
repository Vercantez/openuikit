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
// UIView inherits NSObject through UIResponder, like UIKit. NSObject supplies
// identity Equatable/Hashable behavior on both Foundation and ObjectiveC
// substrate branches, so no duplicate conformance belongs here.

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

// MARK: - Semantic content direction

/// Raw values match UIKit's `UISemanticContentAttribute`.
public enum UISemanticContentAttribute: Int, Sendable {
    case unspecified = 0
    case playback = 1
    case spatial = 2
    case forceLeftToRight = 3
    case forceRightToLeft = 4
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
    // Metatype identity is the trait's key. A third-party definition may use
    // the same human-readable `name` as a built-in without becoming that
    // built-in trait.
    let traits: [ObjectIdentifier]
    let fire: (UITraitCollection) -> Void
    init(traits: [ObjectIdentifier], fire: @escaping (UITraitCollection) -> Void) {
        self.traits = traits
        self.fire = fire
    }

    /// Whether at least one requested trait changed between the host's two
    /// environments. Unknown custom definitions are conservatively delivered:
    /// OpenUIKit's bounded collection has no value slot with which to compare
    /// them, but an explicit host event may still represent their change.
    func shouldFire(previous: UITraitCollection,
                    current: UITraitCollection) -> Bool {
        guard !traits.isEmpty else { return false }
        for trait in traits {
            if trait == ObjectIdentifier(UITraitPreferredContentSizeCategory.self) {
                if previous.preferredContentSizeCategory
                    != current.preferredContentSizeCategory { return true }
            } else if trait == ObjectIdentifier(UITraitUserInterfaceStyle.self) {
                if previous.userInterfaceStyle != current.userInterfaceStyle { return true }
            } else if trait == ObjectIdentifier(UITraitDisplayScale.self) {
                if previous.displayScale != current.displayScale { return true }
            } else if trait == ObjectIdentifier(UITraitVerticalSizeClass.self) {
                if previous.verticalSizeClass != current.verticalSizeClass { return true }
            } else if trait == ObjectIdentifier(UITraitHorizontalSizeClass.self) {
                if previous.horizontalSizeClass != current.horizontalSizeClass { return true }
            } else {
                return true
            }
        }
        return false
    }
}

extension UIView {
    @discardableResult
    public func registerForTraitChanges<Target: UIView>(
        _ traits: [any UITraitDefinition.Type],
        handler: @escaping (Target, UITraitCollection) -> Void
    ) -> UITraitChangeRegistration {
        let identifiers = traits.map(ObjectIdentifier.init)
        let reg = UITraitChangeRegistration(traits: identifiers) { [weak self] previous in
            guard let target = self as? Target else { return }
            handler(target, previous)
        }
        _traitRegistrations.append(reg)
        return reg
    }

    public func unregisterForTraitChanges(_ registration: UITraitChangeRegistration) {
        _traitRegistrations.removeAll { $0 === registration }
    }

    /// Fire matching registrations on this view and, recursively, its subviews.
    /// Hosts call this after changing `UITraitCollection.current`.
    /// `previous` must be this receiver/root's complete effective prior
    /// collection, not unresolved raw process traits, because filtering uses it.
    public func _traitsDidChange(previous: UITraitCollection) {
        let current = traitCollection
        // UIViewController's legacy callback is attached to its root view in
        // UIKit. Deliver it once at that boundary; child-controller roots are
        // reached naturally by the subtree walk below.
        if let controller = _managingViewController,
           controller.viewIfLoaded === self {
            // OpenUIKit deterministically delivers modern handlers before
            // its existing legacy callback in the same synchronous,
            // host-driven change. Controller registrations live on the
            // controller, so replacing its root view does not lose them.
            controller._deliverRegisteredTraitChanges(previous: previous,
                                                       current: current)
            controller.traitCollectionDidChange(previous)
        }
        for r in _traitRegistrations where r.shouldFire(previous: previous,
                                                        current: current) {
            r.fire(previous)
        }
        if previous != current {
            traitCollectionDidChange(previous)
        }
        for subview in subviews {
            // `previous` is effective for this view. A child's fixed local
            // style was effective before and after an inherited host change,
            // so rebuild that child's previous environment before filtering.
            var childPrevious = previous
            if subview.overrideUserInterfaceStyle != .unspecified {
                childPrevious.userInterfaceStyle = subview.overrideUserInterfaceStyle
            }
            subview._traitsDidChange(previous: childPrevious)
        }
    }
}

extension UIViewController {
    /// Bounded handler-form compatibility for iOS 17 trait observation.
    /// OpenUIKit does not yet model the full `UITraitChangeObservable`
    /// protocol, selector overloads, or `traitOverrides`; hosts explicitly
    /// drive delivery through the loaded root view's `_traitsDidChange` hook.
    @available(iOS 17.0, tvOS 17.0, *)
    @available(watchOS, unavailable)
    @discardableResult
    public func registerForTraitChanges<Target: UIViewController>(
        _ traits: [any UITraitDefinition.Type],
        handler: @escaping (Target, UITraitCollection) -> Void
    ) -> UITraitChangeRegistration {
        let identifiers = traits.map(ObjectIdentifier.init)
        let registration = UITraitChangeRegistration(traits: identifiers) { [weak self] previous in
            guard let target = self as? Target else { return }
            handler(target, previous)
        }
        _traitRegistrations.append(registration)
        return registration
    }

    @available(iOS 17.0, tvOS 17.0, *)
    @available(watchOS, unavailable)
    public func unregisterForTraitChanges(_ registration: UITraitChangeRegistration) {
        _traitRegistrations.removeAll { $0 === registration }
    }

    func _deliverRegisteredTraitChanges(previous: UITraitCollection,
                                         current: UITraitCollection) {
        for registration in _traitRegistrations
        where registration.shouldFire(previous: previous, current: current) {
            registration.fire(previous)
        }
    }
}
