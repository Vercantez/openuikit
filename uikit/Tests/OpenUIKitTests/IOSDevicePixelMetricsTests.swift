// Carried-measurement tests for the iOS-cut rules measured on the iPhone SE
// (2x) and iPhone 16 (3x) simulators on 2026-09-04 (docs/REAL_APP_TEST.md,
// "The screen is the scene" and the rounds after it). Each case pins one
// number the real device produced; the Catalyst gate covers the other cut.
import XCTest
@testable import OpenUIKit

#if !os(Linux)
@MainActor
#endif
final class IOSDevicePixelMetricsTests: XCTestCase {
    private var savedCut: FontEngine.SystemFontCut!
    private var savedBounds: CGRect!
    private var savedScale: CGFloat!
    private var savedIdiom: UIUserInterfaceIdiom!
    private var savedTraits: UITraitCollection!

    override func setUp() {
        super.setUp()
        savedCut = OpenUIKitRuntime.systemFontCut
        savedBounds = UIScreen.main.bounds
        savedScale = UIScreen.main.scale
        savedIdiom = UIDevice.current.userInterfaceIdiom
        savedTraits = UITraitCollection.current
        OpenUIKitRuntime.systemFontCut = .iOS
    }

    override func tearDown() {
        OpenUIKitRuntime.systemFontCut = savedCut
        UIScreen.main._hostConfigure(bounds: savedBounds, scale: savedScale)
        UIDevice.current.userInterfaceIdiom = savedIdiom
        UITraitCollection.current = savedTraits
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
        XCTAssertEqual(UITableViewCell.plainSubtitleRowHeight, 62, accuracy: 1e-9)
        XCTAssertEqual(UITableViewCell.subtitlePrimaryY, 15.5, accuracy: 1e-9)
        XCTAssertEqual(UITableViewCell.plainSubtitlePrimaryY, 9, accuracy: 1e-9)
        XCTAssertEqual(UITableViewCell.plainSubtitleDetailY, 32.5, accuracy: 1e-9)
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

        // MEASURED ipadprobe navLargeTable, iPad (A16) 820×1180 @2x: the
        // inset-grouped card is at x 20, 780 wide — the same 20 pt system
        // margin as a 390+ phone, not a larger readable-width inset.
        XCTAssertEqual(UITableView.iOSSystemMargin(width: 820), 20)
        device(820, 1180, scale: 2)
        let pad = UITableView(frame: CGRect(x: 0, y: 0, width: 820, height: 1180), style: .insetGrouped)
        XCTAssertEqual(pad.insetGroupedSideInset, 20)
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
        XCTAssertEqual(UINavigationBar.largeTitleLabelY, 57.5)
        XCTAssertEqual(UINavigationBar.largeTitleLabelHeight, 41)
        XCTAssertEqual(UINavigationBar.iOSSnapCollapseDistance, 36)
        XCTAssertEqual(UINavigationBar.iOSCollapsedBarHeight, 54)
        XCTAssertEqual(UINavigationBar.iOSBarContentHeight, 54)
        XCTAssertEqual(UINavigationBar.iOSLargeTitleBarHeight, 106)
        XCTAssertEqual(UINavigationBar.iOSMinimumBarTop, 10)
        XCTAssertEqual(UINavigationBar.iOSCompactHeightBarTop, 24)

        // MEASURED NavFlow t200.ax1 / TableEditor t200.ax1, iPhone SE 2x /
        // iOS 26.1: 48 pt Bold, label 57.5, zone 61.5, bar 115.5, inset 125.5.
        device(375, 667, scale: 2)
        let ax1 = UITraitCollection(preferredContentSizeCategory: .accessibilityLarge)
        XCTAssertEqual(UINavigationBar.largeTitleFont(compatibleWith: ax1).pointSize, 48)
        XCTAssertEqual(UINavigationBar.largeTitleLabelHeight(compatibleWith: ax1), 57.5)
        XCTAssertEqual(UINavigationBar.largeTitleLabelY(compatibleWith: ax1), 54)
        XCTAssertEqual(UINavigationBar.iOSLargeTitleBarHeight(compatibleWith: ax1), 115.5)
        XCTAssertEqual(UINavigationBar.largeTitleExpandedInset(compatibleWith: ax1), 125.5)
        XCTAssertEqual(
            UIFontMetrics(forTextStyle: .body).scaledValue(for: 44, compatibleWith: ax1),
            80)
        XCTAssertEqual(UITableViewCell.plainClassicRowHeight(compatibleWith: ax1), 80)
        let actionFont = UIAlertMetrics.actionFont(compatibleWith: ax1)
        XCTAssertEqual(actionFont.pointSize, 33)
        XCTAssertEqual(UIAlertMetrics.actionHeight(for: actionFont, compatibleWith: ax1), 63.5)
        let xxxl = UITraitCollection(preferredContentSizeCategory: .extraExtraExtraLarge)
        XCTAssertEqual(UITableViewCell.plainClassicRowHeight(compatibleWith: xxxl), 59)
        let xxxlAction = UIAlertMetrics.actionFont(compatibleWith: xxxl)
        XCTAssertEqual(xxxlAction.pointSize, 23)
        XCTAssertEqual(UIAlertMetrics.actionHeight(for: xxxlAction, compatibleWith: xxxl), 48)
        XCTAssertEqual(UIAlertMetrics.actionStackHeight(count: 5, actionH: 48), 304)
        XCTAssertEqual(
            UIFontMetrics(forTextStyle: .body).scaledValue(for: 44, compatibleWith: xxxl),
            58)
        XCTAssertEqual(UINavigationBar.iOSLargeTitleBarHeight(compatibleWith: xxxl), 108)
        XCTAssertEqual(UINavigationBar.largeTitleExpandedInset(compatibleWith: xxxl), 118)
        let titleFont = UIAlertMetrics.titleFont(compatibleWith: ax1)
        XCTAssertEqual(titleFont.pointSize, 33)
        let messageFont = UIAlertMetrics.messageFont(compatibleWith: ax1)
        XCTAssertEqual(messageFont.pointSize, 30)
        XCTAssertEqual(
            UIAlertMetrics.labelBoxHeight(for: messageFont, lines: 2,
                                          oneLine: 18, pitch: 20),
            72)

        // prefersLargeTitles is set before the bar joins the window, as
        // NavFlow's makeRoot does. Layout must pick up 48 pt from the
        // window override, not keep the construction-time 34 pt font.
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 667))
        window.traitOverrides.preferredContentSizeCategory = .accessibilityLarge
        let bar = UINavigationBar(frame: CGRect(x: 0, y: 10, width: 375, height: 106))
        bar.prefersLargeTitles = true
        bar.setState(title: "Library", backTitle: nil)
        XCTAssertEqual(bar.largeTitleLabel?.font.pointSize, 34)
        window.addSubview(bar)
        bar.setNeedsLayout()
        bar.layoutIfNeeded()
        XCTAssertEqual(bar.largeTitleLabel?.font.pointSize, 48)
        XCTAssertEqual(bar.largeTitleLabel?.frame.height, 57.5)

        // MEASURED Modal t5200.ax1: action label 33 Medium in a 63.5 pill.
        // `_layoutCard` styles actions from the presenting view's traits.
        let root = UIViewController()
        window.rootViewController = root
        window.makeKeyAndVisible()
        let alert = UIAlertController(title: "Save changes?",
                                      message: "This cannot be undone.",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Save", style: .default))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        root.present(alert, animated: false)
        let pill = alert.actionViews.first
        XCTAssertEqual(pill?.label.font.pointSize, 33)
        XCTAssertEqual(pill?.bounds.height, 63.5)

        root.dismiss(animated: false)
        // MEASURED Modal t7200.ax1, iPhone SE 2x / iOS 26.1: headerless
        // action sheet PhoneTVMacView **304** with 63.5 pills clipped
        // (separatable sequence 381.5). t7200.xxxl pills stay 48 in the
        // same 304 card.
        let sheet = UIAlertController(title: nil, message: nil,
                                      preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "Copy", style: .default))
        sheet.addAction(UIAlertAction(title: "Share", style: .default))
        sheet.addAction(UIAlertAction(title: "Favorite", style: .default))
        sheet.addAction(UIAlertAction(title: "Delete", style: .destructive))
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        root.present(sheet, animated: false)
        XCTAssertEqual(sheet.actionViews.first?.label.font.pointSize, 33)
        XCTAssertEqual(sheet.actionViews.first?.bounds.height, 63.5)
        XCTAssertEqual(sheet.view.bounds.height, 304)
        XCTAssertTrue(sheet.view.clipsToBounds)

        OpenUIKitRuntime.systemFontCut = savedCut
        if savedCut != .iOS {
            XCTAssertEqual(UINavigationBar.largeTitleX, 20)
            XCTAssertEqual(UINavigationBar.largeTitleLabelHeight, 40.5)
        }
    }

    /// MEASURED NavFlow-ipad t200 / TableEditor-ipad t200, iPad (A16)
    /// 820×1180 @2x / iOS 26.1: table `safeAreaInsets.top` **138** =
    /// 32 + 54 + 52; phone stays 116 = 10 + 54 + 52.
    func testPadLargeTitleExpandedInsetIs138() {
        XCTAssertEqual(UINavigationBar.largeTitleExpandedInset, 116)
        UIDevice.current.userInterfaceIdiom = .pad
        UITraitCollection.current = UITraitCollection(
            userInterfaceStyle: .light, displayScale: 2, userInterfaceIdiom: .pad)
        XCTAssertEqual(UINavigationBar.largeTitleExpandedInset, 138)
        UIDevice.current.userInterfaceIdiom = .phone
        UITraitCollection.current = UITraitCollection(
            userInterfaceStyle: .light, displayScale: 2, userInterfaceIdiom: .phone)
        XCTAssertEqual(UINavigationBar.largeTitleExpandedInset, 116)
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

        // navLarge: first header compact 38. MEASURED headerprobe; the
        // discriminator is `displaysLargeTitles` (Notes t6000 SA.top 124
        // without large titles stays 55.5). Bare SA.top=116 is not enough.
        let host = UIViewController()
        host.view.addSubview(table)
        let nav = UINavigationController(rootViewController: host)
        nav.navigationBar.prefersLargeTitles = true
        host.navigationItem.largeTitleDisplayMode = .always
        table._setSafeAreaInsets(UIEdgeInsets(top: 116, left: 0, bottom: 0, right: 0))
        table.layoutIfNeeded()
        XCTAssertTrue(nav.navigationBar.displaysLargeTitles)
        XCTAssertEqual(table.metrics[0].headerHeight, 38, accuracy: 1e-9)
        XCTAssertTrue(table.metrics[0].compactHeader)
        XCTAssertEqual(table.rectForRow(at: IndexPath(row: 0, section: 0)).minY, 38, accuracy: 1e-9)
        XCTAssertEqual(table.metrics[1].headerY, 187.5, accuracy: 1e-9)
        XCTAssertEqual(table.metrics[1].headerHeight, 38, accuracy: 1e-9)
        XCTAssertEqual(table.rectForRow(at: IndexPath(row: 0, section: 1)).minY, 225.5, accuracy: 1e-9)
    }

    /// MEASURED NavFlow t200.landscape vs Notes t4000.xxxl, iPhone SE 2x /
    /// iOS 26.1: compact-height rest SA.top **78** (= 24+54) must keep the
    /// 55.5 first header (a `> 10+54` compare treated 78 as a search
    /// overlay and dropped t200.landscape 96.71 → 81.13). xxxl search
    /// overlay SA.top **84** (table y 84) is compact **38**.
    func testCompactHeightRestDoesNotCompactInsetGroupedFirstHeader() {
        device(667, 375, scale: 2)
        let source = UntitledGroupedSource()
        let table = UITableView(frame: CGRect(x: 0, y: 0, width: 667, height: 375),
                                style: .insetGrouped)
        table.dataSource = source
        table.delegate = source
        UITraitCollection.current = UITraitCollection(
            userInterfaceStyle: .light, displayScale: 2,
            horizontalSizeClass: .compact, verticalSizeClass: .compact)
        table._setSafeAreaInsets(UIEdgeInsets(top: 78, left: 0, bottom: 0, right: 0))
        table.layoutIfNeeded()
        XCTAssertEqual(table.metrics[0].headerHeight, 55.5, accuracy: 1e-9)
        XCTAssertFalse(table.metrics[0].compactHeader)

        // Notes replaced the SA.top overlay heuristic with overflow compact
        // under tab-hosted search. xxxl SA.top 84 without a search
        // controller (this table) stays 55.5; Notes t200.xxxl compact 38
        // is the overflow path (`searchOverflowCompact`).
        UITraitCollection.current = UITraitCollection(
            userInterfaceStyle: .light, displayScale: 2,
            preferredContentSizeCategory: .extraExtraExtraLarge)
        table._setSafeAreaInsets(UIEdgeInsets(top: 84, left: 0, bottom: 0, right: 0))
        table.layoutIfNeeded()
        XCTAssertEqual(table.metrics[0].headerHeight, 55.5, accuracy: 1e-9)
        XCTAssertFalse(table.metrics[0].compactHeader)
    }

    // MARK: Compact pageSheet top inset (probe_sheet_inset / NavFlow t1200)

    /// MEASURED 2026-09-04, probe_sheet_inset on the iPhone SE 2x / iOS 26.1:
    /// `UIDropShadowView` `[0, 30, 375, 637]` at windowSafeArea.top 0 and 20.
    /// The iPhone 16 surface (393×852, zero modelled safe area) keeps 59.
    func testCompactPhoneSheetTopInsetIsThirty() {
        device(375, 667, scale: 2)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 667))
        let base = UIViewController()
        base.view.frame = window.bounds
        window.addSubview(base.view)
        let sheet = UIViewController()
        sheet.view.backgroundColor = .systemBackground
        base.present(sheet, animated: false)
        XCTAssertEqual(sheet._presentationSheet!.frame,
                       CGRect(x: 0, y: 30, width: 375, height: 637))

        device(393, 852, scale: 3)
        let phone16 = UIWindow(frame: CGRect(x: 0, y: 0, width: 393, height: 852))
        let base16 = UIViewController()
        base16.view.frame = phone16.bounds
        phone16.addSubview(base16.view)
        let sheet16 = UIViewController()
        sheet16.view.backgroundColor = .systemBackground
        base16.present(sheet16, animated: false)
        XCTAssertEqual(sheet16._presentationSheet!.frame,
                       CGRect(x: 0, y: 59, width: 393, height: 793))
    }

    /// MEASURED `/tmp/ipad-open-cap` sheet_{white,black,red,grad} +
    /// NavFlow-ipad t1200 / Modal-ipad t3200, iPad (A16) 820×1180 @2x /
    /// iOS 26.1: `UIDropShadowView [0, 42, 820, 1138]`. Window SA.top is 32.
    func testPadPageSheetTopInsetIsFortyTwo() {
        UIDevice.current.userInterfaceIdiom = .pad
        UITraitCollection.current = UITraitCollection(
            userInterfaceStyle: .light, displayScale: 2, userInterfaceIdiom: .pad)
        device(820, 1180, scale: 2)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 820, height: 1180))
        window._setSafeAreaInsets(UIEdgeInsets(top: 32, left: 0, bottom: 25, right: 0))
        let base = UIViewController()
        window.rootViewController = base
        window.makeKeyAndVisible()
        let sheet = UIViewController()
        sheet.view.backgroundColor = .systemBackground
        sheet.modalPresentationStyle = .pageSheet
        base.present(sheet, animated: false)
        XCTAssertEqual(_UIPageSheetView.iOSPadTopInset, 42)
        XCTAssertEqual(_UIPageSheetView.topInset(in: window), 42)
        XCTAssertEqual(sheet._presentationSheet!.frame,
                       CGRect(x: 0, y: 42, width: 820, height: 1138))
        UIDevice.current.userInterfaceIdiom = .phone
        UITraitCollection.current = UITraitCollection(
            userInterfaceStyle: .light, displayScale: 2, userInterfaceIdiom: .phone)
    }

    /// MEASURED Modal t1200.landscape / t3200.landscape, iPhone SE 2x /
    /// iOS 26.1: compact height makes both medium and large pageSheets
    /// `[0, 0, 667, 375]`. Portrait SE (unspecified vertical) stays 30.
    func testCompactHeightPageSheetFillsTheWindow() {
        UIDevice.current.userInterfaceIdiom = .phone
        UITraitCollection.current = UITraitCollection(
            userInterfaceStyle: .light,
            displayScale: 2,
            horizontalSizeClass: .compact,
            verticalSizeClass: .compact)
        device(667, 375, scale: 2)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 667, height: 375))
        let base = UIViewController()
        window.rootViewController = base
        window.makeKeyAndVisible()

        let large = UIViewController()
        large.modalPresentationStyle = .pageSheet
        large.sheetPresentationController?.detents = [.large()]
        large.sheetPresentationController?.selectedDetentIdentifier = .large
        base.present(large, animated: false)
        XCTAssertEqual(large.sheetPresentationController!.frameOfPresentedViewInContainerView,
                       CGRect(x: 0, y: 0, width: 667, height: 375))
        base.dismiss(animated: false)

        let medium = UIViewController()
        medium.modalPresentationStyle = .pageSheet
        medium.sheetPresentationController?.detents = [.medium(), .large()]
        base.present(medium, animated: false)
        XCTAssertEqual(medium.sheetPresentationController!.frameOfPresentedViewInContainerView,
                       CGRect(x: 0, y: 0, width: 667, height: 375))
    }

    // MARK: iPad formSheet (ipadprobe / realapp_settings_light_ipad)

    /// MEASURED ipadprobe on iPad (A16) 820×1180 @2x / iOS 26.1:
    /// `.formSheet` default `[120, 260, 580, 650]`; custom detent 343
    /// `[120, 567, 580, 343]` (same bottom edge 910). Not a pageSheet
    /// floating card. Inline nav bar is still 54 pt (bar `[0, 32, 820, 54]`),
    /// not the pre-iOS-26 regular-width 50.
    func testPadFormSheetIsCentredCardNotPageSheet() {
        let savedIdiom = UIDevice.current.userInterfaceIdiom
        let savedTraits = UITraitCollection.current
        defer {
            UIDevice.current.userInterfaceIdiom = savedIdiom
            UITraitCollection.current = savedTraits
        }
        device(820, 1180, scale: 2)
        UIDevice.current.userInterfaceIdiom = .pad
        UITraitCollection.current = UITraitCollection(
            userInterfaceStyle: .light, displayScale: 2, userInterfaceIdiom: .pad)

        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 820, height: 1180))
        window._setSafeAreaInsets(UIEdgeInsets(top: 32, left: 0, bottom: 25, right: 0))
        let base = UIViewController()
        window.rootViewController = base
        window.makeKeyAndVisible()

        let large = UIViewController()
        large.view.backgroundColor = .white
        large.modalPresentationStyle = .formSheet
        base.present(large, animated: false)
        XCTAssertEqual(large._presentationSheet!.frame,
                       CGRect(x: 120, y: 260, width: 580, height: 650))
        XCTAssertEqual(large._presentationDim?.alpha ?? 0, 0.2, accuracy: 1e-9)
        base.dismiss(animated: false)

        let custom = UIViewController()
        custom.view.backgroundColor = .white
        custom.modalPresentationStyle = .formSheet
        custom.sheetPresentationController?.detents = [
            .custom { ctx in
                XCTAssertEqual(ctx.maximumDetentValue, 650, accuracy: 1e-9)
                return 343
            }
        ]
        base.present(custom, animated: false)
        XCTAssertEqual(custom._presentationSheet!.frame,
                       CGRect(x: 120, y: 567, width: 580, height: 343))
        XCTAssertEqual(custom._presentationSheet!.layer.cornerRadius, 32)
        XCTAssertEqual(custom._presentationDim?.alpha ?? 0, 0.2, accuracy: 1e-9)
    }

    /// MEASURED realapp_storage_light_ipad, iPad (A16) 820×1180 @2x /
    /// iOS 26.1: large-title label x **20** (phone iOS stays 16); grouped
    /// cell layoutMargins horizontal **16** (phone 393 stays 20); inset-
    /// grouped card x stays **20**.
    func testPadLargeTitleXAndGroupedCellMargin() {
        XCTAssertEqual(UINavigationBar.largeTitleX, 16)
        let phoneCell = UITableViewCell(style: .default, reuseIdentifier: nil)
        // No window: iOSMargin falls back to bounds width (0 → 16).
        device(393, 852, scale: 3)
        let phone = UITableView(frame: CGRect(x: 0, y: 0, width: 393, height: 600), style: .grouped)
        XCTAssertEqual(phone.insetGroupedSideInset, 20)

        UIDevice.current.userInterfaceIdiom = .pad
        UITraitCollection.current = UITraitCollection(
            userInterfaceStyle: .light, displayScale: 2, userInterfaceIdiom: .pad)
        device(820, 1180, scale: 2)
        XCTAssertEqual(UINavigationBar.largeTitleX, 20)
        XCTAssertEqual(UITableView.iOSPadCellMargin, 16)
        let padCell = UITableViewCell(style: .default, reuseIdentifier: nil)
        XCTAssertEqual(padCell.iOSMargin, 16)
        // Bare cell in the 820 pt window still reports 16 (storage xib
        // SwitchCell). Forms-ipad fields at x 20 are a second sample that
        // does not fit this default — OPEN, not a 20 override (that drop
        // was realapp_storage_light_ipad 99.689 → 99.554).
        let padWindow = UIWindow(frame: CGRect(x: 0, y: 0, width: 820, height: 1180))
        let padGrouped = UITableView(frame: padWindow.bounds, style: .grouped)
        padWindow.addSubview(padGrouped)
        padGrouped.addSubview(padCell)
        padCell.frame = CGRect(x: 0, y: 0, width: 820, height: 44)
        XCTAssertEqual(padCell.layoutMargins.left, 16)
        XCTAssertEqual(padCell.layoutMargins.right, 16)
        XCTAssertEqual(padCell.layoutMargins.top, 15)
        XCTAssertEqual(padGrouped.iOSMargin, 20, "inset-grouped / table chrome stays 20")
        let padInset = UITableView(frame: CGRect(x: 0, y: 0, width: 820, height: 1180), style: .insetGrouped)
        XCTAssertEqual(padInset.insetGroupedSideInset, 20)
        XCTAssertEqual(padInset.groupedTextInset, 20)
        XCTAssertEqual(padInset.groupedHeaderLabelX,
                       padInset.insetGroupedSideInset + 20)
        XCTAssertEqual(padGrouped.groupedTextInset, 16)
        let insetCell = UITableViewCell(style: .default, reuseIdentifier: nil)
        insetCell.tableView = padInset
        XCTAssertEqual(insetCell.iOSMargin, 20)
        XCTAssertEqual(insetCell.layoutMargins.left, 20)
        let groupedCell = UITableViewCell(style: .default, reuseIdentifier: nil)
        groupedCell.tableView = padGrouped
        XCTAssertEqual(groupedCell.iOSMargin, 16)

        UIDevice.current.userInterfaceIdiom = .phone
        UITraitCollection.current = UITraitCollection(
            userInterfaceStyle: .light, displayScale: 3, userInterfaceIdiom: .phone)
        XCTAssertEqual(UINavigationBar.largeTitleX, 16)
        _ = phoneCell
    }

    // MARK: iPad popover (Modal-ipad t7200 / t9200)

    /// MEASURED Modal-ipad t9200, iPad (A16) 820×1180 @2x / iOS 26.1:
    /// `_UIPopoverView [561, 62, 240, 180]` = preferredContentSize, trailing
    /// inset 19 (`820 − 240 − 561`), y = SA.top + 30. Phone still adapts.
    func testPadPopoverDoesNotAdaptToASheet() {
        UIDevice.current.userInterfaceIdiom = .pad
        UITraitCollection.current = UITraitCollection(
            userInterfaceStyle: .light, displayScale: 2, userInterfaceIdiom: .pad)
        device(820, 1180, scale: 2)

        let vc = UIViewController()
        vc.modalPresentationStyle = .popover
        vc.preferredContentSize = CGSize(width: 240, height: 180)
        let popover = try! XCTUnwrap(vc.popoverPresentationController)
        XCTAssertEqual(popover.adaptedStyle, .popover)
        XCTAssertEqual(vc._resolvedPresentationStyle, .popover)

        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 820, height: 1180))
        window._setSafeAreaInsets(UIEdgeInsets(top: 32, left: 0, bottom: 25, right: 0))
        let base = UIViewController()
        window.rootViewController = base
        window.makeKeyAndVisible()
        vc.view.backgroundColor = .systemBackground
        base.present(vc, animated: false)
        XCTAssertNil(vc._presentationSheet)
        XCTAssertEqual(vc.view.frame,
                       CGRect(x: 561, y: 62, width: 240, height: 180))
        XCTAssertTrue(vc.view._usesIOSGlass)
        XCTAssertEqual(vc.view._iosGlassKind, .padContentPopover)
        XCTAssertEqual(_UIGlassMaterial.padContentPopoverMixAlpha, 218.0 / 255.0, accuracy: 1e-12)
        XCTAssertEqual(_UIGlassMaterial.padContentPopoverTintGray, 215.0 / 218.0, accuracy: 1e-12)
    }

    /// MEASURED Modal-ipad t7200: `_UIPopoverView [266, 466, 288, 248]`,
    /// 4 pills (cancel dropped), centred on sourceRect (410, 590), dim 0.
    /// Phone action sheet stays the 320×304 card.
    func testPadActionSheetPopoverDropsCancelAndIs288() {
        UIDevice.current.userInterfaceIdiom = .pad
        UITraitCollection.current = UITraitCollection(
            userInterfaceStyle: .light, displayScale: 2, userInterfaceIdiom: .pad)
        device(820, 1180, scale: 2)

        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 820, height: 1180))
        window._setSafeAreaInsets(UIEdgeInsets(top: 32, left: 0, bottom: 25, right: 0))
        let base = UIViewController()
        window.rootViewController = base
        window.makeKeyAndVisible()
        base.view.layoutIfNeeded()

        let sheet = UIAlertController(title: nil, message: nil,
                                      preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "Copy", style: .default))
        sheet.addAction(UIAlertAction(title: "Share", style: .default))
        sheet.addAction(UIAlertAction(title: "Favorite", style: .default))
        sheet.addAction(UIAlertAction(title: "Delete", style: .destructive))
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        if let popover = sheet.popoverPresentationController {
            popover.sourceView = base.view
            popover.sourceRect = CGRect(x: 410, y: 590, width: 1, height: 1)
        }
        base.present(sheet, animated: false)
        XCTAssertEqual(sheet.view.frame,
                       CGRect(x: 266, y: 466, width: 288, height: 248))
        XCTAssertEqual(sheet.actionViews.count, 4)
        let dim = sheet.presentationController?.containerView?.subviews
            .first { $0 is _UIDimmingView }
        XCTAssertEqual(dim?.alpha ?? -1, 0, accuracy: 1e-9)
        XCTAssertTrue(sheet.view._usesIOSGlass)
        XCTAssertEqual(sheet.view._iosGlassKind, .padActionSheetPopover)
        let shadow = sheet.presentationController?.containerView?.subviews
            .compactMap { $0 as? _UIAlertShadowView }.first
        XCTAssertEqual(shadow?.frame,
                       CGRect(x: 266 - 150, y: 466 - 150,
                              width: 288 + 300, height: 248 + 300))
        XCTAssertEqual(shadow?.shadowOffsetY, 0)
        XCTAssertEqual(shadow?.shadowAlpha ?? -1, 21.0 / 255.0, accuracy: 1e-12)
        XCTAssertEqual(_UIGlassMaterial.padActionSheetMixAlpha, 187.0 / 255.0, accuracy: 1e-12)
        XCTAssertEqual(_UIGlassMaterial.padActionSheetTintGray, 178.0 / 187.0, accuracy: 1e-12)
    }

    // MARK: iPad tab bar (Tabs-ipad t200 / t1000 / t2000)

    /// MEASURED Tabs-ipad t200, iPad (A16) 820×1180 @2x / iOS 26.1:
    /// `_UIFloatingTabBar [0, 32, 820, 44]`; child bottom inset is window
    /// SA 25, not the phone 83. Non-nav children start at y **96**.
    func testPadTabBarIsTopStripAndDoesNotStealBottomInset() {
        UIDevice.current.userInterfaceIdiom = .pad
        UITraitCollection.current = UITraitCollection(
            userInterfaceStyle: .light, displayScale: 2, userInterfaceIdiom: .pad)
        device(820, 1180, scale: 2)

        let tab = UITabBarController()
        let plain = UIViewController()
        plain.tabBarItem = UITabBarItem(title: "Tools", image: nil, tag: 0)
        tab.viewControllers = [plain]
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 820, height: 1180))
        window._setSafeAreaInsets(UIEdgeInsets(top: 32, left: 0, bottom: 25, right: 0))
        window.rootViewController = tab
        window.layoutIfNeeded()

        XCTAssertEqual(UITabBar.barHeight, 44)
        XCTAssertEqual(tab.tabBar.frame,
                       CGRect(x: 0, y: 32, width: 820, height: 44))
        XCTAssertEqual(tab.transitionView.safeAreaInsets.bottom, 25)
        XCTAssertEqual(tab.transitionView.safeAreaInsets.top, 96)
    }

    /// MEASURED Tabs-ipad t200: title-only pills packed by intrinsic + 16
    /// and centred; (820 − 237) / 2 = 291.5 for Library/Tools/Scroll.
    func testPadTabBarItemsPackByTitleAndCenter() {
        UIDevice.current.userInterfaceIdiom = .pad
        UITraitCollection.current = UITraitCollection(
            userInterfaceStyle: .light, displayScale: 2, userInterfaceIdiom: .pad)
        device(820, 1180, scale: 2)

        let tab = UITabBarController()
        let a = UIViewController(); a.tabBarItem = UITabBarItem(title: "Library", image: nil, tag: 0)
        let b = UIViewController(); b.tabBarItem = UITabBarItem(title: "Tools", image: nil, tag: 1)
        b.tabBarItem?.badgeValue = "3"
        let c = UIViewController(); c.tabBarItem = UITabBarItem(title: "Scroll", image: nil, tag: 2)
        tab.viewControllers = [a, b, c]
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 820, height: 1180))
        window._setSafeAreaInsets(UIEdgeInsets(top: 32, left: 0, bottom: 25, right: 0))
        window.rootViewController = tab
        window.layoutIfNeeded()

        XCTAssertEqual(tab.tabBar.itemViews.count, 3)
        XCTAssertEqual(tab.tabBar.itemViews[0].frame.minY, 4)
        XCTAssertEqual(tab.tabBar.itemViews[0].frame.height, 36)
        let total = tab.tabBar.itemViews.reduce(CGFloat(0)) { $0 + $1.frame.width }
        XCTAssertEqual(tab.tabBar.itemViews[0].frame.minX,
                       (820 - total) / 2, accuracy: 0.5)
        XCTAssertFalse(tab.tabBar.itemViews[1].badgeView.isHidden)
        XCTAssertEqual(tab.tabBar.itemViews[1].badgeView.frame.size,
                       CGSize(width: 18.5, height: 18.5))
    }

    /// MEASURED Tabs-ipad t200 / t4000, iPad (A16) 820×1180 @2x / iOS 26.1:
    /// rest search `[565, 0, 240, 44]` bar-local (trailing 15);
    /// active **280** wide, same trailing; tab bar y = −32; nav stays 54.
    func testPadHostedSearchIsTrailing240AndHidesTabBarWhenActive() {
        UIDevice.current.userInterfaceIdiom = .pad
        UITraitCollection.current = UITraitCollection(
            userInterfaceStyle: .light, displayScale: 2, userInterfaceIdiom: .pad)
        device(820, 1180, scale: 2)

        let root = UIViewController()
        root.title = "Library"
        let sc = UISearchController(searchResultsController: nil)
        sc.obscuresBackgroundDuringPresentation = false
        root.navigationItem.searchController = sc
        let nav = UINavigationController(rootViewController: root)
        root.tabBarItem = UITabBarItem(title: "Library", image: nil, tag: 0)
        let tab = UITabBarController()
        tab.viewControllers = [nav]
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 820, height: 1180))
        window._setSafeAreaInsets(UIEdgeInsets(top: 32, left: 0, bottom: 25, right: 0))
        window.rootViewController = tab
        window.layoutIfNeeded()

        let bar = nav.navigationBar.hostedSearchBar
        XCTAssertEqual(bar?.frame, CGRect(x: 565, y: 0, width: 240, height: 44))
        XCTAssertEqual(bar?.searchTextField.frame,
                       CGRect(x: 0, y: 0, width: 240, height: 44))
        XCTAssertEqual(nav.navigationBar.titleLabel.alpha, 0)
        XCTAssertTrue(nav.navigationBar.titleLabel.isHidden)
        XCTAssertEqual(tab.tabBar.frame.minY, 32)
        XCTAssertEqual(nav.navigationBar.bounds.height, 54)
        // MEASURED Tabs-ipad t7000: golden offset stays 200 (inline
        // search, no overlay slot). Phone t7000 is 260. Sample while
        // `!isActive` — the active-search guard also returns 0.
        XCTAssertEqual(nav.navigationBar.hideOnScrollContentBump(requestedY: 200), 0)

        sc.isActive = true
        window.layoutIfNeeded()
        XCTAssertEqual(bar?.frame, CGRect(x: 525, y: 0, width: 280, height: 44))
        XCTAssertEqual(tab.tabBar.frame,
                       CGRect(x: 0, y: -32, width: 820, height: 44))
        XCTAssertEqual(nav.navigationBar.bounds.height, 54)
        XCTAssertEqual(nav.navigationBar.searchOverlayHeight, 0)
    }

    // MARK: Compact-height phone tab bar (Tabs t200.landscape + Notes t200.landscape)

    /// MEASURED Tabs t200.landscape / t2000.landscape, iPhone SE 2x /
    /// iOS 26.1: `UITabBar [0, 311, 667, 64]`, platter `[205, 0, 257.5, 44]`,
    /// buttons 36 pt tall at y 4 packed 86.5 / 76.5 / 78.5, table SA
    /// bottom **64**. Portrait 83 / stacked 94×54 is unchanged.
    func testCompactHeightTabBarIsInline64Pt() {
        device(667, 375, scale: 2)
        UITraitCollection.current = UITraitCollection(
            userInterfaceStyle: .light, displayScale: 2,
            horizontalSizeClass: .compact, verticalSizeClass: .compact)

        let tab = UITabBarController()
        let a = UIViewController()
        a.tabBarItem = UITabBarItem(title: "Library",
                                    image: UIImage(systemName: "calendar"), tag: 0)
        let b = UIViewController()
        b.tabBarItem = UITabBarItem(title: "Tools",
                                    image: UIImage(systemName: "plus.circle.fill"), tag: 1)
        b.tabBarItem?.badgeValue = "3"
        let c = UIViewController()
        c.tabBarItem = UITabBarItem(title: "Scroll",
                                    image: UIImage(systemName: "clock"), tag: 2)
        tab.viewControllers = [a, b, c]
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 667, height: 375))
        window.rootViewController = tab
        window.layoutIfNeeded()

        XCTAssertEqual(UITabBar.barHeight, 64)
        XCTAssertEqual(tab.tabBar.frame,
                       CGRect(x: 0, y: 311, width: 667, height: 64))
        XCTAssertEqual(tab.transitionView.safeAreaInsets.bottom, 64)

        XCTAssertEqual(tab.tabBar.itemViews.count, 3)
        XCTAssertEqual(tab.tabBar.itemViews[0].frame.minY, 4)
        XCTAssertEqual(tab.tabBar.itemViews[0].frame.height, 36)
        XCTAssertEqual(tab.tabBar.platter.frame,
                       CGRect(x: 205, y: 0, width: 257.5, height: 44))
        XCTAssertEqual(tab.tabBar.itemViews[0].frame.width, 86.5, accuracy: 0.5)
        XCTAssertEqual(tab.tabBar.itemViews[1].frame.width, 76.5, accuracy: 0.5)
        XCTAssertEqual(tab.tabBar.itemViews[2].frame.width, 78.5, accuracy: 0.5)
        XCTAssertEqual(tab.tabBar.itemViews[0].iconView.frame.origin.x, 6)
        XCTAssertGreaterThan(tab.tabBar.itemViews[0].titleLabel.frame.minX,
                             tab.tabBar.itemViews[0].iconView.frame.maxX)
        XCTAssertFalse(tab.tabBar.itemViews[1].badgeView.isHidden)
        XCTAssertEqual(tab.tabBar.itemViews[1].badgeView.frame.size,
                       CGSize(width: 16, height: 16))
        XCTAssertEqual(tab.tabBar.itemViews[1].badgeView.frame.origin.y, 0)
    }

    /// MEASURED Notes t200.landscape, iPhone SE 2x / iOS 26.1: 2-item
    /// compact-height bar is the same 64 / platter 44 / items 36 at y 4
    /// with 4 pt side pad and 4 pt gaps (Notes + Settings).
    func testCompactHeightTabBarIs64AndPacksIconTitle() {
        UIDevice.current.userInterfaceIdiom = .phone
        UITraitCollection.current = UITraitCollection(
            userInterfaceStyle: .light, displayScale: 2,
            horizontalSizeClass: .compact, verticalSizeClass: .compact)
        device(667, 375, scale: 2)

        let tab = UITabBarController()
        let notes = UIViewController()
        notes.tabBarItem = UITabBarItem(title: "Notes", image: nil, tag: 0)
        let settings = UIViewController()
        settings.tabBarItem = UITabBarItem(title: "Settings", image: nil, tag: 1)
        tab.viewControllers = [notes, settings]
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 667, height: 375))
        window.rootViewController = tab
        window.layoutIfNeeded()

        XCTAssertEqual(UITabBar.barHeight, 64)
        XCTAssertEqual(tab.tabBar.frame,
                       CGRect(x: 0, y: 311, width: 667, height: 64))
        XCTAssertEqual(tab.tabBar.platter.frame.height, 44)
        XCTAssertEqual(tab.tabBar.itemViews.count, 2)
        XCTAssertEqual(tab.tabBar.itemViews[0].frame.minY, 4)
        XCTAssertEqual(tab.tabBar.itemViews[0].frame.height, 36)
        XCTAssertEqual(tab.tabBar.itemViews[0].frame.minX, 4, accuracy: 0.5)
        XCTAssertEqual(
            tab.tabBar.itemViews[1].frame.minX
                - tab.tabBar.itemViews[0].frame.maxX,
            4, accuracy: 0.5)
        XCTAssertEqual(tab.tabBar.itemViews[0].titleLabel.font.pointSize, 12,
                       accuracy: 1e-9)
        XCTAssertEqual(tab.transitionView.safeAreaInsets.bottom, 64)
    }

    /// MEASURED Notes t200.landscape platter `[585, 24, 44, 44]`,
    /// NavFlow t200.landscape Filter `[557.5, 24, 71.5, 44]`,
    /// TableEditor t200.landscape Edit `[566.5, 24, 62.5, 44]`:
    /// compact-height trailing inset **38**. Portrait SE stays 16.
    func testCompactHeightNavItemSideMarginIs38() {
        UIDevice.current.userInterfaceIdiom = .phone
        device(667, 375, scale: 2)
        UITraitCollection.current = UITraitCollection(
            userInterfaceStyle: .light, displayScale: 2,
            horizontalSizeClass: .compact, verticalSizeClass: .compact)
        XCTAssertEqual(_UIBarMetrics.itemSideMargin, 38)

        let nav = UINavigationController(rootViewController: UIViewController())
        nav.topViewController?.navigationItem.rightBarButtonItem =
            UIBarButtonItem(barButtonSystemItem: .trash, target: nil, action: nil)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 667, height: 375))
        window.rootViewController = nav
        window.layoutIfNeeded()
        XCTAssertEqual(nav.navigationBar.rightItemViews.count, 1)
        XCTAssertEqual(nav.navigationBar.rightItemViews[0].frame.minX, 585,
                       accuracy: 0.5)
        XCTAssertEqual(nav.navigationBar.rightItemViews[0].frame.width, 44,
                       accuracy: 0.5)
    }

    /// MEASURED Notes t200.landscape All Notes abs.x **40** = card 20 +
    /// inner 20. Portrait SE stays 16+16=32. iPhone 16 portrait stays
    /// card 20 + inner 16 = 36 (realapp_focus_settings_light "General").
    func testInsetGroupedHeaderInnerFollowsSystemMargin() {
        device(375, 667, scale: 2)
        let se = UITableView(frame: CGRect(x: 0, y: 0, width: 375, height: 667),
                             style: .insetGrouped)
        XCTAssertEqual(se.groupedHeaderLabelX, 32)

        device(393, 852, scale: 3)
        let phone16 = UITableView(frame: CGRect(x: 0, y: 0, width: 393, height: 852),
                                  style: .insetGrouped)
        XCTAssertEqual(phone16.groupedHeaderLabelX, 36)

        UITraitCollection.current = UITraitCollection(
            userInterfaceStyle: .light, displayScale: 2,
            horizontalSizeClass: .compact, verticalSizeClass: .compact)
        device(667, 375, scale: 2)
        let land = UITableView(frame: CGRect(x: 0, y: 0, width: 667, height: 375),
                               style: .insetGrouped)
        XCTAssertEqual(land.groupedHeaderLabelX, 40)
    }

    /// MEASURED Notes t200.ax1 accessory **20×28.5** (contentView 307);
    /// t200.xxxl **14×19.5** (contentView 313). `.large` stays 10.5×14.
    func testDisclosureSizeFollowsDynamicType() {
        device(375, 667, scale: 2)
        let large = UITraitCollection(preferredContentSizeCategory: .large)
        XCTAssertEqual(UITableViewCell.disclosureSize(compatibleWith: large),
                       CGSize(width: 10.5, height: 14))
        let ax1 = UITraitCollection(preferredContentSizeCategory: .accessibilityLarge)
        XCTAssertEqual(UITableViewCell.disclosureSize(compatibleWith: ax1),
                       CGSize(width: 20, height: 28.5))
        let xxxl = UITraitCollection(preferredContentSizeCategory: .extraExtraExtraLarge)
        XCTAssertEqual(UITableViewCell.disclosureSize(compatibleWith: xxxl),
                       CGSize(width: 14, height: 19.5))
    }
}

#if !os(Linux)
@MainActor
#endif
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
