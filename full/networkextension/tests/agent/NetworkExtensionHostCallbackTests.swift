@_spi(OpenUIKitHost) import NetworkExtension
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
func testReturnBeforeCallbackAndQueueIdentity() {

let error = neCallback { handler in
    NEVPNManager.shared().loadFromPreferences(completionHandler: handler)
}
precondition(error == nil)

let disconnect = neCallback { handler in
    NEVPNManager.shared().connection.fetchLastDisconnectError(completionHandler: handler)
}
precondition(disconnect == nil)
}

func testExactlyOnceDelivery() {

let count = LockedState(0)
let tcp = NWTCPConnection(endpoint: NWHostEndpoint(hostname: "example.invalid", port: "443"))
NetworkExtensionHostCallback.holdDelivery()
tcp.readLength(1) { _, _ in
    precondition(NetworkExtensionHostCallback.isCurrentQueue)
    count.withLock { $0 += 1 }
}
tcp.cancel()
let beforeRelease = count.withLock { $0 }
precondition(beforeRelease == 0, "callback ran before releaseDelivery")
NetworkExtensionHostCallback.releaseDelivery()
neDrain()
precondition(count.withLock { $0 } == 1)
neDrain()
precondition(count.withLock { $0 } == 1)
precondition(tcp.state == .cancelled)
}

func testCancellation() {

let tcp = NWTCPConnection(endpoint: NWHostEndpoint(hostname: "example.invalid", port: "1"))
tcp.cancel()
precondition(tcp.state == .cancelled)
let result = neCallback { handler in
    tcp.readMinimumLength(1, maximumLength: 8) { data, error in
        handler((data, error))
    }
}
precondition(result.0 == nil)
guard let error = result.1 as? NEAppProxyFlowError else {
    fatalError("expected NEAppProxyFlowError after cancel")
}
precondition(error.code == NEAppProxyFlowError.Code.aborted)

let udp = NWUDPSession(endpoint: NWHostEndpoint(hostname: "example.invalid", port: "1"))
udp.cancel()
precondition(udp.state == .cancelled)
let datagram = neCallback { handler in
    udp.writeDatagram(Data([0x01]), completionHandler: handler)
}
precondition(datagram != nil)
}

func testDelegateReplacement() {

let manager = NEAppPushManager()
let first = PushCallDelegate()
let second = PushCallDelegate()
manager.delegate = first
manager.deliverIncomingCallForHostTesting(userInfo: ["token": "a"])
manager.delegate = second
neDrain()
precondition(first.calls == 0)
precondition(second.calls == 1)
}

func testWeakOwnership() {

let manager = NEAppPushManager()
weak var weakDelegate: PushCallDelegate?
do {
    let delegate = PushCallDelegate()
    manager.delegate = delegate
    weakDelegate = delegate
    precondition(weakDelegate != nil)
}
precondition(weakDelegate == nil)

weak var weakManager: NEAppPushManager?
do {
    let owned = NEAppPushManager()
    weakManager = owned
    owned.deliverIncomingCallForHostTesting()
}
neDrain()
precondition(weakManager == nil)
}

func testConcurrentSafety() {
    neWait {
        let groupCount = 8
        let results = await withTaskGroup(of: (any Error)?.self, returning: [(any Error)?].self) { group in
            for _ in 0..<groupCount {
                group.addTask {
                    await awaitHostCallback { handler in
                        NEVPNManager().loadFromPreferences(completionHandler: handler)
                    }
                }
            }
            var collected: [(any Error)?] = []
            for await error in group {
                collected.append(error)
            }
            return collected
        }
        precondition(results.count == groupCount)
        for error in results {
            precondition(error == nil)
        }

        let filterSaves = await withTaskGroup(of: (any Error)?.self, returning: [(any Error)?].self) { group in
            for _ in 0..<4 {
                group.addTask {
                    await awaitHostCallback { handler in
                        NEFilterManager.shared().saveToPreferences(completionHandler: handler)
                    }
                }
            }
            var collected: [(any Error)?] = []
            for await error in group {
                collected.append(error)
            }
            return collected
        }
        precondition(filterSaves.count == 4)
    }
}

func testOverrideDispatch() {
    neWait {
        class HostTunnel: NEPacketTunnelProvider {
            var started = false

            override func startTunnel(options: [String: NSObject]? = nil) async throws {
                started = true
                try await super.startTunnel(options: options)
            }
        }

        let concrete = HostTunnel()
        let existential: NEProvider = concrete
        let endpoint = NWHostEndpoint(hostname: "example.invalid", port: "80")
        let connection = existential.createTCPConnection(
            to: endpoint,
            enableTLS: false,
            tlsParameters: nil,
            delegate: nil
        )
        precondition(connection.endpoint === endpoint)
        do {
            try await concrete.startTunnel(options: nil)
            fatalError("overridden startTunnel must still fail closed")
        } catch {
            requireVPNError(error, code: .connectionFailed)
        }
        precondition(concrete.started)

        let slept: Void = await awaitHostCallback { handler in
            existential.sleep {
                handler(())
            }
        }
        _ = slept
    }
}
