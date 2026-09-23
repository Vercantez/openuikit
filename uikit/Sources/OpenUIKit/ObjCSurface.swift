// The Objective-C surface of UIFont and CALayer (docs/agent_reports/
// objc-surface.md).
//
// Every member here is an `@objc(<iOS SDK selector>)` twin of an existing
// OpenUIKit member: the selector, argument order and types are the
// iPhoneSimulator26.1 SDK's (UIFont.h, CALayer.h), the body is one OpenUIKit
// call, and the observable behaviour is checked against the iOS 26.1
// simulator by Tools/oracle2/objcsurfaceprobe (Tests/ObjCSurfaceTests on the
// Apple toolchain, scripts/objc_surface_guest_probe.sh under machorun).
//
// These live in OpenUIKit itself, not in OpenUIKitObjCBridge, because the
// Mach-O guest (machorun + objc4) has the Objective-C runtime and no bridge
// target: an Objective-C category on UIFont or a CALayer subclass must work
// there too. Two limits follow from the guest's Foundation-hidden build:
//   * its CGFloat / CGRect are OpenCoreGraphics' own Swift structs, which
//     Objective-C cannot represent; a CGFloat parameter is spelled
//     `_OUKObjCFloat` (CGFloat where Foundation exists, Double on the guest,
//     the same 64-bit C `double`), and CGRect/CGPoint/CGSize members exist
//     only where Foundation provides the C structs;
//   * String and Array bridge through Foundation, so NSString / NSArray
//     members exist only where Foundation does.
// CGColorRef members (UIColor.CGColor, CALayer.borderColor, …) need Apple's
// CoreGraphics and live in OpenUIKitObjCBridge.
//
// Linux ELF has no Objective-C runtime; this file is empty there.

#if _runtime(_ObjC)
#if canImport(Foundation)
// `@objc` members that mention NSString/NSArray need the Foundation module
// loaded; a scoped declaration import keeps its names out of this file
// (UITableViewCell.swift does the same).
import struct Foundation.Data
import ObjectiveC

/// The Objective-C spelling of a `CGFloat` parameter or result.
public typealias _OUKObjCFloat = CGFloat
#else
import ObjectiveC

/// The Objective-C spelling of a `CGFloat` parameter or result: C `double`
/// (CGFloat on every 64-bit Apple platform). OpenCoreGraphics' portable
/// CGFloat struct is not an Objective-C type.
public typealias _OUKObjCFloat = Double
#endif

extension UIFont.Weight {
    /// `UIFontWeight` (a CGFloat) to OpenUIKit's weight: the measured raw
    /// values (iOS 26.1 `fontdesc.weight.raws`, UIFontDescriptor.swift) map
    /// exactly; any other value takes the nearest measured weight.
    init(nearestRawValue raw: Double) {
        let all: [UIFont.Weight] = [.ultraLight, .thin, .light, .regular, .medium, .semibold, .bold, .heavy, .black]
        self = all.min { abs(Double($0.rawValue) - raw) < abs(Double($1.rawValue) - raw) } ?? .regular
    }
}

// MARK: - UIFont (UIFont.h)

extension UIFont {
    @objc(systemFontOfSize:)
    public class func __objc_systemFont(ofSize fontSize: _OUKObjCFloat) -> UIFont {
        systemFont(ofSize: CGFloat(fontSize))
    }
    @objc(boldSystemFontOfSize:)
    public class func __objc_boldSystemFont(ofSize fontSize: _OUKObjCFloat) -> UIFont {
        boldSystemFont(ofSize: CGFloat(fontSize))
    }
    @objc(italicSystemFontOfSize:)
    public class func __objc_italicSystemFont(ofSize fontSize: _OUKObjCFloat) -> UIFont {
        italicSystemFont(ofSize: CGFloat(fontSize))
    }
    @objc(systemFontOfSize:weight:)
    public class func __objc_systemFont(ofSize fontSize: _OUKObjCFloat, weight: _OUKObjCFloat) -> UIFont {
        systemFont(ofSize: CGFloat(fontSize), weight: Weight(nearestRawValue: Double(weight)))
    }
    @objc(monospacedSystemFontOfSize:weight:)
    public class func __objc_monospacedSystemFont(ofSize fontSize: _OUKObjCFloat, weight: _OUKObjCFloat) -> UIFont {
        monospacedSystemFont(ofSize: CGFloat(fontSize), weight: Weight(nearestRawValue: Double(weight)))
    }
    @objc(fontWithSize:)
    public func __objc_withSize(_ fontSize: _OUKObjCFloat) -> UIFont { withSize(CGFloat(fontSize)) }

    @objc(pointSize) public var __objc_pointSize: _OUKObjCFloat { _OUKObjCFloat(pointSize) }
    @objc(ascender) public var __objc_ascender: _OUKObjCFloat { _OUKObjCFloat(ascender) }
    @objc(descender) public var __objc_descender: _OUKObjCFloat { _OUKObjCFloat(descender) }
    @objc(capHeight) public var __objc_capHeight: _OUKObjCFloat { _OUKObjCFloat(capHeight) }
    @objc(xHeight) public var __objc_xHeight: _OUKObjCFloat { _OUKObjCFloat(xHeight) }
    @objc(lineHeight) public var __objc_lineHeight: _OUKObjCFloat { _OUKObjCFloat(lineHeight) }
    @objc(leading) public var __objc_leading: _OUKObjCFloat { _OUKObjCFloat(leading) }

    /// NSCopying (UIFont.h). iOS 26.1 returns the receiver (objcsurfaceprobe
    /// `## identity`: `[font copy] == font`); a UIFont is immutable.
    @objc(copyWithZone:)
    public func __objc_copy(with zone: OpaquePointer?) -> AnyObject { self }

#if canImport(Foundation)
    @objc(fontWithName:size:)
    public class func __objc_font(name fontName: String, size fontSize: _OUKObjCFloat) -> UIFont? {
        UIFont(name: fontName, size: CGFloat(fontSize))
    }
    @objc(preferredFontForTextStyle:)
    public class func __objc_preferredFont(forTextStyle style: String) -> UIFont {
        preferredFont(forTextStyle: TextStyle(rawValue: style))
    }
    @objc(preferredFontForTextStyle:compatibleWithTraitCollection:)
    public class func __objc_preferredFont(forTextStyle style: String,
                                           compatibleWith traitCollection: UITraitCollection?) -> UIFont {
        preferredFont(forTextStyle: TextStyle(rawValue: style), compatibleWith: traitCollection)
    }
    @objc(familyNames) public class var __objc_familyNames: [String] { familyNames }
    @objc(fontNamesForFamilyName:)
    public class func __objc_fontNames(forFamilyName familyName: String) -> [String] {
        fontNames(forFamilyName: familyName)
    }
    @objc(fontName) public var __objc_fontName: String { fontName }
    @objc(familyName) public var __objc_familyName: String { familyName }
#endif
}

// MARK: - CALayer (CALayer.h)

extension CALayer {
    /// `+[CALayer layer]`: `[[self alloc] init]`, so an Objective-C
    /// subclass's `-init` runs (iOS 26.1, objcsurfaceprobe `## layersubclass`).
    @objc(layer)
    public class func __objc_layer() -> Self {
        // `self` may be the Swift wrapper metadata of an Objective-C class.
        // `NSObject.Type.init()` is a message send that converts either kind
        // to the class object; the metatype is reinterpreted, never boxed
        // (CALayer._makeBackingLayer). `as! Self` would check against that
        // wrapper and fail (MEASURED: "Could not cast value of type
        // 'OUKTraceLayer' to 'OUKTraceLayer'"); the object is an instance of
        // the receiver by construction.
        let object = unsafeBitCast(self, to: NSObject.Type.self).init()
        return unsafeBitCast(object, to: Self.self)
    }

    @objc(setNeedsLayout) public func __objc_setNeedsLayout() { setNeedsLayout() }
    @objc(needsLayout) public func __objc_needsLayout() -> Bool { needsLayout() }
    @objc(layoutIfNeeded) public func __objc_layoutIfNeeded() { layoutIfNeeded() }
    @objc(addSublayer:) public func __objc_addSublayer(_ layer: CALayer) { addSublayer(layer) }
    @objc(insertSublayer:atIndex:) public func __objc_insertSublayer(_ layer: CALayer, at index: UInt32) {
        insertSublayer(layer, at: index)
    }
    @objc(removeFromSuperlayer) public func __objc_removeFromSuperlayer() { removeFromSuperlayer() }
    @objc(superlayer) public var __objc_superlayer: CALayer? { superlayer }
    @objc(mask) public var __objc_mask: CALayer? { get { mask } set { mask = newValue } }
    /// The Swift delegate object (OpenUIKit's CALayerDelegate is a Swift
    /// protocol); an Objective-C reader sees it as `id`.
    @objc(delegate) public var __objc_delegate: AnyObject? { delegate }

    @objc(opacity) public var __objc_opacity: Float { get { opacity } set { opacity = newValue } }
    @objc(hidden) public var __objc_hidden: Bool {
        @objc(isHidden) get { isHidden }
        @objc(setHidden:) set { isHidden = newValue }
    }
    @objc(opaque) public var __objc_opaque: Bool {
        @objc(isOpaque) get { isOpaque }
        @objc(setOpaque:) set { isOpaque = newValue }
    }
    @objc(masksToBounds) public var __objc_masksToBounds: Bool {
        get { masksToBounds } set { masksToBounds = newValue }
    }
    @objc(cornerRadius) public var __objc_cornerRadius: _OUKObjCFloat {
        get { _OUKObjCFloat(cornerRadius) } set { cornerRadius = CGFloat(newValue) }
    }
    @objc(borderWidth) public var __objc_borderWidth: _OUKObjCFloat {
        get { _OUKObjCFloat(borderWidth) } set { borderWidth = CGFloat(newValue) }
    }
    @objc(contentsScale) public var __objc_contentsScale: _OUKObjCFloat {
        get { _OUKObjCFloat(contentsScale) } set { contentsScale = CGFloat(newValue) }
    }
    @objc(shadowOpacity) public var __objc_shadowOpacity: Float {
        get { shadowOpacity } set { shadowOpacity = newValue }
    }
    @objc(shadowRadius) public var __objc_shadowRadius: _OUKObjCFloat {
        get { _OUKObjCFloat(shadowRadius) } set { shadowRadius = CGFloat(newValue) }
    }
    @objc(shouldRasterize) public var __objc_shouldRasterize: Bool {
        get { shouldRasterize } set { shouldRasterize = newValue }
    }
    @objc(rasterizationScale) public var __objc_rasterizationScale: _OUKObjCFloat {
        get { _OUKObjCFloat(rasterizationScale) } set { rasterizationScale = CGFloat(newValue) }
    }
    @objc(drawsAsynchronously) public var __objc_drawsAsynchronously: Bool {
        get { drawsAsynchronously } set { drawsAsynchronously = newValue }
    }

#if canImport(Foundation)
    @objc(bounds) public var __objc_bounds: CGRect { get { bounds } set { bounds = newValue } }
    @objc(frame) public var __objc_frame: CGRect { get { frame } set { frame = newValue } }
    @objc(position) public var __objc_position: CGPoint { get { position } set { position = newValue } }
    @objc(anchorPoint) public var __objc_anchorPoint: CGPoint { get { anchorPoint } set { anchorPoint = newValue } }
    @objc(shadowOffset) public var __objc_shadowOffset: CGSize { get { shadowOffset } set { shadowOffset = newValue } }
    @objc(sublayers) public var __objc_sublayers: [CALayer]? { get { sublayers } set { sublayers = newValue } }
#endif
}
#endif
