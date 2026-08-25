// Modal presentation. Owner: viewcontroller module (M10 chrome).
//
// UIViewController.present(_:animated:) / dismiss(animated:) with the iOS 26
// pageSheet look, measured from golden/modal_sheet (real iOS 26, iPhone 16
// simulator — Catalyst cannot render the iOS sheet chrome):
//   - Dimming: black at 20% over the presenting content (white base →
//     #CCCCCC). Touches on the dim do nothing (minimal isModalInPresentation
//     semantics — there is no tap-to-dismiss).
//   - Sheet: full width, top edge 59.5 pt below the window top, rounded
//     corners fit from the golden's edge profile (top R ≈ 37.7 pt, bottom
//     R ≈ 58.2 pt — iOS draws continuous corners; a circular fit matches
//     the measured profile within ~0.4 pt on top, ~1.7 pt on the bottom's
//     display-concentric curve).
//   - Present: sheet slides up from below over 0.4 s on a critically damped
//     spring while the dim fades in (feel-matched; scripted captures via
//     the shared animation clock). Dismiss is the exact reverse.
//
// Appearance callbacks follow UIKit: the PRESENTED controller gets
// viewWillAppear/viewDidAppear ("did" fires when the host clock passes the
// transition end — UIView.animate completion, same pattern as navigation
// transitions). The PRESENTING controller only gets disappearance callbacks
// for .fullScreen (a pageSheet leaves it visible, like UIKit).
//
// The presentation attaches to the presenting controller's topmost view
// (its window when it is in one) so the sheet covers navigation bars, tab
// bars and any other chrome.

public enum UIModalPresentationStyle {
    /// Resolves to .pageSheet (the iOS default for a plain present).
    case automatic
    case pageSheet
    case fullScreen
}

/// Container for one modal presentation: dimming + sheet, sized to the
/// presentation root. Class name is private to compare.py (never part of
/// scene dumps anyway — layout dumps run before presentation).
final class UIPresentationContainerView: UIView {}

/// The dim behind a sheet: swallows every touch (tap-to-dismiss is NOT the
/// default; minimal isModalInPresentation semantics).
final class _UIDimmingView: UIView {
    static let maxAlpha: CGFloat = 0.2
}

/// The sheet platter: fills its bounds with the measured rounded-corner
/// shape. The presented view sits on top with a clear background — the
/// platter provides the background color so the corners stay rounded.
final class _UIPageSheetView: UIView {
    static let topInset: CGFloat = 59.5
    static let topCornerRadius: CGFloat = 37.7
    static let bottomCornerRadius: CGFloat = 58.2

    /// Sheet background; defaults to systemBackground, resolved at draw
    /// time against the effective traits.
    var fillColor: UIColor = .systemBackground {
        didSet { setNeedsDisplay() }
    }

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        isOpaque = false
        clipsToBounds = false
    }

    override func drawContent(in canvas: Canvas, bounds: CGRect) {
        let path = _UIPageSheetView.sheetPath(
            in: bounds,
            topRadius: _UIPageSheetView.topCornerRadius,
            bottomRadius: _UIPageSheetView.bottomCornerRadius)
        let color = fillColor.resolvedColor(with: traitCollection).cgColor
        canvas.fill(path, color: color)
    }

    /// Rounded rect with independent top/bottom corner radii (circular
    /// arcs via the standard cubic approximation).
    static func sheetPath(in r: CGRect, topRadius: CGFloat,
                          bottomRadius: CGFloat) -> Path {
        let k: CGFloat = 0.5522847498
        let rt = min(topRadius, min(r.width, r.height) / 2)
        let rb = min(bottomRadius, min(r.width, r.height) / 2)
        var p = Path()
        p.move(to: CGPoint(x: r.minX + rt, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX - rt, y: r.minY))
        p.addCurve(to: CGPoint(x: r.maxX, y: r.minY + rt),
                   control1: CGPoint(x: r.maxX - rt + k * rt, y: r.minY),
                   control2: CGPoint(x: r.maxX, y: r.minY + rt - k * rt))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY - rb))
        p.addCurve(to: CGPoint(x: r.maxX - rb, y: r.maxY),
                   control1: CGPoint(x: r.maxX, y: r.maxY - rb + k * rb),
                   control2: CGPoint(x: r.maxX - rb + k * rb, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX + rb, y: r.maxY))
        p.addCurve(to: CGPoint(x: r.minX, y: r.maxY - rb),
                   control1: CGPoint(x: r.minX + rb - k * rb, y: r.maxY),
                   control2: CGPoint(x: r.minX, y: r.maxY - rb + k * rb))
        p.addLine(to: CGPoint(x: r.minX, y: r.minY + rt))
        p.addCurve(to: CGPoint(x: r.minX + rt, y: r.minY),
                   control1: CGPoint(x: r.minX, y: r.minY + rt - k * rt),
                   control2: CGPoint(x: r.minX + rt - k * rt, y: r.minY))
        p.close()
        return p
    }
}

extension UIViewController {
    /// Present duration (feel-matched slide-up; critically damped spring).
    public static let presentTransitionDuration: Double = 0.4

    /// The style `modalPresentationStyle` resolves to for this
    /// presentation (.automatic → .pageSheet, the iOS default).
    var _resolvedPresentationStyle: UIModalPresentationStyle {
        modalPresentationStyle == .automatic ? .pageSheet
                                             : modalPresentationStyle
    }

    // MARK: Present

    public func present(_ vc: UIViewController, animated: Bool,
                        completion: (() -> Void)? = nil) {
        // UIKit forwards a present from a covered controller to the top of
        // the presentation stack.
        if let already = presentedViewController {
            already.present(vc, animated: animated, completion: completion)
            return
        }
        guard vc.presentingViewController == nil else { return }
        loadViewIfNeeded()

        // Presentation root: the topmost ancestor of our view (the window
        // when we are installed in one).
        var root: UIView = view
        while let s = root.superview { root = s }

        let style = vc._resolvedPresentationStyle
        let container = UIPresentationContainerView(frame: root.bounds)
        container.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        let dim = _UIDimmingView(frame: container.bounds)
        dim.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        dim.backgroundColor = .black
        dim.alpha = 0
        if style == .pageSheet { container.addSubview(dim) }

        let sheetFrame = style == .pageSheet
            ? CGRect(x: 0, y: _UIPageSheetView.topInset,
                     width: container.bounds.width,
                     height: container.bounds.height - _UIPageSheetView.topInset)
            : container.bounds
        let sheet = _UIPageSheetView(frame: sheetFrame)
        sheet.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        vc.loadViewIfNeeded()
        let cv = vc.view!
        // The sheet platter draws the (rounded) background; the presented
        // view's own rectangular background would paint over the corners.
        vc._savedSheetBackgroundColor = cv.backgroundColor
        if style == .pageSheet {
            if let bg = cv.backgroundColor { sheet.fillColor = bg }
            cv.backgroundColor = nil
        } else if cv.backgroundColor == nil {
            sheet.fillColor = .systemBackground
        }
        cv.frame = sheet.bounds
        cv.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        sheet.addSubview(cv)
        container.addSubview(sheet)
        root.addSubview(container)

        presentedViewController = vc
        vc.presentingViewController = self
        vc._presentationContainer = container
        vc._presentationSheet = sheet
        vc._presentationDim = dim

        let presenterDisappears = style == .fullScreen
        if presenterDisappears { beginAppearanceTransition(false, animated: animated) }
        vc.beginAppearanceTransition(true, animated: animated)

        let finish = { [weak self, weak vc] in
            vc?.endAppearanceTransition()
            if presenterDisappears { self?.endAppearanceTransition() }
            completion?()
        }
        if animated {
            let up = sheet.frame
            sheet.frame = up.offsetBy(dx: 0, dy: container.bounds.height - up.minY)
            UIView.animate(withDuration: UIViewController.presentTransitionDuration,
                           delay: 0, usingSpringWithDamping: 1,
                           initialSpringVelocity: 0, options: [], animations: {
                sheet.frame = up
                dim.alpha = _UIDimmingView.maxAlpha
            }, completion: { _ in finish() })
        } else {
            dim.alpha = _UIDimmingView.maxAlpha
            finish()
        }
    }

    // MARK: Dismiss

    public func dismiss(animated: Bool, completion: (() -> Void)? = nil) {
        // UIKit: a dismiss on a controller that presented something
        // dismisses ITS presented controller; a dismiss on a presented
        // controller dismisses itself.
        let vc: UIViewController
        if let presented = presentedViewController {
            // Collapse anything stacked above it first (non-animated), then
            // animate this one down.
            presented.presentedViewController?.dismiss(animated: false)
            vc = presented
        } else if let presenter = presentingViewController {
            presenter.dismiss(animated: animated, completion: completion)
            return
        } else {
            return
        }

        let presenter = self
        let container = vc._presentationContainer
        let sheet = vc._presentationSheet
        let dim = vc._presentationDim
        let presenterReappears = vc._resolvedPresentationStyle == .fullScreen

        vc.beginAppearanceTransition(false, animated: animated)
        if presenterReappears { presenter.beginAppearanceTransition(true, animated: animated) }

        let finish = { [weak presenter] in
            vc.viewIfLoaded?.backgroundColor = vc._savedSheetBackgroundColor
            vc.viewIfLoaded?.removeFromSuperview()
            container?.removeFromSuperview()
            vc.endAppearanceTransition()
            if presenterReappears { presenter?.endAppearanceTransition() }
            vc.presentingViewController = nil
            presenter?.presentedViewController = nil
            vc._presentationContainer = nil
            vc._presentationSheet = nil
            vc._presentationDim = nil
            completion?()
        }
        if animated, let sheet, let container {
            UIView.animate(withDuration: UIViewController.presentTransitionDuration,
                           delay: 0, usingSpringWithDamping: 1,
                           initialSpringVelocity: 0, options: [], animations: {
                sheet.frame = sheet.frame.offsetBy(
                    dx: 0, dy: container.bounds.height - sheet.frame.minY)
                dim?.alpha = 0
            }, completion: { _ in finish() })
        } else {
            finish()
        }
    }
}
