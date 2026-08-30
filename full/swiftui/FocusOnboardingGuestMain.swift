// Project-owned Linux/machorun harness around exact unchanged Focus modules.
import CPortableIO
import Foundation
import Onboarding
import SwiftUI
import Widget

@_silgen_name("open_focus_uuid_compat_probe")
private func openFocusUUIDCompatProbe() -> Int32

@main
@MainActor
struct FocusOnboardingGuestMain {
    private static func fail(_ message: String) -> Never {
        ("FAIL: " + message).withCString { cpio_log_stderr($0) }
        cpio_exit(1)
        fatalError(message)
    }

    private static func require(
        _ condition: @autoclosure () -> Bool,
        _ message: String
    ) {
        if !condition() { fail(message) }
    }

    private static func descendants(_ root: UIView) -> [UIView] {
        root.subviews.flatMap { [$0] + descendants($0) }
    }

    private static func control(in root: UIView, titled title: String) -> UIControl? {
        descendants(root).compactMap { $0 as? UIControl }.first { control in
            descendants(control).compactMap { ($0 as? UILabel)?.text }.contains(title)
        }
    }

    private static func tap(
        _ control: UIControl,
        in window: UIWindow,
        timestamp: TimeInterval
    ) {
        let point = control.convert(
            CGPoint(x: control.bounds.midX, y: control.bounds.midY),
            to: window
        )
        require(window.hitTest(point, with: nil) === control,
                "\(control) is not the window hit-test target")
        window.sendTouch(.began, at: point, timestamp: timestamp)
        window.sendTouch(.ended, at: point, timestamp: timestamp + 0.05)
    }

    private static func actionName(_ action: OnboardingViewModel.Action) -> String {
        switch action {
        case .getStartedAppeared: return "getStartedAppeared"
        case .getStartedCloseTapped: return "getStartedCloseTapped"
        case .getStartedButtonTapped: return "getStartedButtonTapped"
        case .defaultBrowserCloseTapped: return "defaultBrowserCloseTapped"
        case .defaultBrowserSettingsTapped: return "defaultBrowserSettingsTapped"
        case .defaultBrowserSkip: return "defaultBrowserSkip"
        case .defaultBrowserAppeared: return "defaultBrowserAppeared"
        }
    }

    static func main() {
        let arguments = CommandLine.arguments
        require(
            arguments.count == 5,
            "usage: focus_onboarding_guest <Onboarding.bundle> <Widget.bundle> "
                + "<OpenUIKit resources> <font directory>"
        )
        OpenUIKitRuntime.resourceRoot = arguments[3]
        OpenUIKitRuntime.imageScreenScale = 2
        OpenUIKitRuntime.renderBackend = .swift
        OpenUIKitRuntime.compositor = .renderPass
        OpenUIKitRuntime.fontPaths["system"] = arguments[4] + "/DejaVuSans.ttf"
        OpenUIKitRuntime.fontPaths["medium"] = arguments[4] + "/DejaVuSans-Bold.ttf"
        UIImage.clearNamedCache()

        require(
            FocusOnboardingResourceProof.bundlePath == arguments[1],
            "Bundle.module did not identify normalized Focus_Onboarding.bundle"
        )
        require(
            FocusOnboardingResourceProof.resourcePath == arguments[1],
            "Bundle.module resource root did not identify normalized bundle"
        )
        require(
            FocusOnboardingResourceProof.exerciseUnchangedAssets(),
            "unchanged Onboarding named image did not resolve from Bundle.module"
        )
        require(
            FocusWidgetResourceProof.bundlePath == arguments[2],
            "Bundle.module did not identify normalized Focus_Widget.bundle"
        )
        require(
            FocusWidgetResourceProof.resourcePath == arguments[2],
            "Bundle.module resource root did not identify normalized widget bundle"
        )
        FocusWidgetResourceProof.exerciseUnchangedAssets()

        let generatedUUID = UUID()
        let uuidText = generatedUUID.uuidString
        require(uuidText.count == 36, "Foundation UUID did not format 36 characters")
        require(uuidText.dropFirst(14).first == "4", "Foundation UUID is not random/version 4")
        require(UUID(uuidString: uuidText) == generatedUUID,
                "Foundation UUID parse/unparse did not round-trip")
        let uuidProbeResult = openFocusUUIDCompatProbe()
        require(uuidProbeResult == 0,
                "raw Foundation UUID compatibility probe failed: \(uuidProbeResult)")

        var telemetry: [String] = []
        var dismissals = 0
        var openedURL: String?
        UIApplication.urlOpenHandler = {
            openedURL = $0
            return true
        }
        defer { UIApplication.urlOpenHandler = nil }

        let model = OnboardingViewModel(
            config: GetStartedOnboardingViewConfig(
                title: "Welcome to Firefox Focus",
                subtitle: "Fast. Private. No distractions.",
                buttonTitle: "Get Started"
            ),
            defaultBrowserConfig: DefaultBrowserViewConfig(
                title: "Focus isn't like other browsers",
                firstSubtitle: "We clear your history when you close the app for extra privacy",
                secondSubtitle: "Make Focus your default to protect your data with every link you open.",
                topButtonTitle: "Set as Default Browser",
                bottomButtonTitle: "Skip"
            ),
            dismissAction: { dismissals += 1 },
            telemetry: { telemetry.append(actionName($0)) }
        )
        let controller = PortraitHostingController(rootView: OnboardingView(viewModel: model))
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 810))
        window.rootViewController = controller
        window.layoutIfNeeded()
        controller.view.layoutIfNeeded()
        controller.beginAppearanceTransition(true, animated: false)
        controller.endAppearanceTransition()

        let initialLabels = descendants(controller.view).compactMap { ($0 as? UILabel)?.text }
        require(initialLabels.contains("Welcome to Firefox Focus"),
                "exact initial onboarding page did not mount")
        require(telemetry == ["getStartedAppeared"],
                "initial onAppear telemetry changed: \(telemetry)")
        let initialPage = descendants(controller.view).compactMap { $0 as? UIPageControl }.first
        require(initialPage?.numberOfPages == 2 && initialPage?.currentPage == 0,
                "exact TabView page control is not on page zero")

        guard let getStarted = control(in: controller.view, titled: "Get Started") else {
            fail("exact Get Started control was not found")
        }
        tap(getStarted, in: window, timestamp: 0)
        require(
            !descendants(controller.view).compactMap { ($0 as? UILabel)?.text }
                .contains("Focus isn't like other browsers"),
            "published navigation rendered synchronously instead of on a host turn"
        )
        window.tick(timestamp: 0.1)
        controller.view.layoutIfNeeded()

        let secondLabels = descendants(controller.view).compactMap { ($0 as? UILabel)?.text }
        require(secondLabels.contains("Focus isn't like other browsers"),
                "published selection did not mount the exact second page")
        let secondPage = descendants(controller.view).compactMap { $0 as? UIPageControl }.first
        require(secondPage?.currentPage == 1, "page control did not follow published selection")
        require(telemetry == [
            "getStartedAppeared",
            "getStartedButtonTapped",
            "defaultBrowserAppeared",
        ], "second-page telemetry changed: \(telemetry)")

        guard let settings = control(in: controller.view, titled: "Set as Default Browser") else {
            fail("exact default-browser settings control was not found")
        }
        tap(settings, in: window, timestamp: 0.2)
        require(openedURL == UIApplication.openSettingsURLString,
                "Foundation URL bridge did not reach the OpenUIKit host hook")
        require(telemetry.last == "defaultBrowserSettingsTapped",
                "settings telemetry did not fire")

        guard let skip = control(in: controller.view, titled: "Skip") else {
            fail("exact Skip control was not found")
        }
        tap(skip, in: window, timestamp: 0.4)
        require(dismissals == 1, "Skip did not invoke the exact dismissal closure")
        require(telemetry.last == "defaultBrowserSkip", "Skip telemetry did not fire")

        print(
            "FOCUS_ONBOARDING_MACHO_GUEST_OK "
                + "sources=12 pages=2 touches=3 uuid=full telemetry="
                + telemetry.joined(separator: ",")
        )
        cpio_exit(0)
    }
}
