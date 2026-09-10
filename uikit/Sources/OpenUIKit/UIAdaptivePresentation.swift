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

/// Anchors, arrow and placement. MEASURED Tools/oracle2/wordpressrowsprobe,
/// iPad (A16) 820×1180 @2x / iOS 26.1, `preferredContentSize` 240×180,
/// window safe area top 32 (`ios-26.1-ipad-popover.json`):
///
///   sourceItem = right bar button   `_UIPopoverView [561, 62, 240, 180]`,
///                                   `arrowDirection` raw 0 (no arrow), no
///                                   chrome / shadow views
///   sourceItem = left bar button    `[19, 62, 240, 180]` — centred on the
///                                   item, clamped to a 19 pt margin
///   sourceItem = view [100,300,60,40]  `[160, 230, 253, 180]`, arrow .left:
///                                   x = view.maxX, width = 240 + 13 (the
///                                   arrow), centred on the view's midY
///   sourceItem = view [100,980,60,40]  `[160, 910, 253, 180]`, .left
///   sourceItem = tab bar item [412,1101,66,36]  `[325, 908, 240, 193]`,
///                                   arrow .down: maxY = item.minY, height
///                                   = 180 + 13, centred on the item's midX
///   sourceView = view / sourceRect (0,0,10,10)  `[110, 215, 253, 180]` —
///                                   sourceRect applies to sourceView AND to
///                                   a view sourceItem
///   permittedArrowDirections .down, view   `[19, 107, 240, 193]` (x clamped)
///   permittedArrowDirections .down, bar button   unchanged — bar buttons
///                                   ignore the mask and never grow an arrow
///   `sourceRect` default            CGRect.null
///   `arrowDirection` before presentation   `.unknown` (= NSUIntegerMax)
///   `sourceItem = view` leaves `sourceView` nil, `sourceView = v` leaves
///   `sourceItem` nil; `sourceItem = barButtonItem` sets `barButtonItem`
///   and `barButtonItem = item` reads back as `sourceItem`.
///   No source at all → iOS throws NSGenericException ("should have a
///   non-nil sourceView or barButtonItem"); the port keeps the pre-existing
///   trailing layout (Modal-ipad t9200) instead of throwing.
///
/// Direction choice for a view anchor, `.any`: the first of up / down /
/// left / right whose frame fits the window's 19 pt margins WITHOUT being
/// clamped, else the first permitted direction clamped. Fitted from four
/// oracle rows (view at y 300 and y 980 → .left even though "below" had
/// room but needed an x clamp; the tab item → .down; sourceRect → .left);
/// a forced `.right` on the oracle also squeezed the width to 111, which is
/// NOT modelled — the port clamps and keeps the width.
///
/// Compact width (iPhone 16, `ios-26.1-iphone16-popover.json`): every
/// source kind adapts to the same full-height sheet `[0, 59, 393, 793]`,
/// `arrowDirection` stays `.unknown`, and
/// `adaptiveSheetPresentationController.detents = [.medium()]` (WordPress's
/// ReaderCommentsFollowPresenter line) puts the medium detent on that sheet.
@available(iOS 8.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@preconcurrency @MainActor
open class UIPopoverPresentationController: UIPresentationController {
    public weak var sourceView: UIView?
    /// UIKit default is `CGRect.null` (MEASURED; the port previously said
    /// `.zero`) — "use the whole source".
    public var sourceRect: CGRect = CGRect.null
    /// Anchor for a popover presented from a bar button. MEASURED: mirrors
    /// `sourceItem` in both directions.
    public var barButtonItem: UIBarButtonItem? {
        get { _barButtonItem }
        set {
            _barButtonItem = newValue
            if let newValue {
                _sourceItem = newValue
            } else if _sourceItem is UIBarButtonItem {
                _sourceItem = nil
            }
        }
    }
    private weak var _barButtonItem: UIBarButtonItem?
    private var _sourceItem: (any UIPopoverPresentationControllerSourceItem)?
    /// iOS 16 anchor. Strong, like the SDK's (`strong, nullable`). Setting a
    /// bar button item here also sets `barButtonItem`; setting a view does
    /// NOT touch `sourceView` (MEASURED).
    public var sourceItem: (any UIPopoverPresentationControllerSourceItem)? {
        get { _sourceItem }
        set {
            _sourceItem = newValue
            _barButtonItem = newValue as? UIBarButtonItem
        }
    }
    public var permittedArrowDirections: UIPopoverArrowDirection = .any
    /// The arrow the presented popover ended up with. `.unknown` until the
    /// presentation lays out; raw 0 for a bar-button popover (no arrow).
    public private(set) var arrowDirection: UIPopoverArrowDirection = .unknown
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

    /// The sheet this popover becomes on compact width. UIKit's is
    /// non-optional; it is the presented controller's sheet controller, so
    /// detents set here reach the adapted presentation.
    public var adaptiveSheetPresentationController: UISheetPresentationController {
        let vc = presentedViewController
        if let existing = vc._sheetController { return existing }
        let c = UISheetPresentationController(presentedViewController: vc, presenting: nil)
        vc._sheetController = c
        return c
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

    /// MEASURED Modal-ipad t9200 and wordpressrowsprobe: 19 pt from every
    /// window edge (`820 − 240 − 561 = 19`; left item → x 19).
    static let iOSPadTrailingInset: CGFloat = 19
    static let iOSPadEdgeMargin: CGFloat = 19
    /// MEASURED Modal-ipad t9200 / wordpressrowsprobe: bar-button popover
    /// y = window SA.top + 30 (32 + 30 = 62) in the 54 pt inline bar.
    static let iOSPadTopBelowSafeArea: CGFloat = 30
    /// MEASURED: a view-anchored popover's frame grows by 13 on the arrow's
    /// axis (253 = 240 + 13, 193 = 180 + 13).
    static let iOSPadArrowSize: CGFloat = 13

    let dim = _UIDimmingView()

    /// The anchor rectangle in `container` coordinates, or nil when nothing
    /// anchors the popover (the pre-existing trailing layout then applies).
    func _anchorRect(in container: UIView) -> CGRect? {
        if let b = barButtonItem, let r = b.frame(in: container), r.width > 0 || r.height > 0 {
            return r
        }
        if barButtonItem != nil { return nil }
        let anchorView = (_sourceItem as? UIView) ?? sourceView
        if let v = anchorView {
            let rect = sourceRect.isNull ? v.bounds : sourceRect
            return v.convert(rect, to: container)
        }
        if let item = _sourceItem, let r = item.frame(in: container) {
            return r
        }
        return nil
    }

    /// Frame for `size` with the arrow on `direction`, unclamped.
    static func _frame(for direction: UIPopoverArrowDirection, anchor: CGRect,
                       size: CGSize) -> CGRect {
        let a = iOSPadArrowSize
        switch direction {
        case .up:
            return CGRect(x: anchor.midX - size.width / 2, y: anchor.maxY,
                          width: size.width, height: size.height + a)
        case .down:
            return CGRect(x: anchor.midX - size.width / 2, y: anchor.minY - size.height - a,
                          width: size.width, height: size.height + a)
        case .left:
            return CGRect(x: anchor.maxX, y: anchor.midY - size.height / 2,
                          width: size.width + a, height: size.height)
        default:
            return CGRect(x: anchor.minX - size.width - a, y: anchor.midY - size.height / 2,
                          width: size.width + a, height: size.height)
        }
    }

    /// Clamp into the container's 19 pt margins (top: below the safe area).
    static func _clamp(_ f: CGRect, in container: UIView) -> CGRect {
        let m = iOSPadEdgeMargin
        let b = container.bounds
        let top = Swift.max(m, container.safeAreaInsets.top)
        let bottom = Swift.max(m, container.safeAreaInsets.bottom)
        var r = f
        r.origin.x = Swift.min(Swift.max(r.origin.x, m), Swift.max(m, b.width - m - r.width))
        r.origin.y = Swift.min(Swift.max(r.origin.y, top), Swift.max(top, b.height - bottom - r.height))
        return r
    }

    /// (frame, arrow) for the current anchors. Bar buttons: no arrow, the
    /// content size below the bar, centred on the item and clamped.
    func _resolvedLayout(in container: UIView) -> (CGRect, UIPopoverArrowDirection)? {
        let size = presentedViewController.preferredContentSize
        guard size.width > 0, size.height > 0, let anchor = _anchorRect(in: container) else {
            return nil
        }
        if barButtonItem != nil {
            let y = container.safeAreaInsets.top + Self.iOSPadTopBelowSafeArea
            let f = CGRect(x: anchor.midX - size.width / 2, y: y,
                           width: size.width, height: size.height)
            return (Self._clamp(f, in: container), UIPopoverArrowDirection(rawValue: 0))
        }
        let order: [UIPopoverArrowDirection] = [.up, .down, .left, .right]
        let permitted = order.filter { permittedArrowDirections.contains($0) }
        guard !permitted.isEmpty else {
            let f = CGRect(x: anchor.midX - size.width / 2, y: anchor.maxY,
                           width: size.width, height: size.height)
            return (Self._clamp(f, in: container), UIPopoverArrowDirection(rawValue: 0))
        }
        for d in permitted {
            let f = Self._frame(for: d, anchor: anchor, size: size)
            if Self._clamp(f, in: container) == f { return (f, d) }
        }
        let d = permitted[0]
        return (Self._clamp(Self._frame(for: d, anchor: anchor, size: size), in: container), d)
    }

    /// MEASURED Modal-ipad t9200: `_UIPopoverView [561, 62, 240, 180]` =
    /// `preferredContentSize`, trailing inset 19, y = SA.top + 30 when
    /// nothing anchors the popover. Anchored popovers: see the class note.
    /// Action-sheet popovers are laid out by `_UIAlertPresentationController`
    /// (Modal-ipad t7200).
    public override var frameOfPresentedViewInContainerView: CGRect {
        guard let c = containerView else { return .zero }
        let size = presentedViewController.preferredContentSize
        guard size.width > 0, size.height > 0 else { return c.bounds }
        if let (f, _) = _resolvedLayout(in: c) { return f }
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
        if isPadRegular {
            // MEASURED `/tmp/ipad-open-cap` popover_{white,black,red,grad}:
            // content-popover interiors 252/215 (α=218/255, T=215/218). Dump
            // has no corner radius; PNG top-left of `[561, 62, 240, 180]` is
            // already the fill (252). No `_UIRoundedRectShadowView` — the
            // 11-count halo is not modelled (scoreboard/open.txt).
            cv._usesIOSGlass = true
            cv._iosGlassKind = .padContentPopover
            cv.backgroundColor = nil
            cv.isOpaque = false
        } else if cv.backgroundColor == nil {
            cv.backgroundColor = .systemBackground
        }
        if let (_, d) = _resolvedLayout(in: container) { arrowDirection = d }
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
    /// `UIPopoverArrowDirectionUnknown = NSUIntegerMax` (MEASURED raw
    /// 18446744073709551615 before a presentation) — every bit set.
    public static let unknown = UIPopoverArrowDirection(rawValue: Int(bitPattern: UInt.max))
}
