// Focus Settings table chrome under the iOS cut — the rules the
// realapp_focus_settings_light golden (iPhone 16 3x, iOS 26.1) and the
// tableprobe oracle run of 2026-09-07 (agent/focus-fidelity-tables; the
// same insetGrouped table on the iPhone 16 3x AND the iPhone SE 2x) pin
// down. Every number below is a frame read off one of those dumps.
import XCTest
@testable import OpenUIKit

/// Blockzilla's SettingsViewController shape: classic textLabel cells with
/// `contentView.layoutMargins = (0, 20, 0, 0)` and `cell.layoutMargins =
/// .zero`, nil-title sections whose `heightForHeaderInSection` returns 30,
/// a 50 pt titled header, a UIImageView(systemName:) accessory, a padded
/// switch accessory.
private final class FocusShapeSource: UITableViewDataSource, UITableViewDelegate {
    struct Section { let title: String?; let headerHeight: CGFloat; let rows: Int }
    let sections: [Section] = [
        Section(title: nil, headerHeight: 30, rows: 1),        // default browser
        Section(title: "General", headerHeight: 30, rows: 1),  // theme (value1 + chevron)
        Section(title: "PRIVACY", headerHeight: 50, rows: 2),  // tracking (value1) + toggle
        Section(title: nil, headerHeight: 30, rows: 1),        // usage data (toggle)
    ]
    var accessoryForRow: (IndexPath) -> UIView? = { _ in nil }

    func numberOfSections(in tableView: UITableView) -> Int { sections.count }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { sections[section].rows }
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? { sections[section].title }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { sections[section].headerHeight }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let value1 = indexPath == IndexPath(row: 0, section: 1) || indexPath == IndexPath(row: 0, section: 2)
        let cell = UITableViewCell(style: value1 ? .value1 : .subtitle, reuseIdentifier: nil)
        cell.contentView.layoutMargins = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
        cell.layoutMargins = .zero
        cell.textLabel.text = ["Set as Default Browser", "Theme", "Tracking Protection", "Send usage data"][indexPath.section]
        if value1 { cell.detailTextLabel?.text = indexPath.section == 1 ? "Light" : "On" }
        cell.accessoryView = accessoryForRow(indexPath)
        return cell
    }
}

#if !os(Linux)
@MainActor
#endif
final class FocusSettingsTableTests: XCTestCase {
    private var savedCut: FontEngine.SystemFontCut!
    private var savedBounds: CGRect!
    private var savedScale: CGFloat!

    override func setUp() {
        super.setUp()
        TextTestSupport.configureResourceRoot()
        savedCut = OpenUIKitRuntime.systemFontCut
        savedBounds = UIScreen.main.bounds
        savedScale = UIScreen.main.scale
        OpenUIKitRuntime.systemFontCut = .iOS
        UIScreen.main._hostConfigure(bounds: CGRect(x: 0, y: 0, width: 393, height: 852), scale: 3)
    }

    override func tearDown() {
        OpenUIKitRuntime.systemFontCut = savedCut
        UIScreen.main._hostConfigure(bounds: savedBounds, scale: savedScale)
        super.tearDown()
    }

    /// iPhone 16 window (393 wide) so the inset-grouped card sits at 20.
    private func makeTable(_ source: FocusShapeSource) -> (UIWindow, UITableView) {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 393, height: 852))
        let table = UITableView(frame: CGRect(x: 0, y: 0, width: 393, height: 739), style: .insetGrouped)
        table.estimatedRowHeight = UITableView.automaticDimension
        table.dataSource = source
        table.delegate = source
        window.addSubview(table)
        window.isHidden = false
        table.layoutIfNeeded()
        return (window, table)
    }

    private func chevron() -> UIImageView {
        let iv = UIImageView(image: UIImage(systemName: "chevron.right"))
        // Real UIKit's body-size chevron.right: 12.667 × 16.667 (golden + probe).
        iv.frame = CGRect(x: 0, y: 0, width: 12.666667, height: 16.666667)
        return iv
    }

    /// Golden realapp_focus_settings_light / tableprobe 3x: untitled sections
    /// ignore the delegate's 30 — the first section's rows start at 35, a
    /// later untitled header is 17.667 after a 17.333 untitled footer — and
    /// titled sections honour 30 / 50. Rows are 52.
    func testUntitledSectionsIgnoreTheDelegateHeightAndClassicRowsAre52() {
        let source = FocusShapeSource()
        let (_, table) = makeTable(source)
        let r = { (s: Int, r: Int) in table.rectForRow(at: IndexPath(row: r, section: s)) }
        // Section 0: `SettingsTableViewCell [0, 35, 353, 52]`.
        XCTAssertEqual(r(0, 0).minY, 35, accuracy: 0.001)
        XCTAssertEqual(r(0, 0).height, 52, accuracy: 0.001)
        XCTAssertEqual(r(0, 0).minX, 20, accuracy: 0.001)
        XCTAssertEqual(r(0, 0).width, 353, accuracy: 0.001)
        XCTAssertNil(table.headerViews[0], "an untitled header installs no view")
        // Section 1: untitled footer 17.333 (87 → 104.333), titled header 30.
        XCTAssertEqual(table.metrics[1].headerY, 87 + 17.333333, accuracy: 0.001)
        XCTAssertEqual(table.metrics[1].headerHeight, 30, accuracy: 0.001)
        XCTAssertEqual(r(1, 0).minY, 134.333333, accuracy: 0.001)
        // Section 2: 50 pt header; rows 52 + 52.
        XCTAssertEqual(table.metrics[2].headerHeight, 50, accuracy: 0.001)
        XCTAssertEqual(r(2, 1).minY - r(2, 0).minY, 52, accuracy: 0.001)
        // Section 3 (untitled, delegate 30): 17.333 footer + 17.667 header = 35
        // between the last privacy row and the toggle row.
        XCTAssertEqual(table.metrics[3].headerHeight, 17.666667, accuracy: 0.001)
        XCTAssertEqual(r(3, 0).minY - r(2, 1).maxY, 35, accuracy: 0.001)
        XCTAssertNil(table.headerViews[3])
    }

    /// tableprobe 3x: delegate heights 30 / 50 put the 20.333 label at
    /// y 3.667 / 23.667 (bottom pad 6). Golden "General"
    /// `_UITableViewHeaderFooterViewLabel [16, 3.667, 62, 20.333]` inside the
    /// content view at x 20 — abs 36.
    func testDelegateHeightHeaderLabelBottomAlignsWithSixPoints() {
        let source = FocusShapeSource()
        let (_, table) = makeTable(source)
        guard let general = table.headerViews[1] as? UITableViewHeaderFooterView,
              let privacy = table.headerViews[2] as? UITableViewHeaderFooterView else {
            return XCTFail("titled headers install a view")
        }
        general.layoutIfNeeded(); privacy.layoutIfNeeded()
        XCTAssertEqual(general.textLabel.frame.minY, 3.666667, accuracy: 0.001)
        XCTAssertEqual(general.textLabel.frame.height, 20.333333, accuracy: 0.001)
        XCTAssertEqual(general.textLabel.frame.minX, 36, accuracy: 0.001)
        XCTAssertEqual(privacy.textLabel.frame.minY, 23.666667, accuracy: 0.001)
    }

    /// Golden "Theme" `[20, 16, 53, 20.333]`, "Light" right edge 309 in the
    /// 309 pt content view (chevron accessory), chevron `[314.667, 17.667,
    /// 12.667, 16.667]`; "Set as Default Browser" (subtitle, no detail)
    /// `[20, 16, 173, 20.333]`; separator `[20, 51, 333, 1]`.
    func testAssignedContentMarginsPlaceTheClassicLabelsAndSeparator() {
        let source = FocusShapeSource()
        source.accessoryForRow = { [self] path in path.section == 1 || path == IndexPath(row: 0, section: 2) ? chevron() : nil }
        let (_, table) = makeTable(source)
        guard let theme = table.cellForRow(at: IndexPath(row: 0, section: 1)),
              let browser = table.cellForRow(at: IndexPath(row: 0, section: 0)),
              let tracking = table.cellForRow(at: IndexPath(row: 0, section: 2)) else {
            return XCTFail("cells are built")
        }
        theme.layoutIfNeeded(); browser.layoutIfNeeded(); tracking.layoutIfNeeded()
        XCTAssertEqual(theme.textLabel.frame.minX, 20, accuracy: 0.001)
        XCTAssertEqual(theme.textLabel.frame.minY, 16, accuracy: 0.001)
        XCTAssertEqual(theme.contentView.frame.width, 309, accuracy: 0.001)
        XCTAssertEqual(theme.detailTextLabel!.frame.maxX, 309, accuracy: 0.001)
        XCTAssertEqual(theme.accessoryView!.frame.minX, 314.666667, accuracy: 0.001)
        XCTAssertEqual(theme.accessoryView!.frame.minY, 17.666667, accuracy: 0.001)
        XCTAssertEqual(browser.textLabel.frame.minX, 20, accuracy: 0.001)
        XCTAssertEqual(browser.textLabel.frame.minY, 16, accuracy: 0.001)
        // Tracking is followed by a row: its separator spans 20 … 353.
        XCTAssertEqual(tracking.separatorView.frame.minX, 20, accuracy: 0.001)
        XCTAssertEqual(tracking.separatorView.frame.maxX, 353, accuracy: 0.001)
        XCTAssertEqual(tracking.separatorView.frame.minY, 51, accuracy: 0.001)
    }

    /// tableprobe 3x: a plain (non-symbol) 24 pt image view and a 71 pt
    /// UIView keep the right-edge-at-the-margin rule (x 309 / 262), while
    /// symbol image views of any width centre in the 24 pt slot (30 wide
    /// chevron at 306, gearshape 20.667 at 310.667).
    func testOnlySymbolImageAccessoriesTakeTheTwentyFourPointSlot() {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 393, height: 852))
        window.addSubview(cell)
        cell.frame = CGRect(x: 20, y: 0, width: 353, height: 52)

        let plain = UIImageView(image: UIImage(bitmap: Bitmap(width: 24, height: 24)))
        plain.frame = CGRect(x: 0, y: 0, width: 24, height: 24)
        cell.accessoryView = plain
        cell.layoutIfNeeded()
        XCTAssertEqual(plain.frame.minX, 309, accuracy: 0.001)
        XCTAssertEqual(cell.contentView.frame.width, 309, accuracy: 0.001)

        let box = UIView(frame: CGRect(x: 0, y: 0, width: 71, height: 28))
        cell.accessoryView = box
        cell.layoutIfNeeded()
        XCTAssertEqual(box.frame.minX, 262, accuracy: 0.001)
        XCTAssertEqual(cell.contentView.frame.width, 262, accuracy: 0.001)

        let wide = UIImageView(image: UIImage(systemName: "chevron.right"))
        wide.frame = CGRect(x: 0, y: 0, width: 30, height: 16.666667)
        cell.accessoryView = wide
        cell.layoutIfNeeded()
        XCTAssertEqual(wide.frame.minX, 306, accuracy: 0.001)
        XCTAssertEqual(cell.contentView.frame.width, 309, accuracy: 0.001)

        let gear = UIImageView(image: UIImage(systemName: "gearshape"))
        gear.frame = CGRect(x: 0, y: 0, width: 20.666667, height: 20)
        cell.accessoryView = gear
        cell.layoutIfNeeded()
        XCTAssertEqual(gear.frame.minX, 310.666667, accuracy: 0.001)
        XCTAssertEqual(gear.frame.minY, 16, accuracy: 0.001)
    }

    /// tableprobe (3x and 2x): a legacy system button with no image is at
    /// least 30 wide, and an empty title keeps the one-line box —
    /// 12 pt: no title 30 × 27, "abcd" 30 × 27, "abcdef" 40 × 27,
    /// "Learn more." 68 × 27; 17 pt no title 30 × 33. Focus's
    /// ActionFooterView footer is 71.667 = 8 + 28.667 + 27 + 8 with it.
    func testLegacyButtonMinimumWidthAndEmptyTitleHeight() {
        func button(_ title: String?, _ size: CGFloat) -> UIButton {
            let b = UIButton(type: .system)
            b.titleLabel?.font = .systemFont(ofSize: size)
            if let title { b.setTitle(title, for: .normal) }
            return b
        }
        XCTAssertEqual(button(nil, 12).intrinsicContentSize, CGSize(width: 30, height: 27))
        XCTAssertEqual(button("", 12).intrinsicContentSize, CGSize(width: 30, height: 27))
        XCTAssertEqual(button("abcd", 12).intrinsicContentSize, CGSize(width: 30, height: 27))
        XCTAssertEqual(button("abcdef", 12).intrinsicContentSize.height, 27)
        XCTAssertGreaterThan(button("abcdef", 12).intrinsicContentSize.width, 30)
        XCTAssertEqual(button("Learn more.", 12).intrinsicContentSize, CGSize(width: 68, height: 27))
        XCTAssertEqual(button(nil, 17).intrinsicContentSize, CGSize(width: 30, height: 33))
    }

    /// The Catalyst cut keeps its own numbers: an empty legacy button is
    /// 0 × 12 there and untitled headers stay 0 (golden/tableview_grouped).
    func testCatalystCutIsUntouched() {
        OpenUIKitRuntime.systemFontCut = .macOS
        UIScreen.main._hostConfigure(bounds: savedBounds, scale: savedScale)
        let b = UIButton(type: .system)
        b.titleLabel?.font = .systemFont(ofSize: 12)
        XCTAssertEqual(b.intrinsicContentSize.width, 0)
        XCTAssertEqual(b.intrinsicContentSize.height, 12)
    }
}
