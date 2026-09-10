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

// The nine NSObject-level attributes moved to NSObjectAccessibility.swift,
// which is where the iOS 26.1 SDK puts them (`@interface NSObject
// (UIAccessibility)`); `AccessibilityState` moved with them. What stays here
// is `accessibilityIdentifier`, which Apple keeps OFF NSObject — it rides
// the `UIAccessibilityIdentification` protocol on UIView / UIBarItem /
// UIAlertAction / UIMenuElement (UIAccessibilityIdentification.h:19-39). The
// port declares it one level up, on UIResponder, so a view controller can
// carry one too; UIView satisfies the protocol by inheritance.
extension UIResponder {
    public var accessibilityIdentifier: String? {
        get { _accessibility.identifier }
        set { _accessibility.identifier = newValue }
    }
}

/// MEASURED iPhone 16 / iOS 26.1: raw values 0...2, a fresh view reads
/// `.automatic` (ios-oss-launch.md probe).
public enum UIAccessibilityNavigationStyle: Int, Sendable {
    case automatic = 0
    case separate = 1
    case combined = 2
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
        constraintFittingSize(targetSize,
                              withHorizontalFittingPriority: horizontal,
                              verticalFittingPriority: vertical)
            ?? estimatedFittingSize(targetSize,
                                    withHorizontalFittingPriority: horizontal,
                                    verticalFittingPriority: vertical)
    }

    /// `systemLayoutSizeFitting` for the case where this subtree really does
    /// install constraints; nil when it does not.
    ///
    /// The distinction matters to a caller deciding whether a view HAS an
    /// opinion about its own size. `systemLayoutSizeFitting` can never say
    /// "no opinion": UIView's `sizeThatFits` returns `bounds.size`, so a
    /// frame-based container answers with its current height and looks
    /// self-sizing. MEASURED 2026-09-04: treating that as an answer took the
    /// Catalyst scene `tableview_grouped` from 98.154 to 92.663, because the
    /// port's default `rowHeight` is `automaticDimension` and every ordinary
    /// cell in the corpus started "self-sizing" to whatever it already was.
    func constraintFittingSize(
        _ targetSize: CGSize,
        withHorizontalFittingPriority horizontal: UILayoutPriority,
        verticalFittingPriority vertical: UILayoutPriority) -> CGSize? {
        // Ask the engine what the constraints require at this target
        // (AutoLayout/LayoutEngine.swift, `fittingSize`) and take the LARGER
        // of that and the FRAME-BASED subviews' extent.
        //
        // Both, not either. A frame-based subview enters the solver as a fixed
        // rect and says nothing about its container, so a fitting solve is
        // free to collapse the container underneath it — the extent is the
        // floor that case needs. MEASURED 2026-09-04: taking only the solve
        // dropped the three picker goldens from 99.1/98.5/98.5 to
        // 83.8/63.1/64.0, because the sheet's detent height comes through here
        // and its content is frame-based.
        //
        // The CONSTRAINT-based subviews are deliberately not counted. Their
        // frames are an output of this same measurement, so folding them in
        // would let the container only ever grow. MEASURED: with every
        // subview counted, DisclosureCell ratcheted to 86 pt against a golden
        // 65. `sizeThatFits` is left out for the same reason — UIView's
        // returns `bounds.size`.
        guard let solved = LayoutEngine.fittingSize(
            root: self, target: targetSize,
            freeWidth: horizontal != .required,
            freeHeight: vertical != .required) else { return nil }
        layoutIfNeeded()
        var w = solved.width
        var h = solved.height
        for s in subviews
        where !s.isHidden && s.translatesAutoresizingMaskIntoConstraints {
            w = max(w, s.frame.maxX)
            h = max(h, s.frame.maxY)
        }
        let intrinsic = intrinsicContentSize
        if intrinsic.width != UIView.noIntrinsicMetric { w = max(w, intrinsic.width) }
        if intrinsic.height != UIView.noIntrinsicMetric { h = max(h, intrinsic.height) }
        return CGSize(width: horizontal == .required ? targetSize.width : w,
                      height: vertical == .required ? targetSize.height : h)
    }

    /// The pre-Auto-Layout estimate: lay the subtree out and take the union of
    /// the laid-out subviews, `sizeThatFits` and the intrinsic size. Still the
    /// answer for a frame-based hierarchy, which has nothing to solve.
    private func estimatedFittingSize(
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
public enum UITraitUserInterfaceIdiom: UITraitDefinition {
    public static var name: String { "userInterfaceIdiom" }
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
            } else if trait == ObjectIdentifier(UITraitUserInterfaceIdiom.self) {
                if previous.userInterfaceIdiom != current.userInterfaceIdiom { return true }
            } else {
                return true
            }
        }
        return false
    }
}

extension UIView {
    // `@_optimize(none)`: keeps this generic function out of cross-module
    // SIL serialization. Swift 6.2.4 for Linux aborts ("SILFunction type
    // mismatch ... _NativeClass vs AnyObject" in MandatorySILLinker) when a
    // `-default-isolation MainActor` client (RealAppProbe) deserializes its
    // body; measured 2026-09-04 in Docker (swift:6.2-noble), and the
    // annotation is what made `swift build --product openrender` link.
    @discardableResult
    @_optimize(none)
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
    // `@_optimize(none)`: keeps this generic function out of cross-module
    // SIL serialization. Swift 6.2.4 for Linux aborts ("SILFunction type
    // mismatch ... _NativeClass vs AnyObject" in MandatorySILLinker) when a
    // `-default-isolation MainActor` client (RealAppProbe) deserializes its
    // body; measured 2026-09-04 in Docker (swift:6.2-noble), and the
    // annotation is what made `swift build --product openrender` link.
    @discardableResult
    @_optimize(none)
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
