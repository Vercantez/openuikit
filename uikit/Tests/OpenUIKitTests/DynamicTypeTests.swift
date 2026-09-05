// Dynamic Type + sheet detents (M14). Owner: text / viewcontroller modules.
//
// Every expected number here is a MEASUREMENT taken from real iOS 26 in the
// Simulator, replayed:
//
//   * the Dynamic Type numbers come from Tools/oracle2/dyntypeprobe
//     (scripts/dyntype_probe_sim.sh); the dump is committed at
//     fixtures/realapp/dynamic_type_ios.json and its distilled form is
//     Sources/OpenUIKit/Resources/dynamic_type.json;
//   * the detent numbers come from Tools/oracle2/detentprobe
//     (scripts/detent_probe_sim.sh); the dump is committed at
//     fixtures/realapp/detents_ios.json.
//
// Neither has a fixture scene: a text style is a number, not a picture, and
// the non-large detent's iOS-26 appearance is a floating scaled card
// OpenUIKit deliberately does not draw (see UIPresentation.swift). These
// tests are the gate instead.
import XCTest
@testable import OpenUIKit

#if !os(Linux)
@MainActor
#endif
final class DynamicTypeTests: XCTestCase {

    override func setUp() {
        super.setUp()
        UITraitCollection.current = UITraitCollection(userInterfaceStyle: .light,
                                                     displayScale: 2)
    }

    /// dyntypeprobe, category `large` (a device's default): the preferred
    /// point size per text style on iOS 26.
    func testPreferredPointSizesAtDefaultCategory() {
        let expected: [(UIFont.TextStyle, CGFloat)] = [
            (.largeTitle, 34), (.title1, 28), (.title2, 22), (.title3, 20),
            (.headline, 17), (.subheadline, 15), (.body, 17), (.callout, 16),
            (.footnote, 13), (.caption1, 12), (.caption2, 11),
        ]
        for (style, pt) in expected {
            XCTAssertEqual(UIFont.preferredFont(forTextStyle: style).pointSize, pt,
                           "\(style.rawValue)")
            XCTAssertEqual(
                UIFontDescriptor.preferredFontDescriptor(withTextStyle: style).pointSize,
                pt, "\(style.rawValue) descriptor")
        }
    }

    /// dyntypeprobe: only `.headline` is bold on iOS 26 (`.SFUI-Semibold`,
    /// traitBold set); every other style is `.SFUI-Regular`.
    func testOnlyHeadlineIsBold() {
        XCTAssertEqual(UIFont.preferredFont(forTextStyle: .headline).weight, .semibold)
        for style: UIFont.TextStyle in [.largeTitle, .title1, .title2, .title3,
                                        .subheadline, .body, .callout,
                                        .footnote, .caption1, .caption2] {
            XCTAssertEqual(UIFont.preferredFont(forTextStyle: style).weight, .regular,
                           style.rawValue)
        }
    }

    /// dyntypeprobe: at `.large`, `scaledValue(for:)` is the IDENTITY for
    /// every style at every base value probed — which is why an app at the
    /// default Dynamic Type setting gets real-UIKit point sizes out of
    /// OpenUIKit.
    func testScaledValueIsIdentityAtDefaultCategory() {
        for style: UIFont.TextStyle in [.largeTitle, .body, .headline,
                                        .footnote, .caption2] {
            let m = UIFontMetrics(forTextStyle: style)
            for v: CGFloat in [8, 11, 13, 16, 17, 18, 24, 34, 48, 64] {
                XCTAssertEqual(m.scaledValue(for: v), v, accuracy: 0.0001,
                               "\(style.rawValue) @ \(v)")
            }
            XCTAssertEqual(m.scaledFont(for: .systemFont(ofSize: 18, weight: .semibold))
                            .pointSize, 18, accuracy: 0.0001, style.rawValue)
        }
    }

    /// dyntypeprobe, a spread of non-default categories. Exact table hits.
    func testScaledValueAtOtherCategories() {
        let cases: [(UIContentSizeCategory, UIFont.TextStyle, CGFloat, CGFloat)] = [
            // (category, style, base, measured scaledValue)
            (.extraSmall, .body, 18, 15.666667),
            (.extraExtraExtraLarge, .body, 18, 23.666667),
            (.extraExtraExtraLarge, .footnote, 18, 24),
            (.extraExtraExtraLarge, .caption2, 18, 30.333333),
            (.accessibilityLarge, .body, 18, 32.666667),
            (.accessibilityLarge, .caption2, 8, 18),
            (.accessibilityExtraExtraExtraLarge, .title2, 18, 42.333333),
        ]
        for (cat, style, base, want) in cases {
            let traits = UITraitCollection(preferredContentSizeCategory: cat)
            let got = UIFontMetrics(forTextStyle: style)
                .scaledValue(for: base, compatibleWith: traits)
            XCTAssertEqual(got, want, accuracy: 0.001,
                           "\(cat.rawValue)/\(style.rawValue)@\(base)")
        }
    }

    /// The four Settings Dynamic Type sizes `realapp_settings_light{_xs,_xxxl,_ax1}`
    /// capture. Same numbers dyntypeprobe wrote into dynamic_type.json;
    /// the app path is `UIFont.font(ofSize:weight:scalingWith:)` →
    /// `UIFontMetrics.scaledFont(for:)` of 18 pt headline / 16 pt callout /
    /// 13 pt footnote / 24 pt largeTitle (the icon floor).
    func testSettingsScreenFontsAtCapturedCategories() {
        let cases: [(UIContentSizeCategory, UIFont.TextStyle, CGFloat, CGFloat)] = [
            (.extraSmall, .headline, 18, 16),
            (.large, .headline, 18, 18),
            (.extraExtraExtraLarge, .headline, 18, 24),
            (.accessibilityLarge, .headline, 18, 33),
            (.extraSmall, .callout, 16, 14),
            (.large, .callout, 16, 16),
            (.extraExtraExtraLarge, .callout, 16, 21),
            (.accessibilityLarge, .callout, 16, 30),
            (.extraSmall, .footnote, 13, 12),
            (.accessibilityLarge, .footnote, 13, 24),
            (.extraSmall, .largeTitle, 24, 22.333333),
            (.accessibilityLarge, .largeTitle, 24, 33.333333),
        ]
        for (cat, style, base, want) in cases {
            let traits = UITraitCollection(preferredContentSizeCategory: cat)
            if style == .largeTitle {
                let got = UIFontMetrics(forTextStyle: style)
                    .scaledValue(for: base, compatibleWith: traits)
                XCTAssertEqual(got, want, accuracy: 0.001,
                               "scaledValue \(cat.rawValue)/\(style.rawValue)@\(base)")
            } else {
                let got = UIFontMetrics(forTextStyle: style)
                    .scaledFont(for: .systemFont(ofSize: base, weight: .semibold),
                                compatibleWith: traits).pointSize
                XCTAssertEqual(got, want, accuracy: 0.001,
                               "scaledFont \(cat.rawValue)/\(style.rawValue)@\(base)")
            }
        }
    }

    /// dyntypeprobe: the preferred size table across categories, spot-checked
    /// at the extremes.
    func testPreferredPointSizeAcrossCategories() {
        let cases: [(UIContentSizeCategory, UIFont.TextStyle, CGFloat)] = [
            (.extraSmall, .body, 14),
            (.extraExtraExtraLarge, .body, 23),
            (.accessibilityExtraExtraExtraLarge, .body, 53),
            (.extraSmall, .largeTitle, 31),
            (.accessibilityExtraExtraExtraLarge, .largeTitle, 60),
            (.medium, .footnote, 12),
            (.accessibilityMedium, .caption2, 20),
        ]
        for (cat, style, want) in cases {
            let traits = UITraitCollection(preferredContentSizeCategory: cat)
            XCTAssertEqual(
                UIFont.preferredFont(forTextStyle: style, compatibleWith: traits).pointSize,
                want, "\(cat.rawValue)/\(style.rawValue)")
        }
    }

    func testDefaultMetricsIsBody() {
        XCTAssertEqual(UIFontMetrics.default.textStyle, .body)
    }

    func testAccessibilityCategoryFlag() {
        XCTAssertTrue(UIContentSizeCategory.accessibilityMedium.isAccessibilityCategory)
        XCTAssertFalse(UIContentSizeCategory.extraExtraExtraLarge.isAccessibilityCategory)
    }

    /// MEASURED dtmetrics probe, iPhone 16 / iOS 26.1: the no-`compatibleWith`
    /// `scaledValue(for:)` overload tracks `UIApplication.shared`'s category
    /// (Settings), not `UITraitCollection.current`. After setting current to
    /// `.accessibilityLarge`, current reads AX1, the app category stays L,
    /// `scaledValue(for: 24)` stays 24, and `compatibleWith: current` is 33.333.
    func testIOSScaledValueUsesApplicationCategoryNotCurrent() {
        let savedCut = OpenUIKitRuntime.systemFontCut
        let savedTraits = UITraitCollection.current
        let savedApp = UIApplication.shared.preferredContentSizeCategory
        OpenUIKitRuntime.systemFontCut = .iOS
        defer {
            OpenUIKitRuntime.systemFontCut = savedCut
            UITraitCollection.current = savedTraits
            UIApplication.shared.preferredContentSizeCategory = savedApp
        }
        UIApplication.shared.preferredContentSizeCategory = .large
        UITraitCollection.current = UITraitCollection(
            userInterfaceStyle: .light, displayScale: 3,
            preferredContentSizeCategory: .accessibilityLarge)
        let m = UIFontMetrics(forTextStyle: .largeTitle)
        XCTAssertEqual(m.scaledValue(for: 24), 24, accuracy: 0.001)
        XCTAssertEqual(
            m.scaledValue(for: 24, compatibleWith: UITraitCollection.current),
            33.333, accuracy: 0.01)
    }

    /// MEASURED realapp_settings_light_ax1, iPhone 16 / iOS 26.1: a stack
    /// row that is a plain UIView with `height >= 40` and a label on
    /// `layoutMarginsGuide` grows to 8 + labelIntrinsic + 8 when that is
    /// above 40. At `.accessibilityLarge` the 24 pt footnote is 28.667.
    func testSettingsTitleContainerGrowsAtAccessibilityLarge() {
        let savedCut = OpenUIKitRuntime.systemFontCut
        let savedTraits = UITraitCollection.current
        OpenUIKitRuntime.systemFontCut = .iOS
        UIScreen.main._hostConfigure(bounds: CGRect(x: 0, y: 0, width: 393, height: 852),
                                     scale: 3)
        defer {
            OpenUIKitRuntime.systemFontCut = savedCut
            UITraitCollection.current = savedTraits
        }

        func titleStack(category: UIContentSizeCategory) -> (UIStackView, UILabel) {
            UITraitCollection.current = UITraitCollection(
                userInterfaceStyle: .light, displayScale: 3,
                preferredContentSizeCategory: category)
            let stack = UIStackView()
            stack.axis = .vertical
            stack.translatesAutoresizingMaskIntoConstraints = false
            let container = UIView()
            NSLayoutConstraint.activate([
                container.heightAnchor.constraint(greaterThanOrEqualToConstant: 40)
            ])
            let label = UILabel()
            label.font = UIFontMetrics(forTextStyle: .footnote)
                .scaledFont(for: .systemFont(ofSize: 13, weight: .bold))
            label.text = "ROW ACTION"
            label.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(label)
            NSLayoutConstraint.activate([
                label.topAnchor.constraint(equalTo: container.layoutMarginsGuide.topAnchor),
                label.bottomAnchor.constraint(equalTo: container.layoutMarginsGuide.bottomAnchor),
            ])
            stack.addArrangedSubview(container)
            return (stack, label)
        }

        let (large, largeLabel) = titleStack(category: .large)
        XCTAssertEqual(largeLabel.font.pointSize, 13)
        XCTAssertEqual(large.sizeThatFits(CGSize(width: 393, height: 0)).height, 40)

        let (ax1, ax1Label) = titleStack(category: .accessibilityLarge)
        XCTAssertEqual(ax1Label.font.pointSize, 24)
        // 28.667 intrinsic + 8+8 layout margins. Golden title container 44.667.
        XCTAssertEqual(ax1Label.intrinsicContentSize.height, 28.667, accuracy: 0.01)
        XCTAssertEqual(ax1.sizeThatFits(CGSize(width: 393, height: 0)).height, 44.667,
                       accuracy: 0.01)
    }
}

#if !os(Linux)
@MainActor
#endif
final class SheetDetentTests: XCTestCase {

    /// Present a sheet on a 393x852 container with the measured window safe
    /// area, and hand back its presentation controller.
    private func present(detents: [UISheetPresentationController.Detent])
        -> (UIViewController, UISheetPresentationController) {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 393, height: 852))
        // detentprobe's device: top 59 (status bar), bottom 34 (home indicator).
        window._setSafeAreaInsets(UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0))
        let base = UIViewController()
        window.rootViewController = base
        window.makeKeyAndVisible()
        let sheet = UIViewController()
        sheet.modalPresentationStyle = .formSheet
        base.present(sheet, animated: false)
        let pc = sheet.sheetPresentationController!
        pc.detents = detents
        window.layoutIfNeeded()
        return (sheet, pc)
    }

    /// MEASURED: `context.maximumDetentValue` == 759 on a 393x852 window
    /// == 852 - 59 (sheet top inset) - 34 (bottom safe area).
    func testMaximumDetentValue() {
        var seen: CGFloat = -1
        let (_, pc) = present(detents: [.custom { ctx in
            seen = ctx.maximumDetentValue
            return 300
        }])
        _ = pc.frameOfPresentedViewInContainerView
        XCTAssertEqual(seen, 759)
    }

    /// MEASURED: `.large()` sits at [0, 59, 393, 793] — the frame OpenUIKit
    /// already drew before detents existed, so this is a no-regression gate.
    func testLargeDetentFrame() {
        let (_, pc) = present(detents: [.large()])
        XCTAssertEqual(pc.frameOfPresentedViewInContainerView,
                       CGRect(x: 0, y: 59, width: 393, height: 793))
    }

    /// MEASURED: a custom value ABOVE the maximum collapses to exactly the
    /// `.large` frame (probe case custom-10000).
    func testOverMaximumCollapsesToLarge() {
        let (_, pc) = present(detents: [.custom { _ in 10_000 }])
        XCTAssertEqual(pc.frameOfPresentedViewInContainerView,
                       CGRect(x: 0, y: 59, width: 393, height: 793))
    }

    /// A custom value below the maximum sits `value + bottomSafeArea` tall at
    /// the bottom of the container. NOTE the standing divergence: iOS 26
    /// draws this as an inset, scaled floating card
    /// (probe: detent 400 -> [8, 427.669, 377, 416.331]); OpenUIKit draws it
    /// edge to edge at the same HEIGHT. See UIPresentation.swift.
    func testCustomDetentHeight() {
        let (_, pc) = present(detents: [.custom { _ in 400 }])
        let f = pc.frameOfPresentedViewInContainerView
        XCTAssertEqual(f.height, 434)          // 400 + 34 bottom safe area
        XCTAssertEqual(f.maxY, 852)
        XCTAssertEqual(f.width, 393)
    }

    /// A resolver returning nil falls through to the large frame, like a
    /// detent UIKit cannot resolve.
    func testNilResolverIsLarge() {
        let (_, pc) = present(detents: [.custom { _ in nil }])
        XCTAssertEqual(pc.frameOfPresentedViewInContainerView.minY, 59)
    }

    /// `.formSheet` resolves to the sheet presentation on an iPhone-width
    /// container (MEASURED: detentprobe presents `.formSheet` and gets the
    /// pageSheet geometry).
    func testFormSheetResolvesToPageSheet() {
        let vc = UIViewController()
        vc.modalPresentationStyle = .formSheet
        XCTAssertEqual(vc._resolvedPresentationStyle, .pageSheet)
    }

    /// MEASURED detentprobe iPhone 16 / iOS 26.1: medium unscaled height
    /// 459 = 425 + 34, floating frame [8, 403.687, 377, 440.313].
    func testMediumDetentFloatingFrameOnIOS() {
        let saved = OpenUIKitRuntime.systemFontCut
        OpenUIKitRuntime.systemFontCut = .iOS
        defer { OpenUIKitRuntime.systemFontCut = saved }
        let (_, pc) = present(detents: [.medium()])
        let f = pc.frameOfPresentedViewInContainerView
        let scale: CGFloat = 377 / 393
        let unscaled: CGFloat = 425 + 34
        XCTAssertEqual(f.width, 377, accuracy: 1e-9)
        XCTAssertEqual(f.height, unscaled * scale, accuracy: 1e-6)
        XCTAssertEqual(f.minX, 8, accuracy: 1e-9)
        XCTAssertEqual(f.minY, 852 - 8 - unscaled * scale, accuracy: 1e-6)
    }

    /// MEASURED Modal t3200/t1200, iPhone SE 2x / iOS 26.1, window SA 0:
    /// large `[0, 30, 375, 637]`; medium unscaled 356.5, floating
    /// `[8, 317.711, 359, 341.289]`.
    func testSEWindowLargeAndMediumDetentsOnIOS() {
        let saved = OpenUIKitRuntime.systemFontCut
        OpenUIKitRuntime.systemFontCut = .iOS
        defer { OpenUIKitRuntime.systemFontCut = saved }
        UITraitCollection.current = UITraitCollection(userInterfaceStyle: .light,
                                                      displayScale: 2)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 667))
        let base = UIViewController()
        window.rootViewController = base
        window.makeKeyAndVisible()

        let large = UIViewController()
        large.modalPresentationStyle = .pageSheet
        large.sheetPresentationController?.detents = [.large()]
        large.sheetPresentationController?.selectedDetentIdentifier = .large
        base.present(large, animated: false)
        window.layoutIfNeeded()
        let largePC = large.sheetPresentationController!
        XCTAssertEqual(largePC.frameOfPresentedViewInContainerView,
                       CGRect(x: 0, y: 30, width: 375, height: 637))
        base.dismiss(animated: false)

        let medium = UIViewController()
        medium.modalPresentationStyle = .pageSheet
        medium.sheetPresentationController?.detents = [.medium(), .large()]
        base.present(medium, animated: false)
        window.layoutIfNeeded()
        let mf = medium.sheetPresentationController!.frameOfPresentedViewInContainerView
        XCTAssertEqual(mf.minX, 8, accuracy: 1e-9)
        XCTAssertEqual(mf.width, 359, accuracy: 1e-9)
        XCTAssertEqual(mf.height, 356.5 * 359 / 375, accuracy: 1e-6)
        XCTAssertEqual(mf.minY, 667 - 8 - 356.5 * 359 / 375, accuracy: 1e-6)
        XCTAssertEqual(mf.minY, 317.711, accuracy: 0.001)
    }

    /// MEASURED sheetfillprobe / Modal t1200, iPhone SE 2x / iOS 26.1:
    /// floating + `systemBackground` paints 245; floating + `.white` and
    /// large + `systemBackground` stay 255. The view's resolved
    /// systemBackground is still 1 — this is the glass compositor.
    func testFloatingSystemBackgroundGlassFillOnIOS() {
        let saved = OpenUIKitRuntime.systemFontCut
        OpenUIKitRuntime.systemFontCut = .iOS
        defer { OpenUIKitRuntime.systemFontCut = saved }
        UITraitCollection.current = UITraitCollection(userInterfaceStyle: .light,
                                                      displayScale: 2)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 667))
        let base = UIViewController()
        window.rootViewController = base
        window.makeKeyAndVisible()

        let medium = UIViewController()
        medium.view.backgroundColor = .systemBackground
        medium.modalPresentationStyle = .pageSheet
        medium.sheetPresentationController?.detents = [.medium(), .large()]
        base.present(medium, animated: false)
        window.layoutIfNeeded()
        let glass = medium._presentationSheet!.paintedFillColor
            .resolvedCGColor(with: UITraitCollection.current)
        XCTAssertEqual(glass.red, 245.0 / 255.0, accuracy: 1e-9)
        XCTAssertEqual(glass.green, 245.0 / 255.0, accuracy: 1e-9)
        XCTAssertEqual(glass.blue, 245.0 / 255.0, accuracy: 1e-9)
        base.dismiss(animated: false)

        let white = UIViewController()
        white.view.backgroundColor = .white
        white.modalPresentationStyle = .pageSheet
        white.sheetPresentationController?.detents = [.medium()]
        base.present(white, animated: false)
        window.layoutIfNeeded()
        let opaque = white._presentationSheet!.paintedFillColor
            .resolvedCGColor(with: UITraitCollection.current)
        XCTAssertEqual(opaque.red, 1, accuracy: 1e-9)
        base.dismiss(animated: false)

        let large = UIViewController()
        large.view.backgroundColor = .systemBackground
        large.modalPresentationStyle = .pageSheet
        large.sheetPresentationController?.detents = [.large()]
        large.sheetPresentationController?.selectedDetentIdentifier = .large
        base.present(large, animated: false)
        window.layoutIfNeeded()
        let full = large._presentationSheet!.paintedFillColor
            .resolvedCGColor(with: UITraitCollection.current)
        XCTAssertEqual(full.red, 1, accuracy: 1e-9)
    }

    /// MEASURED /tmp/sheetfill_dark + Modal t3200.dark / t1200.dark /
    /// NavFlow t1200.dark, iPhone SE 2x / iOS 26.1: large dark
    /// systemBackground is elevated secondarySystemBackground (28/255);
    /// floating dark fallback is 57/255 (glass samples the dimmed backdrop).
    func testDarkSystemBackgroundSheetFillOnIOS() {
        let saved = OpenUIKitRuntime.systemFontCut
        OpenUIKitRuntime.systemFontCut = .iOS
        defer { OpenUIKitRuntime.systemFontCut = saved }
        UITraitCollection.current = UITraitCollection(userInterfaceStyle: .dark,
                                                      displayScale: 2)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 667))
        window.overrideUserInterfaceStyle = .dark
        let base = UIViewController()
        window.rootViewController = base
        window.makeKeyAndVisible()

        let large = UIViewController()
        large.view.backgroundColor = .systemBackground
        large.modalPresentationStyle = .pageSheet
        large.sheetPresentationController?.detents = [.large()]
        large.sheetPresentationController?.selectedDetentIdentifier = .large
        base.present(large, animated: false)
        window.layoutIfNeeded()
        let full = large._presentationSheet!.paintedFillColor
            .resolvedCGColor(with: UITraitCollection.current)
        XCTAssertEqual(full.red, 28.0 / 255.0, accuracy: 0.002)
        XCTAssertEqual(full.green, 28.0 / 255.0, accuracy: 0.002)
        XCTAssertEqual(full.blue, 30.0 / 255.0, accuracy: 0.002)
        XCTAssertFalse(large._presentationSheet!._usesIOSDarkGlass)
        base.dismiss(animated: false)

        let medium = UIViewController()
        medium.view.backgroundColor = .systemBackground
        medium.modalPresentationStyle = .pageSheet
        medium.sheetPresentationController?.detents = [.medium(), .large()]
        base.present(medium, animated: false)
        window.layoutIfNeeded()
        let glass = medium._presentationSheet!.paintedFillColor
            .resolvedCGColor(with: UITraitCollection.current)
        XCTAssertEqual(glass.red, 57.0 / 255.0, accuracy: 1e-9)
        XCTAssertTrue(medium._presentationSheet!._usesIOSDarkGlass)
        XCTAssertTrue(_UIGlassMaterial.shouldApply(medium._presentationSheet!))
        base.dismiss(animated: false)

        // MEASURED modal_sheet_grabber_dark, iPhone 16 3x / iOS 26.1:
        // presented view with nil background keeps unelevated
        // systemBackground (0, 0, 0). The 28/30 remap is only for an
        // explicit `.systemBackground` (NavFlow / Modal / the probe).
        let implicit = UIViewController()
        implicit.view.backgroundColor = nil
        implicit.modalPresentationStyle = .pageSheet
        implicit.sheetPresentationController?.detents = [.large()]
        implicit.sheetPresentationController?.selectedDetentIdentifier = .large
        base.present(implicit, animated: false)
        window.layoutIfNeeded()
        XCTAssertFalse(implicit._presentationSheet!.presentedViewSetBackground)
        let implicitFill = implicit._presentationSheet!.paintedFillColor
            .resolvedCGColor(with: UITraitCollection.current)
        XCTAssertEqual(implicitFill.red, 0, accuracy: 1e-9)
        XCTAssertEqual(implicitFill.green, 0, accuracy: 1e-9)
        XCTAssertEqual(implicitFill.blue, 0, accuracy: 1e-9)
    }
}

#if !os(Linux)
@MainActor
#endif
final class ScrollViewLayoutGuideTests: XCTestCase {

    /// Constraints against `contentLayoutGuide` are what drive `contentSize`
    /// in every modern "scroll view with Auto Layout" recipe. Three 60 pt
    /// rows in a vertical stack pinned to the content guide, width pinned to
    /// the frame guide -> contentSize 300x180.
    func testContentLayoutGuideDrivesContentSize() {
        let host = UIView(frame: CGRect(x: 0, y: 0, width: 300, height: 100))
        let scroll = UIScrollView(frame: host.bounds)
        host.addSubview(scroll)
        let stack = UIStackView()
        stack.axis = .vertical
        stack.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(stack)
        for _ in 0..<3 {
            let row = UIView()
            stack.addArrangedSubview(row)
            row.heightAnchor.constraint(equalToConstant: 60).isActive = true
        }
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor),
            stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor),
            stack.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor),
        ])
        host.layoutIfNeeded()
        XCTAssertEqual(stack.frame, CGRect(x: 0, y: 0, width: 300, height: 180))
        XCTAssertEqual(scroll.contentSize, CGSize(width: 300, height: 180))
    }

    /// `frameLayoutGuide` is the scroll view's own frame in CONTENT
    /// coordinates, so it tracks the content offset.
    func testFrameLayoutGuideTracksContentOffset() {
        let scroll = UIScrollView(frame: CGRect(x: 0, y: 0, width: 200, height: 120))
        scroll.contentSize = CGSize(width: 200, height: 500)
        XCTAssertEqual(scroll.frameLayoutGuide.layoutFrame,
                       CGRect(x: 0, y: 0, width: 200, height: 120))
        scroll.contentOffset = CGPoint(x: 0, y: 90)
        XCTAssertEqual(scroll.frameLayoutGuide.layoutFrame,
                       CGRect(x: 0, y: 90, width: 200, height: 120))
    }

    /// UIKit's `addArrangedSubview` turns off the autoresizing-mask
    /// translation, which is what lets a row's own size constraints take
    /// effect (M14).
    func testAddArrangedSubviewClearsTranslatesAutoresizingMask() {
        let stack = UIStackView()
        let v = UIView()
        XCTAssertTrue(v.translatesAutoresizingMaskIntoConstraints)
        stack.addArrangedSubview(v)
        XCTAssertFalse(v.translatesAutoresizingMaskIntoConstraints)
    }

    /// A stack sizes its rows from their own size constraints, and reports
    /// the total as its fitting size.
    func testStackHonoursRowSizeConstraints() {
        let stack = UIStackView(frame: CGRect(x: 0, y: 0, width: 200, height: 150))
        stack.axis = .vertical
        for h in [40, 60, 50] {
            let row = UIView()
            stack.addArrangedSubview(row)
            row.heightAnchor.constraint(equalToConstant: CGFloat(h)).isActive = true
        }
        stack.layoutSubviews()
        XCTAssertEqual(stack.arrangedSubviews.map { $0.frame.height }, [40, 60, 50])
        XCTAssertEqual(stack.sizeThatFits(stack.bounds.size).height, 150)
    }
}

#if !os(Linux)
@MainActor
#endif
final class ViewCompatTests: XCTestCase {

    /// Real UIKit's views are NSObjects, so app code writes `a != b` freely.
    func testViewIdentityEquality() {
        let a = UIView(), b = UIView()
        XCTAssertTrue(a == a)
        XCTAssertFalse(a == b)
        XCTAssertNotEqual(a, b)
        XCTAssertEqual(Set([a, b, a]).count, 2)
    }

    func testAccessibilityStorage() {
        let v = UIView()
        v.isAccessibilityElement = true
        v.accessibilityLabel = "Play"
        v.accessibilityTraits = [.button]
        v.accessibilityElementsHidden = true
        XCTAssertTrue(v.isAccessibilityElement)
        XCTAssertEqual(v.accessibilityLabel, "Play")
        XCTAssertTrue(v.accessibilityTraits.contains(.button))
        XCTAssertTrue(v.accessibilityElementsHidden)
    }

    func testSystemLayoutSizeFittingRespectsRequiredAxis() {
        let host = UIView(frame: CGRect(x: 0, y: 0, width: 300, height: 100))
        let stack = UIStackView()
        stack.axis = .vertical
        stack.translatesAutoresizingMaskIntoConstraints = false
        host.addSubview(stack)
        for _ in 0..<2 {
            let row = UIView()
            stack.addArrangedSubview(row)
            row.heightAnchor.constraint(equalToConstant: 44).isActive = true
        }
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: host.topAnchor),
            stack.leadingAnchor.constraint(equalTo: host.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: host.trailingAnchor),
        ])
        host.layoutIfNeeded()
        let fit = stack.systemLayoutSizeFitting(
            CGSize(width: 300, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel)
        XCTAssertEqual(fit.width, 300)
        XCTAssertEqual(fit.height, 88)
    }

    /// MEASURED probe_textstyle_leading + probe_feed_color_label, iPhone SE
    /// 2x / iOS 26.1: preferred `.subheadline` reports `leading` 2.100
    /// (20 − 17.900); `systemFont(ofSize: 15)` reports 0. A 2-line
    /// wrapping label at 343 pt is 38 vs 36.
    func testPreferredFontLeadingAddsBetweenWrappedLinesOnIOS() {
        TextTestSupport.configureResourceRoot()
        let saved = OpenUIKitRuntime.systemFontCut
        OpenUIKitRuntime.systemFontCut = .iOS
        defer { OpenUIKitRuntime.systemFontCut = saved }
        UITraitCollection.current = UITraitCollection(userInterfaceStyle: .light,
                                                     displayScale: 2)

        let preferred = UIFont.preferredFont(forTextStyle: .subheadline)
        let system = UIFont.systemFont(ofSize: 15)
        XCTAssertEqual(preferred.pointSize, 15)
        XCTAssertEqual(preferred.leading, 20 - preferred.lineHeight, accuracy: 1e-6)
        XCTAssertEqual(system.leading, 0, accuracy: 1e-6)

        let body = "A quiet start, then a run of meetings. The 16:9 art is generated, not an asset."
        let wrap = CGSize(width: 343, height: 1e6)
        let prefLabel = UILabel()
        prefLabel.font = preferred
        prefLabel.numberOfLines = 2
        prefLabel.text = body
        XCTAssertEqual(prefLabel.sizeThatFits(wrap).height, 38, accuracy: 1e-6)

        let sysLabel = UILabel()
        sysLabel.font = system
        sysLabel.numberOfLines = 2
        sysLabel.text = body
        XCTAssertEqual(sysLabel.sizeThatFits(wrap).height, 36, accuracy: 1e-6)

        let one = UILabel()
        one.font = preferred
        one.text = "x"
        XCTAssertEqual(one.sizeThatFits(CGSize(width: 100, height: 1e6)).height, 18,
                       accuracy: 1e-6)
    }

    func testRegisterForTraitChangesFires() {
        let v = UIView()
        var fired = 0
        v.registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) {
            (_: UIView, _) in fired += 1
        }
        var previous = v.traitCollection
        previous.preferredContentSizeCategory = .extraLarge
        v._traitsDidChange(previous: previous)
        XCTAssertEqual(fired, 1)
    }
}
