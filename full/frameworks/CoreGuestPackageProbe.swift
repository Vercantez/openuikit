// Project-owned runtime proof for the reusable core guest package. Application
// sources are deliberately absent: this executable proves that the packaged
// framework identities, resources, fonts, observation path, and loader closure
// survive outside the build directories that produced them.
import Foundation
import UIKit
import CoreImage.CIFilterBuiltins
import QuartzCore
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
import CoreGraphics
import ImageIO
import LinkPresentation
import MessageUI
import MobileCoreServices
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
private final class CoreMailDelegate: NSObject, MFMailComposeViewControllerDelegate {
    var result: MFMailComposeResult?
    var receivedServiceUnavailable = false

    nonisolated func mailComposeController(
        _ controller: MFMailComposeViewController,
        didFinishWith result: MFMailComposeResult,
        error: Error?
    ) {
        MainActor.assumeIsolated {
            self.result = result
            self.receivedServiceUnavailable =
                error as? MFMailComposeError == .serviceUnavailable
        }
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
        let foundationCompatibility = runFoundationHackersCompatibilityProbe(
            resourceRoot: CommandLine.arguments[1]
        )
        precondition(
            foundationCompatibility ==
                "locks,filehandle,characters,strings,ranges,attributed,objc,number-bridge,data-search,cfurl,reexports"
        )
        let observationPlatform = runObservationGuestRuntimeProbe()
        precondition(
            observationPlatform ==
                "macro,reexport,registrar,tracking,ignored,one-shot"
        )

        let gradient = CIFilter.linearGradient()
        gradient.color0 = .black
        gradient.color1 = .clear
        gradient.point0 = CGPoint(x: 0, y: 2)
        gradient.point1 = CGPoint(x: 0, y: 0)
        let gradientImage: CoreImage.CGImage = CIContext().createCGImage(
            gradient.outputImage!,
            from: CGRect(x: 0, y: 0, width: 2, height: 2)
        )!
        precondition(gradientImage.width == 2 && gradientImage.height == 2)
        precondition(gradientImage.pixels.count == 16)
        precondition(gradientImage.pixels[3] < gradientImage.pixels[11])
        let layerOwner = UIView()
        precondition(
            _openUIKitQuartzCoreLayerIdentity(layerOwner.layer) ==
                ObjectIdentifier(layerOwner.layer)
        )

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

        let allocatedLock = OSAllocatedUnfairLock<[Int]>(initialState: [])
        let allocatedLockCopy = allocatedLock
        allocatedLock.withLock { $0.append(1) }
        allocatedLockCopy.withLock { $0.append(2) }
        precondition(allocatedLock.withLock { $0 } == [1, 2])

        let ubiquitous = NSUbiquitousKeyValueStore.default
        precondition(ubiquitous === NSUbiquitousKeyValueStore.default)
        let ubiquitousKey = "CoreGuestPackageProbe.data-platform"
        ubiquitous.removeObject(forKey: ubiquitousKey)
        ubiquitous.set(Data([1, 2, 3]), forKey: ubiquitousKey)
        precondition(ubiquitous.synchronize())
        precondition(ubiquitous.data(forKey: ubiquitousKey) == Data([1, 2, 3]))
        ubiquitous.removeObject(forKey: ubiquitousKey)

        let relative = RelativeDateTimeFormatter()
        relative.locale = Locale(identifier: "en_US_POSIX")
        var relativeCalendar = Calendar(identifier: .gregorian)
        relativeCalendar.locale = relative.locale
        relativeCalendar.timeZone = TimeZone(secondsFromGMT: 0)!
        relative.calendar = relativeCalendar
        let relativeReference = Date(timeIntervalSince1970: 1_700_000_000)
        precondition(
            relative.localizedString(
                for: relativeReference.addingTimeInterval(-7_200),
                relativeTo: relativeReference
            ) == "2 hours ago"
        )
        relative.locale = Locale(identifier: "fr_FR")
        precondition(
            relative.localizedString(
                for: relativeReference.addingTimeInterval(86_400),
                relativeTo: relativeReference
            ) == "dans 1 jour"
        )

        let fileManager = FileManager.default
        let enumerationRoot = URL(
            fileURLWithPath: "/tmp/open-foundation-core-enumerator",
            isDirectory: true
        )
        try? fileManager.removeItem(at: enumerationRoot)
        defer { try? fileManager.removeItem(at: enumerationRoot) }
        try! fileManager.createDirectory(
            at: enumerationRoot.appendingPathComponent(
                "Nested",
                isDirectory: true
            ),
            withIntermediateDirectories: true
        )
        try! fileManager.createDirectory(
            at: enumerationRoot.appendingPathComponent(
                "Example.bundle",
                isDirectory: true
            ),
            withIntermediateDirectories: true
        )
        try! Data([1, 2, 3]).write(
            to: enumerationRoot.appendingPathComponent("visible.bin")
        )
        try! Data([4]).write(
            to: enumerationRoot.appendingPathComponent(".hidden")
        )
        try! Data([5]).write(
            to: enumerationRoot.appendingPathComponent("Nested/inside")
        )
        try! Data([6]).write(
            to: enumerationRoot.appendingPathComponent(
                "Example.bundle/inside"
            )
        )
        let fileKeys: Set<URLResourceKey> = [
            .isRegularFileKey,
            .fileAllocatedSizeKey,
            .totalFileAllocatedSizeKey,
        ]
        let enumerator = fileManager.enumerator(
            at: enumerationRoot,
            includingPropertiesForKeys: Array(fileKeys),
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        )!
        let enumerated = enumerator.compactMap { value -> String? in
            guard let url = value as? URL,
                  let rootIndex = url.pathComponents.lastIndex(
                    of: enumerationRoot.lastPathComponent
                  ) else { return nil }
            return url.pathComponents.dropFirst(rootIndex + 1)
                .joined(separator: "/")
        }.sorted()
        precondition(enumerated == [
            "Example.bundle",
            "Nested",
            "Nested/inside",
            "visible.bin",
        ])
        let visibleValues = try! enumerationRoot
            .appendingPathComponent("visible.bin")
            .resourceValues(forKeys: fileKeys)
        precondition(visibleValues.isRegularFile == true)
        precondition(
            (visibleValues.totalFileAllocatedSize ??
                visibleValues.fileAllocatedSize ?? 0) >= 3
        )

        let portableProduct = Product(
            id: "core.product",
            displayName: "Core Product",
            description: "Portable StoreKit model",
            price: Decimal(string: "1.99")!,
            displayPrice: "USD 1.99"
        )
        precondition(portableProduct.displayPrice == "USD 1.99")
        let portableTransaction = Transaction(
            id: 1,
            productID: portableProduct.id,
            purchaseDate: relativeReference,
            expirationDate: relativeReference.addingTimeInterval(60),
            revocationDate: nil
        )
        precondition(portableTransaction.expirationDate != nil)
        precondition(portableTransaction.revocationDate == nil)
        switch StoreKitError.userCancelled {
        case .userCancelled: break
        default: preconditionFailure("StoreKit cancellation identity drifted")
        }
        let dataPlatform =
            "lock,kvs,relative-time-icu,filesystem,storekit-model"

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

        let bitmap = CoreGraphics.CGImage(width: 2, height: 1)
        bitmap.pixels = [255, 0, 0, 255, 0, 128, 255, 192]
        let encoded = Data(bitmap.pngData())
        let imageSource = CGImageSourceCreateWithData(encoded as CFData, nil)!
        precondition(CGImageSourceGetCount(imageSource) == 1)
        precondition(CGImageSourceGetType(imageSource) == "public.png")
        let decoded = CGImageSourceCreateImageAtIndex(imageSource, 0, nil)!
        precondition(decoded.width == 2 && decoded.height == 1)
        precondition(decoded.pixels == bitmap.pixels)
        precondition(CGImageSourceCreateImageAtIndex(imageSource, 1, nil) == nil)

        let metadata = LPLinkMetadata()
        metadata.title = "Core package"
        metadata.url = URL(string: "https://core.invalid/share")
        metadata.originalURL = metadata.url
        precondition(metadata.title == "Core package")
        precondition(metadata.originalURL == metadata.url)

        precondition(!MFMailComposeViewController.canSendMail())
        let mailController = MFMailComposeViewController()
        mailController.setToRecipients(["portable@example.invalid"])
        mailController.setSubject("Core package")
        mailController.setMessageBody("Linux", isHTML: false)
        precondition(mailController.portableToRecipients == ["portable@example.invalid"])
        precondition(mailController.portableSubject == "Core package")
        let mailDelegate = CoreMailDelegate()
        mailController.mailComposeDelegate = mailDelegate
        mailController.reportPortableServiceUnavailable()
        precondition(mailDelegate.result == .failed)
        precondition(mailDelegate.receivedServiceUnavailable)
        precondition(kUTTypeURL == "public.url" && kUTTypePNG == "public.png")

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
                + "foundation=\(foundationCompatibility) "
                + "data-platform=\(dataPlatform) "
                + "observation=\(observationPlatform) "
                + "graphics=coreimage,quartzcore "
                + "intentsui=host-driven swiftui-app=constructed "
                + "first-party=portable-12 "
                + "webkit=engine-unavailable preview=\(preview)"
        )
    }
}
