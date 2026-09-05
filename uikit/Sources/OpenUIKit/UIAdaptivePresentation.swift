// Adaptive-presentation delegates + UIPopoverPresentationController.
// Owner: viewcontroller module (M13 "delegate protocols" cluster,
// docs/APP_COMPAT.md #4).
//
// The census counts 9 uses of UIAdaptivePresentationControllerDelegate, 14 of
// UISheetPresentationControllerDelegate and 10 of
// UIPopoverPresentationControllerDelegate across three of the four corpus
// apps — every one of them a CONFORMANCE, i.e. a compile error before any
// behaviour is missing. All three exist here with UIKit's exact member names
// and default (no-op) implementations.
//
// WHAT IS REALLY WIRED (the rest are declarations, honestly):
//   - `presentationControllerShouldDismiss(_:)` gates the interactive sheet
//     drag exactly like `isModalInPresentation` does — a false answer springs
//     the sheet back and then reports
//     `presentationControllerDidAttemptToDismiss(_:)`.
//   - `presentationControllerWillDismiss(_:)` fires when a user-driven
//     dismissal commits, `presentationControllerDidDismiss(_:)` when its
//     teardown finishes. Like UIKit, NEITHER fires for a programmatic
//     `dismiss(animated:)` — they report user intent.
//   - `adaptivePresentationStyle(for:)` is consulted by
//     UIPopoverPresentationController (below).
//
// POPOVERS. Real UIKit shows a popover only in a horizontally REGULAR
// environment; on an iPhone-width screen it adapts, and the default
// adaptation is `.fullScreen`. Compact-width OpenUIKit still ALWAYS takes
// the adaptive path (default `.pageSheet`) — that is real UIKit behaviour
// on the phone, and `DelegateProtocolTests.testPopoverAdaptsToASheet`
// pins it. Pad regular width does not adapt: MEASURED Modal-ipad t9200,
// iPad (A16) 820×1180 @2x / iOS 26.1, `_UIPopoverView [561, 62, 240, 180]`
// with trailing inset 19 and y = SA.top + 30; t7200 action sheet is a
// 288×248 popover centred on sourceRect, cancel dropped, dim alpha 0.

// MARK: - UIAdaptivePresentationControllerDelegate

@preconcurrency @MainActor
public protocol UIAdaptivePresentationControllerDelegate: AnyObject {
    func adaptivePresentationStyle(for controller: UIPresentationController)
        -> UIModalPresentationStyle
    func adaptivePresentationStyle(for controller: UIPresentationController,
                                   traitCollection: UITraitCollection)
        -> UIModalPresentationStyle
    func presentationController(_ controller: UIPresentationController,
                                viewControllerForAdaptivePresentationStyle style: UIModalPresentationStyle)
        -> UIViewController?
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool
    func presentationControllerWillDismiss(_ presentationController: UIPresentationController)
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController)
    func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController)
}

public extension UIAdaptivePresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController)
        -> UIModalPresentationStyle { .automatic }
    func adaptivePresentationStyle(for controller: UIPresentationController,
                                   traitCollection: UITraitCollection)
        -> UIModalPresentationStyle { adaptivePresentationStyle(for: controller) }
    func presentationController(_ controller: UIPresentationController,
                                viewControllerForAdaptivePresentationStyle style: UIModalPresentationStyle)
        -> UIViewController? { nil }
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool { true }
    func presentationControllerWillDismiss(_ presentationController: UIPresentationController) {}
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {}
    func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {}
}

// MARK: - UISheetPresentationControllerDelegate

/// UIKit's sheet delegate refines the adaptive one. Detents are not modelled
/// (the sheet has exactly one, full-height detent — docs/KNOWN_GAPS.md), so
/// the detent callback is a declaration and never fires.
@preconcurrency @MainActor
public protocol UISheetPresentationControllerDelegate: UIAdaptivePresentationControllerDelegate {
    func sheetPresentationControllerDidChangeSelectedDetentIdentifier(
        _ sheetPresentationController: UISheetPresentationController)
}

public extension UISheetPresentationControllerDelegate {
    func sheetPresentationControllerDidChangeSelectedDetentIdentifier(
        _ sheetPresentationController: UISheetPresentationController) {}
}

// MARK: - UIPopoverPresentationControllerDelegate

@available(iOS 8.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@preconcurrency @MainActor
public protocol UIPopoverPresentationControllerDelegate: UIAdaptivePresentationControllerDelegate {
    func prepareForPopoverPresentation(_ popoverPresentationController: UIPopoverPresentationController)
    func popoverPresentationControllerShouldDismissPopover(
        _ popoverPresentationController: UIPopoverPresentationController) -> Bool
    func popoverPresentationControllerDidDismissPopover(
        _ popoverPresentationController: UIPopoverPresentationController)
}

public extension UIPopoverPresentationControllerDelegate {
    func prepareForPopoverPresentation(_ popoverPresentationController: UIPopoverPresentationController) {}
    func popoverPresentationControllerShouldDismissPopover(
        _ popoverPresentationController: UIPopoverPresentationController) -> Bool { true }
    func popoverPresentationControllerDidDismissPopover(
        _ popoverPresentationController: UIPopoverPresentationController) {}
}

// MARK: - UIPopoverPresentationController

/// The anchor properties exist so that the ubiquitous
/// `ac.popoverPresentationController?.sourceView = view` line compiles and
/// carries its information; nothing draws an arrow (see the file header).
@available(iOS 8.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@preconcurrency @MainActor
open class UIPopoverPresentationController: UIPresentationController {
    public weak var sourceView: UIView?
    public var sourceRect: CGRect = .zero
    /// Anchor for a popover presented from a bar button. Stored so
    /// `popover.barButtonItem = navigationItem.rightBarButtonItem` compiles
    /// against both UIKits (Sources/ConformanceApps/Modal). On this device
    /// class the popover still adapts to a sheet (see the file header).
    public weak var barButtonItem: UIBarButtonItem?
    public var permittedArrowDirections: UIPopoverArrowDirection = .any
    /// UIKit defaults to nil. OpenUIKit retains the requested popover chrome
    /// color even though compact-width presentations adapt to a sheet and no
    /// regular-width popover chrome is drawn yet.
    @available(iOS 8.0, *)
    @available(visionOS, unavailable)
    open var backgroundColor: UIColor?
    public weak var popoverDelegate: UIPopoverPresentationControllerDelegate? {
        get { delegate as? UIPopoverPresentationControllerDelegate }
        set { delegate = newValue }
    }

    /// iOS cut AND pad idiom. Compact-width (phone) still adapts to a
    /// sheet; regular-width pad stays a popover.
    var isPadRegular: Bool {
        OpenUIKitRuntime.systemFontCut == .iOS
            && (UITraitCollection.current.userInterfaceIdiom == .pad
                || UIDevice.current.userInterfaceIdiom == .pad)
    }

    /// The style this popover adapts to on this device class. Compact
    /// width (phone) adapts to a sheet. Pad regular width stays a popover.
    /// MEASURED Modal-ipad t9200, iPad (A16) 820×1180 @2x / iOS 26.1:
    /// `_UIPopoverView [561, 62, 240, 180]` (preferredContentSize); phone
    /// still adapts (DelegateProtocolTests.testPopoverAdaptsToASheet).
    public var adaptedStyle: UIModalPresentationStyle {
        if isPadRegular { return .popover }
        let style = delegate?.adaptivePresentationStyle(for: self) ?? .automatic
        switch style {
        // `.popover` here would mean "stay a popover", which compact width
        // never does — it adapts, like UIKit on an iPhone.
        case .automatic, .fullScreen, .popover, .formSheet: return .pageSheet
        case .pageSheet, .alert, .currentContext, .custom,
             .overFullScreen, .overCurrentContext, .none:
            return style
        }
    }

    /// MEASURED Modal-ipad t9200: popover trailing edge is 19 pt from the
    /// 820 pt window (`820 − 240 − 561 = 19`).
    static let iOSPadTrailingInset: CGFloat = 19
    /// MEASURED Modal-ipad t9200: popover y = window SA.top + 30
    /// (32 + 30 = 62) for a bar-button source in the 54 pt inline bar.
    static let iOSPadTopBelowSafeArea: CGFloat = 30

    let dim = _UIDimmingView()

    /// MEASURED Modal-ipad t9200: `_UIPopoverView [561, 62, 240, 180]` =
    /// `preferredContentSize`, trailing inset 19, y = SA.top + 30.
    /// Action-sheet popovers are laid out by `_UIAlertPresentationController`
    /// (Modal-ipad t7200).
    public override var frameOfPresentedViewInContainerView: CGRect {
        guard let c = containerView else { return .zero }
        let size = presentedViewController.preferredContentSize
        guard size.width > 0, size.height > 0 else { return c.bounds }
        let x = c.bounds.width - size.width - Self.iOSPadTrailingInset
        let y = c.safeAreaInsets.top + Self.iOSPadTopBelowSafeArea
        return CGRect(x: x, y: y, width: size.width, height: size.height)
    }

    public override func presentationTransitionWillBegin() {
        guard let container = containerView else { return }
        dim.frame = container.bounds
        dim.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        // MEASURED Modal-ipad t9200 / t7200: `_UIPopoverDimmingView`
        // `bg [0, 0, 0, 0]` — the presenter is not dimmed. Phone sheets
        // keep the 0.2 black dim.
        dim.backgroundColor = .clear
        dim.alpha = 0
        container.addSubview(dim)
        presentedViewController.loadViewIfNeeded()
        let cv = presentedViewController.view!
        if cv.backgroundColor == nil { cv.backgroundColor = .systemBackground }
        cv.frame = frameOfPresentedViewInContainerView
        cv.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin,
                               .flexibleTopMargin, .flexibleBottomMargin]
        container.addSubview(cv)
    }

    public override func dismissalTransitionDidEnd(_ completed: Bool) {
        guard completed else { return }
        presentedViewController.viewIfLoaded?.removeFromSuperview()
        dim.removeFromSuperview()
        containerView?.removeFromSuperview()
    }
}

public struct UIPopoverArrowDirection: OptionSet, Sendable {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }
    public static let up = UIPopoverArrowDirection(rawValue: 1 << 0)
    public static let down = UIPopoverArrowDirection(rawValue: 1 << 1)
    public static let left = UIPopoverArrowDirection(rawValue: 1 << 2)
    public static let right = UIPopoverArrowDirection(rawValue: 1 << 3)
    public static let any: UIPopoverArrowDirection = [.up, .down, .left, .right]
    public static let unknown = UIPopoverArrowDirection(rawValue: 1 << 4)
}
