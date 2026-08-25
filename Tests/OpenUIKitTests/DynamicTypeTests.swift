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

private typealias CGFloat = OpenUIKit.CGFloat
private typealias CGRect = OpenUIKit.CGRect
private typealias CGSize = OpenUIKit.CGSize
private typealias CGPoint = OpenUIKit.CGPoint

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
}

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
}

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
        XCTAssertTrue(v.isAccessibilityElement)
        XCTAssertEqual(v.accessibilityLabel, "Play")
        XCTAssertTrue(v.accessibilityTraits.contains(.button))
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

    func testRegisterForTraitChangesFires() {
        let v = UIView()
        var fired = 0
        v.registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) {
            (_: UIView, _) in fired += 1
        }
        v._traitsDidChange(previous: UITraitCollection.current)
        XCTAssertEqual(fired, 1)
    }
}
