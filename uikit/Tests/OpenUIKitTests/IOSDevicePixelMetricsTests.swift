// Carried-measurement tests for the iOS-cut rules measured on the iPhone SE
// (2x) and iPhone 16 (3x) simulators on 2026-09-04 (docs/REAL_APP_TEST.md,
// "The screen is the scene" and the rounds after it). Each case pins one
// number the real device produced; the Catalyst gate covers the other cut.
import XCTest
@testable import OpenUIKit

@MainActor
final class IOSDevicePixelMetricsTests: XCTestCase {
    private var savedCut: FontEngine.SystemFontCut!
    private var savedBounds: CGRect!
    private var savedScale: CGFloat!

    override func setUp() {
        super.setUp()
        savedCut = OpenUIKitRuntime.systemFontCut
        savedBounds = UIScreen.main.bounds
        savedScale = UIScreen.main.scale
        OpenUIKitRuntime.systemFontCut = .iOS
    }

    override func tearDown() {
        OpenUIKitRuntime.systemFontCut = savedCut
        UIScreen.main._hostConfigure(bounds: savedBounds, scale: savedScale)
        super.tearDown()
    }

    private func device(_ width: CGFloat, _ height: CGFloat, scale: CGFloat) {
        UIScreen.main._hostConfigure(bounds: CGRect(x: 0, y: 0, width: width, height: height), scale: scale)
    }

    // MARK: Device-pixel table metrics (tableview_grouped on both devices)

    func testGroupedTableMetricsFollowTheDevicePixel() {
        device(375, 667, scale: 2)
        XCTAssertEqual(UITableView.iOSLabelHeight17, 20.5, accuracy: 1e-9)
        XCTAssertEqual(UITableView.headerHeight(style: .insetGrouped, firstSection: true), 55.5, accuracy: 1e-9)
        XCTAssertEqual(UITableView.headerHeight(style: .insetGrouped, firstSection: false), 45.5, accuracy: 1e-9)
        XCTAssertEqual(UITableView.headerHeight(style: .insetGrouped, firstSection: true, compact: true), 38, accuracy: 1e-9)
        XCTAssertEqual(UITableView.headerHeight(style: .insetGrouped, firstSection: false, compact: true), 38, accuracy: 1e-9)
        XCTAssertEqual(UITableView.untitledGroupedFooterHeight, 17.5, accuracy: 1e-9)
        XCTAssertEqual(UITableViewCell.subtitleRowHeight, 69.5, accuracy: 1e-9)
        XCTAssertEqual(UITableViewCell.subtitlePrimaryY, 15.5, accuracy: 1e-9)
        XCTAssertEqual(UITableViewCell.disclosureSize.width, 10.5, accuracy: 1e-9)
        XCTAssertEqual(UITableViewCell.checkmarkSize.height, 18, accuracy: 1e-9)
        XCTAssertEqual(UITableView.valueCellPadding, 0)

        device(393, 852, scale: 3)
        XCTAssertEqual(UITableView.iOSLabelHeight17, 20.333333, accuracy: 1e-5)
        XCTAssertEqual(UITableView.headerHeight(style: .insetGrouped, firstSection: true), 55.333333, accuracy: 1e-5)
        XCTAssertEqual(UITableViewCell.subtitleRowHeight, 69.333333, accuracy: 1e-5)
        XCTAssertEqual(UITableViewCell.subtitlePrimaryY, 15.666667, accuracy: 1e-5)
        XCTAssertEqual(UITableViewCell.disclosureSize.width, 10.333333, accuracy: 1e-5)
        XCTAssertEqual(UITableViewCell.checkmarkSize.height, 17.333333, accuracy: 1e-5)
        XCTAssertEqual(UITableView.valueCellPadding, 2)
    }

    // MARK: System layout margin (inset-grouped card x 16 on the SE, 20 on the 16)

    func testInsetGroupedMarginFollowsTheWindowWidth() {
        XCTAssertEqual(UITableView.iOSSystemMargin(width: 375), 16)
        XCTAssertEqual(UITableView.iOSSystemMargin(width: 390), 20)
        XCTAssertEqual(UITableView.iOSSystemMargin(width: 393), 20)
        device(375, 667, scale: 2)
        let narrow = UITableView(frame: CGRect(x: 0, y: 0, width: 375, height: 600), style: .insetGrouped)
        XCTAssertEqual(narrow.insetGroupedSideInset, 16)
        XCTAssertEqual(narrow.plainTextInset, 16)
        let wide = UITableView(frame: CGRect(x: 0, y: 0, width: 393, height: 600), style: .insetGrouped)
        XCTAssertEqual(wide.insetGroupedSideInset, 20)
        XCTAssertEqual(wide.plainSeparatorInsets.left, 20)
        wide.insetGroupedSideInset = 8   // an explicit value still pins
        XCTAssertEqual(wide.insetGroupedSideInset, 8)
    }

    // MARK: UIStackView rounds both edges (stack_vertical on the SE)

    func testStackViewRoundsEdgesToTheDevicePixel() {
        device(200, 320, scale: 2)
        let stack = UIStackView(frame: CGRect(x: 10, y: 10, width: 180, height: 300))
        stack.axis = .vertical
        stack.spacing = 10
        stack.distribution = .fillEqually
        stack.alignment = .fill
        let views = (0..<3).map { _ in UIView() }
        views.forEach { stack.addArrangedSubview($0) }
        stack.layoutSubviews()
        // 280 / 3 = 93.333: edges at 103.333 -> 103.5, 113.333 -> 113.5,
        // 206.667 -> 206.5, 216.667 -> 216.5 (stack coordinates).
        XCTAssertEqual(views[0].frame, CGRect(x: 0, y: 0, width: 180, height: 93.5))
        XCTAssertEqual(views[1].frame, CGRect(x: 0, y: 103.5, width: 180, height: 93))
        XCTAssertEqual(views[2].frame, CGRect(x: 0, y: 206.5, width: 180, height: 93.5))
    }

    // MARK: Baseline anchor = ascender rounded to the pixel (constraints_baseline)

    func testLabelBaselineAnchorIsThePixelRoundedAscender() {
        device(320, 160, scale: 2)
        let big = UILabel(); big.font = .systemFont(ofSize: 28); big.text = "Big 28pt"
        let small = UILabel(); small.font = .systemFont(ofSize: 13); small.text = "small 13"
        XCTAssertEqual(big._constraintBaselines()!.firstFromTop, 26.5, accuracy: 1e-9)    // 26.66 -> 26.5
        XCTAssertEqual(small._constraintBaselines()!.firstFromTop, 12.5, accuracy: 1e-9)  // 12.38 -> 12.5
        let title = UILabel(); title.font = .systemFont(ofSize: 22); title.text = "Title 22"
        XCTAssertEqual(title._constraintBaselines()!.firstFromTop, 21, accuracy: 1e-9)    // 20.95 -> 21
    }

    // MARK: Bar items (navitem_dark, the five-image probe)

    func testImageBarItemsAndSharedPlatters() {
        device(393, 852, scale: 3)
        let img = UIImage(bitmap: Bitmap(width: 54, height: 54), scale: 3)   // 18 x 18 pt
        let a = _UIBarButtonItemView(item: UIBarButtonItem(image: img))
        let b = _UIBarButtonItemView(item: UIBarButtonItem(image: img))
        let title = _UIBarButtonItemView(item: UIBarButtonItem(title: "Reset"))
        XCTAssertEqual(a.sizeThatFits(.zero).width, 44)
        XCTAssertTrue(a.isImageOnly); XCTAssertFalse(title.isImageOnly)
        // 8 pt between two image views (16 between their buttons), 12 otherwise.
        XCTAssertEqual(_UIBarItemLayout.gapBefore([a, b], 1), 8)
        XCTAssertEqual(_UIBarItemLayout.gapBefore([a, title], 1), 12)
        let host = UIView(frame: CGRect(x: 0, y: 0, width: 393, height: 64))
        for v in [a, b, title] { host.addSubview(v) }
        a.frame = CGRect(x: 333, y: 10, width: 44, height: 44)
        b.frame = CGRect(x: 281, y: 10, width: 44, height: 44)
        title.frame = CGRect(x: 200, y: 10, width: 76.5, height: 44)
        let shared = _UIBarItemLayout.sharedPlatterFrames([a, b, title])
        XCTAssertEqual(shared, [CGRect(x: 281, y: 10, width: 96, height: 44)])
        XCTAssertTrue(a._platterHiddenByGroup && b._platterHiddenByGroup)
        XCTAssertFalse(title._platterHiddenByGroup)
    }

    // MARK: Large title (navbar_dark / navbar_large on the SE)

    func testLargeTitleMetricsUnderTheIOSCut() {
        XCTAssertEqual(UINavigationBar.largeTitleX, 16)
        XCTAssertEqual(UINavigationBar.largeTitleLabelY, 67.5)
        XCTAssertEqual(UINavigationBar.largeTitleLabelHeight, 41)
        XCTAssertEqual(UINavigationBar.iOSSnapCollapseDistance, 36)
        XCTAssertEqual(UINavigationBar.iOSCollapsedBarHeight, 64)
        OpenUIKitRuntime.systemFontCut = savedCut
        if savedCut != .iOS {
            XCTAssertEqual(UINavigationBar.largeTitleX, 20)
            XCTAssertEqual(UINavigationBar.largeTitleLabelHeight, 40.5)
        }
    }

    // MARK: Untitled grouped footers + compact headers (headerprobe / NavFlow)

    func testUntitledGroupedFooterAndCompactHeadersMatchHeaderprobe() {
        device(375, 667, scale: 2)
        let source = UntitledGroupedSource()
        let table = UITableView(frame: CGRect(x: 0, y: 0, width: 375, height: 667),
                                style: .insetGrouped)
        table.dataSource = source
        table.delegate = source
        table.layoutIfNeeded()

        // noNav: first header 55.5, untitled footer 17.5, later header 38.
        XCTAssertEqual(table.metrics[0].headerHeight, 55.5, accuracy: 1e-9)
        XCTAssertEqual(table.rectForRow(at: IndexPath(row: 0, section: 0)).minY, 55.5, accuracy: 1e-9)
        XCTAssertEqual(table.metrics[0].footerHeight, 17.5, accuracy: 1e-9)
        XCTAssertFalse(table.metrics[0].footerHasView)
        XCTAssertEqual(table.metrics[1].headerY, 205, accuracy: 1e-9)
        XCTAssertEqual(table.metrics[1].headerHeight, 38, accuracy: 1e-9)
        XCTAssertTrue(table.metrics[1].compactHeader)
        XCTAssertEqual(table.rectForRow(at: IndexPath(row: 0, section: 1)).minY, 243, accuracy: 1e-9)
        XCTAssertNil(table.footerViews[0], "untitled footer is spacing, no view")

        table._setSafeAreaInsets(UIEdgeInsets(top: 116, left: 0, bottom: 0, right: 0))
        table.layoutIfNeeded()
        // navLarge: first header compact 38, later still 38 after untitled footer.
        XCTAssertEqual(table.metrics[0].headerHeight, 38, accuracy: 1e-9)
        XCTAssertTrue(table.metrics[0].compactHeader)
        XCTAssertEqual(table.rectForRow(at: IndexPath(row: 0, section: 0)).minY, 38, accuracy: 1e-9)
        XCTAssertEqual(table.metrics[1].headerY, 187.5, accuracy: 1e-9)
        XCTAssertEqual(table.metrics[1].headerHeight, 38, accuracy: 1e-9)
        XCTAssertEqual(table.rectForRow(at: IndexPath(row: 0, section: 1)).minY, 225.5, accuracy: 1e-9)
    }
}

@MainActor
private final class UntitledGroupedSource: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int { 2 }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? 3 : 2
    }
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        section == 0 ? "General" : "Storage"
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        UITableViewCell(style: .value1, reuseIdentifier: nil)
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 44 }
}
