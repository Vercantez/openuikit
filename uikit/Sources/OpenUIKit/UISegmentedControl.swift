// UISegmentedControl. Owner: controls module (app-compat cluster).
//
// Measured against real UIKit (Mac Catalyst iOS 26.1). The background and
// the segment titles render offscreen (v1 oracle); the SELECTED pill is an
// iOS 26 `_UILiquidLensView`, drawn only by the render server, so the
// fixture (`fixtures/scenes/control_segmented.json`) is a `"window": true`
// scene captured by Tools/oracle2.
//
// Geometry (oracle layout dumps, 300 pt control with 1..3 segments):
//   - Background: capsule filling the bounds (radius = height / 2),
//     `tertiarySystemFill` (measured (238,238,239) over white — exactly
//     (118,118,128) at 12 %).
//   - Segments split the width EQUALLY with integer-floor boundaries:
//     280 / 3 dumps as 93, 93, 94 (boundary i = floor(i * W / n)).
//   - Selected pill: the segment rect inset by 2 pt on every side, a
//     circular capsule (radius = (h-4)/2; the golden's corner profile
//     matches r = 14 on a 28 pt pill within a quarter point), filled white
//     in light mode.
//   - Titles: 13 pt system, REGULAR when unselected and MEDIUM when
//     selected (probe: "Three" dumps 36.5 pt wide unselected, 37.5 selected
//     — exactly our 13 pt regular/medium widths). The label is centred in
//     its segment with the origin rounded half-up to the pixel grid, and
//     the label height is the 13 pt line box (16).
//   - Disabled controls draw at half strength (probe: background 246 and
//     title ink 146 over white, both ~0.5 of the enabled values).
//
// Intrinsic size is NOT reproduced: real UIKit's per-segment intrinsic
// width follows an unexplained mix of the widest title, a 32 pt floor and
// a ~18.5 pt padding that does not fit every probe. The oracle therefore
// does not dump `intrinsic` for this class (docs/KNOWN_GAPS.md).

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
#elseif canImport(Foundation)
import Foundation
#endif


/// Private title label class (matches real UIKit's private class name, so
/// neither renderer's internals enter the structural layout comparison).
@preconcurrency @MainActor
final class UISegmentLabel: UILabel {}

@preconcurrency @MainActor
open class UISegmentedControl: UIControl {
    public static let noSegment = -1

    static let titleFontSize: CGFloat = 13
    static let pillInset: CGFloat = 2
    static let disabledAlpha: CGFloat = 0.5
    /// Measured background fill (tertiarySystemFill).
    static let backgroundFill = UIColor.tertiarySystemFill
    /// Selected pill fill: white in light mode; in dark mode the golden
    /// (control_dark) reads (90, 90, 96) over the control's own background,
    /// which is modelled as that opaque color.
    public static let defaultSelectedSegmentTintColor = UIColor(dynamicProvider: { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 90.0 / 255.0, green: 90.0 / 255.0, blue: 96.0 / 255.0, alpha: 1)
            : UIColor(white: 1, alpha: 1)
    })

    private var titles: [String] = []
    private var labels: [UISegmentLabel] = []

    public var selectedSegmentIndex: Int = UISegmentedControl.noSegment {
        didSet {
            if selectedSegmentIndex != oldValue {
                updateLabels()
                setNeedsLayout()
                setNeedsDisplay()
            }
        }
    }
    public var selectedSegmentTintColor: UIColor? { didSet { setNeedsDisplay() } }
    /// Accepted for source compatibility; segments are always equal width
    /// here (that is what the oracle dumps for every probe).
    public var apportionsSegmentWidthsByContent: Bool = false

    public init(items: [String]) {
        super.init(frame: .zero)
        for t in items { insertSegment(withTitle: t, at: titles.count, animated: false) }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    public var numberOfSegments: Int { titles.count }

    public func insertSegment(withTitle title: String?, at index: Int, animated: Bool = false) {
        let i = Swift.max(0, Swift.min(index, titles.count))
        titles.insert(title ?? "", at: i)
        let label = UISegmentLabel()
        label.font = .systemFont(ofSize: UISegmentedControl.titleFontSize)
        label.textAlignment = .center
        labels.insert(label, at: i)
        insertSubview(label, at: i)
        updateLabels()
        setNeedsLayout()
    }

    public func removeSegment(at index: Int, animated: Bool = false) {
        guard titles.indices.contains(index) else { return }
        titles.remove(at: index)
        labels.remove(at: index).removeFromSuperview()
        if selectedSegmentIndex >= titles.count {
            selectedSegmentIndex = UISegmentedControl.noSegment
        }
        setNeedsLayout()
    }

    public func removeAllSegments() {
        titles.removeAll()
        for l in labels { l.removeFromSuperview() }
        labels.removeAll()
        selectedSegmentIndex = UISegmentedControl.noSegment
        setNeedsLayout()
    }

    public func setTitle(_ title: String?, forSegmentAt index: Int) {
        guard titles.indices.contains(index) else { return }
        titles[index] = title ?? ""
        updateLabels()
        setNeedsLayout()
    }

    public func titleForSegment(at index: Int) -> String? {
        titles.indices.contains(index) ? titles[index] : nil
    }

    /// Segment rect in bounds coordinates. Boundaries are integer-floored,
    /// exactly like the oracle's dumps (280 / 3 -> 93, 93, 94).
    public func segmentRect(at index: Int) -> CGRect {
        let n = titles.count
        guard n > 0, titles.indices.contains(index) else { return .zero }
        let w = bounds.width
        let x0 = (CGFloat(index) * w / CGFloat(n)).rounded(.down)
        let x1 = (CGFloat(index + 1) * w / CGFloat(n)).rounded(.down)
        return CGRect(x: bounds.minX + x0, y: bounds.minY,
                      width: (index == n - 1 ? w : x1) - x0, height: bounds.height)
    }

    private func updateLabels() {
        for (i, l) in labels.enumerated() {
            l.text = titles[i]
            let selected = i == selectedSegmentIndex
            l.font = selected
                ? .systemFont(ofSize: UISegmentedControl.titleFontSize, weight: .medium)
                : .systemFont(ofSize: UISegmentedControl.titleFontSize)
            l.textColor = isEnabled
                ? UIColor.label
                : UIColor.label.withMultipliedAlpha(UISegmentedControl.disabledAlpha)
        }
    }

    open override func stateDidChange() {
        super.stateDidChange()
        updateLabels()
        setNeedsDisplay()
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        updateLabels()
        let scale = traitCollection.displayScale
        func pixelRound(_ v: CGFloat) -> CGFloat { (v * scale + 0.5).rounded(.down) / scale }
        for (i, l) in labels.enumerated() {
            let seg = segmentRect(at: i)
            let intr = l.intrinsicContentSize
            let w = Swift.min(intr.width, Swift.max(0, seg.width - 8))
            l.frame = CGRect(x: seg.minX + pixelRound((seg.width - w) / 2),
                             y: seg.minY + pixelRound((seg.height - intr.height) / 2),
                             width: w, height: intr.height)
        }
    }

    // MARK: Tracking

    open override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        super.endTracking(touch, with: event)
        guard isTouchInside, let touch else { return }
        let p = touch.location(in: self)
        for i in titles.indices where segmentRect(at: i).contains(p) {
            if i != selectedSegmentIndex {
                selectedSegmentIndex = i
                sendActions(for: .valueChanged, with: event)
            }
            return
        }
    }

    // MARK: Drawing (background + pill; the titles are label subviews)

    public override func drawContent(in canvas: Canvas, bounds: CGRect) {
        guard bounds.width > 0, bounds.height > 0 else { return }
        let traits = traitCollection
        let dim = isEnabled ? 1 : UISegmentedControl.disabledAlpha
        var bg = UISegmentedControl.backgroundFill.resolvedCGColor(with: traits)
        bg.alpha *= dim
        canvas.fill(Path.roundedRect(bounds, cornerRadius: bounds.height / 2), color: bg)

        guard titles.indices.contains(selectedSegmentIndex) else { return }
        let seg = segmentRect(at: selectedSegmentIndex)
        let pill = seg.insetBy(dx: UISegmentedControl.pillInset, dy: UISegmentedControl.pillInset)
        guard pill.width > 0, pill.height > 0 else { return }
        var fill = (selectedSegmentTintColor
                    ?? UISegmentedControl.defaultSelectedSegmentTintColor)
            .resolvedCGColor(with: traits)
        fill.alpha *= dim
        canvas.fill(Path.roundedRect(pill, cornerRadius: pill.height / 2), color: fill)
    }
}
