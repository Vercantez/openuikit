// VENDORED, UNMODIFIED apart from the marked lines:
// pocket-casts-ios podcasts/SwitchCell.swift (73 lines).
//
// The cell every small settings screen registers as
// `UINib(nibName: "SwitchCell", bundle: nil)`. Its labels, image view and
// text-to-image constraint come out of SwitchCell.xib
// (fixtures/realapp/nibs/SwitchCell.nib) — see Sources/OpenUIKit/UINib.swift.
//
// ADAPTED(objc-runtime): the three `@IBOutlet` attributes. `@IBOutlet` implies
// `@objc`, which native ELF Swift refuses before OpenUIKit is consulted — the
// same wall as `#selector` (docs/REAL_APP_TEST.md blocker 1). The portable
// spelling is the plain property plus one line per outlet in
// Sources/RealAppProbe/NibClasses.swift, the nib-side twin of
// SelectorTables.swift. scripts/realapp_probe_sim.sh puts the upstream
// attribute back for the Darwin build, so the real-UIKit oracle compiles the
// upstream text.

import UIKit

class SwitchCell: ThemeableCell {
    let cellSwitch: ThemeableSwitch = {
        let cellSwitch = ThemeableSwitch()
        cellSwitch.isAccessibilityElement = false
        return cellSwitch
    }()
    var cellLabel: UILabel! {
        didSet {
            cellLabel.font = UIFont.font(ofSize: 16.0, scalingWith: .callout)
            cellLabel.numberOfLines = 0
            cellLabel.adjustsFontForContentSizeCategory = true
            // Ensure label can expand vertically
            cellLabel.setContentCompressionResistancePriority(.required, for: .vertical)
            cellLabel.setContentHuggingPriority(.defaultLow, for: .vertical)
        }
    }
    var cellImage: UIImageView!
    var cellTextToImageConstraint: NSLayoutConstraint!

    var switchStyle: ThemeStyle = .primaryInteractive01

    var isLocked = true {
        didSet {
            cellSwitch.isUserInteractionEnabled = isLocked
            cellSwitch.isEnabled = isLocked
            contentView.alpha = isLocked ? 1 : 0.3
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        accessoryView = cellSwitch
        setNoImage()

        registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) { (view: SwitchCell, _) in
            view.updateSize()
        }
    }

    override func handleThemeDidChange() {
        let color = AppTheme.colorForStyle(switchStyle)
        cellSwitch.onTintColor = color
        cellImage.tintColor = color
    }

    func setImage(imageName: String) {
        cellTextToImageConstraint.isActive = true
        cellImage.tintColor = cellSwitch.onTintColor
        cellImage.image = UIImage(named: imageName)
        updateSize()
    }

    func setNoImage() {
        cellTextToImageConstraint.isActive = false
        cellImage.image = nil
    }

    override func setSelected(_ selected: Bool, animated: Bool) {}
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {}

    override func accessibilityActivate() -> Bool {
        return isLocked
    }

    private func updateSize() {
        let metric = UIFontMetrics(forTextStyle: .largeTitle)

        let settingsSize = max(24, metric.scaledValue(for: 24))
        cellImage.updateSizeConstraints(to: settingsSize)
    }
}
