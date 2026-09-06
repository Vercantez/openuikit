// The MENU PLATTER + UIContextMenuInteraction / UIContextMenuConfiguration.
// Owner: menus module (M13 "menus & actions" cluster).
//
// ============================ HOW THIS WAS MEASURED ======================
//
// `Tools/oracle2/menuprobe` (scripts/menu_probe_sim.sh) presents a REAL
// UIMenu from a real UIButton in the headless iPhone-16 simulator (iOS 26.1)
// and dumps every window's private view tree in screen coordinates plus a
// snapshot per window. Seventeen configurations: 1/2/3 items, a menu title,
// leading images, check state, subtitles, a disabled item, a submenu, an
// inline section, a wrapping title, and the same menu over six known base
// colours in both appearances. Mac Catalyst is useless here — it turns a
// UIMenu into an AppKit NSMenu.
//
// ============================ THE HONEST DIVERGENCE ======================
//
// **There is no fixture scene for the menu, and there cannot be one today.**
// iOS 26 draws the menu platter ENTIRELY in the render server: the tree
// dumps at full geometry, but `drawHierarchy(afterScreenUpdates: true)` —
// the capture both Mac oracles and the SimScene renderer use — comes back
// with the platter MISSING (verified: three settle times, identical blank
// captures; only the "magic morph" placeholder appears). The platter is
// visible only in the device FRAMEBUFFER (`xcrun simctl io screenshot`),
// which also carries SpringBoard's Dynamic Island and runs at the device's
// 3× scale — not a golden any scene renderer can be compared against.
//
// So the geometry below (frames, insets, row heights, fonts, colours) is
// measured from the view-tree dumps and is exact; the platter's FILL, CORNER
// RADIUS and SHADOW are solved from framebuffer pixels and are quoted with
// their residuals; and no pixel gate protects any of it. Recorded in
// docs/KNOWN_GAPS.md. Two further divergences are known and deliberate:
//
//   - **No SF Symbols.** Real iOS draws `checkmark` and `chevron.right` in
//     the leading/trailing columns. Those columns are reserved at exactly the
//     measured widths, but the glyphs are drawn as strokes here.
//   - **No blur.** Like every other platter in this project the fill is a
//     flat colour at alpha (fitted below), so a strongly patterned backdrop
//     shows through flat instead of smeared (docs/KNOWN_GAPS.md).
//
// ============================ WHAT UIKIT DRAWS ===========================
//
// Anchoring: the platter's top-left sits on the SOURCE VIEW's top-left
// (measured at one anchor — a 100×44 button at (40, 120) produced a platter
// at (40, 120)), clamped into the window. Real UIKit also flips the platter
// above/beside the source when it would not fit; the clamp is our stand-in
// and is not measured.

// MARK: - Measured metrics

/// Every constant here comes from `Tools/oracle2/menuprobe` dumps unless it
/// says otherwise. Sizes are points on a 393-pt-wide window.
@preconcurrency @MainActor
public enum UIMenuMetrics {
    /// Platter width. CONSTANT across every probed configuration — a long
    /// title WRAPS rather than widening the platter (measured).
    public static let platterWidth: CGFloat = 250
    /// Padding above the first row and below the last.
    public static let platterPadding: CGFloat = 10

    /// Row = label box + this. MEASURED: a one-line row is 42 (20.333 +
    /// 21.667) and a two-line row is 64 (42.333 + 21.667).
    public static let rowPaddingV: CGFloat = 21.0 + 2.0 / 3.0
    /// Label top inset inside a row (the remaining 11 sits below it).
    public static let rowLabelTop: CGFloat = 10.0 + 2.0 / 3.0

    /// Title line box and wrapped-line pitch, measured off the menu's own
    /// labels (the device lays out on a 1/3 pt grid, so a 17 pt line box is
    /// 20.333 where the general-purpose font engine rounds to 20 — the same
    /// discrepancy the alert documents).
    public static let titleLineHeight: CGFloat = 20.0 + 1.0 / 3.0
    public static let titleLinePitch: CGFloat = 22
    /// Subtitle line box, its gap under the title, and the row's bottom pad
    /// in a subtitled row (measured: 10.667 + 20.333 + 0.667 + 15.667 +
    /// 10.667 = 58).
    public static let subtitleLineHeight: CGFloat = 15.0 + 2.0 / 3.0
    public static let subtitleGap: CGFloat = 2.0 / 3.0
    public static let subtitleRowBottom: CGFloat = 10.0 + 2.0 / 3.0

    /// Leading inset of the title column: plain, with a check column, with
    /// an image column (measured 28 / 40 / 60). Trailing inset is always 28.
    public static let titleInsetPlain: CGFloat = 28
    public static let titleInsetChecked: CGFloat = 40
    public static let titleInsetImage: CGFloat = 60
    public static let titleInsetTrailing: CGFloat = 28

    /// Centres of the decoration columns, from the platter's leading edge
    /// (check) and its trailing edge (submenu chevron), both measured.
    public static let checkCenterX: CGFloat = 20
    public static let imageCenterX: CGFloat = 36.0 + 1.0 / 6.0
    public static let chevronCenterFromTrailing: CGFloat = 31
    /// Measured glyph boxes (SF Symbols in real UIKit — see the header).
    public static let checkSize = CGSize(width: 13.0 + 1.0 / 3.0, height: 12.0 + 1.0 / 3.0)
    public static let chevronSize = CGSize(width: 9.0 + 1.0 / 3.0, height: 12.0 + 2.0 / 3.0)
    /// Leading image column: images sit centred on `imageCenterX` in a box
    /// this tall (measured 20.67–23 across three SF Symbols; the mean).
    public static let imageBox: CGFloat = 22

    /// Gap between two sections (a `.displayInline` submenu). MEASURED 21.
    public static let sectionGap: CGFloat = 21

    /// The menu TITLE header: total height, its label's top inset and line
    /// box, and the hairline that closes it.
    public static let headerHeight: CGFloat = 40.0 + 1.0 / 3.0
    public static let headerLabelTop: CGFloat = 20
    public static let headerLineHeight: CGFloat = 15.0 + 2.0 / 3.0

    public static let titleFont = UIFont.systemFont(ofSize: 17, weight: .regular)
    public static let subtitleFont = UIFont.systemFont(ofSize: 13, weight: .regular)
    /// Header title: 13 pt at weight trait 0.23 — UIKit's `.medium`.
    public static let headerFont = UIFont.systemFont(ofSize: 13, weight: .medium)

    /// Row title colour: MEASURED black/white at alpha 0.96 (not `label`,
    /// which is opaque).
    public static let titleColor = UIColor(dynamicProvider: { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(white: 1, alpha: 0.96)
            : UIColor(white: 0, alpha: 0.96)
    })
    /// Subtitle colour: MEASURED opaque 0.5098 grey in both appearances'
    /// light probe; the dark subtitle was not probed, so dark reuses
    /// `secondaryLabel` (flagged in docs/KNOWN_GAPS.md).
    public static let subtitleColor = UIColor(dynamicProvider: { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor.secondaryLabel.resolvedColor(with: traits)
            : UIColor(white: 0.5098, alpha: 1)
    })
    /// A disabled row: MEASURED exactly `secondaryLabel`.
    public static let disabledColor = UIColor.secondaryLabel
    /// The header's title: MEASURED exactly `secondaryLabel`.
    public static let headerColor = UIColor.secondaryLabel
    /// Destructive rows: MEASURED systemRed in both appearances.
    public static let destructiveColor = UIColor.systemRed

    /// Corner radius. The layer reports 0 (the shape is the glass effect's,
    /// not a layer radius), so it is FITTED to the framebuffer edge profile:
    /// a circle of R = 32.57 pt, r.m.s. residual 0.37 pt over 92 rows. Same
    /// method, and the same order of residual, as the page sheet's corners.
    public static let cornerRadius: CGFloat = 32.5

    /// Platter fill, solved as "flat colour at alpha over the backdrop" from
    /// four bases per appearance (framebuffer pixels):
    ///   light  out = 0.2892·base + 176.93  ->  alpha 0.7108 of 0.976 white
    ///                (max residual 1.1 counts)
    ///   dark   out = 0.2798·base +  21.74  ->  alpha 0.7202 of 0.118 white
    ///                (max residual 3.7 counts — the dark blur is the less
    ///                linear of the two)
    public static let platterFill = UIColor(dynamicProvider: { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(white: 0.1184, alpha: 0.7202)
            : UIColor(white: 0.976, alpha: 0.7108)
    })

    /// Shadow, fitted to the measured framebuffer edge profiles over white:
    /// the darkening reaches ~37 pt to the SIDE, peaks at 12 counts beside
    /// the platter (so ~24 counts under it → alpha 0.094) and is pushed
    /// 8.7 pt DOWN (top edge 8 counts, bottom edge 16 — the same
    /// offset-solving the alert's shadow uses).
    public static let shadowOffsetY: CGFloat = 8.7
    public static let shadowBlur: CGFloat = 25
    public static let shadowAlpha: CGFloat = 0.094
    /// How far outside the platter the shadow view reaches.
    static let shadowSpill: CGFloat = 48

    /// The hairline under a menu title header (measured height 0 — a device
    /// hairline; we draw one pixel).
    public static let headerSeparatorInset: CGFloat = 24
}

// MARK: - Layout (pure, unit-testable)

/// One laid-out row of a menu platter. Pure data — the views are built from
/// it, and the tests assert on it directly.
public struct UIMenuRowLayout {
    public let element: UIMenuElement
    /// Row frame in platter coordinates.
    public let frame: CGRect
    public let titleFrame: CGRect
    public let titleLines: [String]
    public let subtitleFrame: CGRect?
    public let showsCheck: Bool
    public let showsChevron: Bool
    public let showsImage: Bool
}

@preconcurrency @MainActor
public struct UIMenuLayout {
    public let size: CGSize
    public let headerFrame: CGRect?
    public let headerLines: [String]
    public let separatorYs: [CGFloat]
    public let rows: [UIMenuRowLayout]

    /// Lay a menu out at the measured platter width.
    public static func layout(_ menu: UIMenu) -> UIMenuLayout {
        let W = UIMenuMetrics.platterWidth
        var y: CGFloat = 0
        var headerFrame: CGRect? = nil
        var headerLines: [String] = []
        var separators: [CGFloat] = []
        if !menu.title.isEmpty {
            headerFrame = CGRect(x: 0, y: 0, width: W, height: UIMenuMetrics.headerHeight)
            headerLines = [menu.title]
            separators.append(UIMenuMetrics.headerHeight)
            y = UIMenuMetrics.headerHeight
        }
        y += UIMenuMetrics.platterPadding

        var rows: [UIMenuRowLayout] = []
        let sections = menu.sections
        // The leading column is reserved for the WHOLE menu, not per row.
        // MEASURED: in the `state` probe only the middle item is `.on`, yet
        // ALL THREE titles sit at inset 40. (A mixed image / no-image menu
        // was not probed; the same rule is assumed — docs/KNOWN_GAPS.md.)
        let all = sections.flatMap { $0 }
        let anyImage = all.contains { $0.image != nil }
        let anyState = all.contains { $0.state != .off }
        let lead = anyImage ? UIMenuMetrics.titleInsetImage
                 : anyState ? UIMenuMetrics.titleInsetChecked
                 : UIMenuMetrics.titleInsetPlain
        let textW = W - lead - UIMenuMetrics.titleInsetTrailing
        for (i, section) in sections.enumerated() {
            if i > 0 { y += UIMenuMetrics.sectionGap }
            for element in section {
                let showsImage = element.image != nil
                let showsCheck = element.state != .off
                let lines = TextLayout.wrap(element.title, font: UIMenuMetrics.titleFont,
                                            maxWidth: textW, maxLines: 0)
                    .map { String($0.text) }
                let n = CGFloat(Swift.max(lines.count, 1))
                let titleH = UIMenuMetrics.titleLineHeight
                    + UIMenuMetrics.titleLinePitch * (n - 1)
                var rowH = titleH + UIMenuMetrics.rowPaddingV
                var subtitleFrame: CGRect? = nil
                if let sub = element.subtitle, !sub.isEmpty {
                    rowH = UIMenuMetrics.rowLabelTop + titleH + UIMenuMetrics.subtitleGap
                        + UIMenuMetrics.subtitleLineHeight + UIMenuMetrics.subtitleRowBottom
                    subtitleFrame = CGRect(
                        x: lead,
                        y: y + UIMenuMetrics.rowLabelTop + titleH + UIMenuMetrics.subtitleGap,
                        width: textW, height: UIMenuMetrics.subtitleLineHeight)
                }
                let frame = CGRect(x: 0, y: y, width: W, height: rowH)
                let titleFrame = CGRect(x: lead, y: y + UIMenuMetrics.rowLabelTop,
                                        width: textW, height: titleH)
                rows.append(UIMenuRowLayout(element: element, frame: frame,
                                            titleFrame: titleFrame, titleLines: lines,
                                            subtitleFrame: subtitleFrame,
                                            showsCheck: showsCheck,
                                            showsChevron: element is UIMenu,
                                            showsImage: showsImage))
                y += rowH
            }
        }
        y += UIMenuMetrics.platterPadding
        return UIMenuLayout(size: CGSize(width: W, height: y),
                            headerFrame: headerFrame, headerLines: headerLines,
                            separatorYs: separators, rows: rows)
    }
}

// MARK: - Views

/// The platter itself: measured fill + corner radius. Private class name, so
/// compare.py prunes it the way it prunes UIKit's `_UIContextMenuView`.
@preconcurrency @MainActor
final class _UIContextMenuView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIMenuMetrics.platterFill
        layer.cornerRadius = UIMenuMetrics.cornerRadius
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = UIMenuMetrics.platterFill
        layer.cornerRadius = UIMenuMetrics.cornerRadius
    }
}

/// The platter's shadow, drawn as a RING for exactly the reason
/// `_UIAlertShadowView` documents: a CALayer shadow shows THROUGH a
/// semi-transparent platter and would darken its interior, which real iOS
/// does not do.
@preconcurrency @MainActor
final class _UIContextMenuShadowView: UIView {
    var platterRect: CGRect = .zero

    override init(frame: CGRect) {
        super.init(frame: frame)
        isOpaque = false
        isUserInteractionEnabled = false
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        isOpaque = false
        isUserInteractionEnabled = false
    }

    override func drawContent(in canvas: Canvas, bounds: CGRect) {
        guard !platterRect.isEmpty else { return }
        var ring = Path.rect(bounds)
        ring.elements += _UIMenuShapes.reversedRoundedRect(
            platterRect, cornerRadius: UIMenuMetrics.cornerRadius).elements
        canvas.save()
        canvas.clip(to: ring)
        canvas.setShadow(color: CGColor(red: 0, green: 0, blue: 0,
                                        alpha: UIMenuMetrics.shadowAlpha),
                         offset: CGSize(width: 0, height: UIMenuMetrics.shadowOffsetY),
                         blur: UIMenuMetrics.shadowBlur)
        canvas.drawShadow(of: Path.roundedRect(platterRect,
                                               cornerRadius: UIMenuMetrics.cornerRadius))
        canvas.restore()
    }
}

@preconcurrency @MainActor
enum _UIMenuShapes {
    /// `Path.roundedRect` wound the other way, so adding it to an enclosing
    /// rect yields a ring under the non-zero winding rule.
    static func reversedRoundedRect(_ r: CGRect, cornerRadius: CGFloat) -> Path {
        let radius = Swift.min(cornerRadius, Swift.min(r.width, r.height) / 2)
        let k: CGFloat = 0.5522847498307936
        let kr = k * radius
        var p = Path()
        p.move(to: CGPoint(x: r.minX + radius, y: r.minY))
        p.addCurve(to: CGPoint(x: r.minX, y: r.minY + radius),
                   control1: CGPoint(x: r.minX + radius - kr, y: r.minY),
                   control2: CGPoint(x: r.minX, y: r.minY + radius - kr))
        p.addLine(to: CGPoint(x: r.minX, y: r.maxY - radius))
        p.addCurve(to: CGPoint(x: r.minX + radius, y: r.maxY),
                   control1: CGPoint(x: r.minX, y: r.maxY - radius + kr),
                   control2: CGPoint(x: r.minX + radius - kr, y: r.maxY))
        p.addLine(to: CGPoint(x: r.maxX - radius, y: r.maxY))
        p.addCurve(to: CGPoint(x: r.maxX, y: r.maxY - radius),
                   control1: CGPoint(x: r.maxX - radius + kr, y: r.maxY),
                   control2: CGPoint(x: r.maxX, y: r.maxY - radius + kr))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY + radius))
        p.addCurve(to: CGPoint(x: r.maxX - radius, y: r.minY),
                   control1: CGPoint(x: r.maxX, y: r.minY + radius - kr),
                   control2: CGPoint(x: r.maxX - radius + kr, y: r.minY))
        p.close()
        return p
    }
}

/// The check / chevron column glyphs. NOT SF Symbols (see the file header):
/// strokes inside the measured boxes.
@preconcurrency @MainActor
final class _UIContextMenuGlyphView: UIView {
    enum Kind { case check, chevron }
    var kind: Kind = .check
    var strokeColor: UIColor = UIMenuMetrics.titleColor

    override init(frame: CGRect) {
        super.init(frame: frame)
        isOpaque = false
        isUserInteractionEnabled = false
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        isOpaque = false
        isUserInteractionEnabled = false
    }

    override func drawContent(in canvas: Canvas, bounds: CGRect) {
        var p = Path()
        switch kind {
        case .check:
            p.move(to: CGPoint(x: bounds.minX + bounds.width * 0.06,
                               y: bounds.minY + bounds.height * 0.55))
            p.addLine(to: CGPoint(x: bounds.minX + bounds.width * 0.36,
                                  y: bounds.maxY - bounds.height * 0.12))
            p.addLine(to: CGPoint(x: bounds.maxX - bounds.width * 0.06,
                                  y: bounds.minY + bounds.height * 0.12))
        case .chevron:
            p.move(to: CGPoint(x: bounds.minX + bounds.width * 0.15, y: bounds.minY + 1))
            p.addLine(to: CGPoint(x: bounds.maxX - bounds.width * 0.15, y: bounds.midY))
            p.addLine(to: CGPoint(x: bounds.minX + bounds.width * 0.15, y: bounds.maxY - 1))
        }
        canvas.stroke(p, color: strokeColor.resolvedColor(with: traitCollection).cgColor,
                      lineWidth: 2, cap: .round, join: .round)
    }
}

/// One row. A UIControl so a tap runs the element and dismisses the menu.
@preconcurrency @MainActor
final class _UIContextMenuCell: UIControl {
    let layout: UIMenuRowLayout
    let titleLabel = UILabel()
    var subtitleLabel: UILabel?
    var imageView: UIImageView?
    var glyphs: [_UIContextMenuGlyphView] = []

    init(layout: UIMenuRowLayout) {
        self.layout = layout
        super.init(frame: layout.frame)
        let element = layout.element
        titleLabel.numberOfLines = 0
        titleLabel.text = element.title
        titleLabel.font = UIMenuMetrics.titleFont
        titleLabel.textColor =
            element.attributes.contains(.disabled) ? UIMenuMetrics.disabledColor
            : element.attributes.contains(.destructive) ? UIMenuMetrics.destructiveColor
            : UIMenuMetrics.titleColor
        addSubview(titleLabel)

        if let sub = element.subtitle, !sub.isEmpty {
            let l = UILabel()
            l.text = sub
            l.font = UIMenuMetrics.subtitleFont
            l.textColor = UIMenuMetrics.subtitleColor
            addSubview(l)
            subtitleLabel = l
        }
        if let image = element.image {
            let iv = UIImageView(image: image)
            iv.contentMode = .scaleAspectFit
            addSubview(iv)
            imageView = iv
        }
        if layout.showsCheck {
            let g = _UIContextMenuGlyphView()
            g.kind = .check
            g.strokeColor = titleLabel.textColor
            addSubview(g)
            glyphs.append(g)
        }
        if layout.showsChevron {
            let g = _UIContextMenuGlyphView()
            g.kind = .chevron
            g.strokeColor = UIMenuMetrics.subtitleColor
            addSubview(g)
            glyphs.append(g)
        }
        isEnabled = !element.attributes.contains(.disabled)
    }

    @available(*, unavailable, message: "context-menu cells require a row layout")
    required init?(coder: NSCoder) {
        fatalError("context-menu cells cannot be decoded")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let o = layout.frame.origin
        titleLabel.frame = layout.titleFrame.offsetBy(dx: -o.x, dy: -o.y)
        if let subtitleLabel, let f = layout.subtitleFrame {
            subtitleLabel.frame = f.offsetBy(dx: -o.x, dy: -o.y)
        }
        if let imageView {
            let b = UIMenuMetrics.imageBox
            imageView.frame = CGRect(x: UIMenuMetrics.imageCenterX - b / 2,
                                     y: (bounds.height - b) / 2, width: b, height: b)
        }
        for g in glyphs {
            switch g.kind {
            case .check:
                let s = UIMenuMetrics.checkSize
                g.frame = CGRect(x: UIMenuMetrics.checkCenterX - s.width / 2,
                                 y: (bounds.height - s.height) / 2,
                                 width: s.width, height: s.height)
            case .chevron:
                let s = UIMenuMetrics.chevronSize
                g.frame = CGRect(x: bounds.width - UIMenuMetrics.chevronCenterFromTrailing
                                    - s.width / 2,
                                 y: (bounds.height - s.height) / 2,
                                 width: s.width, height: s.height)
            }
        }
    }
}

/// The container UIKit calls `_UIContextMenuContainerView`: covers the whole
/// window, swallows the tap that dismisses, and hosts the platter.
@preconcurrency @MainActor
final class _UIContextMenuContainerView: UIView {
    /// A touch that lands on the container itself is a touch OUTSIDE the
    /// platter (the platter is a subview and hit-tests first), and UIKit
    /// takes the menu down on it.
    var onTapOutside: (() -> Void)?

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        onTapOutside?()
    }
}

/// A live menu presentation. Not UIKit API — UIKit hides this behind
/// `UIContextMenuInteraction` and `UIButton.menu`, and so does OpenUIKit;
/// it is public so a host or a test can drive a menu without synthesising a
/// long press.
@preconcurrency @MainActor
public final class _UIMenuPresentation {
    public let menu: UIMenu
    public private(set) weak var sourceView: UIView?
    let container = _UIContextMenuContainerView()
    let shadowView = _UIContextMenuShadowView()
    let platter = _UIContextMenuView()
    var cells: [_UIContextMenuCell] = []
    var headerLabel: UILabel?
    var separators: [UIView] = []
    /// Called when the menu goes away, for whatever reason.
    var onDismiss: (() -> Void)?
    /// What runs when a row is chosen (submenus push, actions perform).
    var onSelect: ((UIMenuElement) -> Void)?

    /// The one menu on screen. UIKit allows exactly one too, and like
    /// UIKit's the presentation is owned by the framework for as long as it
    /// is up — an app that ignores the return value of `present` still gets
    /// a live menu. `dismiss()` releases it.
    public private(set) static var active: _UIMenuPresentation?

    init(menu: UIMenu, sourceView: UIView) {
        self.menu = menu
        self.sourceView = sourceView
    }

    /// Present `menu` anchored to `sourceRect` (in `source`'s coordinates,
    /// defaulting to its bounds). Returns nil when the source is not in a
    /// window — there is nowhere to put the platter.
    @discardableResult
    public static func present(_ menu: UIMenu, from source: UIView,
                               sourceRect: CGRect? = nil) -> _UIMenuPresentation? {
        guard let root = source.window else { return nil }
        active?.dismiss()
        let p = _UIMenuPresentation(menu: menu, sourceView: source)
        let rect = sourceRect ?? source.bounds
        let anchor = CGRect(origin: source.convert(rect.origin, to: root), size: rect.size)
        p.install(in: root, anchor: anchor)
        active = p
        return p
    }

    func install(in root: UIView, anchor: CGRect) {
        container.frame = root.bounds
        container.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        container.onTapOutside = { [weak self] in self?.dismiss() }
        root.addSubview(container)

        let layout = UIMenuLayout.layout(menu)
        // Anchoring: platter top-left on the source's top-left (measured),
        // then clamped into the container. See the file header.
        var origin = CGPoint(x: anchor.minX, y: anchor.minY)
        origin.x = Swift.min(Swift.max(origin.x, 0), Swift.max(container.bounds.width - layout.size.width, 0))
        origin.y = Swift.min(Swift.max(origin.y, 0), Swift.max(container.bounds.height - layout.size.height, 0))
        let platterRect = CGRect(origin: origin, size: layout.size)

        shadowView.frame = platterRect.insetBy(dx: -UIMenuMetrics.shadowSpill,
                                               dy: -UIMenuMetrics.shadowSpill)
        shadowView.platterRect = CGRect(x: UIMenuMetrics.shadowSpill,
                                        y: UIMenuMetrics.shadowSpill,
                                        width: platterRect.width, height: platterRect.height)
        container.addSubview(shadowView)

        platter.frame = platterRect
        platter.clipsToBounds = true
        container.addSubview(platter)

        if let hf = layout.headerFrame {
            let l = UILabel()
            l.text = menu.title
            l.font = UIMenuMetrics.headerFont
            l.textColor = UIMenuMetrics.headerColor
            l.frame = CGRect(x: UIMenuMetrics.titleInsetPlain,
                             y: UIMenuMetrics.headerLabelTop,
                             width: hf.width - 2 * UIMenuMetrics.titleInsetPlain,
                             height: UIMenuMetrics.headerLineHeight)
            platter.addSubview(l)
            headerLabel = l
        }
        for y in layout.separatorYs {
            let v = UIView(frame: CGRect(x: UIMenuMetrics.headerSeparatorInset, y: y,
                                         width: layout.size.width
                                             - 2 * UIMenuMetrics.headerSeparatorInset,
                                         height: 1 / UIScreen.main.scale))
            v.backgroundColor = UIColor.separator
            platter.addSubview(v)
            separators.append(v)
        }
        for row in layout.rows {
            let cell = _UIContextMenuCell(layout: row)
            cell.addTarget(for: .touchUpInside) { [weak self] _, _ in
                self?.select(row.element)
            }
            platter.addSubview(cell)
            cells.append(cell)
        }
    }

    func select(_ element: UIMenuElement) {
        guard !element.attributes.contains(.disabled) else { return }
        if let submenu = element as? UIMenu {
            // A submenu REPLACES the platter (UIKit slides it in; we swap).
            guard let source = sourceView else { return }
            let anchor = CGRect(origin: container.convert(platter.frame.origin, to: source),
                                size: platter.frame.size)
            dismiss()
            _UIMenuPresentation.present(submenu, from: source, sourceRect: anchor)
            return
        }
        dismiss()
        if let action = element as? UIAction {
            action.performWithSender(sourceView, target: nil)
        } else if let command = element as? UICommand, let source = sourceView {
            source._perform(command, from: source)
        }
        onSelect?(element)
    }

    public func dismiss() {
        container.removeFromSuperview()
        if _UIMenuPresentation.active === self { _UIMenuPresentation.active = nil }
        onDismiss?()
    }

}

// MARK: - UIInteraction

/// UIKit's protocol for objects a view hosts (`addInteraction(_:)`).
@preconcurrency @MainActor
public protocol UIInteraction: AnyObject {
    var view: UIView? { get }
    func willMove(to view: UIView?)
    func didMove(to view: UIView?)
}

public extension UIInteraction {
    func willMove(to view: UIView?) {}
    func didMove(to view: UIView?) {}
}

extension UIView {
    public var interactions: [UIInteraction] { _interactions }

    public func addInteraction(_ interaction: UIInteraction) {
        guard !_interactions.contains(where: { $0 === interaction }) else { return }
        // UIKit interactions have one owning view. A live iOS 26.1 probe
        // confirms that adding an attached interaction to B first removes it
        // from A (including A's willMove/didMove(nil) lifecycle) before B's
        // attachment callbacks run.
        if let oldView = interaction.view, oldView !== self {
            oldView.removeInteraction(interaction)
        }
        interaction.willMove(to: self)
        _interactions.append(interaction)
        interaction.didMove(to: self)
    }

    public func removeInteraction(_ interaction: UIInteraction) {
        guard _interactions.contains(where: { $0 === interaction }) else { return }
        interaction.willMove(to: nil)
        _interactions.removeAll { $0 === interaction }
        interaction.didMove(to: nil)
    }
}

// MARK: - UIContextMenuConfiguration

@preconcurrency @MainActor
public final class UIContextMenuConfiguration {
    public let identifier: AnyHashable?
    public let previewProvider: (() -> UIViewController?)?
    public let actionProvider: (([UIMenuElement]) -> UIMenu?)?

    public init(identifier: AnyHashable? = nil,
                previewProvider: (() -> UIViewController?)? = nil,
                actionProvider: (([UIMenuElement]) -> UIMenu?)? = nil) {
        self.identifier = identifier
        self.previewProvider = previewProvider
        self.actionProvider = actionProvider
    }

    /// The menu this configuration produces, or nil.
    public func resolvedMenu() -> UIMenu? { actionProvider?([]) }
}

/// UIKit's preview clipping / background descriptor. Stored as data;
/// OpenUIKit does not composite a live preview (docs/KNOWN_GAPS.md).
@preconcurrency @MainActor
open class UIPreviewParameters {
    public var visiblePath: UIBezierPath?
    public var shadowPath: UIBezierPath?
    public var backgroundColor: UIColor?
    public init() {}
    public init(textLineRects: [CGRect]) {
        if !textLineRects.isEmpty {
            let path = UIBezierPath()
            for r in textLineRects { path.append(UIBezierPath(rect: r)) }
            visiblePath = path
        }
    }
}

@preconcurrency @MainActor
open class UIDragPreviewParameters: UIPreviewParameters {}

/// Where a targeted preview should come from or go to. Stored as data.
@preconcurrency @MainActor
open class UIPreviewTarget {
    public let container: UIView
    public let center: CGPoint
    public let transform: CGAffineTransform
    public init(container: UIView, center: CGPoint, transform: CGAffineTransform) {
        self.container = container
        self.center = center
        self.transform = transform
    }
    public convenience init(container: UIView, center: CGPoint) {
        self.init(container: container, center: center, transform: .identity)
    }
}

@preconcurrency @MainActor
open class UIDragPreviewTarget: UIPreviewTarget {}

/// UIKit's preview descriptor. Declared for source compatibility; OpenUIKit
/// draws no preview (docs/KNOWN_GAPS.md), so the parameters are stored and
/// ignored. MEASURED existing pointer tests keep `init(view:)` compiling
/// without a window.
@preconcurrency @MainActor
open class UITargetedPreview {
    public let view: UIView
    public let parameters: UIPreviewParameters
    public let target: UIPreviewTarget
    public var size: CGSize { view.bounds.size }

    public init(view: UIView, parameters: UIPreviewParameters, target: UIPreviewTarget) {
        self.view = view
        self.parameters = parameters
        self.target = target
    }

    public convenience init(view: UIView, parameters: UIPreviewParameters) {
        let container = view.superview ?? view
        self.init(view: view, parameters: parameters,
                  target: UIPreviewTarget(container: container, center: view.center))
    }

    public convenience init(view: UIView) {
        self.init(view: view, parameters: UIPreviewParameters())
    }

    public func retargetedPreview(with newTarget: UIPreviewTarget) -> UITargetedPreview {
        UITargetedPreview(view: view, parameters: parameters, target: newTarget)
    }
}

@preconcurrency @MainActor
open class UITargetedDragPreview: UITargetedPreview {
    public func retargetedPreview(with newTarget: UIDragPreviewTarget) -> UITargetedDragPreview {
        UITargetedDragPreview(view: view, parameters: parameters, target: newTarget)
    }
}

/// UIKit's animator objects. The menu here appears and disappears without a
/// transition (docs/KNOWN_GAPS.md), so an app's added animations and
/// completions are run IMMEDIATELY rather than alongside a morph — which
/// keeps the side effects apps put in them (state updates, navigation)
/// happening, in order, at the right moment.
@preconcurrency @MainActor
public protocol UIContextMenuInteractionAnimating: AnyObject {
    var previewViewController: UIViewController? { get }
    func addAnimations(_ animations: @escaping () -> Void)
    func addCompletion(_ completion: @escaping () -> Void)
}

@preconcurrency @MainActor
public protocol UIContextMenuInteractionCommitAnimating: UIContextMenuInteractionAnimating {
    var preferredCommitStyle: UIContextMenuInteractionCommitStyle { get set }
}

public enum UIContextMenuInteractionCommitStyle: Int, Sendable { case dismiss = 0, pop = 1 }

/// The concrete animator handed to the delegate: it runs what it is given,
/// straight away. See the protocol's note.
@preconcurrency @MainActor
final class _UIContextMenuAnimator: UIContextMenuInteractionCommitAnimating {
    var previewViewController: UIViewController?
    var preferredCommitStyle: UIContextMenuInteractionCommitStyle = .dismiss
    func addAnimations(_ animations: @escaping () -> Void) { animations() }
    func addCompletion(_ completion: @escaping () -> Void) { completion() }
}

@preconcurrency @MainActor
public protocol UIContextMenuInteractionDelegate: AnyObject {
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                configurationForMenuAtLocation location: CGPoint)
        -> UIContextMenuConfiguration?
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                willDisplayMenuFor configuration: UIContextMenuConfiguration,
                                animator: UIContextMenuInteractionAnimating?)
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                willEndFor configuration: UIContextMenuConfiguration,
                                animator: UIContextMenuInteractionAnimating?)
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                previewForHighlightingMenuWithConfiguration
                                    configuration: UIContextMenuConfiguration)
        -> UITargetedPreview?
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                previewForDismissingMenuWithConfiguration
                                    configuration: UIContextMenuConfiguration)
        -> UITargetedPreview?
}

public extension UIContextMenuInteractionDelegate {
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                willDisplayMenuFor configuration: UIContextMenuConfiguration,
                                animator: UIContextMenuInteractionAnimating?) {}
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                willEndFor configuration: UIContextMenuConfiguration,
                                animator: UIContextMenuInteractionAnimating?) {}
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                previewForHighlightingMenuWithConfiguration
                                    configuration: UIContextMenuConfiguration)
        -> UITargetedPreview? { nil }
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                previewForDismissingMenuWithConfiguration
                                    configuration: UIContextMenuConfiguration)
        -> UITargetedPreview? { nil }
}

/// Long-press to open a menu. The gesture is a real
/// `UILongPressGestureRecognizer` at UIKit's 0.5 s, so the menu appears at
/// the same moment UIKit's would; what is missing is UIKit's preview
/// morph and background blur (see the file header).
@preconcurrency @MainActor
public final class UIContextMenuInteraction: UIInteraction {
    public weak var delegate: UIContextMenuInteractionDelegate?
    public private(set) weak var view: UIView?
    private var press: UILongPressGestureRecognizer?
    private var presentation: _UIMenuPresentation?
    private var configuration: UIContextMenuConfiguration?

    public init(delegate: UIContextMenuInteractionDelegate) {
        self.delegate = delegate
    }

    public func willMove(to view: UIView?) {
        if let press, let old = self.view {
            old.removeGestureRecognizer(press)
            self.press = nil
        }
    }

    public func didMove(to view: UIView?) {
        self.view = view
        guard let view else { return }
        let g = UILongPressGestureRecognizer { [weak self] r in
            guard r.state == .began else { return }
            self?.presentMenu(at: r.location(in: view))
        }
        view.addGestureRecognizer(g)
        press = g
    }

    /// UIKit's `dismissMenu()`.
    public func dismissMenu() {
        presentation?.dismiss()
    }

    func presentMenu(at location: CGPoint) {
        guard let view,
              let config = delegate?.contextMenuInteraction(self,
                                                            configurationForMenuAtLocation: location),
              let menu = config.resolvedMenu() else { return }
        configuration = config
        delegate?.contextMenuInteraction(self, willDisplayMenuFor: config,
                                         animator: _UIContextMenuAnimator())
        let p = _UIMenuPresentation.present(menu, from: view,
                                            sourceRect: CGRect(origin: location, size: .zero))
        p?.onDismiss = { [weak self] in
            guard let self, let config = self.configuration else { return }
            self.delegate?.contextMenuInteraction(self, willEndFor: config,
                                                  animator: _UIContextMenuAnimator())
            self.presentation = nil
            self.configuration = nil
        }
        presentation = p
    }
}
