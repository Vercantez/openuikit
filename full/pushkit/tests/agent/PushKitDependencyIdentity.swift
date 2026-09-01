import Dispatch
import Foundation
@_spi(OpenUIKitHost) import PushKit

/// Future EC2 dependency-identity client.
///
/// This probe is **not** executed by the isolated `tests/acceptance/test_host.sh`
/// gate. A later clean EC2 run must:
/// 1. Build the real guest Foundation module and `libFoundation.dylib` (plus
///    the platform Dispatch/runtime) first.
/// 2. Build `PushKit` / `libPushKit.dylib` with those `-I`/`-L` paths.
/// 3. Link this file as a client that imports both `PushKit` and Foundation.
/// 4. Run with `LD_LIBRARY_PATH` covering those dylibs.
/// 5. Confirm this exact marker and that `libPushKit.dylib` is loaded.
///
/// Isolated host-gate success is not integrated Linux-guest success.

private func acceptFoundationData(_ value: Foundation.Data) -> Int {
    value.count
}

private final class ExistentialOverrideDelegate: NSObject, PKPushRegistryDelegate,
    @unchecked Sendable
{
    let done = DispatchSemaphore(value: 0)
    private let stateLock = NSLock()
    private var seenToken: Foundation.Data?
    private var seenPayloadBlob: Foundation.Data?

    func recordedToken() -> Foundation.Data? {
        stateLock.lock()
        defer { stateLock.unlock() }
        return seenToken
    }

    func recordedPayloadBlob() -> Foundation.Data? {
        stateLock.lock()
        defer { stateLock.unlock() }
        return seenPayloadBlob
    }

    func pushRegistry(
        _ registry: PKPushRegistry,
        didUpdate pushCredentials: PKPushCredentials,
        for type: PKPushType
    ) {
        _ = registry
        _ = type
        let token: Foundation.Data = pushCredentials.token
        _ = acceptFoundationData(token)
        stateLock.lock()
        seenToken = token
        stateLock.unlock()
        done.signal()
    }

    func pushRegistry(
        _ registry: PKPushRegistry,
        didReceiveIncomingPushWith payload: PKPushPayload,
        for type: PKPushType,
        completion: @escaping @Sendable () -> Void
    ) {
        _ = registry
        _ = type
        let blob = payload.dictionaryPayload["blob"] as? Foundation.Data
        stateLock.lock()
        seenPayloadBlob = blob
        stateLock.unlock()
        completion()
    }
}

private func runPushKitDependencyIdentity() {
    let credentialToken: Foundation.Data = Foundation.Data([0x10, 0x20, 0x30])
    let payloadBlob: Foundation.Data = Foundation.Data([0xDE, 0xAD])

    let credentials = PKPushCredentials(type: .voIP, token: credentialToken)
    precondition(acceptFoundationData(credentials.token) == 3)
    precondition(credentials.token == credentialToken)

    let payload = PKPushPayload(
        type: .voIP,
        dictionaryPayload: ["blob": payloadBlob]
    )
    let extractedBlob = payload.dictionaryPayload["blob"] as? Foundation.Data
    precondition(extractedBlob == payloadBlob)
    _ = acceptFoundationData(extractedBlob ?? Foundation.Data())

    let queue = DispatchQueue(label: "pushkit.dependency-identity")
    let registry = PKPushRegistry(queue: queue)
    let concrete = ExistentialOverrideDelegate()
    let override: any PKPushRegistryDelegate = concrete
    registry.delegate = override
    precondition(registry.delegate === concrete)
    registry.desiredPushTypes = [.voIP]

    precondition(registry._portableInstallCredentials(credentials))
    precondition(concrete.done.wait(timeout: .now() + 2) == .success)
    precondition(concrete.recordedToken() == credentialToken)
    precondition(registry.pushToken(for: .voIP) == credentialToken)
    _ = acceptFoundationData(registry.pushToken(for: .voIP) ?? Foundation.Data())

    let incomingDone = DispatchSemaphore(value: 0)
    precondition(
        registry._portableDeliverIncomingPush(payload) {
            incomingDone.signal()
        }
    )
    precondition(incomingDone.wait(timeout: .now() + 2) == .success)
    precondition(concrete.recordedPayloadBlob() == payloadBlob)

    print("PUSHKIT_DEPENDENCY_IDENTITY_OK")
}

runPushKitDependencyIdentity()
