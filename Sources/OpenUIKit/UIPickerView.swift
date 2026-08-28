// UIPickerView — the wheel, MEASURED, plus a documented flat approximation
// of the one part that cannot be reproduced portably.
// Owner: controls module (app-compat cluster "controls2").
//
// ============================ THE WHEEL LAW ============================
//
// Real UIKit lays a picker's rows out on a CYLINDER, and the projection is
// not a guess here: it is an exact fit to the cell frames real UIKit
// computes, measured through the offscreen oracle over THIRTEEN
// configurations (picker heights 120…500 pt at rowHeight 32, and rowHeights
// 20/26/32/44/60 at height 216). Let
//
//     d          = row index minus the selected row (0 = the selected row)
//     H          = the picker's height, rowH = the row height
//     tableH     = H + 75                       (measured, exact, every H)
//     N          = ceil(2 * tableH / rowH)      (measured, INTEGER, every case)
//     beta       = 2*pi / N                     (the angular pitch)
//     R          = 0.334225372 * tableH         (measured ratio, 7 digits,
//                                                identical in all 13 cases)
//
// then row d's rectangle in the picker's own coordinates is
//
//     centerY = H/2 + R * sin(d * beta)
//     height  = rowH * cos(d * beta)
//
// and rows with |d * beta| >= pi/2 are on the far side of the wheel and are
// not drawn. Residual of the fit against real UIKit's own cell frames:
// 1e-6 pt on the centres, 1e-13 pt on the heights, i.e. exact. Two sanity
// checks that fell out of it and are worth recording because they say the
// law is structural rather than curve-fitted: N came out an exact integer in
// every one of the thirteen configurations (13, 15, 16, 19, 21, 24, 30, 36 /
// 30, 23, 19, 14, 10), and R/tableH agreed to the seventh decimal across a
// 4x range of heights.
//
// Note what the law is NOT: a plain cylinder. A plain cylinder would need
// R * beta == rowH; here R * beta is 32.16 for a 32 pt row and 61.1 for a
// 60 pt one. UIKit stretches the position curve independently of the height
// curve, and the two constants above are what it actually uses.
//
// ========================= THE REST OF THE CHROME =========================
//
// All measured from the same probe (Mac Catalyst iOS 26.1):
//
//   * Default size 320 x 216; `sizeThatFits` returns (width, 216) at every
//     width, and `intrinsicContentSize` matches.
//   * SELECTION BAND: height rowH + 2, centred vertically -> its top is
//     (H - rowH - 2) / 2. Verified at rowH 20/26/32/44/60 (bands 22/28/34/
//     46/62 and tops 97/94/91/85/77).
//   * SELECTION INDICATOR: a `quaternarySystemFill` view at
//     (9, bandTop, W - 18, rowH + 2). The colour resolves to
//     (0.454902, 0.454902, 0.501961, 0.08) light and
//     (0.462745, 0.462745, 0.501961, 0.18) dark.
//   * COMPONENT WIDTH, from `rowSize(forComponent:)` at 320 pt wide:
//     302 / 148 / 97 / 71 / 56 for 1…5 components — exactly
//     floor((W - 18 - 5 * (n - 1)) / n).
//   * ROW LABEL: inset 9 pt inside the component on each side, centred.
//     The SELECTED band draws at 23.5 pt regular, full opacity; every other
//     band at 21 pt regular with alpha 0.447. Both in `label`.
//
// ===================== WHAT IS APPROXIMATED, AND HOW =====================
//
// **THE ROW TEXT IS NOT PERSPECTIVE-PROJECTED.** This is the deliberate
// flat approximation, and it is the one thing about this control a caller
// must know. Real UIKit rotates each row's cell in 3D, so a distant row's
// LABEL is projected along with its rectangle. OpenUIKit's text engine draws
// from harvested glyph masks on an axis-aligned baseline; there is no
// mechanism to shear or foreshorten a glyph run, and adding one would mean a
// second rasterizer.
//
// So each row's rectangle uses the exact measured law above, and its text is
// drawn UNSQUASHED, centred in that rectangle. Measured against the golden,
// the error is:
//
//     |d| = 0   exact (0.75 pt of ink offset, which is the font's own
//               cap-height asymmetry and matches)
//     |d| = 1   within ~0.5 pt
//     |d| = 2   ~4 pt of vertical offset
//     |d| >= 3  progressively worse; the row is mostly clipped anyway
//
// ================== WHY THERE IS NO PICKER FIXTURE ==================
//
// **The picker is the one control in this cluster with NO golden scene, and
// the reason is a property of the oracle, not a shortcut.** Two things make
// an offscreen `layer.render(in:)` capture of a real UIPickerView
// unrepresentative of what the control looks like:
//
//   1. A `CAGradientLayer` at (0, 10, W, H - 20) — present in the layer dump,
//      with stops the dump does not expose — is composited over the whole
//      control. Captured over a transparent background it comes out as a
//      translucent WASH: the reference capture's centre pixel is
//      (231, 231, 231) at alpha 204 and its corners are alpha 0, so the
//      golden is not an image of the picker at all. It also erases the
//      opaque sibling view behind it.
//   2. The selection band composites to NOTHING (see below), so even a
//      capture over an opaque background would be missing the control's
//      defining affordance.
//
// The measured wheel is therefore pinned by `PickerWheelTests`, which
// replays REAL UIKit's own private cell frames — `|d|` up to 4 over
// THIRTEEN configurations, to 5e-4 pt — plus the band rects, the component
// widths and `sizeThatFits`. That is a stronger and tighter check than a
// pixel golden of this control could be, and it is the honest split: the
// geometry is oracle-exact, the glyph projection is not attempted. A real
// pixel golden needs the WINDOWED oracle (`Tools/oracle2`), which needs an
// active display session (docs/KNOWN_GAPS.md), the same blocker
// `UIStepper` has.
//
// Also not reproduced, each for a measured reason:
//
//   * THE SELECTION INDICATOR'S CORNER RADIUS. The indicator's layer reports
//     `cornerRadius = nan` with `cornerCurve = .continuous`, and the fill
//     does not composite through `layer.render(in:)` at all (the band is
//     pure background in the capture), so there is neither a property nor a
//     pixel to read it from. `selectionIndicatorCornerRadius` below is a
//     PLACEHOLDER, not a measurement. Same class of gap as the UIPageControl
//     glass background (docs/KNOWN_GAPS.md).
//   * THE TOP/BOTTOM FADE described above. Not drawn here, so OpenUIKit's
//     picker has hard edges where iOS fades the wheel out.
//   * MULTI-COMPONENT X POSITIONS. Offscreen, every component's table lands
//     at the SAME centred x ((W - componentWidth) / 2 for 2, 3 and 4
//     components) — UIKit does not position the columns without a window, so
//     there is nothing to measure. The widths above ARE measured; the
//     left-to-right packing here (components laid side by side with a 5 pt
//     gap, the whole row centred) is inferred from those widths and is NOT
//     oracle-validated. The fixture uses ONE component for that reason.
//   * SCROLLING. The wheel does not spin: `selectRow(_:inComponent:animated:)`
//     jumps. There is no pan gesture, no deceleration and no snap. The
//     interaction has the same problem the refresh control's threshold does
//     — an offscreen picker receives no gesture — and closing it needs the
//     Simulator drag route (docs/KNOWN_GAPS.md).

@preconcurrency @MainActor
public protocol UIPickerViewDataSource: AnyObject {
    func numberOfComponents(in pickerView: UIPickerView) -> Int
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int
}

@preconcurrency @MainActor
public protocol UIPickerViewDelegate: AnyObject {
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int,
                    forComponent component: Int) -> String?
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int,
                    forComponent component: Int) -> NSAttributedString?
    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int)
}

extension UIPickerViewDelegate {
    public func pickerView(_ pickerView: UIPickerView, titleForRow row: Int,
                           forComponent component: Int) -> String? { nil }
    public func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int,
                           forComponent component: Int) -> NSAttributedString? { nil }
    public func pickerView(_ pickerView: UIPickerView,
                           widthForComponent component: Int) -> CGFloat { -1 }
    public func pickerView(_ pickerView: UIPickerView,
                           rowHeightForComponent component: Int) -> CGFloat { -1 }
    public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int,
                           inComponent component: Int) {}
}

@preconcurrency @MainActor
open class UIPickerView: UIView {
    // MARK: Measured constants (file header)

    /// Default height; also what `sizeThatFits` reports at every width.
    public static let defaultHeight: CGFloat = 216
    /// Default row height.
    public static let defaultRowHeight: CGFloat = 32
    /// The picker's row table is 75 pt taller than the picker itself.
    // `nonisolated`: immutable calibration constants, read by the pure-math
    // `Wheel` struct which has no reason to be main-actor bound.
    nonisolated static let tableHeightBonus: CGFloat = 75
    /// Wheel radius as a fraction of the table height (7-digit measured fit).
    nonisolated static let wheelRadiusRatio: CGFloat = 0.334225372
    /// Side inset of the row area and of the selection indicator.
    static let sideInset: CGFloat = 9
    /// Gap between components (inferred from the measured widths — header).
    static let componentGap: CGFloat = 5
    /// Selection band height is `rowHeight + selectionBandBonus`.
    static let selectionBandBonus: CGFloat = 2
    /// Horizontal inset of a row's title inside its component.
    static let titleInset: CGFloat = 9
    static let selectedFontSize: CGFloat = 23.5
    static let unselectedFontSize: CGFloat = 21
    static let unselectedAlpha: CGFloat = 0.447
    /// PLACEHOLDER, not a measurement — see the file header.
    static let selectionIndicatorCornerRadius: CGFloat = 10

    // MARK: State

    public weak var dataSource: UIPickerViewDataSource? {
        didSet { reloadAllComponents() }
    }
    public weak var delegate: UIPickerViewDelegate? {
        didSet { reloadAllComponents() }
    }

    /// Whether the band behind the selected row is drawn. UIKit deprecated
    /// this in iOS 13 and ignores it; OpenUIKit honors it, because the band
    /// is the one part of the control the offscreen oracle cannot render at
    /// all (file header).
    public var showsSelectionIndicator = true {
        didSet { if showsSelectionIndicator != oldValue { setNeedsLayout() } }
    }

    private var rowCounts: [Int] = []
    private var selection: [Int] = []
    private var rowLabels: [UILabel] = []
    private var indicatorView: UIView?

    public override init(frame: CGRect) {
        super.init(frame: frame.width == 0 && frame.height == 0
                   ? CGRect(x: 0, y: 0, width: 320, height: UIPickerView.defaultHeight)
                   : frame)
    }

    public convenience init() {
        self.init(frame: CGRect(x: 0, y: 0, width: 320,
                                height: UIPickerView.defaultHeight))
    }

    // MARK: Model

    public var numberOfComponents: Int { rowCounts.count }

    public func numberOfRows(inComponent component: Int) -> Int {
        rowCounts.indices.contains(component) ? rowCounts[component] : 0
    }

    public func rowSize(forComponent component: Int) -> CGSize {
        CGSize(width: componentWidth(component), height: rowHeight(component))
    }

    public func selectedRow(inComponent component: Int) -> Int {
        selection.indices.contains(component) ? selection[component] : 0
    }

    /// Selects a row. `animated` is accepted and ignored — the wheel does not
    /// spin (file header).
    public func selectRow(_ row: Int, inComponent component: Int, animated: Bool) {
        guard selection.indices.contains(component) else { return }
        let clamped = max(0, min(row, max(0, rowCounts[component] - 1)))
        guard selection[component] != clamped else { return }
        selection[component] = clamped
        setNeedsLayout()
        delegate?.pickerView(self, didSelectRow: clamped, inComponent: component)
    }

    public func reloadAllComponents() {
        let n = dataSource?.numberOfComponents(in: self) ?? 0
        var counts: [Int] = []
        for c in 0..<max(0, n) {
            counts.append(max(0, dataSource?.pickerView(self, numberOfRowsInComponent: c) ?? 0))
        }
        rowCounts = counts
        if selection.count != counts.count {
            selection = Array(repeating: 0, count: counts.count)
        } else {
            for c in counts.indices {
                selection[c] = max(0, min(selection[c], max(0, counts[c] - 1)))
            }
        }
        setNeedsLayout()
    }

    public func reloadComponent(_ component: Int) {
        guard rowCounts.indices.contains(component) else { return }
        rowCounts[component] = max(0, dataSource?.pickerView(self,
                                                             numberOfRowsInComponent: component) ?? 0)
        selection[component] = max(0, min(selection[component],
                                          max(0, rowCounts[component] - 1)))
        setNeedsLayout()
    }

    public func view(forRow row: Int, forComponent component: Int) -> UIView? { nil }

    // MARK: Sizing

    open override var intrinsicContentSize: CGSize {
        CGSize(width: bounds.width > 0 ? bounds.width : 320,
               height: UIPickerView.defaultHeight)
    }

    open override func sizeThatFits(_ size: CGSize) -> CGSize {
        CGSize(width: size.width > 0 ? size.width : 320,
               height: UIPickerView.defaultHeight)
    }

    // MARK: The measured wheel (file header)

    func rowHeight(_ component: Int) -> CGFloat {
        let d = delegate?.pickerView(self, rowHeightForComponent: component) ?? -1
        return d > 0 ? d : UIPickerView.defaultRowHeight
    }

    func componentWidth(_ component: Int) -> CGFloat {
        let d = delegate?.pickerView(self, widthForComponent: component) ?? -1
        if d > 0 { return d }
        let n = max(1, numberOfComponents)
        let usable = bounds.width - 2 * UIPickerView.sideInset
            - UIPickerView.componentGap * CGFloat(n - 1)
        return (usable / CGFloat(n)).rounded(.down)
    }

    /// The wheel's table height, radius and angular pitch for one component.
    /// Public-ish (internal) because the tests replay real UIKit's numbers
    /// against it directly.
    struct Wheel {
        let rowHeight: CGFloat
        let tableHeight: CGFloat
        let rowsPerRevolution: Int
        let beta: CGFloat
        let radius: CGFloat
        let centerY: CGFloat

        init(pickerHeight H: CGFloat, rowHeight rowH: CGFloat) {
            self.rowHeight = rowH
            let tableH = H + UIPickerView.tableHeightBonus
            tableHeight = tableH
            let raw = 2 * tableH / max(rowH, 0.0001)
            rowsPerRevolution = max(4, Int(raw.rounded(.up)))
            beta = 2 * CGFloat.pi / CGFloat(rowsPerRevolution)
            radius = UIPickerView.wheelRadiusRatio * tableH
            centerY = H / 2
        }

        /// The rectangle of the row `d` steps from the selected one, or nil
        /// when it has rotated past the wheel's edge.
        func rowRect(offset d: Int, x: CGFloat, width: CGFloat) -> CGRect? {
            let theta = CGFloat(d) * beta
            guard theta > -CGFloat.pi / 2, theta < CGFloat.pi / 2 else { return nil }
            let h = rowHeight * _bpCos(theta)
            guard h > 0 else { return nil }
            let cy = centerY + radius * _bpSin(theta)
            return CGRect(x: x, y: cy - h / 2, width: width, height: h)
        }

        /// How far a row can be from the selection and still be on the front
        /// of the wheel.
        var maxVisibleOffset: Int { (rowsPerRevolution - 1) / 4 }
    }

    func wheel(_ component: Int) -> Wheel {
        Wheel(pickerHeight: bounds.height, rowHeight: rowHeight(component))
    }

    /// The band behind the selected row: `rowHeight + 2` tall, centred.
    public func selectionBandRect(forComponent component: Int = 0) -> CGRect {
        let h = rowHeight(component) + UIPickerView.selectionBandBonus
        return CGRect(x: UIPickerView.sideInset,
                      y: ((bounds.height - h) / 2).rounded(.toNearestOrAwayFromZero),
                      width: max(0, bounds.width - 2 * UIPickerView.sideInset),
                      height: h)
    }

    /// x of a component's left edge: the components are packed left to right
    /// with `componentGap` between them and the whole row centred (INFERRED,
    /// not measured — file header).
    func componentOrigin(_ component: Int) -> CGFloat {
        let n = max(1, numberOfComponents)
        var total: CGFloat = 0
        for c in 0..<n { total += componentWidth(c) }
        total += UIPickerView.componentGap * CGFloat(n - 1)
        var x = ((bounds.width - total) / 2).rounded(.toNearestOrAwayFromZero)
        for c in 0..<component {
            x += componentWidth(c) + UIPickerView.componentGap
        }
        return x
    }

    // MARK: Layout

    open override func layoutSubviews() {
        super.layoutSubviews()
        layoutIndicator()
        layoutRows()
    }

    private func layoutIndicator() {
        guard showsSelectionIndicator, numberOfComponents > 0 else {
            indicatorView?.isHidden = true
            return
        }
        let v: UIView
        if let existing = indicatorView { v = existing } else {
            v = UIView()
            v.isUserInteractionEnabled = false
            insertSubview(v, at: 0)
            indicatorView = v
        }
        v.isHidden = false
        v.frame = selectionBandRect()
        v.backgroundColor = .quaternarySystemFill
        v.layer.cornerRadius = UIPickerView.selectionIndicatorCornerRadius
    }

    private func dequeueLabel(_ index: Int) -> UILabel {
        if index < rowLabels.count { return rowLabels[index] }
        let l = UILabel()
        l.textAlignment = .center
        l.clipsToBounds = true
        addSubview(l)
        rowLabels.append(l)
        return l
    }

    private func layoutRows() {
        var used = 0
        let band = selectionBandRect()
        for c in 0..<numberOfComponents {
            let w = componentWidth(c)
            let x = componentOrigin(c)
            let wheel = self.wheel(c)
            let sel = selectedRow(inComponent: c)
            let span = wheel.maxVisibleOffset
            for d in -span...span {
                let row = sel + d
                guard row >= 0, row < rowCounts[c] else { continue }
                guard let rect = wheel.rowRect(offset: d, x: x, width: w) else { continue }
                guard rect.maxY > 0, rect.minY < bounds.height else { continue }
                let title = delegate?.pickerView(self, titleForRow: row, forComponent: c)
                let attributed = delegate?.pickerView(self, attributedTitleForRow: row,
                                                      forComponent: c)
                guard title != nil || attributed != nil else { continue }
                let selected = d == 0
                let l = dequeueLabel(used)
                used += 1
                l.isHidden = false
                l.frame = rect.insetBy(dx: UIPickerView.titleInset, dy: 0)
                l.font = .systemFont(ofSize: selected ? UIPickerView.selectedFontSize
                                                      : UIPickerView.unselectedFontSize)
                l.textColor = .label
                // Measured: rows outside the selection band draw at 0.447.
                l.alpha = selected ? 1 : UIPickerView.unselectedAlpha
                if let attributed {
                    l.attributedText = attributed
                } else {
                    l.attributedText = nil
                    l.text = title
                }
                // The row's rect is exact; the TEXT is not projected — the
                // flat approximation documented in the file header.
                _ = band
            }
        }
        for i in used..<rowLabels.count { rowLabels[i].isHidden = true }
    }
}
