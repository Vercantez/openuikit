// NSLayoutConstraint + UILayoutPriority. Owner: autolayout module (M9).
//
// UIKit-compatible constraint objects. Activation installs the constraint on
// the nearest common ancestor of the two items (UIKit semantics); the
// LayoutEngine gathers installed constraints and solves them with the
// Cassowary solver during layoutIfNeeded.

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

public final class NSLayoutConstraint {
    public enum Attribute: Sendable {
        case left, right, top, bottom, leading, trailing
        case width, height, centerX, centerY
        case lastBaseline, firstBaseline
        case notAnAttribute
    }

    public enum Relation: Sendable {
        case lessThanOrEqual, equal, greaterThanOrEqual
    }

    /// Layout axis (also used by UIStackView.axis and the content-hugging /
    /// compression-resistance APIs). Previously declared as a stand-alone
    /// namespace enum in UIStackView.swift; moved here with M9.
    public enum Axis: Sendable {
        case horizontal, vertical
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
