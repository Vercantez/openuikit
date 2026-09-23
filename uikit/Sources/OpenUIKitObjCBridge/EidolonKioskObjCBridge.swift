// Eidolon Kiosk rows: the Objective-C selectors and C functions
// DZNWebViewController, SDWebImage, SVProgressHUD, XNGMarkdownParser,
// ARTiledImageView and Artsy+UIFonts send that OpenUIKit did not answer on
// the iOS triple (docs/agent_reports/eidolon-kiosk.md). Forwarding twins of
// OpenUIKit members, in the shape of UIKitObjCBridge.swift; every value is
// checked line for line against the iOS 26.1 simulator by
// Tests/KioskRowsTests (Tools/oracle2/kioskrowsprobe/transcript-ios26.1.txt).

#if canImport(ObjectiveC)
import CoreGraphics
import Foundation
import ObjectiveC
import OpenCoreGraphics
import OpenUIKit
import OpenUIKitObjCSupport

// MARK: - View controllers and bars (DZNWebViewController)

extension UIViewController {
    @objc(navigationItem) public var __objc_navigationItem: UINavigationItem { navigationItem }
    @objc(toolbarItems) public var __objc_toolbarItems: [UIBarButtonItem]? {
        get { toolbarItems } set { toolbarItems = newValue }
    }
    @objc(setToolbarItems:animated:)
    public func __objc_setToolbarItems(_ items: [UIBarButtonItem]?, animated: Bool) {
        setToolbarItems(items, animated: animated)
    }
}

extension UINavigationController {
    @objc(toolbar) public var __objc_toolbar: UIToolbar { toolbar }
    /// UINavigationController.h: `@property(nonatomic,getter=isToolbarHidden) BOOL toolbarHidden`.
    @objc(toolbarHidden) public var __objc_toolbarHidden: Bool {
        @objc(isToolbarHidden) get { isToolbarHidden }
        @objc(setToolbarHidden:) set { isToolbarHidden = newValue }
    }
    @objc(setToolbarHidden:animated:) public func __objc_setToolbarHidden(_ hidden: Bool, animated: Bool) {
        setToolbarHidden(hidden, animated: animated)
    }
    /// UIKit loads a navigation controller's view inside
    /// `-initWithRootViewController:` (MEASURED kioskrowsprobe during this
    /// work: isViewLoaded is YES right after it), so the edge recognizer
    /// always exists there. OpenUIKit installs it when the view loads; the
    /// view is loaded here so the recognizer is never nil.
    @objc(interactivePopGestureRecognizer) public var __objc_interactivePopGestureRecognizer: UIGestureRecognizer? {
        loadViewIfNeeded()
        return interactivePopGestureRecognizer
    }
}

extension UINavigationItem {
    @objc(title) public var __objc_title: String? { get { title } set { title = newValue } }
}

extension UINavigationBar {
    @objc(titleTextAttributes) public var __objc_titleTextAttributes: [String: Any]? {
        get { titleTextAttributes.map { Dictionary(uniqueKeysWithValues: $0.map { ($0.key.rawValue, $0.value) }) } }
        set {
            titleTextAttributes = newValue.map {
                Dictionary(uniqueKeysWithValues: $0.map { (NSAttributedString.Key(rawValue: $0.key), $0.value) })
            }
        }
    }
}

extension UIBarItem {
    /// UIBarItem.h: `@property(nonatomic,getter=isEnabled) BOOL enabled`.
    @objc(enabled) public var __objc_enabled: Bool {
        @objc(isEnabled) get { isEnabled }
        @objc(setEnabled:) set { isEnabled = newValue }
    }
    @objc(title) public var __objc_title: String? { get { title } set { title = newValue } }
}

extension UIBarButtonItem {
    @objc(width) public var __objc_width: CGFloat { get { width } set { width = newValue } }
    @objc(customView) public var __objc_customView: UIView? { get { customView } set { customView = newValue } }
    @objc(initWithCustomView:) public convenience init(__objcCustomView customView: UIView) {
        self.init(customView: customView)
    }
}

extension UIGestureRecognizer {
    @objc(delaysTouchesBegan) public var __objc_delaysTouchesBegan: Bool {
        get { delaysTouchesBegan } set { delaysTouchesBegan = newValue }
    }
}

extension UILongPressGestureRecognizer {
    @objc(minimumPressDuration) public var __objc_minimumPressDuration: TimeInterval {
        get { minimumPressDuration } set { minimumPressDuration = newValue }
    }
    @objc(allowableMovement) public var __objc_allowableMovement: CGFloat {
        get { allowableMovement } set { allowableMovement = newValue }
    }
}

// MARK: - UIActivityViewController (DZNWebViewController's share sheet)

extension UIActivityViewController {
    @objc(initWithActivityItems:applicationActivities:)
    public convenience init(__objcActivityItems items: [Any], applicationActivities: [UIActivity]?) {
        self.init(activityItems: items, applicationActivities: applicationActivities)
    }
    @objc(excludedActivityTypes) public var __objc_excludedActivityTypes: [String]? {
        get { excludedActivityTypes?.map(\.rawValue) }
        set { excludedActivityTypes = newValue?.map { UIActivity.ActivityType(rawValue: $0) } }
    }
    /// UIActivityViewControllerCompletionHandler (deprecated since iOS 8):
    /// UIKit keeps it separately from the items handler (MEASURED: setting
    /// it leaves completionWithItemsHandler nil).
    @objc(completionHandler) public var __objc_completionHandler: (@convention(block) (String?, Bool) -> Void)? {
        get { _EidolonKioskStorage.completionHandlers[ObjectIdentifier(self)] }
        set { _EidolonKioskStorage.completionHandlers[ObjectIdentifier(self)] = newValue }
    }
    @objc(completionWithItemsHandler)
    public var __objc_completionWithItemsHandler: (@convention(block) (String?, Bool, [Any]?, Error?) -> Void)? {
        get {
            guard let handler = completionWithItemsHandler else { return nil }
            return { type, completed, items, error in
                handler(type.map { UIActivity.ActivityType(rawValue: $0) }, completed, items, error)
            }
        }
        set {
            completionWithItemsHandler = newValue.map { block in
                { type, completed, items, error in block(type?.rawValue, completed, items, error) }
            }
        }
    }
}

@MainActor
enum _EidolonKioskStorage {
    static var completionHandlers: [ObjectIdentifier: @convention(block) (String?, Bool) -> Void] = [:]
}

// MARK: - UIApplication (Kiosk's AppDelegate, SDWebImage, DZNWebViewController)

extension UIApplication {
    /// UIApplication.h: `@property(nonatomic,getter=isIdleTimerDisabled) BOOL idleTimerDisabled`.
    @objc(idleTimerDisabled) public var __objc_idleTimerDisabled: Bool {
        @objc(isIdleTimerDisabled) get { isIdleTimerDisabled }
        @objc(setIdleTimerDisabled:) set { isIdleTimerDisabled = newValue }
    }
    /// Reads NO whatever was set (MEASURED iOS 26.1; UIApplication.swift).
    @objc(networkActivityIndicatorVisible) public var __objc_networkActivityIndicatorVisible: Bool {
        @objc(isNetworkActivityIndicatorVisible) get { isNetworkActivityIndicatorVisible }
        @objc(setNetworkActivityIndicatorVisible:) set { isNetworkActivityIndicatorVisible = newValue }
    }
    /// UIBackgroundTaskIdentifier is NSUInteger with UIBackgroundTaskInvalid
    /// 0 (MEASURED); OpenUIKit's identifiers are the same integers.
    @objc(beginBackgroundTaskWithExpirationHandler:)
    public func __objc_beginBackgroundTask(expirationHandler handler: (() -> Void)?) -> UInt {
        UInt(beginBackgroundTask(expirationHandler: handler).rawValue)
    }
    @objc(endBackgroundTask:) public func __objc_endBackgroundTask(_ identifier: UInt) {
        endBackgroundTask(UIBackgroundTaskIdentifier(rawValue: Int(identifier)))
    }
}

// MARK: - NSValue (UIGeometry.h's NSValue (NSValueUIGeometryExtensions))

extension NSValue {
    @objc(valueWithCGPoint:) public class func __objc_value(cgPoint point: CGPoint) -> NSValue {
        var p = point
        return NSValue(bytes: &p, objCType: "{CGPoint=dd}")
    }
    @objc(valueWithCGRect:) public class func __objc_value(cgRect rect: CGRect) -> NSValue {
        var r = rect
        return NSValue(bytes: &r, objCType: "{CGRect={CGPoint=dd}{CGSize=dd}}")
    }
    @objc(valueWithCGSize:) public class func __objc_value(cgSize size: CGSize) -> NSValue {
        var s = size
        return NSValue(bytes: &s, objCType: "{CGSize=dd}")
    }
    @objc(CGPointValue) public var __objc_CGPointValue: CGPoint {
        var p = CGPoint.zero
        getValue(&p, size: MemoryLayout<CGPoint>.size)
        return p
    }
    @objc(CGRectValue) public var __objc_CGRectValue: CGRect {
        var r = CGRect.zero
        getValue(&r, size: MemoryLayout<CGRect>.size)
        return r
    }
    @objc(CGSizeValue) public var __objc_CGSizeValue: CGSize {
        var s = CGSize.zero
        getValue(&s, size: MemoryLayout<CGSize>.size)
        return s
    }
}

// MARK: - Drawing (SDWebImage, ARTiledImageView, SVProgressHUD)

extension UIImage {
    @objc(drawInRect:blendMode:alpha:)
    public func __objc_draw(in rect: CGRect, blendMode: CGBlendMode, alpha: CGFloat) {
        draw(in: rect, blendMode: blendMode, alpha: alpha)
    }
}

extension UIColor {
    @objc(setFill) public func __objc_setFill() { setFill() }
    @objc(setStroke) public func __objc_setStroke() { setStroke() }
    @objc(set) public func __objc_set() { set() }
}

/// UIGraphics.h / UIImage.h C functions for Objective-C callers
/// (UIKitObjCSupport.h declares them, Objective-C side only).
@_cdecl("UIGraphicsBeginImageContextWithOptions")
public nonisolated func __ouk_UIGraphicsBeginImageContextWithOptions(_ size: CGSize, _ opaque: ObjCBool, _ scale: CGFloat) {
    MainActor.assumeIsolated { UIGraphicsBeginImageContextWithOptions(size, opaque.boolValue, scale) }
}
@_cdecl("UIGraphicsBeginImageContext")
public nonisolated func __ouk_UIGraphicsBeginImageContext(_ size: CGSize) {
    MainActor.assumeIsolated { UIGraphicsBeginImageContext(size) }
}
@_cdecl("UIGraphicsGetImageFromCurrentImageContext")
public nonisolated func __ouk_UIGraphicsGetImageFromCurrentImageContext() -> UIImage? {
    MainActor.assumeIsolated { UIGraphicsGetImageFromCurrentImageContext() }
}
@_cdecl("UIGraphicsEndImageContext")
public nonisolated func __ouk_UIGraphicsEndImageContext() {
    MainActor.assumeIsolated { UIGraphicsEndImageContext() }
}
/// CF_RETURNS_NOT_RETAINED, as UIKit's.
@_cdecl("UIGraphicsGetCurrentContext")
public nonisolated func __ouk_UIGraphicsGetCurrentContext() -> UnsafeMutableRawPointer? {
    MainActor.assumeIsolated {
        UIGraphicsGetCurrentContext().map { Unmanaged.passUnretained($0).toOpaque() }
    }
}
@_cdecl("UIRectFill")
public nonisolated func __ouk_UIRectFill(_ rect: CGRect) {
    MainActor.assumeIsolated { UIRectFill(rect) }
}
@_cdecl("UIImagePNGRepresentation")
public nonisolated func __ouk_UIImagePNGRepresentation(_ image: UIImage) -> NSData? {
    MainActor.assumeIsolated { image.pngData().map { $0 as NSData } }
}
@_cdecl("UIImageJPEGRepresentation")
public nonisolated func __ouk_UIImageJPEGRepresentation(_ image: UIImage, _ quality: CGFloat) -> NSData? {
    MainActor.assumeIsolated { image.jpegData(compressionQuality: quality).map { $0 as NSData } }
}

// MARK: - Labels, buttons, text (Kiosk, Artsy-UIButtons)

extension UILabel {
    /// The TEXT shadow (UILabel.h). OpenUIKit's UIView spells shadowColor /
    /// shadowOffset for the layer shadow; the label keeps its own.
    @objc(shadowColor) public var __objc_shadowColor: UIColor? {
        get { _textShadowColor } set { _textShadowColor = newValue }
    }
    @objc(shadowOffset) public var __objc_shadowOffset: CGSize {
        get { _textShadowOffset } set { _textShadowOffset = newValue }
    }
}

extension UIButton {
    @objc(setTitleShadowColor:forState:) public func __objc_setTitleShadowColor(_ color: UIColor?, forState state: UInt) {
        setTitleShadowColor(color, for: State(rawValue: state))
    }
    @objc(titleShadowColorForState:) public func __objc_titleShadowColor(forState state: UInt) -> UIColor? {
        titleShadowColor(for: State(rawValue: state))
    }
    @objc(currentTitleShadowColor) public var __objc_currentTitleShadowColor: UIColor? { currentTitleShadowColor }
}

extension UITextField {
    @objc(clearsOnBeginEditing) public var __objc_clearsOnBeginEditing: Bool {
        get { clearsOnBeginEditing } set { clearsOnBeginEditing = newValue }
    }
}

extension UITextView {
    @objc(scrollRangeToVisible:) public func __objc_scrollRangeToVisible(_ range: NSRange) { scrollRangeToVisible(range) }
}

extension UIScrollView {
    @objc(adjustedContentInset) public var __objc_adjustedContentInset: UIEdgeInsetsObjC {
        let i = adjustedContentInset
        return UIEdgeInsetsObjC(top: i.top, left: i.left, bottom: i.bottom, right: i.right)
    }
}

// MARK: - Fonts (Artsy+UIFonts)

extension UIFontDescriptor {
    @objc(fontDescriptorWithFontAttributes:)
    public class func __objc_fontDescriptor(fontAttributes attributes: [String: Any]) -> UIFontDescriptor {
        UIFontDescriptor(__objcFontAttributes: attributes)
    }
    @objc(initWithFontAttributes:) public convenience init(__objcFontAttributes attributes: [String: Any]) {
        var converted: [AttributeName: Any] = [:]
        for (key, value) in attributes {
            let name = AttributeName(rawValue: key)
            if name == .featureSettings, let features = value as? [[String: Any]] {
                converted[name] = features.map { f in
                    Dictionary(uniqueKeysWithValues: f.map { (FeatureKey(rawValue: $0.key), ($0.value as? NSNumber)?.intValue ?? $0.value) })
                }
            } else if name == .size, let n = value as? NSNumber {
                converted[name] = CGFloat(n.doubleValue)
            } else {
                converted[name] = value
            }
        }
        self.init(fontAttributes: converted)
    }
    @objc(postscriptName) public var __objc_postscriptName: String { postscriptName }
    @objc(pointSize) public var __objc_pointSize: CGFloat { pointSize }
    @objc(fontAttributes) public var __objc_fontAttributes: [String: Any] {
        Dictionary(uniqueKeysWithValues: fontAttributes.map { ($0.key.rawValue, $0.value) })
    }
}

extension UIFont {
    @objc(fontWithDescriptor:size:)
    public class func __objc_font(descriptor: UIFontDescriptor, size: CGFloat) -> UIFont {
        UIFont(descriptor: descriptor, size: size)
    }
    @objc(fontDescriptor) public var __objc_fontDescriptor: UIFontDescriptor { fontDescriptor }
}

// MARK: - UIBezierPath (SVProgressHUD)

extension UIBezierPath {
    @objc(bezierPath) public class func __objc_bezierPath() -> UIBezierPath { UIBezierPath() }
    @objc(bezierPathWithRect:) public class func __objc_bezierPath(rect: CGRect) -> UIBezierPath { UIBezierPath(rect: rect) }
    @objc(bezierPathWithOvalInRect:) public class func __objc_bezierPath(ovalIn rect: CGRect) -> UIBezierPath {
        UIBezierPath(ovalIn: rect)
    }
    @objc(bezierPathWithRoundedRect:cornerRadius:)
    public class func __objc_bezierPath(roundedRect rect: CGRect, cornerRadius: CGFloat) -> UIBezierPath {
        UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)
    }
    @objc(bezierPathWithArcCenter:radius:startAngle:endAngle:clockwise:)
    public class func __objc_bezierPath(arcCenter center: CGPoint, radius: CGFloat, startAngle: CGFloat,
                                        endAngle: CGFloat, clockwise: Bool) -> UIBezierPath {
        UIBezierPath(arcCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: clockwise)
    }
    @objc(CGPath) public var __objc_CGPath: CGPath { cgPath }
    @objc(isEmpty) public var __objc_isEmpty: Bool { isEmpty }
    @objc(empty) public var __objc_empty: Bool { isEmpty }
    @objc(lineWidth) public var __objc_lineWidth: CGFloat { get { lineWidth } set { lineWidth = newValue } }
    @objc(moveToPoint:) public func __objc_move(to point: CGPoint) { move(to: point) }
    @objc(addLineToPoint:) public func __objc_addLine(to point: CGPoint) { addLine(to: point) }
    @objc(closePath) public func __objc_close() { close() }
    @objc(fill) public func __objc_fill() { fill() }
    @objc(stroke) public func __objc_stroke() { stroke() }
}

// MARK: - Paragraph tabs (XNGMarkdownParser)

extension NSParagraphStyle {
    @objc(tabStops) public var __objc_tabStops: [NSTextTab] { tabStops }
}

extension NSMutableParagraphStyle {
    @objc(setTabStops:) public func __objc_setTabStops(_ tabs: [NSTextTab]?) { tabStops = tabs ?? [] }
}

// MARK: - Motion effects (SVProgressHUD)

extension UIInterpolatingMotionEffect {
    @objc(initWithKeyPath:type:) public convenience init(__objcKeyPath keyPath: String, type: Int) {
        self.init(keyPath: keyPath, type: EffectType(rawValue: type) ?? .tiltAlongHorizontalAxis)
    }
    @objc(keyPath) public var __objc_keyPath: String { keyPath }
    @objc(type) public var __objc_type: Int { type.rawValue }
    @objc(minimumRelativeValue) public var __objc_minimumRelativeValue: Any? {
        get { minimumRelativeValue } set { minimumRelativeValue = newValue }
    }
    @objc(maximumRelativeValue) public var __objc_maximumRelativeValue: Any? {
        get { maximumRelativeValue } set { maximumRelativeValue = newValue }
    }
}

extension UIMotionEffectGroup {
    @objc(motionEffects) public var __objc_motionEffects: [UIMotionEffect]? {
        get { motionEffects } set { motionEffects = newValue }
    }
}

extension UIView {
    @objc(motionEffects) public var __objc_motionEffects: [UIMotionEffect] {
        get { motionEffects } set { motionEffects = newValue }
    }
    @objc(addMotionEffect:) public func __objc_addMotionEffect(_ effect: UIMotionEffect) { addMotionEffect(effect) }
    @objc(removeMotionEffect:) public func __objc_removeMotionEffect(_ effect: UIMotionEffect) { removeMotionEffect(effect) }
}
#endif

// MARK: - Round 2: ARTiledImageView, DZNWebViewController bars, SVProgressHUD
#if canImport(ObjectiveC)
extension UIView {
    @objc(insertSubview:belowSubview:) public func __objc_insertSubview(_ view: UIView, below sibling: UIView) {
        insertSubview(view, belowSubview: sibling)
    }
    @objc(contentScaleFactor) public var __objc_contentScaleFactor: CGFloat {
        get { contentScaleFactor } set { contentScaleFactor = newValue }
    }
    @objc(setNeedsDisplayInRect:) public func __objc_setNeedsDisplay(in rect: CGRect) { setNeedsDisplay(rect) }
    @objc(accessibilityIdentifier) public var __objc_accessibilityIdentifier: String? {
        get { accessibilityIdentifier } set { accessibilityIdentifier = newValue }
    }
    /// NSObject (UIAccessibility): `@property BOOL isAccessibilityElement`.
    @objc(isAccessibilityElement) public var __objc_isAccessibilityElement: Bool {
        @objc(isAccessibilityElement) get { isAccessibilityElement }
        @objc(setIsAccessibilityElement:) set { isAccessibilityElement = newValue }
    }
}

extension UIScrollView {
    @objc(panGestureRecognizer) public var __objc_panGestureRecognizer: UIPanGestureRecognizer { panGestureRecognizer }
}

extension UIToolbar {
    @objc(barTintColor) public var __objc_barTintColor: UIColor? { get { barTintColor } set { barTintColor = newValue } }
    /// UIToolbar.h: `@property(nonatomic,assign,getter=isTranslucent) BOOL translucent`.
    @objc(translucent) public var __objc_translucent: Bool {
        @objc(isTranslucent) get { isTranslucent }
        @objc(setTranslucent:) set { isTranslucent = newValue }
    }
}

extension UINavigationItem {
    @objc(initWithTitle:) public convenience init(__objcTitle title: String) { self.init(title: title) }
    @objc(titleView) public var __objc_titleView: UIView? { get { titleView } set { titleView = newValue } }
    @objc(rightBarButtonItem) public var __objc_rightBarButtonItem: UIBarButtonItem? {
        get { rightBarButtonItem } set { rightBarButtonItem = newValue }
    }
    @objc(rightBarButtonItems) public var __objc_rightBarButtonItems: [UIBarButtonItem]? {
        get { rightBarButtonItems } set { rightBarButtonItems = newValue }
    }
    @objc(leftBarButtonItem) public var __objc_leftBarButtonItem: UIBarButtonItem? {
        get { leftBarButtonItem } set { leftBarButtonItem = newValue }
    }
}

extension UILabel {
    @objc(baselineAdjustment) public var __objc_baselineAdjustment: Int {
        get { baselineAdjustment.rawValue }
        set { baselineAdjustment = UIBaselineAdjustment(rawValue: newValue) ?? .alignBaselines }
    }
}

extension UIWindow {
    @objc(screen) public var __objc_screen: UIScreen { UIScreen.main }
}

extension UIFeedbackGenerator {
    @objc(prepare) public func __objc_prepare() { prepare() }
}

extension UINotificationFeedbackGenerator {
    /// UINotificationFeedbackType raw values are OpenUIKit's (MEASURED
    /// Success 0, Warning 1, Error 2); an undefined value is ignored.
    @objc(notificationOccurred:) public func __objc_notificationOccurred(_ type: Int) {
        if let t = FeedbackType(rawValue: type) { notificationOccurred(t) }
    }
}

extension UIApplication {
    @objc(statusBarOrientation) public var __objc_statusBarOrientation: Int { statusBarOrientation.rawValue }
    @objc(statusBarFrame) public var __objc_statusBarFrame: CGRect { statusBarFrame }
}

extension UIEvent {
    @objc(allTouches) public var __objc_allTouches: Set<UITouch>? { allTouches }
}

extension UITouch {
    @objc(locationInView:) public func __objc_location(in view: UIView?) -> CGPoint { location(in: view) }
}

extension NSString {
    /// NSString (UIStringDrawing), over OpenUIKit's text measurement
    /// (_OUKStringDrawing). Attributes other than the font are ignored.
    @objc(boundingRectWithSize:options:attributes:context:)
    public func __objc_boundingRect(with size: CGSize, options: Int, attributes: [String: Any]?,
                                    context: AnyObject?) -> CGRect {
        let font = attributes?["NSFont"] as? UIFont ?? UIFont.systemFont(ofSize: 12)
        return _OUKStringDrawing.boundingRect(self as String, size: size,
                                              options: NSStringDrawingOptions(rawValue: UInt(options)), font: font)
    }
}

/// UIAccessibilityPostNotification (UIAccessibility.h). Nothing listens in
/// OpenUIKit (UIAccessibility.post).
@_cdecl("UIAccessibilityPostNotification")
public nonisolated func __ouk_UIAccessibilityPostNotification(_ notification: UInt32, _ argument: AnyObject?) {
    UIAccessibility.post(notification: UIAccessibility.Notification(rawValue: notification), argument: argument)
}
#endif
