// Project-owned runtime proof for the reusable core guest package. Application
// sources are deliberately absent: this executable proves that the packaged
// framework identities, resources, fonts, observation path, and loader closure
// survive outside the build directories that produced them.
import Foundation
import UIKit
import SwiftUI
import Combine
@_spi(OpenIntentsHost) import Intents
import IntentsUI
import LocalAuthentication
import SafariServices
import Network
import StoreKit
import AudioToolbox
import CoreHaptics
import PassKit
import WebKit

@MainActor
private final class CoreWebKitDelegate: WKNavigationDelegate {
    var policies = 0
    var starts = 0
    var provisionalFailures = 0
    var commits = 0
    var finishes = 0
    var error: WKPortableError?

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        preferences: WKWebpagePreferences,
        decisionHandler: @escaping (
            WKNavigationActionPolicy, WKWebpagePreferences
        ) -> Void
    ) {
        policies += 1
        preferences.preferredContentMode = .desktop
        decisionHandler(.allow, preferences)
    }

    func webView(
        _ webView: WKWebView,
        didStartProvisionalNavigation navigation: WKNavigation?
    ) {
        starts += 1
        precondition(navigation?.effectiveContentMode == .desktop)
    }

    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation?,
        withError error: Error
    ) {
        provisionalFailures += 1
        self.error = error as? WKPortableError
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation?) {
        commits += 1
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation?) {
        finishes += 1
    }
}

private final class CoreProbeIntent: INIntent, @unchecked Sendable {}

private final class CoreStoreObserver: SKPaymentTransactionObserver {
    var states: [SKPaymentTransactionState] = []

    func paymentQueue(
        _ queue: SKPaymentQueue,
        updatedTransactions transactions: [SKPaymentTransaction]
    ) {
        states.append(contentsOf: transactions.map(\.transactionState))
    }
}

@MainActor
private final class CoreLifecycleDelegate: NSObject, UIApplicationDelegate {}

@MainActor
private struct CoreLifecycleApplication: App {
    @UIApplicationDelegateAdaptor(CoreLifecycleDelegate.self)
    private var delegate

    var body: some Scene {
        WindowGroup("Core package") {
            Text("SwiftUI lifecycle")
        }
    }
}

@MainActor
private final class CoreSafariDelegate: SFSafariViewControllerDelegate {
    var loads: [Bool] = []

    func safariViewController(
        _ controller: SFSafariViewController,
        didCompleteInitialLoad didLoadSuccessfully: Bool
    ) {
        loads.append(didLoadSuccessfully)
    }
}

#if canImport(DeveloperToolsSupport)
@_spi(OpenUIKitPreview) import DeveloperToolsSupport

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
private struct CorePreviewRegistry: DeveloperToolsSupport.PreviewRegistry {
    static let fileID = "CoreGuestPackageProbe.swift"
    static let line = 1
    static let column = 1

    @MainActor static let retainedView = UIView()

    @MainActor
    static func makePreview() throws -> DeveloperToolsSupport.Preview {
        DeveloperToolsSupport.Preview(body: { retainedView })
    }
}
#endif

@main
struct CoreGuestPackageProbe {
    @MainActor
    static func main() {
        guard CommandLine.arguments.count == 4 else {
            fatalError(
                "usage: CoreGuestPackageProbe <resource-root> <system-font> <bold-font>"
            )
        }

        OpenUIKitRuntime.resourceRoot = CommandLine.arguments[1]
        OpenUIKitRuntime.fontPaths = [
            "system": CommandLine.arguments[2],
            "bold": CommandLine.arguments[3],
        ]

        let foundationNotification: Foundation.Notification.Type =
            Foundation.Notification.self
        let _: UIKit.Notification.Type = foundationNotification
        let foundationCenter: Foundation.NotificationCenter.Type =
            Foundation.NotificationCenter.self
        let _: UIKit.NotificationCenter.Type = foundationCenter
        let foundationQueue: Foundation.OperationQueue.Type =
            Foundation.OperationQueue.self
        let _: UIKit.OperationQueue.Type = foundationQueue

        let center = NotificationCenter()
        let name = Notification.Name("CoreGuestPackageProbe")
        var deliveries = 0
        let token = center.addObserver(
            forName: name,
            object: nil,
            queue: nil
        ) { _ in
            deliveries += 1
        }
        center.post(name: name, object: nil)
        center.removeObserver(token)
        precondition(deliveries == 1)

        let subject = PassthroughSubject<Int, Never>()
        var values: [Int] = []
        let cancellable = subject.sink { values.append($0) }
        subject.send(7)
        withExtendedLifetime(cancellable) {}
        precondition(values == [7])

        var request = URLRequest(
            url: URL(string: "https://core-webkit.invalid/")!
        )
        request.setValue("guest", forHTTPHeaderField: "X-Portable-WebKit")
        precondition(
            request.value(forHTTPHeaderField: "x-portable-webkit") == "guest"
        )
        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.websiteDataStore = .nonPersistent()
        let webView = WKWebView(
            frame: CGRect(x: 0, y: 0, width: 320, height: 480),
            configuration: webConfiguration
        )
        precondition(webView.configuration !== webConfiguration)
        precondition(
            webView.configuration.websiteDataStore ===
                webConfiguration.websiteDataStore
        )
        let webDelegate = CoreWebKitDelegate()
        webView.navigationDelegate = webDelegate
        let navigation = webView.load(request)
        precondition(navigation?.effectiveContentMode == .desktop)
        precondition(webDelegate.policies == 1 && webDelegate.starts == 1)
        precondition(webDelegate.provisionalFailures == 1)
        precondition(webDelegate.commits == 0 && webDelegate.finishes == 0)
        precondition(webDelegate.error?.code == .engineUnavailable)
        precondition(webView.lastPortableError?.code == .engineUnavailable)
        precondition(!webView.isLoading)
        precondition(webView.backForwardList.currentItem == nil)
        var javaScriptFailures = 0
        webView.evaluateJavaScript("document.title") { value, error in
            precondition(value == nil)
            precondition((error as? WKPortableError)?.code == .engineUnavailable)
            javaScriptFailures += 1
        }
        precondition(javaScriptFailures == 1)

        let auth = LAContext()
        var authError: LAError?
        precondition(
            !auth.canEvaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                error: &authError
            )
        )
        precondition(authError?.code == .biometryNotAvailable)

        let safariConfiguration = SFSafariViewController.Configuration()
        safariConfiguration.entersReaderIfAvailable = true
        let safari = SFSafariViewController(
            url: URL(string: "https://core.invalid/")!,
            configuration: safariConfiguration
        )
        precondition(safari.configuration !== safariConfiguration)
        let safariDelegate = CoreSafariDelegate()
        safari.delegate = safariDelegate
        safari.reportPortableInitialLoadFailure()
        precondition(safariDelegate.loads == [false])

        let monitor = NWPathMonitor()
        precondition(IPv4Address("127.0.0.1")?.rawValue == Data([127, 0, 0, 1]))
        precondition(IPv4Address("300.0.0.1") == nil)
        precondition(IPv6Address("fc00::1")?.rawValue.first == 0xfc)
        var pathStatuses: [NWPath.Status] = []
        monitor.pathUpdateHandler = { pathStatuses.append($0.status) }
        monitor.start(queue: "core-probe-monitor")
        precondition(pathStatuses == [.unsatisfied])
        let connection = NWConnection(
            to: .hostPort(host: "core.invalid", port: .https),
            using: .tcp
        )
        var connectionState: NWConnection.State?
        connection.stateUpdateHandler = { connectionState = $0 }
        connection.start(queue: "core-probe-connection")
        precondition(connectionState == .failed(.unsupported))

        let reviewCount = SKStoreReviewController.portableRequestCount
        SKStoreReviewController.requestReview()
        precondition(
            SKStoreReviewController.portableRequestCount == reviewCount + 1
        )
        let storeObserver = CoreStoreObserver()
        let paymentQueue = SKPaymentQueue.default()
        paymentQueue.add(storeObserver)
        paymentQueue.add(
            SKPayment(product: SKProduct(productIdentifier: "core.invalid"))
        )
        precondition(storeObserver.states == [.failed])
        paymentQueue.remove(storeObserver)

        AudioToolboxPortable.resetRequestHistory()
        AudioServicesPlaySystemSound(1519)
        precondition(AudioToolboxPortable.requestedSystemSounds == [1519])
        precondition(AudioToolboxPortable.playbackDisposition == .unsupported)

        precondition(!CHHapticEngine.capabilitiesForHardware().supportsHaptics)
        let hapticEvent = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 1)
            ],
            relativeTime: 0
        )
        let hapticPattern = try! CHHapticPattern(
            events: [hapticEvent],
            parameters: []
        )
        let hapticEngine = try! CHHapticEngine()
        let hapticPlayer = try! hapticEngine.makePlayer(with: hapticPattern)
        do {
            try hapticPlayer.start(atTime: CHHapticTimeImmediate)
            preconditionFailure("portable haptic player reported success")
        } catch let error as CHHapticError {
            precondition(error.code == .notSupported)
        } catch {
            preconditionFailure("unexpected haptic error")
        }

        do {
            _ = try PKPass(data: Data([0x50, 0x4B]))
            preconditionFailure("portable PassKit accepted unverifiable data")
        } catch let error as PassKitPortableError {
            precondition(error.code == .passValidationUnavailable)
        } catch {
            preconditionFailure("unexpected pass error")
        }
        precondition(!PKPaymentAuthorizationController.canMakePayments())

        _ = Text("core-package")
        let lifecycleApplication = CoreLifecycleApplication()
        _ = lifecycleApplication.body
        let lifecycleMain: @MainActor () -> Void = CoreLifecycleApplication.main
        withExtendedLifetime(lifecycleMain) {}
        let label = UIColor.label
        let system = UIFont.systemFont(ofSize: 17)
        let bold = UIFont.boldSystemFont(ofSize: 17)
        precondition(system.pointSize == 17)
        precondition(bold.pointSize == 17)
        _ = label

        INVoiceShortcutCenter.shared.removeAll()
        let intent = CoreProbeIntent()
        intent.suggestedInvocationPhrase = "Core package"
        let shortcut = INShortcut(intent: intent)
        let installed = INVoiceShortcutCenter.shared.install(
            shortcut,
            invocationPhrase: "Core package"
        )
        var shortcuts: [INVoiceShortcut] = []
        INVoiceShortcutCenter.shared.getAllVoiceShortcuts { values, error in
            precondition(error == nil)
            shortcuts = values ?? []
        }
        precondition(shortcuts.count == 1)
        precondition(shortcuts[0] === installed)
        let interaction = INInteraction(intent: intent, response: nil)
        interaction.donate()
        precondition(INInteraction.donatedInteractions.count == 1)
        INInteraction.deleteAll()
        precondition(INInteraction.donatedInteractions.isEmpty)
        let addController = INUIAddVoiceShortcutViewController(shortcut: shortcut)
        precondition(
            type(of: addController).presentationCapability == .hostDriven
        )

        #if canImport(DeveloperToolsSupport)
        if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *) {
            let value = try! CorePreviewRegistry.makePreview()
            precondition(
                value._openUIKitBody() as AnyObject ===
                    CorePreviewRegistry.retainedView
            )
        }
        let preview = "enabled"
        #else
        let preview = "disabled"
        #endif
        print(
            "CORE_GUEST_PACKAGE_MACHO_OK "
                + "notification=shared combine=delivered resources=loaded "
                + "fonts=system,bold intents=donated shortcuts=stored "
                + "intentsui=host-driven swiftui-app=constructed "
                + "first-party=fail-closed-7 "
                + "webkit=engine-unavailable preview=\(preview)"
        )
    }
}
