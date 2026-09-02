import XCTest
@testable import OpenUIKit

@MainActor
private final class AdjustedInsetRecorder: UIScrollViewDelegate {
    var values: [UIEdgeInsets] = []

    func scrollViewDidChangeAdjustedContentInset(_ scrollView: UIScrollView) {
        values.append(scrollView.adjustedContentInset)
    }
}

@MainActor
final class ApplicationShellCompatibilityTests: XCTestCase {
    private final class ActivityRestorer: UIUserActivityRestoring {
        var restoredType: String?

        func restoreUserActivityState(_ userActivity: NSUserActivity) {
            restoredType = userActivity.activityType
        }
    }

    private final class OverridingActivity: NSUserActivity {
        override var activityType: String { super.activityType + ".override" }
    }

    func testSceneWindowUsesSceneScreenAndWindowLevelsSupportArithmetic() {
        let scene = UIWindowScene()
        let window = UIWindow(windowScene: scene)

        XCTAssertTrue(window.windowScene === scene)
        XCTAssertEqual(window.frame, scene.screen.bounds)
        XCTAssertEqual(window.windowLevel, .normal)

        window.windowLevel = .alert + 1
        XCTAssertEqual(window.windowLevel.rawValue, 2_001)
        XCTAssertGreaterThan(window.windowLevel, .statusBar)
    }

    func testNavigationAppearanceProxyIsInheritedByNewBars() {
        let proxy = UINavigationBar.appearance()
        let originalStandard = proxy._standardAppearance
        let originalStandardIsExplicit = proxy._standardAppearanceIsExplicit
        let originalEdge = proxy.scrollEdgeAppearance
        let originalCompact = proxy.compactAppearance
        let originalBackgroundImages = proxy._legacyBackgroundImages
        let originalShadowImage = proxy.shadowImage
        let originalTitleAttributes = proxy.titleTextAttributes
        let originalLargeTitleAttributes = proxy.largeTitleTextAttributes
        let originalIsTranslucent = proxy.isTranslucent
        defer {
            proxy._standardAppearance = originalStandard
            proxy._standardAppearanceIsExplicit = originalStandardIsExplicit
            proxy.scrollEdgeAppearance = originalEdge
            proxy.compactAppearance = originalCompact
            proxy._legacyBackgroundImages = originalBackgroundImages
            proxy.shadowImage = originalShadowImage
            proxy.titleTextAttributes = originalTitleAttributes
            proxy.largeTitleTextAttributes = originalLargeTitleAttributes
            proxy.isTranslucent = originalIsTranslucent
            proxy.applyAppearance()
        }

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemPurple
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.systemBlue,
        ]
        appearance.backButtonAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.systemOrange,
        ]
        let indicator = UIImage(bitmap: Bitmap(width: 1, height: 1))
        appearance.setBackIndicatorImage(indicator, transitionMaskImage: indicator)
        proxy.standardAppearance = appearance
        proxy.scrollEdgeAppearance = appearance
        let emptyBackground = UIImage()
        let emptyShadow = UIImage()
        proxy.setBackgroundImage(emptyBackground, for: .default)
        proxy.shadowImage = emptyShadow
        proxy.titleTextAttributes = [
            .foregroundColor: UIColor.systemRed,
        ]

        let bar = UINavigationBar()
        XCTAssertTrue(bar.standardAppearance === appearance)
        XCTAssertTrue(bar.scrollEdgeAppearance === appearance)
        XCTAssertTrue(bar._standardAppearanceIsExplicit)
        XCTAssertTrue(appearance.backIndicatorImage === indicator)
        XCTAssertTrue(appearance.backIndicatorTransitionMaskImage === indicator)
        XCTAssertTrue(bar.backgroundImage(for: .default) === emptyBackground)
        XCTAssertTrue(bar.shadowImage === emptyShadow)

        bar.setState(title: "Details", backTitle: "Back")
        XCTAssertEqual(bar.backgroundColor, .systemPurple)
        XCTAssertNil(bar.backgroundImageView.image,
                     "the proxy's explicit modern appearance wins as a whole")
        XCTAssertTrue(bar.backgroundImageView.isHidden)
        XCTAssertFalse(bar.hairline.isHidden)
        XCTAssertEqual(bar.titleLabel.textColor, .systemBlue)
        XCTAssertEqual(bar.backButton?.backLabel.textColor, .systemOrange)
        XCTAssertEqual(bar.backButton?.chevron.textColor, .systemOrange)
    }

    func testBaseViewAppearanceTintIsInheritedWithoutReplacingHierarchyTint() {
        let proxy = UIView.appearance()
        let original = proxy._tintColor
        defer { proxy._tintColor = original }

        proxy.tintColor = .systemOrange
        let inherited = UIView()
        XCTAssertEqual(inherited.tintColor, .systemOrange)

        inherited.tintColor = .systemPurple
        XCTAssertEqual(inherited.tintColor, .systemPurple)
        XCTAssertEqual(UIView().tintColor, .systemOrange)
    }

    func testRectConversionUsesAllTransformedCornersAndRoundTripsPoints() {
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        let child = UIView(frame: CGRect(x: 40, y: 45, width: 20, height: 10))
        child.transform = CGAffineTransform(rotationAngle: .pi / 2)
        root.addSubview(child)

        let converted = child.convert(child.bounds, to: root)
        XCTAssertEqual(converted.minX, 45, accuracy: 0.001)
        XCTAssertEqual(converted.minY, 40, accuracy: 0.001)
        XCTAssertEqual(converted.width, 10, accuracy: 0.001)
        XCTAssertEqual(converted.height, 20, accuracy: 0.001)

        let local = CGPoint(x: 3, y: 7)
        let inRoot = child.convert(local, to: root)
        let roundTrip = child.convert(inRoot, from: root)
        XCTAssertEqual(roundTrip.x, local.x, accuracy: 0.001)
        XCTAssertEqual(roundTrip.y, local.y, accuracy: 0.001)
    }

    func testColorDecompositionAdjustedInsetsAndGestureShellDefaults() throws {
        let previous = UITraitCollection.current
        defer { UITraitCollection.current = previous }
        UITraitCollection.current = UITraitCollection(
            userInterfaceStyle: .dark,
            displayScale: 3
        )

        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        let color = UIColor(red: 0.2, green: 0.4, blue: 0.6, alpha: 0.8)
        XCTAssertTrue(color.getRed(&red, green: &green, blue: &blue, alpha: &alpha))
        XCTAssertEqual(red, 0.2, accuracy: 0.001)
        XCTAssertEqual(green, 0.4, accuracy: 0.001)
        XCTAssertEqual(blue, 0.6, accuracy: 0.001)
        XCTAssertEqual(alpha, 0.8, accuracy: 0.001)
        var white: CGFloat = 0
        XCTAssertFalse(color.getWhite(&white, alpha: nil))
        XCTAssertTrue(UIColor(white: 0.3, alpha: 0.7).getWhite(&white, alpha: &alpha))
        XCTAssertEqual(white, 0.3, accuracy: 0.001)
        XCTAssertEqual(alpha, 0.7, accuracy: 0.001)

        let recorder = AdjustedInsetRecorder()
        let scroll = UIScrollView(frame: CGRect(x: 0, y: 0, width: 100, height: 120))
        scroll.delegate = recorder
        scroll.contentInset = UIEdgeInsets(top: 1, left: 2, bottom: 3, right: 4)
        scroll._setSafeAreaInsets(UIEdgeInsets(top: 10, left: 20, bottom: 30, right: 40))
        XCTAssertEqual(
            scroll.adjustedContentInset,
            UIEdgeInsets(top: 11, left: 22, bottom: 33, right: 44)
        )
        XCTAssertEqual(recorder.values.last, scroll.adjustedContentInset)
        scroll.verticalScrollIndicatorInsets = UIEdgeInsets(top: 5, right: 7)
        scroll.horizontalScrollIndicatorInsets = UIEdgeInsets(bottom: 9, right: 11)
        XCTAssertEqual(scroll.verticalScrollIndicatorInsets.top, 5)
        XCTAssertEqual(scroll.horizontalScrollIndicatorInsets.bottom, 9)

        let recognizer = UIGestureRecognizer()
        XCTAssertFalse(recognizer.delaysTouchesBegan)
        XCTAssertTrue(recognizer.delaysTouchesEnded)

        let navigation = UINavigationController(rootViewController: UIViewController())
        navigation.loadViewIfNeeded()
        XCTAssertTrue(
            try XCTUnwrap(navigation.interactiveContentPopGestureRecognizer)
                === navigation.interactivePopGestureRecognizer
        )
    }

    func testOverlayPresentationFillsWindowWithoutRemovingPresenter() {
        let presenter = UIViewController()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        window.rootViewController = presenter

        let overlay = UIViewController()
        overlay.modalPresentationStyle = .overCurrentContext
        presenter.present(overlay, animated: false)

        XCTAssertEqual(overlay.view.frame, window.bounds)
        XCTAssertNotNil(presenter.view.superview)
        XCTAssertTrue(presenter.presentedViewController === overlay)
    }

    func testFoundationURLUsesThePortableHostHook() {
        let prior = UIApplication.urlOpenHandler
        defer { UIApplication.urlOpenHandler = prior }
        var opened: String?
        UIApplication.urlOpenHandler = {
            opened = $0
            return $0 == "https://example.com/path"
        }

        let url = URL(string: "https://example.com/path")!
        XCTAssertTrue(UIApplication.shared.canOpenURL(url))
        var result: Bool?
        UIApplication.shared.open(url, options: [.universalLinksOnly: true]) {
            result = $0
        }
        XCTAssertEqual(opened, url.absoluteString)
        XCTAssertEqual(result, true)
        XCTAssertEqual(UIApplication.openSettingsURLString, "app-settings:")
    }

    func testShortcutAndIncomingURLMetadataShapes() {
        let icon = UIApplicationShortcutIcon(systemImageName: "trash")
        let item = UIApplicationShortcutItem(
            type: "org.example.erase", localizedTitle: "Erase",
            localizedSubtitle: "Erase and open", icon: icon)
        XCTAssertEqual(item.type, "org.example.erase")
        XCTAssertEqual(item.localizedTitle, "Erase")
        XCTAssertEqual(item.localizedSubtitle, "Erase and open")
        XCTAssertTrue(item.icon === icon)

        let options: [UIApplication.OpenURLOptionsKey: Any] = [
            .sourceApplication: "org.example.sender",
            .openInPlace: true,
        ]
        XCTAssertEqual(options[.sourceApplication] as? String,
                       "org.example.sender")

        let restorer = ActivityRestorer()
        restorer.restoreUserActivityState(NSUserActivity(activityType: "org.example.activity"))
        XCTAssertEqual(restorer.restoredType, "org.example.activity")

        let overridden = OverridingActivity(activityType: "org.example.activity")
        let object: NSObject = overridden
        XCTAssertTrue(object === overridden)
        XCTAssertEqual(overridden.activityType, "org.example.activity.override")
    }
}
