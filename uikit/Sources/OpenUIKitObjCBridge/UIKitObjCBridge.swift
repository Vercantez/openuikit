// OpenUIKitObjCBridge — route (b) Objective-C selectors over OpenUIKit's
// existing Swift API (simplenote-launch3).
//
// On the Apple toolchain SwiftPM emits `OpenUIKit-Swift.h` for every
// NSObject-derived OpenUIKit class (134 interfaces), but only `@objc`
// members appear in it. OpenUIKit's members are plain Swift, so an
// Objective-C caller sees the classes and none of their behaviour. Each
// member below is a forwarding `@objc(selector)` twin of an existing OpenUIKit
// member; the generated `OpenUIKitObjCBridge-Swift.h` adds them to the
// classes as categories. Nothing here is new behaviour: the selector, its
// argument order and its raw values are the iOS 26.1 SDK's (measured against
// the iPhoneSimulator26.1.sdk headers); the body is one OpenUIKit call.
//
// Selection: the members the 50 Simplenote 9b1bb17 Objective-C translation
// units resolve against a UIKit class (per-TU clang census, 1,071
// missing-selector diagnostics before this file; docs/agent_reports/
// simplenote-launch3.md), restricted to Objective-C-representable types.
// Members whose type is an OpenUIKit class that does not derive from NSObject
// (UIColor, UIFont, UIBarButtonItem, UIAlertAction, UIScreen, UIDevice,
// OpenUIKit's NSAttributedString) are NOT bridged: the class is the wall,
// not the selector.
//
// What this file does not change: an Objective-C class still cannot subclass
// any of these classes (objc_subclassing_restricted; lifting it crashes at
// UIView.init() on a null vtable slot, MEASURED probe1). Override points
// (viewDidLoad, layoutSubviews, …) are therefore forwarded for CALLERS only.

#if canImport(ObjectiveC)
import CoreGraphics
import Foundation
import ObjectiveC
import OpenCoreGraphics
import OpenUIKit
import OpenUIKitObjCSupport

// MARK: - Raw-value maps (iOS 26.1 SDK values; OpenUIKit enums carry no raw values)

private func cellStyle(_ raw: Int) -> UITableViewCell.CellStyle {
    switch raw { case 1: return .value1; case 2: return .value2; case 3: return .subtitle; default: return .default }
}
private func mapSelectionStyle(_ raw: Int) -> UITableViewCell.SelectionStyle {
    switch raw { case 0: return .none; case 1: return .blue; case 2: return .gray; default: return .default }
}
private func selectionStyleRaw(_ style: UITableViewCell.SelectionStyle) -> Int {
    switch style { case .none: return 0; case .blue: return 1; case .gray: return 2; default: return 3 }
}
/// OpenUIKit carries none/disclosureIndicator/checkmark; the SDK's detail
/// buttons (2, 4) have no OpenUIKit accessory and map to none (fail closed).
private func mapAccessoryType(_ raw: Int) -> UITableViewCell.AccessoryType {
    switch raw { case 1: return .disclosureIndicator; case 3: return .checkmark; default: return .none }
}
private func accessoryTypeRaw(_ type: UITableViewCell.AccessoryType) -> Int {
    switch type { case .none: return 0; case .disclosureIndicator: return 1; case .checkmark: return 3 }
}
private func tableStyle(_ raw: Int) -> UITableView.Style {
    switch raw { case 1: return .grouped; case 2: return .insetGrouped; default: return .plain }
}
private func gestureStateRaw(_ state: UIGestureRecognizer.State) -> Int {
    switch state {
    case .possible: return 0
    case .began: return 1
    case .changed: return 2
    case .ended: return 3
    case .cancelled: return 4
    case .failed: return 5
    @unknown default: return 0
    }
}
private func edgeInsets(_ insets: OpenUIKit.UIEdgeInsets) -> OpenUIKitObjCSupport.UIEdgeInsetsObjC {
    OpenUIKitObjCSupport.UIEdgeInsetsObjC(top: insets.top, left: insets.left, bottom: insets.bottom, right: insets.right)
}
private func edgeInsets(_ insets: OpenUIKitObjCSupport.UIEdgeInsetsObjC) -> OpenUIKit.UIEdgeInsets {
    OpenUIKit.UIEdgeInsets(top: insets.top, left: insets.left, bottom: insets.bottom, right: insets.right)
}

// MARK: - UIResponder

// `isFirstResponder` is an `@objc open dynamic` member of UIResponder itself
// (overridable, as in UIKit), so it already answers the ObjC selector.

// MARK: - UIView

extension UIView {
    // `frame` is an `@objc open dynamic` member of UIView itself (overridable,
    // as in UIKit); a twin here would re-enter it forever.
    @objc(center) public var __objc_center: CGPoint { get { center } set { center = newValue } }
    @objc(alpha) public var __objc_alpha: CGFloat { get { alpha } set { alpha = newValue } }
    @objc(isHidden) public var __objc_hidden: Bool { get { isHidden } set { isHidden = newValue } }
    @objc(hidden) public var __objc_hiddenPlain: Bool { get { isHidden } set { isHidden = newValue } }
    @objc(clipsToBounds) public var __objc_clipsToBounds: Bool { get { clipsToBounds } set { clipsToBounds = newValue } }
    @objc(tag) public var __objc_tag: Int { get { tag } set { tag = newValue } }
    @objc(isUserInteractionEnabled) public var __objc_userInteractionEnabled: Bool {
        get { isUserInteractionEnabled } set { isUserInteractionEnabled = newValue }
    }
    @objc(userInteractionEnabled) public var __objc_userInteractionEnabledPlain: Bool {
        get { isUserInteractionEnabled } set { isUserInteractionEnabled = newValue }
    }
    @objc(autoresizingMask) public var __objc_autoresizingMask: UInt {
        get { autoresizingMask.rawValue } set { autoresizingMask = UIView.AutoresizingMask(rawValue: newValue) }
    }
    @objc(superview) public var __objc_superview: UIView? { superview }
    @objc(subviews) public var __objc_subviews: [UIView] { subviews }
    @objc(addSubview:) public func __objc_addSubview(_ view: UIView) { addSubview(view) }
    @objc(insertSubview:atIndex:) public func __objc_insertSubview(_ view: UIView, at index: Int) { insertSubview(view, at: index) }
    @objc(insertSubview:aboveSubview:) public func __objc_insertSubview(_ view: UIView, above sibling: UIView) { insertSubview(view, aboveSubview: sibling) }
    @objc(sendSubviewToBack:) public func __objc_sendSubviewToBack(_ view: UIView) { sendSubviewToBack(view) }
    @objc(bringSubviewToFront:) public func __objc_bringSubviewToFront(_ view: UIView) { bringSubviewToFront(view) }
    @objc(removeFromSuperview) public func __objc_removeFromSuperview() { removeFromSuperview() }
    @objc(setNeedsLayout) public func __objc_setNeedsLayout() { setNeedsLayout() }
    @objc(layoutIfNeeded) public func __objc_layoutIfNeeded() { layoutIfNeeded() }
    @objc(setNeedsDisplay) public func __objc_setNeedsDisplay() { setNeedsDisplay() }
    @objc(sizeToFit) public func __objc_sizeToFit() { sizeToFit() }
    @objc(safeAreaInsets) public var __objc_safeAreaInsets: OpenUIKitObjCSupport.UIEdgeInsetsObjC { edgeInsets(safeAreaInsets) }
    @objc(addGestureRecognizer:) public func __objc_addGestureRecognizer(_ recognizer: UIGestureRecognizer) { addGestureRecognizer(recognizer) }
    @objc(removeGestureRecognizer:) public func __objc_removeGestureRecognizer(_ recognizer: UIGestureRecognizer) { removeGestureRecognizer(recognizer) }
    @objc(convertRect:toView:) public func __objc_convert(_ rect: CGRect, to view: UIView?) -> CGRect { convert(rect, to: view) }
    @objc(convertPoint:toView:) public func __objc_convert(_ point: CGPoint, to view: UIView?) -> CGPoint { convert(point, to: view) }
}

// MARK: - UIControl

extension UIControl {
    @objc(addTarget:action:forControlEvents:)
    public func __objc_addTarget(_ target: Any?, action: Selector, forControlEvents events: UInt) {
        addTarget(target, action: action, for: UIControl.Event(rawValue: events))
    }
    @objc(sendActionsForControlEvents:) public func __objc_sendActions(forControlEvents events: UInt) {
        sendActions(for: UIControl.Event(rawValue: events))
    }
}

// MARK: - UIScrollView

extension UIScrollView {
    @objc(contentOffset) public var __objc_contentOffset: CGPoint { get { contentOffset } set { contentOffset = newValue } }
    @objc(contentSize) public var __objc_contentSize: CGSize { get { contentSize } set { contentSize = newValue } }
    @objc(contentInset) public var __objc_contentInset: OpenUIKitObjCSupport.UIEdgeInsetsObjC {
        get { edgeInsets(contentInset) } set { contentInset = edgeInsets(newValue) }
    }
    @objc(isScrollEnabled) public var __objc_scrollEnabled: Bool { get { isScrollEnabled } set { isScrollEnabled = newValue } }
    @objc(scrollEnabled) public var __objc_scrollEnabledPlain: Bool { get { isScrollEnabled } set { isScrollEnabled = newValue } }
    @objc(setContentOffset:animated:) public func __objc_setContentOffset(_ offset: CGPoint, animated: Bool) {
        setContentOffset(offset, animated: animated)
    }
}

// MARK: - UILabel / UITextView / UITextField

extension UILabel {
    // text / numberOfLines are native @objc members of UILabel now
    // (vtable-free, eidolon-first-screen.md).
}

extension UITextView {
    @objc(editable) public var __objc_editable: Bool { get { isEditable } set { isEditable = newValue } }
}

extension UITextField {
}

// MARK: - UIViewController

extension UIViewController {
    @objc(view) public var __objc_view: UIView { get { view } set { view = newValue } }
    @objc(isViewLoaded) public var __objc_isViewLoaded: Bool { isViewLoaded }
    @objc(loadViewIfNeeded) public func __objc_loadViewIfNeeded() { loadViewIfNeeded() }
    @objc(title) public var __objc_title: String? { get { title } set { title = newValue } }
    @objc(parentViewController) public var __objc_parent: UIViewController? { parent }
    @objc(navigationController) public var __objc_navigationController: UINavigationController? { navigationController }
    @objc(presentingViewController) public var __objc_presentingViewController: UIViewController? { presentingViewController }
    @objc(presentedViewController) public var __objc_presentedViewController: UIViewController? { presentedViewController }
    @objc(childViewControllers) public var __objc_children: [UIViewController] { children }
    @objc(addChildViewController:) public func __objc_addChild(_ child: UIViewController) { addChild(child) }
    @objc(removeFromParentViewController) public func __objc_removeFromParent() { removeFromParent() }
    @objc(beginAppearanceTransition:animated:) public func __objc_beginAppearanceTransition(_ isAppearing: Bool, animated: Bool) {
        beginAppearanceTransition(isAppearing, animated: animated)
    }
    @objc(endAppearanceTransition) public func __objc_endAppearanceTransition() { endAppearanceTransition() }
    @objc(presentViewController:animated:completion:)
    public func __objc_present(_ controller: UIViewController, animated: Bool, completion: (() -> Void)?) {
        present(controller, animated: animated, completion: completion)
    }
    @objc(dismissViewControllerAnimated:completion:)
    public func __objc_dismiss(animated: Bool, completion: (() -> Void)?) {
        dismiss(animated: animated, completion: completion)
    }
}

// MARK: - UINavigationController

extension UINavigationController {
    @objc(viewControllers) public var __objc_viewControllers: [UIViewController] { viewControllers }
    @objc(topViewController) public var __objc_topViewController: UIViewController? { topViewController }
    @objc(visibleViewController) public var __objc_visibleViewController: UIViewController? { visibleViewController }
    @objc(navigationBar) public var __objc_navigationBar: UINavigationBar { navigationBar }
    @objc(pushViewController:animated:) public func __objc_push(_ controller: UIViewController, animated: Bool) {
        pushViewController(controller, animated: animated)
    }
    @objc(popViewControllerAnimated:) @discardableResult public func __objc_pop(animated: Bool) -> UIViewController? {
        popViewController(animated: animated)
    }
    @objc(popToRootViewControllerAnimated:) @discardableResult public func __objc_popToRoot(animated: Bool) -> [UIViewController]? {
        popToRootViewController(animated: animated)
    }
}

// MARK: - UIWindow / UIApplication

extension UIWindow {
    @objc(rootViewController) public var __objc_rootViewController: UIViewController? {
        get { rootViewController } set { rootViewController = newValue }
    }
    @objc(makeKeyAndVisible) public func __objc_makeKeyAndVisible() { makeKeyAndVisible() }
    @objc(isKeyWindow) public var __objc_isKeyWindow: Bool { isKeyWindow }
}

extension UIApplication {
    @objc(sharedApplication) public class var __objc_shared: UIApplication { UIApplication.shared }
    /// The Swift delegate object; an Objective-C caller reads it as `id`.
    @objc(keyWindow) public var __objc_keyWindow: UIWindow? { keyWindow }
    @objc(windows) public var __objc_windows: [UIWindow] { windows }
    @objc(openURL:options:completionHandler:)
    public func __objc_open(_ url: URL, options: [String: Any], completionHandler: ((Bool) -> Void)?) {
        var converted: [UIApplication.OpenExternalURLOptionsKey: Any] = [:]
        for (key, value) in options { converted[UIApplication.OpenExternalURLOptionsKey(rawValue: key)] = value }
        open(url, options: converted, completionHandler: completionHandler)
    }
}

// MARK: - UITableView / UITableViewCell / NSIndexPath

extension UITableView {
    @objc(reloadData) public func __objc_reloadData() { reloadData() }
    @objc(beginUpdates) public func __objc_beginUpdates() { beginUpdates() }
    @objc(endUpdates) public func __objc_endUpdates() { endUpdates() }
    @objc(rowHeight) public var __objc_rowHeight: CGFloat { get { rowHeight } set { rowHeight = newValue } }
    @objc(tableHeaderView) public var __objc_tableHeaderView: UIView? { get { tableHeaderView } set { tableHeaderView = newValue } }
    @objc(tableFooterView) public var __objc_tableFooterView: UIView? { get { tableFooterView } set { tableFooterView = newValue } }
    @objc(registerClass:forCellReuseIdentifier:) public func __objc_register(_ cellClass: AnyClass?, forCellReuseIdentifier identifier: String) {
        guard let cellClass = cellClass as? UITableViewCell.Type else { return }
        register(cellClass, forCellReuseIdentifier: identifier)
    }
    @objc(dequeueReusableCellWithIdentifier:) public func __objc_dequeueReusableCell(withIdentifier identifier: String) -> UITableViewCell? {
        dequeueReusableCell(withIdentifier: identifier)
    }
    @objc(dequeueReusableCellWithIdentifier:forIndexPath:)
    public func __objc_dequeueReusableCell(withIdentifier identifier: String, for indexPath: IndexPath) -> UITableViewCell {
        dequeueReusableCell(withIdentifier: identifier, for: indexPath)
    }
    @objc(cellForRowAtIndexPath:) public func __objc_cellForRow(at indexPath: IndexPath) -> UITableViewCell? { cellForRow(at: indexPath) }
    @objc(indexPathForSelectedRow) public var __objc_indexPathForSelectedRow: IndexPath? { indexPathForSelectedRow }
    @objc(deselectRowAtIndexPath:animated:) public func __objc_deselectRow(at indexPath: IndexPath, animated: Bool) {
        deselectRow(at: indexPath, animated: animated)
    }
    @objc(numberOfSections) public var __objc_numberOfSections: Int { numberOfSections }
    @objc(numberOfRowsInSection:) public func __objc_numberOfRows(inSection section: Int) -> Int { numberOfRows(inSection: section) }
}

extension UITableViewCell {
    @objc(textLabel) public var __objc_textLabel: UILabel? { textLabel }
    @objc(detailTextLabel) public var __objc_detailTextLabel: UILabel? { detailTextLabel }
    @objc(imageView) public var __objc_imageView: UIImageView? { imageView }
    @objc(contentView) public var __objc_contentView: UIView { contentView }
    @objc(accessoryView) public var __objc_accessoryView: UIView? { get { accessoryView } set { accessoryView = newValue } }
    @objc(selectedBackgroundView) public var __objc_selectedBackgroundView: UIView? {
        get { selectedBackgroundView } set { selectedBackgroundView = newValue }
    }
    @objc(selectionStyle) public var __objc_selectionStyle: Int {
        get { selectionStyleRaw(selectionStyle) } set { selectionStyle = mapSelectionStyle(newValue) }
    }
    @objc(accessoryType) public var __objc_accessoryType: Int {
        get { accessoryTypeRaw(accessoryType) } set { accessoryType = mapAccessoryType(newValue) }
    }
    @objc(isSelected) public var __objc_selected: Bool { isSelected }
    @objc(reuseIdentifier) public var __objc_reuseIdentifier: String? { reuseIdentifier }
}

/// UIKit's `NSIndexPath (UITableView)` category: `row` and `section` are
/// index positions 1 and 0 (UITableView.h). On macOS AppKit's
/// `NSIndexPath (NSCollectionViewAdditions)` already implements `section`
/// (and `item`, `+indexPathForItem:inSection:`); a twin would replace it
/// (MEASURED ObjCSurfaceTests.testNoTwinShadowsANativeSelector), so those
/// three are declared in UIKitObjCSupport.h and implemented here only where
/// AppKit is absent.
extension NSIndexPath {
    @objc(row) public var __objc_row: Int { index(atPosition: 1) }
    @objc(indexPathForRow:inSection:) public class func __objc_indexPath(forRow row: Int, inSection section: Int) -> NSIndexPath {
        NSIndexPath(indexes: [section, row], length: 2)
    }
#if !canImport(AppKit)
    @objc(section) public var __objc_section: Int { index(atPosition: 0) }
#endif
}

// MARK: - UISwitch / UIActivityIndicatorView / UIImageView / UIImage

extension UISwitch {
    @objc(isOn) public var __objc_isOn: Bool { isOn }
    @objc(on) public var __objc_on: Bool { get { isOn } set { isOn = newValue } }
    @objc(setOn:animated:) public func __objc_setOn(_ on: Bool, animated: Bool) { setOn(on, animated: animated) }
}

extension UIActivityIndicatorView {
    @objc(startAnimating) public func __objc_startAnimating() { startAnimating() }
    @objc(stopAnimating) public func __objc_stopAnimating() { stopAnimating() }
    @objc(isAnimating) public var __objc_isAnimating: Bool { isAnimating }
}

extension UIImageView {
    // initWithImage: / image are native @objc members of UIImageView now.
}

extension UIImage {
    @objc(imageNamed:) public class func __objc_imageNamed(_ name: String) -> UIImage? { UIImage(named: name) }
    @objc(size) public var __objc_size: CGSize { size }
    @objc(scale) public var __objc_scale: CGFloat { scale }
    @objc(drawInRect:) public func __objc_draw(in rect: CGRect) { draw(in: rect) }
}

// MARK: - Gesture recognizers

extension UIGestureRecognizer {
    @objc(initWithTarget:action:) public convenience init(__objcTarget target: Any?, action: Selector?) {
        self.init(target: target, action: action)
    }
    @objc(state) public var __objc_state: Int { gestureStateRaw(state) }
    @objc(view) public var __objc_view: UIView? { view }
    @objc(isEnabled) public var __objc_enabled: Bool { get { isEnabled } set { isEnabled = newValue } }
    @objc(cancelsTouchesInView) public var __objc_cancelsTouchesInView: Bool {
        get { cancelsTouchesInView } set { cancelsTouchesInView = newValue }
    }
    @objc(locationInView:) public func __objc_location(in view: UIView?) -> CGPoint { location(in: view) }
    @objc(addTarget:action:) public func __objc_addTarget(_ target: Any?, action: Selector) { addTarget(target, action: action) }
}

extension UIPanGestureRecognizer {
    @objc(translationInView:) public func __objc_translation(in view: UIView?) -> CGPoint { translation(in: view) }
    @objc(velocityInView:) public func __objc_velocity(in view: UIView?) -> CGPoint { velocity(in: view) }
}

extension UITapGestureRecognizer {
    @objc(numberOfTapsRequired) public var __objc_numberOfTapsRequired: Int {
        get { numberOfTapsRequired } set { numberOfTapsRequired = newValue }
    }
    @objc(numberOfTouchesRequired) public var __objc_numberOfTouchesRequired: Int {
        get { numberOfTouchesRequired } set { numberOfTouchesRequired = newValue }
    }
}
// MARK: - UIColor (NSObject-derived since simplenote-objc-core)

// UIColor.h spells the named colors as class properties `<name>Color`
// (`clearColor`, `labelColor`, `systemBackgroundColor`, ...) and the
// component factories as `colorWithRed:green:blue:alpha:` /
// `colorWithWhite:alpha:`. Each twin returns OpenUIKit's own color.
extension UIColor {
    @objc(clearColor) public class var __objc_clearColor: UIColor { UIColor.clear }
    @objc(blackColor) public class var __objc_blackColor: UIColor { UIColor.black }
    @objc(whiteColor) public class var __objc_whiteColor: UIColor { UIColor.white }
    @objc(redColor) public class var __objc_redColor: UIColor { UIColor.red }
    @objc(greenColor) public class var __objc_greenColor: UIColor { UIColor.green }
    @objc(blueColor) public class var __objc_blueColor: UIColor { UIColor.blue }
    @objc(grayColor) public class var __objc_grayColor: UIColor { UIColor.gray }
    @objc(lightGrayColor) public class var __objc_lightGrayColor: UIColor { UIColor.lightGray }
    @objc(darkGrayColor) public class var __objc_darkGrayColor: UIColor { UIColor.darkGray }
    @objc(yellowColor) public class var __objc_yellowColor: UIColor { UIColor.yellow }
    @objc(orangeColor) public class var __objc_orangeColor: UIColor { UIColor.orange }
    @objc(purpleColor) public class var __objc_purpleColor: UIColor { UIColor.purple }
    @objc(cyanColor) public class var __objc_cyanColor: UIColor { UIColor.cyan }
    @objc(magentaColor) public class var __objc_magentaColor: UIColor { UIColor.magenta }
    @objc(brownColor) public class var __objc_brownColor: UIColor { UIColor.brown }
    @objc(systemRedColor) public class var __objc_systemRedColor: UIColor { UIColor.systemRed }
    @objc(systemOrangeColor) public class var __objc_systemOrangeColor: UIColor { UIColor.systemOrange }
    @objc(systemYellowColor) public class var __objc_systemYellowColor: UIColor { UIColor.systemYellow }
    @objc(systemGreenColor) public class var __objc_systemGreenColor: UIColor { UIColor.systemGreen }
    @objc(systemMintColor) public class var __objc_systemMintColor: UIColor { UIColor.systemMint }
    @objc(systemTealColor) public class var __objc_systemTealColor: UIColor { UIColor.systemTeal }
    @objc(systemCyanColor) public class var __objc_systemCyanColor: UIColor { UIColor.systemCyan }
    @objc(systemBlueColor) public class var __objc_systemBlueColor: UIColor { UIColor.systemBlue }
    @objc(systemIndigoColor) public class var __objc_systemIndigoColor: UIColor { UIColor.systemIndigo }
    @objc(systemPurpleColor) public class var __objc_systemPurpleColor: UIColor { UIColor.systemPurple }
    @objc(systemPinkColor) public class var __objc_systemPinkColor: UIColor { UIColor.systemPink }
    @objc(systemBrownColor) public class var __objc_systemBrownColor: UIColor { UIColor.systemBrown }
    @objc(systemGrayColor) public class var __objc_systemGrayColor: UIColor { UIColor.systemGray }
    @objc(systemGray2Color) public class var __objc_systemGray2Color: UIColor { UIColor.systemGray2 }
    @objc(systemGray3Color) public class var __objc_systemGray3Color: UIColor { UIColor.systemGray3 }
    @objc(systemGray4Color) public class var __objc_systemGray4Color: UIColor { UIColor.systemGray4 }
    @objc(systemGray5Color) public class var __objc_systemGray5Color: UIColor { UIColor.systemGray5 }
    @objc(systemGray6Color) public class var __objc_systemGray6Color: UIColor { UIColor.systemGray6 }
    @objc(labelColor) public class var __objc_labelColor: UIColor { UIColor.label }
    @objc(secondaryLabelColor) public class var __objc_secondaryLabelColor: UIColor { UIColor.secondaryLabel }
    @objc(tertiaryLabelColor) public class var __objc_tertiaryLabelColor: UIColor { UIColor.tertiaryLabel }
    @objc(quaternaryLabelColor) public class var __objc_quaternaryLabelColor: UIColor { UIColor.quaternaryLabel }
    @objc(systemBackgroundColor) public class var __objc_systemBackgroundColor: UIColor { UIColor.systemBackground }
    @objc(secondarySystemBackgroundColor) public class var __objc_secondarySystemBackgroundColor: UIColor { UIColor.secondarySystemBackground }
    @objc(tertiarySystemBackgroundColor) public class var __objc_tertiarySystemBackgroundColor: UIColor { UIColor.tertiarySystemBackground }
    @objc(systemGroupedBackgroundColor) public class var __objc_systemGroupedBackgroundColor: UIColor { UIColor.systemGroupedBackground }
    @objc(secondarySystemGroupedBackgroundColor) public class var __objc_secondarySystemGroupedBackgroundColor: UIColor { UIColor.secondarySystemGroupedBackground }
    @objc(tertiarySystemGroupedBackgroundColor) public class var __objc_tertiarySystemGroupedBackgroundColor: UIColor { UIColor.tertiarySystemGroupedBackground }
    @objc(separatorColor) public class var __objc_separatorColor: UIColor { UIColor.separator }
    @objc(opaqueSeparatorColor) public class var __objc_opaqueSeparatorColor: UIColor { UIColor.opaqueSeparator }
    @objc(linkColor) public class var __objc_linkColor: UIColor { UIColor.link }
    @objc(placeholderTextColor) public class var __objc_placeholderTextColor: UIColor { UIColor.placeholderText }
    @objc(systemFillColor) public class var __objc_systemFillColor: UIColor { UIColor.systemFill }
    @objc(secondarySystemFillColor) public class var __objc_secondarySystemFillColor: UIColor { UIColor.secondarySystemFill }
    @objc(tertiarySystemFillColor) public class var __objc_tertiarySystemFillColor: UIColor { UIColor.tertiarySystemFill }
    @objc(quaternarySystemFillColor) public class var __objc_quaternarySystemFillColor: UIColor { UIColor.quaternarySystemFill }
    @objc(tintColorColor) public class var __objc_tintColorColor: UIColor { UIColor.tintColor }
    @objc(colorWithRed:green:blue:alpha:)
    public class func __objc_color(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) -> UIColor {
        UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
    @objc(colorWithWhite:alpha:)
    public class func __objc_color(white: CGFloat, alpha: CGFloat) -> UIColor { UIColor(white: white, alpha: alpha) }
    @objc(colorNamed:) public class func __objc_colorNamed(_ name: String) -> UIColor? { UIColor(named: name) }
    @objc(colorWithAlphaComponent:) public func __objc_withAlphaComponent(_ alpha: CGFloat) -> UIColor {
        withAlphaComponent(alpha)
    }
}

extension UIView {
    @objc(backgroundColor) public var __objc_backgroundColor: UIColor? {
        get { backgroundColor } set { backgroundColor = newValue }
    }
}

extension UILabel {
    // textColor is a native @objc member of UILabel now.
}

extension UITextField {
    @objc(textColor) public var __objc_textColor: UIColor? { get { textColor } set { textColor = newValue } }
}

extension UITextView {
    // UIKit declares the property nullable; OpenUIKit's is not, so nil
    // restores OpenUIKit's own initial value (UITextView.swift).
    @objc(textColor) public var __objc_textColor: UIColor? { get { textColor } set { textColor = newValue ?? .label } }
}

// MARK: - CGColorRef (UIColor.CGColor, CALayer's color properties)

// Objective-C passes colors to Core Animation as CoreGraphics `CGColorRef`
// (`layer.borderColor = color.CGColor`) and reads them back with
// CGColorGetComponents / CGColorGetAlpha. Since cg-unify OpenUIKit's Swift
// `CGColor` IS CoreGraphics' on this toolchain, so the Objective-C twins
// hand the same object through. The model is kept by `UIColor.cgColor`: a
// gray color (white, clear, `colorWithWhite:alpha:`) is a 2-component gray
// CGColor, everything else 4-component sRGB — iOS 26.1, objcsurfaceprobe
// `## cgcolor` (`whiteColor n=2 [1 1]`, `redColor n=4`).

extension UIColor {
    /// The color resolved in the current trait environment, as UIKit's
    /// `CGColor` property does.
    @objc(CGColor) public var __objc_CGColor: CoreGraphics.CGColor { cgColor }
    @objc(colorWithCGColor:) public class func __objc_color(cgColor: CoreGraphics.CGColor) -> UIColor {
        UIColor(cgColor: cgColor)
    }
}

extension CALayer {
    @objc(borderColor) public var __objc_borderColor: CoreGraphics.CGColor? {
        get { borderColor } set { borderColor = newValue }
    }
    @objc(backgroundColor) public var __objc_backgroundColor: CoreGraphics.CGColor? {
        get { backgroundColor } set { backgroundColor = newValue }
    }
    @objc(shadowColor) public var __objc_shadowColor: CoreGraphics.CGColor? {
        get { shadowColor } set { shadowColor = newValue }
    }
}

// MARK: - UIView.layer, font properties

extension UIView {
    @objc(layer) public var __objc_layer: CALayer { layer }
}

extension UILabel {
    // font is a native @objc member of UILabel now.
}

extension UITextField {
    @objc(font) public var __objc_font: UIFont? { get { font } set { font = newValue } }
}

extension UITextView {
    @objc(font) public var __objc_font: UIFont? { get { font } set { font = newValue } }
}
// MARK: - UIVisualEffectView / UIBlurEffect, UIView.transform / contentMode / animations

// The eidolon pod census ranked these next (docs/agent_reports/objc-surface.md).
// Raw values are the iOS 26.1 SDK's; each body is one OpenUIKit call.

extension UIVisualEffectView {
    @objc(initWithEffect:) public convenience init(__objcEffect effect: UIVisualEffect?) { self.init(effect: effect) }
    @objc(contentView) public var __objc_contentView: UIView { contentView }
    @objc(effect) public var __objc_effect: UIVisualEffect? { get { effect } set { effect = newValue } }
}

extension UIBlurEffect {
    /// `+effectWithStyle:`; a raw value UIKit does not define fails closed
    /// to the inert `UIBlurEffect()`.
    @objc(effectWithStyle:) public class func __objc_effect(style: Int) -> UIBlurEffect {
        Style(rawValue: style).map { UIBlurEffect(style: $0) } ?? UIBlurEffect()
    }
}

/// UIViewContentMode's SDK order (UIView.h) is OpenUIKit's case order.
private let contentModes: [UIViewContentMode] = [
    .scaleToFill, .scaleAspectFit, .scaleAspectFill, .redraw, .center, .top, .bottom,
    .left, .right, .topLeft, .topRight, .bottomLeft, .bottomRight,
]

extension UIView {
    /// OpenUIKit's CGAffineTransform is OpenCoreGraphics' struct; Objective-C
    /// passes CoreGraphics' C struct with the same six fields.
    @objc(transform) public var __objc_transform: CoreGraphics.CGAffineTransform {
        get {
            let t = transform
            return CoreGraphics.CGAffineTransform(a: t.a, b: t.b, c: t.c, d: t.d, tx: t.tx, ty: t.ty)
        }
        set {
            transform = OpenCoreGraphics.CGAffineTransform(a: newValue.a, b: newValue.b, c: newValue.c,
                                                           d: newValue.d, tx: newValue.tx, ty: newValue.ty)
        }
    }
    @objc(contentMode) public var __objc_contentMode: Int {
        get { contentModes.firstIndex(of: contentMode) ?? 0 }
        set { contentMode = contentModes.indices.contains(newValue) ? contentModes[newValue] : .scaleToFill }
    }
    @objc(addConstraint:) public func __objc_addConstraint(_ constraint: NSLayoutConstraint) { addConstraint(constraint) }
    @objc(animateWithDuration:animations:)
    public class func __objc_animate(withDuration duration: TimeInterval, animations: @escaping () -> Void) {
        animate(withDuration: duration, animations: animations)
    }
    @objc(animateWithDuration:animations:completion:)
    public class func __objc_animate(withDuration duration: TimeInterval, animations: @escaping () -> Void,
                                     completion: ((Bool) -> Void)?) {
        animate(withDuration: duration, animations: animations, completion: completion)
    }
    @objc(animateWithDuration:delay:options:animations:completion:)
    public class func __objc_animate(withDuration duration: TimeInterval, delay: TimeInterval, options: UInt,
                                     animations: @escaping () -> Void, completion: ((Bool) -> Void)?) {
        animate(withDuration: duration, delay: delay, options: AnimationOptions(rawValue: options),
                animations: animations, completion: completion)
    }
}

// MARK: - Auto Layout

extension NSLayoutConstraint {
    /// `+constraintWithItem:attribute:relatedBy:toItem:attribute:multiplier:constant:`.
    /// NSLayoutAttribute / NSLayoutRelation raw values equal OpenUIKit's
    /// (the support header's enums); an undefined raw value fails closed to
    /// `.notAnAttribute` / `.equal`.
    @objc(constraintWithItem:attribute:relatedBy:toItem:attribute:multiplier:constant:)
    public class func __objc_constraint(item view1: AnyObject, attribute attr1: Int, relatedBy relation: Int,
                                        toItem view2: AnyObject?, attribute attr2: Int,
                                        multiplier: CGFloat, constant: CGFloat) -> NSLayoutConstraint {
        NSLayoutConstraint(item: view1, attribute: Attribute(rawValue: attr1) ?? .notAnAttribute,
                           relatedBy: Relation(rawValue: relation) ?? .equal,
                           toItem: view2, attribute: Attribute(rawValue: attr2) ?? .notAnAttribute,
                           multiplier: multiplier, constant: constant)
    }
    @objc(constant) public var __objc_constant: CGFloat { get { constant } set { constant = newValue } }
    @objc(isActive) public var __objc_isActive: Bool { get { isActive } set { isActive = newValue } }
    @objc(setActive:) public func __objc_setActive(_ active: Bool) { isActive = active }
}

// MARK: - UIImage / UIImageView

extension UIImage {
    @objc(imageWithContentsOfFile:) public class func __objc_image(contentsOfFile path: String) -> UIImage? {
        UIImage(contentsOfFile: path)
    }
    @objc(initWithData:) public convenience init?(__objcData data: Data) { self.init(data: [UInt8](data)) }
    @objc(imageWithData:) public class func __objc_image(data: Data) -> UIImage? { UIImage(data: [UInt8](data)) }
    /// UIImageRenderingMode's SDK values: Automatic 0, AlwaysOriginal 1,
    /// AlwaysTemplate 2 (UIImage.h).
    @objc(imageWithRenderingMode:) public func __objc_withRenderingMode(_ mode: Int) -> UIImage {
        withRenderingMode(mode == 2 ? .alwaysTemplate : mode == 1 ? .alwaysOriginal : .automatic)
    }
    @objc(renderingMode) public var __objc_renderingMode: Int {
        switch renderingMode {
        case .automatic: return 0
        case .alwaysOriginal: return 1
        case .alwaysTemplate: return 2
        }
    }
}

// MARK: - UIButton / UIControl

extension UIControl {
    @objc(state) public var __objc_state: UInt { state.rawValue }
}

extension UIButton {
    @objc(titleLabel) public var __objc_titleLabel: UILabel? { titleLabel }
    @objc(imageView) public var __objc_imageView: UIImageView? { imageView }
    @objc(setTitle:forState:) public func __objc_setTitle(_ title: String?, forState state: UInt) {
        setTitle(title, for: State(rawValue: state))
    }
    @objc(setTitleColor:forState:) public func __objc_setTitleColor(_ color: UIColor?, forState state: UInt) {
        setTitleColor(color, for: State(rawValue: state))
    }
    @objc(setImage:forState:) public func __objc_setImage(_ image: UIImage?, forState state: UInt) {
        setImage(image, for: State(rawValue: state))
    }
    @objc(setBackgroundImage:forState:) public func __objc_setBackgroundImage(_ image: UIImage?, forState state: UInt) {
        setBackgroundImage(image, for: State(rawValue: state))
    }
}

// MARK: - UIApplication / UIScreen / UIColor

extension UIApplication {
    @objc(canOpenURL:) public func __objc_canOpenURL(_ url: URL) -> Bool { canOpenURL(url) }
    /// Deprecated since iOS 10 (UIApplication.h); OpenUIKit's
    /// `open(_:options:completionHandler:)` with no completion.
    @objc(openURL:) public func __objc_openURL(_ url: URL) -> Bool {
        let can = canOpenURL(url)
        open(url, options: [:], completionHandler: nil)
        return can
    }
}

extension UIScreen {
    @objc(mainScreen) public class var __objc_mainScreen: UIScreen { UIScreen.main }
    @objc(bounds) public var __objc_bounds: CGRect { bounds }
    @objc(scale) public var __objc_scale: CGFloat { scale }
}

extension UIColor {
    @objc(colorWithHue:saturation:brightness:alpha:)
    public class func __objc_color(hue: CGFloat, saturation: CGFloat, brightness: CGFloat, alpha: CGFloat) -> UIColor {
        UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: alpha)
    }
}
// MARK: - Alerts, bar button items, collection index paths (Simplenote / eidolon census)

extension UIAlertAction {
    /// UIAlertActionStyle raw values equal OpenUIKit's (alertprobe); an
    /// undefined one fails closed to `.default`.
    @objc(actionWithTitle:style:handler:)
    public class func __objc_action(title: String?, style: Int, handler: ((UIAlertAction) -> Void)?) -> UIAlertAction {
        UIAlertAction(title: title, style: Style(rawValue: style) ?? .default, handler: handler)
    }
    @objc(title) public var __objc_title: String? { title }
    @objc(style) public var __objc_style: Int { style.rawValue }
    @objc(isEnabled) public var __objc_isEnabled: Bool { isEnabled }
    @objc(setEnabled:) public func __objc_setEnabled(_ enabled: Bool) { isEnabled = enabled }
}

extension UIAlertController {
    /// UIAlertControllerStyle: ActionSheet 0, Alert 1 (UIAlertController.h).
    @objc(alertControllerWithTitle:message:preferredStyle:)
    public class func __objc_alertController(title: String?, message: String?, preferredStyle: Int) -> UIAlertController {
        UIAlertController(title: title, message: message, preferredStyle: preferredStyle == 1 ? .alert : .actionSheet)
    }
    @objc(addAction:) public func __objc_addAction(_ action: UIAlertAction) { addAction(action) }
    @objc(actions) public var __objc_actions: [UIAlertAction] { actions }
    @objc(message) public var __objc_message: String? { get { message } set { message = newValue } }
}

/// UIBarButtonSystemItem's SDK values: OpenUIKit's case order up to
/// UIBarButtonSystemItemRedo (22); PageCurl (23) has no OpenUIKit item;
/// Close is 24 (UIBarButtonItem.h).
private func barSystemItem(_ raw: Int) -> UIBarButtonItem.SystemItem? {
    if raw == 24 { return .close }
    guard raw >= 0, raw <= 22 else { return nil }
    return UIBarButtonItem.SystemItem.allCases[raw]
}

extension UIBarButtonItem {
    /// UIBarButtonItemStyle: Plain 0, Done/Prominent 2 map to OpenUIKit's
    /// styles; the deprecated Bordered (1) and undefined values fail closed
    /// to `.plain`.
    @objc(initWithTitle:style:target:action:)
    public convenience init(__objcTitle title: String?, style: Int, target: AnyObject?, action: Selector?) {
        self.init(title: title, style: Style(rawValue: style) ?? .plain, target: target, action: action)
    }
    @objc(initWithImage:style:target:action:)
    public convenience init(__objcImage image: UIImage?, style: Int, target: AnyObject?, action: Selector?) {
        self.init(image: image, style: Style(rawValue: style) ?? .plain, target: target, action: action)
    }
    /// PageCurl has no OpenUIKit item: it fails closed to an untitled
    /// plain item with the same target and action.
    @objc(initWithBarButtonSystemItem:target:action:)
    public convenience init(__objcSystemItem systemItem: Int, target: AnyObject?, action: Selector?) {
        if let item = barSystemItem(systemItem) {
            self.init(barButtonSystemItem: item, target: target, action: action)
        } else {
            self.init(title: nil, style: .plain, target: target, action: action)
        }
    }
}

/// UIKit's `NSIndexPath (UICollectionViewAdditions)`: `item` is index
/// position 1, as `row` is (UICollectionView.h). AppKit implements the same
/// category on macOS (see `row` above).
#if !canImport(AppKit)
extension NSIndexPath {
    @objc(item) public var __objc_item: Int { index(atPosition: 1) }
    @objc(indexPathForItem:inSection:) public class func __objc_indexPath(forItem item: Int, inSection section: Int) -> NSIndexPath {
        NSIndexPath(indexes: [section, item], length: 2)
    }
}
#endif

extension UIView {
    @objc(animateWithDuration:delay:usingSpringWithDamping:initialSpringVelocity:options:animations:completion:)
    public class func __objc_animate(withDuration duration: TimeInterval, delay: TimeInterval,
                                     usingSpringWithDamping dampingRatio: CGFloat,
                                     initialSpringVelocity velocity: CGFloat, options: UInt,
                                     animations: @escaping () -> Void, completion: ((Bool) -> Void)?) {
        animate(withDuration: duration, delay: delay, usingSpringWithDamping: dampingRatio,
                initialSpringVelocity: velocity, options: AnimationOptions(rawValue: options),
                animations: animations, completion: completion)
    }
}

// MARK: - Eidolon's CocoaPods (eidolon-first-screen)
//
// Selectors FLKAutoLayout, ORStackView, Artsy+UILabels, Artsy-UIButtons,
// SDWebImage and NJKWebViewProgress send, as forwarding twins; values checked
// line for line against the iOS 26.1 simulator by Tests/PodSurfaceTests
// (Tools/oracle2/podsurfaceprobe/transcript-ios26.1.txt).

private func lineBreakModeRaw(_ mode: NSLineBreakMode) -> Int {
    switch mode {
    case .byWordWrapping: return 0
    case .byCharWrapping: return 1
    case .byClipping: return 2
    case .byTruncatingHead: return 3
    case .byTruncatingTail: return 4
    case .byTruncatingMiddle: return 5
    }
}
private func podLineBreakMode(_ raw: Int) -> NSLineBreakMode {
    switch raw {
    case 1: return .byCharWrapping
    case 2: return .byClipping
    case 3: return .byTruncatingHead
    case 4: return .byTruncatingTail
    case 5: return .byTruncatingMiddle
    default: return .byWordWrapping
    }
}
private func podTextAlignment(_ raw: Int) -> NSTextAlignment { NSTextAlignment(rawValue: raw) ?? .natural }

extension UIView {
    @objc(translatesAutoresizingMaskIntoConstraints) public var __objc_translatesAutoresizingMaskIntoConstraints: Bool {
        get { translatesAutoresizingMaskIntoConstraints } set { translatesAutoresizingMaskIntoConstraints = newValue }
    }
    @objc(isOpaque) public var __objc_isOpaque: Bool { get { isOpaque } set { isOpaque = newValue } }
    @objc(opaque) public var __objc_opaque: Bool { get { isOpaque } set { isOpaque = newValue } }
    @objc(window) public var __objc_window: UIWindow? { window }
}

extension NSLayoutConstraint {
    @objc(priority) public var __objc_priority: Float {
        get { priority.rawValue } set { priority = UILayoutPriority(rawValue: newValue) }
    }
}

extension UILabel {
    @objc(textAlignment) public var __objc_textAlignment: Int {
        get { textAlignment.rawValue } set { textAlignment = podTextAlignment(newValue) }
    }
    @objc(lineBreakMode) public var __objc_lineBreakMode: Int {
        get { lineBreakModeRaw(lineBreakMode) } set { lineBreakMode = podLineBreakMode(newValue) }
    }
}

extension NSParagraphStyle {
    @objc(lineSpacing) public var __objc_lineSpacing: CGFloat { lineSpacing }
    @objc(alignment) public var __objc_alignment: Int { alignment.rawValue }
    @objc(paragraphSpacing) public var __objc_paragraphSpacing: CGFloat { paragraphSpacing }
    @objc(paragraphSpacingBefore) public var __objc_paragraphSpacingBefore: CGFloat { paragraphSpacingBefore }
    @objc(firstLineHeadIndent) public var __objc_firstLineHeadIndent: CGFloat { firstLineHeadIndent }
    @objc(headIndent) public var __objc_headIndent: CGFloat { headIndent }
}

extension NSMutableParagraphStyle {
    @objc(setLineSpacing:) public func __objc_setLineSpacing(_ v: CGFloat) { lineSpacing = v }
    @objc(setAlignment:) public func __objc_setAlignment(_ v: Int) { alignment = podTextAlignment(v) }
    @objc(setParagraphSpacing:) public func __objc_setParagraphSpacing(_ v: CGFloat) { paragraphSpacing = v }
    @objc(setParagraphSpacingBefore:) public func __objc_setParagraphSpacingBefore(_ v: CGFloat) { paragraphSpacingBefore = v }
    @objc(setFirstLineHeadIndent:) public func __objc_setFirstLineHeadIndent(_ v: CGFloat) { firstLineHeadIndent = v }
    @objc(setHeadIndent:) public func __objc_setHeadIndent(_ v: CGFloat) { headIndent = v }
}

extension UIButton {
    @objc(contentEdgeInsets) public var __objc_contentEdgeInsets: OpenUIKitObjCSupport.UIEdgeInsetsObjC {
        get { edgeInsets(contentEdgeInsets) } set { contentEdgeInsets = edgeInsets(newValue) }
    }
}


extension UIActivityIndicatorView {
    /// `-initWithActivityIndicatorStyle:` (SDWebImage UIImageView+WebCache),
    /// including the deprecated 0/1/2 styles.
    @objc(initWithActivityIndicatorStyle:) public convenience init(__objcStyle raw: Int) {
        self.init(style: UIActivityIndicatorView.Style(rawValue: raw) ?? .medium)
    }
    @objc(activityIndicatorViewStyle) public var __objc_activityIndicatorViewStyle: Int {
        get { style.rawValue } set { style = UIActivityIndicatorView.Style(rawValue: newValue) ?? .medium }
    }
    @objc(color) public var __objc_color: UIColor? { get { color } set { color = newValue } }
    @objc(hidesWhenStopped) public var __objc_hidesWhenStopped: Bool {
        get { hidesWhenStopped } set { hidesWhenStopped = newValue }
    }
}


extension UIButton {
    /// `+buttonWithType:`. OpenUIKit has custom (0) and system (1); the
    /// SDK's other system-drawn types (detailDisclosure 2 … close 7) build a
    /// system button without their glyph.
    @objc(buttonWithType:) public class func __objc_button(withType raw: Int) -> UIButton {
        UIButton(type: raw == 0 ? .custom : .system)
    }
}

extension UIColor {
    @objc(getRed:green:blue:alpha:) public func __objc_getRed(
        _ red: UnsafeMutablePointer<CGFloat>?, green: UnsafeMutablePointer<CGFloat>?,
        blue: UnsafeMutablePointer<CGFloat>?, alpha: UnsafeMutablePointer<CGFloat>?) -> Bool {
        getRed(red, green: green, blue: blue, alpha: alpha)
    }
    @objc(getWhite:alpha:) public func __objc_getWhite(
        _ white: UnsafeMutablePointer<CGFloat>?, alpha: UnsafeMutablePointer<CGFloat>?) -> Bool {
        getWhite(white, alpha: alpha)
    }
}


extension UIImage {
    @objc(images) public var __objc_images: [UIImage]? { images }
    @objc(duration) public var __objc_duration: TimeInterval { duration }
    @objc(animatedImageWithImages:duration:)
    public class func __objc_animatedImage(with images: [UIImage], duration: TimeInterval) -> UIImage? {
        animatedImage(with: images, duration: duration)
    }
}

extension UIApplication {
    /// iOS types it `id<UIApplicationDelegate>` (NJKWebViewProgressView reads
    /// `.delegate.window` through it); the object is the same one `delegate`
    /// returns.
    @objc(delegate) public var __objc_typedDelegate: UIApplicationDelegateObjC? {
        (delegate as AnyObject?).map { unsafeBitCast($0, to: UIApplicationDelegateObjC.self) }
    }
}


extension NSLayoutConstraint {
    /// ORStackView: `+constraintsWithVisualFormat:options:metrics:views:`.
    @objc(constraintsWithVisualFormat:options:metrics:views:)
    public class func __objc_constraints(withVisualFormat format: String, options: UInt,
                                          metrics: [String: Any]?, views: [String: Any]) -> [NSLayoutConstraint] {
        constraints(withVisualFormat: format, options: FormatOptions(rawValue: options), metrics: metrics, views: views)
    }
}

extension UIView {
    @objc(addConstraints:) public func __objc_addConstraints(_ constraints: [NSLayoutConstraint]) {
        addConstraints(constraints)
    }
    @objc(removeConstraint:) public func __objc_removeConstraint(_ constraint: NSLayoutConstraint?) {
        if let constraint { removeConstraint(constraint) }
    }
    @objc(removeConstraints:) public func __objc_removeConstraints(_ constraints: [NSLayoutConstraint]) {
        removeConstraints(constraints)
    }
}


extension NSLayoutConstraint {
    @objc(firstItem) public var __objc_firstItem: AnyObject? { firstItem }
    @objc(secondItem) public var __objc_secondItem: AnyObject? { secondItem }
    @objc(firstAttribute) public var __objc_firstAttribute: Int { firstAttribute.rawValue }
    @objc(secondAttribute) public var __objc_secondAttribute: Int { secondAttribute.rawValue }
    @objc(relation) public var __objc_relation: Int { relation.rawValue }
    @objc(multiplier) public var __objc_multiplier: CGFloat { multiplier }
}

extension UIView {
    @objc(layoutMarginsGuide) public var __objc_layoutMarginsGuide: UILayoutGuide { layoutMarginsGuide }
}


extension UIPasteboard {
    @objc(generalPasteboard) public class var __objc_general: UIPasteboard { general }
    @objc(pasteboardWithUniqueName) public class func __objc_withUniqueName() -> UIPasteboard { withUniqueName() }
    @objc(removePasteboardWithName:) public class func __objc_remove(withName name: String) {
        remove(withName: Name(name))
    }
    @objc(name) public var __objc_name: String { name.rawValue }
    @objc(string) public var __objc_string: String? { get { string } set { string = newValue } }
    @objc(URL) public var __objc_URL: URL? { get { url } set { url = newValue } }
    @objc(numberOfItems) public var __objc_numberOfItems: Int { numberOfItems }
    @objc(hasStrings) public var __objc_hasStrings: Bool { hasStrings }
    @objc(hasURLs) public var __objc_hasURLs: Bool { hasURLs }
}

extension UIWindow {
    @objc(windowLevel) public var __objc_windowLevel: CGFloat {
        get { windowLevel.rawValue } set { windowLevel = UIWindow.Level(newValue) }
    }
}

#endif
