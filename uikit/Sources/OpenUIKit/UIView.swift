// UIView + CALayer facade. Owner: view module.
// SKELETON — structure is in place; rendering (RenderPass.swift), autoresizing
// and layout behaviors must be completed and verified against goldens.

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
import class CoreGraphics.CGContext
#elseif canImport(Foundation)
import Foundation
#endif

// A scoped Foundation declaration makes a conditional `@objc` member legal
// in ordinary Darwin builds without importing the umbrella (and its colliding
// geometry declarations) into this file. Foundation-hidden Mach-O cross
// builds instead use the production
// `-disable-objc-attr-requires-foundation-module` frontend setting.
#if canImport(ObjectiveC) && canImport(Foundation)
import struct Foundation.Data
#endif

// CALayer is an NSObject in Core Animation (see its declaration below), and
// this file has to be able to spell the name. Same fail-closed provider
// choice as UIResponder.swift.
#if canImport(Foundation)
import class Foundation.NSObject
#elseif canImport(ObjectiveC)
import class ObjectiveC.NSObject
#else
#error("OpenUIKit requires Foundation.NSObject or ObjectiveC.NSObject")
#endif


public struct UIRectEdge: OptionSet, Sendable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
}

/// The corners affected by `CALayer.cornerRadius`.
///
/// Core Animation names corners in the layer's local coordinate system.
/// UIView backing layers are not geometry-flipped, so minY is the visual top
/// in OpenUIKit's UIKit-style, top-left coordinate space.
#if !canImport(CoreGraphics)  // QuartzCore's own CACornerMask otherwise (QuartzCoreUnification.swift)
public struct CACornerMask: OptionSet, Sendable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }

    public static let layerMinXMinYCorner = CACornerMask(rawValue: 1 << 0)
    public static let layerMaxXMinYCorner = CACornerMask(rawValue: 1 << 1)
    public static let layerMinXMaxYCorner = CACornerMask(rawValue: 1 << 2)
    public static let layerMaxXMaxYCorner = CACornerMask(rawValue: 1 << 3)

    public static let _allKnown: CACornerMask = [
        .layerMinXMinYCorner, .layerMaxXMinYCorner,
        .layerMinXMaxYCorner, .layerMaxXMaxYCorner,
    ]
}

#endif
public enum UIViewContentMode: Sendable {
    case scaleToFill, scaleAspectFit, scaleAspectFill, redraw, center
    case top, bottom, left, right, topLeft, topRight, bottomLeft, bottomRight
}

#if !canImport(CoreGraphics)
// OpenUIKit's own Core Animation layer, for Linux ELF and the Mach-O guest.
// Where Apple's frameworks exist CALayer / CAGradientLayer / CALayerDelegate
// are QuartzCore's, and the port's state for them lives in
// QuartzCoreUnification.swift (cg-unify phase 3).
/// Class-only subset of QuartzCore's layer delegate used for layout. Core
/// Animation makes this callback optional; a default implementation gives
/// portable Swift delegates the same adopt-only-what-you-use ergonomics.
@preconcurrency @MainActor
public protocol CALayerDelegate: AnyObject {
    func layoutSublayers(of layer: CALayer)
}

public extension CALayerDelegate {
    func layoutSublayers(of layer: CALayer) {}
}

/// Portable CALayer subset. A UIView's backing layer forwards its geometry
/// to the view; layers created directly keep independent geometry and can be
/// attached as an explicit layer tree.  Rendering lives in RenderPass.swift
/// (and LayerBridge.swift for the quartz compositor).
///
/// SDK EVIDENCE (iOS 26.1,
/// .../iPhoneSimulator26.1.sdk/System/Library/Frameworks/QuartzCore.framework/
/// Headers/CALayer.h:117):
///
///     @interface CALayer : NSObject <NSSecureCoding, CAMediaTiming>
///
/// The NSObject base is adopted here: without it Kickstarter-Prelude's
/// `CALayerProtocol: KSObjectProtocol: NSObjectProtocol` cannot be satisfied
/// ("cannot declare conformance to NSObjectProtocol", 9 lens diagnostics in
/// docs/agent_reports/ios-oss-launch.md). `NSSecureCoding` and
/// `CAMediaTiming` are NOT adopted: the port has no archiver for a layer and
/// no `CAMediaTiming` protocol, and declaring either would mean writing
/// unmeasured stubs. Recorded in docs/KNOWN_GAPS.md.
// Objective-C runtime name: UIKit's `CALayer` on the Foundation-hidden
// Mach-O guest, where OpenUIKit is the only Core Animation, so the generated
// header marks it SWIFT_CLASS_NAMED and an Objective-C app may subclass it
// (vtable-free: every member `final` except the `@objc dynamic`
// `layoutSublayers`; objc-surface.md). A Foundation build keeps the mangled
// Swift name: QuartzCore's CALayer is in every macOS host process.
#if _runtime(_ObjC) && !canImport(Foundation)
@objc(CALayer)
#endif
@preconcurrency @MainActor
open class CALayer: NSObject {
    public final weak var owner: UIView?
    public final weak var delegate: CALayerDelegate?

    private final var storedBounds: CGRect = .zero
    private final var storedPosition: CGPoint = .zero
    private final var storedAnchorPoint = CGPoint(x: 0.5, y: 0.5)
    private final var storedSublayers: [CALayer] = []
    private final var storedBackgroundColor = _LayerColor(value: nil)
    private final var storedOpacity: Float = 1
    private final var storedHidden = false
    private final var storedMask: CALayer?
    private final weak var maskOwner: CALayer?
    private final var storedCompatibilityValues: [String: Any] = [:]
    /// iOS 26.1 (objcsurfaceprobe `## layer`): a new layer reports
    /// `needsLayout` NO, and `layoutIfNeeded` on it runs no
    /// `layoutSublayers`. A view's backing layer starts dirty (the view's
    /// first layout pass runs through it); `init(owner:)` sets that.
    private final var _needsLayout = false
    private final var _isLayingOut = false
    /// Core Animation records live in `CoreAnimation.swift`. They are kept on
    /// the portable layer rather than the transient QZLayer built for one
    /// frame, so rebuilding the renderer tree does not restart animations.
    final var _explicitAnimations: [_CALayerAnimationRecord] = []

    /// Geometry follows Core Animation's bounds/position/anchor model.
    /// A backing layer mirrors its UIView so existing view geometry remains
    /// the single source of truth.
    public final var bounds: CGRect {
        get { owner?.bounds ?? storedBounds }
        set {
            if let owner { owner.bounds = newValue }
            else if storedBounds != newValue {
                _recordImplicitAnimation(keyPath: "bounds", from: storedBounds,
                                         to: newValue)
                storedBounds = newValue
                _setNeedsLayoutFromMutation()
                superlayer?._setNeedsLayoutFromMutation()
            }
        }
    }
    public final var position: CGPoint {
        get { owner?.center ?? storedPosition }
        set {
            if let owner { owner.center = newValue }
            else if storedPosition != newValue {
                _recordImplicitAnimation(keyPath: "position", from: storedPosition,
                                         to: newValue)
                storedPosition = newValue
            }
        }
    }
    public final var anchorPoint: CGPoint {
        get { storedAnchorPoint }
        set {
            if storedAnchorPoint != newValue {
                _recordImplicitAnimation(keyPath: "anchorPoint",
                                         from: storedAnchorPoint, to: newValue)
                storedAnchorPoint = newValue
            }
        }
    }
    public final var frame: CGRect {
        get {
            if let owner { return owner.frame }
            return CGRect(x: position.x - anchorPoint.x * bounds.width,
                          y: position.y - anchorPoint.y * bounds.height,
                          width: bounds.width, height: bounds.height)
        }
        set {
            if let owner {
                owner.frame = newValue
                return
            }
            let oldBounds = storedBounds
            let oldPosition = storedPosition
            storedBounds.size = newValue.size
            storedPosition = CGPoint(x: newValue.minX + anchorPoint.x * newValue.width,
                                     y: newValue.minY + anchorPoint.y * newValue.height)
            if storedBounds != oldBounds || storedPosition != oldPosition {
                if storedBounds != oldBounds {
                    _recordImplicitAnimation(keyPath: "bounds", from: oldBounds,
                                             to: storedBounds)
                }
                if storedPosition != oldPosition {
                    _recordImplicitAnimation(keyPath: "position", from: oldPosition,
                                             to: storedPosition)
                }
                _setNeedsLayoutFromMutation()
                superlayer?._setNeedsLayoutFromMutation()
            }
        }
    }

    /// Explicit Core Animation children. UIKit exposes nil, rather than an
    /// empty array, when a layer has no children.
    public final var sublayers: [CALayer]? {
        get { storedSublayers.isEmpty ? nil : storedSublayers }
        set {
            for child in storedSublayers where child.superlayer === self {
                child.superlayer = nil
            }
            storedSublayers.removeAll(keepingCapacity: true)
            for child in newValue ?? [] { _insertSublayer(child, at: storedSublayers.count) }
            _setNeedsLayoutFromMutation()
        }
    }
    public private(set) final weak var superlayer: CALayer?

    /// The exact ordered storage used by the render pipelines (unlike the
    /// public UIKit-shaped optional, this never allocates an Optional array).
    final var _orderedSublayers: [CALayer] { storedSublayers }

    public final func addSublayer(_ layer: CALayer) {
        _insertSublayer(layer, at: storedSublayers.count)
    }

    public final func insertSublayer(_ layer: CALayer, at index: UInt32) {
        _insertSublayer(layer, at: Swift.min(Int(index), storedSublayers.count))
    }

    private final func _insertSublayer(_ layer: CALayer, at index: Int) {
        // Reject self and ancestor insertion. Without this guard a malformed
        // graph would recurse forever in both render pipelines.
        var ancestor: CALayer? = self
        while let candidate = ancestor {
            if candidate === layer { return }
            ancestor = candidate.superlayer
        }
        if let owner = layer.maskOwner {
            owner.storedMask = nil
            layer.maskOwner = nil
        }
        layer.removeFromSuperlayer()
        layer.superlayer = self
        storedSublayers.insert(layer, at: Swift.max(0, Swift.min(index, storedSublayers.count)))
        _setNeedsLayoutFromMutation()
    }

    public final func removeFromSuperlayer() {
        guard let parent = superlayer else { return }
        parent.storedSublayers.removeAll { $0 === self }
        superlayer = nil
        parent._setNeedsLayoutFromMutation()
    }

    /// Core Animation's colour properties speak CoreGraphics' `CGColor`
    /// (cg-unify); the renderer reads the `_…Value` twins, which hold its
    /// value colour, so no frame converts.
    /// MEASURED iOS 26.1 (cgunifyprobe `## layer`): the colour object
    /// assigned is the one read back (its colour space included), a backing
    /// layer reports its view's `UIColor.cgColor`, and a new layer's
    /// border and shadow colours are opaque black in `kCGColorSpaceSRGB`.
    public final var backgroundColor: CGColor? {
        get {
            if let owner {
                return owner.backgroundColor?._cgColorObject(with: owner.traitCollection)
            }
            return storedBackgroundColor.cgColor
        }
        set {
            if let owner {
                owner.backgroundColor = newValue.map { UIColor(cgColor: $0) }
            } else {
                storedBackgroundColor.set(newValue)
            }
        }
    }
    public final var borderColor: CGColor? {
        get { storedBorderColor.cgColor }
        set { storedBorderColor.set(newValue) }
    }
    public final var shadowColor: CGColor? {
        get { storedShadowColor.cgColor }
        set { storedShadowColor.set(newValue) }
    }
    private final var storedBorderColor = _LayerColor(object: CanvasColor._layerDefaultBlack)
    private final var storedShadowColor = _LayerColor(object: CanvasColor._layerDefaultBlack)

    final var _backgroundColorValue: CanvasColor? {
        get {
            if let owner {
                return owner.backgroundColor?.resolvedCGColor(with: owner.traitCollection)
            }
            return storedBackgroundColor.value
        }
        set {
            if let owner {
                owner.backgroundColor = newValue.map {
                    UIColor(red: $0.red, green: $0.green, blue: $0.blue, alpha: $0.alpha)
                }
            } else {
                storedBackgroundColor.value = newValue
            }
        }
    }
    public final var opacity: Float {
        get { owner.map { Float($0.alpha) } ?? storedOpacity }
        set {
            if let owner { owner.alpha = CGFloat(newValue) }
            else { storedOpacity = newValue }
        }
    }
    public final var isHidden: Bool {
        get { owner?.isHidden ?? storedHidden }
        set {
            if let owner { owner.isHidden = newValue }
            else { storedHidden = newValue }
        }
    }
    public final var cornerRadius: CGFloat = 0 {
        didSet {
            if cornerRadius != oldValue {
                owner?.recordAnimation(.cornerRadius, from: .scalar(oldValue),
                                       to: .scalar(cornerRadius))
            }
        }
    }
    /// Per-corner radii installed by `UIView.cornerConfiguration`. Non-nil
    /// radii win over `cornerRadius` (measured: `cornerRadius = 30` after
    /// a fixed-8 configuration still renders 8; UICornerConfiguration.swift).
    final var _cornerRadii: _CACornerRadii?
    /// Stored only; see `CALayerCornerCurve` (CoreAnimation.swift).
    public final var cornerCurve: CALayerCornerCurve = .circular
    private final var storedMaskedCorners: CACornerMask = ._allKnown
    /// Selects which corners receive `cornerRadius`. Unknown raw-value bits
    /// are discarded, matching iOS 26 Core Animation.
    public final var maskedCorners: CACornerMask {
        get { storedMaskedCorners }
        set { storedMaskedCorners = newValue.intersection(._allKnown) }
    }
    public final var borderWidth: CGFloat = 0 {
        didSet {
            if borderWidth != oldValue {
                _recordImplicitAnimation(keyPath: "borderWidth",
                                         from: oldValue, to: borderWidth)
            }
        }
    }
    final var _borderColorValue: CanvasColor? {
        get { storedBorderColor.value }
        set { storedBorderColor.value = newValue }
    }
    public final var masksToBounds: Bool = false
    /// Core Animation's opaque-content optimization hint. It does not alter
    /// composited pixels by itself; renderers may use it to skip alpha work
    /// once they can prove the layer's contents are opaque.
    public final var isOpaque: Bool = false
    /// Scale of the layer's backing contents. OpenUIKit's UIView renderer
    /// derives its raster scale from the host surface, but this public state
    /// is retained because app and framework code configures it directly.
    public final var contentsScale: CGFloat = 1
    /// Filters attached to this exact layer identity. QuartzCore's portable
    /// module re-exports CALayer rather than wrapping it, so assignments made
    /// through either module spelling reach this single storage location.
    public final var filters: [Any]?
    /// An alpha mask is retained by the receiving layer but is not a
    /// sublayer. The CQuartz compositor renders its full layer tree into an
    /// alpha surface, matching Core Animation's ownership and paint model.
    public final var mask: CALayer? {
        get { storedMask }
        set {
            guard newValue !== self, storedMask !== newValue else { return }
            let oldMask = storedMask
            storedMask = nil
            oldMask?.maskOwner = nil

            if let previousOwner = newValue?.maskOwner {
                previousOwner.storedMask = nil
            }
            newValue?.removeFromSuperlayer()
            storedMask = newValue
            newValue?.maskOwner = self
        }
    }
    /// Core Animation treats this as a rendering-policy hint; it does not
    /// alter pixels or scheduling, which is also true for this deterministic
    /// software renderer.
    public final var drawsAsynchronously: Bool = false
    // Shadow (spec v2) — CALayer defaults: opaque black, opacity 0 (off),
    // offset (0, -3) (up, in iOS's top-left geometry), radius 3.
    // Invisible while masksToBounds is true, like CoreAnimation.
    final var _shadowColorValue: CanvasColor? {
        get { storedShadowColor.value }
        set { storedShadowColor.value = newValue }
    }
    public final var shadowOpacity: Float = 0 {
        didSet {
            if shadowOpacity != oldValue {
                _recordImplicitAnimation(keyPath: "shadowOpacity",
                                         from: oldValue, to: shadowOpacity)
            }
        }
    }
    public final var shadowOffset: CGSize = CGSize(width: 0, height: -3) {
        didSet {
            if shadowOffset != oldValue {
                _recordImplicitAnimation(keyPath: "shadowOffset",
                                         from: oldValue, to: shadowOffset)
            }
        }
    }
    public final var shadowRadius: CGFloat = 3 {
        didSet {
            if shadowRadius != oldValue {
                _recordImplicitAnimation(keyPath: "shadowRadius",
                                         from: oldValue, to: shadowRadius)
            }
        }
    }

    /// Core Animation caches the layer's rendered content as a bitmap when
    /// this is set. OpenUIKit's compositor rebuilds the layer tree every
    /// frame and has no such cache, so this is faithful round-trip storage
    /// and nothing else — the drawn result is identical either way.
    /// Kickstarter-Prelude's `CALayerProtocol` requires it (`Lens` #9).
    public final var shouldRasterize = false
    /// Companion to `shouldRasterize` (CALayer.h). Same storage-only status.
    public final var rasterizationScale: CGFloat = 1

#if _runtime(_ObjC)
    // With the Objective-C runtime the class is vtable-free (an Objective-C
    // app may subclass it, see ObjCSurface.swift): no required initializer.
    // A view creates its backing layer with an Objective-C `-init` sent to
    // `+layerClass` (`_makeBackingLayer`), which reaches an Objective-C
    // subclass's `-init` as UIKit does (objcsurfaceprobe `## layersubclass`).
    public override init() {}
    public convenience init(owner: UIView) {
        self.init()
        _adoptOwner(owner)
    }
#else
    public override init() {}
    public required init(owner: UIView) {
        self.owner = owner
        super.init()
        self.delegate = owner
        _needsLayout = true
    }
#endif

    /// Makes the receiver `owner`'s backing layer.
    final func _adoptOwner(_ owner: UIView) {
        self.owner = owner
        self.delegate = owner
        _needsLayout = true
    }

    /// The backing layer of a view whose `+layerClass` is `type`.
    static func _makeBackingLayer(of type: CALayer.Type, owner: UIView) -> CALayer {
#if _runtime(_ObjC)
        // An Objective-C `alloc`/`init`: `NSObject.Type.init()` is sent as a
        // message, and the conversion to the class object it performs accepts
        // both a Swift class and the wrapper metadata Swift uses for an
        // Objective-C subclass. The metatype is reinterpreted, never boxed:
        // `type as AnyObject` retains the wrapper as if it were an object
        // (MEASURED SIGSEGV in swift_unknownObjectRelease at 0x320 for an
        // Objective-C `+layerClass`).
        let layer = unsafeBitCast(type, to: NSObject.Type.self).init()
        guard let layer = layer as? CALayer else { return CALayer(owner: owner) }
        layer._adoptOwner(owner)
        return layer
#else
        return type.init(owner: owner)
#endif
    }

    isolated deinit {
        for record in _explicitAnimations {
            _OUKTransaction._removeAnimation(workID: record.workID)
        }
    }

    // MARK: Bounded key-value compatibility

    /// Retain dynamically addressed Core Animation properties used by
    /// open-source visual-effect implementations. This is deliberately a
    /// CALayer-owned compatibility surface rather than a pretend NSObject
    /// runtime: known public properties remain strongly typed above, while
    /// private filter inputs retain their exact values under their keys.
    final func _openSetValue(_ value: Any?, forKey key: String) {
        switch key {
        case "isOpaque":
            if let value = value as? Bool { isOpaque = value }
        case "contentsScale":
            if let value = value as? CGFloat { contentsScale = value }
        default:
            if let value {
                storedCompatibilityValues[key] = value
            } else {
                storedCompatibilityValues.removeValue(forKey: key)
            }
        }
    }

    final func _openValue(forKey key: String) -> Any? {
        switch key {
        case "isOpaque": return isOpaque
        case "contentsScale": return contentsScale
        default: return storedCompatibilityValues[key]
        }
    }

    // The four entry points below are `override`s only where the NSObject the
    // port is built on actually declares KVC as CLASS members: Darwin, where
    // they arrive from the Objective-C runtime. On the native-Linux corelibs
    // branch they live in an `extension NSObject` (which Swift will not let a
    // subclass override), and on the Foundation-hidden Mach-O guest route the
    // ObjectiveC module's root class has no KVC at all — on both the layer
    // declares them fresh. Same fail-closed shape as `awakeFromNib` above.
    //
    // The override matters on Darwin: without it, `layer.setValue(_:forKey:)`
    // from an app's open-source visual-effect code would reach NSObject's real
    // KVC and raise `undefined key`, because these layer properties are Swift
    // stored properties, not `@objc` ivars.
    //
    /// Key-path variants preserve the complete path. They cover private
    /// paths such as `filters.gaussianBlur.inputRadius` without claiming a
    /// general Objective-C KVC implementation on non-Objective-C platforms.
#if canImport(ObjectiveC) && canImport(Foundation)
    open override func setValue(_ value: Any?, forKey key: String) {
        _openSetValue(value, forKey: key)
    }
    open override func value(forKey key: String) -> Any? {
        _openValue(forKey: key)
    }
    open override func setValue(_ value: Any?, forKeyPath keyPath: String) {
        _openSetValue(value, forKey: keyPath)
    }
    open override func value(forKeyPath keyPath: String) -> Any? {
        _openValue(forKey: keyPath)
    }
#elseif _runtime(_ObjC)
    // Foundation-hidden Mach-O guest: objc4's root class has no KVC, and
    // `Any?`/`String` are not Objective-C types without Foundation, so these
    // are `final` (the class stays vtable-free for Objective-C subclasses).
    public final func setValue(_ value: Any?, forKey key: String) {
        _openSetValue(value, forKey: key)
    }
    public final func value(forKey key: String) -> Any? {
        _openValue(forKey: key)
    }
    public final func setValue(_ value: Any?, forKeyPath keyPath: String) {
        _openSetValue(value, forKey: keyPath)
    }
    public final func value(forKeyPath keyPath: String) -> Any? {
        _openValue(forKey: keyPath)
    }
#else
    open func setValue(_ value: Any?, forKey key: String) {
        _openSetValue(value, forKey: key)
    }
    open func value(forKey key: String) -> Any? {
        _openValue(forKey: key)
    }
    open func setValue(_ value: Any?, forKeyPath keyPath: String) {
        _openSetValue(value, forKey: keyPath)
    }
    open func value(forKeyPath keyPath: String) -> Any? {
        _openValue(forKey: keyPath)
    }
#endif

    /// Marks this layer's delegate/layout pass dirty.
    public final func setNeedsLayout() {
        _needsLayout = true
        owner?.needsLayout = true
    }

    /// Property-tree mutations implicitly invalidate layout, except while
    /// the receiving layer is already running its callback (Core Animation's
    /// documented recursion guard). Explicit `setNeedsLayout()` calls remain
    /// able to schedule a subsequent pass.
    private final func _setNeedsLayoutFromMutation() {
        guard !_isLayingOut else { return }
        setNeedsLayout()
    }

    public final func needsLayout() -> Bool { _needsLayout }

    /// Runs the nearest dirty ancestor first, then every dirty descendant.
    /// This mirrors the observable Core Animation contract while remaining
    /// synchronous and deterministic for portable hosts.
    public final func layoutIfNeeded() {
        var root = self
        var ancestor = superlayer
        while let candidate = ancestor, candidate._needsLayout {
            root = candidate
            ancestor = candidate.superlayer
        }
        root._layoutTreeIfNeeded()
    }

    private final func _layoutTreeIfNeeded() {
        if _needsLayout {
            _needsLayout = false
            _isLayingOut = true
            layoutSublayers()
            _isLayingOut = false
        }
        for sublayer in storedSublayers {
            sublayer._layoutTreeIfNeeded()
        }
    }

    /// Subclass override point. The default Core Animation implementation
    /// consults its delegate before any layout manager; OpenUIKit currently
    /// models that delegate path and has no CALayoutManager surface.
#if _runtime(_ObjC)
    @objc(layoutSublayers)
#endif
    open dynamic func layoutSublayers() {
        delegate?.layoutSublayers(of: self)
    }

    /// Paint the receiver and its descendants into an existing graphics
    /// context. Like Core Animation, the root's own frame/position is not
    /// applied; only its bounds contents and descendant placement are drawn.
#if canImport(CoreGraphics)
    /// UIKit's `render(in:)` into a CoreGraphics context: the port's own
    /// surface when the port made the context, else a surface over the app's
    /// bitmap context (UIGraphicsCoreGraphics.swift).
    public final func render(in context: CGContext) {
        UIGraphicsPushContext(context)
        UIGraphics.draw { render(in: $0) }
        UIGraphicsPopContext()
    }
#endif

    public final func render(in context: Canvas) {
        // iOS 26's legacy render(in:) path was measured to round all four
        // corners regardless of maskedCorners, unlike live compositing.
        if let owner {
            UIRenderer.renderView(owner, into: context,
                                  honorsMaskedCorners: false)
        } else {
            UIRenderer.renderLayer(self, into: context,
                                   honorsMaskedCorners: false)
        }
    }
}

/// One Core Animation colour property: the renderer's value colour plus the
/// CoreGraphics object an app assigned, so the object (and its colour space)
/// reads back unchanged. An internal write of the value drops the object.
struct _LayerColor {
    var value: CanvasColor? { didSet { object = nil } }
    private var object: CGColor?
    init(value: CanvasColor?) { self.value = value }
    init(object: CGColor) {
        self.value = CanvasColor(object)
        self.object = object
    }
    var cgColor: CGColor? { object ?? value?.cgColor }
    mutating func set(_ color: CGColor?) {
        value = color.map(CanvasColor.init)
        object = color
    }
}

/// Axial Core Animation gradient layer. The render pipelines route these
/// stops through the same oracle-calibrated Generic-RGB interpolation used by
/// UIGradientView (or quartz's calibrated QZGradientLayer implementation).
@preconcurrency @MainActor
public final class CAGradientLayer: CALayer {
    /// CoreGraphics colours, as Core Animation takes them (cg-unify). The
    /// renderer reads `_colorValues`.
    public var colors: [CGColor]? {
        get { storedColorObjects ?? _colorValues?.map(\.cgColor) }
        set {
            _colorValues = newValue?.map(CanvasColor.init)
            storedColorObjects = newValue
        }
    }
    private var storedColorObjects: [CGColor]?
    var _colorValues: [CanvasColor]? { didSet { storedColorObjects = nil } }
    var _locationValues: [CGFloat]? { locations }
    public var locations: [CGFloat]?
    public var startPoint = CGPoint(x: 0.5, y: 0)
    public var endPoint = CGPoint(x: 0.5, y: 1)

    public override init() { super.init() }
#if !_runtime(_ObjC)
    public required init(owner: UIView) { super.init(owner: owner) }
#endif
}

#endif
/// Internal hierarchy policy for UIKit containers whose public contract does
/// not permit arbitrary direct children. UIView's public insertion methods
/// consult it; framework implementation paths can install private children
/// through the scoped bypasses below.
@MainActor
protocol _UIViewSubviewAdmission: AnyObject {
    func validateSubviewInsertion(_ view: UIView)
}

// Objective-C runtime name = UIKit's, and header macro SWIFT_CLASS_NAMED:
// Objective-C app classes may subclass it (vtable-free, see
// ObjCSubclassing.swift).
#if OPENUIKIT_OBJC_SUBCLASSING
@objc(UIView)
#endif
@preconcurrency @MainActor
open class UIView: UIResponder, CALayerDelegate {
    /// Process-wide base-view appearance proxy. New views inherit explicitly
    /// configured values; inherited defaults remain live through the normal
    /// superview chain. A construction guard prevents the proxy from trying
    /// to inherit from itself.
    private static var _appearanceProxy: UIView?
    private static var _constructingAppearanceProxy = false

#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    public class dynamic func appearance() -> Self {
        precondition(
            self == UIView.self,
            "UIView subclasses with appearance-customizable properties must provide their own proxy"
        )
        if let proxy = _appearanceProxy { return proxy as! Self }
        _constructingAppearanceProxy = true
        let proxy = UIView(frame: .zero)
        _constructingAppearanceProxy = false
        _appearanceProxy = proxy
        return proxy as! Self
    }
    // Geometry: center/bounds/transform are source of truth (like real UIKit).
    public final var center: CGPoint = .zero {
        didSet {
            if center != oldValue {
                recordAnimation(.position, from: .point(oldValue), to: .point(center))
            }
        }
    }
#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    open dynamic var bounds: CGRect = .zero {
        didSet {
            if bounds != oldValue {
                recordAnimation(.bounds, from: .rect(oldValue), to: .rect(bounds))
            }
            if oldValue.size != bounds.size {
                setNeedsLayout()
                _autoresizeChildren(oldSize: oldValue.size)
                // MEASURED signallastrowsprobe: a `.capsule()` view resized
                // 100×40 → 200×60 renders radius 30, so the configuration
                // re-resolves with the bounds (UICornerConfiguration.swift).
                if !_cornerConfiguration.isUnspecified { _resolveCornerConfiguration() }
            }
        }
    }
    /// Backing store for `cornerConfiguration` (UICornerConfiguration.swift).
    final var _cornerConfiguration: UICornerConfiguration = .unspecified
    public final var transform: CGAffineTransform = .identity {
        didSet {
            if transform != oldValue {
                recordAnimation(.transform, from: .transform(oldValue),
                                to: .transform(transform))
            }
        }
    }

    /// Animations recorded by UIView.animate blocks (M6). LayerBridge
    /// samples these at OpenUIKitRuntime.animationTime to build the
    /// presentation layer tree; the stored properties above are the MODEL.
    final var animations: [UIViewAnimation] = []

    // MARK: Layer-contents caching (M8 perf — see LayerBridge.swift)

    /// Monotone version of this view's CUSTOM drawn content (drawContent).
    /// OpenUIKit's own content views (UILabel, UISwitch, …) are fingerprinted
    /// property-by-property by LayerBridge; a custom view outside OpenUIKit
    /// that draws state in `drawContent` must call `setNeedsDisplay()` when
    /// that state changes (the same contract as real UIKit) or cached layer
    /// contents may go stale.
    final var contentVersion: UInt64 = 0

    /// Mark this view's custom-drawn content as needing a redraw (UIKit
    /// semantics). Cheap: bumps a version consumed by the render caches.
    public final func setNeedsDisplay() { contentVersion &+= 1 }

    /// LayerBridge's per-view cache storage (content image, subtree
    /// composite, fingerprint stability). Opaque here to keep the view
    /// model free of compositor types.
    final var _layerCacheState: AnyObject?

    /// Overridable, as in UIKit (NetNewsWire ImageScrollView overrides it).
#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    open dynamic var frame: CGRect {
        get {
            if transform.isIdentity {
                return CGRect(x: center.x - bounds.width / 2, y: center.y - bounds.height / 2,
                              width: bounds.width, height: bounds.height)
            }
            // bbox of bounds transformed about center
            let half = CGRect(x: -bounds.width / 2, y: -bounds.height / 2,
                              width: bounds.width, height: bounds.height)
            let bbox = half.applying(transform)
            return bbox.offsetBy(dx: center.x, dy: center.y)
        }
        set {
            // UIKit: under a pure (axis-aligned) scale the frame is still
            // meaningful and setting it sizes the BOUNDS so that the
            // transformed box equals the new frame — a sheet scaled by
            // 377/393 given frame width 377 keeps bounds width 393 (measured
            // 2026-09-04: iOS 26 floating sheet card, UIDropShadowView frame
            // [8, 482.349, 377, 361.651] with bounds 393x377). Any other
            // transform keeps the old "size as given" behaviour.
            var size = newValue.size
            if !transform.isIdentity, transform.b == 0, transform.c == 0,
               transform.a != 0, transform.d != 0 {
                size = CGSize(width: newValue.width / abs(transform.a),
                              height: newValue.height / abs(transform.d))
            }
            bounds.size = size
            center = CGPoint(x: newValue.origin.x + newValue.width / 2,
                             y: newValue.origin.y + newValue.height / 2)
        }
    }

    // MEASURED EidolonTap (iPhone 16 / iOS 26.1) and UIKit Mac Catalyst
    // (26.1 SDK, macOS 26.5.2): a child does not retain its parent (released,
    // child.superview nil). A bare UIButton also releases with its label.
    // A strong back-reference leaked buttons and prevented RxCocoa's
    // deallocated stream from completing: 0 completions vs the oracle's 1.
    public internal(set) weak final var superview: UIView?
    public internal(set) final var subviews: [UIView] = []
    /// UIKit's `+layerClass`. GradientBackgroundView (Focus a2832521) returns
    /// CAGradientLayer.self; the lazy backing layer is that class.
    /// MEASURED `swift build --target Blockzilla` 2026-09-06: "property does
    /// not override any property from its superclass" at
    /// GradientBackgroundView.swift:29.
#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    open class dynamic var layerClass: AnyClass { CALayer.self }
    public private(set) final lazy var layer: CALayer = {
        if let type = _objcMessageable(Self.self).layerClass as? CALayer.Type {
            return CALayer._makeBackingLayer(of: type, owner: self)
        }
        return CALayer(owner: self)
    }()

    public final var backgroundColor: UIColor? {
        didSet {
            if backgroundColor != oldValue {
                recordAnimation(.backgroundColor, from: .color(oldValue),
                                to: .color(backgroundColor))
            }
        }
    }
    public final var alpha: CGFloat = 1 {
        didSet {
            if alpha != oldValue {
                recordAnimation(.alpha, from: .scalar(oldValue), to: .scalar(alpha))
            }
        }
    }
    /// Portable compositor hooks used by SwiftUI's brightness/saturation
    /// modifiers. They apply to the completed subtree as a single group,
    /// preserving descendant alpha and overlap exactly like a layer filter.
    public final var _openUIKitBrightness: CGFloat = 0 {
        didSet { if _openUIKitBrightness != oldValue { setNeedsDisplay() } }
    }
    public final var _openUIKitSaturation: CGFloat = 1 {
        didSet { if _openUIKitSaturation != oldValue { setNeedsDisplay() } }
    }
    public final var isHidden = false
    public final var isOpaque = true
    /// iOS 26 liquid-glass chrome (tab-bar / toolbar / bar-button platters,
    /// floating sheet). The Canvas backdrop-filter path applies
    /// `_UIGlassMaterial`; Catalyst ignores the flag.
    /// Public so the SwiftUI module can set it (`.glassEffect` on the iOS cut).
    public final var _usesIOSGlass = false
    /// Which measured glass mix `_UIGlassMaterial` applies. Bar platters
    /// keep `.platter`. Pad popovers are two other mixes (content vs
    /// action-sheet) — they do not share α with the platter or each other.
    final var _iosGlassKind: _UIGlassKind = .platter
    /// Dark floating sheet only. Bar platters use `_usesIOSDarkBarGlass`
    /// (MEASURED /tmp/glass-dark-out, SE 2x: 19 over black, not the
    /// sheet's 57). The sheet's systemBackground fill tracks the dimmed
    /// backdrop (MEASURED /tmp/sheetfill_dark, SE 2x).
    final var _usesIOSDarkGlass = false
    /// Dark tab-bar / toolbar platters. Distinct from the floating-sheet
    /// mix; nav-bar platters keep the measured dark flats + refraction.
    final var _usesIOSDarkBarGlass = false
    /// Clip path for `_UIGlassMaterial`. Bar platters are capsules; the
    /// floating sheet overrides with independent top/bottom radii.
    ///
    /// Vtable-free (OPENUIKIT_OBJC_SUBCLASSING): `Path` is not an
    /// Objective-C type, so the one override (the floating sheet) is reached
    /// by a type check instead of a Swift vtable slot.
    final func _iosGlassPath(in bounds: CGRect) -> Path {
        if let sheet = self as? _UIPageSheetView { return sheet._sheetGlassPath(in: bounds) }
        return UIRenderer.layerRoundedRect(bounds, cornerRadius: layer.cornerRadius,
                                           maskedCorners: layer.maskedCorners)
    }
    /// Hit-testing / touch delivery opt-out. UIKit defaults: true for
    /// UIView/controls, false for UILabel and UIImageView.
    public final var isUserInteractionEnabled = true
    public final var clipsToBounds: Bool {
        get { layer.masksToBounds }
        set { layer.masksToBounds = newValue }
    }
    public final var contentMode: UIViewContentMode = .scaleToFill
    /// UIKit's backing-store scale for `draw(_:)`. Stored only: OpenUIKit
    /// draws view content at the destination surface's scale (cg-unify's
    /// probe sets 1 so the simulator draws at 1x like the port).
    public final var contentScaleFactor: CGFloat = OpenUIKitRuntime.imageScreenScale
    public final var tag: Int = 0

    public struct AutoresizingMask: OptionSet, Sendable {
        public let rawValue: UInt
        public init(rawValue: UInt) { self.rawValue = rawValue }
        public static let flexibleLeftMargin = AutoresizingMask(rawValue: 1 << 0)
        public static let flexibleWidth = AutoresizingMask(rawValue: 1 << 1)
        public static let flexibleRightMargin = AutoresizingMask(rawValue: 1 << 2)
        public static let flexibleTopMargin = AutoresizingMask(rawValue: 1 << 3)
        public static let flexibleHeight = AutoresizingMask(rawValue: 1 << 4)
        public static let flexibleBottomMargin = AutoresizingMask(rawValue: 1 << 5)
    }
    public final var autoresizingMask: AutoresizingMask = []
    public final var autoresizesSubviews = true

    // MARK: Auto Layout (M9 — autolayout module, AutoLayout/*.swift)

    /// UIKit semantics: while true, the view's frame is authoritative and
    /// enters the solver as required left/top/width/height constraints;
    /// constraint-positioned views set this to false.
    public final var translatesAutoresizingMaskIntoConstraints = true
    /// UIKit creates every view with a pending constraints update. The flag
    /// is cleared by `updateConstraints()` (whose overrides must call super)
    /// and is propagated to ancestors by `setNeedsUpdateConstraints()` so a
    /// root-driven pass can visit dirty descendants bottom-up.
    final var _needsUpdateConstraints = true
    /// Constraints installed on this view (nearest common ancestor of their
    /// items). Managed by NSLayoutConstraint.activate/deactivate.
    final var _installedConstraints: [NSLayoutConstraint] = []
    final var _huggingH: UILayoutPriority = .defaultLow
    final var _huggingV: UILayoutPriority = .defaultLow
    final var _compressionH: UILayoutPriority = .defaultHigh
    final var _compressionV: UILayoutPriority = .defaultHigh

    // MARK: Layout guides / safe area (app-compat cluster; the measured
    // model lives in AutoLayout/UILayoutGuide.swift, which owns every rule
    // and every constant. Only the STORAGE is here — Swift extensions cannot
    // add stored properties.)

    /// `registerForTraitChanges` bookings (UIViewCompat.swift).
    final var _traitRegistrations: [UITraitChangeRegistration] = []
    /// Backing storage for UIView's semantic layout-direction contract.
    final var _semanticContentAttribute: UISemanticContentAttribute = .unspecified

    final var _customLayoutGuides: [UILayoutGuide] = []
    final var _safeAreaGuide: UILayoutGuide?
    final var _layoutMarginsGuide: UILayoutGuide?
    final var _readableGuide: UILayoutGuide?
    /// Derived by propagation from the nearest ancestor that has its own.
    final var _safeAreaInsets: UIEdgeInsets = .zero
    /// Set by `_setSafeAreaInsets(_:)` — this view is a propagation ROOT.
    final var _ownSafeAreaInsets: UIEdgeInsets?
    /// `UIViewController.additionalSafeAreaInsets` of the controller managing
    /// this view, added on top of the inherited insets.
    final var _additionalSafeAreaInsets: UIEdgeInsets = .zero
    /// An assignment to ``layoutMargins``, which wins over the class default.
    final var _baseLayoutMarginsOverride: UIEdgeInsets?
    /// The base margins ``layoutMargins`` starts from: whatever was assigned,
    /// else the class's own default.
    final var _baseLayoutMargins: UIEdgeInsets {
        get { _baseLayoutMarginsOverride ?? _defaultBaseLayoutMargins }
        set { _baseLayoutMarginsOverride = newValue }
    }
    /// UIKit's default base margins: 8 pt on every edge. Computed rather than
    /// stored so a subclass whose margins depend on its geometry can override
    /// it and stay live as that geometry changes — `UITableViewCell`'s do,
    /// they follow the window's system margin.
    ///
    /// Vtable-free (OPENUIKIT_OBJC_SUBCLASSING): `UIEdgeInsets` is a Swift
    /// struct here, so the two overrides (the cell and its content view) are
    /// reached by type checks instead of a Swift vtable slot.
    final var _defaultBaseLayoutMargins: UIEdgeInsets {
        if let content = self as? UITableViewCellContentView { return content._contentDefaultBaseLayoutMargins }
        if let cell = self as? UITableViewCell { return cell._cellDefaultBaseLayoutMargins }
        return _viewDefaultBaseLayoutMargins
    }
    /// UIView's own default (8 pt on every edge).
    final var _viewDefaultBaseLayoutMargins: UIEdgeInsets {
        UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    }
    /// UIKit default true: `layoutMargins` = base + `safeAreaInsets`.
    public final var insetsLayoutMarginsFromSafeArea = true {
        didSet { if insetsLayoutMarginsFromSafeArea != oldValue { _notifyLayoutMarginsChanged() } }
    }
    /// UIKit default false: inherit the superview's margins where they
    /// overlap this view.
    public final var preservesSuperviewLayoutMargins = false {
        didSet { if preservesSuperviewLayoutMargins != oldValue { _notifyLayoutMarginsChanged() } }
    }

    /// Called after ``safeAreaInsets`` changes. Override to react; the
    /// default does nothing, like UIKit's. (Declared in the class body, not
    /// the guide extension: a non-@objc extension method cannot be
    /// overridden.)
#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    open dynamic func safeAreaInsetsDidChange() {}

    /// Called after ``layoutMargins`` changes.
#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    open dynamic func layoutMarginsDidChange() {}

    /// Hierarchy lifecycle override points. OpenUIKit delivers window changes
    /// to the complete moved subtree, with `window` already reflecting the
    /// new hierarchy when `didMoveToWindow()` runs. Moving between two
    /// superviews in the same window does not manufacture a window change.
#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    open dynamic func willMove(toSuperview newSuperview: UIView?) {}
#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    open dynamic func didMoveToSuperview() {}
#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    open dynamic func willMove(toWindow newWindow: UIWindow?) {}
#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    open dynamic func didMoveToWindow() {}

    /// Legacy trait callback retained by UIKit for source compatibility.
    /// Host-driven trait changes call this once per view after matching modern
    /// registrations have fired. Subclasses may intentionally omit `super`.
#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    open dynamic func traitCollectionDidChange(
        _ previousTraitCollection: UITraitCollection?
    ) {}

    /// Baseline offsets for firstBaseline/lastBaseline constraint attributes:
    /// (first baseline from the view's top, last baseline from its bottom).
    /// nil (plain views): both baselines alias the bottom edge, like UIKit.
    /// UILabel overrides (text module hook).
    /// Vtable-free (OPENUIKIT_OBJC_SUBCLASSING): a tuple is not an
    /// Objective-C type, so UILabel's override is reached by a type check.
    final func _constraintBaselines() -> (firstFromTop: CGFloat, lastFromBottom: CGFloat)? {
        if let label = self as? UILabel { return label._labelConstraintBaselines() }
        return nil
    }

    /// Trait override; `.unspecified` inherits from superview / current.
    public final var overrideUserInterfaceStyle: UIUserInterfaceStyle = .unspecified
    /// iOS 17 window/view trait overrides. Mutate in place
    /// (`window.traitOverrides.preferredContentSizeCategory = .accessibilityLarge`)
    /// the way real UIKit does; unspecified inherits `UITraitCollection.current`.
    public final var traitOverrides = UITraitOverrides()
    /// `open`, as UIKit declares it: pocket-casts' TintableImageView overrides
    /// it to re-tint its image on assignment.
#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    open dynamic var tintColor: UIColor! {
        get { _tintColor ?? superview?.tintColor ?? .systemBlue }
        set { _tintColor = newValue }
    }
    final var _tintColor: UIColor?

#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    public dynamic init(frame: CGRect) {
        super.init()
        if !UIView._constructingAppearanceProxy {
            _tintColor = UIView._appearanceProxy?._tintColor
            // MEASURED /tmp/rtlprobe, iPhone SE 2x / iOS 26.1:
            // `UIView.appearance().semanticContentAttribute = .forceRightToLeft`
            // stamps every subsequently constructed UIView (74/76 views
            // dump `uiDir=rtl`). Window-only assignment stamps the window
            // (1/76) and does not propagate — `effectiveUserInterfaceLayoutDirection`
            // of an unspecified child stays LTR (UIButtonTests).
            if let proxy = UIView._appearanceProxy,
               proxy._semanticContentAttribute != .unspecified {
                _semanticContentAttribute = proxy._semanticContentAttribute
            }
        }
        self.frame = frame
    }

    /// UIKit exposes a real zero-argument convenience initializer in addition
    /// to `init(frame:)`.  It cannot be modeled as a default argument on the
    /// designated frame initializer: default arguments are not inherited when
    /// a subclass overrides `init(frame:)`, while convenience initializers are.
    public convenience override init() {
        self.init(frame: .zero)
    }

    /// UIKit's keyed-archive initializer. Given the `UINibCoder` a nib or
    /// storyboard hands an archived view (UINibCoder.swift), it decodes the
    /// archived geometry, colours, flags, subviews and constraints into
    /// `self` before returning — so an app's `init(coder:)` body after
    /// `super.init(coder:)` sees them, as on iOS (MEASURED,
    /// Tools/oracle2/nibruntimeprobe `badgeAtInit`). Any other coder is not
    /// consulted: the view starts with zero geometry, as before.
#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    public required dynamic init?(coder: NSCoder) {
        super.init()
        self.frame = .zero
        UINibCoder.decodeViewState(self, from: coder)
    }

    /// UIKit's NSObject description is a live diagnostic of the concrete
    /// view identity and geometry. Keeping the dynamic class name first is
    /// important to unchanged code which distinguishes private visual-effect
    /// hierarchy nodes by their description. UIView is main-thread-only; the
    /// inherited NSObject requirement is nonisolated, so make that existing
    /// contract explicit at this single synchronous boundary.
    nonisolated private final var _openDescription: String {
        let className = String(describing: type(of: self))
        let identity = Unmanaged.passUnretained(self).toOpaque()
        return MainActor.assumeIsolated {
            "<\(className): \(identity); frame = \(frame); bounds = \(bounds)>"
        }
    }

#if canImport(Foundation)
    /// Foundation's NSObject declares `description`, so the Darwin/host
    /// surface is a genuine override.
    nonisolated open override var description: String { _openDescription }
#else
    /// The guest ObjectiveC NSObject deliberately has no Foundation
    /// description property. Keep UIView's UIKit surface without claiming a
    /// nonexistent override; statically typed UIView callers (including
    /// unchanged applications) see the same public member.
#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    nonisolated open dynamic var description: String { _openDescription }
#endif

    // MARK: Hierarchy
    public final func addSubview(_ view: UIView) {
        (self as? _UIViewSubviewAdmission)?.validateSubviewInsertion(view)
        _addSubviewWithoutAdmissionCheck(view)
    }

    /// Framework containers with a restricted public hierarchy use this
    /// path to install their own implementation views. It intentionally is
    /// not public: app calls still pass through the admission check above.
    final func _addSubviewWithoutAdmissionCheck(_ view: UIView) {
        guard view !== self else { return }
        if view.superview === self {
            bringSubviewToFront(view)
            return
        }
        let oldWindow = view.window
        let newWindow = window
        view.willMove(toSuperview: self)
        if oldWindow !== newWindow {
            view._willMoveSubtree(toWindow: newWindow)
        }
        view._detachFromSuperviewWithoutCallbacks()
        view.superview = self
        subviews.append(view)
        // A newly attached view starts with a pending constraints update.
        // Re-issuing the invalidation after assigning `superview` propagates
        // that pending work to this hierarchy's root.
        view.setNeedsUpdateConstraints()
        setNeedsLayout()
        view.didMoveToSuperview()
        if oldWindow !== newWindow {
            view._didMoveSubtreeToWindow()
        }
    }

    public final func insertSubview(_ view: UIView, at index: Int) {
        (self as? _UIViewSubviewAdmission)?.validateSubviewInsertion(view)
        _insertSubviewWithoutAdmissionCheck(view, at: index)
    }

    /// Insert `view` immediately below an existing child. UIKit requires the
    /// sibling to belong to this receiver; fail at the call site rather than
    /// silently inventing an ordering for an unrelated view.
    public final func insertSubview(_ view: UIView, belowSubview siblingSubview: UIView) {
        guard siblingSubview.superview === self else {
            preconditionFailure("belowSubview must be a subview of the receiver")
        }
        guard view !== siblingSubview else { return }
        let index = subviews.firstIndex(where: { $0 === siblingSubview })!
        insertSubview(view, at: index)
    }

    /// Insert `view` immediately above an existing child.
    public final func insertSubview(_ view: UIView, aboveSubview siblingSubview: UIView) {
        guard siblingSubview.superview === self else {
            preconditionFailure("aboveSubview must be a subview of the receiver")
        }
        guard view !== siblingSubview else { return }
        let index = subviews.firstIndex(where: { $0 === siblingSubview })!
        insertSubview(view, at: index + 1)
    }

    /// Internal twin of `_addSubviewWithoutAdmissionCheck(_:)` for ordered
    /// implementation children.
    final func _insertSubviewWithoutAdmissionCheck(_ view: UIView, at index: Int) {
        guard view !== self else { return }
        if view.superview === self {
            guard let oldIndex = subviews.firstIndex(where: { $0 === view }) else { return }
            subviews.remove(at: oldIndex)
            let adjustedIndex = oldIndex < index ? index - 1 : index
            subviews.insert(view, at: Swift.max(0, Swift.min(adjustedIndex, subviews.count)))
            setNeedsLayout()
            return
        }
        let oldWindow = view.window
        let newWindow = window
        view.willMove(toSuperview: self)
        if oldWindow !== newWindow {
            view._willMoveSubtree(toWindow: newWindow)
        }
        view._detachFromSuperviewWithoutCallbacks()
        view.superview = self
        subviews.insert(view, at: Swift.max(0, Swift.min(index, subviews.count)))
        view.setNeedsUpdateConstraints()
        setNeedsLayout()
        view.didMoveToSuperview()
        if oldWindow !== newWindow {
            view._didMoveSubtreeToWindow()
        }
    }
    public final func removeFromSuperview() {
        guard superview != nil else { return }
        let oldWindow = window
        willMove(toSuperview: nil)
        if oldWindow != nil { _willMoveSubtree(toWindow: nil) }
        let formerSuperview = superview
        _detachFromSuperviewWithoutCallbacks()
        formerSuperview?.setNeedsLayout()
        didMoveToSuperview()
        if oldWindow != nil { _didMoveSubtreeToWindow() }
    }

    private final func _detachFromSuperviewWithoutCallbacks() {
        guard let currentSuperview = superview else { return }
        currentSuperview.subviews.removeAll { $0 === self }
        superview = nil
    }

    private final func _willMoveSubtree(toWindow newWindow: UIWindow?) {
        willMove(toWindow: newWindow)
        for subview in subviews {
            subview._willMoveSubtree(toWindow: newWindow)
        }
    }

    private final func _didMoveSubtreeToWindow() {
        didMoveToWindow()
        for subview in subviews {
            subview._didMoveSubtreeToWindow()
        }
    }

    /// Whether the receiver is the supplied view or lies below it in the
    /// view hierarchy (UIKit includes identity in this predicate).
#if OPENUIKIT_OBJC_SUBCLASSING
    @objc(isDescendantOfView:)
#endif
    open dynamic func isDescendant(of view: UIView) -> Bool {
        var candidate: UIView? = self
        while let current = candidate {
            if current === view { return true }
            candidate = current.superview
        }
        return false
    }

    /// Ask the first responder in this view's subtree to resign.
    ///
    /// iOS 26.1's measured `force` behavior is subtler than the SDK header's
    /// “optionally force” shorthand: UIKit still gives the responder (and
    /// therefore its text delegate) the opportunity to refuse; `true` changes
    /// the RETURN VALUE to true but leaves focus/editing untouched and sends
    /// no did-end callback. An active responder outside the receiver's
    /// subtree returns false for either force value. With no active responder,
    /// the operation is already satisfied and returns true.
#if canImport(ObjectiveC)
    @objc(endEditing:)
#endif
    @discardableResult
    open dynamic func endEditing(_ force: Bool) -> Bool {
        guard let window else { return true }
        guard let responder = window.firstResponder else { return true }
        guard let responderView = responder as? UIView,
              responderView.isDescendant(of: self) else { return false }
        if force {
            // Measured UIKit calls the responder once, then reports success
            // even when that call refuses to end editing.
            _ = responder.resignFirstResponder()
            return true
        }
        // The non-force path first checks eligibility, then performs the
        // resignation. A permissive text delegate is consequently asked
        // twice; a refusing one is asked once (iOS 26.1 behavior).
        guard responder.canResignFirstResponder else { return false }
        return responder.resignFirstResponder()
    }

    public final func bringSubviewToFront(_ view: UIView) {
        guard let i = subviews.firstIndex(where: { $0 === view }) else { return }
        subviews.remove(at: i)
        subviews.append(view)
    }
    public final func sendSubviewToBack(_ view: UIView) {
        guard let i = subviews.firstIndex(where: { $0 === view }) else { return }
        subviews.remove(at: i)
        subviews.insert(view, at: 0)
    }

    /// Capture the receiver's current laid-out presentation as a static image
    /// view. The portable renderer has no private live snapshot layer, so the
    /// returned view intentionally remains unchanged when the source changes.
    public final func snapshotView(afterScreenUpdates afterUpdates: Bool) -> UIView? {
        _ = afterUpdates
        guard bounds.width > 0, bounds.height > 0 else { return nil }
        layoutIfNeeded()
        let scale = max(1, window?.windowScene?.screen.scale ?? UIScreen.main.scale)
        let bitmap = UIRenderer.render(self, scale: scale)
        guard bitmap.width > 0, bitmap.height > 0 else { return nil }
        let snapshot = UIImageView(image: UIImage(bitmap: bitmap, scale: scale))
        snapshot.frame = CGRect(origin: .zero, size: bounds.size)
        return snapshot
    }

    // MARK: Traits
    /// The semantic direction of this view's immediate content. OpenUIKit's
    /// unspecified value resolves against its process-wide LTR fallback;
    /// playback and spatial controls deliberately remain left-to-right.
#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    open dynamic var semanticContentAttribute: UISemanticContentAttribute {
        get { _semanticContentAttribute }
        set {
            guard newValue != _semanticContentAttribute else { return }
            _semanticContentAttribute = newValue
            setNeedsLayout()
        }
    }

#if OPENUIKIT_OBJC_SUBCLASSING
    @objc(userInterfaceLayoutDirectionForSemanticContentAttribute:)
#endif
    open class dynamic func userInterfaceLayoutDirection(
        for semanticContentAttribute: UISemanticContentAttribute
    ) -> UIUserInterfaceLayoutDirection {
        userInterfaceLayoutDirection(for: semanticContentAttribute,
                                     relativeTo: .leftToRight)
    }

#if OPENUIKIT_OBJC_SUBCLASSING
    @objc(userInterfaceLayoutDirectionForSemanticContentAttribute:relativeToLayoutDirection:)
#endif
    open class dynamic func userInterfaceLayoutDirection(
        for semanticContentAttribute: UISemanticContentAttribute,
        relativeTo layoutDirection: UIUserInterfaceLayoutDirection
    ) -> UIUserInterfaceLayoutDirection {
        switch semanticContentAttribute {
        case .unspecified:
            return layoutDirection
        case .playback, .spatial, .forceLeftToRight:
            return .leftToRight
        case .forceRightToLeft:
            return .rightToLeft
        }
    }

    /// Direction appropriate for arranging this view's immediate content.
    /// UIKit does not propagate semantic content attributes through a view
    /// subtree. OpenUIKit has no process-wide UIApplication locale yet, so
    /// each unspecified view resolves against an LTR application fallback.
#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    open dynamic var effectiveUserInterfaceLayoutDirection: UIUserInterfaceLayoutDirection {
        _objcMessageable(type(of: self)).userInterfaceLayoutDirection(for: semanticContentAttribute)
    }

    /// Whether this view arranges its own content right-to-left.
    /// Unspecified still resolves LTR (UIButtonTests: a child of an RTL
    /// parent does not inherit).
    final var _layoutIsRTL: Bool {
        effectiveUserInterfaceLayoutDirection == .rightToLeft
    }

#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    open dynamic var traitCollection: UITraitCollection {
        // UIKit supplies a complete environment even before a view joins a
        // hierarchy. OpenUIKit's process-wide collection may intentionally
        // leave size axes unspecified for the host surface to resolve, so a
        // detached view completes just those axes from UIScreen's bounds
        // rather than exposing placeholders to initializers/viewDidLoad.
        let t = superview?.traitCollection ?? UIScreen.main._currentTraitsResolvingSizeClasses
        // A controller's own override applies to its root view (and so its
        // subtree) unless the view overrides the style itself.
        var style = overrideUserInterfaceStyle
        if style == .unspecified, let controller = _managingViewController,
           controller.viewIfLoaded === self {
            style = controller.overrideUserInterfaceStyle
        }
        let category = traitOverrides.preferredContentSizeCategory
        if style == .unspecified && category == .unspecified { return t }
        return t._with { t in
            if style != .unspecified {
                t.userInterfaceStyle = style
            }
            if category != .unspecified {
                t.preferredContentSizeCategory = category
            }
        }
    }

    // MARK: Layout
    final var needsLayout = true
    public final func setNeedsLayout() {
        needsLayout = true
        layer.setNeedsLayout()
    }

    /// Schedule the receiver's update-constraints callback for the next
    /// layout pass. UIKit propagates this dirtiness to the hierarchy root:
    /// invalidating a child and laying out the root updates the child first,
    /// then the ancestors, and finally lays out the root.
#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    open dynamic func setNeedsUpdateConstraints() {
        _needsUpdateConstraints = true
        var top = self
        var ancestor = superview
        while let current = ancestor {
            current._needsUpdateConstraints = true
            top = current
            ancestor = current.superview
        }
        // Measured UIKit behavior: a constraints invalidation schedules the
        // root layout, not a standalone layoutSubviews call on the child.
        top.setNeedsLayout()
    }

#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    open dynamic func needsUpdateConstraints() -> Bool { _needsUpdateConstraints }

    /// Run a bottom-up constraints update for the hierarchy rooted here.
    /// A view-controller-managed root dispatches to the controller in lieu
    /// of calling the root view directly; UIViewController's base method then
    /// sends `updateConstraints()` to the view, matching UIKit's documented
    /// separation-of-concerns hook.
#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    open dynamic func updateConstraintsIfNeeded() {
        _updateConstraintsSubtreeIfNeeded()
    }

    final func _updateConstraintsSubtreeIfNeeded() {
        for subview in subviews {
            subview._updateConstraintsSubtreeIfNeeded()
        }
        guard _needsUpdateConstraints else { return }
        if let controller = _managingViewController,
           controller.viewIfLoaded === self {
            controller.updateViewConstraints()
        } else {
            updateConstraints()
        }
    }

    /// Override point for constraint creation/adjustment. Overrides must call
    /// super; the base implementation clears the pending-update flag. This
    /// also gives direct calls the same state transition observed on UIKit.
#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    open dynamic func updateConstraints() {
        _needsUpdateConstraints = false
    }

    public final func layoutIfNeeded() {
        // Auto Layout (M9): solve constraints for the whole hierarchy first
        // (UIKit solves in the window/root space before layoutSubviews).
        // No-op (one integer compare) when no constraints are installed.
        var top: UIView = self
        while let sv = top.superview { top = sv }
        // Constraints update bottom-up before solving and layout. A child
        // invalidation dirties its ancestors, so the controller-managed root
        // is reached after every dirty descendant.
        top._updateConstraintsSubtreeIfNeeded()
        // Safe area is a layout INPUT (it is derived from frames) and also a
        // layout OUTPUT (guides move views). UIKit resolves that by treating
        // the previous pass's safe area as this pass's input; we iterate
        // twice, which converges for every hierarchy a fixture or an app
        // builds. See AutoLayout/UILayoutGuide.swift.
        top._propagateSafeArea()
        LayoutEngine.solveIfNeeded(root: top)
        if top._propagateSafeArea() {
            LayoutEngine.solveIfNeeded(root: top)
        }
        // Layout entire subtree (top-down), like a simplified layout pass.
        _layoutSubtree()
    }
    final func _layoutSubtree() {
        if needsLayout {
            // Clear before callbacks so setNeedsLayout() from inside an
            // override schedules a subsequent pass instead of being erased.
            needsLayout = false
            let controller = _managingViewController.flatMap {
                $0.viewIfLoaded === self ? $0 : nil
            }
            controller?.viewWillLayoutSubviews()
            layer.layoutIfNeeded()  // the port's pass on Apple toolchains too (QuartzCoreUnification.swift)
            controller?.viewDidLayoutSubviews()
        }
        for s in subviews { s._layoutSubtree() }
    }
#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    open dynamic func layoutSubviews() {}

    /// CALayerDelegate entry point for this view's backing layer. UIKit routes
    /// `layoutSubviews()` through this callback; doing the same preserves the
    /// ordering seen by subclasses that override `layoutSublayers(of:)` and
    /// call `super`, including views that resize explicit gradient layers.
#if OPENUIKIT_OBJC_SUBCLASSING
    @objc(layoutSublayersOfLayer:)
#endif
    open dynamic func layoutSublayers(of layer: CALayer) {
        guard layer === self.layer else { return }
        needsLayout = false
        layoutSubviews()
    }

    final func _autoresizeChildren(oldSize: CGSize) {
        // UIKit autoresizing-mask distribution. For each axis the frame is
        // split into three components (leading margin, size, trailing margin).
        // The size delta of the superview is distributed among the FLEXIBLE
        // components proportionally to their current magnitudes; fixed
        // components never change. If every flexible component is zero, the
        // delta is split equally between them. No flexible components => the
        // child's frame is left untouched.
        guard autoresizesSubviews else { return }
        let newSize = bounds.size
        let dw = newSize.width - oldSize.width
        let dh = newSize.height - oldSize.height
        if dw == 0 && dh == 0 { return }
        for sub in subviews {
            let mask = sub.autoresizingMask
            if mask.isEmpty { continue }
            var f = sub.frame
            (f.origin.x, f.size.width) = UIView._autoresizeAxis(
                origin: f.origin.x, length: f.size.width,
                oldParent: oldSize.width, delta: dw,
                flexLead: mask.contains(.flexibleLeftMargin),
                flexSize: mask.contains(.flexibleWidth),
                flexTrail: mask.contains(.flexibleRightMargin))
            (f.origin.y, f.size.height) = UIView._autoresizeAxis(
                origin: f.origin.y, length: f.size.height,
                oldParent: oldSize.height, delta: dh,
                flexLead: mask.contains(.flexibleTopMargin),
                flexSize: mask.contains(.flexibleHeight),
                flexTrail: mask.contains(.flexibleBottomMargin))
            sub.frame = f
        }
    }

    /// One-axis autoresizing distribution. Returns (newOrigin, newLength).
    static func _autoresizeAxis(origin: CGFloat, length: CGFloat,
                                oldParent: CGFloat, delta: CGFloat,
                                flexLead: Bool, flexSize: Bool,
                                flexTrail: Bool) -> (CGFloat, CGFloat) {
        if delta == 0 { return (origin, length) }
        if !flexLead && !flexSize && !flexTrail { return (origin, length) }
        let lead = origin
        let trail = oldParent - origin - length
        var total: CGFloat = 0
        var count = 0
        if flexLead { total += lead; count += 1 }
        if flexSize { total += length; count += 1 }
        if flexTrail { total += trail; count += 1 }
        var dLead: CGFloat = 0
        var dSize: CGFloat = 0
        if total == 0 {
            // All flexible components are zero: split the delta equally.
            let each = delta / CGFloat(count)
            if flexLead { dLead = each }
            if flexSize { dSize = each }
        } else {
            if flexLead { dLead = delta * lead / total }
            if flexSize { dSize = delta * length / total }
        }
        return (origin + dLead, length + dSize)
    }

    // MARK: Sizing
#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    open dynamic func sizeThatFits(_ size: CGSize) -> CGSize { bounds.size }
#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    open dynamic var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: UIView.noIntrinsicMetric)
    }
    public static let noIntrinsicMetric: CGFloat = -1
    public final func sizeToFit() {
        // Real UIKit passes the CURRENT bounds size to sizeThatFits (a
        // multiline label with frame width 200 wraps at 200 — verified
        // against golden label_multiline). Contract fix by the text module.
        let s = sizeThatFits(bounds.size)
        let origin = frame.origin
        frame = CGRect(origin: origin, size: s)
    }

    // MARK: Coordinate conversion (event module, M7)

    /// Transform mapping this view's bounds coordinates to its superview's
    /// bounds coordinates: p_super = center + transform · (p − boundsMid).
    /// (Anchor point (0.5, 0.5): the middle of the bounds rect maps to
    /// `center`; bounds.origin shifts the content, hence the mid offset.)
    final var _toSuperview: CGAffineTransform {
        CGAffineTransform(translationX: -bounds.midX, y: -bounds.midY)
            .concatenating(transform)
            .concatenating(CGAffineTransform(translationX: center.x, y: center.y))
    }

    /// Accumulated transform from this view's coordinates to the coordinates
    /// of the hierarchy's root (the view with no superview), plus that root.
    final func _transformToRoot() -> (CGAffineTransform, UIView) {
        var t = CGAffineTransform.identity
        var v: UIView = self
        while let sv = v.superview {
            t = t.concatenating(v._toSuperview)
            v = sv
        }
        return (t, v)
    }

    /// Convert a point from this view's coordinate system to `view`'s.
    /// nil = the root of this view's hierarchy (window/root coordinates),
    /// matching UIKit's nil-window behavior.
    public final func convert(_ point: CGPoint, to view: UIView?) -> CGPoint {
        let (t, root) = _transformToRoot()
        var inRoot = point.applying(t)
        guard let view else { return inRoot }
        let (t2, root2) = view._transformToRoot()
        if root !== root2 {
            // MEASURED signalrowsprobe screen.offsetWindow, iPhone 16 / iOS
            // 26.1: across hierarchies the conversion passes through screen
            // space — a window at (10, 20) converts its subview's (8, 9) to
            // (23, 35) in the full-screen window, i.e. each window's frame
            // origin is applied. Detached roots contribute no offset.
            let from = (root as? UIWindow)?.frame.origin ?? .zero
            let to = (root2 as? UIWindow)?.frame.origin ?? .zero
            inRoot.x += from.x - to.x
            inRoot.y += from.y - to.y
        }
        return inRoot.applying(t2.inverted())
    }

    /// Convert a point from `view`'s coordinate system to this view's.
    public final func convert(_ point: CGPoint, from view: UIView?) -> CGPoint {
        if let view { return view.convert(point, to: self) }
        let (t, _) = _transformToRoot()
        return point.applying(t.inverted())
    }

    /// Converts all four corners and returns their axis-aligned bounding box,
    /// which is UIKit's CGRect behavior when either hierarchy contains a
    /// transform.
    public final func convert(_ rect: CGRect, to view: UIView?) -> CGRect {
        let corners = [
            CGPoint(x: rect.minX, y: rect.minY),
            CGPoint(x: rect.maxX, y: rect.minY),
            CGPoint(x: rect.minX, y: rect.maxY),
            CGPoint(x: rect.maxX, y: rect.maxY),
        ].map { convert($0, to: view) }
        guard let first = corners.first else { return .zero }
        let minX = corners.dropFirst().reduce(first.x) { min($0, $1.x) }
        let maxX = corners.dropFirst().reduce(first.x) { max($0, $1.x) }
        let minY = corners.dropFirst().reduce(first.y) { min($0, $1.y) }
        let maxY = corners.dropFirst().reduce(first.y) { max($0, $1.y) }
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    public final func convert(_ rect: CGRect, from view: UIView?) -> CGRect {
        if let view { return view.convert(rect, to: self) }
        let corners = [
            CGPoint(x: rect.minX, y: rect.minY),
            CGPoint(x: rect.maxX, y: rect.minY),
            CGPoint(x: rect.minX, y: rect.maxY),
            CGPoint(x: rect.maxX, y: rect.maxY),
        ].map { convert($0, from: nil) }
        guard let first = corners.first else { return .zero }
        let minX = corners.dropFirst().reduce(first.x) { min($0, $1.x) }
        let maxX = corners.dropFirst().reduce(first.x) { max($0, $1.x) }
        let minY = corners.dropFirst().reduce(first.y) { min($0, $1.y) }
        let maxY = corners.dropFirst().reduce(first.y) { max($0, $1.y) }
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    // MARK: Hit testing (event module, M7 — exact UIKit semantics)

    /// CGRectContainsPoint(bounds, point): min-edge inclusive, max-edge
    /// exclusive.
#if OPENUIKIT_OBJC_SUBCLASSING
    @objc(pointInside:withEvent:)
#endif
    open dynamic func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        bounds.contains(point)
    }

    /// UIKit recursion: a view is only reachable if EVERY ancestor on the
    /// path passes its own point(inside:) — subviews outside the parent's
    /// bounds are unreachable regardless of clipsToBounds (clipping is
    /// visual only, oracle-verified). Skips hidden views, alpha < 0.01 and
    /// disabled interaction (each prunes its whole subtree); subviews are
    /// tested front-to-back (reverse array order).
#if OPENUIKIT_OBJC_SUBCLASSING
    @objc(hitTest:withEvent:)
#endif
    open dynamic func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard isUserInteractionEnabled, !isHidden, alpha >= 0.01 else { return nil }
        guard !_hasInteractionBlockingAnimation(at: OpenUIKitRuntime.animationTime)
        else { return nil }
        guard self.point(inside: point, with: event) else { return nil }
        for sub in subviews.reversed() {
            if let hit = sub.hitTest(sub.convert(point, from: self), with: event) {
                return hit
            }
        }
        return self
    }

    // MARK: Touch handling (UIResponder subset — event module, M7)

    /// Gesture recognizers attached to this view (nil when none, like UIKit).
    public final var gestureRecognizers: [UIGestureRecognizer]? {
        _gestureRecognizers.isEmpty ? nil : _gestureRecognizers
    }
    final var _gestureRecognizers: [UIGestureRecognizer] = []

    /// Interactions attached to this view (M13 — `addInteraction(_:)` and
    /// the rest live in UIContextMenu.swift, which owns the protocol).
    final var _interactions: [UIInteraction] = []
    /// Process-local paste configuration (UIPasteConfigurationSupporting).
    final var _pasteConfiguration: UIPasteConfiguration?

    public final func addGestureRecognizer(_ recognizer: UIGestureRecognizer) {
        recognizer.view?.removeGestureRecognizer(recognizer)
        recognizer.view = self
        _gestureRecognizers.append(recognizer)
    }

    public final func removeGestureRecognizer(_ recognizer: UIGestureRecognizer) {
        guard recognizer.view === self else { return }
        _gestureRecognizers.removeAll { $0 === recognizer }
        recognizer.view = nil
    }

    // (The UIResponder touch entry points — touchesBegan/Moved/Ended/
    // Cancelled — now live on UIResponder, where UIKit puts them, and their
    // default forwards up the responder chain. See UIResponder.swift.)

    // MARK: Responder chain (lifecycle module, M12)

    /// The view controller whose ROOT view this is, if any. Set by
    /// UIViewController when it takes ownership of a view; the one hop that
    /// makes the responder chain pass through view controllers.
    weak final var _managingViewController: UIViewController?

    /// UIKit: a view's next responder is the view controller it is the root
    /// view of, otherwise its superview.
    open override var next: UIResponder? {
        if let vc = _managingViewController, vc.viewIfLoaded === self { return vc }
        return superview
    }

    // MARK: First responder (text-input module, M8; storage moved to
    // UIResponder in M12 — the become/resign behavior is unchanged)

    /// The UIWindow at the root of this view's superview chain, if any.
    public final var window: UIWindow? {
        var v: UIView? = self
        while let cur = v {
            if let w = cur as? UIWindow { return w }
            v = cur.superview
        }
        return nil
    }

    /// A view can only hold focus while it is installed in a window — the
    /// rule that makes `becomeFirstResponder()` fail on a detached view.
    override var _firstResponderWindow: UIWindow? { window }

    // MARK: Rendering (view module: RenderPass.swift implements)
    /// Draw this view's own content (background is handled by the render
    /// pass; subclasses draw text/images/chrome here).
    ///
    /// The base implementation is the bridge to UIKit's app-facing drawing
    /// API: it makes `canvas` the current graphics context and calls
    /// `draw(_ rect:)`, so an app subclass that overrides `draw(_:)` — with
    /// `UIBezierPath`, `UIColor.setFill()`, `UIGraphicsGetCurrentContext()`
    /// — renders through the normal content path (and the layer-contents
    /// cache, invalidated by `setNeedsDisplay()`). OpenUIKit's own content
    /// views override `drawContent` directly and never pay for this.
#if OPENUIKIT_OBJC_SUBCLASSING
    @objc(_ouk_drawContentIn:bounds:)
#endif
    open dynamic func drawContent(in canvas: Canvas, bounds: CGRect) {
        UIGraphics.pushContext(canvas, clip: bounds)
        draw(bounds)
        UIGraphics.popContext()
    }

    /// UIKit's app-side drawing hook. Override to draw the view's content
    /// with `UIBezierPath` / `UIGraphicsGetCurrentContext()`; call
    /// `setNeedsDisplay()` when the drawing inputs change. `rect` is the
    /// view's bounds (OpenUIKit always redraws the whole view).
#if OPENUIKIT_OBJC_SUBCLASSING
    @objc(drawRect:)
#endif
    open dynamic func draw(_ rect: CGRect) {}
}
