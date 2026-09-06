// UIGlassEffect / UIGlassContainerEffect. SDK shape from iOS 26.1
// UIGlassEffect.h (NS_SWIFT_NAME Style, effectWithStyle: → init(style:),
// isInteractive, tintColor, UIGlassContainerEffect.spacing).
//
// MEASURED /tmp/materials-probe, iPhone SE 2x / iOS 26.1:
//   Style.regular.rawValue = 0, .clear = 1
//   init() and init(style:.regular) are distinct objects (NSObject
//   identity equality; hashes are pointer-sized). copy() of a glass
//   effect is a new object with the same isInteractive / tintColor.
//   UIGlassContainerEffect.copy() returns self; default spacing = 0.
//   isInteractive does not change rest pixels (regular.interactive
//   interiors byte-match regular).

#if canImport(Foundation)
import class Foundation.NSCoder
import class Foundation.NSObject
import struct Foundation.NSZone
#elseif canImport(ObjectiveC)
import class ObjectiveC.NSObject
#endif

#if canImport(CoreGraphics)
import struct CoreFoundation.CGFloat
#elseif canImport(Foundation)
import Foundation
#endif

@available(iOS 26.0, *)
@available(watchOS, unavailable)
@preconcurrency @MainActor
open class UIGlassEffect: UIVisualEffect {
    @available(iOS 26.0, *)
    @available(watchOS, unavailable)
    public enum Style: Int, Sendable {
        case regular = 0
        case clear = 1
    }

    public var isInteractive: Bool = false
    public var tintColor: UIColor?

    nonisolated let storedStyle: Style

    public override init() {
        storedStyle = .regular
        super.init()
    }

    /// SDK `+effectWithStyle:` (`NS_SWIFT_NAME(init(style:))`).
    public convenience init(style: Style) {
        self.init(_style: style)
    }

    init(_style style: Style) {
        storedStyle = style
        super.init()
    }

    public required init?(coder: NSCoder) {
#if canImport(Foundation)
        if coder.allowsKeyedCoding,
           coder.containsValue(forKey: "OpenUIKit.UIGlassEffect.style") {
            let raw = coder.decodeInteger(forKey: "OpenUIKit.UIGlassEffect.style")
            storedStyle = Style(rawValue: raw) ?? .regular
        } else {
            storedStyle = .regular
        }
        super.init(coder: coder)
        if coder.allowsKeyedCoding {
            isInteractive = coder.decodeBool(
                forKey: "OpenUIKit.UIGlassEffect.interactive")
            if coder.containsValue(forKey: "OpenUIKit.UIGlassEffect.tint.r") {
                tintColor = UIColor(
                    red: CGFloat(coder.decodeDouble(
                        forKey: "OpenUIKit.UIGlassEffect.tint.r")),
                    green: CGFloat(coder.decodeDouble(
                        forKey: "OpenUIKit.UIGlassEffect.tint.g")),
                    blue: CGFloat(coder.decodeDouble(
                        forKey: "OpenUIKit.UIGlassEffect.tint.b")),
                    alpha: CGFloat(coder.decodeDouble(
                        forKey: "OpenUIKit.UIGlassEffect.tint.a")))
            }
        }
#else
        storedStyle = .regular
        super.init(coder: coder)
#endif
    }

#if canImport(Foundation)
    open override class var supportsSecureCoding: Bool { true }

    open override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(storedStyle.rawValue,
                     forKey: "OpenUIKit.UIGlassEffect.style")
        coder.encode(isInteractive,
                     forKey: "OpenUIKit.UIGlassEffect.interactive")
        if let tintColor {
            let c = tintColor.cgColor
            coder.encode(Double(c.red), forKey: "OpenUIKit.UIGlassEffect.tint.r")
            coder.encode(Double(c.green), forKey: "OpenUIKit.UIGlassEffect.tint.g")
            coder.encode(Double(c.blue), forKey: "OpenUIKit.UIGlassEffect.tint.b")
            coder.encode(Double(c.alpha), forKey: "OpenUIKit.UIGlassEffect.tint.a")
        }
    }

    /// MEASURED /tmp/materials-probe: copy() is a new object (identity
    /// false) carrying isInteractive and tintColor.
    open override func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        let copied = UIGlassEffect(_style: storedStyle)
        copied.isInteractive = isInteractive
        copied.tintColor = tintColor
        return copied
    }
#endif

    override var _descriptor: _UIVisualEffectDescriptor {
        .glass(style: storedStyle)
    }
}

@available(iOS 26.0, *)
@available(watchOS, unavailable)
@preconcurrency @MainActor
open class UIGlassContainerEffect: UIVisualEffect {
    /// Distance at which nested glass elements begin to merge.
    /// MEASURED default 0; copy() returns self.
    public var spacing: CGFloat = 0

    public override init() {
        super.init()
    }

    public required init?(coder: NSCoder) {
#if canImport(Foundation)
        if coder.allowsKeyedCoding,
           coder.containsValue(forKey: "OpenUIKit.UIGlassContainerEffect.spacing") {
            spacing = CGFloat(coder.decodeDouble(
                forKey: "OpenUIKit.UIGlassContainerEffect.spacing"))
        }
#endif
        super.init(coder: coder)
    }

#if canImport(Foundation)
    open override class var supportsSecureCoding: Bool { true }

    open override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(Double(spacing),
                     forKey: "OpenUIKit.UIGlassContainerEffect.spacing")
    }

    open override func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        return self
    }
#endif

    override var _descriptor: _UIVisualEffectDescriptor {
        .glassContainer(spacing: spacing)
    }
}
