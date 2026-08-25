// Settings row + group card components. Owner: demo app (M7.5).
//
// The row-component helper docs/APP_FEEL.md asks for: a 44pt table-style row
// with an optional icon tile, a title, and an accessory (chevron / switch /
// value+chevron), grouped into rounded "inset grouped" cards.
//
// Touch feel (APP_FEEL "Row/touch feel"):
//   - The row highlights with systemGray4 on touch-down. Rows live inside a
//     UIScrollView, so touch-down reaches them AFTER the ~150ms
//     delaysContentTouches window (or immediately on a quick tap's touch-up
//     — UIKit's own behavior); either way the highlight paints before the
//     tap action runs, because touchesBegan is always delivered before
//     touchesEnded fires .touchUpInside.
//   - On touch-up (or cancel) the highlight fades back over 0.3s via
//     UIView.animate — the fade keeps playing while a push transition runs,
//     exactly like a real Settings row.

import OpenUIKit

// MARK: - Row

public final class SettingsRow: UIControl {
    public enum Accessory {
        case none
        case chevron
        case value(String)          // right-aligned detail text + chevron
        case detail(String)         // right-aligned detail text only (static)
        case toggle(Bool)           // a UISwitch, initially on/off
    }

    public static let rowHeight: CGFloat = 44
    static let contentInset: CGFloat = 16
    static let iconLeading: CGFloat = 15
    static let iconTitleGap: CGFloat = 14
    static let highlightFadeDuration: Double = 0.3

    public let titleLabel = UILabel()
    let iconTile: IconTile?
    var valueLabel: UILabel?
    var chevronLabel: UILabel?
    public private(set) var toggle: UISwitch?
    let separator = UIView()
    public var showsSeparator: Bool {
        get { !separator.isHidden }
        set { separator.isHidden = !newValue }
    }

    /// Fired on .touchUpInside (after the highlight has painted).
    public var onTap: ((SettingsRow) -> Void)?
    /// Fired when the accessory switch changes value.
    public var onToggle: ((Bool) -> Void)?

    /// Rows with a switch (or nothing) don't highlight, like iOS cells with
    /// selectionStyle == .none.
    let highlights: Bool

    public init(icon: IconGlyph? = nil, iconColor: UIColor = .systemBlue,
                title: String, accessory: Accessory = .chevron) {
        iconTile = icon.map { IconTile(glyph: $0, color: iconColor) }
        switch accessory {
        case .chevron, .value: highlights = true
        case .none, .detail, .toggle: highlights = false
        }
        super.init(frame: CGRect(x: 0, y: 0, width: 358,
                                 height: SettingsRow.rowHeight))
        backgroundColor = .secondarySystemGroupedBackground

        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 17)
        titleLabel.textColor = .label
        addSubview(titleLabel)
        if let tile = iconTile { addSubview(tile) }

        switch accessory {
        case .none:
            break
        case .chevron:
            addChevron()
        case .value(let text):
            let v = UILabel()
            v.text = text
            v.font = .systemFont(ofSize: 17)
            v.textColor = .secondaryLabel
            addSubview(v)
            valueLabel = v
            addChevron()
        case .detail(let text):
            let v = UILabel()
            v.text = text
            v.font = .systemFont(ofSize: 17)
            v.textColor = .secondaryLabel
            addSubview(v)
            valueLabel = v
        case .toggle(let isOn):
            let sw = UISwitch()
            sw.setOn(isOn, animated: false)
            sw.addTarget(for: .valueChanged) { [weak self] control, _ in
                guard let self, let sw = control as? UISwitch else { return }
                self.onToggle?(sw.isOn)
            }
            addSubview(sw)
            toggle = sw
        }

        separator.backgroundColor = .separator
        separator.isUserInteractionEnabled = false
        addSubview(separator)

        // Tap action: .touchUpInside fires after touchesBegan painted the
        // highlight (see file header).
        addTarget(for: .touchUpInside) { [weak self] _, _ in
            guard let self else { return }
            self.onTap?(self)
        }
    }

    private func addChevron() {
        let c = UILabel()
        c.text = "\u{203A}" // ›
        c.font = .systemFont(ofSize: 17, weight: .semibold)
        c.textColor = .systemGray2
        addSubview(c)
        chevronLabel = c
    }

    /// Leading x of the title (also the separator inset).
    var titleX: CGFloat {
        iconTile == nil ? SettingsRow.contentInset
            : SettingsRow.iconLeading + IconTile.tileSize.width
                + SettingsRow.iconTitleGap
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        let h = bounds.height
        if let tile = iconTile {
            tile.frame = CGRect(x: SettingsRow.iconLeading,
                                y: (h - IconTile.tileSize.height) / 2,
                                width: IconTile.tileSize.width,
                                height: IconTile.tileSize.height)
        }
        let t = titleLabel.intrinsicContentSize
        titleLabel.frame = CGRect(x: titleX, y: (h - t.height) / 2,
                                  width: t.width, height: t.height)
        var trailingX = bounds.width - SettingsRow.contentInset
        if let c = chevronLabel {
            let s = c.intrinsicContentSize
            c.frame = CGRect(x: trailingX - s.width, y: (h - s.height) / 2,
                             width: s.width, height: s.height)
            trailingX -= s.width + 8
        }
        if let v = valueLabel {
            let s = v.intrinsicContentSize
            v.frame = CGRect(x: trailingX - s.width, y: (h - s.height) / 2,
                             width: s.width, height: s.height)
        }
        if let sw = toggle {
            sw.frame = CGRect(x: bounds.width - SettingsRow.contentInset
                                 - sw.bounds.width,
                              y: (h - sw.bounds.height) / 2,
                              width: sw.bounds.width, height: sw.bounds.height)
        }
        separator.frame = CGRect(x: titleX, y: h - 0.5,
                                 width: bounds.width - titleX, height: 0.5)
    }

    // MARK: Highlight flash (APP_FEEL row feel)

    public override func stateDidChange() {
        super.stateDidChange()
        guard highlights else { return }
        if isHighlighted {
            // Instant flash — kill any in-flight fade first.
            removeAllAnimations()
            backgroundColor = .systemGray4
        } else {
            UIView.animate(withDuration: SettingsRow.highlightFadeDuration,
                           delay: 0, options: .curveLinear, animations: {
                self.backgroundColor = .secondarySystemGroupedBackground
            })
        }
    }

}

// MARK: - Group card

/// An inset-grouped card: rounded 10pt corners, rows stacked at 44pt, the
/// last row's separator hidden. Sized to fit its rows.
public final class GroupCard: UIView {
    public let rows: [SettingsRow]

    public init(rows: [SettingsRow]) {
        self.rows = rows
        let height = CGFloat(rows.count) * SettingsRow.rowHeight
        super.init(frame: CGRect(x: 0, y: 0, width: 358, height: height))
        backgroundColor = .secondarySystemGroupedBackground
        layer.cornerRadius = 10
        clipsToBounds = true
        for (i, row) in rows.enumerated() {
            row.frame = CGRect(x: 0, y: CGFloat(i) * SettingsRow.rowHeight,
                               width: bounds.width,
                               height: SettingsRow.rowHeight)
            row.autoresizingMask = [.flexibleWidth]
            row.showsSeparator = i < rows.count - 1
            addSubview(row)
        }
    }
}

/// A grouped-table section header ("GENERAL" style: 13pt, secondaryLabel,
/// uppercase supplied by the caller).
public func makeSectionHeader(_ text: String) -> UILabel {
    let l = UILabel()
    l.text = text
    l.font = .systemFont(ofSize: 13)
    l.textColor = .secondaryLabel
    return l
}

/// A grouped-table footer/footnote label (13pt, secondaryLabel, wrapping).
public func makeFootnote(_ text: String) -> UILabel {
    let l = UILabel()
    l.text = text
    l.font = .systemFont(ofSize: 13)
    l.textColor = .secondaryLabel
    l.numberOfLines = 0
    return l
}
