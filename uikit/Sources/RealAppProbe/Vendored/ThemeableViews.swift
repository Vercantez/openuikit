// VENDORED, UNMODIFIED apart from the marked lines: five of pocket-casts'
// themeable base classes, concatenated into one file because each is under
// 80 lines.
//
//   podcasts/ThemeableView.swift                       (49 lines)
//   podcasts/ThemeableLabel.swift                      (55 lines)
//   podcasts/TintableImageView.swift                   (27 lines)
//   podcasts/Theme/Themable Views/ThemeableTable.swift (58 lines)
//   podcasts/Theme/Themable Views/ThemeableCell.swift  (74 lines)
//
// These are the superclasses of everything the storage screen renders:
// SwitchCell and DisclosureCell are ThemeableCells inside a ThemeableTable,
// their labels are ThemeableLabels, DisclosureCell's chevron is a
// TintableImageView, and each section header is a ThemeableView. They are
// vendored rather than shimmed BECAUSE they paint — every colour on the
// screen is decided in one of these `updateColor()` bodies.
//
// ADAPTED(objc-runtime): `#selector(themeDidChange)` becomes
// `Selector.named("themeDidChange")` and the method loses `@objc private`, as
// in every vendored file here (docs/REAL_APP_TEST.md blocker 1).

import UIKit

class ThemeableView: UIView {
    var style: ThemeStyle = .primaryUi01 {
        didSet {
            updateColor()
        }
    }

    var themeOverride: Theme.ThemeType? {
        didSet {
            updateColor()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        setup()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setup() {
        updateColor()

        NotificationCenter.default.addObserver(self, selector: Selector.named("themeDidChange"), name: Constants.Notifications.themeChanged, object: nil)
    }

    func themeDidChange() {
        updateColor()
        handleThemeDidChange()
    }

    // For subclasses to be notified about theme changes
    func handleThemeDidChange() {}

    private func updateColor() {
        backgroundColor = AppTheme.colorForStyle(style, themeOverride: themeOverride)
    }
}

class ThemeableLabel: UILabel {
    var style: ThemeStyle = .primaryText01 {
        didSet {
            updateTextColor()
        }
    }

    var themeOverride: Theme.ThemeType? {
        didSet {
            updateTextColor()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        setup()
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        updateTextColor()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setup() {
        NotificationCenter.default.addObserver(self, selector: Selector.named("themeDidChange"), name: Constants.Notifications.themeChanged, object: nil)
        updateTextColor()
    }

    func themeDidChange() {
        updateTextColor()
        handleThemeDidChange()
    }

    // can be overridden by sub-classes to do more when the theme changes
    func handleThemeDidChange() {}

    private func updateTextColor() {
        textColor = AppTheme.colorForStyle(style, themeOverride: themeOverride)
    }
}

class TintableImageView: UIImageView {
    override init(image: UIImage?) {
        super.init(image: image)

        super.image = image?.tintedImage(tintColor)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        super.image = image?.tintedImage(tintColor)
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        super.image = image?.tintedImage(tintColor)
    }

    override var tintColor: UIColor! {
        didSet {
            super.image = image?.tintedImage(tintColor)
        }
    }
}

class ThemeableTable: UITableView {
    var themeStyle: ThemeStyle = .primaryUi04 {
        didSet {
            updateColor()
        }
    }

    var themeOverride: Theme.ThemeType? {
        didSet {
            updateColor()
        }
    }

    override init(frame: CGRect = .zero, style: UITableView.Style = .plain) {
        super.init(frame: frame, style: style)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        commonInit()
    }

    func commonInit() {
        NotificationCenter.default.addObserver(self, selector: Selector.named("themeDidChange"), name: Constants.Notifications.themeChanged, object: nil)
        updateColor()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func themeDidChange() {
        updateColor()
    }

    class func setHeaderFooterTextColor(on headerFooter: UIView) {
        // we do this instead of using UIAppearance because UIKit overwrites this colour sometimes
        // mentioned here (https://developer.apple.com/forums/thread/60735) and reproducible if you set your phone to dark and our app to light
        if let headerFooterView = headerFooter as? UITableViewHeaderFooterView {
            headerFooterView.textLabel?.textColor = ThemeColor.primaryText02()
        }
    }

    private func updateColor() {
        backgroundColor = AppTheme.colorForStyle(themeStyle, themeOverride: themeOverride)
        separatorColor = AppTheme.tableDividerColor(for: themeOverride)
        indicatorStyle = AppTheme.indicatorStyle()
    }
}

class ThemeableCell: UITableViewCell, ReusableTableCell {
    var style: ThemeStyle = .primaryUi02 {
        didSet {
            updateColor()
        }
    }

    var selectedStyle: ThemeStyle = .primaryUi02Active
    var iconStyle: ThemeStyle = .primaryIcon02
    var themeOverride: Theme.ThemeType? {
        didSet {
            updateColor()
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        NotificationCenter.default.addObserver(self, selector: Selector.named("themeDidChange"), name: Constants.Notifications.themeChanged, object: nil)
        updateColor()
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        NotificationCenter.default.addObserver(self, selector: Selector.named("themeDidChange"), name: Constants.Notifications.themeChanged, object: nil)
        updateColor()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        setHighlightedState(highlighted)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        setHighlightedState(selected)
    }

    func themeDidChange() {
        updateColor()
    }

    func handleThemeDidChange() {}

    func updateColor() {
        updateBgColor(AppTheme.colorForStyle(style, themeOverride: themeOverride))
        accessoryView?.tintColor = AppTheme.colorForStyle(iconStyle, themeOverride: themeOverride)
        tintColor = AppTheme.colorForStyle(iconStyle, themeOverride: themeOverride)

        handleThemeDidChange()
    }

    private func setHighlightedState(_ highlighted: Bool) {
        if highlighted {
            updateBgColor(AppTheme.colorForStyle(selectedStyle, themeOverride: themeOverride))
        } else {
            updateBgColor(AppTheme.colorForStyle(style, themeOverride: themeOverride))
        }
    }

    private func updateBgColor(_ color: UIColor) {
        contentView.backgroundColor = color
        backgroundColor = color
        accessoryView?.backgroundColor = color
    }
}
