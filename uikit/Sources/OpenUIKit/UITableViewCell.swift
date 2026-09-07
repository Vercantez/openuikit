// UITableViewCell. Owner: tableview module (M10).
//
// Cell chrome MEASURED against real UIKit (iOS 26 Catalyst oracle, compact
// width, scale 2 — golden/tableview_*.png + .layout.json):
//   - default/value1 cell height 51.5 pt, subtitle cell height 70.5 pt
//     (15.5 top/bottom padding; primary 17 pt regular at (16, 15.5);
//     subtitle secondary 15 pt regular at (16, 36)).
//   - value1 detail: 17 pt regular, secondaryLabel, right-aligned to the
//     content edge (16 pt margin without accessory, 8 pt from the accessory
//     edge with one).
//   - Accessories: disclosure chevron 10.5x14 pt at trailing margin 16
//     (tertiaryLabel vector stroke); checkmark 19x18 pt at trailing margin
//     18.5 (tintColor stroke). Vertical center rounds UP to half points.
//   - Separator: 1 pt, `separator` color, bottom-aligned (the table sets
//     the inset per style and hides it next to selections / on the last
//     row of an inset-grouped section).
//   - Selection/highlight: full-bleed #DCDCDC in light mode (measured from
//     tableview_selected; the dark value is unmeasured — systemGray4-family
//     approximation). Fade-out 0.3 s on deselect, like the row-highlight
//     feel in docs/APP_FEEL.md.
//
// Touch feel: the cell highlights on touch-down (delivery is already
// delayed/cancelled by UIScrollView's content-touch pipeline), commits the
// selection to the table on touch-up, and un-highlights with a 0.3 s fade
// on cancel — the same pattern as DemoApp's SettingsRow.

// MARK: - Content view (forwards touches to the cell)

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


/// The cell's content container. Plain-view touches that land on it (or on
/// non-interactive labels above it) are forwarded to the cell so row
/// highlighting works while real controls inside keep receiving their own
/// touches. The class name keeps the subtree private to compare.py.
@preconcurrency @MainActor
final class UITableViewCellContentView: UIView {
    var cell: UITableViewCell? { superview as? UITableViewCell }

    /// The content view takes the cell's margins, except on a trailing edge
    /// accessory chrome already ate — there it keeps `UIView`'s 8 pt.
    ///
    /// MEASURED (realapp_storage_light, both oracle devices): the content
    /// view of the accessory-less DisclosureCell reports the cell's own
    /// [15, 20, 15, 20], while SwitchCell's — 310 wide, with the switch as
    /// its accessory view — reports [15, 20, 15, 8] on the iPhone 16 and
    /// [15, 16, 15, 8] on the SE.
    ///
    /// MEASURED Ledger t200, iPhone SE 2x / iOS 26.1: disclosureIndicator
    /// contentView 316.5, subtitle `[16, 39.5, 292.5, 16]` → trailing **8**
    /// (same 8 the custom accessoryView path already carried). Amount
    /// `$4.50` trailing edge 308.5 = 316.5 − 8. The previous `accessoryView
    /// != nil` guard left `accessoryType` cells at 16 and shifted every
    /// Auto Layout label 8 pt left.
    ///
    /// MEASURED Ledger t200.rtl: contentView still `[42.5, …, 316.5, 92]`
    /// (accessory on the leading/left edge); subtitle abs x **50.5** =
    /// 42.5 + **8**, `$4.50` at 50.5. Tight inset follows the accessory
    /// (physical left in RTL), not `layoutMargins.right`.
    ///
    /// MEASURED Notes t200 / t5000 / t5000.rtl, iPhone SE 2x / iOS 26.1:
    /// same 8 pt on a disclosure title `[16, 15, 292.5, 20.5]` (LTR) /
    /// `[8, 15, 292.5]` (RTL, physical left is trailing) in a 316.5
    /// content view.
    override var _defaultBaseLayoutMargins: UIEdgeInsets {
        guard let cell else { return super._defaultBaseLayoutMargins }
        var m = cell.layoutMargins
        if cell.accessoryView != nil || cell.accessoryType != .none {
            let tight = super._defaultBaseLayoutMargins.right
            if cell._layoutIsRTL {
                m.left = tight
            } else {
                m.right = tight
            }
        }
        return m
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        cell?.touchesBegan(touches, with: event)
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        cell?.touchesMoved(touches, with: event)
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        cell?.touchesEnded(touches, with: event)
    }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        cell?.touchesCancelled(touches, with: event)
    }
}

// MARK: - Accessory view (vector chevron / checkmark)

/// Draws the accessory glyph as Canvas vector strokes (no SF Symbols in the
/// portable stack). Geometry fitted to the golden accessory ink.
@preconcurrency @MainActor
final class UITableCellAccessoryView: UIView {
    var accessoryType: UITableViewCell.AccessoryType = .none {
        didSet { if accessoryType != oldValue { setNeedsDisplay() } }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        isOpaque = false
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        isUserInteractionEnabled = false
        isOpaque = false
    }

    /// Fill a round dot (for round caps/joins on top of the butt-capped
    /// backend stroke).
    private func dot(at p: CGPoint, radius r: CGFloat, in canvas: Canvas,
                     color: CGColor) {
        let k: CGFloat = 0.5522847498307936 * r
        var path = Path()
        path.move(to: CGPoint(x: p.x + r, y: p.y))
        path.addCurve(to: CGPoint(x: p.x, y: p.y + r),
                      control1: CGPoint(x: p.x + r, y: p.y + k),
                      control2: CGPoint(x: p.x + k, y: p.y + r))
        path.addCurve(to: CGPoint(x: p.x - r, y: p.y),
                      control1: CGPoint(x: p.x - k, y: p.y + r),
                      control2: CGPoint(x: p.x - r, y: p.y + k))
        path.addCurve(to: CGPoint(x: p.x, y: p.y - r),
                      control1: CGPoint(x: p.x - r, y: p.y - k),
                      control2: CGPoint(x: p.x - k, y: p.y - r))
        path.addCurve(to: CGPoint(x: p.x + r, y: p.y),
                      control1: CGPoint(x: p.x + k, y: p.y - r),
                      control2: CGPoint(x: p.x + r, y: p.y - k))
        path.close()
        canvas.fill(path, color: color)
    }

    /// Stroke A→…→Z with round caps (backend strokes butt-cap/round-join).
    private func strokePolyline(_ points: [CGPoint], width: CGFloat,
                                in canvas: Canvas, color: CGColor) {
        var path = Path()
        path.move(to: points[0])
        for p in points.dropFirst() { path.addLine(to: p) }
        canvas.stroke(path, color: color, lineWidth: width)
        if let f = points.first { dot(at: f, radius: width / 2, in: canvas, color: color) }
        if let l = points.last { dot(at: l, radius: width / 2, in: canvas, color: color) }
    }

    override func drawContent(in canvas: Canvas, bounds: CGRect) {
        switch accessoryType {
        case .none:
            break
        case .disclosureIndicator:
            // Fitted in the .large 10.5×14 box (2 pt stroke, round caps,
            // apex right of center). RTL (MEASURED /tmp/rtlprobe, iPhone
            // SE 2x / iOS 26.1, disclosure abs.x = 16): the chevron points
            // toward trailing (left). ax1 / xxxl scale the same polyline
            // into the measured 20×28.5 / 14×19.5 boxes (NavFlow t200.ax1 /
            // t200.xxxl, Ledger t200.ax1 / t200.xxxl, Notes t200.ax1 /
            // t200.xxxl). Scale only when the box is taller than 15 so the
            // 3x 10.333×14 box (realapp_storage / focus_settings) keeps the
            // fitted 2 pt stroke (ledger-fidelity2).
            let color = UIColor.tertiaryLabel.resolvedCGColor(with: traitCollection)
            if bounds.height > 15 {
                let sx = bounds.width / 10.5
                let sy = bounds.height / 14
                let points: [CGPoint]
                if _layoutIsRTL {
                    points = [CGPoint(x: 7.3 * sx, y: 1.1 * sy),
                              CGPoint(x: 2.5 * sx, y: 5.85 * sy),
                              CGPoint(x: 7.3 * sx, y: 10.6 * sy)]
                } else {
                    points = [CGPoint(x: 3.2 * sx, y: 1.1 * sy),
                              CGPoint(x: 8.0 * sx, y: 5.85 * sy),
                              CGPoint(x: 3.2 * sx, y: 10.6 * sy)]
                }
                strokePolyline(points, width: 2 * sx, in: canvas, color: color)
            } else if _layoutIsRTL {
                strokePolyline([CGPoint(x: 7.3, y: 1.1),
                                CGPoint(x: 2.5, y: 5.85),
                                CGPoint(x: 7.3, y: 10.6)],
                               width: 2, in: canvas, color: color)
            } else {
                strokePolyline([CGPoint(x: 3.2, y: 1.1),
                                CGPoint(x: 8.0, y: 5.85),
                                CGPoint(x: 3.2, y: 10.6)],
                               width: 2, in: canvas, color: color)
            }
        case .checkmark:
            // 19x18 box; tintColor stroke fitted to the golden checkmark.
            let color = tintColor.resolvedCGColor(with: traitCollection)
            strokePolyline([CGPoint(x: 2.9, y: 9.4),
                            CGPoint(x: 7.5, y: 16.2),
                            CGPoint(x: 16.3, y: 2.0)],
                           width: 2.2, in: canvas, color: color)
        }
    }
}

// MARK: - Edit / reorder controls (iOS 26.1, MEASURED TableEditor t900, SE 2x)

/// Red minus disc. Golden class name matches real UIKit's so the dump is
/// comparable. 22 pt disc / 10.5 × 1.5 pt white minus read off TableEditor
/// t900, Alpha's control at [15, 133, 26, 26] @2x (crop 52×52, minus rows
/// 27–29 = 1.5 pt). Fill under the iOS cut is the captured sRGB of
/// `UIColor.systemRed` — see `fill`.
@preconcurrency @MainActor
final class UITableViewCellEditControl: UIView {
    /// MEASURED editredprobe + TableEditor t900, iPhone SE 2x / iOS 26.1,
    /// confprobe/simscene extended-range → untagged sRGB: disc interior is
    /// **(255, 56, 60)** over white, 50 % gray, black and blue (opaque, 1400
    /// solid px each). A 40 pt UIView filled with `UIColor.systemRed` in the
    /// same capture is byte-identical; painting colorprobe's getRed() of
    /// systemRed (255, 66, 69) is 10/9 counts high. The previous (235, 75, 70)
    /// was the Display-P3-raw reading from before confprobe re-encoded
    /// through sRGB (Feed card: P3-raw 78,121,211 vs sRGB 64,122,217).
    /// Catalyst keeps (235, 75, 70).
    static var fill: UIColor {
        if UITableView.isIOSChrome {
            return UIColor(red: 255.0 / 255.0, green: 56.0 / 255.0,
                           blue: 60.0 / 255.0, alpha: 1)
        }
        return UIColor(red: 235.0 / 255.0, green: 75.0 / 255.0,
                       blue: 70.0 / 255.0, alpha: 1)
    }
    /// 2 pt inset → 22 pt disc in the 26 pt box (red cols 4–47 of 52).
    /// MEASURED TableEditor t900.xxxl PNG: disc **29** in the 34.5 pt box
    /// (inset 2·34.5/26). Draw scales `discInset` with the box.
    static let discInset: CGFloat = 2
    /// MEASURED TableEditor t900, SE 2x: 10.5 × 1.5 in the 26 pt box.
    /// MEASURED TableEditor t900.xxxl, SE 2x / iOS 26.1: 14 × 2 in the
    /// 34.5 pt box (= 10.5·34.5/26 × 1.5·34.5/26). Scales with the box.
    static let minusWidth: CGFloat = 10.5
    static let minusHeight: CGFloat = 1.5
    static let minusReferenceSize: CGFloat = 26

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = true
        isOpaque = false
        backgroundColor = nil
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        isUserInteractionEnabled = true
        isOpaque = false
        backgroundColor = nil
    }

    override func drawContent(in canvas: Canvas, bounds: CGRect) {
        let ref = UITableViewCellEditControl.minusReferenceSize
        let inset = UITableViewCellEditControl.discInset * bounds.width / ref
        let disc = CGRect(x: bounds.minX + inset, y: bounds.minY + inset,
                          width: bounds.width - 2 * inset,
                          height: bounds.height - 2 * inset)
        canvas.fill(UITableViewCellEditControl.ellipse(in: disc),
                    color: UITableViewCellEditControl.fill.resolvedCGColor(with: traitCollection))
        let scale = bounds.width / ref
        let mw = UITableViewCellEditControl.minusWidth * scale
        let mh = UITableViewCellEditControl.minusHeight * scale
        let minus = CGRect(x: bounds.midX - mw / 2,
                           y: bounds.midY - mh / 2,
                           width: mw, height: mh)
        canvas.fill(UITableViewCellEditControl.rectPath(minus),
                    color: CGColor(red: 1, green: 1, blue: 1, alpha: 1))
    }

    static func ellipse(in rect: CGRect) -> Path {
        let k: CGFloat = 0.5522847498307936
        let rx = rect.width / 2
        let ry = rect.height / 2
        let cx = rect.midX
        let cy = rect.midY
        var path = Path()
        path.move(to: CGPoint(x: cx + rx, y: cy))
        path.addCurve(to: CGPoint(x: cx, y: cy + ry),
                      control1: CGPoint(x: cx + rx, y: cy + k * ry),
                      control2: CGPoint(x: cx + k * rx, y: cy + ry))
        path.addCurve(to: CGPoint(x: cx - rx, y: cy),
                      control1: CGPoint(x: cx - k * rx, y: cy + ry),
                      control2: CGPoint(x: cx - rx, y: cy + k * ry))
        path.addCurve(to: CGPoint(x: cx, y: cy - ry),
                      control1: CGPoint(x: cx - rx, y: cy - k * ry),
                      control2: CGPoint(x: cx - k * rx, y: cy - ry))
        path.addCurve(to: CGPoint(x: cx + rx, y: cy),
                      control1: CGPoint(x: cx + k * rx, y: cy - k * ry),
                      control2: CGPoint(x: cx + rx, y: cy - k * ry))
        path.close()
        return path
    }

    static func rectPath(_ r: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: r.minX, y: r.minY))
        path.addLine(to: CGPoint(x: r.maxX, y: r.minY))
        path.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        path.addLine(to: CGPoint(x: r.minX, y: r.maxY))
        path.close()
        return path
    }
}

/// Three-line reorder handle. MEASURED TableEditor t900, SE 2x: control
/// [332, cellY, 27, 62], glyph [332, cellY+24, 27, 15], three 1.5 pt
/// bars at glyph-local y 2.0 / 6.5 / 11.5. iOS ink is `.tertiaryLabel`
/// (not the opaque (197, 197, 199) that happens to match it over white):
/// TableEditor t900.dark over black → (70, 70, 73); t3800.dark over
/// selected systemGray4 (58, 58, 60) → (111, 111, 115); light t900 over
/// white → (197, 197, 199); light t3800 over selected (209, 209, 214) →
/// (165, 165, 170). Catalyst keeps the opaque light-over-white constant.
@preconcurrency @MainActor
final class UITableViewCellReorderControl: UIView {
    static let glyphSize = CGSize(width: 27, height: 15)
    static var ink: UIColor {
        if UITableView.isIOSChrome { return .tertiaryLabel }
        return UIColor(red: 197.0 / 255.0, green: 197.0 / 255.0,
                       blue: 199.0 / 255.0, alpha: 1)
    }
    static let lineHeight: CGFloat = 1.5
    static let lineOrigins: [CGFloat] = [2.0, 6.5, 11.5]
    static let lineInsetX: CGFloat = 2.5

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = true
        isOpaque = false
        backgroundColor = nil
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        isUserInteractionEnabled = true
        isOpaque = false
        backgroundColor = nil
    }

    override func drawContent(in canvas: Canvas, bounds: CGRect) {
        let color = UITableViewCellReorderControl.ink.resolvedCGColor(with: traitCollection)
        let glyphH = UITableViewCellReorderControl.glyphSize.height
        // MEASURED TableEditor t900: glyph at cellY+24 in a 62 pt row —
        // iOSCeilToPixel((62 − 15) / 2) = 24 at 2x.
        // MEASURED TableEditor t900.xxxl PNG, SE 2x: 2.0 pt bars at cell
        // y 34.5 / 41.0 / 47.5 in the 83 × 36.5 control (glyph 15, origins
        // 0 / 6.5 / 13). `.large` stays 1.5 pt at 2.0 / 6.5 / 11.5.
        let xxxxl = UITableView.isIOSChrome
            && abs(bounds.width - UITableViewCell.xxxxlReorderWidth) < 0.01
        let glyphY: CGFloat
        let lineH: CGFloat
        let origins: [CGFloat]
        if xxxxl {
            glyphY = UITableView.iOSFloorToPixel((bounds.height - glyphH) / 2) + 0.5
            lineH = 2.0
            origins = [0.0, 6.5, 13.0]
        } else {
            glyphY = UITableView.isIOSChrome
                ? UITableView.iOSCeilToPixel((bounds.height - glyphH) / 2)
                : (bounds.height - glyphH) / 2
            lineH = UITableViewCellReorderControl.lineHeight
            origins = UITableViewCellReorderControl.lineOrigins
        }
        let x = bounds.minX + UITableViewCellReorderControl.lineInsetX
        let w = bounds.width - 2 * UITableViewCellReorderControl.lineInsetX
        for y in origins {
            canvas.fill(UITableViewCellEditControl.rectPath(
                CGRect(x: x, y: bounds.minY + glyphY + y, width: w, height: lineH)),
                        color: color)
        }
    }
}

// MARK: - UITableViewCell

@preconcurrency @MainActor
open class UITableViewCell: UIView, ReusableView {
    public enum CellStyle: Sendable {
        case `default`, subtitle, value1, value2
    }

    public enum AccessoryType: Sendable {
        case none, disclosureIndicator, checkmark
    }

    public enum SelectionStyle: Sendable {
        case none, blue, gray, `default`
    }

    public enum EditingStyle: Sendable {
        case none, delete, insert
    }

    // MARK: Measured metrics (see file header)

    /// Default (and value1) row height; subtitle rows are taller.
    // Catalyst-measured chrome (file header); the iOS 26 values below are
    // MEASURED 2026-09-04 on the iPhone 16 simulator (see UITableView.swift,
    // "iOS 26.1 chrome").
    static var isIOSChrome: Bool { UITableView.isIOSChrome }
    /// iOS `defaultContentConfiguration()` / grouped row height. MEASURED
    /// `tableview_grouped` / `tableview_plain` and rowprobe `*_config_*`
    /// on iPhone SE 2x / iOS 26.1: content-configuration cells are **53**.
    /// Classic `textLabel` cells on the same device are 52 — see
    /// `plainClassicRowHeight`. Catalyst stays 51.5.
    public static var defaultRowHeight: CGFloat { isIOSChrome ? 53 : 51.5 }
    /// iOS plain-style classic `textLabel` row height. MEASURED Tabs t200
    /// golden PNG + dump, iPhone SE 2x / iOS 26.1: separators at pixel
    /// rows 128–129 / 230–231 / 334–335 / … (pt 64, 115, 167, … stride
    /// **52**), RGB (232,232,232); text ink top 84.0 + 52·n; dump cell
    /// `[0, 64+52·n, 375, 52]`, label `[16, 0, 343, 52]`, `contentSize.height`
    /// 1560 = 30×52. Dump and pixels agree (the inset-grouped card-x dump
    /// was the one that lied). rowprobe on the same device: every classic
    /// case is 52 (plain / grouped / insetGrouped / header / accessory /
    /// value1 / UITableViewController); every `defaultContentConfiguration()`
    /// case is 53. Grouped stays `defaultRowHeight` 53 so tableview_grouped
    /// and Focus do not drop. Catalyst stays 51.5.
    static var plainClassicRowHeight: CGFloat {
        plainClassicRowHeight(compatibleWith: .current)
    }
    /// MEASURED Tabs t200, iPhone SE 2x / iOS 26.1: **52**. Tabs t200.ax1:
    /// **80** = `UIFontMetrics(forTextStyle: .body).scaledValue(for: 44)` at
    /// `.accessibilityLarge` (base 44 is a table hit). Floor stays 52 so
    /// `.large` is unchanged (`max(52, 44) = 52`).
    /// MEASURED Tabs t200.xxxl / t7000.xxxl: cells **59**.
    /// `scaledValue(44)` interpolates to 58 (bases 40→52.667,
    /// 48→63.333). ax1 is a table hit **80**.
    static func plainClassicRowHeight(compatibleWith traits: UITraitCollection) -> CGFloat {
        guard isIOSChrome else { return 51.5 }
        let cat = traits.preferredContentSizeCategory
        if cat == .extraExtraExtraLarge { return 59 }
        let scaled = UIFontMetrics(forTextStyle: .body).scaledValue(
            for: 44, compatibleWith: traits)
        return max(52, scaled)
    }
    /// iOS: 49 above the 17 pt primary label's device-pixel height
    /// (69.333 at 3x, 69.5 at 2x — both measured).
    public static var subtitleRowHeight: CGFloat {
        isIOSChrome ? 49 + UITableView.iOSLabelHeight17 : 70.5
    }
    /// Plain-style subtitle row on iOS. MEASURED 2026-09-04, TableEditor t200,
    /// iPhone SE 2x, iOS 26.1: Alpha abs [0, 116, 375, 62], Bravo
    /// [0, 178, 375, 62] — stride **62**. MEASURED TableEditor t200.xxxl:
    /// Alpha [0, 118, 375, **83**], Bravo [0, 201, 375, 83] — stride **83**.
    /// Grouped subtitle stays `subtitleRowHeight` (tableview_grouped:
    /// 69.5 / 69.333). Catalyst automaticDimension is still `defaultRowHeight`.
    public static var plainSubtitleRowHeight: CGFloat {
        plainSubtitleRowHeight(compatibleWith: .current)
    }
    static func plainSubtitleRowHeight(compatibleWith traits: UITraitCollection) -> CGFloat {
        guard isIOSChrome else { return 70.5 }
        if traits.preferredContentSizeCategory == .extraExtraExtraLarge { return 83 }
        return 62
    }
    static let labelX: CGFloat = 16
    static let primaryLabelY: CGFloat = 15.5
    /// iOS: the two-line block (17 pt + 15 pt labels) centred in the row and
    /// the top rounded UP to the device pixel — 15.5 -> 15.667 at 3x, 15.5
    /// on the grid at 2x (measured on both devices).
    static var subtitlePrimaryY: CGFloat {
        guard isIOSChrome else { return primaryLabelY }
        let block = UITableView.iOSLabelHeight17 + FontEngine.labelLineHeight(for: .systemFont(ofSize: 15))
        return UITableView.iOSCeilToPixel((subtitleRowHeight - block) / 2)
    }
    static let subtitleDetailY: CGFloat = 36
    /// Plain iOS subtitle primary origin. MEASURED TableEditor t200, SE 2x:
    /// Alpha text abs y 125, cell y 116 → **9**.
    static let plainSubtitlePrimaryY: CGFloat = 9
    /// Plain iOS subtitle detail origin. MEASURED TableEditor t200, SE 2x:
    /// "First item" abs y 148.5, cell y 116 → **32.5** (9 + 20.5 + 3 pt gap).
    static let plainSubtitleDetailY: CGFloat = 32.5
    /// Accessibility-size plain subtitle layout. MEASURED TableEditor
    /// t200.ax1, iPhone SE 2x / iOS 26.1: cell **117**, primary 33 pt
    /// h=39.5 at y **15** (= `layoutMargins.top`), detail 30 pt h=36 at
    /// y **60.5** (15+39.5+**6**), bottom pad **20.5** (117−96.5).
    /// `.large` keeps 62 / 9 / 32.5.
    static let plainSubtitleAccessibilityTop: CGFloat = 15
    static let plainSubtitleAccessibilityGap: CGFloat = 6
    static let plainSubtitleAccessibilityBottom: CGFloat = 20.5
    /// MEASURED TableEditor t200.xxxl, iPhone SE 2x / iOS 26.1: cell **83**,
    /// primary 23 pt h=27.5 at y **11**, detail 21 pt h=25.5 at y **42.5**
    /// (11+27.5+**4**), bottom pad **15** (83−68). `.large` keeps 62 / 9 / 32.5.
    static let plainSubtitleXxxxlTop: CGFloat = 11
    static let plainSubtitleXxxxlGap: CGFloat = 4
    static let plainSubtitleXxxxlBottom: CGFloat = 15
    static let plainSubtitleXxxxlDetailY: CGFloat = 42.5
    /// Edit-mode contentView.x. MEASURED TableEditor t900, SE 2x: content
    /// view abs [40, cellY, 292, 62] with labels at x 56 (= 40 + 16).
    static let editLeadingGutter: CGFloat = 40
    /// Delete-control box. MEASURED TableEditor t900: UITableViewCellEditControl
    /// abs [15, cellY+17, 26, 26]; the disc is 22 pt (2 pt inset).
    static let editControlSize: CGFloat = 26
    static let editControlX: CGFloat = 15
    /// Reorder handle. MEASURED TableEditor t900: UITableViewCellReorderControl
    /// abs [332, cellY, 27, 62] — 27 wide, 16 pt (SE system margin) from the
    /// trailing edge (375 − 16 − 27 = 332).
    static let reorderWidth: CGFloat = 27
    /// MEASURED TableEditor t2350.ax1, iPhone SE 2x / iOS 26.1: at
    /// `.accessibilityLarge` the delete control is **[16, cellY+33, 39, 38]**,
    /// content view x **55** (= 16+39), reorder **[318, cellY, 41, 117]**
    /// (375−16−41). Labels at x **71** (= 55+16). `.large` stays 15/26/40/27.
    static let accessibilityEditControlSize = CGSize(width: 39, height: 38)
    static let accessibilityEditControlX: CGFloat = 16
    static let accessibilityEditLeadingGutter: CGFloat = 55
    static let accessibilityReorderWidth: CGFloat = 41
    static let accessibilityEditControlY: CGFloat = 33
    /// MEASURED TableEditor t900.xxxl, iPhone SE 2x / iOS 26.1: at
    /// `.extraExtraExtraLarge` the delete control is **[14.5, cellY+21, 34.5, 34.5]**
    /// in the 83 pt row, content view x **47.5**, reorder **[322.5, cellY, 36.5, 83]**
    /// (375−16−36.5). Labels at x **63.5** (= 47.5+16). y 21 is not centred
    /// ((83−34.5)/2 = 24.25), same class as ax1's y 33 vs (117−38)/2.
    static let xxxxlEditControlSize: CGFloat = 34.5
    static let xxxxlEditControlX: CGFloat = 14.5
    static let xxxxlEditLeadingGutter: CGFloat = 47.5
    static let xxxxlReorderWidth: CGFloat = 36.5
    static let xxxxlEditControlY: CGFloat = 21
    /// iOS: the window's system layout margin (20 on the iPhone 16, 16 on
    /// the SE — see UITableView.iOSSystemMargin).
    var trailingMargin: CGFloat { UITableViewCell.isIOSChrome ? iOSMargin : 16 }

    /// Window `traitOverrides` `.accessibilityLarge` grows the edit chrome.
    /// Guarded by the iOS cut; Catalyst keeps the `.large` 26/40/27 numbers.
    var usesAccessibilityEditChrome: Bool {
        UITableViewCell.isIOSChrome
            && traitCollection.preferredContentSizeCategory.isAccessibilityCategory
    }
    /// MEASURED TableEditor t900.xxxl: `.extraExtraExtraLarge` is not an
    /// accessibility category, so the ax1 39/55/41 chrome must not fire;
    /// the 34.5/47.5/36.5 numbers apply instead.
    var usesXxxxlEditChrome: Bool {
        UITableViewCell.isIOSChrome
            && traitCollection.preferredContentSizeCategory == .extraExtraExtraLarge
    }
    var effectiveEditLeadingGutter: CGFloat {
        if usesAccessibilityEditChrome { return UITableViewCell.accessibilityEditLeadingGutter }
        if usesXxxxlEditChrome { return UITableViewCell.xxxxlEditLeadingGutter }
        return UITableViewCell.editLeadingGutter
    }
    var effectiveReorderWidth: CGFloat {
        if usesAccessibilityEditChrome { return UITableViewCell.accessibilityReorderWidth }
        if usesXxxxlEditChrome { return UITableViewCell.xxxxlReorderWidth }
        return UITableViewCell.reorderWidth
    }

    /// A cell's layout margins are the window's system margin horizontally
    /// and a flat 15 vertically — NOT `UIView`'s 8 pt default. Invisible
    /// until something constrains against them, which is exactly what a xib
    /// cell does: IB writes its leading constraints against
    /// `contentView.leadingMargin`.
    ///
    /// MEASURED (realapp_storage_light, both oracle devices, 2026-09-04):
    /// `SwitchCell.layoutMargins` and its content view's are [15, 20, 15, 20]
    /// on the iPhone 16 (393 pt) and [15, 16, 15, 16] on the SE (375 pt) —
    /// the same 390 pt threshold `UITableView.iOSSystemMargin` already
    /// carries, confirmed here on a second view class. Pad (A16) 820 pt
    /// stays **16** (`iOSPadCellMargin` / `iOSMargin`): SwitchCell switch
    /// at x 741 = 820 − 16 − 63, `layoutMargins` `[15, 16, 15, 16]`.
    /// Forms-ipad t200 fields sit at x 20 against `layoutMarginsGuide`;
    /// flipping this default to 20 dropped `realapp_storage_light_ipad`
    /// 99.689 → 99.554. Two samples disagree; the xib oracle wins and
    /// Forms-ipad x=20 stays OPEN.
    override var _defaultBaseLayoutMargins: UIEdgeInsets {
        UIEdgeInsets(top: 15, left: contentMargin, bottom: 15, right: contentMargin)
    }
    /// The horizontal layout margin of the cell and its content view. MEASURED
    /// realapp_ledger_light golden (iPhone 16 / iOS 26.1, 2026-09-07) and the
    /// focus-fidelity-tables tableprobe on the same device: inside an
    /// inset-grouped card (itself at the 20 pt system inset) the margins are
    /// [15, 16, 15, 16] and labels constrained to the margins guide sit at
    /// x 36 = 20 + 16, not 40. Plain/grouped cells keep the 20 pt system
    /// margin (realapp_storage_light SwitchCell [15, 20, 15, 20]). Accessories
    /// keep `trailingMargin` (20): the same probe puts a custom accessory's
    /// right edge at 353 - 20 and the PaddedSwitch at x 262.
    var contentMargin: CGFloat {
        if UITableViewCell.isIOSChrome, !UITableView.isPadChrome, tableView?.style == .insetGrouped {
            // MEASURED both ways: iPhone 16 portrait (393 pt) labels at 36 =
            // card 20 + 16; SE landscape (667 pt, Ledger.t200.landscape golden)
            // labels at 40 = card 20 + 20. The inner inset follows the window
            // width at 414, not the 390 threshold of the system margin (the
            // merge check refused a flat 16: three Ledger landscape rows
            // dropped ~1 pt).
            let width = window?.bounds.width ?? tableView?.bounds.width ?? bounds.width
            return width >= 414 ? UITableView.iOSSystemMargin(width: width)
                                : UITableView.iOSPhoneInsetGroupedInnerInset
        }
        return trailingMargin
    }
    var iOSMargin: CGFloat {
        if UITableView.isPadChrome {
            // MEASURED `/tmp/ipad-open-cap` table_inset / table_grouped,
            // iPad (A16) 820×1180 @2x / iOS 26.1: inset-grouped
            // `layoutMargins` `[15, 20, 15, 20]`; grouped / plain stay 16.
            if tableView?.style == .insetGrouped {
                return UITableView.iOSPadInsetGroupedInnerInset
            }
            return UITableView.iOSPadCellMargin
        }
        return UITableView.iOSSystemMargin(width: window?.bounds.width ?? tableView?.bounds.width ?? bounds.width)
    }
    /// Right edge of a value1 detail label with no accessory (16 in on iOS).
    static var detailTrailingMargin: CGFloat { isIOSChrome ? 16 : 16 }
    /// iOS: the chevron symbol is 10.333 wide at 3x and 10.5 at 2x — a
    /// width in (10, 10.333] rounded up to the device pixel; 14 tall on both.
    /// `.large` / unspecified. Dynamic Type uses ``effectiveDisclosureSize``.
    /// MEASURED NavFlow / Ledger / Notes t200.ax1 / t200.xxxl, iPhone SE 2x /
    /// iOS 26.1: `.large` accessory 10.5×14 (contentView 316.5); `.xxxl`
    /// 14×19.5 (contentView 313); `.ax1` 20×28.5 (contentView 307). Trailing
    /// margin stays 16 (343 − content − accessory).
    static var disclosureSize: CGSize {
        isIOSChrome ? CGSize(width: UITableView.iOSCeilToPixel(10.2), height: 14) : CGSize(width: 10.5, height: 14)
    }
    /// MEASURED NavFlow t200.ax1, iPhone SE 2x / iOS 26.1:
    /// `_UITableCellAccessoryButton [307, 2, 20, 28.5]` in the 44 pt
    /// inset-grouped cell (343 − 16 trailing − 20 = contentView 307).
    /// MEASURED NavFlow t200.xxxl / Ledger t200.xxxl / Notes t200.xxxl:
    /// `[313, 10, 14, 19.5]` (contentView 313). `.large` t200 stays 10.5×14
    /// (contentView 316.5).
    static func disclosureSize(compatibleWith traits: UITraitCollection) -> CGSize {
        guard isIOSChrome else { return disclosureSize }
        let cat = traits.preferredContentSizeCategory
        if cat.isAccessibilityCategory { return CGSize(width: 20, height: 28.5) }
        if cat == .extraExtraExtraLarge { return CGSize(width: 14, height: 19.5) }
        return disclosureSize
    }
    var effectiveDisclosureSize: CGSize {
        UITableViewCell.disclosureSize(compatibleWith: traitCollection)
    }
    /// iOS: 19 x 17.333 at 3x, 19 x 18 at 2x (measured; no single rounding
    /// of one value gives both, so the two readings are carried as such).
    static var checkmarkSize: CGSize {
        isIOSChrome ? CGSize(width: 19, height: UIScreen.main.scale >= 3 ? 17.333333 : 18) : CGSize(width: 19, height: 18)
    }
    /// Leading text inset (16; the table sets 20 for plain cells on iOS).
    var _textInset: CGFloat = 16
    /// Extra top padding of a grouped section's first row on iOS (2 pt).
    var _leadingPadding: CGFloat = 0
    /// Checkmark trailing margin (measured 18.5, vs 16 for the chevron).
    var checkmarkTrailingMargin: CGFloat { UITableViewCell.isIOSChrome ? iOSMargin + 2.5 : 18.5 }
    /// Content-edge gap between the content view and a checkmark accessory.
    static let checkmarkContentGap: CGFloat = 2.5
    /// value1 detail gap from the content edge when an accessory is present.
    static let detailAccessoryGap: CGFloat = 8
    /// Minimum gap between a value1 primary and its detail when they
    /// would overlap. MEASURED NavFlow t200.ax1, iPhone SE 2x / iOS 26.1:
    /// "Appearance" maxX 188 + **6** = "Automatic" x 194 (detail width 105
    /// against content 307 − 8). "Manage Downloads" maxX 297 leaves 2 pt
    /// so "1.2 GB" collapses to width 0 at x 299.
    static let value1TitleDetailGap: CGFloat = 6
    static let separatorThickness: CGFloat = 1
    static let highlightFadeDuration: Double = 0.3

    /// Selection/highlight fill. Light is MEASURED (#DCDCDC,
    /// golden/tableview_selected); dark is the systemGray4-family
    /// approximation (unmeasured — no dark selected golden).
    public static let selectionColor = UIColor(dynamicProvider: { traits in
        // iOS 26.1, MEASURED 2026-09-04 (scripts/ios_suite.sh
        // tableview_selected): the selected row is systemGray4 —
        // (209, 209, 214) in light, i.e. the dynamic colour itself.
        if UITableView.isIOSChrome { return UIColor.systemGray4.resolvedColor(with: traits) }
        return traits.userInterfaceStyle == .dark
            ? UIColor(red: 58.0 / 255, green: 58.0 / 255, blue: 60.0 / 255, alpha: 1)
            : UIColor(red: 220.0 / 255, green: 220.0 / 255, blue: 220.0 / 255, alpha: 1)
    })

    // MARK: State

    /// INTERNAL, deliberately. UIKit takes `style` in the initializer and
    /// never gives it back — `UITableViewCell` has no `style` property at all —
    /// so publishing one here breaks any app class that declares its own.
    /// pocket-casts' ThemeableCell declares `var style: ThemeStyle`, which
    /// collided with this until it went internal.
    let style: CellStyle
    /// UIKit declares this read-only; a cell built from a nib has no
    /// `init(style:reuseIdentifier:)` to carry it, so the table stamps it on
    /// after instantiation (`_setNibReuseIdentifier`), which is what UIKit
    /// does too.
    public private(set) var reuseIdentifier: String?

    public let contentView: UIView = UITableViewCellContentView()
    /// UIKit exposes these legacy cell views as optionals.  The stock styles
    /// create them eagerly, so an implicitly-unwrapped optional preserves both
    /// source shapes used by applications: `textLabel.text` and
    /// `textLabel?.text`.
    public let textLabel: UILabel! = UILabel()
    /// Present for subtitle/value1/value2 cells, nil for `.default` (UIKit).
    public private(set) var detailTextLabel: UILabel?
    public private(set) var imageView: UIImageView? = UIImageView()

    /// Per-cell separator override. The untouched initial value uses the
    /// table's measured style inset; assigning any value (including `.zero`)
    /// establishes an explicit cell override, matching common UIKit code.
    public var separatorInset: UIEdgeInsets = .zero {
        didSet {
            _hasExplicitSeparatorInset = true
            setNeedsLayout()
        }
    }
    var _hasExplicitSeparatorInset = false

    public var accessoryType: AccessoryType = .none {
        didSet {
            if accessoryType != oldValue {
                _accessoryGlyphView.accessoryType = accessoryType
                contentView._notifyLayoutMarginsChanged()
                setNeedsLayout()
            }
        }
    }

    /// A custom trailing view for the cell. As in UIKit, a custom accessory
    /// takes visual precedence over `accessoryType`; removing it restores the
    /// configured stock glyph.
    public var accessoryView: UIView? {
        didSet {
            guard accessoryView !== oldValue else { return }
            oldValue?.removeFromSuperview()
            if let accessoryView {
                addSubview(accessoryView)
            }
            setNeedsLayout()
        }
    }

    public var selectionStyle: SelectionStyle = .default

    public private(set) var isSelected = false
    public private(set) var isHighlighted = false
    public private(set) var isEditing = false

    /// The table currently displaying this cell (set while bound).
    weak var tableView: UITableView?
    /// Managed by the table's tiling pass.
    let separatorView = UIView()
    /// The line above the row. Only `.grouped` uses it, and only on the first
    /// row of a section — see `UITableView.updateSeparators`.
    let topSeparatorView = UIView()
    /// The portable vector backing for `accessoryType`. Keep it separate from
    /// UIKit's public `accessoryView`, which is application-owned content.
    let _accessoryGlyphView = UITableCellAccessoryView()
    /// iOS edit-mode chrome (nil until the cell first enters editing).
    var _editControl: UITableViewCellEditControl?
    var _reorderControl: UITableViewCellReorderControl?
    public var selectedBackgroundView: UIView? {
        didSet {
            guard selectedBackgroundView !== oldValue else { return }
            oldValue?.removeFromSuperview()
            if let view = selectedBackgroundView {
                view.isUserInteractionEnabled = false
                view.alpha = (isSelected || isHighlighted) ? 1 : 0
                insertSubview(view, at: 0)
                setNeedsLayout()
            }
        }
    }

    // MARK: Init

    public init(style: CellStyle, reuseIdentifier: String?) {
        self.style = style
        self.reuseIdentifier = reuseIdentifier
        super.init(frame: CGRect(x: 0, y: 0, width: 320,
                                 height: UITableViewCell.defaultRowHeight))
        configureCell(for: style)
    }

    /// UIKit's legacy zero-argument cell keeps the standard 320 x 44 frame
    /// of `init(style:reuseIdentifier:)`; it is not UIView's zero-frame path.
    public convenience init() {
        self.init(style: .default, reuseIdentifier: nil)
    }

    public override convenience init(frame: CGRect) {
        _ = frame
        self.init(style: .default, reuseIdentifier: nil)
    }

    public required init?(coder: NSCoder) {
        style = .default
        reuseIdentifier = nil
        super.init(coder: coder)
        configureCell(for: .default)
    }

    /// Stamp the reuse identifier onto a cell a `UINib` produced (see
    /// `UITableView.register(_:forCellReuseIdentifier:)`).
    func _setNibReuseIdentifier(_ identifier: String) {
        reuseIdentifier = identifier
    }

    private func configureCell(for style: CellStyle) {
        textLabel.font = .systemFont(ofSize: 17)
        textLabel.textColor = .label

        contentView.frame = bounds
        addSubview(contentView)
        if let imageView { contentView.addSubview(imageView) }
        contentView.addSubview(textLabel)

        switch style {
        case .default:
            break
        case .subtitle:
            let d = UILabel()
            d.font = .systemFont(ofSize: 15)
            d.textColor = .secondaryLabel
            contentView.addSubview(d)
            detailTextLabel = d
        case .value1, .value2:
            let d = UILabel()
            d.font = .systemFont(ofSize: 17)
            d.textColor = .secondaryLabel
            contentView.addSubview(d)
            detailTextLabel = d
        }

        _accessoryGlyphView.accessoryType = accessoryType
        addSubview(_accessoryGlyphView)

        separatorView.backgroundColor = .separator
        separatorView.isUserInteractionEnabled = false
        addSubview(separatorView)

        topSeparatorView.backgroundColor = .separator
        topSeparatorView.isUserInteractionEnabled = false
        topSeparatorView.isHidden = true
        addSubview(topSeparatorView)
    }

    /// MEASURED TableEditor t200.ax1, iPhone SE 2x / iOS 26.1: a plain
    /// `.subtitle` cell's `UITableViewLabel`s follow the window
    /// `traitOverrides` (primary **33 pt** body, detail **30 pt**
    /// subheadline) even though `UIFont.preferredFont(forTextStyle:)` at
    /// construction still reads process `.large` (Forms/Feed custom
    /// labels stay 17). `.large` is 17/15 — the previous hardcoded sizes.
    func applyIOSPreferredFonts() {
        guard UITableViewCell.isIOSChrome else { return }
        let traits = traitCollection
        switch style {
        case .subtitle:
            textLabel.font = .preferredFont(forTextStyle: .body, compatibleWith: traits)
            detailTextLabel?.font = .preferredFont(forTextStyle: .subheadline,
                                                   compatibleWith: traits)
        case .default, .value1, .value2:
            // MEASURED NavFlow t200.ax1: value1 `UITableViewLabel` is **33 pt**
            // body (h=39.5) for primary and detail; rows stay 44 because
            // `heightForRowAt` pins them. Tabs t200.ax1 default `textLabel` is
            // the same 33 pt. Applied from the cell's `traitCollection` (window
            // `traitOverrides`), not `current`. `.large` keeps the
            // construction 17 pt `systemFont` — preferredFont body at
            // `.large` is also 17 but a different face and dropped
            // NavFlow t4800.landscape 96.35 → 96.054 (same 75.5 blob).
            let body = UIFont.preferredFont(forTextStyle: .body, compatibleWith: traits)
            if abs(body.pointSize - 17) > 0.01 {
                textLabel.font = body
                detailTextLabel?.font = body
            }
        }
    }

    /// Self-sized height of a plain subtitle cell. `.large` stays **62**.
    /// Accessibility: 15 + primaryH + 6 + detailH + 20.5 (**117** at ax1).
    /// xxxl: 11 + primaryH + 4 + detailH + 15 (**83** at 27.5/25.5).
    func iOSPlainSubtitleFittingHeight() -> CGFloat {
        applyIOSPreferredFonts()
        let cat = traitCollection.preferredContentSizeCategory
        if cat.isAccessibilityCategory {
            let p = textLabel.intrinsicContentSize.height
            let d = detailTextLabel?.intrinsicContentSize.height ?? 0
            return UITableViewCell.plainSubtitleAccessibilityTop
                + p + UITableViewCell.plainSubtitleAccessibilityGap
                + d + UITableViewCell.plainSubtitleAccessibilityBottom
        }
        if cat == .extraExtraExtraLarge {
            let p = textLabel.intrinsicContentSize.height
            let d = detailTextLabel?.intrinsicContentSize.height ?? 0
            return UITableViewCell.plainSubtitleXxxxlTop
                + p + UITableViewCell.plainSubtitleXxxxlGap
                + d + UITableViewCell.plainSubtitleXxxxlBottom
        }
        return UITableViewCell.plainSubtitleRowHeight
    }

    // MARK: Reuse

    open func prepareForReuse() {
        setSelected(false, animated: false)
        setHighlighted(false, animated: false)
        setEditing(false, animated: false)
        separatorView.isHidden = false
        topSeparatorView.isHidden = true
    }

    public func setEditing(_ editing: Bool, animated: Bool) {
        guard editing != isEditing else { return }
        isEditing = editing
        setNeedsLayout()
    }

    private var showsDeleteControl: Bool {
        isEditing && UITableViewCell.isIOSChrome
            && (tableView?._editingStyle(for: self) == .delete)
    }
    private var showsReorderControlNow: Bool {
        isEditing && UITableViewCell.isIOSChrome
            && (tableView?._canMove(self) ?? false)
    }

    // MARK: Selection / highlight

    open func setSelected(_ selected: Bool, animated: Bool) {
        guard selected != isSelected else { return }
        isSelected = selected
        updateSelectionOverlay(animated: animated)
    }

    open func setHighlighted(_ highlighted: Bool, animated: Bool) {
        guard highlighted != isHighlighted else { return }
        isHighlighted = highlighted
        updateSelectionOverlay(animated: animated)
    }

    private func ensureSelectedBackgroundView() -> UIView {
        if let v = selectedBackgroundView { return v }
        let v = UIView()
        v.backgroundColor = UITableViewCell.selectionColor
        v.isUserInteractionEnabled = false
        v.alpha = 0
        selectedBackgroundView = v
        return v
    }

    private func updateSelectionOverlay(animated: Bool) {
        let on = (isSelected || isHighlighted) && selectionStyle != .none
        if on {
            let v = ensureSelectedBackgroundView()
            v.frame = bounds
            v.removeAllAnimations()
            v.alpha = 1
        } else if let v = selectedBackgroundView, v.alpha > 0 {
            if animated {
                UIView.animate(withDuration: UITableViewCell.highlightFadeDuration,
                               delay: 0, options: .curveLinear,
                               animations: { v.alpha = 0 })
            } else {
                v.removeAllAnimations()
                v.alpha = 0
            }
        }
        tableView?.updateSeparators()
    }

    // MARK: Touch handling (row tap → highlight → select)

    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard selectionStyle != .none, tableView?.allowsSelection != false else { return }
        setHighlighted(true, animated: false)
        tableView?.cellHighlightDidChange(self, highlighted: true)
    }

    open override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {}

    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isHighlighted else { return }
        setHighlighted(false, animated: false)
        tableView?.cellHighlightDidChange(self, highlighted: false)
        tableView?.commitRowTap(on: self)
    }

    open override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isHighlighted else { return }
        setHighlighted(false, animated: true)
        tableView?.cellHighlightDidChange(self, highlighted: false)
    }

    // MARK: Layout (measured cell geometry)

    /// Width of the content region for the current accessory / edit chrome.
    var contentWidth: CGFloat {
        var leading: CGFloat = 0
        var trailing: CGFloat = 0
        if showsDeleteControl { leading = effectiveEditLeadingGutter }
        if showsReorderControlNow {
            trailing = effectiveReorderWidth + trailingMargin
        }
        let available = max(0, bounds.width - leading - trailing)
        if let accessoryView {
            // iOS butts the content view straight up against a custom
            // accessory: no gap between them.
            //
            // MEASURED (realapp_storage_light, both oracle devices): the
            // SwitchCell content view is 310 wide with its 63 pt switch at
            // x = 310 on the iPhone 16 (393 - 20 - 63) and 296 wide with the
            // switch at x = 296 on the SE (375 - 16 - 63). The port's 8 pt
            // `detailAccessoryGap` — which is the DETAIL LABEL's gap, and
            // stays that below — left it 8 pt short on both.
            let gap = UITableViewCell.isIOSChrome
                ? 0 : UITableViewCell.detailAccessoryGap
            return max(0, available - trailingMargin
                       - accessoryView.frame.width - gap)
        }
        switch accessoryType {
        case .none:
            return available
        case .disclosureIndicator:
            return max(0, available - trailingMargin
                       - effectiveDisclosureSize.width)
        case .checkmark:
            return max(0, available - checkmarkTrailingMargin
                       - UITableViewCell.checkmarkSize.width
                       - UITableViewCell.checkmarkContentGap)
        }
    }

    /// Round up to the half-point grid (accessory centering, measured).
    /// iOS: down to the third-point grid ((53 - 14) / 2 = 19.5 -> 19.333).
    private static func ceilHalf(_ v: CGFloat) -> CGFloat {
        if isIOSChrome { return UITableView.iOSFloorToPixel(v) }
        return (v * 2).rounded(.up) / 2
    }

    private func layoutEditChrome(pad: CGFloat, height h: CGFloat, width w: CGFloat) {
        if showsDeleteControl {
            let control: UITableViewCellEditControl
            if let existing = _editControl {
                control = existing
            } else {
                let v = UITableViewCellEditControl()
                v.isHidden = true
                addSubview(v)
                _editControl = v
                control = v
            }
            let size: CGSize
            let x: CGFloat
            let y: CGFloat
            if usesAccessibilityEditChrome {
                size = UITableViewCell.accessibilityEditControlSize
                x = UITableViewCell.accessibilityEditControlX
                // ax1: MEASURED y 33 in the 117 pt cell (not (117−38)/2 = 39.5).
                y = UITableViewCell.accessibilityEditControlY
            } else if usesXxxxlEditChrome {
                size = CGSize(width: UITableViewCell.xxxxlEditControlSize,
                               height: UITableViewCell.xxxxlEditControlSize)
                x = UITableViewCell.xxxxlEditControlX
                // MEASURED TableEditor t900.xxxl: y 21 in the 83 pt cell
                // (not (83−34.5)/2 = 24.25).
                y = UITableViewCell.xxxxlEditControlY
            } else {
                size = CGSize(width: UITableViewCell.editControlSize,
                               height: UITableViewCell.editControlSize)
                x = UITableViewCell.editControlX
                // `.large`: centred in the row, (62−26)/2 = 18.
                y = UITableView.iOSFloorToPixel((h - size.height) / 2)
            }
            control.isHidden = false
            control.frame = CGRect(x: x, y: pad + y,
                                   width: size.width, height: size.height)
        } else {
            _editControl?.isHidden = true
        }

        if showsReorderControlNow {
            let control: UITableViewCellReorderControl
            if let existing = _reorderControl {
                control = existing
            } else {
                let v = UITableViewCellReorderControl()
                v.isHidden = true
                addSubview(v)
                _reorderControl = v
                control = v
            }
            control.isHidden = false
            control.frame = CGRect(x: w - trailingMargin - effectiveReorderWidth,
                                   y: pad,
                                   width: effectiveReorderWidth, height: h)
        } else {
            _reorderControl?.isHidden = true
        }
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        applyIOSPreferredFonts()
        let w = bounds.width
        let pad = _leadingPadding
        let h = bounds.height - pad

        selectedBackgroundView?.frame = bounds
        if let tableView {
            _textInset = tableView.style == .plain
                ? tableView.plainTextInset : tableView.groupedTextInset
        }
        let lead = showsDeleteControl ? effectiveEditLeadingGutter : 0
        contentView.frame = CGRect(x: lead, y: pad, width: contentWidth, height: h)
        layoutEditChrome(pad: pad, height: h, width: w)

        // Accessory. A custom view owns its size and replaces the stock glyph.
        if let custom = accessoryView {
            _accessoryGlyphView.isHidden = true
            let size = custom.frame.size
            // A custom accessory centres UP to the pixel, where the stock
            // glyph below centres DOWN (`ceilHalf`). Two code paths in UIKit,
            // and each was measured on its own: the glyph's
            // (53 - 14) / 2 = 19.5 -> 19.333, and this one's.
            //
            // MEASURED (realapp_storage_light, iPhone 16 3x / iOS 26.1): the
            // 28 pt switch in a 65 pt SwitchCell sits at y = 18.667, not the
            // 18.333 the glyph rule gives. Consistent with the Auto Layout
            // centre in the same golden — the sibling DisclosureCell's
            // xib-constrained 32 pt chevron rounds (65 - 32) / 2 = 16.5 up to
            // 16.667 too. The SE (2x) has both on the grid at 18.5 and 16.5,
            // so it neither confirms nor contradicts the direction.
            let y = UITableView.isIOSChrome
                ? UITableView.iOSCeilToPixel((h - size.height) / 2)
                : UITableViewCell.ceilHalf((h - size.height) / 2)
            custom.frame = CGRect(x: w - trailingMargin - size.width,
                                  y: pad + y,
                                  width: size.width, height: size.height)
        } else {
            switch accessoryType {
            case .none:
                _accessoryGlyphView.isHidden = true
            case .disclosureIndicator:
                _accessoryGlyphView.isHidden = false
                let s = effectiveDisclosureSize
                _accessoryGlyphView.frame = CGRect(
                    x: w - trailingMargin - s.width,
                    y: pad + UITableViewCell.ceilHalf((h - s.height) / 2),
                    width: s.width, height: s.height)
            case .checkmark:
                _accessoryGlyphView.isHidden = false
                let s = UITableViewCell.checkmarkSize
                _accessoryGlyphView.frame = CGRect(
                    x: w - checkmarkTrailingMargin - s.width,
                    y: pad + UITableViewCell.ceilHalf((h - s.height) / 2),
                    width: s.width, height: s.height)
            }
        }

        // Labels (inside the content view, which already carries `pad`).
        var labelX = _textInset
        if let imageView, let image = imageView.image {
            let size = image.size
            let longestSide = max(size.width, size.height)
            let scale = longestSide > h ? h / longestSide : 1
            let fitted = CGSize(width: size.width * scale,
                                height: size.height * scale)
            imageView.isHidden = false
            imageView.frame = CGRect(x: _textInset,
                                     y: (h - fitted.height) / 2,
                                     width: fitted.width,
                                     height: fitted.height)
            labelX = imageView.frame.maxX + UITableViewCell.labelX
        } else {
            imageView?.isHidden = true
        }
        let maxTextW: CGFloat
        if UITableViewCell.isIOSChrome, style == .value1 || style == .value2,
           detailTextLabel != nil {
            // MEASURED NavFlow t200.ax1: value1 primary is not inset a
            // second 16 pt from the content trailing edge — "Manage
            // Downloads" is 281 at x 16 in a 307 content view (16+281=297).
            // The detail then takes whatever remains after `value1TitleDetailGap`.
            maxTextW = contentWidth - labelX
        } else {
            maxTextW = contentWidth - labelX - _textInset
        }
        let primary = textLabel.sizeThatFits(
            CGSize(width: CGFloat.greatestFiniteMagnitude, height: h))
        // iOS: a single-line primary is centred and its top rounded UP to
        // the device pixel ((53 - 20.333) / 2 = 16.333 at 3x; (53 - 20.5) / 2
        // = 16.5 at 2x, both measured); a subtitle cell's primary
        // sits at subtitlePrimaryY.
        //
        // Default-style iOS exception: the label FILLS the content view.
        // MEASURED Tabs t200, iPhone SE 2x / iOS 26.1: `UITableViewLabel`
        // `[16, 0, 343, 52]` — width = contentWidth − 16 − 16, height =
        // contentView.height, while intrinsic stays 20.5. UILabel then
        // centres the 17 pt line in that box (`drawContent` iOS y0).
        // Catalyst and subtitle / value1 keep the intrinsic box.
        let primaryY: CGFloat
        let accessibilitySubtitle = UITableViewCell.isIOSChrome
            && style == .subtitle
            && tableView?.style == .plain
            && traitCollection.preferredContentSizeCategory.isAccessibilityCategory
        let xxxxlSubtitle = UITableViewCell.isIOSChrome
            && style == .subtitle
            && tableView?.style == .plain
            && traitCollection.preferredContentSizeCategory == .extraExtraExtraLarge
        if accessibilitySubtitle {
            primaryY = UITableViewCell.plainSubtitleAccessibilityTop
        } else if xxxxlSubtitle {
            primaryY = UITableViewCell.plainSubtitleXxxxlTop
        } else if UITableViewCell.isIOSChrome, style == .subtitle {
            primaryY = tableView?.style == .plain
                ? UITableViewCell.plainSubtitlePrimaryY
                : UITableViewCell.subtitlePrimaryY
        } else if UITableViewCell.isIOSChrome {
            if style == .value1 || style == .value2 {
                // MEASURED NavFlow t200.ax1: 39.5 body in a 44 pt row at
                // y **3** (`ceil((44−39.5)/2)`), not the 2x pixel-ceil 2.5.
                // t200.xxxl: 27.5 at y **9** (`ceil(8.25)=9` vs pixel 8.5).
                // `.large` 20.5 → 12 on both grids.
                primaryY = ((h - primary.height) / 2).rounded(.up)
            } else {
                primaryY = UITableView.iOSCeilToPixel((h - primary.height) / 2)
            }
        } else {
            primaryY = UITableViewCell.primaryLabelY
        }
        if UITableViewCell.isIOSChrome, style == .default {
            textLabel.frame = CGRect(x: labelX,
                                     y: 0,
                                     width: max(0, maxTextW),
                                     height: h)
        } else {
            textLabel.frame = CGRect(x: labelX,
                                     y: primaryY,
                                     width: min(primary.width, max(0, maxTextW)),
                                     height: primary.height)
        }
        if let d = detailTextLabel {
            let s = d.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude,
                                          height: h))
            switch style {
            case .subtitle:
                let detailY: CGFloat
                if accessibilitySubtitle {
                    detailY = UITableViewCell.plainSubtitleAccessibilityTop
                        + primary.height
                        + UITableViewCell.plainSubtitleAccessibilityGap
                } else if xxxxlSubtitle {
                    detailY = UITableViewCell.plainSubtitleXxxxlDetailY
                } else if UITableViewCell.isIOSChrome && tableView?.style == .plain {
                    detailY = UITableViewCell.plainSubtitleDetailY
                } else {
                    detailY = UITableViewCell.subtitleDetailY
                }
                d.frame = CGRect(x: labelX,
                                 y: detailY,
                                 width: min(s.width, max(0, maxTextW)),
                                 height: s.height)
            default: // value1 / value2: right-aligned detail
                let right = accessoryView == nil && accessoryType == .none
                    ? bounds.width - UITableViewCell.detailTrailingMargin
                    : contentWidth - UITableViewCell.detailAccessoryGap
                // MEASURED NavFlow t200.ax1: "Automatic" is 105 at x 194
                // against Appearance maxX 188 (gap 6), not the intrinsic
                // 145; "1.2 GB" collapses to width 0 at the right edge.
                let leftMin = textLabel.frame.maxX + UITableViewCell.value1TitleDetailGap
                let fitted = min(s.width, max(0, right - leftMin))
                d.frame = CGRect(x: right - fitted,
                                 y: primaryY,
                                 width: fitted, height: s.height)
            }
        }

        // Separator: bottom-aligned; horizontal inset applied by the table.
        let inset = tableView?.separatorDrawInsets(for: self)
            ?? (left: UITableViewCell.labelX, right: 0)
        let separatorWidth = max(0, w - inset.left - inset.right)
        separatorView.frame = CGRect(
            x: inset.left,
            y: h - UITableViewCell.separatorThickness,
            width: separatorWidth,
            height: UITableViewCell.separatorThickness)
        topSeparatorView.frame = CGRect(
            x: inset.left, y: 0,
            width: separatorWidth,
            height: UITableViewCell.separatorThickness)

        // MEASURED NavFlow t200.rtl / TableEditor t200.rtl, iPhone SE 2x /
        // iOS 26.1: appearance-RTL mirrors stock chrome about the cell
        // width. Notifications primary 247 vs LTR 32; Alpha 315.5 =
        // 375 − 16 − 43.5; disclosure abs.x 16. Auto Layout children of
        // contentView (Forms `pinTrailingControl`) are already placed by
        // leading/trailing and must not be mirrored again.
        if _layoutIsRTL {
            func mirror(_ v: UIView, inWidth span: CGFloat) {
                var f = v.frame
                f.origin.x = span - f.maxX
                v.frame = f
            }
            var cf = contentView.frame
            cf.origin.x = w - cf.maxX
            contentView.frame = cf
            mirror(_accessoryGlyphView, inWidth: w)
            if let custom = accessoryView { mirror(custom, inWidth: w) }
            if let edit = _editControl { mirror(edit, inWidth: w) }
            if let reorder = _reorderControl { mirror(reorder, inWidth: w) }
            mirror(separatorView, inWidth: w)
            mirror(topSeparatorView, inWidth: w)
            let cw = contentView.bounds.width
            mirror(textLabel, inWidth: cw)
            if let d = detailTextLabel { mirror(d, inWidth: cw) }
            if let img = imageView, !img.isHidden { mirror(img, inWidth: cw) }
        }
    }

    open func defaultContentConfiguration() -> UIListContentConfiguration {
        switch style {
        case .subtitle: return .subtitleCell()
        case .value1, .value2: return .valueCell()
        default: return .cell()
        }
    }
}

// MARK: - Header/footer view

/// Section header/footer chrome (measured): header 40.5 pt tall, 17 pt
/// semibold secondaryLabel at y=10 (x=8 plain, x=24 inset-grouped); footer
/// 13 pt regular at y=8, wrapping. The class name matches real UIKit's so
/// compare.py treats the subtree as private on both sides.
@preconcurrency @MainActor
open class UITableViewHeaderFooterView: UIView, ReusableView {
    public static let headerHeight: CGFloat = 40.5
    static let headerLabelY: CGFloat = 10
    /// iOS: 7.667 at 3x, 7.5 at 2x (measured on both devices; the 30 pt
    /// one-line footer holds on each grid: 7.667 + 15.667 + 6.667 and
    /// 7.5 + 16 + 6.5).
    static var footerLabelY: CGFloat { UITableView.isIOSChrome ? (UIScreen.main.scale >= 3 ? 7.666667 : 7.5) : 8 }
    /// Footer height = labelY + text height + 6 (measured 30 for one line).
    static var footerBottomPadding: CGFloat { UITableView.isIOSChrome ? (UIScreen.main.scale >= 3 ? 6.666667 : 6.5) : 6 }
    /// Header label y (iOS 26: plain 4; grouped 28.667 for the first section,
    /// 18.667 after).
    var _headerLabelY: CGFloat = UITableViewHeaderFooterView.headerLabelY
    /// iOS 26 plain headers size their 17 pt semibold label to a whole 21 pt.
    var _wholePointLabelHeight = false

    public internal(set) var reuseIdentifier: String?
    public let contentView = UIView()
    public let textLabel: UILabel! = UILabel()

    public var backgroundView: UIView? {
        didSet {
            guard backgroundView !== oldValue else { return }
            oldValue?.removeFromSuperview()
            if let view = backgroundView {
                view.isUserInteractionEnabled = false
                insertSubview(view, at: 0)
            }
            setNeedsLayout()
        }
    }

    enum Kind { case header, footer }
    var kind: Kind = .header
    /// Leading x of the label (style-dependent; the table sets it).
    var labelX: CGFloat = 8

    public init(reuseIdentifier: String?) {
        self.reuseIdentifier = reuseIdentifier
        super.init(frame: .zero)
        configureContentView()
    }

    public required init?(coder: NSCoder) {
        reuseIdentifier = nil
        super.init(coder: coder)
        configureContentView()
    }

    private func configureContentView() {
        contentView.addSubview(textLabel)
        addSubview(contentView)
    }

    public override convenience init(frame: CGRect) {
        self.init(reuseIdentifier: nil)
        self.frame = frame
    }

    public convenience init() {
        self.init(reuseIdentifier: nil)
    }

    open func prepareForReuse() {
        textLabel.text = nil
        kind = .header
        labelX = 8
    }

    func configure(kind: Kind, text: String?, labelX: CGFloat,
                   style: UITableView.Style = .plain, firstSection: Bool = false,
                   compact: Bool = false) {
        self.kind = kind
        self.labelX = labelX
        if UITableView.isIOSChrome {
            switch style {
            case .plain: _headerLabelY = 4; _wholePointLabelHeight = true
            case .grouped, .insetGrouped:
                // MEASURED: 28.667 / 18.667 on the iPhone 16 (3x), 29.5 /
                // 19.5 on the iPhone SE (2x) — not one value rounded two
                // ways, so both readings are carried. Compact 38 pt
                // headers (headerprobe / NavFlow t200, SE 2x) put the
                // label at y = 12.
                let threeX = UIScreen.main.scale >= 3
                if compact {
                    _headerLabelY = 12
                } else {
                    _headerLabelY = firstSection ? (threeX ? 28.666667 : 29.5) : (threeX ? 18.666667 : 19.5)
                }
                _wholePointLabelHeight = false
            }
        } else {
            _headerLabelY = UITableViewHeaderFooterView.headerLabelY
            _wholePointLabelHeight = false
        }
        textLabel.text = text
        switch kind {
        case .header:
            textLabel.font = .systemFont(ofSize: 17, weight: .semibold)
            textLabel.numberOfLines = 1
        case .footer:
            textLabel.font = .systemFont(ofSize: 13)
            textLabel.numberOfLines = 0
        }
        textLabel.textColor = .secondaryLabel
        setNeedsLayout()
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        backgroundView?.frame = bounds
        contentView.frame = bounds
        let maxW = max(0, bounds.width - 2 * labelX)
        var s = textLabel.sizeThatFits(CGSize(width: maxW, height: CGFloat.greatestFiniteMagnitude))
        if _wholePointLabelHeight, kind == .header { s.height = textLabel.font.lineHeight.rounded(.up) }
        let y = kind == .header ? _headerLabelY
                                : UITableViewHeaderFooterView.footerLabelY
        var lf = CGRect(x: labelX, y: y,
                         width: min(s.width, maxW), height: s.height)
        // MEASURED NavFlow t200.rtl, iPhone SE 2x / iOS 26.1: "General"
        // header abs.x 281 vs LTR 32 — leading inset mirrored about the
        // header width.
        if _layoutIsRTL {
            lf.origin.x = bounds.width - lf.maxX
        }
        textLabel.frame = lf
    }
}

// Swift only permits a dynamic metatype call through a required initializer,
// unlike Objective-C's selector dispatch. These open SPI sibling classes turn
// that source-language restriction into the same initializer-vtable lookup:
// UITableView casts only the one-word class metatype, then invokes the required
// override below. Because each override occupies its base initializer's vtable
// slot, the allocator receives the original registered metatype and constructs
// that subclass, including its ordinary non-required initializer override.
//
// These classes must remain open. That prevents whole-module optimization from
// devirtualizing the constructor call which deliberately carries another class's
// metatype. They are SPI so application subclasses inherit no OpenUIKit-only
// required initializer.
@_spi(OpenUIKitInternals)
@preconcurrency @MainActor
open class _UITableViewCellDynamicConstructor: UITableViewCell {
    public required override init(style: CellStyle,
                                  reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}

@_spi(OpenUIKitInternals)
@preconcurrency @MainActor
open class _UITableViewHeaderFooterDynamicConstructor: UITableViewHeaderFooterView {
    public required override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
