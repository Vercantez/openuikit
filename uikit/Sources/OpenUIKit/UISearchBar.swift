// UISearchBar. Owner: controls module (app-compat cluster "controls2"),
// with the delegate contract from the "menus / delegate protocols" cluster.
//
// MERGE NOTE (M13 integration): two clusters built this type independently —
// controls2 measured the CHROME (everything below), menus built the DELEGATE
// contract and the UITextField bridge that makes typing actually reach an
// app. Both are kept: the geometry here is the measured one, and the
// `UISearchBarDelegate` surface is UIKit's full member list, wired through
// `Bridge` so a real touch/keystroke drives it.
//
// MEASURED (Mac Catalyst iOS 26.1, offscreen oracle — view tree, layer tree
// and the rendered ink):
//
//   * `sizeThatFits(_:)` returns (width, 44) at EVERY height (probed at
//     36/44/50/56/60/80) and `intrinsicContentSize` is (noIntrinsicMetric,
//     44).
//   * The search text field is (8, (H - 44) / 2, W - 16, 36) — fitted over
//     six heights (H = 36 -> y = -4, 44 -> 0, 50 -> 3, 56 -> 6, 60 -> 8,
//     80 -> 18) and three widths (200/320/375 all give W - 16).
//   * The magnifier image view is (12, 7.5, 20.5, 20) INSIDE the field, its
//     image 20.5 x 18.5, tinted `label`. The rendered ink is a 2 pt stroked
//     ring of outer radius 6.5 centred at (8.5, 8.5) in the image view, plus
//     a 2 pt handle running at 45 degrees from the ring to (17.5, 17.5) —
//     read off the golden ink at 2x, where the ring spans exactly 13 x 13 pt
//     and every stroke is 4 device pixels wide.
//   * The placeholder label is at (39.5, 8, ..., 20.5) in the field —
//     7 pt after the magnifier — in **system MEDIUM 17**, not regular, and
//     its colour resolves to black at alpha 0.25 (light) / white at alpha
//     0.25 (dark). The field's own font is the same medium 17.
//   * The clear button (present only with text) is (269.5, 7.5, 20.5, 20.5)
//     in a 304 pt field, i.e. 14 pt in from the field's trailing edge.
//   * The editable text starts at x 39.5 in the field, same as the
//     placeholder.
//
// NOT MEASURABLE OFFSCREEN, and therefore NOT GOLDENED — this control has no
// fixture scene, deliberately:
//
//   * **The field's pill does not composite.** `searchTextField.backgroundColor`
//     is nil, its layer's `backgroundColor` is nil and `cornerRadius` is 0
//     with `cornerCurve = .continuous`; the visible rounded fill is a private
//     material that `layer.render(in:)` draws as NOTHING (the capture is
//     transparent everywhere except the magnifier and the placeholder ink).
//     Same limitation as the tab-bar platter, the sheet grabber and the dark
//     text-field border (docs/KNOWN_GAPS.md). `fieldFill` and
//     `fieldCornerRadius` below are therefore INFERRED, not measured:
//     `tertiarySystemFill` is iOS's documented search-field material and
//     10 pt reads as the iOS rounded rect. A pixel golden needs the WINDOWED
//     oracle (`Tools/oracle2`), which needs an active display session.
//   * **The cancel button never appears offscreen.** `showsCancelButton = true`
//     followed by a layout pass leaves the view tree unchanged — UIKit builds
//     the button lazily in a real window. Everything about it here (a 17 pt
//     regular "Cancel" in the tint colour, 8 pt from the trailing edge, the
//     field shrinking to make room) is UIKit's documented shape, NOT a
//     measurement.
//   * `searchBarStyle`, `barTintColor`, scope bars, bookmark/results buttons
//     and the search-results-controller integration are not implemented.
//     `.minimal` is honoured to the extent that it suppresses the pill.
//
// REAL iOS 26.1 (iPhone 16 @3x in a window — fixtures `searchbar_placeholder`
// and `searchbar_text_clear`, plus /tmp/probe_sb_{geom,fill,dark}.json,
// measured 2026-09-04). The windowed oracle the Catalyst run could not reach
// (the pill DOES composite here) contradicts four of the numbers above, so
// every one of them is guarded by the iOS cut in `_UISearchFieldMetrics`:
//
//   * The field is **44 pt tall**, not 36 — it fills the bar's standard
//     height. Probed at bar heights 30/36/40/44/50/56/60/80: the field frame
//     is (8, (H - 44) / 2, W - 16, 44) at every one of them (y = -7/-4/-2/0/
//     3/6/8/18), so only the HEIGHT differs from the Catalyst measurement.
//     Widths 200/320/375/393 all give W - 16.
//   * The pill is a **capsule** — a circular-corner fit to the golden's own
//     left edge over a black backdrop gives r = 21.75 (rms 0.175 pt) for a
//     44 pt field, i.e. height / 2, not the 10 pt inferred offscreen.
//   * The pill fill is a glass material. Its FLAT equivalent, read at the
//     field's centre over eight backdrops (white / black / #808080 / #404040
//     / #C0C0C0 / red / green / blue): light mode 252-253 on every one of
//     them, dark mode 19-21. Modelled as the measured (253, 253, 253) /
//     (19, 19, 19) — the same "flat equivalent of a glass platter" divergence
//     `_UIBarMetrics.platterFill` carries (docs/KNOWN_GAPS.md): over a
//     saturated backdrop the real material tints toward the backdrop hue by
//     up to 6 counts and ours does not.
//   * The magnifier, the placeholder and the clear glyph all draw in
//     **`secondaryLabel`**, not `label` / black-at-0.25: their darkest ink is
//     (137, 137, 141) in light mode, which is exactly (60, 60, 67) at alpha
//     0.6 over the (253, 253, 253) pill, and (149, 149, 155) in dark, which
//     is (235, 235, 245) at 0.6 over (19, 19, 19). Typed text stays `label`
//     (golden ink 0 / 255).
//   * The clear button is present with text and NO first responder, at
//     (W - 34.333, 11.667, 20, 20) in the field (probed at field widths 359
//     and 377), and its filled circle is 17 pt across, centred in that box.
//
// STILL NOT MODELLED (open questions, measured but not reproduced):
//   * `UISearchBarBackground` is a glass material of its own — over a black
//     backdrop the bar's own rect reads 237-242, over white 247-250. Over the
//     backdrops the fixtures use (systemBackground) it is within 2 counts of
//     the backdrop, so nothing is drawn for it here.
//   * The field's drop shadow: the backdrop just above the bar reads 0.985x
//     and just below 0.962x its own value (identical ratios over white / 191
//     / 127 / 63, i.e. a black shadow at low alpha), fading out over ~25 pt.
//     Not fitted yet.

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


/// UIKit's protocol, member for member. Everything is defaulted, so a
/// conformance implements only what it uses.
@preconcurrency @MainActor
public protocol UISearchBarDelegate: AnyObject {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String)
    func searchBar(_ searchBar: UISearchBar, shouldChangeTextIn range: NSRange,
                   replacementText text: String) -> Bool
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar)
    func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar)
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar)
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar)
    func searchBarBookmarkButtonClicked(_ searchBar: UISearchBar)
    func searchBarResultsListButtonClicked(_ searchBar: UISearchBar)
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int)
}

extension UISearchBarDelegate {
    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {}
    public func searchBar(_ searchBar: UISearchBar, shouldChangeTextIn range: NSRange,
                          replacementText text: String) -> Bool { true }
    public func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool { true }
    public func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {}
    public func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool { true }
    public func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {}
    public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {}
    public func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {}
    public func searchBarBookmarkButtonClicked(_ searchBar: UISearchBar) {}
    public func searchBarResultsListButtonClicked(_ searchBar: UISearchBar) {}
    public func searchBar(_ searchBar: UISearchBar,
                          selectedScopeButtonIndexDidChange selectedScope: Int) {}
}

public enum UISearchBarStyle: Int, Sendable {
    case `default` = 0
    case prominent = 1
    case minimal = 2
}

/// Everything the windowed iOS 26.1 oracle measured about the search field
/// that the Catalyst offscreen oracle could not (file header). Every member
/// falls back to the Catalyst number off the iOS cut, so the macOS goldens
/// are untouched.
@preconcurrency @MainActor
enum _UISearchFieldMetrics {
    static var isIOS: Bool { OpenUIKitRuntime.systemFontCut == .iOS }
    static var pixel: CGFloat { 1 / max(1, UIScreen.main.scale) }
    static func ceilToPixel(_ v: CGFloat) -> CGFloat { (v / pixel).rounded(.up) * pixel }
    static func floorToPixel(_ v: CGFloat) -> CGFloat { (v / pixel).rounded(.down) * pixel }

    /// Field height: 44 on iOS (probed at eight bar heights), 36 on Catalyst.
    static var fieldHeight: CGFloat { isIOS ? 44 : 36 }

    /// MEASURED Tabs t4000.ax1 / Notes t4000.ax1, iPhone SE 2x / iOS 26.1:
    /// field **80** = `UIFontMetrics.body.scaledValue(44)` at ax1 (table hit).
    /// `.large` stays 44. Catalyst stays `fieldHeight`.
    static func scaledFieldHeight(compatibleWith traits: UITraitCollection) -> CGFloat {
        guard isIOS else { return fieldHeight }
        return UIFontMetrics(forTextStyle: .body).scaledValue(for: 44, compatibleWith: traits)
    }

    /// Flat equivalent of the pill's glass material (file header): the
    /// measured centre reading over eight backdrops.
    static let pillFill = UIColor(.dynamic { t in
        t.userInterfaceStyle == .dark
            ? CGColor(red: 19 / 255, green: 19 / 255, blue: 19 / 255, alpha: 1)
            : CGColor(red: 253 / 255, green: 253 / 255, blue: 253 / 255, alpha: 1)
    })

    /// Magnifier / placeholder / clear-glyph ink.
    static var glyphColor: UIColor { isIOS ? .secondaryLabel : .label }

    /// The magnifier's box inside the field: MEASURED (12, 12, 20.667,
    /// 19.333) at 3x in the 44 pt field, against Catalyst's (12, 7.5, 20.5,
    /// 20) in the 36 pt one.
    static var iconFrame: CGRect {
        isIOS
            ? CGRect(x: 12, y: 12, width: 20.667, height: 19.333)
            : CGRect(x: 12, y: 7.5, width: 20.5, height: 20)
    }
    /// The magnifier vector, in icon-box coordinates. The iOS numbers come
    /// off the golden's own ink (`searchbar_placeholder` at 3x): the ring's
    /// outer edge spans x 22.0 … 35.333 and y 41.333 … 54.667 in scene
    /// points, i.e. centre (8.833, 8.0) in the box with outer radius 6.667,
    /// and the handle runs to (18.0, 17.667). Every stroke is 6 device
    /// pixels = 2 pt wide, as on Catalyst.
    static var ringCenter: CGPoint {
        isIOS ? CGPoint(x: 8.833, y: 8) : CGPoint(x: 8.5, y: 8.5)
    }
    static var ringOuterRadius: CGFloat { isIOS ? 6.667 : 6.5 }
    static var handleEnd: CGPoint {
        isIOS ? CGPoint(x: 18, y: 17.667) : CGPoint(x: 17.5, y: 17.5)
    }

    /// Text/placeholder left inset. Both oracles put it 7 pt after the
    /// magnifier, and the magnifier's width is the symbol rounded to the
    /// DEVICE pixel — 39.5 exactly at 2x, 39.667 at 3x — so the Catalyst
    /// number ceiled to the pixel grid reproduces both.
    static var textLeftInset: CGFloat { isIOS ? ceilToPixel(39.5) : 39.5 }

    /// Clear button box in the field: MEASURED (W - 34.333, 11.667, 20, 20)
    /// at 3x in fields 359 and 377 wide (`searchbar_text_clear` and
    /// probe_sb_geom). Catalyst measured the same 34.5 pt trailing edge at
    /// 2x, so the inset is that value floored to the device pixel. The
    /// 11.667 top centres the box on 21.667 — the field's 22 pt mid-line one
    /// device pixel up, the same mid-line the magnifier's 19.333-tall image
    /// sits on.
    static var clearSize: CGFloat { isIOS ? 20 : 20.5 }
    static var clearTrailingInset: CGFloat { isIOS ? floorToPixel(34.5) : 34.5 }
    static var clearTop: CGFloat {
        isIOS ? floorToPixel(fieldHeight / 2) - pixel - clearSize / 2 : 7.5
    }
    /// Gap the text box keeps clear of the button: the golden's text canvas
    /// ends at 333 in a 377 pt field, 9.667 before the button.
    static var clearTextGap: CGFloat { isIOS ? ceilToPixel(9.5) : 0 }
    /// The filled circle is 17 pt across inside the 20 pt box (measured: the
    /// glyph spans y 41.167 … 58.167 of a box at 39.667), and the knocked-out
    /// cross runs 7 pt tip to tip inside it (the golden's arms break the disc
    /// from y 46.2 to 53.3).
    static let clearCircleDiameter: CGFloat = 17
    static let clearCrossSpan: CGFloat = 7

    /// The pill's drop shadow. Least-squares fit of (opacity, sigma, dy) to
    /// the `searchbar_placeholder` golden's own falloff everywhere outside
    /// the capsule (`python3 /tmp/fit_search_shadow.py`, the search-field
    /// twin of Tools/compare/fit_bar_shadow.py): rms residual 1.09 counts
    /// over the whole 393 x 100 scene. It is a plain black shadow — the
    /// backdrop reads 0.985x its own value just above the bar and 0.962x
    /// just below, the same two ratios over white, 191, 127 and 63.
    static let shadowOpacity: Float = 0.07
    static let shadowRadius: CGFloat = 16
    static let shadowOffset = CGSize(width: 0, height: 7.5)
}

/// The search bar's text field. UIKit exposes the same class name and it is
/// an ordinary `UITextField` there too; the magnifier is drawn by this
/// subclass rather than by a separate image view, because OpenUIKit has no
/// SF Symbols to load one from (the geometry is the measured one).
@preconcurrency @MainActor
open class UISearchTextField: UITextField {
    /// Measured icon frame inside the field (per cut — `_UISearchFieldMetrics`).
    public static var iconFrame: CGRect { _UISearchFieldMetrics.iconFrame }
    /// Measured ring: centre (8.5, 8.5) in the icon box, outer radius 6.5,
    /// 2 pt stroke; the handle ends at (17.5, 17.5). iOS 26 draws the same
    /// vector a third of a point wider and half a point higher.
    static var ringCenter: CGPoint { _UISearchFieldMetrics.ringCenter }
    static var ringOuterRadius: CGFloat { _UISearchFieldMetrics.ringOuterRadius }
    static let strokeWidth: CGFloat = 2
    static var handleEnd: CGPoint { _UISearchFieldMetrics.handleEnd }
    /// Measured: the placeholder and the text both start 39.5 pt in.
    public static var textLeftInset: CGFloat { _UISearchFieldMetrics.textLeftInset }
    /// Measured: 14 pt from the field's trailing edge to the clear button,
    /// which is itself 20.5 pt wide.
    public static var clearButtonInset: CGFloat {
        _UISearchFieldMetrics.clearTrailingInset - _UISearchFieldMetrics.clearSize
    }
    public static var clearButtonWidth: CGFloat { _UISearchFieldMetrics.clearSize }
    /// Inferred, NOT measured, on Catalyst (file header); on iOS the pill is
    /// a capsule fitted to the golden's own edge.
    public static let fieldCornerRadius: CGFloat = 10

    /// Whether the private material pill is drawn. `false` reproduces what
    /// the offscreen oracle captures (nothing) and what `.minimal` looks
    /// like.
    var drawsFieldBackground = true
    weak var _searchBar: UISearchBar?

    /// Measured text box: 39.5 pt in from the left, and 14 + 20.5 pt in from
    /// the right once a clear button is present (iOS: 34.333 + a 9.667 pt
    /// gap, so the canvas ends at 333 in a 377 pt field).
    public override func textRect(forBounds bounds: CGRect) -> CGRect {
        let right = (text ?? "").isEmpty ? 0
            : _UISearchFieldMetrics.clearTrailingInset + _UISearchFieldMetrics.clearTextGap
        let left = UISearchTextField.textLeftInset
        return CGRect(x: bounds.minX + left, y: bounds.minY,
                      width: max(0, bounds.width - left - right),
                      height: bounds.height)
    }

    /// MEASURED (iOS 26.1, `searchbar_placeholder` at 3x): the placeholder's
    /// darkest ink is (137, 137, 141) on the (253, 253, 253) pill, i.e.
    /// `secondaryLabel` — (60, 60, 67) at alpha 0.6, twice the alpha of
    /// `placeholderText`, which is what a plain field uses and what this
    /// field drew before (ink 195 where the golden has 137).
    override var defaultPlaceholderColor: UIColor {
        _UISearchFieldMetrics.isIOS ? .secondaryLabel : super.defaultPlaceholderColor
    }

    /// Measured clear-button box (`_UISearchFieldMetrics.clear*`); UITextField's
    /// own hook is the plain-field geometry and does not apply here.
    public override func clearButtonRect(forBounds bounds: CGRect) -> CGRect {
        let size = _UISearchFieldMetrics.clearSize
        return CGRect(x: bounds.maxX - _UISearchFieldMetrics.clearTrailingInset,
                      y: bounds.minY + _UISearchFieldMetrics.clearTop,
                      width: size, height: size)
    }

    /// The search field's clear glyph is `secondaryLabel` on the pill, not
    /// `tertiaryLabel` on `systemBackground` (measured ink (137, 137, 141)
    /// light / (149, 149, 155) dark — file header).
    override var clearButtonPalette: (circle: UIColor, knockout: UIColor) {
        _UISearchFieldMetrics.isIOS
            ? (_UISearchFieldMetrics.glyphColor, _UISearchFieldMetrics.pillFill)
            : super.clearButtonPalette
    }

    /// Measured: the filled circle is 17 pt across inside the 20 pt box.
    override var clearButtonCircleDiameter: CGFloat {
        _UISearchFieldMetrics.isIOS
            ? _UISearchFieldMetrics.clearCircleDiameter : super.clearButtonCircleDiameter
    }

    override var clearButtonCrossSpan: CGFloat {
        _UISearchFieldMetrics.isIOS
            ? _UISearchFieldMetrics.clearCrossSpan : super.clearButtonCrossSpan
    }

    /// iOS draws the pill as a real layer (capsule corner radius + fill)
    /// rather than as ink, because the measured drop shadow is cast by the
    /// layer's silhouette — the same shape `_UIBarMetrics` gives a bar
    /// platter. Catalyst keeps the ink-only pill it was measured with.
    public override func layoutSubviews() {
        super.layoutSubviews()
        guard _UISearchFieldMetrics.isIOS else { return }
        let visible = drawsFieldBackground
        layer.cornerRadius = visible ? bounds.height / 2 : 0
        backgroundColor = visible ? _UISearchFieldMetrics.pillFill : nil
        layer.shadowColor = visible ? CGColor(red: 0, green: 0, blue: 0, alpha: 1) : nil
        layer.shadowOpacity = visible ? _UISearchFieldMetrics.shadowOpacity : 0
        layer.shadowRadius = _UISearchFieldMetrics.shadowRadius
        layer.shadowOffset = _UISearchFieldMetrics.shadowOffset
    }

    public override func drawContent(in canvas: Canvas, bounds: CGRect) {
        if drawsFieldBackground, !_UISearchFieldMetrics.isIOS {
            let fill = UIColor.tertiarySystemFill.resolvedCGColor(with: traitCollection)
            canvas.fill(Path.roundedRect(bounds,
                                         cornerRadius: UISearchTextField.fieldCornerRadius),
                        color: fill)
        }
        drawMagnifier(in: canvas, bounds: bounds)
        super.drawContent(in: canvas, bounds: bounds)
    }

    private func drawMagnifier(in canvas: Canvas, bounds: CGRect) {
        let box = UISearchTextField.iconFrame.offsetBy(dx: bounds.minX, dy: bounds.minY)
        let c = CGPoint(x: box.minX + UISearchTextField.ringCenter.x,
                        y: box.minY + UISearchTextField.ringCenter.y)
        let color = (_tintColor ?? _UISearchFieldMetrics.glyphColor)
            .resolvedCGColor(with: traitCollection)
        let w = UISearchTextField.strokeWidth
        let mid = UISearchTextField.ringOuterRadius - w / 2
        // A square with cornerRadius == half its side IS a circle in Path.
        let ring = Path.roundedRect(CGRect(x: c.x - mid, y: c.y - mid,
                                           width: mid * 2, height: mid * 2),
                                    cornerRadius: mid)
        canvas.stroke(ring, color: color, lineWidth: w)
        let end = CGPoint(x: box.minX + UISearchTextField.handleEnd.x,
                          y: box.minY + UISearchTextField.handleEnd.y)
        let k = mid / (2 as CGFloat).squareRoot()
        var handle = Path()
        handle.move(to: CGPoint(x: c.x + k, y: c.y + k))
        handle.addLine(to: end)
        canvas.stroke(handle, color: color, lineWidth: w)
    }
}

@preconcurrency @MainActor
open class UISearchBar: UIView {
    /// Measured: 44 pt tall whatever the frame says.
    public static let standardHeight: CGFloat = 44
    /// Measured: the field is inset 8 pt on each side and 36 pt tall on
    /// Catalyst, 44 (the bar's whole standard height) on iOS 26.
    public static let fieldSideInset: CGFloat = 8
    public static var fieldHeight: CGFloat { _UISearchFieldMetrics.fieldHeight }
    /// NOT measured (file header): the cancel button's metrics.
    public static let cancelButtonFontSize: CGFloat = 17
    public static let cancelButtonGap: CGFloat = 8
    /// MEASURED Tabs t4000, iPhone SE 2x / iOS 26.1: inline-nav search
    /// (isActive) uses 16 pt side inset, a 44×44 dismiss at trailing 16,
    /// 11 pt gap to the field, field y 8 in a 60 pt bar. Not the
    /// standalone "Cancel" text button.
    static let navInlineSideInset: CGFloat = 16
    static let navInlineFieldY: CGFloat = 8
    static let navInlineDismissSize: CGFloat = 44
    static let navInlineDismissRadius: CGFloat = 17
    static let navInlineDismissGap: CGFloat = 11

    public weak var delegate: UISearchBarDelegate?

    public let searchTextField = UISearchTextField()
    private var cancelButton: UIButton?
    /// Set by UINavigationBar when this bar is the active inline-nav search.
    var _navInlineActive = false
    /// Set by UINavigationBar when this bar is the inactive slot below the
    /// 54 pt content (Notes t6000 / Tabs t6000).
    var _navInactiveSlot = false
    /// Set by UINavigationBar on pad: the field fills the 240/280 × 44
    /// trailing chrome (Tabs-ipad t200 / t4000: UISearchBarTextField
    /// frame equals the search bar).
    var _padTrailingChrome = false

    public var text: String? {
        get { searchTextField.text }
        set {
            searchTextField.text = newValue ?? ""
            setNeedsLayout()
            setNeedsDisplay()
        }
    }

    public var placeholder: String? {
        get { searchTextField.placeholder }
        set { searchTextField.placeholder = newValue; setNeedsDisplay() }
    }

    public var searchBarStyle: UISearchBarStyle = .default {
        didSet {
            searchTextField.drawsFieldBackground = searchBarStyle != .minimal
            // The iOS pill is a layer, not ink: it needs a layout pass too.
            searchTextField.setNeedsLayout()
            searchTextField.setNeedsDisplay()
        }
    }

    public var showsCancelButton: Bool = false {
        didSet { if showsCancelButton != oldValue { setNeedsLayout() } }
    }

    public func setShowsCancelButton(_ shows: Bool, animated: Bool) {
        showsCancelButton = shows
    }

    /// Stored for source compatibility; no scope bar is drawn.
    public var scopeButtonTitles: [String]?
    public var selectedScopeIndex: Int = 0 {
        didSet {
            guard selectedScopeIndex != oldValue else { return }
            delegate?.searchBar(self, selectedScopeButtonIndexDidChange: selectedScopeIndex)
        }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        configureSearchField()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureSearchField()
    }

    private func configureSearchField() {
        // Measured: the field's font is system MEDIUM 17, not regular.
        searchTextField.font = .systemFont(ofSize: 17, weight: .medium)
        // The placeholder colour lives on `UISearchTextField`'s
        // `defaultPlaceholderColor` override, not here: the label's own
        // `textColor` is rewritten by `UITextField.refreshContent()` on every
        // content change, so an assignment at this point never survived (the
        // Catalyst black-at-0.25 in the file header was measured but has
        // never actually been drawn — the field has always used the
        // `placeholderText` a plain field uses).
        // Real UIKit shows the clear glyph whenever the field has text, with
        // or without a first responder (measured: `searchbar_text_clear` is
        // captured with no keyboard and the button is there).
        searchTextField.clearButtonMode = .always
        searchTextField._searchBar = self
        // MEASURED kbstateprobe search_empty, iPhone SE 2x / iOS 26.1:
        // searchTextField.returnKeyType .search (6), autocorrectionType
        // .no (1). Tabs t5000 search-return is a blue magnifying glass.
        searchTextField.returnKeyType = .search
        searchTextField.autocorrectionType = .no
        // Delegate plumbing (menus cluster): the field's own delegate is a
        // private bridge, so an app's `searchBar.delegate` can never be
        // confused with a UITextFieldDelegate.
        bridge.owner = self
        searchTextField.delegate = bridge
        // textDidChange follows the field's .editingChanged event, not the
        // selection callback — a caret move is not a text change.
        searchTextField.addTarget(for: .editingChanged) { [weak self] _, _ in
            self?._textDidChange()
        }
        addSubview(searchTextField)
    }

    /// MEASURED Tabs t4000.ax1 / Notes t4000.ax1: placeholder
    /// `UISearchBarTextFieldLabel` is **33 pt Medium** = body preferred size
    /// at ax1, weight medium. `.large` stays 17 medium.
    private func applyIOSDynamicTypeFieldFont() {
        guard OpenUIKitRuntime.systemFontCut == .iOS else { return }
        let size = UIFont.preferredFont(forTextStyle: .body,
                                        compatibleWith: traitCollection).pointSize
        searchTextField.font = .systemFont(ofSize: size, weight: .medium)
    }

    @discardableResult
    open override func becomeFirstResponder() -> Bool {
        searchTextField.becomeFirstResponder()
    }

    @discardableResult
    open override func resignFirstResponder() -> Bool {
        searchTextField.resignFirstResponder()
    }

    open override var canBecomeFirstResponder: Bool { false }

    open override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: UISearchBar.standardHeight)
    }

    open override func sizeThatFits(_ size: CGSize) -> CGSize {
        CGSize(width: size.width, height: UISearchBar.standardHeight)
    }

    /// Measured: standalone (8, (H - 44) / 2, W - 16, 36/44); inline-nav
    /// active (Tabs t4000): field (16, 8, 288, 44) and dismiss (315, 8, 44, 44).
    open override func layoutSubviews() {
        super.layoutSubviews()
        applyIOSDynamicTypeFieldFont()
        if bounds.height < 1 {
            searchTextField.isHidden = true
            cancelButton?.isHidden = true
            return
        }
        searchTextField.isHidden = false
        if _padTrailingChrome {
            cancelButton?.isHidden = true
            searchTextField.frame = bounds
            return
        }
        if _navInlineActive {
            layoutNavInline()
            return
        }
        if _navInactiveSlot {
            layoutNavInactiveSlot()
            return
        }
        let fieldH = _UISearchFieldMetrics.scaledFieldHeight(compatibleWith: traitCollection)
        let y = (bounds.height - fieldH) / 2
        var right = bounds.width - UISearchBar.fieldSideInset
        if showsCancelButton {
            let b = cancelButton ?? makeCancelButton()
            b.isHidden = false
            applyStandaloneCancelChrome(b)
            let w = b.sizeThatFits(bounds.size).width
            b.frame = CGRect(x: bounds.width - UISearchBar.fieldSideInset - w,
                             y: y, width: w, height: fieldH)
            right -= w + UISearchBar.cancelButtonGap
        } else {
            cancelButton?.isHidden = true
        }
        searchTextField.frame = CGRect(x: UISearchBar.fieldSideInset, y: y,
                                       width: max(0, right - UISearchBar.fieldSideInset),
                                       height: fieldH)
    }

    /// MEASURED Notes t6000 / Tabs t6000, iPhone SE 2x / iOS 26.1:
    /// inactive slot field `[16, 1, 343, 44]` in a 60 pt bar (16 = SE
    /// system margin; landscape Notes t6000 `[20, 1, 627, 44]` in 667).
    /// ax1 field `[16, 1, 343, 80]` in the 96 pt slot. No dismiss.
    func layoutNavInactiveSlot() {
        cancelButton?.isHidden = true
        let fieldH = _UISearchFieldMetrics.scaledFieldHeight(compatibleWith: traitCollection)
        let side = UITableView.iOSSystemMargin(width: bounds.width)
        searchTextField.frame = CGRect(x: side, y: 1,
                                         width: max(0, bounds.width - 2 * side),
                                         height: fieldH)
    }

    func layoutNavInline() {
        let side = UISearchBar.navInlineSideInset
        let d = _UISearchFieldMetrics.scaledFieldHeight(compatibleWith: traitCollection)
        let gap = UISearchBar.navInlineDismissGap
        let y = UISearchBar.navInlineFieldY
        let b = cancelButton ?? makeCancelButton()
        b.isHidden = false
        applyNavInlineCancelChrome(b)
        let fieldW = max(0, bounds.width - side - d - gap - side)
        // MEASURED Tabs t4000.rtl, iPhone SE 2x / iOS 26.1: dismiss is on
        // the trailing (left) edge — field abs [71, 18, 288, 44] =
        // 16 + 44 + 11, not LTR's [16, 18, 288, 44] with dismiss at 315.
        // Field internals stay physical (placeholder at field-x + 39.5 =
        // 110.5). MEASURED Tabs t4000.ax1 / Notes t4000.ax1: field height
        // `d` = `scaledFieldHeight` (80 at ax1, 44 at `.large`).
        if _layoutIsRTL {
            b.frame = CGRect(x: side, y: y, width: d, height: d)
            searchTextField.frame = CGRect(x: side + d + gap, y: y, width: fieldW,
                                           height: d)
        } else {
            b.frame = CGRect(x: bounds.width - side - d, y: y, width: d, height: d)
            searchTextField.frame = CGRect(x: side, y: y, width: fieldW,
                                           height: d)
        }
    }

    func applyStandaloneCancelChrome(_ b: UIButton) {
        b.setTitle("Cancel", for: .normal)
        b.setImage(nil, for: .normal)
        b.backgroundColor = nil
        b.layer.cornerRadius = 0
        b.titleLabel?.font = .systemFont(ofSize: UISearchBar.cancelButtonFontSize)
    }

    func applyNavInlineCancelChrome(_ b: UIButton) {
        // Tabs t4000: UIButton `[315, 18, 44, 44]` with an empty title and
        // a 22.5×21.5 image view (not the word "Cancel", not a "×" label —
        // golden has 0 of both). Portable SF subset includes `multiply`.
        b.setTitle(nil, for: .normal)
        b.setImage(UIImage(systemName: "multiply"), for: .normal)
        b.tintColor = .label
        b.backgroundColor = _UISearchFieldMetrics.pillFill
        b.layer.cornerRadius = UISearchBar.navInlineDismissRadius
        b.clipsToBounds = true
    }

    private func makeCancelButton() -> UIButton {
        let b = UIButton(type: .system)
        b.setTitle("Cancel", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: UISearchBar.cancelButtonFontSize)
        b.addTarget(for: .touchUpInside) { [weak self] _, _ in
            self?._cancel()
        }
        addSubview(b)
        cancelButton = b
        return b
    }

    // MARK: Delegate plumbing

    /// Called by the field when its text changes (the field routes editing
    /// through the M8 text-input path; the search bar only forwards).
    func _textDidChange() {
        delegate?.searchBar(self, textDidChange: searchTextField.text ?? "")
        setNeedsLayout()
    }

    func _shouldBeginEditing() -> Bool { delegate?.searchBarShouldBeginEditing(self) ?? true }
    func _didBeginEditing() { delegate?.searchBarTextDidBeginEditing(self) }
    func _shouldEndEditing() -> Bool { delegate?.searchBarShouldEndEditing(self) ?? true }
    func _didEndEditing() { delegate?.searchBarTextDidEndEditing(self) }
    func _searchButtonClicked() { delegate?.searchBarSearchButtonClicked(self) }

    /// The bar's own "the user tapped Cancel" entry point — also what the
    /// cancel button, when one is shown, is wired to. UIKit's callback order:
    /// the text clears, the change is reported, then the cancel click.
    public func _cancel() {
        text = ""
        delegate?.searchBar(self, textDidChange: "")
        delegate?.searchBarCancelButtonClicked(self)
        resignFirstResponder()
    }

    /// Translates UITextField's delegate into UISearchBar's.
    @MainActor
    final class Bridge: UITextFieldDelegate {
        weak var owner: UISearchBar?

        func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
            owner?._shouldBeginEditing() ?? true
        }
        func textFieldDidBeginEditing(_ textField: UITextField) {
            owner?._didBeginEditing()
        }
        func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
            owner?._shouldEndEditing() ?? true
        }
        func textFieldDidEndEditing(_ textField: UITextField) {
            owner?._didEndEditing()
        }
        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange,
                       replacementString string: String) -> Bool {
            guard let o = owner else { return true }
            return o.delegate?.searchBar(o, shouldChangeTextIn: range,
                                         replacementText: string) ?? true
        }
        /// The keyboard's return key IS the search button.
        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            owner?._searchButtonClicked()
            return true
        }
    }
    let bridge = Bridge()
}
