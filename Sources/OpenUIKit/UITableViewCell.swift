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

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
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
            // 10.5x14 box; ink fitted to the golden chevron (2 pt stroke,
            // round caps, apex right of center).
            let color = UIColor.tertiaryLabel.resolvedCGColor(with: traitCollection)
            strokePolyline([CGPoint(x: 3.2, y: 1.1),
                            CGPoint(x: 8.0, y: 5.85),
                            CGPoint(x: 3.2, y: 10.6)],
                           width: 2, in: canvas, color: color)
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
    public static let defaultRowHeight: CGFloat = 51.5
    public static let subtitleRowHeight: CGFloat = 70.5
    static let labelX: CGFloat = 16
    static let primaryLabelY: CGFloat = 15.5
    static let subtitleDetailY: CGFloat = 36
    static let trailingMargin: CGFloat = 16
    static let disclosureSize = CGSize(width: 10.5, height: 14)
    static let checkmarkSize = CGSize(width: 19, height: 18)
    /// Checkmark trailing margin (measured 18.5, vs 16 for the chevron).
    static let checkmarkTrailingMargin: CGFloat = 18.5
    /// Content-edge gap between the content view and a checkmark accessory.
    static let checkmarkContentGap: CGFloat = 2.5
    /// value1 detail gap from the content edge when an accessory is present.
    static let detailAccessoryGap: CGFloat = 8
    static let separatorThickness: CGFloat = 1
    static let highlightFadeDuration: Double = 0.3

    /// Selection/highlight fill. Light is MEASURED (#DCDCDC,
    /// golden/tableview_selected); dark is the systemGray4-family
    /// approximation (unmeasured — no dark selected golden).
    public static let selectionColor = UIColor(dynamicProvider: { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 58.0 / 255, green: 58.0 / 255, blue: 60.0 / 255, alpha: 1)
            : UIColor(red: 220.0 / 255, green: 220.0 / 255, blue: 220.0 / 255, alpha: 1)
    })

    // MARK: State

    public let style: CellStyle
    public let reuseIdentifier: String?

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
                accessoryView.accessoryType = accessoryType
                setNeedsLayout()
            }
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
    let accessoryView = UITableCellAccessoryView()
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

    public init(style: CellStyle = .default, reuseIdentifier: String? = nil) {
        self.style = style
        self.reuseIdentifier = reuseIdentifier
        super.init(frame: CGRect(x: 0, y: 0, width: 320,
                                 height: UITableViewCell.defaultRowHeight))

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

        accessoryView.accessoryType = accessoryType
        addSubview(accessoryView)

        separatorView.backgroundColor = .separator
        separatorView.isUserInteractionEnabled = false
        addSubview(separatorView)
    }

    // MARK: Reuse

    open func prepareForReuse() {
        setSelected(false, animated: false)
        setHighlighted(false, animated: false)
        setEditing(false, animated: false)
        separatorView.isHidden = false
    }

    public func setEditing(_ editing: Bool, animated: Bool) {
        guard editing != isEditing else { return }
        isEditing = editing
        setNeedsLayout()
    }

    // MARK: Selection / highlight

    public func setSelected(_ selected: Bool, animated: Bool) {
        guard selected != isSelected else { return }
        isSelected = selected
        updateSelectionOverlay(animated: animated)
    }

    public func setHighlighted(_ highlighted: Bool, animated: Bool) {
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

    /// Width of the content region for the current accessory.
    var contentWidth: CGFloat {
        switch accessoryType {
        case .none:
            return bounds.width
        case .disclosureIndicator:
            return bounds.width - UITableViewCell.trailingMargin
                - UITableViewCell.disclosureSize.width
        case .checkmark:
            return bounds.width - UITableViewCell.checkmarkTrailingMargin
                - UITableViewCell.checkmarkSize.width
                - UITableViewCell.checkmarkContentGap
        }
    }

    /// Round up to the half-point grid (accessory centering, measured).
    private static func ceilHalf(_ v: CGFloat) -> CGFloat {
        (v * 2).rounded(.up) / 2
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        let w = bounds.width
        let h = bounds.height

        selectedBackgroundView?.frame = bounds
        contentView.frame = CGRect(x: 0, y: 0, width: contentWidth, height: h)

        // Accessory.
        switch accessoryType {
        case .none:
            accessoryView.isHidden = true
        case .disclosureIndicator:
            accessoryView.isHidden = false
            let s = UITableViewCell.disclosureSize
            accessoryView.frame = CGRect(
                x: w - UITableViewCell.trailingMargin - s.width,
                y: UITableViewCell.ceilHalf((h - s.height) / 2),
                width: s.width, height: s.height)
        case .checkmark:
            accessoryView.isHidden = false
            let s = UITableViewCell.checkmarkSize
            accessoryView.frame = CGRect(
                x: w - UITableViewCell.checkmarkTrailingMargin - s.width,
                y: UITableViewCell.ceilHalf((h - s.height) / 2),
                width: s.width, height: s.height)
        }

        // Labels.
        var labelX = UITableViewCell.labelX
        if let imageView, let image = imageView.image {
            let size = image.size
            let longestSide = max(size.width, size.height)
            let scale = longestSide > h ? h / longestSide : 1
            let fitted = CGSize(width: size.width * scale,
                                height: size.height * scale)
            imageView.isHidden = false
            imageView.frame = CGRect(x: UITableViewCell.labelX,
                                     y: (h - fitted.height) / 2,
                                     width: fitted.width,
                                     height: fitted.height)
            labelX = imageView.frame.maxX + UITableViewCell.labelX
        } else {
            imageView?.isHidden = true
        }
        let maxTextW = contentWidth - labelX - UITableViewCell.labelX
        let primary = textLabel.sizeThatFits(
            CGSize(width: CGFloat.greatestFiniteMagnitude, height: h))
        textLabel.frame = CGRect(x: labelX,
                                 y: UITableViewCell.primaryLabelY,
                                 width: min(primary.width, max(0, maxTextW)),
                                 height: primary.height)
        if let d = detailTextLabel {
            let s = d.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude,
                                          height: h))
            switch style {
            case .subtitle:
                d.frame = CGRect(x: labelX,
                                 y: UITableViewCell.subtitleDetailY,
                                 width: min(s.width, max(0, maxTextW)),
                                 height: s.height)
            default: // value1 / value2: right-aligned detail
                let right = accessoryType == .none
                    ? bounds.width - UITableViewCell.trailingMargin
                    : contentWidth - UITableViewCell.detailAccessoryGap
                d.frame = CGRect(x: right - s.width,
                                 y: UITableViewCell.primaryLabelY,
                                 width: s.width, height: s.height)
            }
        }

        // Separator: bottom-aligned; horizontal inset applied by the table.
        let inset = tableView?.separatorDrawInsets(for: self)
            ?? (left: UITableViewCell.labelX, right: 0)
        separatorView.frame = CGRect(
            x: inset.left,
            y: h - UITableViewCell.separatorThickness,
            width: max(0, w - inset.left - inset.right),
            height: UITableViewCell.separatorThickness)
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
    static let footerLabelY: CGFloat = 8
    /// Footer height = labelY + text height + 6 (measured 30 for one line).
    static let footerBottomPadding: CGFloat = 6

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
        contentView.addSubview(textLabel)
        addSubview(contentView)
    }

    public convenience override init(frame: CGRect = .zero) {
        self.init(reuseIdentifier: nil)
        self.frame = frame
    }

    open func prepareForReuse() {
        textLabel.text = nil
        kind = .header
        labelX = 8
    }

    func configure(kind: Kind, text: String?, labelX: CGFloat) {
        self.kind = kind
        self.labelX = labelX
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
        let s = textLabel.sizeThatFits(CGSize(width: maxW, height: CGFloat.greatestFiniteMagnitude))
        let y = kind == .header ? UITableViewHeaderFooterView.headerLabelY
                                : UITableViewHeaderFooterView.footerLabelY
        textLabel.frame = CGRect(x: labelX, y: y,
                                 width: min(s.width, maxW), height: s.height)
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
    public required override init(style: CellStyle = .default,
                                  reuseIdentifier: String? = nil) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
}

@_spi(OpenUIKitInternals)
@preconcurrency @MainActor
open class _UITableViewHeaderFooterDynamicConstructor: UITableViewHeaderFooterView {
    public required override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
    }
}
