// UICornerConfiguration / UICornerRadius (iOS 26) and UIView.cornerConfiguration.
// Owner: view module.
//
// MEASURED (iOS 26.1, iPhone 16 @3x — Tools/oracle2/signallastrowsprobe,
// transcript ios-26.1-iphone16.json section `corners`, pixel reduction
// corners-ios-26.1-iphone16.json from the render-server screenshots):
//
//   * Setting `cornerConfiguration` leaves `layer.cornerRadius` at 0 and
//     `layer.maskedCorners` at all four; the radii land in a private
//     Core Animation per-corner property (`cornerRadii`, 64 bytes). A
//     `layer.cornerRadius` written afterwards reads back (2, 30) but the
//     pixels stay the configuration's (max channel diff 0 against the
//     untouched twin) — the per-corner radii win.
//   * Pixels: every configured view is identical (max diff ≤ 1/255) to a
//     twin drawn with `layer.cornerRadius = r` and `cornerCurve =
//     .continuous`, and differs from the `.circular` twin by up to 97/255
//     over ~400 px at r = 8. A fresh `UIView().layer.cornerCurve` already
//     reads `.continuous` on iOS 26.1.
//   * Resolution, per corner, from the view's own bounds (w × h):
//       .fixed(r)            → min(r, min(w, h) / 2)   (40 on 100×40 → 20)
//       .capsule()           → min(w, h) / 2           (100×40 → 20, 60×100 → 30,
//                                                        re-derived on resize:
//                                                        200×60 → 30)
//       .capsule(maximumRadius: m) → the configuration itself describes
//                              as `.fixed(radius: m)` (measured description),
//                              so 10 on 100×40 → 10
//       unspecified (nil)    → 0 (square corner)
//       .containerConcentric(minimum: m) → container corner radius − inset
//                              (container 20, inset 4 → 16; ≥ m). The
//                              container is the nearest ancestor with a
//                              resolved corner radius.
//     Per-corner radii render independently (tl 10 / tr 0 / bl 20 / br 30
//     measured 10.1 / 1.0 / 20.2 / 30.2; top 16 / bottom 4; top 16 /
//     bottom unspecified → 0).
//   * `description` formats as
//     `UICornerConfiguration(topLeftRadius: .fixed(radius: 8.0), …)` with
//     `.unspecified`, `.capsule`, `.containerConcentric(minimumRadius: 8.0)`.
//
// The port maps the resolved per-corner radii onto its existing layer
// corner drawing (`UIRenderer.layerRoundedRect`), which draws CIRCULAR
// arcs; the continuous-curve delta above is a known gap of that drawing,
// not of this mapping. Signal-iOS demand (1 use, VideoTimelineView):
// `.uniformCorners(radius: .fixed(8))` on a view and on a subview.

#if canImport(CoreGraphics)
import struct CoreFoundation.CGFloat
import struct CoreGraphics.CGRect
#elseif canImport(Foundation)
import Foundation
#endif

public struct UICornerRadius: Equatable, Hashable, ExpressibleByFloatLiteral,
                              ExpressibleByIntegerLiteral, CustomStringConvertible {
    enum Kind: Equatable, Hashable {
        case unspecified
        case fixed(Double)
        case capsule
        case containerConcentric(minimum: CGFloat?)
    }
    let kind: Kind

    public static func fixed(_ radius: Double) -> UICornerRadius {
        UICornerRadius(kind: .fixed(radius))
    }
    public static func containerConcentric(minimum: CGFloat? = nil) -> UICornerRadius {
        UICornerRadius(kind: .containerConcentric(minimum: minimum))
    }
    static let unspecified = UICornerRadius(kind: .unspecified)
    static let capsule = UICornerRadius(kind: .capsule)

    public init(floatLiteral value: Double) { kind = .fixed(value) }
    public init(integerLiteral value: Int) { kind = .fixed(Double(value)) }
    init(kind: Kind) { self.kind = kind }

    public var description: String {
        switch kind {
        case .unspecified: return ".unspecified"
        case .capsule: return ".capsule"
        case .fixed(let r): return ".fixed(radius: \(r))"
        case .containerConcentric(let m):
            return ".containerConcentric(minimumRadius: \(m.map { "\(Double($0))" } ?? "nil"))"
        }
    }

    /// The radius for one corner of a `size` view. `container` is the
    /// resolved radius of the nearest configured ancestor's matching corner
    /// and the inset from it (nil when there is none).
    func resolve(in size: CGSize, container: (radius: CGFloat, inset: CGFloat)?) -> CGFloat {
        let half = Swift.max(0, Swift.min(size.width, size.height) / 2)
        switch kind {
        case .unspecified: return 0
        case .capsule: return half
        case .fixed(let r): return Swift.max(0, Swift.min(CGFloat(r), half))
        case .containerConcentric(let minimum):
            let base: CGFloat = container.map { Swift.max(0, $0.radius - $0.inset) } ?? 0
            let floor: CGFloat = minimum ?? 0
            return Swift.min(Swift.max(base, floor), half)
        }
    }
}

public struct UICornerConfiguration: Equatable, Hashable, CustomStringConvertible {
    public var topLeftRadius: UICornerRadius?
    public var topRightRadius: UICornerRadius?
    public var bottomLeftRadius: UICornerRadius?
    public var bottomRightRadius: UICornerRadius?

    init(topLeft: UICornerRadius?, topRight: UICornerRadius?,
         bottomLeft: UICornerRadius?, bottomRight: UICornerRadius?) {
        topLeftRadius = topLeft
        topRightRadius = topRight
        bottomLeftRadius = bottomLeft
        bottomRightRadius = bottomRight
    }

    /// A fresh view's configuration: four unspecified corners.
    static let unspecified = UICornerConfiguration(topLeft: nil, topRight: nil,
                                                   bottomLeft: nil, bottomRight: nil)

    public static func corners(radius: UICornerRadius) -> UICornerConfiguration {
        UICornerConfiguration(topLeft: radius, topRight: radius,
                              bottomLeft: radius, bottomRight: radius)
    }
    public static func corners(topLeftRadius: UICornerRadius?, topRightRadius: UICornerRadius?,
                               bottomLeftRadius: UICornerRadius?, bottomRightRadius: UICornerRadius?)
        -> UICornerConfiguration {
        UICornerConfiguration(topLeft: topLeftRadius, topRight: topRightRadius,
                              bottomLeft: bottomLeftRadius, bottomRight: bottomRightRadius)
    }
    /// `.capsule()` describes as four `.capsule` corners; with a maximum the
    /// configuration is literally `.fixed(maximumRadius)` (measured
    /// description), which the fixed clamp then caps at min(w, h) / 2.
    public static func capsule(maximumRadius: Double? = nil) -> UICornerConfiguration {
        if let m = maximumRadius { return corners(radius: .fixed(m)) }
        return corners(radius: .capsule)
    }
    public static func uniformCorners(radius: UICornerRadius) -> UICornerConfiguration {
        corners(radius: radius)
    }
    public static func uniformEdges(topRadius: UICornerRadius, bottomRadius: UICornerRadius)
        -> UICornerConfiguration {
        UICornerConfiguration(topLeft: topRadius, topRight: topRadius,
                              bottomLeft: bottomRadius, bottomRight: bottomRadius)
    }
    public static func uniformEdges(leftRadius: UICornerRadius, rightRadius: UICornerRadius)
        -> UICornerConfiguration {
        UICornerConfiguration(topLeft: leftRadius, topRight: rightRadius,
                              bottomLeft: leftRadius, bottomRight: rightRadius)
    }
    public static func uniformTopRadius(_ topRadius: UICornerRadius,
                                        bottomLeftRadius: UICornerRadius? = nil,
                                        bottomRightRadius: UICornerRadius? = nil)
        -> UICornerConfiguration {
        UICornerConfiguration(topLeft: topRadius, topRight: topRadius,
                              bottomLeft: bottomLeftRadius, bottomRight: bottomRightRadius)
    }
    public static func uniformBottomRadius(_ bottomRadius: UICornerRadius,
                                           topLeftRadius: UICornerRadius? = nil,
                                           topRightRadius: UICornerRadius? = nil)
        -> UICornerConfiguration {
        UICornerConfiguration(topLeft: topLeftRadius, topRight: topRightRadius,
                              bottomLeft: bottomRadius, bottomRight: bottomRadius)
    }
    public static func uniformLeftRadius(_ leftRadius: UICornerRadius,
                                         topRightRadius: UICornerRadius? = nil,
                                         bottomRightRadius: UICornerRadius? = nil)
        -> UICornerConfiguration {
        UICornerConfiguration(topLeft: leftRadius, topRight: topRightRadius,
                              bottomLeft: leftRadius, bottomRight: bottomRightRadius)
    }
    public static func uniformRightRadius(_ rightRadius: UICornerRadius,
                                          topLeftRadius: UICornerRadius? = nil,
                                          bottomLeftRadius: UICornerRadius? = nil)
        -> UICornerConfiguration {
        UICornerConfiguration(topLeft: topLeftRadius, topRight: rightRadius,
                              bottomLeft: bottomLeftRadius, bottomRight: rightRadius)
    }

    public var description: String {
        func d(_ r: UICornerRadius?) -> String { r?.description ?? ".unspecified" }
        return "UICornerConfiguration(topLeftRadius: \(d(topLeftRadius)), "
            + "topRightRadius: \(d(topRightRadius)), "
            + "bottomLeftRadius: \(d(bottomLeftRadius)), "
            + "bottomRightRadius: \(d(bottomRightRadius)))"
    }

    /// True when no corner is specified — the layer then follows its own
    /// `cornerRadius` exactly as before.
    var isUnspecified: Bool {
        topLeftRadius == nil && topRightRadius == nil
            && bottomLeftRadius == nil && bottomRightRadius == nil
    }

    /// Resolve the four radii for a `size` view. `container` supplies the
    /// nearest configured ancestor's resolved radii and the view's insets
    /// from that ancestor's corners (for `.containerConcentric`).
    func resolve(in size: CGSize,
                 container: (radii: _CACornerRadii, insets: UIEdgeInsets)?) -> _CACornerRadii {
        func one(_ r: UICornerRadius?, _ containerRadius: CGFloat, _ dx: CGFloat, _ dy: CGFloat) -> CGFloat {
            (r ?? .unspecified).resolve(
                in: size,
                container: container == nil ? nil
                    : (containerRadius, Swift.min(dx, dy)))
        }
        let c = container?.radii ?? _CACornerRadii()
        let i = container?.insets ?? .zero
        return _CACornerRadii(
            topLeft: one(topLeftRadius, c.topLeft, i.left, i.top),
            topRight: one(topRightRadius, c.topRight, i.right, i.top),
            bottomLeft: one(bottomLeftRadius, c.bottomLeft, i.left, i.bottom),
            bottomRight: one(bottomRightRadius, c.bottomRight, i.right, i.bottom))
    }
}

/// Per-corner layer radii in the view's coordinate space (y down: topLeft
/// is minX/minY). Installed by `UIView.cornerConfiguration`; a layer with
/// radii set ignores its `cornerRadius` (measured).
struct _CACornerRadii: Equatable, Hashable {
    var topLeft: CGFloat = 0
    var topRight: CGFloat = 0
    var bottomLeft: CGFloat = 0
    var bottomRight: CGFloat = 0

    var isUniform: Bool {
        topLeft == topRight && topLeft == bottomLeft && topLeft == bottomRight
    }
    var maxRadius: CGFloat {
        Swift.max(topLeft, topRight, bottomLeft, bottomRight)
    }
    /// Radii with the corners outside `mask` squared off.
    func masked(_ mask: CACornerMask) -> _CACornerRadii {
        _CACornerRadii(
            topLeft: mask.contains(.layerMinXMinYCorner) ? topLeft : 0,
            topRight: mask.contains(.layerMaxXMinYCorner) ? topRight : 0,
            bottomLeft: mask.contains(.layerMinXMaxYCorner) ? bottomLeft : 0,
            bottomRight: mask.contains(.layerMaxXMaxYCorner) ? bottomRight : 0)
    }
    /// Every radius shrunk by `inset` (a border ring's inner outline).
    func inset(by inset: CGFloat) -> _CACornerRadii {
        _CACornerRadii(topLeft: Swift.max(0, topLeft - inset),
                       topRight: Swift.max(0, topRight - inset),
                       bottomLeft: Swift.max(0, bottomLeft - inset),
                       bottomRight: Swift.max(0, bottomRight - inset))
    }
}

extension UIView {
    /// iOS 26's per-corner configuration. Resolved against the view's
    /// bounds now and again whenever the bounds change (a capsule follows
    /// a resize, measured). `.unspecified` corners are square, not
    /// "inherit `layer.cornerRadius`".
    public var cornerConfiguration: UICornerConfiguration {
        get { _cornerConfiguration }
        set {
            _cornerConfiguration = newValue
            _resolveCornerConfiguration()
        }
    }

    func _resolveCornerConfiguration() {
        let configuration = _cornerConfiguration
        if configuration.isUnspecified {
            if layer._cornerRadii != nil {
                layer._cornerRadii = nil
                setNeedsDisplay()
            }
            _propagateCornerConfigurationToSubviews()
            return
        }
        let radii = configuration.resolve(in: bounds.size, container: _cornerContainer())
        if layer._cornerRadii != radii {
            layer._cornerRadii = radii
            setNeedsDisplay()
        }
        _propagateCornerConfigurationToSubviews()
    }

    /// A subview's `.containerConcentric` re-resolves when its container
    /// does; only configured subviews are visited.
    private func _propagateCornerConfigurationToSubviews() {
        for s in subviews where !s._cornerConfiguration.isUnspecified {
            s._resolveCornerConfiguration()
        }
    }

    /// Nearest ancestor with resolved per-corner radii (or a plain
    /// `cornerRadius`), with this view's insets from its corners.
    private func _cornerContainer() -> (radii: _CACornerRadii, insets: UIEdgeInsets)? {
        var ancestor = superview
        while let a = ancestor {
            let radii: _CACornerRadii
            if let r = a.layer._cornerRadii {
                radii = r
            } else if a.layer.cornerRadius > 0 {
                let r = a.layer.cornerRadius
                radii = _CACornerRadii(topLeft: r, topRight: r, bottomLeft: r, bottomRight: r)
            } else {
                ancestor = a.superview
                continue
            }
            let f = convert(bounds, to: a)
            let b = a.bounds
            return (radii, UIEdgeInsets(top: f.minY - b.minY, left: f.minX - b.minX,
                                        bottom: b.maxY - f.maxY, right: b.maxX - f.maxX))
        }
        return nil
    }
}
