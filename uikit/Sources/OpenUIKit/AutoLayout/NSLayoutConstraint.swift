// NSLayoutConstraint + UILayoutPriority. Owner: autolayout module (M9).
//
// UIKit-compatible constraint objects. Activation installs the constraint on
// the nearest common ancestor of the two items (UIKit semantics); the
// LayoutEngine gathers installed constraints and solves them with the
// Cassowary solver during layoutIfNeeded.

// M15: a DEFAULT ARGUMENT or an `@inlinable` body may only use members whose
// defining module THIS FILE imports -- `CGRect.zero` and `CGFloat.pi` do not
// ride in on OpenCoreGraphics' typealias the way ordinary uses do. These are
// SCOPED imports on purpose: they satisfy that rule without pulling in
// CoreGraphics' CGColor / CGAffineTransform, which would collide with
// OpenCoreGraphics' own. One knock-on, measured: in a file where the name is
// visible twice, `[CGFloat](repeating:count:)` array sugar stops parsing as a
// type; spell it `Array<CGFloat>(...)`.
#if canImport(CoreGraphics)
import struct CoreFoundation.CGFloat
import struct CoreGraphics.CGPoint
import struct CoreGraphics.CGRect
import struct CoreGraphics.CGSize
#elseif canImport(Foundation)
import Foundation
#endif
// UIKit's NSLayoutConstraint is an NSObject (NSLayoutConstraint.h). SnapKit
// 5.7.0 e74fe2a LayoutConstraint subclasses it and Debugging.swift overrides
// `description` from an extension through NSObject/@objc dispatch (full/focus-ios
// snapkit-exclusions.json). MEASURED /tmp/snapkit-ouik swift build --target
// SnapKit against OpenUIKit UIKit: 0 errors in 36 DSL files; the only miss was
// `non-'@objc' property 'description' declared in 'NSLayoutConstraint' cannot
// be overridden from extension`. Inheriting NSObject is the iOS 26.1 identity,
// not a comparison-score parameter.
#if canImport(Foundation)
import class Foundation.NSObject
#elseif canImport(ObjectiveC)
import class ObjectiveC.NSObject
#endif


public struct UILayoutPriority: RawRepresentable, Hashable, Comparable, Sendable {
    public var rawValue: Float
    public init(rawValue: Float) { self.rawValue = rawValue }
    public init(_ rawValue: Float) { self.rawValue = rawValue }
    public static let required = UILayoutPriority(rawValue: 1000)
    public static let defaultHigh = UILayoutPriority(rawValue: 750)
    public static let defaultLow = UILayoutPriority(rawValue: 250)
    public static let fittingSizeLevel = UILayoutPriority(rawValue: 50)
    public static func < (a: UILayoutPriority, b: UILayoutPriority) -> Bool {
        a.rawValue < b.rawValue
    }
}

// `open`, not `final`: real UIKit's NSLayoutConstraint is an ordinary
// Objective-C class and libraries subclass it. SnapKit's `LayoutConstraint:
// NSLayoutConstraint` is the case that measured this — with the class final
// the subclass fails to declare, loses the @MainActor it would have
// inherited, and every member access inside it then reports as an isolation
// violation, so ONE keyword produced 74 unrelated-looking errors.
@preconcurrency @MainActor
open class NSLayoutConstraint: NSObject {
    /// Raw values are Darwin's `NSLayoutAttribute` (NSLayoutConstraint.h):
    /// left = 1 through centerYWithinMargins = 20, notAnAttribute = 0.
    /// `baseline` is `NS_SWIFT_UNAVAILABLE` on iOS, so it is not spelled here.
    public enum Attribute: Int, Sendable {
        case left = 1, right = 2, top = 3, bottom = 4, leading = 5, trailing = 6
        case width = 7, height = 8, centerX = 9, centerY = 10
        case lastBaseline = 11, firstBaseline = 12
        /// The margin attributes address the item's own `layoutMarginsGuide`
        /// edges — `leftMargin` is `left` inset by `layoutMargins.left`, and
        /// `centerXWithinMargins` is the centre of what remains between the
        /// horizontal margins. iOS 8.0; absent from AppKit, which is why the
        /// header guards them with `TARGET_OS_IPHONE`.
        case leftMargin = 13, rightMargin = 14, topMargin = 15, bottomMargin = 16
        case leadingMargin = 17, trailingMargin = 18
        case centerXWithinMargins = 19, centerYWithinMargins = 20
        case notAnAttribute = 0
    }

    /// Raw values are Darwin's `NSLayoutRelation`.
    public enum Relation: Int, Sendable {
        case lessThanOrEqual = -1, equal = 0, greaterThanOrEqual = 1
    }

    /// Layout axis (also used by UIStackView.axis and the content-hugging /
    /// compression-resistance APIs). Previously declared as a stand-alone
    /// namespace enum in UIStackView.swift; moved here with M9.
    public enum Axis: Int, Sendable {
        case horizontal = 0, vertical = 1
    }

    /// The constrained object: a `UIView` or a ``UILayoutGuide`` (UIKit types
    /// it `AnyObject?` for the same reason). Weak, like UIKit's.
    public private(set) weak var firstItem: AnyObject?
    public let firstAttribute: Attribute
    public let relation: Relation
    public private(set) weak var secondItem: AnyObject?
    public let secondAttribute: Attribute
    public let multiplier: CGFloat
    public var constant: CGFloat {
        didSet { if constant != oldValue { _holder?.setNeedsLayout() } }
    }
    /// UIKit: must be set before activation; changing between required and
    /// optional while active is a programmer error there. We simply honor the
    /// current value at each solve.
    public var priority: UILayoutPriority = .required

    /// A debugging name, printed in `description` (UIKit's `NSIdentifier`
    /// category). Identifiers starting with NS or UI are reserved there.
    public var identifier: String?

    /// The view whose `constraints` array holds this constraint while active
    /// (nearest common ancestor of the items).
    weak var _holder: UIView?

    public init(item view1: AnyObject, attribute attr1: Attribute, relatedBy: Relation,
                toItem view2: AnyObject?, attribute attr2: Attribute,
                multiplier: CGFloat = 1, constant: CGFloat = 0) {
        self.firstItem = view1
        self.firstAttribute = attr1
        self.relation = relatedBy
        self.secondItem = view2
        self.secondAttribute = attr2
        self.multiplier = multiplier
        self.constant = constant
        super.init()
    }

    /// Focus SearchSuggestionsPromptView.swift:16 `= NSLayoutConstraint()`.
    /// The object is replaced before activation (same file:131). Required
    /// once this class inherits NSObject (focus-deps); an extension
    /// `convenience init()` is then an override of `NSObject.init()`.
    public convenience override init() {
        self.init(
            item: UIView(),
            attribute: .notAnAttribute,
            relatedBy: .equal,
            toItem: nil,
            attribute: .notAnAttribute,
            multiplier: 1,
            constant: 0
        )
    }

    public var isActive: Bool {
        get { _holder != nil }
        set { newValue ? activate() : deactivate() }
    }

    /// The view an item lives in: itself for a view, `owningView` for a
    /// layout guide. A guide with no owning view cannot be constrained.
    static func hostView(of item: AnyObject?) -> UIView? {
        if let v = item as? UIView { return v }
        if let g = item as? UILayoutGuide { return g.owningView }
        return nil
    }

    func activate() {
        guard _holder == nil, let first = NSLayoutConstraint.hostView(of: firstItem)
        else { return }
        let holder: UIView
        if secondItem != nil {
            guard let second = NSLayoutConstraint.hostView(of: secondItem),
                  let common = NSLayoutConstraint.commonAncestor(first, second) else {
                fatalError("NSLayoutConstraint: items have no common ancestor")
            }
            holder = common
        } else {
            holder = first  // unary (size) constraints live on the item
        }
        holder._installedConstraints.append(self)
        _holder = holder
        LayoutEngine.installedConstraintCount += 1
        holder.setNeedsLayout()
    }

    func deactivate() {
        guard let holder = _holder else { return }
        holder._installedConstraints.removeAll { $0 === self }
        _holder = nil
        LayoutEngine.installedConstraintCount -= 1
        holder.setNeedsLayout()
    }

    public static func activate(_ constraints: [NSLayoutConstraint]) {
        for c in constraints { c.isActive = true }
    }

    public static func deactivate(_ constraints: [NSLayoutConstraint]) {
        for c in constraints { c.isActive = false }
    }

    /// Real UIKit's constraint inherits `description` from `NSObject` and
    /// subclasses / extensions override it (SnapKit 5.7.0 Debugging.swift).
    /// The default text is not UIKit's and nothing may depend on its wording.
    open override var description: String {
        let name = identifier.map { " '\($0)'" } ?? ""
        return "<NSLayoutConstraint\(name) \(firstAttribute) \(relation) "
            + "\(secondAttribute) * \(multiplier) + \(constant)>"
    }

    static func commonAncestor(_ a: UIView, _ b: UIView) -> UIView? {
        var chain: Set<ObjectIdentifier> = []
        var v: UIView? = a
        while let cur = v {
            chain.insert(ObjectIdentifier(cur))
            v = cur.superview
        }
        v = b
        while let cur = v {
            if chain.contains(ObjectIdentifier(cur)) { return cur }
            v = cur.superview
        }
        return nil
    }
}

// No `CustomStringConvertible` conformance: the protocol is nonisolated, so
// conforming a @MainActor class to it "crosses into main actor-isolated
// code" (a warning today, an error in Swift 6 language mode) for a printing
// convenience nothing here needs. Real UIKit gets `description` from
// NSObject, which is not a Swift protocol conformance at all.

// MARK: - UIView constraint surface

extension UIView {
    /// Constraints held by this view (installed on it as the nearest common
    /// ancestor of their items).
    public var constraints: [NSLayoutConstraint] { _installedConstraints }

    public func addConstraint(_ constraint: NSLayoutConstraint) {
        constraint.isActive = true
    }

    public func addConstraints(_ constraints: [NSLayoutConstraint]) {
        NSLayoutConstraint.activate(constraints)
    }

    public func removeConstraint(_ constraint: NSLayoutConstraint) {
        constraint.isActive = false
    }

    public func removeConstraints(_ constraints: [NSLayoutConstraint]) {
        NSLayoutConstraint.deactivate(constraints)
    }

    public func contentHuggingPriority(for axis: NSLayoutConstraint.Axis) -> UILayoutPriority {
        axis == .horizontal ? _huggingH : _huggingV
    }

    public func setContentHuggingPriority(_ priority: UILayoutPriority,
                                          for axis: NSLayoutConstraint.Axis) {
        if axis == .horizontal { _huggingH = priority } else { _huggingV = priority }
        setNeedsLayout()
    }

    public func contentCompressionResistancePriority(
        for axis: NSLayoutConstraint.Axis
    ) -> UILayoutPriority {
        axis == .horizontal ? _compressionH : _compressionV
    }

    public func setContentCompressionResistancePriority(
        _ priority: UILayoutPriority, for axis: NSLayoutConstraint.Axis
    ) {
        if axis == .horizontal { _compressionH = priority } else { _compressionV = priority }
        setNeedsLayout()
    }
}

extension UIView {
    /// The constant of this view's own unary size constraint on `attribute`
    /// (`.width` / `.height`), if it has one — i.e. what
    /// `view.heightAnchor.constraint(equalToConstant:)` or
    /// `…(greaterThanOrEqualToConstant:)` asked for. Only `multiplier == 1`
    /// constraints against no second item count, which is what those
    /// spellings produce.
    ///
    /// UIKit gets this out of the solver; OpenUIKit's UIStackView is a
    /// frame-based layout that does not take part in one, so it reads the
    /// number directly (Sources/OpenUIKit/UIStackView.swift, M14).
    func _explicitSizeConstraint(_ attribute: NSLayoutConstraint.Attribute) -> CGFloat? {
        var best: CGFloat?
        for c in _installedConstraints
        where c.secondItem == nil && c.firstAttribute == attribute
            && c.firstItem === self && c.multiplier == 1
            && c.priority.rawValue >= UILayoutPriority.defaultHigh.rawValue {
            switch c.relation {
            case .equal: return c.constant
            case .greaterThanOrEqual: best = Swift.max(best ?? 0, c.constant)
            case .lessThanOrEqual: break
            }
        }
        return best
    }
}
