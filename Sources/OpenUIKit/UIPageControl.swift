// UIPageControl. Owner: controls module (app-compat cluster).
//
// Measured against real UIKit (Mac Catalyst iOS 26.1) with the windowed
// oracle (`fixtures/scenes/control_pagecontrol.json`, `"window": true`).
//
// Note for anyone re-probing this control: with DEFAULT colors it renders
// nothing over a white background — not because the render server drops it,
// but because the default indicator color is WHITE at 45 % (invisible on
// white). Probing over black and over red separates color from alpha
// exactly:
//     over black -> 114, over red -> (254, 114, 115)  => white @ 0.45
// and the current-page dot is OPAQUE white on both.
//
// Geometry (oracle layout dumps + pixel scans, 280 pt control, 4 pages):
//   - Content view: 26 pt tall, (18 * n + 20) pt wide, centred in the
//     bounds; that width is also intrinsicContentSize (dumped [92, 26] for
//     n = 4).
//   - Indicator slots are 10 x 10 on an 18 pt pitch, starting 14 pt inside
//     the content view; the row of dots is vertically centred (slot centre
//     = content top + 13). The drawn dot is 7.59 pt across and sits
//     0.19 pt left of / below its slot centre — fitted from ink area and
//     centroid, see `dotDiameter`.
//   - hidesForSinglePage suppresses the whole control at n <= 1.

public class UIPageControl: UIControl {
    static let contentHeight: CGFloat = 26
    static let slotPitch: CGFloat = 18
    static let contentSidePadding: CGFloat = 14
    static let slotSize: CGFloat = 10
    /// The drawn dot: real UIKit stamps an SF Symbol into the 10 pt slot,
    /// and it is neither exactly 8 pt nor exactly centred. Fitted from the
    /// goldens by INK AREA and centroid (identical across every dot, tint
    /// and control probed): area 45.2 pt^2 => diameter 7.59, centroid
    /// (-0.19, +0.19) from the slot centre.
    static let dotDiameter: CGFloat = 7.59
    static let dotCenterOffset = CGSize(width: -0.19, height: 0.19)

    /// Measured default: white at 45 % (see the header).
    public static let defaultPageIndicatorTintColor = UIColor(white: 1, alpha: 0.45)
    /// Measured default: opaque white.
    public static let defaultCurrentPageIndicatorTintColor = UIColor(white: 1, alpha: 1)

    public var numberOfPages: Int = 0 {
        didSet {
            numberOfPages = Swift.max(0, numberOfPages)
            if currentPage >= numberOfPages { currentPage = Swift.max(0, numberOfPages - 1) }
            setNeedsDisplay()
        }
    }
    public var currentPage: Int = 0 {
        didSet {
            currentPage = Swift.max(0, Swift.min(currentPage, Swift.max(0, numberOfPages - 1)))
            if currentPage != oldValue { setNeedsDisplay() }
        }
    }
    public var hidesForSinglePage: Bool = false { didSet { setNeedsDisplay() } }
    public var pageIndicatorTintColor: UIColor? { didSet { setNeedsDisplay() } }
    public var currentPageIndicatorTintColor: UIColor? { didSet { setNeedsDisplay() } }

    public override init(frame: CGRect = .zero) {
        super.init(frame: frame)
    }

    /// UIKit's sizing helper (independent of the current page count).
    public func size(forNumberOfPages pageCount: Int) -> CGSize {
        CGSize(width: UIPageControl.slotPitch * CGFloat(Swift.max(0, pageCount)) + 20,
               height: UIPageControl.contentHeight)
    }

    public override var intrinsicContentSize: CGSize { size(forNumberOfPages: numberOfPages) }
    public override func sizeThatFits(_ fitting: CGSize) -> CGSize {
        size(forNumberOfPages: numberOfPages)
    }

    /// Centre of indicator `index` in bounds coordinates.
    public func indicatorCenter(at index: Int) -> CGPoint {
        let contentSize = size(forNumberOfPages: numberOfPages)
        let x = bounds.minX + ((bounds.width - contentSize.width) / 2)
            .rounded(.toNearestOrAwayFromZero)
        let y = bounds.minY + ((bounds.height - contentSize.height) / 2)
            .rounded(.toNearestOrAwayFromZero)
        return CGPoint(
            x: x + UIPageControl.contentSidePadding + UIPageControl.slotSize / 2
               + CGFloat(index) * UIPageControl.slotPitch
               + UIPageControl.dotCenterOffset.width,
            y: y + UIPageControl.contentHeight / 2 + UIPageControl.dotCenterOffset.height)
    }

    // MARK: Tracking (UIKit advances one page per tap on the leading /
    // trailing half; not oracle-validated — see docs/KNOWN_GAPS.md).

    open override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        super.endTracking(touch, with: event)
        guard isTouchInside, let touch, numberOfPages > 1 else { return }
        let p = touch.location(in: self)
        let next = p.x < bounds.midX ? currentPage - 1 : currentPage + 1
        let clamped = Swift.max(0, Swift.min(numberOfPages - 1, next))
        guard clamped != currentPage else { return }
        currentPage = clamped
        sendActions(for: .valueChanged, with: event)
    }

    // MARK: Drawing

    public override func drawContent(in canvas: Canvas, bounds: CGRect) {
        guard numberOfPages > 0 else { return }
        if hidesForSinglePage && numberOfPages == 1 { return }
        let traits = traitCollection
        let normal = (pageIndicatorTintColor ?? UIPageControl.defaultPageIndicatorTintColor)
            .resolvedCGColor(with: traits)
        let current = (currentPageIndicatorTintColor
                       ?? UIPageControl.defaultCurrentPageIndicatorTintColor)
            .resolvedCGColor(with: traits)
        let r = UIPageControl.dotDiameter / 2
        for i in 0..<numberOfPages {
            let c = indicatorCenter(at: i)
            let rect = CGRect(x: c.x - r, y: c.y - r,
                              width: UIPageControl.dotDiameter,
                              height: UIPageControl.dotDiameter)
            canvas.fill(UIBezierPath.oval(in: rect),
                        color: i == currentPage ? current : normal)
        }
    }
}
