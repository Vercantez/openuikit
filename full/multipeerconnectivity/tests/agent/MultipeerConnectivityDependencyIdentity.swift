// Future clean EC2 dependency-identity client.
//
// This file is not part of the isolated host gate. That gate compiles only
// tests/agent/MultipeerConnectivityRuntime.swift against Foundation. A later
// EC2 run should:
//   1. Build actual guest Foundation and UIKit modules and dylibs.
//   2. Build MultipeerConnectivity with those -I and -L paths so
//      canImport(UIKit) is true and MCBrowserViewController subclasses
//      UIKit.UIViewController.
//   3. Link this client, which imports Foundation, UIKit, and
//      MultipeerConnectivity (no module-local substitutes).
//   4. Run with LD_LIBRARY_PATH covering those dylibs, verify the marker,
//      and confirm libMultipeerConnectivity.dylib was loaded.
// Isolated host-gate success is not integrated Linux success.

import Dispatch
import Foundation
import UIKit
import MultipeerConnectivity

class IdentitySessionDelegate: NSObject, MCSessionDelegate {
    var receivedDataCount = 0
    var receivedStreamCount = 0
    var startedResourceCount = 0

    func session(
        _ session: MCSession,
        peer peerID: MCPeerID,
        didChange state: MCSessionState
    ) {
        _ = (session, peerID, state)
    }

    func session(
        _ session: MCSession,
        didReceive data: Data,
        fromPeer peerID: MCPeerID
    ) {
        _ = (session, peerID)
        receivedDataCount += 1
        _ = data
    }

    func session(
        _ session: MCSession,
        didReceive stream: InputStream,
        withName streamName: String,
        fromPeer peerID: MCPeerID
    ) {
        _ = (session, streamName, peerID)
        receivedStreamCount += 1
        _ = stream
    }

    func session(
        _ session: MCSession,
        didStartReceivingResourceWithName resourceName: String,
        fromPeer peerID: MCPeerID,
        with progress: Progress
    ) {
        _ = (session, resourceName, peerID)
        startedResourceCount += 1
        _ = progress
    }

    func session(
        _ session: MCSession,
        didFinishReceivingResourceWithName resourceName: String,
        fromPeer peerID: MCPeerID,
        at localURL: URL?,
        withError error: (any Error)?
    ) {
        _ = (session, resourceName, peerID, localURL, error)
    }
}

final class IdentitySessionOverrideDelegate: IdentitySessionDelegate {
    override func session(
        _ session: MCSession,
        didReceive data: Data,
        fromPeer peerID: MCPeerID
    ) {
        receivedDataCount += 10
        super.session(session, didReceive: data, fromPeer: peerID)
    }

    override func session(
        _ session: MCSession,
        didReceive stream: InputStream,
        withName streamName: String,
        fromPeer peerID: MCPeerID
    ) {
        receivedStreamCount += 10
        super.session(
            session,
            didReceive: stream,
            withName: streamName,
            fromPeer: peerID
        )
    }

    override func session(
        _ session: MCSession,
        didStartReceivingResourceWithName resourceName: String,
        fromPeer peerID: MCPeerID,
        with progress: Progress
    ) {
        startedResourceCount += 10
        super.session(
            session,
            didStartReceivingResourceWithName: resourceName,
            fromPeer: peerID,
            with: progress
        )
    }
}

class IdentityAdvertiserDelegate: NSObject, MCNearbyServiceAdvertiserDelegate {
    var startCount = 0
    var startError: (any Error)?
    let startLock = DispatchSemaphore(value: 0)

    func advertiser(
        _ advertiser: MCNearbyServiceAdvertiser,
        didReceiveInvitationFromPeer peerID: MCPeerID,
        withContext context: Data?,
        invitationHandler: @escaping (Bool, MCSession?) -> Void
    ) {
        _ = (advertiser, peerID, context)
        invitationHandler(false, nil)
    }

    func advertiser(
        _ advertiser: MCNearbyServiceAdvertiser,
        didNotStartAdvertisingPeer error: any Error
    ) {
        startError = error
        startCount += 1
        startLock.signal()
    }
}

final class IdentityAdvertiserOverrideDelegate: IdentityAdvertiserDelegate {
    var overrideCount = 0

    override func advertiser(
        _ advertiser: MCNearbyServiceAdvertiser,
        didNotStartAdvertisingPeer error: any Error
    ) {
        overrideCount += 1
        super.advertiser(advertiser, didNotStartAdvertisingPeer: error)
    }
}

class IdentityBrowserDelegate: NSObject, MCNearbyServiceBrowserDelegate {
    var startCount = 0
    var startError: (any Error)?
    let startLock = DispatchSemaphore(value: 0)

    func browser(
        _ browser: MCNearbyServiceBrowser,
        foundPeer peerID: MCPeerID,
        withDiscoveryInfo info: [String: String]?
    ) {
        _ = (browser, peerID, info)
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        _ = (browser, peerID)
    }

    func browser(
        _ browser: MCNearbyServiceBrowser,
        didNotStartBrowsingForPeers error: any Error
    ) {
        startError = error
        startCount += 1
        startLock.signal()
    }
}

final class IdentityBrowserOverrideDelegate: IdentityBrowserDelegate {
    var overrideCount = 0

    override func browser(
        _ browser: MCNearbyServiceBrowser,
        didNotStartBrowsingForPeers error: any Error
    ) {
        overrideCount += 1
        super.browser(browser, didNotStartBrowsingForPeers: error)
    }
}

func identityRequireMCError(_ error: any Error, code: MCError.Code) {
    guard let typed = error as? MCError else {
        fatalError("expected typed MCError")
    }
    precondition(typed.code == code)
}

func identityWait(_ semaphore: DispatchSemaphore) {
    let result = semaphore.wait(timeout: .now() + 2)
    precondition(result == .success, "fail-closed callback was not delivered")
}

@main
struct MultipeerConnectivityDependencyIdentity {
    static func main() async {
        let peer = MCPeerID(displayName: "identity")
        let remote = MCPeerID(displayName: "remote")
        let session = MCSession(peer: peer)
        let payload = Data([0x11, 0x22, 0x33])
        let progress = Progress(totalUnitCount: 8)
        let input = InputStream(data: payload)
        let output = OutputStream.toMemory()

        do {
            try session.send(payload, toPeers: [remote], with: .reliable)
            fatalError("send must fail closed")
        } catch {
            identityRequireMCError(error, code: .notConnected)
        }

        do {
            let produced: OutputStream = try session.startStream(
                withName: "identity-stream",
                toPeer: remote
            )
            _ = produced
            fatalError("startStream must fail closed")
        } catch {
            identityRequireMCError(error, code: .notConnected)
        }
        _ = output

        var resourceCount = 0
        var resourceError: (any Error)?
        let resourceLock = DispatchSemaphore(value: 0)
        let resourceProgress = session.sendResource(
            at: URL(fileURLWithPath: "/tmp/mc-identity-resource"),
            withName: "identity.bin",
            toPeer: remote
        ) { error in
            resourceCount += 1
            resourceError = error
            resourceLock.signal()
        }
        precondition(resourceProgress == nil)
        precondition(resourceCount == 0)
        identityWait(resourceLock)
        precondition(resourceCount == 1)
        identityRequireMCError(resourceError!, code: .notConnected)
        Thread.sleep(forTimeInterval: 0.05)
        precondition(resourceCount == 1)

        var nearbyCount = 0
        let nearbyLock = DispatchSemaphore(value: 0)
        session.nearbyConnectionData(forPeer: remote) { data, error in
            precondition(data == nil)
            nearbyCount += 1
            identityRequireMCError(error!, code: .unavailable)
            nearbyLock.signal()
        }
        precondition(nearbyCount == 0)
        identityWait(nearbyLock)
        precondition(nearbyCount == 1)
        do {
            _ = try await session.nearbyConnectionData(forPeer: remote)
            fatalError("async nearbyConnectionData must fail closed")
        } catch {
            identityRequireMCError(error, code: .unavailable)
        }
        Thread.sleep(forTimeInterval: 0.05)
        precondition(nearbyCount == 1)

        let advertiserOverride = IdentityAdvertiserOverrideDelegate()
        let advertiserExistential: any MCNearbyServiceAdvertiserDelegate =
            advertiserOverride
        let advertiser = MCNearbyServiceAdvertiser(
            peer: peer,
            discoveryInfo: ["probe": "identity"],
            serviceType: "id-xfer"
        )
        advertiser.delegate = advertiserExistential
        advertiser.startAdvertisingPeer()
        precondition(advertiserOverride.startCount == 0)
        identityWait(advertiserOverride.startLock)
        precondition(advertiserOverride.overrideCount == 1)
        precondition(advertiserOverride.startCount == 1)
        identityRequireMCError(advertiserOverride.startError!, code: .unavailable)

        let browserOverride = IdentityBrowserOverrideDelegate()
        let browserExistential: any MCNearbyServiceBrowserDelegate = browserOverride
        let browser = MCNearbyServiceBrowser(peer: peer, serviceType: "id-xfer")
        browser.delegate = browserExistential
        browser.startBrowsingForPeers()
        precondition(browserOverride.startCount == 0)
        identityWait(browserOverride.startLock)
        precondition(browserOverride.overrideCount == 1)
        precondition(browserOverride.startCount == 1)
        identityRequireMCError(browserOverride.startError!, code: .unavailable)

        let sessionOverride = IdentitySessionOverrideDelegate()
        let sessionExistential: any MCSessionDelegate = sessionOverride
        sessionExistential.session(session, didReceive: payload, fromPeer: remote)
        sessionExistential.session(
            session,
            didReceive: input,
            withName: "identity-stream",
            fromPeer: remote
        )
        sessionExistential.session(
            session,
            didStartReceivingResourceWithName: "identity.bin",
            fromPeer: remote,
            with: progress
        )
        precondition(sessionOverride.receivedDataCount == 11)
        precondition(sessionOverride.receivedStreamCount == 11)
        precondition(sessionOverride.startedResourceCount == 11)

        await MainActor.run {
            let controller = MCBrowserViewController(
                serviceType: "id-xfer",
                session: session
            )
            let asViewController: UIKit.UIViewController = controller
            precondition(asViewController === controller)
            precondition(controller.session === session)
            precondition(controller.browser?.serviceType == "id-xfer")
            let wrapped = MCBrowserViewController(browser: browser, session: session)
            let wrappedViewController: UIKit.UIViewController = wrapped
            precondition(wrappedViewController === wrapped)
        }

        print("MULTIPEERCONNECTIVITY_DEPENDENCY_IDENTITY_OK")
    }
}
