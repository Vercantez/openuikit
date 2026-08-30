import Foundation
import Dispatch
import LocalAuthentication
import SafariServices
import Network
import StoreKit
import AudioToolbox
import CoreHaptics
import PassKit

private final class SynchronousReplyCounter: @unchecked Sendable {
    var value = 0
}

private final class LocalAuthenticationCombineReexportProbe {
    @Published var value = 0
}

private final class PaymentObserver: SKPaymentTransactionObserver {
    var states: [SKPaymentTransactionState] = []
    var restorationFailed = false

    func paymentQueue(
        _ queue: SKPaymentQueue,
        updatedTransactions transactions: [SKPaymentTransaction]
    ) {
        states.append(contentsOf: transactions.map(\.transactionState))
    }

    func paymentQueue(
        _ queue: SKPaymentQueue,
        restoreCompletedTransactionsFailedWithError error: Error
    ) {
        restorationFailed = true
    }
}

@MainActor
private final class SafariDelegate: SFSafariViewControllerDelegate {
    var initialLoads: [Bool] = []
    func safariViewController(
        _ controller: SFSafariViewController,
        didCompleteInitialLoad didLoadSuccessfully: Bool
    ) {
        initialLoads.append(didLoadSuccessfully)
    }
}

@main
private struct FirstPartyHostRuntime {
    @MainActor
    static func main() async {
        let context = LAContext()
        var authError: LAError?
        precondition(
            !context.canEvaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                error: &authError
            )
        )
        precondition(authError?.code == .biometryNotAvailable)
        precondition(context.biometryType == .none)
        let authReplies = SynchronousReplyCounter()
        context.evaluatePolicy(
            .deviceOwnerAuthentication,
            localizedReason: "host gate"
        ) { success, error in
            precondition(!success)
            precondition((error as? LAError)?.code == .biometryNotAvailable)
            authReplies.value += 1
        }
        precondition(authReplies.value == 1)
        do {
            _ = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: "host gate async"
            )
            preconditionFailure("portable authentication reported success")
        } catch let error as LAError {
            precondition(error.code == .biometryNotAvailable)
        } catch {
            preconditionFailure("unexpected authentication error")
        }
        let reexport = LocalAuthenticationCombineReexportProbe()
        var reexportValues: [Int] = []
        let reexportToken = reexport.$value.sink { reexportValues.append($0) }
        reexport.value = 1
        withExtendedLifetime(reexportToken) {}
        precondition(reexportValues == [0, 1])

        let safariConfiguration = SFSafariViewController.Configuration()
        safariConfiguration.entersReaderIfAvailable = true
        let safari = SFSafariViewController(
            url: URL(string: "https://example.invalid/")!,
            configuration: safariConfiguration
        )
        precondition(safari.configuration !== safariConfiguration)
        precondition(safari.configuration.entersReaderIfAvailable)
        let safariDelegate = SafariDelegate()
        safari.delegate = safariDelegate
        safari.reportPortableInitialLoadFailure()
        precondition(safariDelegate.initialLoads == [false])
        var blockerCallbacks = 0
        SFContentBlockerManager.getStateOfContentBlocker(
            withIdentifier: "portable.blocker"
        ) { state, error in
            precondition(state == nil)
            precondition(
                (error as? SafariServicesPortableError)?.code
                    == .contentBlockerServiceUnavailable
            )
            blockerCallbacks += 1
        }
        precondition(blockerCallbacks == 1)

        let monitor = NWPathMonitor(requiredInterfaceType: .wifi)
        precondition(IPv4Address("127.0.0.1")?.rawValue == Data([127, 0, 0, 1]))
        precondition(IPv4Address("999.0.0.1") == nil)
        precondition(IPv6Address("fe80::1")?.rawValue.prefix(2) == Data([0xfe, 0x80]))
        precondition(IPv6Address("not-an-address") == nil)
        var paths: [NWPath.Status] = []
        monitor.pathUpdateHandler = { paths.append($0.status) }
        monitor.start(queue: DispatchQueue.global())
        precondition(paths == [.unsatisfied])
        precondition(monitor.currentPath.availableInterfaces.isEmpty)
        let endpoint = NWEndpoint.hostPort(host: "example.invalid", port: .https)
        let connection = NWConnection(to: endpoint, using: .tcp)
        var connectionStates: [NWConnection.State] = []
        connection.stateUpdateHandler = { connectionStates.append($0) }
        connection.start(queue: DispatchQueue.global())
        precondition(connectionStates == [.preparing, .failed(.unsupported)])
        var sendError: NWError?
        connection.send(content: Data([1]), completion: .contentProcessed {
            sendError = $0
        })
        precondition(sendError == .unsupported)
        let listener = try! NWListener(using: .tcp, on: .http)
        var listenerState: NWListener.State?
        listener.stateUpdateHandler = { listenerState = $0 }
        listener.start(queue: DispatchQueue.global())
        precondition(listenerState == .failed(.unsupported))

        let reviewBefore = SKStoreReviewController.portableRequestCount
        SKStoreReviewController.requestReview()
        precondition(SKStoreReviewController.portableRequestCount == reviewBefore + 1)
        do {
            _ = try await Product.products(for: ["portable.product"])
            preconditionFailure("portable store returned fake catalog data")
        } catch let error as StoreKitPortableError {
            precondition(error.code == .productUnavailable)
        } catch {
            preconditionFailure("unexpected product error")
        }
        let observer = PaymentObserver()
        let queue = SKPaymentQueue.default()
        queue.add(observer)
        queue.add(SKPayment(product: SKProduct(productIdentifier: "portable")))
        precondition(observer.states == [.failed])
        queue.restoreCompletedTransactions()
        precondition(observer.restorationFailed)
        queue.remove(observer)

        AudioToolboxPortable.resetRequestHistory()
        AudioServicesPlaySystemSound(1519)
        precondition(AudioToolboxPortable.requestedSystemSounds == [1519])
        precondition(AudioToolboxPortable.playbackDisposition == .unsupported)
        var sound: SystemSoundID = 99
        let soundStatus = AudioServicesCreateSystemSoundID(
            URL(string: "file:///not-present.wav")!,
            &sound
        )
        precondition(soundStatus == kAudioServicesUnsupportedPropertyError)
        precondition(sound == 0)

        precondition(!CHHapticEngine.capabilitiesForHardware().supportsHaptics)
        let event = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 1)
            ],
            relativeTime: 0
        )
        let pattern = try! CHHapticPattern(events: [event], parameters: [])
        let engine = try! CHHapticEngine()
        let player = try! engine.makePlayer(with: pattern)
        do {
            try player.start(atTime: CHHapticTimeImmediate)
            preconditionFailure("portable haptics reported playback")
        } catch let error as CHHapticError {
            precondition(error.code == .notSupported)
        } catch {
            preconditionFailure("unexpected haptic error")
        }

        do {
            _ = try PKPass(data: Data([0x50, 0x4B]))
            preconditionFailure("portable PassKit accepted an unverifiable pass")
        } catch let error as PassKitPortableError {
            precondition(error.code == .passValidationUnavailable)
        } catch {
            preconditionFailure("unexpected pass error")
        }
        precondition(!PKAddPassesViewController.canAddPasses())
        precondition(!PKPaymentAuthorizationController.canMakePayments())
        let paymentRequest = PKPaymentRequest()
        paymentRequest.merchantIdentifier = "portable.merchant"
        paymentRequest.supportedNetworks = [.visa, .masterCard]
        paymentRequest.merchantCapabilities = [.threeDSecure]
        let paymentController = PKPaymentAuthorizationController(
            paymentRequest: paymentRequest
        )
        var presented: Bool?
        paymentController.present { presented = $0 }
        precondition(presented == false)

        print(
            "FIRST_PARTY_FRAMEWORKS_HOST_OK "
                + "auth=unavailable safari=failed network=unsatisfied "
                + "store=unavailable audio=recorded-unsupported "
                + "haptics=unsupported passkit=unavailable"
        )
    }
}
