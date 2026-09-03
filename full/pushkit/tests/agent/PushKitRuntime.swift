@_spi(OpenUIKitHost) import PushKit
import Foundation

private let eventTimeout = DispatchTimeInterval.seconds(5)

private final class LockedState: @unchecked Sendable {
    private let lock = NSLock()
    private var returned = false
    private var sawReturned = false
    private var count = 0
    private var lastToken: Data?
    private var lastType: PKPushType?
    private var lastPayloadKeys: Set<String> = []
    private var completionCalled = false
    private var invalidated: PKPushType?

    func markReturned() {
        lock.lock()
        returned = true
        lock.unlock()
    }

    func noteCredentials(_ credentials: PKPushCredentials, type: PKPushType) {
        lock.lock()
        sawReturned = returned
        count += 1
        lastToken = credentials.token
        lastType = type
        lock.unlock()
    }

    func noteIncoming(_ payload: PKPushPayload, type: PKPushType, completion: @escaping () -> Void) {
        lock.lock()
        sawReturned = returned
        count += 1
        lastType = type
        lastPayloadKeys = Set(payload.dictionaryPayload.keys.compactMap { $0.base as? String })
        lock.unlock()
        completion()
        lock.lock()
        completionCalled = true
        lock.unlock()
    }

    func noteInvalidation(_ type: PKPushType) {
        lock.lock()
        sawReturned = returned
        count += 1
        invalidated = type
        lock.unlock()
    }

    func snapshot() -> (
        sawReturned: Bool,
        count: Int,
        token: Data?,
        type: PKPushType?,
        payloadKeys: Set<String>,
        completionCalled: Bool,
        invalidated: PKPushType?
    ) {
        lock.lock()
        defer { lock.unlock() }
        return (sawReturned, count, lastToken, lastType, lastPayloadKeys, completionCalled, invalidated)
    }
}

private func waitEvent(_ semaphore: DispatchSemaphore, _ message: String) {
    precondition(semaphore.wait(timeout: .now() + eventTimeout) == .success, message)
}

/// Occupy the SPI-exposed Linux callback queue until `release` so later
/// `async` callbacks cannot run. `occupy` returns only after the blocker
/// is running.
private final class CallbackQueueBlocker: @unchecked Sendable {
    private let occupied = DispatchSemaphore(value: 0)
    private let hold = DispatchSemaphore(value: 0)

    func occupy(_ registry: PKPushRegistry) {
        PushKitHostControl.enqueueCallbackProbe(registry) { [self] in
            occupied.signal()
            hold.wait()
        }
        waitEvent(occupied, "callback queue was never occupied")
    }

    func release() {
        hold.signal()
    }
}

private final class RecordingDelegate: NSObject, PKPushRegistryDelegate {
    let state = LockedState()
    let arrived = DispatchSemaphore(value: 0)

    func pushRegistry(
        _ registry: PKPushRegistry,
        didUpdate pushCredentials: PKPushCredentials,
        for type: PKPushType
    ) {
        _ = registry
        state.noteCredentials(pushCredentials, type: type)
        arrived.signal()
    }

    func pushRegistry(
        _ registry: PKPushRegistry,
        didReceiveIncomingPushWith payload: PKPushPayload,
        for type: PKPushType,
        withCompletionHandler completion: @escaping () -> Void
    ) {
        _ = registry
        state.noteIncoming(payload, type: type, completion: completion)
        arrived.signal()
    }

    func pushRegistry(
        _ registry: PKPushRegistry,
        didInvalidatePushTokenFor type: PKPushType
    ) {
        _ = registry
        state.noteInvalidation(type)
        arrived.signal()
    }
}

func assertPushTypes() {
    precondition(PKPushType.voIP.rawValue == "PKPushTypeVoIP")
    precondition(PKPushType.complication.rawValue == "PKPushTypeComplication")
    precondition(PKPushType.fileProvider.rawValue == "PKPushTypeFileProvider")
    precondition(PKPushType.voIP != PKPushType.complication)
    precondition(PKPushType.voIP != PKPushType.fileProvider)
    precondition(PKPushType.complication != PKPushType.fileProvider)
    precondition(PKPushType.voIP == PKPushType(rawValue: "PKPushTypeVoIP"))
    let unknown = PKPushType(rawValue: "not-a-named-push-type")
    precondition(unknown != PKPushType.voIP)
    precondition(unknown != PKPushType.complication)
    precondition(unknown != PKPushType.fileProvider)

    var hasher = Hasher()
    PKPushType.voIP.hash(into: &hasher)
    _ = hasher.finalize()

    var types: Set<PKPushType> = [PKPushType.voIP, PKPushType.fileProvider]
    precondition(types.contains(.voIP))
    precondition(types.contains(.fileProvider))
    precondition(!types.contains(.complication))
    types.insert(.complication)
    precondition(types.count == 3)
}

func exerciseCredentialsAndPayload() {
    let token = Data([0x01, 0x02, 0x03, 0x04])
    let credentials = PushKitHostControl.makeCredentials(type: .voIP, token: token)
    precondition(credentials.type == .voIP)
    precondition(credentials.token == token)
    var mutated = credentials.token
    mutated.append(0xFF)
    precondition(credentials.token == token)

    var payloadDict: [AnyHashable: Any] = [
        "aps": ["alert": "local-only"],
        "local": true,
    ]
    let payload = PushKitHostControl.makePayload(type: .fileProvider, dictionaryPayload: payloadDict)
    precondition(payload.type == .fileProvider)
    let first = payload.dictionaryPayload
    precondition(first["local"] as? Bool == true)
    payloadDict["injected"] = "no"
    precondition(payload.dictionaryPayload["injected"] == nil)
    var returned = payload.dictionaryPayload
    returned["mutated"] = 1
    precondition(payload.dictionaryPayload["mutated"] == nil)
}

func exerciseRegistryStorage() {
    let customQueue = DispatchQueue(label: "PushKit.runtime.custom")
    let registry = PKPushRegistry(queue: customQueue)
    precondition(registry.delegate == nil)
    precondition(registry.desiredPushTypes == nil)
    precondition(registry.pushToken(for: .voIP) == nil)
    precondition(registry.pushToken(for: .complication) == nil)
    precondition(registry.pushToken(for: .fileProvider) == nil)

    registry.desiredPushTypes = [.voIP, .fileProvider]
    precondition(registry.desiredPushTypes == Set([PKPushType.voIP, PKPushType.fileProvider]))
    precondition(registry.pushToken(for: .voIP) == nil)

    registry.desiredPushTypes = []
    precondition(registry.desiredPushTypes == [])
    registry.desiredPushTypes = nil
    precondition(registry.desiredPushTypes == nil)

    let nilQueueRegistry = PKPushRegistry(queue: nil)
    nilQueueRegistry.desiredPushTypes = [.complication]
    precondition(nilQueueRegistry.desiredPushTypes == [.complication])
    precondition(nilQueueRegistry.pushToken(for: .complication) == nil)
}

func exerciseDelegateDispatch() {
    let registry = PKPushRegistry(queue: nil)
    let delegate = RecordingDelegate()
    registry.delegate = delegate
    precondition(registry.delegate === delegate)

    registry.desiredPushTypes = [.voIP]
    precondition(delegate.state.snapshot().count == 0)
    precondition(registry.pushToken(for: .voIP) == nil)

    let token = Data([0xAA, 0xBB])
    let credentials = PushKitHostControl.makeCredentials(type: .voIP, token: token)
    let blocker = CallbackQueueBlocker()
    blocker.occupy(registry)

    PushKitHostControl.deliverLocalCredentials(registry, credentials: credentials, type: .voIP)
    delegate.state.markReturned()
    precondition(delegate.state.snapshot().count == 0, "didUpdate must not run inline")
    blocker.release()
    waitEvent(delegate.arrived, "didUpdate never arrived")
    let update = delegate.state.snapshot()
    precondition(update.sawReturned, "didUpdate must hop asynchronously")
    precondition(update.count == 1)
    precondition(update.token == token)
    precondition(update.type == .voIP)
    precondition(registry.pushToken(for: .voIP) == nil)

    let payload = PushKitHostControl.makePayload(
        type: .fileProvider,
        dictionaryPayload: ["uuid": "local-only"]
    )
    let incomingBlocker = CallbackQueueBlocker()
    incomingBlocker.occupy(registry)
    PushKitHostControl.deliverLocalIncomingPush(registry, payload: payload, type: .fileProvider)
    delegate.state.markReturned()
    incomingBlocker.release()
    waitEvent(delegate.arrived, "incoming push never arrived")
    let incoming = delegate.state.snapshot()
    precondition(incoming.sawReturned)
    precondition(incoming.count == 2)
    precondition(incoming.type == .fileProvider)
    precondition(incoming.payloadKeys.contains("uuid"))
    precondition(incoming.completionCalled)

    let invalidateBlocker = CallbackQueueBlocker()
    invalidateBlocker.occupy(registry)
    PushKitHostControl.deliverLocalInvalidation(registry, type: .complication)
    delegate.state.markReturned()
    invalidateBlocker.release()
    waitEvent(delegate.arrived, "invalidation never arrived")
    let invalidated = delegate.state.snapshot()
    precondition(invalidated.sawReturned)
    precondition(invalidated.count == 3)
    precondition(invalidated.invalidated == .complication)

    registry.delegate = nil
    precondition(registry.delegate == nil)
}

func pushKitRuntimeMain() {
    assertPushTypes()
    exerciseCredentialsAndPayload()
    exerciseRegistryStorage()
    exerciseDelegateDispatch()
    print("PUSHKIT_AGENT_RUNTIME_OK")
}

pushKitRuntimeMain()
