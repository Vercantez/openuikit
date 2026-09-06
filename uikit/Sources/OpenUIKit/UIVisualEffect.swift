// UIVisualEffect, blur/vibrancy effects, and UIVisualEffectView.
//
// The built-in effect objects are immutable descriptions. Recognized blur
// views install a real destination-sampling Canvas backdrop operation; the
// private CAFilter boundary below also executes VariableBlur's spatial mask.
// This file deliberately does not paint a flat translucent stand-in and call
// it blur. Object/archive semantics and the view hierarchy remain independent
// of rendering: built-in effects copy/archive like UIKit and contentView has
// stable identity and fill geometry.

// UIKit's effect objects are NSObject subclasses and its archive/copy
// protocols are Foundation contracts.  Keep those imports scoped on Darwin
// so CoreGraphics' names do not collide with OpenCoreGraphics (the same rule
// used by UIViewPropertyAnimator and the text-input NSObject family).
#if canImport(Foundation)
import class Foundation.NSCoder
import protocol Foundation.NSCopying
import class Foundation.NSKeyedArchiver
import class Foundation.NSObject
import protocol Foundation.NSSecureCoding
import struct Foundation.NSZone
#elseif canImport(ObjectiveC)
import class ObjectiveC.NSObject
#endif

#if canImport(CoreGraphics)
import struct CoreFoundation.CGFloat
import struct CoreGraphics.CGPoint
import struct CoreGraphics.CGRect
import struct CoreGraphics.CGSize
#elseif canImport(Foundation)
import Foundation
#endif

// MARK: - Backend-neutral effect descriptions

/// A renderer-facing description of a supported effect.  This intentionally
/// carries semantic styles rather than backend objects or sampled pixels.
/// The software and Quartz compositors can resolve adaptive styles against
/// the destination view's traits without making the public effect mutable.
enum _UIVisualEffectDescriptor: Equatable, Sendable {
    /// UIVisualEffect itself and an unknown direct subclass are valid objects
    /// but have no effect configuration UIKit knows how to install.
    case unsupported
    /// `nil` is UIBlurEffect's public zero-argument, zero-radius effect.
    case blur(style: UIBlurEffect.Style?)
    /// `nil` style is the original iOS 8 vibrancy factory.  A nil blur is the
    /// inert zero-argument UIVibrancyEffect.
    case vibrancy(blurStyle: UIBlurEffect.Style?,
                  style: UIVibrancyEffectStyle?)
    case glass(style: UIGlassEffect.Style)
    case glassContainer(spacing: CGFloat)
}

// MARK: - Base effect

@available(iOS 8.0, *)
@available(watchOS, unavailable)
@preconcurrency @MainActor
open class UIVisualEffect: NSObject {
    /// NSObject's public initializer is inherited by UIKit's empty effect
    /// class.  Spell it explicitly because the required coder initializer
    /// below would otherwise suppress initializer inheritance in pure Swift.
    public override init() {
        super.init()
    }

    /// UIVisualEffect conforms to NSSecureCoding on Foundation-visible
    /// builds.  The base object has no payload, but a fresh instance must be
    /// produced when an archive is decoded (copying, in contrast, is
    /// identity-preserving because effects are immutable).
    public required init?(coder: NSCoder) {
        _ = coder
        super.init()
    }

#if canImport(Foundation)
    open class var supportsSecureCoding: Bool { true }

    open func encode(with coder: NSCoder) {
        _ = coder
    }

    open func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        return self
    }
#endif

    /// External subclasses deliberately inherit `.unsupported`: UIKit keeps
    /// unknown UIVisualEffect subclasses in `effect` but installs no blur or
    /// vibrancy hierarchy for them.
    var _descriptor: _UIVisualEffectDescriptor { .unsupported }
}

#if canImport(Foundation)
extension UIVisualEffect: NSCopying, NSSecureCoding {}
#endif

// MARK: - Blur

@available(iOS 8.0, *)
@available(watchOS, unavailable)
@preconcurrency @MainActor
open class UIBlurEffect: UIVisualEffect, @unchecked Sendable {
    /// Imported Objective-C NS_ENUM shape.  Values are pinned to iOS 26.1.
    ///
    /// Clang's extensible enum can carry unnamed integers.  Native Swift has
    /// no exact spelling for that ABI behavior, so two measured runtime tags
    /// are kept as unavailable cases.  They preserve enum switch ergonomics
    /// for clients while making raw 3 and 21 round-trip like UIKit.
    @available(iOS 8.0, *)
    @available(watchOS, unavailable)
    public enum Style: Int, Sendable {
        case extraLight = 0
        case light = 1
        case dark = 2
        @available(*, unavailable, message: "private UIKit runtime value")
        case _extraDark = 3
        @available(iOS 10.0, *)
        case regular = 4
        @available(iOS 10.0, *)
        case prominent = 5
        @available(iOS 13.0, *)
        @available(tvOS, unavailable)
        case systemUltraThinMaterial = 6
        @available(iOS 13.0, *)
        @available(tvOS, unavailable)
        case systemThinMaterial = 7
        @available(iOS 13.0, *)
        @available(tvOS, unavailable)
        case systemMaterial = 8
        @available(iOS 13.0, *)
        @available(tvOS, unavailable)
        case systemThickMaterial = 9
        @available(iOS 13.0, *)
        @available(tvOS, unavailable)
        case systemChromeMaterial = 10
        @available(iOS 13.0, *)
        @available(tvOS, unavailable)
        case systemUltraThinMaterialLight = 11
        @available(iOS 13.0, *)
        @available(tvOS, unavailable)
        case systemThinMaterialLight = 12
        @available(iOS 13.0, *)
        @available(tvOS, unavailable)
        case systemMaterialLight = 13
        @available(iOS 13.0, *)
        @available(tvOS, unavailable)
        case systemThickMaterialLight = 14
        @available(iOS 13.0, *)
        @available(tvOS, unavailable)
        case systemChromeMaterialLight = 15
        @available(iOS 13.0, *)
        @available(tvOS, unavailable)
        case systemUltraThinMaterialDark = 16
        @available(iOS 13.0, *)
        @available(tvOS, unavailable)
        case systemThinMaterialDark = 17
        @available(iOS 13.0, *)
        @available(tvOS, unavailable)
        case systemMaterialDark = 18
        @available(iOS 13.0, *)
        @available(tvOS, unavailable)
        case systemThickMaterialDark = 19
        @available(iOS 13.0, *)
        @available(tvOS, unavailable)
        case systemChromeMaterialDark = 20
        @available(*, unavailable, message: "private UIKit runtime value")
        case _runtime21 = 21

        /// Build a public or measured unnamed tag without exposing the hidden
        /// cases to an app's exhaustive switch. UIKit's imported extensible
        /// enum accepts every integer; a native Swift enum cannot do that and
        /// retain this source shape. OpenUIKit preserves the two unnamed tags
        /// observed on iOS 26.1 (3 and 21) as well as all public cases.
        public init?(rawValue: Int) {
            guard let value = Self._runtimeValue(rawValue: rawValue) else {
                return nil
            }
            self = value
        }

        /// Declaration order and raw order are identical, so compact enum
        /// tags 0...21 are the values.
        static func _runtimeValue(rawValue: Int) -> Self? {
            switch rawValue {
            case 0...21:
                return unsafeBitCast(UInt8(rawValue), to: Self.self)
            default:
                return nil
            }
        }
    }

    /// Effect objects are immutable. NSObject's equality/hash requirements
    /// are nonisolated, so their Sendable semantic key is explicitly safe to
    /// read without hopping to UIKit's main actor.
    nonisolated private let storedStyle: Style?

#if canImport(Foundation)
    /// Foundation's keyed archiver requires a subclass that overrides its
    /// coder initializer to restate this inherited class property.
    open override class var supportsSecureCoding: Bool { true }
#endif

    /// UIKit exposes an inert zero-radius UIBlurEffect through inherited
    /// `init()`, in addition to the styled factory initializer.
    public override init() {
        storedStyle = nil
        super.init()
    }

    public init(style: Style) {
        storedStyle = style
        super.init()
    }

    public required init?(coder: NSCoder) {
#if canImport(Foundation)
        if coder.allowsKeyedCoding,
           coder.containsValue(forKey: "OpenUIKit.UIBlurEffect.style") {
            storedStyle = Style._runtimeValue(
                rawValue: coder.decodeInteger(
                    forKey: "OpenUIKit.UIBlurEffect.style"))
        } else {
            storedStyle = nil
        }
#else
        storedStyle = nil
#endif
        super.init(coder: coder)
    }

#if canImport(Foundation)
    open override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        if let storedStyle {
            coder.encode(storedStyle.rawValue,
                         forKey: "OpenUIKit.UIBlurEffect.style")
        }
    }
#endif

    override var _descriptor: _UIVisualEffectDescriptor {
        .blur(style: storedStyle)
    }

    /// UIKit compares built-in blur effects by their semantic blur style,
    /// not object identity. The style's imported raw value is also the
    /// measured NSObject hash (including zero for the inert initializer).
    nonisolated open override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? UIBlurEffect else { return false }
        return storedStyle == other.storedStyle
    }

    nonisolated open override var hash: Int {
        storedStyle?.rawValue ?? 0
    }

    /// Internal renderer access.  UIKit intentionally exposes no style
    /// getter; keeping this internal maintains that public API boundary.
    nonisolated var _style: Style? { storedStyle }
}

// MARK: - Vibrancy

/// Values are the iOS 13 UIVibrancyEffectStyle NS_ENUM values.
@available(iOS 13.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public enum UIVibrancyEffectStyle: Int, Sendable {
    case label = 0
    case secondaryLabel = 1
    case tertiaryLabel = 2
    case quaternaryLabel = 3
    case fill = 4
    case secondaryFill = 5
    case tertiaryFill = 6
    case separator = 7
}

@available(iOS 8.0, *)
@available(tvOS 9.0, *)
@available(watchOS, unavailable)
@preconcurrency @MainActor
open class UIVibrancyEffect: UIVisualEffect {
    /// Immutable identity used by NSObject's nonisolated equality/hash API.
    /// Global-actor effect references are Sendable, so the constant can be
    /// read safely without a main-actor hop.
    nonisolated private let storedBlurEffect: UIBlurEffect?
    private let storedStyle: UIVibrancyEffectStyle?

#if canImport(Foundation)
    /// See UIBlurEffect.supportsSecureCoding.
    open override class var supportsSecureCoding: Bool { true }
#endif

    /// The inherited-looking zero-argument initializer is observable on iOS
    /// 26.1.  It creates an inert vibrancy effect with no backing blur.
    public override init() {
        storedBlurEffect = nil
        storedStyle = nil
        super.init()
    }

    public init(blurEffect: UIBlurEffect) {
        storedBlurEffect = blurEffect
        storedStyle = nil
        super.init()
    }

    @available(iOS 13.0, *)
    @available(tvOS, unavailable)
    public init(blurEffect: UIBlurEffect, style: UIVibrancyEffectStyle) {
        storedBlurEffect = blurEffect
        storedStyle = style
        super.init()
    }

    /// The SDK symbol graph retains these pre-Swift-3 overlay spellings as
    /// obsoleted/renamed declarations.  Matching that availability produces
    /// the same migration diagnostic without creating a second live API.
    @available(swift, obsoleted: 3, renamed: "init(blurEffect:)")
    public convenience init(forBlurEffect blurEffect: UIBlurEffect) {
        self.init(blurEffect: blurEffect)
    }

    @available(swift, obsoleted: 3,
               renamed: "init(blurEffect:style:)")
    @available(iOS 13.0, *)
    @available(tvOS, unavailable)
    public convenience init(forBlurEffect blurEffect: UIBlurEffect,
                            style: UIVibrancyEffectStyle) {
        self.init(blurEffect: blurEffect, style: style)
    }

    public required init?(coder: NSCoder) {
#if canImport(Foundation)
        if coder.allowsKeyedCoding {
            if coder.containsValue(
                forKey: "OpenUIKit.UIVibrancyEffect.blur") {
                storedBlurEffect = coder.decodeObject(
                    of: UIBlurEffect.self,
                    forKey: "OpenUIKit.UIVibrancyEffect.blur")
            } else {
                // Corelibs Foundation rejects a secure object decode for an
                // absent key instead of returning nil as Darwin does. The
                // zero-argument vibrancy effect intentionally omits this key.
                storedBlurEffect = nil
            }
            if coder.containsValue(
                forKey: "OpenUIKit.UIVibrancyEffect.style") {
                storedStyle = UIVibrancyEffectStyle(
                    rawValue: coder.decodeInteger(
                        forKey: "OpenUIKit.UIVibrancyEffect.style"))
            } else {
                storedStyle = nil
            }
        } else {
            storedBlurEffect = nil
            storedStyle = nil
        }
#else
        storedBlurEffect = nil
        storedStyle = nil
#endif
        super.init(coder: coder)
    }

#if canImport(Foundation)
    open override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        if let storedBlurEffect {
            coder.encode(storedBlurEffect,
                         forKey: "OpenUIKit.UIVibrancyEffect.blur")
        }
        if let storedStyle {
            coder.encode(storedStyle.rawValue,
                         forKey: "OpenUIKit.UIVibrancyEffect.style")
        }
    }
#endif

    override var _descriptor: _UIVisualEffectDescriptor {
        .vibrancy(blurStyle: storedBlurEffect?._style,
                  style: storedStyle)
    }

    /// iOS 26.1's NSObject semantics compare vibrancy effects by their
    /// backing blur and deliberately ignore UIVibrancyEffectStyle. A nil
    /// backing blur remains distinct from an explicitly supplied inert blur.
    nonisolated open override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? UIVibrancyEffect else { return false }
        switch (storedBlurEffect, other.storedBlurEffect) {
        case (nil, nil):
            return true
        case let (lhs?, rhs?):
            return lhs.isEqual(rhs)
        default:
            return false
        }
    }

    nonisolated open override var hash: Int {
        guard let storedBlurEffect else {
            // Stable native iOS 26.1 semantic hash for the no-backing-blur
            // effect; both independent instances and archives return it.
            return 7_502_673_159_197_000_442
        }
        // UIKit uses a distinct sentinel for an explicitly present inert
        // blur, whose own public hash is zero.
        return storedBlurEffect._style?.rawValue ?? 24
    }
}

// MARK: - Effect view

/// Private UIKit uses specialized classes for these two hierarchy nodes. A
/// named internal subclass keeps public `subviews` inspection meaningful and
/// gives the view renderer a future attachment point without drawing fake
/// pixels.
@MainActor
final class _UIVisualEffectContentView: UIView {
    override init(frame: CGRect) { super.init(frame: frame) }
    required init?(coder: NSCoder) { super.init(coder: coder) }
}

@MainActor
final class _UIVisualEffectBackdropView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        isOpaque = false
        isUserInteractionEnabled = false
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        isOpaque = false
        isUserInteractionEnabled = false
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
}

/// Convert dynamically supplied Core Animation inputs without depending on
/// Foundation's NSNumber declaration. Objective-C numeric boxes conditionally
/// cast through Swift's bridge when it is present; the concrete scalar cases
/// also cover Foundation-hidden framework builds and direct Swift callers.
private func _openFilterCGFloat(_ value: Any?) -> CGFloat? {
    switch value {
    case let value as CGFloat: return value
    case let value as Double: return CGFloat(value)
    case let value as Float: return CGFloat(value)
    case let value as Int: return CGFloat(value)
    case let value as Int32: return CGFloat(value)
    case let value as UInt: return CGFloat(value)
    default: return nil
    }
}

private func _openFilterBool(_ value: Any?) -> Bool? {
    switch value {
    case let value as Bool: return value
    case let value as Int: return value != 0
    case let value as Int32: return value != 0
    default: return nil
    }
}

/// Normalize an Objective-C object argument at the private CAFilter boundary.
///
/// Foundation-hidden guest builds cannot name `NSString` in this module: the
/// public Foundation overlay is intentionally compiled later in the platform
/// graph. An Objective-C `id` carrying NSString still dynamically bridges to
/// Swift.String, however, which lets the implementation remain strict (only
/// real string objects are accepted) instead of trusting arbitrary object
/// descriptions as filter names or KVC keys.
private func _openFilterString(_ value: Any?) -> String? {
    value as? String
}

/// Core Image and CGImage masks use a bottom-left image coordinate system,
/// while UIView and Canvas use top-left coordinates. Copy the alpha plane at
/// the private Core Animation boundary so the generic Canvas mask primitive
/// keeps its natural top-left contract and an asymmetric app mask is not
/// silently applied upside down.
private func _openCAFilterMask(_ bitmap: Bitmap) -> CanvasBackdropFilterMask? {
    guard let source = CanvasBackdropFilterMask(bitmap) else { return nil }
    var flipped = [UInt8](repeating: 0, count: source.alpha.count)
    for y in 0..<source.height {
        let sourceStart = y * source.width
        let destinationStart = (source.height - y - 1) * source.width
        flipped.replaceSubrange(
            destinationStart..<(destinationStart + source.width),
            with: source.alpha[sourceStart..<(sourceStart + source.width)])
    }
    return CanvasBackdropFilterMask(
        width: source.width, height: source.height, alpha: flipped)
}

/// Concrete private Core Animation filter used by unchanged applications.
/// Native Objective-C registration is load-bearing: `NSClassFromString`
/// resolves the exact runtime name `CAFilter`, and NSObject's ordinary
/// `perform(_:with:)` dispatch reaches the exact class selector
/// `filterWithType:`. Only the implemented variable blur type is admitted;
/// every unknown filter name returns nil and therefore fails closed.
#if canImport(ObjectiveC)
@objc(CAFilter)
#endif
@preconcurrency @MainActor
final class _OpenCAFilter: NSObject {
    nonisolated let filterType: String
    private var inputRadiusValue: Any?
    private var inputMaskImageValue: Any?
    private var inputNormalizeEdgesValue: Any?
    private var resolvedMaskValue: CanvasBackdropFilterMask?

    private init(filterType: String) {
        self.filterType = filterType
        super.init()
    }

#if canImport(Foundation)
#if canImport(ObjectiveC)
    @objc(filterWithType:)
#endif
    class func filter(withType type: String) -> _OpenCAFilter? {
        _filter(withType: type)
    }
#else
    /// Foundation-hidden Objective-C imports cannot represent Swift.String in
    /// an @objc signature. Use Objective-C `id` at the ABI boundary and bridge
    /// its boxed NSString payload immediately, preserving `filterWithType:`.
#if canImport(ObjectiveC)
    @objc(filterWithType:)
#endif
    class func filter(withType rawType: Any?) -> _OpenCAFilter? {
        guard let type = _openFilterString(rawType) else { return nil }
        return _filter(withType: type)
    }
#endif

    private class func _filter(withType type: String) -> _OpenCAFilter? {
        guard type == "variableBlur" else { return nil }
        return _OpenCAFilter(filterType: type)
    }

#if canImport(Foundation) && canImport(ObjectiveC)
    override func setValue(_ value: Any?, forKey key: String) {
        _setRetainedValue(value, forKey: key)
    }
#elseif canImport(ObjectiveC)
    @objc(setValue:forKey:)
    func setValue(_ value: Any?, forKey rawKey: Any?) {
        guard let key = _openFilterString(rawKey) else { return }
        _setRetainedValue(value, forKey: key)
    }
#else
    // Native ELF: swift-corelibs NSObject has no KVC setter either (same
    // failure as value(forKey:) below, measured 2026-09-04 in Docker).
    func setValue(_ value: Any?, forKey key: String) {
        _setRetainedValue(value, forKey: key)
    }
#endif

    private func _setRetainedValue(_ value: Any?, forKey key: String) {
        switch key {
        case "inputRadius":
            inputRadiusValue = value
        case "inputMaskImage":
            inputMaskImageValue = value
            resolvedMaskValue = (value as? Bitmap).flatMap(_openCAFilterMask)
        case "inputNormalizeEdges":
            inputNormalizeEdgesValue = value
        default:
            // Private filters are not an unbounded KVC dictionary. Silently
            // ignore unsupported inputs so a typo cannot acquire behavior.
            break
        }
    }

#if canImport(Foundation) && canImport(ObjectiveC)
    // Apple's Foundation: NSObject has KVC, so this is an override.
    override func value(forKey key: String) -> Any? {
        _retainedValue(forKey: key)
    }
#elseif canImport(ObjectiveC)
    // Foundation-hidden Mach-O build: publish the selector for KVC callers.
    @objc(valueForKey:)
    func value(forKey rawKey: Any?) -> Any? {
        guard let key = _openFilterString(rawKey) else { return nil }
        return _retainedValue(forKey: key)
    }
#else
    // Native ELF (swift-corelibs Foundation): NSObject has no value(forKey:),
    // so this is a plain method. Measured 2026-09-04: the previous
    // `#if canImport(Foundation)` override failed to compile on Linux
    // ("method does not override any method from its superclass") and had
    // broken scripts/linux_realapp_verify.sh since 2026-08-31.
    func value(forKey key: String) -> Any? {
        _retainedValue(forKey: key)
    }
#endif

    private func _retainedValue(forKey key: String) -> Any? {
        switch key {
        case "inputRadius": return inputRadiusValue
        case "inputMaskImage": return inputMaskImageValue
        case "inputNormalizeEdges": return inputNormalizeEdgesValue
        default: return nil
        }
    }

    var _canvasConfiguration: CanvasBackdropFilterConfiguration? {
        guard filterType == "variableBlur",
              let radius = _openFilterCGFloat(inputRadiusValue),
              radius.isFinite, radius > 0,
              let mask = resolvedMaskValue
        else { return nil }
        return CanvasBackdropFilterConfiguration(
            blurRadius: radius,
            blurMask: mask,
            normalizesMaskEdges: _openFilterBool(
                inputNormalizeEdgesValue) ?? false)
    }

#if canImport(Foundation)
    nonisolated override var description: String { filterType }
#else
    /// ObjectiveC.NSObject has no Foundation description requirement in the
    /// guest graph, but keeping this concrete member is useful to statically
    /// typed framework diagnostics without inventing a superclass override.
    nonisolated var description: String { filterType }
#endif
}

#if !canImport(Foundation)
// ObjectiveC.NSObject alone contributes no CustomStringConvertible witness.
// Declare it explicitly so String(describing:) and CALayer filter inspection
// use the stable private filter name in the Foundation-hidden guest graph.
extension _OpenCAFilter: CustomStringConvertible {}
#endif

/// Name-bearing compatibility token for the standard backdrop filter. Public
/// code inspects these values through CALayer.filters and string interpolation;
/// the renderer resolves the retained semantic radius below.
private final class _OpenVisualEffectFilterToken: CustomStringConvertible {
    let description: String
    let blurRadius: CGFloat

    init(_ description: String, blurRadius: CGFloat = 20) {
        self.description = description
        self.blurRadius = blurRadius
    }
}

@available(iOS 8.0, *)
@available(watchOS, unavailable)
@preconcurrency @MainActor
open class UIVisualEffectView: UIView, _UIViewSubviewAdmission {
    private var storedContentView: UIView?
    private var backdropView: _UIVisualEffectBackdropView?
    private var compatibilityFilterLayer: CALayer?

    open override var bounds: CGRect {
        didSet {
            // A detached materialized content view retains its established
            // origin. A hosted effect view follows its bounds origin, matching
            // the measured UIWindow behavior. Leaving content unmaterialized
            // is important: its first public access uses the then-current
            // bounds, which is UIKit's observable access-order transition.
            if oldValue.origin != bounds.origin, window != nil {
                if var contentFrame = storedContentView?.frame {
                    contentFrame.origin = bounds.origin
                    storedContentView?.frame = contentFrame
                }
                if let backdropView {
                    var backdropFrame = backdropView.frame
                    backdropFrame.origin = bounds.origin
                    backdropView.frame = backdropFrame
                }
            }
            compatibilityFilterLayer?.frame = bounds
        }
    }

    open var contentView: UIView {
        _materializeContentView(usingBoundsOrigin: true)
    }

#if canImport(Foundation)
    /// Objective-C declares this property `copy`; @NSCopying supplies the
    /// same copy-on-assignment behavior to Swift subclasses as UIKit.
    @NSCopying open var effect: UIVisualEffect? {
        didSet { _effectDidChange(from: oldValue) }
    }
#else
    /// Foundation-hidden guests cannot name NSCopying.  They retain the
    /// UIKit-visible property while narrowing assignment to ordinary strong
    /// storage, the same conditional boundary as other coding/copy APIs.
    open var effect: UIVisualEffect? {
        didSet { _effectDidChange(from: oldValue) }
    }
#endif

    public override convenience init(frame: CGRect) {
        self.init(effect: nil)
        self.frame = frame
    }

    public init(effect: UIVisualEffect?) {
#if canImport(Foundation)
        // Swift's stored-property initialization bypasses @NSCopying's
        // synthesized setter. UIKit nevertheless sends exactly one copy to
        // a custom effect passed to init(effect:) and retains that result.
        // Copy before initializing any property so this path cannot observe
        // partially initialized self or accidentally invoke an override.
        let initialEffect = effect?.copy(with: nil) as? UIVisualEffect
#else
        // Foundation-hidden guests cannot name NSCopying and deliberately use
        // the strong-storage compatibility boundary documented below.
        let initialEffect = effect
#endif
        storedContentView = nil
        self.effect = initialEffect
        super.init(frame: .zero)
        _effectDidChange(from: nil)
    }

    public required init?(coder: NSCoder) {
        storedContentView = nil
#if canImport(Foundation)
        if coder.allowsKeyedCoding {
            let decodedEffect = coder.decodeObject(
                of: UIVisualEffect.self,
                forKey: "OpenUIKit.UIVisualEffectView.effect")
            // The iOS 26.1 archive oracle preserves a hostile effect subclass
            // and sends it exactly one copy while decoding the view. As with
            // init(effect:), stored-property initialization would otherwise
            // bypass @NSCopying's setter.
            effect = decodedEffect?.copy(with: nil) as? UIVisualEffect
        } else {
            effect = nil
        }
#else
        effect = nil
#endif
        super.init(coder: coder)
#if canImport(Foundation)
        if coder.allowsKeyedCoding,
           coder.containsValue(forKey: "OpenUIKit.UIVisualEffectView.frame.x") {
            frame = CGRect(
                x: coder.decodeDouble(
                    forKey: "OpenUIKit.UIVisualEffectView.frame.x"),
                y: coder.decodeDouble(
                    forKey: "OpenUIKit.UIVisualEffectView.frame.y"),
                width: coder.decodeDouble(
                    forKey: "OpenUIKit.UIVisualEffectView.frame.width"),
                height: coder.decodeDouble(
                    forKey: "OpenUIKit.UIVisualEffectView.frame.height"))
            bounds.origin = CGPoint(
                x: coder.decodeDouble(
                    forKey: "OpenUIKit.UIVisualEffectView.bounds.x"),
                y: coder.decodeDouble(
                    forKey: "OpenUIKit.UIVisualEffectView.bounds.y"))
        }
#endif
        // UIKit's decoded view exposes a content view whose frame is the
        // decoded bounds immediately, before an explicit layout pass.
        _materializeContentView(usingBoundsOrigin: true)
        _effectDidChange(from: nil)
    }

#if canImport(Foundation)
    open class var supportsSecureCoding: Bool { true }

    open func encode(with coder: NSCoder) {
        coder.encode(effect,
                     forKey: "OpenUIKit.UIVisualEffectView.effect")
        coder.encode(Double(frame.minX),
                     forKey: "OpenUIKit.UIVisualEffectView.frame.x")
        coder.encode(Double(frame.minY),
                     forKey: "OpenUIKit.UIVisualEffectView.frame.y")
        coder.encode(Double(frame.width),
                     forKey: "OpenUIKit.UIVisualEffectView.frame.width")
        coder.encode(Double(frame.height),
                     forKey: "OpenUIKit.UIVisualEffectView.frame.height")
        coder.encode(Double(bounds.minX),
                     forKey: "OpenUIKit.UIVisualEffectView.bounds.x")
        coder.encode(Double(bounds.minY),
                     forKey: "OpenUIKit.UIVisualEffectView.bounds.y")
    }
#endif

    open override func layoutSubviews() {
        super.layoutSubviews()
        guard let storedContentView else {
            if let backdropView {
                backdropView.frame = CGRect(
                    origin: window != nil
                        ? bounds.origin : backdropView.frame.origin,
                    size: bounds.size)
            }
            return
        }
        let fill = CGRect(
            origin: window != nil
                ? bounds.origin : storedContentView.frame.origin,
            size: bounds.size)
        backdropView?.frame = fill
        storedContentView.frame = fill
        bringSubviewToFront(storedContentView)
    }

    /// Current semantic payload for the compositor.  nil means the public
    /// effect property is nil; `.unsupported` means a valid unknown/base
    /// effect is retained but intentionally inert.
    var _visualEffectDescriptor: _UIVisualEffectDescriptor? {
        effect?._descriptor
    }

    /// Resolve the one backdrop operation the current private layer graph
    /// requests. The UIView-backed backdrop is authoritative: replacing its
    /// standard gaussian token with a concrete CAFilter replaces, rather than
    /// stacks with, the built-in effect. The standalone compatibility layer
    /// retains the gaussian radius KVC path used by BackgroundBlur but never
    /// paints a second copy of the filter.
    func _canvasBackdropConfiguration(
        for backdrop: _UIVisualEffectBackdropView
    ) -> CanvasBackdropFilterConfiguration? {
        guard backdrop === backdropView,
              let filters = backdrop.layer.filters,
              !filters.isEmpty
        else { return nil }

        for filter in filters {
            if let variable = filter as? _OpenCAFilter {
                // A recognized-but-incomplete variable filter stays inert;
                // it must never silently turn into a uniform gaussian.
                return variable._canvasConfiguration
            }
        }

        guard let gaussian = filters.first(where: {
            ($0 as? _OpenVisualEffectFilterToken)?.description == "gaussianBlur"
        }) as? _OpenVisualEffectFilterToken else { return nil }
        let retainedRadius = compatibilityFilterLayer?.value(
            forKeyPath: "filters.gaussianBlur.inputRadius")
        let radius = _openFilterCGFloat(retainedRadius) ?? gaussian.blurRadius
        guard radius.isFinite, radius > 0 else { return nil }
        if OpenUIKitRuntime.systemFontCut == .iOS {
            if let blur = effect as? UIBlurEffect {
                // Inert `UIBlurEffect()` is zero-radius (public init). A
                // nil mix must not fall through to the token's radius 20.
                return _UIMaterialMix.blurConfiguration(
                    style: blur._style,
                    traits: traitCollection)
            }
            if let glass = effect as? UIGlassEffect {
                return _UIMaterialMix.glassConfiguration(
                    style: glass.storedStyle,
                    tintColor: glass.tintColor,
                    traits: traitCollection)
            }
        }
        return CanvasBackdropFilterConfiguration(blurRadius: radius)
    }

    @discardableResult
    private func _materializeContentView(
        usingBoundsOrigin: Bool
    ) -> UIView {
        if let storedContentView {
            return storedContentView
        }
        let content = _UIVisualEffectContentView(frame: CGRect(
            origin: usingBoundsOrigin ? bounds.origin : .zero,
            size: bounds.size))
        content.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        storedContentView = content
        _addSubviewWithoutAdmissionCheck(content)
        if let backdropView {
            backdropView.frame = content.frame
            sendSubviewToBack(backdropView)
        }
        return content
    }

    /// The Darwin archive surrogate reconstructs through `init(effect:)`,
    /// then restores scalar geometry. UIKit exposes bounds-origin content as
    /// soon as decoding returns, without requiring `layoutIfNeeded()`.
    fileprivate func _adoptDecodedContentGeometry() {
        let fill = bounds
        backdropView?.frame = fill
        let content = _materializeContentView(usingBoundsOrigin: true)
        content.frame = fill
        bringSubviewToFront(content)
    }

    private func _effectDidChange(from previousEffect: UIVisualEffect?) {
        let changedSemantically: Bool
        switch (previousEffect, effect) {
        case (nil, nil):
            changedSemantically = false
        case let (previous?, current?):
            // UIKit keys this immediate geometry transition to NSObject
            // value equality, not reference identity. This deliberately
            // honors custom subclass equality as well as built-in effects.
            changedSemantically = !previous.isEqual(current)
        default:
            changedSemantically = true
        }

        // Vibrancy eagerly builds the public content host on UIKit. Nil, base,
        // and blur effects leave it lazy until contentView is first read.
        if effect is UIVibrancyEffect, storedContentView == nil {
            _materializeContentView(usingBoundsOrigin: false)
        }

        if effect is UIBlurEffect || effect is UIGlassEffect {
            if backdropView == nil {
                let backdrop = _UIVisualEffectBackdropView(
                    frame: CGRect(origin: storedContentView?.frame.origin ?? .zero,
                                  size: bounds.size))
                backdropView = backdrop
                _insertSubviewWithoutAdmissionCheck(backdrop, at: 0)
            }
            if compatibilityFilterLayer == nil {
                let filterLayer = CALayer()
                filterLayer.frame = bounds
                filterLayer.isOpaque = false
                filterLayer.filters = [_OpenVisualEffectFilterToken("gaussianBlur")]
                compatibilityFilterLayer = filterLayer
                layer.insertSublayer(filterLayer, at: 0)
            }
            if backdropView?.layer.filters == nil {
                backdropView?.layer.filters = [
                    _OpenVisualEffectFilterToken("gaussianBlur")
                ]
            }
        } else {
            backdropView?.removeFromSuperview()
            backdropView = nil
            compatibilityFilterLayer?.removeFromSuperlayer()
            compatibilityFilterLayer = nil
        }

        // A semantically different assignment is an immediate native geometry
        // transition: existing content adopts the current bounds origin
        // without waiting for layout. Equal replacement objects preserve the
        // established origin. Do this after eager vibrancy materialization so
        // nil/base/blur -> vibrancy follows the same transition.
        if changedSemantically, let storedContentView {
            var contentFrame = storedContentView.frame
            contentFrame.origin = bounds.origin
            storedContentView.frame = contentFrame
            backdropView?.frame = contentFrame
        }
        if let storedContentView, storedContentView.superview === self {
            bringSubviewToFront(storedContentView)
        }
        setNeedsDisplay()
    }

    /// Native UIKit raises NSInternalInconsistencyException for this API and
    /// tells callers to insert into contentView. Swift on Linux has no
    /// Objective-C exception ABI, so the closest portable invariant is a
    /// deterministic fatal invariant failure with the same corrective action.
    var _directSubviewInsertionFailureMessage: String {
        "UIVisualEffectView does not accept direct subviews; "
            + "add the view to contentView instead"
    }

    func validateSubviewInsertion(_ view: UIView) {
        _ = view
        fatalError(_directSubviewInsertionFailureMessage)
    }

#if canImport(Foundation) && canImport(ObjectiveC)
    /// Darwin NSKeyedArchiver asks every NSObject root for this replacement
    /// hook before it invokes NSCoding. The surrogate
    /// deliberately represents only a base UIVisualEffectView snapshot:
    /// effect, frame, and bounds origin. It is not UIView graph serialization;
    /// see docs/KNOWN_GAPS.md for the subclass/content-state boundary.
    open override func replacementObject(
        for archiver: NSKeyedArchiver
    ) -> Any? {
        _ = archiver
        return _UIVisualEffectViewArchiveProxy(view: self)
    }
#endif
}

#if canImport(Foundation)
extension UIVisualEffectView: NSSecureCoding {}
#endif

#if canImport(Foundation) && canImport(ObjectiveC)
/// Darwin base-view snapshot surrogate. `awakeAfter(using:)` restores a fresh
/// UIVisualEffectView, never an external subclass or its content hierarchy.
/// It stays internal so no extra framework API escapes the public slice.
@MainActor
final class _UIVisualEffectViewArchiveProxy: NSObject {
    static var supportsSecureCoding: Bool { true }

    private let archivedEffect: UIVisualEffect?
    private let archivedFrame: CGRect
    private let archivedBoundsOrigin: CGPoint

    init(view: UIVisualEffectView) {
        archivedEffect = view.effect
        archivedFrame = view.frame
        archivedBoundsOrigin = view.bounds.origin
        super.init()
    }

    required init?(coder: NSCoder) {
        guard coder.allowsKeyedCoding else { return nil }
        archivedEffect = coder.decodeObject(
            of: UIVisualEffect.self,
            forKey: "OpenUIKit.UIVisualEffectView.effect")
        archivedFrame = CGRect(
            x: coder.decodeDouble(
                forKey: "OpenUIKit.UIVisualEffectView.frame.x"),
            y: coder.decodeDouble(
                forKey: "OpenUIKit.UIVisualEffectView.frame.y"),
            width: coder.decodeDouble(
                forKey: "OpenUIKit.UIVisualEffectView.frame.width"),
            height: coder.decodeDouble(
                forKey: "OpenUIKit.UIVisualEffectView.frame.height"))
        archivedBoundsOrigin = CGPoint(
            x: coder.decodeDouble(
                forKey: "OpenUIKit.UIVisualEffectView.bounds.x"),
            y: coder.decodeDouble(
                forKey: "OpenUIKit.UIVisualEffectView.bounds.y"))
        super.init()
    }

    func encode(with coder: NSCoder) {
        coder.encode(archivedEffect,
                     forKey: "OpenUIKit.UIVisualEffectView.effect")
        coder.encode(Double(archivedFrame.minX),
                     forKey: "OpenUIKit.UIVisualEffectView.frame.x")
        coder.encode(Double(archivedFrame.minY),
                     forKey: "OpenUIKit.UIVisualEffectView.frame.y")
        coder.encode(Double(archivedFrame.width),
                     forKey: "OpenUIKit.UIVisualEffectView.frame.width")
        coder.encode(Double(archivedFrame.height),
                     forKey: "OpenUIKit.UIVisualEffectView.frame.height")
        coder.encode(Double(archivedBoundsOrigin.x),
                     forKey: "OpenUIKit.UIVisualEffectView.bounds.x")
        coder.encode(Double(archivedBoundsOrigin.y),
                     forKey: "OpenUIKit.UIVisualEffectView.bounds.y")
    }

    override func awakeAfter(using coder: NSCoder) -> Any? {
        _ = coder
        let view = UIVisualEffectView(effect: archivedEffect)
        view.frame = archivedFrame
        view.bounds.origin = archivedBoundsOrigin
        view._adoptDecodedContentGeometry()
        return view
    }

}

// Foundation's protocol predates Swift concurrency.  Keep the implementation
// on UIKit's main actor while suppressing only that imported-protocol mismatch.
extension _UIVisualEffectViewArchiveProxy: @preconcurrency NSSecureCoding {}
#endif
