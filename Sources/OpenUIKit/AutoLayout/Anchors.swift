// Layout anchors. Owner: autolayout module (M9).
//
// UIKit-compatible anchor API: view.topAnchor.constraint(equalTo:constant:)
// etc. Anchors are lightweight (view, attribute) references; the constraints
// they create are ordinary NSLayoutConstraints.

// M15: a DEFAULT ARGUMENT or an `@inlinable` body may only use members whose
// defining module THIS FILE imports -- `CGRect.zero` and `CGFloat.pi` do not
// ride in on OpenCoreGraphics' typealias the way ordinary uses do. These are
// SCOPED imports on purpose: they satisfy that rule without pulling in
// CoreGraphics' CGColor / CGAffineTransform, which would collide with
// OpenCoreGraphics' own.
#if canImport(CoreGraphics)
import struct CoreFoundation.CGFloat
import struct CoreGraphics.CGPoint
import struct CoreGraphics.CGRect
import struct CoreGraphics.CGSize
#elseif canImport(Foundation)
import Foundation
#endif


public class NSLayoutAnchor {
    /// The anchored object: a `UIView` or a ``UILayoutGuide``. UIKit types
    /// this as `Any` on `NSLayoutConstraint`; both kinds get the same four
    /// solver variables (AutoLayout/UILayoutGuide.swift).
    let item: AnyObject
    let attribute: NSLayoutConstraint.Attribute
    init(view: UIView, attribute: NSLayoutConstraint.Attribute) {
        self.item = view
        self.attribute = attribute
    }
    init(guide: UILayoutGuide, attribute: NSLayoutConstraint.Attribute) {
        self.item = guide
        self.attribute = attribute
    }

    func make(_ relation: NSLayoutConstraint.Relation, _ other: NSLayoutAnchor,
              multiplier: CGFloat = 1, constant: CGFloat = 0) -> NSLayoutConstraint {
        NSLayoutConstraint(item: item, attribute: attribute, relatedBy: relation,
                           toItem: other.item, attribute: other.attribute,
                           multiplier: multiplier, constant: constant)
    }
}

/// Horizontal-position anchors (left/right/leading/trailing/centerX).
public final class NSLayoutXAxisAnchor: NSLayoutAnchor {
    public func constraint(equalTo anchor: NSLayoutXAxisAnchor,
                           constant: CGFloat = 0) -> NSLayoutConstraint {
        make(.equal, anchor, constant: constant)
    }
    public func constraint(greaterThanOrEqualTo anchor: NSLayoutXAxisAnchor,
                           constant: CGFloat = 0) -> NSLayoutConstraint {
        make(.greaterThanOrEqual, anchor, constant: constant)
    }
    public func constraint(lessThanOrEqualTo anchor: NSLayoutXAxisAnchor,
                           constant: CGFloat = 0) -> NSLayoutConstraint {
        make(.lessThanOrEqual, anchor, constant: constant)
    }
}

/// Vertical-position anchors (top/bottom/centerY/baselines).
public final class NSLayoutYAxisAnchor: NSLayoutAnchor {
    public func constraint(equalTo anchor: NSLayoutYAxisAnchor,
                           constant: CGFloat = 0) -> NSLayoutConstraint {
        make(.equal, anchor, constant: constant)
    }
    public func constraint(greaterThanOrEqualTo anchor: NSLayoutYAxisAnchor,
                           constant: CGFloat = 0) -> NSLayoutConstraint {
        make(.greaterThanOrEqual, anchor, constant: constant)
    }
    public func constraint(lessThanOrEqualTo anchor: NSLayoutYAxisAnchor,
                           constant: CGFloat = 0) -> NSLayoutConstraint {
        make(.lessThanOrEqual, anchor, constant: constant)
    }
}

/// Size anchors (width/height): dimension-to-dimension with multiplier, or
/// constant-only.
public final class NSLayoutDimension: NSLayoutAnchor {
    public func constraint(equalTo anchor: NSLayoutDimension, multiplier: CGFloat = 1,
                           constant: CGFloat = 0) -> NSLayoutConstraint {
        make(.equal, anchor, multiplier: multiplier, constant: constant)
    }
    public func constraint(greaterThanOrEqualTo anchor: NSLayoutDimension,
                           multiplier: CGFloat = 1,
                           constant: CGFloat = 0) -> NSLayoutConstraint {
        make(.greaterThanOrEqual, anchor, multiplier: multiplier, constant: constant)
    }
    public func constraint(lessThanOrEqualTo anchor: NSLayoutDimension,
                           multiplier: CGFloat = 1,
                           constant: CGFloat = 0) -> NSLayoutConstraint {
        make(.lessThanOrEqual, anchor, multiplier: multiplier, constant: constant)
    }
    public func constraint(equalToConstant c: CGFloat) -> NSLayoutConstraint {
        NSLayoutConstraint(item: item, attribute: attribute, relatedBy: .equal,
                           toItem: nil, attribute: .notAnAttribute, constant: c)
    }
    public func constraint(greaterThanOrEqualToConstant c: CGFloat) -> NSLayoutConstraint {
        NSLayoutConstraint(item: item, attribute: attribute, relatedBy: .greaterThanOrEqual,
                           toItem: nil, attribute: .notAnAttribute, constant: c)
    }
    public func constraint(lessThanOrEqualToConstant c: CGFloat) -> NSLayoutConstraint {
        NSLayoutConstraint(item: item, attribute: attribute, relatedBy: .lessThanOrEqual,
                           toItem: nil, attribute: .notAnAttribute, constant: c)
    }
}

extension UIView {
    public var leadingAnchor: NSLayoutXAxisAnchor { .init(view: self, attribute: .leading) }
    public var trailingAnchor: NSLayoutXAxisAnchor { .init(view: self, attribute: .trailing) }
    public var leftAnchor: NSLayoutXAxisAnchor { .init(view: self, attribute: .left) }
    public var rightAnchor: NSLayoutXAxisAnchor { .init(view: self, attribute: .right) }
    public var topAnchor: NSLayoutYAxisAnchor { .init(view: self, attribute: .top) }
    public var bottomAnchor: NSLayoutYAxisAnchor { .init(view: self, attribute: .bottom) }
    public var widthAnchor: NSLayoutDimension { .init(view: self, attribute: .width) }
    public var heightAnchor: NSLayoutDimension { .init(view: self, attribute: .height) }
    public var centerXAnchor: NSLayoutXAxisAnchor { .init(view: self, attribute: .centerX) }
    public var centerYAnchor: NSLayoutYAxisAnchor { .init(view: self, attribute: .centerY) }
    public var firstBaselineAnchor: NSLayoutYAxisAnchor {
        .init(view: self, attribute: .firstBaseline)
    }
    public var lastBaselineAnchor: NSLayoutYAxisAnchor {
        .init(view: self, attribute: .lastBaseline)
    }
}
