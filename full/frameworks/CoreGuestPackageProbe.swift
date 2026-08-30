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
                + "intentsui=host-driven first-party=fail-closed-7 "
                + "preview=\(preview)"
        )
    }
}
