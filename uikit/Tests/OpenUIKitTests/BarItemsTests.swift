// Bars & appearance (M13): UIBarButtonItem, UINavigationItem, UIToolbar and
// the UIBarAppearance family. The pixel truth lives in the oracle fixtures
// (navitem_buttons / navitem_titleview / navitem_dark / navbar_appearance /
// toolbar_basic); these tests pin the geometry rules and the API behaviour
// those fixtures cannot see — item ordering, the gap/space accounting, the
// title-collision fallback, appearance selection and target-action.
import XCTest
@testable import OpenUIKit

// XCTest re-exports Foundation/CoreGraphics on Darwin; pin the portable types.

#if !os(Linux)
@MainActor
#endif
private func makeNav(width: CGFloat = 393, height: CGFloat = 300)
    -> (UINavigationController, UIViewController) {
    let vc = UIViewController()
    vc.title = "Inbox"
    let nav = UINavigationController(rootViewController: vc)
    nav.view.frame = CGRect(x: 0, y: 0, width: width, height: height)
    nav.view.layoutIfNeeded()
    return (nav, vc)
}

#if !os(Linux)
@MainActor
#endif
final class BarButtonItemTests: XCTestCase {

    // MARK: Sizing (measured: platter = content + 2 x 16, never < 44)

    func testTitleItemPlatterWidthIsContentPlusThirtyTwo() {
        let item = UIBarButtonItem(title: "Back")
        let v = _UIBarButtonItemView(item: item)
        let content = v.titleLabel.intrinsicContentSize.width
        XCTAssertEqual(v.sizeThatFits(.zero).width,
                       content + 2 * _UIBarMetrics.contentInset, accuracy: 1e-9)
        XCTAssertEqual(v.sizeThatFits(.zero).height,
                       _UIBarMetrics.platterHeight, accuracy: 1e-9)
    }

    func testImageOnlyItemIsACircle() {
        // MEASURED on iOS 26.1 (five solid images on a dark bar): the platter
        // is max(22, imageWidth) + 22 — an 18 pt image sits in a 44 pt circle,
        // a 4 pt one too, a 30 pt one in a 52 pt capsule; 40 x 24 gives 62.
        let img = UIImage(bitmap: Bitmap(width: 36, height: 36), scale: 2)  // 18 x 18 pt
        let v = _UIBarButtonItemView(item: UIBarButtonItem(image: img))
        XCTAssertEqual(v.sizeThatFits(.zero).width, 44, accuracy: 1e-9)
        let tiny = UIImage(bitmap: Bitmap(width: 8, height: 8), scale: 2)   // 4 x 4 pt
        let tv = _UIBarButtonItemView(item: UIBarButtonItem(image: tiny))
        XCTAssertEqual(tv.sizeThatFits(.zero).width,
                       _UIBarMetrics.platterHeight, accuracy: 1e-9)
        let wide = UIImage(bitmap: Bitmap(width: 60, height: 36), scale: 2)  // 30 x 18 pt
        let wv = _UIBarButtonItemView(item: UIBarButtonItem(image: wide))
        XCTAssertEqual(wv.sizeThatFits(.zero).width, 52, accuracy: 1e-9)
        let wider = UIImage(bitmap: Bitmap(width: 80, height: 48), scale: 2) // 40 x 24 pt
        let ww = _UIBarButtonItemView(item: UIBarButtonItem(image: wider))
        XCTAssertEqual(ww.sizeThatFits(.zero).width, 62, accuracy: 1e-9)
    }

    func testToolbarPlattersAreTallerThanNavigationBarPlatters() {
        // Measured separately — 48 vs 44 (see UIBarButtonItem.swift).
        XCTAssertEqual(_UIBarMetrics.platterHeight, 44)
        XCTAssertEqual(_UIBarMetrics.toolbarPlatterHeight, 48)
    }

    // MARK: System items

    func testEditAndSaveAreTextEverythingElseIsASymbol() {
        XCTAssertEqual(UIBarButtonItem(barButtonSystemItem: .edit).title, "Edit")
        XCTAssertEqual(UIBarButtonItem(barButtonSystemItem: .save).title, "Save")
        XCTAssertNil(UIBarButtonItem(barButtonSystemItem: .edit)._symbol)
        XCTAssertNotNil(UIBarButtonItem(barButtonSystemItem: .add)._symbol)
        XCTAssertNotNil(UIBarButtonItem(barButtonSystemItem: .cancel)._symbol)
        // .done is the PROMINENT (tint-filled) style on iOS 26.
        XCTAssertEqual(UIBarButtonItem(barButtonSystemItem: .done).style, .done)
        XCTAssertEqual(UIBarButtonItem.Style.prominent, .done)
    }

    func testEverySystemItemResolvesToTextOrASymbolOrASpace() {
        for c in UIBarButtonItem.SystemItem.allCases {
            let item = UIBarButtonItem(barButtonSystemItem: c)
            if item._isSpace {
                XCTAssertNil(item._symbol, "\(c) is a space")
                continue
            }
            XCTAssertTrue(item.title != nil || item._symbol != nil,
                          "system item \(c) draws nothing")
        }
    }

    func testSpacesDrawNothing() {
        XCTAssertTrue(UIBarButtonItem(barButtonSystemItem: .flexibleSpace)._isSpace)
        XCTAssertTrue(UIBarButtonItem(barButtonSystemItem: .fixedSpace)._isSpace)
        XCTAssertFalse(UIBarButtonItem(barButtonSystemItem: .add)._isSpace)
    }

    func testAccessibilityIdentifierRoundTripsOnTheItem() {
        let item = UIBarButtonItem(title: "Save")
        XCTAssertNil(item.accessibilityIdentifier)
        item.accessibilityIdentifier = "settings.save"
        XCTAssertEqual(item.accessibilityIdentifier, "settings.save")

        // Real iOS 26.1 exposes the identifier through UIBarItem's AX node;
        // none of the private descendant UIViews copy it.
        let view = _UIBarButtonItemView(item: item)
        XCTAssertNil(view.accessibilityIdentifier)
    }

    // MARK: Colors (measured — see UIBarButtonItem.swift)

    func testUntintedItemIsLabelColoredAndDisabledIsTertiary() {
        let plain = _UIBarButtonItemView(item: UIBarButtonItem(title: "A"))
        XCTAssertEqual(plain.contentColor, UIColor.label)

        let off = UIBarButtonItem(title: "A")
        off.isEnabled = false
        XCTAssertEqual(_UIBarButtonItemView(item: off).contentColor,
                       UIColor.tertiaryLabel)

        let tinted = UIBarButtonItem(title: "A")
        tinted.tintColor = .systemPink
        XCTAssertEqual(_UIBarButtonItemView(item: tinted).contentColor,
                       UIColor.systemPink)
    }

    func testBarTintDoesNotColorAnUntintedItem() {
        // Measured on real iOS 26: setting the BAR's tintColor leaves an
        // untinted glass bar button monochrome.
        let v = _UIBarButtonItemView(item: UIBarButtonItem(title: "A"))
        v.barTintColor = .systemGreen
        XCTAssertEqual(v.contentColor, UIColor.label)
    }
}

#if !os(Linux)
@MainActor
#endif
final class BarItemLayoutTests: XCTestCase {

    private func toolbar(_ items: [UIBarButtonItem], width: CGFloat = 393) -> UIToolbar {
        let t = UIToolbar(frame: CGRect(x: 0, y: 0, width: width,
                                        height: UIToolbar.defaultHeight))
        t.items = items
        t.layoutIfNeeded()
        return t
    }

    func testPlattersAreTopAlignedInAToolbar() {
        let t = toolbar([UIBarButtonItem(title: "One")])
        XCTAssertEqual(t.itemViews[0].frame.minY, 0)
        XCTAssertEqual(t.itemViews[0].frame.height,
                       _UIBarMetrics.toolbarPlatterHeight)
    }

    func testSideMarginsAndFlexibleSpace() {
        let last = UIBarButtonItem(title: "Move")
        let t = toolbar([UIBarButtonItem(title: "Edit"),
                         UIBarButtonItem(barButtonSystemItem: .flexibleSpace),
                         last])
        XCTAssertEqual(t.itemViews[0].frame.minX, _UIBarMetrics.sideMargin)
        XCTAssertEqual(t.itemViews[2].frame.maxX,
                       393 - _UIBarMetrics.sideMargin, accuracy: 1e-9)
        XCTAssertTrue(t.itemViews[1].isHidden, "a space draws nothing")
    }

    /// MEASURED (golden/toolbar_basic): the 12 pt gap goes BEFORE each
    /// element and is skipped when the previous element was a space — a
    /// 40 pt fixed space therefore shows up as 12 + 40 between two items.
    func testFixedSpaceContributesGapPlusWidth() {
        let one = UIBarButtonItem(title: "One")
        let two = UIBarButtonItem(title: "Two")
        let space = UIBarButtonItem(barButtonSystemItem: .fixedSpace)
        space.width = 40
        let t = toolbar([one, space, two])
        let gapBetween = t.itemViews[2].frame.minX - t.itemViews[0].frame.maxX
        XCTAssertEqual(gapBetween, _UIBarMetrics.gap + 40, accuracy: 1e-9)
    }

    func testAdjacentItemsAreSeparatedByTheMeasuredGap() {
        let t = toolbar([UIBarButtonItem(title: "One"), UIBarButtonItem(title: "Two")])
        XCTAssertEqual(t.itemViews[1].frame.minX - t.itemViews[0].frame.maxX,
                       _UIBarMetrics.gap, accuracy: 1e-9)
    }
}

#if !os(Linux)
@MainActor
#endif
final class NavigationItemTests: XCTestCase {

    func testNavigationItemIsLazyAndSeededFromTitle() {
        let vc = UIViewController()
        vc.title = "Inbox"
        XCTAssertNil(vc._navigationItem)
        XCTAssertEqual(vc.navigationItem.title, "Inbox")
        XCTAssertTrue(vc.navigationItem === vc.navigationItem, "cached")
        vc.title = "Renamed"
        XCTAssertEqual(vc.navigationItem.title, "Renamed")
    }

    func testItemsDriveTheBar() {
        let (nav, vc) = makeNav()
        vc.navigationItem.rightBarButtonItems = [UIBarButtonItem(title: "Edit"),
                                                 UIBarButtonItem(title: "Add")]
        vc.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Back")
        nav.view.layoutIfNeeded()
        let bar = nav.navigationBar
        XCTAssertEqual(bar.rightItemViews.count, 2)
        XCTAssertEqual(bar.leftItemViews.count, 1)
        XCTAssertEqual(bar.leftItemViews[0].frame.minX, _UIBarMetrics.sideMargin)
        // UIKit's order: rightBarButtonItems[0] is the TRAILING-most item.
        XCTAssertEqual(bar.rightItemViews[0].frame.maxX,
                       393 - _UIBarMetrics.sideMargin, accuracy: 1e-9)
        XCTAssertLessThan(bar.rightItemViews[1].frame.maxX,
                          bar.rightItemViews[0].frame.minX)
        // Platters top-align in the bar's content zone.
        XCTAssertEqual(bar.leftItemViews[0].frame.minY, UINavigationBar.platterY)
        XCTAssertEqual(bar.leftItemViews[0].frame.height, _UIBarMetrics.platterHeight)
    }

    func testTitleStaysCentredWhenItFits() {
        let (nav, vc) = makeNav()
        vc.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Back")
        vc.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Edit")
        nav.view.layoutIfNeeded()
        XCTAssertEqual(nav.navigationBar.titleLabel.center.x, 393 / 2, accuracy: 1e-9)
        XCTAssertEqual(nav.navigationBar.titleLabel.center.y,
                       UINavigationBar.largeInlineTitleCenterY, accuracy: 1e-9)
    }

    /// Measured fallback: a group wide enough to crowd the centred label
    /// makes UIKit align the title just past the leading group instead.
    func testTitleFallsBackToLeadingAlignmentWhenCrowded() {
        let (nav, vc) = makeNav()
        vc.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Back")
        vc.navigationItem.rightBarButtonItems = [
            UIBarButtonItem(title: "Something"),
            UIBarButtonItem(title: "Very Long Indeed"),
        ]
        nav.view.layoutIfNeeded()
        let bar = nav.navigationBar
        XCTAssertLessThan(bar.titleLabel.center.x, 393 / 2)
        XCTAssertEqual(bar.titleLabel.frame.minX,
                       bar.leadingGroupMaxX + _UIBarMetrics.gap, accuracy: 0.5)
    }

    func testTitleViewReplacesTheTitleLabel() {
        let (nav, vc) = makeNav()
        let tv = UIView(frame: CGRect(x: 0, y: 0, width: 160, height: 28))
        vc.navigationItem.titleView = tv
        nav.view.layoutIfNeeded()
        XCTAssertEqual(nav.navigationBar.titleLabel.alpha, 0)
        XCTAssertEqual(tv.center.x, 393 / 2, accuracy: 1e-9)
        XCTAssertEqual(tv.center.y, UINavigationBar.largeInlineTitleCenterY,
                       accuracy: 1e-9)
    }

    func testPromptPushesTheBarContentDown() {
        let (nav, vc) = makeNav()
        vc.navigationItem.prompt = "Choose a folder"
        vc.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Edit")
        nav.view.layoutIfNeeded()
        let bar = nav.navigationBar
        XCTAssertNotNil(bar.promptLabel)
        XCTAssertEqual(bar.rightItemViews[0].frame.minY,
                       UINavigationBar.platterY + UINavigationBar.promptHeight)
        XCTAssertEqual(bar.titleLabel.center.y,
                       UINavigationBar.largeInlineTitleCenterY
                           + UINavigationBar.promptHeight, accuracy: 1e-9)
    }

    func testBackButtonTitleOverrides() {
        let (nav, root) = makeNav()
        root.title = "Library"
        root.navigationItem.backButtonTitle = "Shelf"
        let child = UIViewController()
        child.title = "Book"
        nav.pushViewController(child, animated: false)
        XCTAssertEqual(nav.navigationBar.backButton?.backLabel.text, "Shelf")

        let child2 = UIViewController()
        child2.title = "Page"
        child2.navigationItem.hidesBackButton = true
        nav.pushViewController(child2, animated: false)
        XCTAssertNil(nav.navigationBar.backButton)
    }

    func testItemStackFollowsTheControllerStack() {
        let (nav, root) = makeNav()
        let child = UIViewController()
        child.title = "Detail"
        nav.pushViewController(child, animated: false)
        XCTAssertEqual(nav.navigationBar.items.count, 2)
        XCTAssertTrue(nav.navigationBar.topItem === child.navigationItem)
        XCTAssertTrue(nav.navigationBar.backItem === root.navigationItem)
        nav.popViewController(animated: false)
        XCTAssertTrue(nav.navigationBar.topItem === root.navigationItem)
    }

    func testMutatingAnItemRelaysOutTheBar() {
        let (nav, vc) = makeNav()
        let item = UIBarButtonItem(title: "Edit")
        vc.navigationItem.rightBarButtonItem = item
        nav.view.layoutIfNeeded()
        let before = nav.navigationBar.rightItemViews[0].frame.width
        vc.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "A much longer title")
        nav.view.layoutIfNeeded()
        XCTAssertGreaterThan(nav.navigationBar.rightItemViews[0].frame.width, before)
    }
}

// MARK: - Target-action through the M12 selector machinery

#if !os(Linux)
@MainActor
#endif
private final class BarActionTarget: SelectorDispatching {
    var taps = 0
    var lastSender: AnyObject?
    static let actions: ActionTable<BarActionTarget> = [
        .action("save", BarActionTarget.save),
        .action("saveSender:", BarActionTarget.saveSender),
    ]
    func save() { taps += 1 }
    func saveSender(_ sender: UIBarButtonItem) { taps += 1; lastSender = sender }
    func perform(_ name: String, with sender: Any?) -> Bool {
        Self.actions.perform(name, on: self, with: sender)
    }
}

#if !os(Linux)
@MainActor
#endif
final class BarButtonActionTests: XCTestCase {
    func testTapFiresTheItemsSelector() {
        let target = BarActionTarget()
        let item = UIBarButtonItem(title: "Save", style: .plain,
                                   target: target, action: Selector.named("save"))
        let (nav, vc) = makeNav()
        vc.navigationItem.rightBarButtonItem = item
        nav.view.layoutIfNeeded()
        let view = nav.navigationBar.rightItemViews[0]
        view.sendActions(for: .touchUpInside)
        XCTAssertEqual(target.taps, 1)
    }

    /// UIKit passes the ITEM (not the internal control) as the sender.
    func testSenderIsTheBarButtonItem() {
        let target = BarActionTarget()
        let item = UIBarButtonItem(barButtonSystemItem: .save, target: target,
                                   action: Selector.named("saveSender:"))
        let t = UIToolbar(frame: CGRect(x: 0, y: 0, width: 300, height: 54))
        t.items = [item]
        t.layoutIfNeeded()
        t.itemViews[0].sendActions(for: .touchUpInside)
        XCTAssertEqual(target.taps, 1)
        XCTAssertTrue(target.lastSender === item)
    }

    func testTargetIsHeldWeakly() {
        var target: BarActionTarget? = BarActionTarget()
        let item = UIBarButtonItem(title: "Save", style: .plain,
                                   target: target, action: Selector.named("save"))
        target = nil
        XCTAssertNil(item.target)
    }
}

#if !os(Linux)
@MainActor
#endif
final class BarAppearanceTests: XCTestCase {

    /// UIAppearance is process-global, so tests of the implicit legacy path
    /// deliberately neutralize any proxy installed by another test.
    private func makeImplicitBar() -> UINavigationBar {
        let bar = UINavigationBar(frame: CGRect(x: 0, y: 0, width: 393, height: 54))
        let initial = UINavigationBarAppearance()
        initial.configureWithOpaqueBackground()
        bar._standardAppearance = initial
        bar._standardAppearanceIsExplicit = false
        bar.scrollEdgeAppearance = nil
        bar.compactAppearance = nil
        bar._legacyBackgroundImages = [:]
        bar.shadowImage = nil
        bar.titleTextAttributes = nil
        bar.largeTitleTextAttributes = nil
        bar.setState(title: "Library", backTitle: nil)
        bar.applyAppearance()
        return bar
    }

    func testConfigurationsSetTheMeasuredDefaults() {
        let a = UINavigationBarAppearance()
        a.configureWithOpaqueBackground()
        XCTAssertEqual(a._configuration, .opaque)
        XCTAssertNotNil(a._resolvedBackgroundColor)
        XCTAssertNotNil(a.shadowColor)

        a.configureWithTransparentBackground()
        XCTAssertEqual(a._configuration, .transparent)
        XCTAssertNil(a._resolvedBackgroundColor)
        XCTAssertNil(a.shadowColor)

        a.configureWithDefaultBackground()
        XCTAssertEqual(a._configuration, .default)
        XCTAssertNil(a._resolvedBackgroundColor, "iOS 26 default is transparent at rest")
    }

    func testAppearanceDrivesTheBarBackgroundAndHairline() {
        let (nav, _) = makeNav()
        let bar = nav.navigationBar
        let a = UINavigationBarAppearance()
        a.configureWithOpaqueBackground()
        a.backgroundColor = .systemPink
        bar.standardAppearance = a
        nav.view.layoutIfNeeded()
        XCTAssertEqual(bar.backgroundColor, UIColor.systemPink)
        XCTAssertFalse(bar.hairline.isHidden)
        XCTAssertEqual(bar.hairline.frame.height, UIBarAppearance.shadowHeight)

        let clear = UINavigationBarAppearance()
        clear.configureWithTransparentBackground()
        bar.standardAppearance = clear
        nav.view.layoutIfNeeded()
        XCTAssertNil(bar.backgroundColor)
        XCTAssertTrue(bar.hairline.isHidden)
    }

    func testTitleTextAttributesOverrideTheDefaults() {
        let (nav, _) = makeNav()
        let a = UINavigationBarAppearance()
        a.configureWithOpaqueBackground()
        a.titleTextAttributes = [
            .font: UIFont.systemFont(ofSize: 20, weight: .bold),
            .foregroundColor: UIColor.systemRed,
        ]
        nav.navigationBar.standardAppearance = a
        nav.view.layoutIfNeeded()
        XCTAssertEqual(nav.navigationBar.titleLabel.font.pointSize, 20)
        XCTAssertEqual(nav.navigationBar.titleLabel.textColor, UIColor.systemRed)
    }

    func testAttributeDictionarySpelling() {
        let appearance = UINavigationBarAppearance()
        appearance.titleTextAttributes = [
            .font: UIFont.systemFont(ofSize: 22),
            .foregroundColor: UIColor.systemGreen,
        ]
        let attrs = appearance.titleTextAttributes
        XCTAssertEqual((attrs[.font] as? UIFont)?.pointSize, 22)
        XCTAssertEqual(attrs[.foregroundColor] as? UIColor, UIColor.systemGreen)
    }

    func testAttributeDictionariesHaveValueSemantics() {
        let appearance = UINavigationBarAppearance()
        var attrs = appearance.titleTextAttributes
        attrs[.foregroundColor] = UIColor.systemRed
        appearance.titleTextAttributes = attrs
        attrs[.foregroundColor] = UIColor.systemBlue

        XCTAssertEqual(appearance.titleTextAttributes[.foregroundColor] as? UIColor,
                       UIColor.systemRed)
    }

    func testBarMetricsRawValuesAndAliasesMatchUIKit() {
        XCTAssertEqual(UIBarMetrics.default.rawValue, 0)
        XCTAssertEqual(UIBarMetrics.compact.rawValue, 1)
        XCTAssertEqual(UIBarMetrics.defaultPrompt.rawValue, 101)
        XCTAssertEqual(UIBarMetrics.compactPrompt.rawValue, 102)
        XCTAssertEqual(UIBarMetrics.landscapePhone, .compact)
        XCTAssertEqual(UIBarMetrics.landscapePhonePrompt, .compactPrompt)
    }

    func testLegacyBackgroundImagesRoundTripByExactMetric() {
        let bar = makeImplicitBar()
        let regular = UIImage(bitmap: Bitmap(width: 4, height: 2))
        let compact = UIImage(bitmap: Bitmap(width: 3, height: 1))

        bar.setBackgroundImage(regular, for: .default)
        XCTAssertTrue(bar.backgroundImage(for: .default) === regular)
        XCTAssertNil(bar.backgroundImage(for: .compact),
                     "the legacy getter does not fall back across metrics")
        bar.setBackgroundImage(compact, for: .compact)
        XCTAssertTrue(bar.backgroundImage(for: .compact) === compact)
        bar.setBackgroundImage(nil, for: .compact)
        XCTAssertNil(bar.backgroundImage(for: .compact))
        XCTAssertTrue(bar.backgroundImage(for: .default) === regular)
    }

    func testPromptArtworkFallsBackVisuallyWithoutChangingExactGetter() {
        let bar = makeImplicitBar()
        let regular = UIImage(bitmap: Bitmap(width: 4, height: 2))
        let prompt = UIImage(bitmap: Bitmap(width: 5, height: 3))
        bar.setBackgroundImage(regular, for: .default)

        let item = UINavigationItem(title: "Library")
        item.prompt = "Choose a shelf"
        bar.setItems([item])
        XCTAssertNil(bar.backgroundImage(for: .defaultPrompt))
        XCTAssertTrue(bar.legacyBackgroundImageForCurrentMetrics === regular)

        bar.setBackgroundImage(prompt, for: .defaultPrompt)
        XCTAssertTrue(bar.backgroundImage(for: .defaultPrompt) === prompt)
        XCTAssertTrue(bar.legacyBackgroundImageForCurrentMetrics === prompt)
    }

    func testLegacyEmptyImagesSuppressBackgroundAndHairline() {
        let bar = makeImplicitBar()
        let emptyBackground = UIImage()
        let emptyShadow = UIImage()
        bar.isTranslucent = false
        bar.setBackgroundImage(emptyBackground, for: .default)
        bar.shadowImage = emptyShadow
        bar.titleTextAttributes = [
            .font: UIFont.systemFont(ofSize: 23, weight: .bold),
            .foregroundColor: UIColor.systemRed,
        ]
        bar.layoutIfNeeded()

        XCTAssertTrue(bar.backgroundImage(for: .default) === emptyBackground)
        XCTAssertTrue(bar.shadowImage === emptyShadow)
        XCTAssertNil(bar.backgroundColor)
        XCTAssertTrue(bar.backgroundImageView.image === emptyBackground)
        XCTAssertFalse(bar.backgroundImageView.isHidden)
        XCTAssertTrue(bar.shadowImageView.image === emptyShadow)
        XCTAssertFalse(bar.shadowImageView.isHidden)
        XCTAssertTrue(bar.hairline.isHidden)
        XCTAssertEqual(bar.titleLabel.font.pointSize, 23)
        XCTAssertEqual(bar.titleLabel.textColor, UIColor.systemRed)
    }

    func testLegacyShadowIsIgnoredWithoutALegacyBackground() {
        let bar = makeImplicitBar()
        let emptyShadow = UIImage()
        bar.shadowImage = emptyShadow
        bar.layoutIfNeeded()

        XCTAssertEqual(bar.backgroundColor, UIColor.systemBackground)
        XCTAssertNil(bar.shadowImageView.image)
        XCTAssertTrue(bar.shadowImageView.isHidden)
        XCTAssertFalse(bar.hairline.isHidden)
    }

    func testExplicitModernAppearanceWinsInBothSetterOrders() {
        for modernFirst in [false, true] {
            let bar = makeImplicitBar()
            let emptyBackground = UIImage()
            let emptyShadow = UIImage()
            let modern = UINavigationBarAppearance()
            modern.configureWithOpaqueBackground()
            modern.backgroundColor = .systemGreen
            modern.shadowColor = .systemBlue
            modern.titleTextAttributes = [.foregroundColor: UIColor.systemBlue]

            let installLegacy = {
                bar.setBackgroundImage(emptyBackground, for: .default)
                bar.shadowImage = emptyShadow
                bar.titleTextAttributes = [.foregroundColor: UIColor.systemRed]
            }
            if modernFirst {
                bar.standardAppearance = modern
                installLegacy()
            } else {
                installLegacy()
                bar.standardAppearance = modern
            }
            bar.layoutIfNeeded()

            XCTAssertTrue(bar.backgroundImage(for: .default) === emptyBackground)
            XCTAssertTrue(bar.shadowImage === emptyShadow)
            XCTAssertEqual(bar.titleTextAttributes?[.foregroundColor] as? UIColor,
                           UIColor.systemRed)
            XCTAssertEqual(bar.backgroundColor, UIColor.systemGreen)
            XCTAssertNil(bar.backgroundImageView.image)
            XCTAssertTrue(bar.backgroundImageView.isHidden)
            XCTAssertNil(bar.shadowImageView.image)
            XCTAssertTrue(bar.shadowImageView.isHidden)
            XCTAssertFalse(bar.hairline.isHidden)
            XCTAssertEqual(bar.hairline.backgroundColor, UIColor.systemBlue)
            XCTAssertEqual(bar.titleLabel.textColor, UIColor.systemBlue)
        }
    }

    func testNavigationItemModernAppearancesWinOverLegacyState() {
        for useScrollEdge in [false, true] {
            let bar = makeImplicitBar()
            let emptyBackground = UIImage()
            bar.setBackgroundImage(emptyBackground, for: .default)
            bar.shadowImage = UIImage()
            bar.titleTextAttributes = [.foregroundColor: UIColor.systemRed]

            let modern = UINavigationBarAppearance()
            modern.configureWithOpaqueBackground()
            modern.backgroundColor = .systemGreen
            modern.titleTextAttributes = [.foregroundColor: UIColor.systemBlue]
            let item = UINavigationItem(title: "Modern")
            if useScrollEdge {
                item.scrollEdgeAppearance = modern
            } else {
                item.standardAppearance = modern
            }
            bar.setItems([item])
            bar.layoutIfNeeded()

            XCTAssertTrue(bar.effectiveAppearance === modern)
            XCTAssertTrue(bar.effectiveAppearanceSelection.isExplicit)
            XCTAssertTrue(bar.backgroundImage(for: .default) === emptyBackground)
            XCTAssertEqual(bar.backgroundColor, UIColor.systemGreen)
            XCTAssertNil(bar.backgroundImageView.image)
            XCTAssertEqual(bar.titleLabel.textColor, UIColor.systemBlue)
        }
    }

    /// `scrollEdgeAppearance` wins while the tracked scroll view sits at its
    /// top edge; `standardAppearance` takes over once it scrolls.
    func testScrollEdgeAppearanceSelection() {
        let vc = UIViewController()
        vc.title = "Feed"
        let scroll = UIScrollView(frame: CGRect(x: 0, y: 0, width: 393, height: 300))
        scroll.contentSize = CGSize(width: 393, height: 2000)
        vc.view.addSubview(scroll)
        let nav = UINavigationController(rootViewController: vc)
        nav.view.frame = CGRect(x: 0, y: 0, width: 393, height: 300)
        nav.view.layoutIfNeeded()

        let standard = UINavigationBarAppearance()
        standard.configureWithOpaqueBackground()
        standard.backgroundColor = .systemBlue
        let edge = UINavigationBarAppearance()
        edge.configureWithTransparentBackground()
        nav.navigationBar.standardAppearance = standard
        nav.navigationBar.scrollEdgeAppearance = edge
        nav.navigationBar.trackedScrollView = scroll

        nav.navigationBar.applyAppearance()
        XCTAssertNil(nav.navigationBar.backgroundColor, "at the edge -> transparent")
        scroll.contentOffset = CGPoint(x: 0, y: 120)
        nav.navigationBar.applyAppearance()
        XCTAssertEqual(nav.navigationBar.backgroundColor, UIColor.systemBlue)
    }

    func testBarTintColorIsTheLegacySpellingOfAnOpaqueBackground() {
        let (nav, _) = makeNav()
        nav.navigationBar.barTintColor = .systemTeal
        nav.view.layoutIfNeeded()
        XCTAssertEqual(nav.navigationBar.standardAppearance._configuration, .opaque)
        XCTAssertEqual(nav.navigationBar.backgroundColor, UIColor.systemTeal)
    }

    func testClearingBarTintRestoresTheImplicitDefaultAndKeepsLegacyState() {
        let bar = makeImplicitBar()
        let compactBackground = UIImage(bitmap: Bitmap(width: 4, height: 2))
        let shadow = UIImage()
        bar.setBackgroundImage(compactBackground, for: .compact)
        bar.shadowImage = shadow
        bar.titleTextAttributes = [.foregroundColor: UIColor.systemRed]

        bar.barTintColor = .systemTeal
        XCTAssertEqual(bar.backgroundColor, UIColor.systemTeal)
        XCTAssertEqual(bar.standardAppearance.backgroundColor, UIColor.systemTeal)

        bar.barTintColor = nil

        XCTAssertFalse(bar._standardAppearanceIsExplicit)
        XCTAssertEqual(bar.standardAppearance._configuration, .opaque)
        XCTAssertEqual(bar.standardAppearance.backgroundColor,
                       UIColor.systemBackground)
        XCTAssertEqual(bar.backgroundColor, UIColor.systemBackground)
        XCTAssertTrue(bar.backgroundImage(for: .compact) === compactBackground)
        XCTAssertTrue(bar.shadowImage === shadow)
        XCTAssertEqual(bar.titleTextAttributes?[.foregroundColor] as? UIColor,
                       UIColor.systemRed)
        XCTAssertEqual(bar.titleLabel.textColor, UIColor.systemRed)
    }

    func testBarTintTransitionsDoNotMutateAnExplicitModernAppearance() {
        let bar = makeImplicitBar()
        let modern = UINavigationBarAppearance()
        modern.configureWithOpaqueBackground()
        modern.backgroundColor = .systemGreen
        modern.shadowColor = .systemOrange
        modern.titleTextAttributes = [.foregroundColor: UIColor.systemBlue]
        bar.standardAppearance = modern

        let legacyBackground = UIImage()
        let legacyShadow = UIImage()
        bar.setBackgroundImage(legacyBackground, for: .default)
        bar.shadowImage = legacyShadow
        bar.titleTextAttributes = [.foregroundColor: UIColor.systemRed]

        bar.barTintColor = .systemTeal
        bar.barTintColor = nil

        XCTAssertTrue(bar.standardAppearance === modern)
        XCTAssertTrue(bar._standardAppearanceIsExplicit)
        XCTAssertEqual(modern._configuration, .opaque)
        XCTAssertEqual(modern.backgroundColor, UIColor.systemGreen)
        XCTAssertEqual(modern.shadowColor, UIColor.systemOrange)
        XCTAssertEqual(bar.backgroundColor, UIColor.systemGreen)
        XCTAssertEqual(bar.hairline.backgroundColor, UIColor.systemOrange)
        XCTAssertEqual(bar.titleLabel.textColor, UIColor.systemBlue)
        XCTAssertTrue(bar.backgroundImage(for: .default) === legacyBackground)
        XCTAssertTrue(bar.shadowImage === legacyShadow)
        XCTAssertEqual(bar.titleTextAttributes?[.foregroundColor] as? UIColor,
                       UIColor.systemRed)
    }
}

#if !os(Linux)
@MainActor
#endif
final class NavigationToolbarTests: XCTestCase {
    func testToolbarIsHiddenUntilAsked() {
        let (nav, vc) = makeNav()
        XCTAssertTrue(nav.isToolbarHidden)
        XCTAssertTrue(nav.toolbar.isHidden)
        XCTAssertEqual(vc.view.frame.height, 300 - UINavigationBar.barHeight)

        vc.toolbarItems = [UIBarButtonItem(barButtonSystemItem: .edit)]
        nav.setToolbarHidden(false, animated: false)
        nav.view.layoutIfNeeded()
        XCTAssertFalse(nav.toolbar.isHidden)
        XCTAssertEqual(nav.toolbar.frame.minY, 300 - UIToolbar.defaultHeight)
        XCTAssertEqual(nav.toolbar.items?.count, 1)
        // The content area gives the toolbar its height back.
        XCTAssertEqual(vc.view.frame.height,
                       300 - UINavigationBar.barHeight - UIToolbar.defaultHeight)
    }

    func testToolbarFollowsTheTopController() {
        let (nav, root) = makeNav()
        root.toolbarItems = [UIBarButtonItem(title: "Root")]
        nav.setToolbarHidden(false, animated: false)
        XCTAssertEqual(nav.toolbar.items?.count, 1)
        let child = UIViewController()
        child.title = "Child"
        child.toolbarItems = [UIBarButtonItem(title: "A"), UIBarButtonItem(title: "B")]
        nav.pushViewController(child, animated: false)
        XCTAssertEqual(nav.toolbar.items?.count, 2)
        nav.popViewController(animated: false)
        XCTAssertEqual(nav.toolbar.items?.count, 1)
    }
}
