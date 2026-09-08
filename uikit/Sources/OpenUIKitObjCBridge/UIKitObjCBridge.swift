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
import Foundation
import ObjectiveC
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
private func edgeInsets(_ insets: OpenUIKit.UIEdgeInsets) -> OpenUIKitObjCSupport.UIEdgeInsets {
    OpenUIKitObjCSupport.UIEdgeInsets(top: insets.top, left: insets.left, bottom: insets.bottom, right: insets.right)
}
private func edgeInsets(_ insets: OpenUIKitObjCSupport.UIEdgeInsets) -> OpenUIKit.UIEdgeInsets {
    OpenUIKit.UIEdgeInsets(top: insets.top, left: insets.left, bottom: insets.bottom, right: insets.right)
}

// MARK: - UIResponder

extension UIResponder {
    @objc(becomeFirstResponder) @discardableResult public func __objc_becomeFirstResponder() -> Bool { becomeFirstResponder() }
    @objc(resignFirstResponder) @discardableResult public func __objc_resignFirstResponder() -> Bool { resignFirstResponder() }
    @objc(isFirstResponder) public var __objc_isFirstResponder: Bool { isFirstResponder }
}

// MARK: - UIView

extension UIView {
    @objc(initWithFrame:) public convenience init(__objcFrame frame: CGRect) { self.init(frame: frame) }
    @objc(frame) public var __objc_frame: CGRect { get { frame } set { frame = newValue } }
    @objc(bounds) public var __objc_bounds: CGRect { get { bounds } set { bounds = newValue } }
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
    @objc(layoutSubviews) public func __objc_layoutSubviews() { layoutSubviews() }
    @objc(setNeedsDisplay) public func __objc_setNeedsDisplay() { setNeedsDisplay() }
    @objc(sizeToFit) public func __objc_sizeToFit() { sizeToFit() }
    @objc(sizeThatFits:) public func __objc_sizeThatFits(_ size: CGSize) -> CGSize { sizeThatFits(size) }
    @objc(safeAreaInsets) public var __objc_safeAreaInsets: OpenUIKitObjCSupport.UIEdgeInsets { edgeInsets(safeAreaInsets) }
    @objc(addGestureRecognizer:) public func __objc_addGestureRecognizer(_ recognizer: UIGestureRecognizer) { addGestureRecognizer(recognizer) }
    @objc(removeGestureRecognizer:) public func __objc_removeGestureRecognizer(_ recognizer: UIGestureRecognizer) { removeGestureRecognizer(recognizer) }
    @objc(convertRect:toView:) public func __objc_convert(_ rect: CGRect, to view: UIView?) -> CGRect { convert(rect, to: view) }
    @objc(convertPoint:toView:) public func __objc_convert(_ point: CGPoint, to view: UIView?) -> CGPoint { convert(point, to: view) }
}

// MARK: - UIControl

extension UIControl {
    @objc(isEnabled) public var __objc_enabled: Bool { get { isEnabled } set { isEnabled = newValue } }
    @objc(enabled) public var __objc_enabledPlain: Bool { get { isEnabled } set { isEnabled = newValue } }
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
    @objc(contentInset) public var __objc_contentInset: OpenUIKitObjCSupport.UIEdgeInsets {
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
    @objc(text) public var __objc_text: String? { get { text } set { text = newValue } }
    @objc(numberOfLines) public var __objc_numberOfLines: Int { get { numberOfLines } set { numberOfLines = newValue } }
}

extension UITextView {
    @objc(text) public var __objc_text: String? { get { text } set { text = newValue ?? "" } }
    @objc(editable) public var __objc_editable: Bool { get { isEditable } set { isEditable = newValue } }
}

extension UITextField {
    @objc(text) public var __objc_text: String? { get { text } set { text = newValue } }
    @objc(placeholder) public var __objc_placeholder: String? { get { placeholder } set { placeholder = newValue } }
}

// MARK: - UIViewController

extension UIViewController {
    @objc(initWithNibName:bundle:) public convenience init(__objcNibName nibName: String?, bundle: Bundle?) {
        self.init(nibName: nibName, bundle: bundle)
    }
    @objc(view) public var __objc_view: UIView { get { view } set { view = newValue } }
    @objc(isViewLoaded) public var __objc_isViewLoaded: Bool { isViewLoaded }
    @objc(loadViewIfNeeded) public func __objc_loadViewIfNeeded() { loadViewIfNeeded() }
    @objc(title) public var __objc_title: String? { get { title } set { title = newValue } }
    @objc(viewDidLoad) public func __objc_viewDidLoad() { viewDidLoad() }
    @objc(viewWillAppear:) public func __objc_viewWillAppear(_ animated: Bool) { viewWillAppear(animated) }
    @objc(viewDidAppear:) public func __objc_viewDidAppear(_ animated: Bool) { viewDidAppear(animated) }
    @objc(viewWillDisappear:) public func __objc_viewWillDisappear(_ animated: Bool) { viewWillDisappear(animated) }
    @objc(viewDidDisappear:) public func __objc_viewDidDisappear(_ animated: Bool) { viewDidDisappear(animated) }
    @objc(viewWillLayoutSubviews) public func __objc_viewWillLayoutSubviews() { viewWillLayoutSubviews() }
    @objc(viewDidLayoutSubviews) public func __objc_viewDidLayoutSubviews() { viewDidLayoutSubviews() }
    @objc(parentViewController) public var __objc_parent: UIViewController? { parent }
    @objc(navigationController) public var __objc_navigationController: UINavigationController? { navigationController }
    @objc(presentingViewController) public var __objc_presentingViewController: UIViewController? { presentingViewController }
    @objc(presentedViewController) public var __objc_presentedViewController: UIViewController? { presentedViewController }
    @objc(childViewControllers) public var __objc_children: [UIViewController] { children }
    @objc(addChildViewController:) public func __objc_addChild(_ child: UIViewController) { addChild(child) }
    @objc(removeFromParentViewController) public func __objc_removeFromParent() { removeFromParent() }
    @objc(willMoveToParentViewController:) public func __objc_willMove(toParent parent: UIViewController?) { willMove(toParent: parent) }
    @objc(didMoveToParentViewController:) public func __objc_didMove(toParent parent: UIViewController?) { didMove(toParent: parent) }
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
    @objc(initWithRootViewController:) public convenience init(__objcRoot root: UIViewController) {
        self.init(rootViewController: root)
    }
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
    @objc(setNavigationBarHidden:animated:) public func __objc_setNavigationBarHidden(_ hidden: Bool, animated: Bool) {
        setNavigationBarHidden(hidden, animated: animated)
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
    @objc(delegate) public var __objc_delegate: AnyObject? { delegate as AnyObject? }
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
    @objc(initWithFrame:style:) public convenience init(__objcFrame frame: CGRect, style: Int) {
        self.init(frame: frame, style: tableStyle(style))
    }
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
    @objc(initWithStyle:reuseIdentifier:) public convenience init(__objcStyle style: Int, reuseIdentifier: String?) {
        self.init(style: cellStyle(style), reuseIdentifier: reuseIdentifier)
    }
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
    @objc(setSelected:animated:) public func __objc_setSelected(_ selected: Bool, animated: Bool) { setSelected(selected, animated: animated) }
    @objc(setHighlighted:animated:) public func __objc_setHighlighted(_ highlighted: Bool, animated: Bool) {
        setHighlighted(highlighted, animated: animated)
    }
    @objc(reuseIdentifier) public var __objc_reuseIdentifier: String? { reuseIdentifier }
    @objc(prepareForReuse) public func __objc_prepareForReuse() { prepareForReuse() }
}

/// UIKit's `NSIndexPath (UITableView)` category: `row` and `section` are
/// index positions 1 and 0 (UITableView.h).
extension NSIndexPath {
    @objc(row) public var __objc_row: Int { index(atPosition: 1) }
    @objc(section) public var __objc_section: Int { index(atPosition: 0) }
    @objc(indexPathForRow:inSection:) public class func __objc_indexPath(forRow row: Int, inSection section: Int) -> NSIndexPath {
        NSIndexPath(indexes: [section, row], length: 2)
    }
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
    @objc(initWithImage:) public convenience init(__objcImage image: UIImage?) { self.init(image: image) }
    @objc(image) public var __objc_image: UIImage? { get { image } set { image = newValue } }
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
#endif
