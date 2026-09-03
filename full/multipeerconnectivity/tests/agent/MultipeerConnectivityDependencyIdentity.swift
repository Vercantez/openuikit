#if canImport(UIKit)
import UIKit
#endif
import Foundation
@_spi(OpenUIKitHost) import MultipeerConnectivity

// Future clean EC2 dependency-identity client. Isolated host-gate success
// against toolchain Foundation is not integrated guest-Foundation/UIKit success.
//
// Expected EC2 steps (no local Docker):
// 1. Build actual guest Foundation and UIKit modules and dylibs.
// 2. Build MultipeerConnectivity with their -I / -L paths.
// 3. Link this file as a client that imports Foundation, UIKit, and
//    MultipeerConnectivity.
// 4. Run with LD_LIBRARY_PATH covering those dylibs.
// 5. Confirm MULTIPEERCONNECTIVITY_DEPENDENCY_IDENTITY_OK and that
//    libMultipeerConnectivity.dylib was loaded.
//
// MCBrowserViewController must inherit UIKit.UIViewController. This file does
// not compile a substitute. When UIKit is absent, the UIKit assertions are
// skipped and the marker is not printed.

private let eventTimeout = DispatchTimeInterval.seconds(5)

private func waitEvent(_ semaphore: DispatchSemaphore, _ message: String) {
    precondition(semaphore.wait(timeout: .now() + eventTimeout) == .success, message)
}

private func requireUnavailable(_ error: any Error) {
    let nsError = error as NSError
    precondition(type(of: nsError) == NSError.self || error is MCError)
    precondition(nsError.domain == MCErrorDomain)
    precondition(nsError.code == MCError.Code.unavailable.rawValue)
}

@main
enum MultipeerConnectivityDependencyIdentity {
    static func main() {
        let peer = MCPeerID(displayName: "identity-peer")
        let session = MCSession(peer: peer)
        session.connectPeer(peer, withNearbyConnectionData: Data())
        let progress: Progress? = session.sendResource(
            at: URL(fileURLWithPath: "/tmp/mc-identity"),
            withName: "n",
            toPeer: peer,
            withCompletionHandler: nil
        )
        precondition(progress == nil)

        do {
            _ = try session.startStream(withName: "s", toPeer: peer)
            fatalError("expected startStream throw")
        } catch {
            let nsError = error as NSError
            precondition(nsError.domain == MCErrorDomain)
        }

        let finished = DispatchSemaphore(value: 0)
        Task {
            do {
                _ = try await session.nearbyConnectionData(forPeer: peer)
                fatalError("expected nearby throw")
            } catch {
                requireUnavailable(error)
                finished.signal()
            }
        }
        waitEvent(finished, "nearbyConnectionData identity wait")

#if canImport(UIKit)
        let browser = MCNearbyServiceBrowser(peer: peer, serviceType: "ou-xfer")
        let controller = MCBrowserViewController(browser: browser, session: session)
        let asViewController: UIViewController = controller
        precondition(asViewController === controller)
        precondition(controller.session === session)
        precondition(controller.browser === browser)
        precondition(controller.minimumNumberOfPeers == kMCSessionMinimumNumberOfPeers)
        let viaService = MCBrowserViewController(serviceType: "ou-xfer", session: session)
        precondition(viaService.session === session)
        print("MULTIPEERCONNECTIVITY_DEPENDENCY_IDENTITY_OK")
#else
        fputs(
            "MULTIPEERCONNECTIVITY_DEPENDENCY_IDENTITY_SKIPPED uikit=unavailable\n",
            stderr
        )
        exit(2)
#endif
    }
}
