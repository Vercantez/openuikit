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
// adaptation is `.fullScreen`. OpenUIKit targets iPhone geometry and has no
// measured popover chrome, so `UIPopoverPresentationController` ALWAYS takes
// the adaptive path — it is a presentation controller that asks its delegate
// for an adaptive style and presents as that style (default `.pageSheet`,
// which is what `.automatic`/`.fullScreen` resolve to here). That is real
// UIKit behaviour on this device class, not a stub, but an app running on an
// iPad-sized window would get a sheet where UIKit draws an arrow-anchored
// popover. See docs/KNOWN_GAPS.md.

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

    /// The style this popover adapts to on this device class. The delegate
    /// gets UIKit's say; `.automatic` and `.fullScreen` both land on the
    /// sheet, which is what OpenUIKit can actually draw.
    public var adaptedStyle: UIModalPresentationStyle {
        let style = delegate?.adaptivePresentationStyle(for: self) ?? .automatic
        switch style {
        // `.popover` here would mean "stay a popover", which this device
        // class never does — it adapts, like UIKit on a compact width.
        case .automatic, .fullScreen, .popover, .formSheet: return .pageSheet
        case .pageSheet, .alert, .currentContext, .custom,
             .overFullScreen, .overCurrentContext, .none:
            return style
        }
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
