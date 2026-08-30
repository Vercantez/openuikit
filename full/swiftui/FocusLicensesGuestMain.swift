// Project-owned Linux/machorun harness for Focus's unchanged Licenses target.
import Licenses
import SwiftUI
import UIKit

@main
@MainActor
struct FocusLicensesGuestMain {
    private static func fail(_ message: String) -> Never {
        fatalError("FAIL: " + message)
    }

    private static func allViews(from root: UIView) -> [UIView] {
        [root] + root.subviews.flatMap(allViews)
    }

    static func main() {
        let arguments = CommandLine.arguments
        guard arguments.count == 2 else {
            fail("usage: FocusLicensesGuest <FocusLicensesGuest.app>")
        }
        let expectedBundle = arguments[1] + "/Focus_Licenses.bundle"
        guard FocusLicensesResourceProof.bundlePath == expectedBundle,
              FocusLicensesResourceProof.resourcePath == expectedBundle,
              FocusLicensesResourceProof.focusLicensePath ==
                expectedBundle + "/focus-ios.plist",
              FocusLicensesResourceProof.libraryLicensesPath ==
                expectedBundle + "/license-list.plist",
              FocusLicensesResourceProof.missingResourcePath == nil else {
            fail("Bundle.module did not identify exact Focus_Licenses.bundle")
        }

        let host = UIHostingController(rootView: LicenseListView())
        let navigation = UINavigationController(rootViewController: host)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = navigation
        window.makeKeyAndVisible()
        window.layoutIfNeeded()

        let links = allViews(from: window).compactMap { $0 as? UIControl }.filter {
            $0.accessibilityIdentifier == "SwiftUI.NavigationLink"
        }
        guard links.count == 8 else {
            fail("decoded license rows: \(links.count)")
        }

        guard let firstLink = links.first else {
            fail("missing first license navigation link")
        }
        let point = firstLink.convert(
            CGPoint(x: firstLink.bounds.midX, y: firstLink.bounds.midY),
            to: window
        )
        guard window.hitTest(point, with: nil) === firstLink else {
            fail("license link is not the window hit-test target")
        }
        window.sendTouch(.began, at: point, timestamp: 0)
        window.sendTouch(.ended, at: point, timestamp: 0.01)
        window.tick(timestamp: 0.1)
        window.layoutIfNeeded()
        guard navigation.viewControllers.count == 2 else {
            fail("license navigation push")
        }

        print(
            "FOCUS_LICENSES_MACHO_GUEST_OK "
                + "sources=2 resources=2 bundle=module rows=8 navigation=push"
        )
    }
}
