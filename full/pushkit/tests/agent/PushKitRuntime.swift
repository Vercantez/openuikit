import Dispatch
import Foundation
@_spi(OpenUIKitHost) import PushKit

private final class RecordingDelegate: NSObject, PKPushRegistryDelegate, @unchecked Sendable {
    private let stateLock = NSLock()
    private var updates: [(type: PKPushType, token: Foundation.Data)] = []
    private var invalidations: [PKPushType] = []
    private var incomingTypes: [PKPushType] = []
    private var incomingDictionaries: [[AnyHashable: Any]] = []
    private var deprecatedIncoming = 0
    private var completionCalls = 0
    var updateSignal: DispatchSemaphore?
    var invalidateSignal: DispatchSemaphore?
    var incomingSignal: DispatchSemaphore?
    var deprecatedSignal: DispatchSemaphore?

    private func withState<T>(_ body: () -> T) -> T {
        stateLock.lock()
        defer { stateLock.unlock() }
        return body()
    }

    func recordedUpdates() -> [(type: PKPushType, token: Foundation.Data)] {
        withState { updates }
    }

    func recordedInvalidations() -> [PKPushType] {
        withState { invalidations }
    }

    func recordedIncomingTypes() -> [PKPushType] {
        withState { incomingTypes }
    }

    func recordedIncomingDictionaries() -> [[AnyHashable: Any]] {
        withState { incomingDictionaries }
    }

    func recordedDeprecatedIncoming() -> Int {
        withState { deprecatedIncoming }
    }

    func recordedCompletionCalls() -> Int {
        withState { completionCalls }
    }

    func pushRegistry(
        _ registry: PKPushRegistry,
        didUpdate pushCredentials: PKPushCredentials,
        for type: PKPushType
    ) {
        _ = registry
        let signal = withState { () -> DispatchSemaphore? in
            updates.append((type, pushCredentials.token))
            return updateSignal
        }
        signal?.signal()
    }

    func pushRegistry(
        _ registry: PKPushRegistry,
        didInvalidatePushTokenFor type: PKPushType
    ) {
        _ = registry
        let signal = withState { () -> DispatchSemaphore? in
            invalidations.append(type)
            return invalidateSignal
        }
        signal?.signal()
    }

    func pushRegistry(
        _ registry: PKPushRegistry,
        didReceiveIncomingPushWith payload: PKPushPayload,
        for type: PKPushType,
        completion: @escaping @Sendable () -> Void
    ) {
        let signal = withState { () -> DispatchSemaphore? in
            incomingTypes.append(type)
            incomingDictionaries.append(payload.dictionaryPayload)
            completionCalls += 1
            return incomingSignal
        }
        completion()
        signal?.signal()
    }

    func pushRegistry(
        _ registry: PKPushRegistry,
        didReceiveIncomingPushWith payload: PKPushPayload,
        for type: PKPushType
    ) {
        _ = registry
        _ = payload
        _ = type
        let signal = withState { () -> DispatchSemaphore? in
            deprecatedIncoming += 1
            return deprecatedSignal
        }
        signal?.signal()
    }
}

/// Implements only the required credentials callback so default witnesses for
/// the optional incoming-push and invalidation requirements are exercised.
private final class RequiredOnlyDelegate: NSObject, PKPushRegistryDelegate, @unchecked Sendable {
    private let stateLock = NSLock()
    private var updateCount = 0
    let updateSignal = DispatchSemaphore(value: 0)

    func recordedUpdateCount() -> Int {
        stateLock.lock()
        defer { stateLock.unlock() }
        return updateCount
    }

    func pushRegistry(
        _ registry: PKPushRegistry,
        didUpdate pushCredentials: PKPushCredentials,
        for type: PKPushType
    ) {
        _ = registry
        _ = pushCredentials
        _ = type
        stateLock.lock()
        updateCount += 1
        stateLock.unlock()
        updateSignal.signal()
    }
}

private func exercisePushTypes() {
    let voip = PKPushType.voIP
    let fileProvider = PKPushType.fileProvider
    let complication = PKPushType.complication

    precondition(voip == PKPushType.voIP)
    precondition(fileProvider == PKPushType.fileProvider)
    precondition(complication == PKPushType.complication)
    precondition(voip != fileProvider)
    precondition(voip != complication)
    precondition(fileProvider != complication)
    precondition(voip.hashValue == PKPushType.voIP.hashValue)

    var hasher = Hasher()
    voip.hash(into: &hasher)
    var hasher2 = Hasher()
    PKPushType.voIP.hash(into: &hasher2)
    precondition(hasher.finalize() == hasher2.finalize())

    let types: Set<PKPushType> = [voip, fileProvider, voip, complication]
    precondition(types.count == 3)
    precondition(types.contains(.voIP))
    precondition(types.contains(.fileProvider))
    precondition(types.contains(.complication))

    let hostLocal = PKPushType(rawValue: "host-local-push-type")
    precondition(hostLocal.rawValue == "host-local-push-type")
    precondition(hostLocal != voip)
    precondition(!types.contains(hostLocal))
}

private func exerciseFailClosedRegistry() {
    let queue = DispatchQueue(label: "pushkit.fail-closed")
    let registry = PKPushRegistry(queue: queue)
    let delegate = RecordingDelegate()
    let existential: any PKPushRegistryDelegate = delegate
    registry.delegate = existential
    precondition(registry.delegate === delegate)

    precondition(registry.desiredPushTypes == nil)
    precondition(registry.pushToken(for: .voIP) == nil)
    precondition(registry._portableCallbackQueue === queue)

    let mainRegistry = PKPushRegistry(queue: nil)
    precondition(mainRegistry._portableUsesMainCallbackQueue)
    precondition(!registry._portableUsesMainCallbackQueue)

    registry.desiredPushTypes = [.voIP, .fileProvider]
    precondition(registry.desiredPushTypes == [.voIP, .fileProvider])
    precondition(registry.pushToken(for: .voIP) == nil)
    precondition(registry.pushToken(for: .fileProvider) == nil)
    precondition(delegate.recordedUpdates().isEmpty)
    precondition(delegate.recordedInvalidations().isEmpty)

    let stray = PKPushCredentials(
        type: PKPushType(rawValue: "host-unrequested"),
        token: Foundation.Data([0xFF])
    )
    precondition(!registry._portableInstallCredentials(stray))
    precondition(registry.pushToken(for: stray.type) == nil)

    let payload = PKPushPayload(
        type: PKPushType(rawValue: "not-requested"),
        dictionaryPayload: ["k": "v"]
    )
    precondition(!registry._portableDeliverIncomingPush(payload))
    precondition(delegate.recordedIncomingTypes().isEmpty)
}

private func exerciseHostInjectedDispatch() {
    let queue = DispatchQueue(label: "pushkit.dispatch")
    let registry = PKPushRegistry(queue: queue)
    let delegate = RecordingDelegate()
    let updated = DispatchSemaphore(value: 0)
    let invalidated = DispatchSemaphore(value: 0)
    let incoming = DispatchSemaphore(value: 0)
    let deprecated = DispatchSemaphore(value: 0)
    delegate.updateSignal = updated
    delegate.invalidateSignal = invalidated
    delegate.incomingSignal = incoming
    delegate.deprecatedSignal = deprecated
    let existential: any PKPushRegistryDelegate = delegate
    registry.delegate = existential
    registry.desiredPushTypes = [.voIP]

    let token = Foundation.Data([0x0A, 0x0B, 0x0C, 0x0D])
    let credentials = PKPushCredentials(type: .voIP, token: token)
    precondition(credentials.type == .voIP)
    precondition(credentials.token == token)
    precondition(registry._portableInstallCredentials(credentials))
    precondition(updated.wait(timeout: .now() + 2) == .success)
    precondition(registry.pushToken(for: .voIP) == token)
    let updates = delegate.recordedUpdates()
    precondition(updates.count == 1)
    precondition(updates[0].type == .voIP)
    precondition(updates[0].token == token)

    let payload = PKPushPayload(
        type: .voIP,
        dictionaryPayload: ["handle": "555-0100", "callUUID": "abc"]
    )
    precondition(payload.type == .voIP)
    precondition(payload.dictionaryPayload["handle"] as? String == "555-0100")
    precondition(registry._portableDeliverIncomingPush(payload))
    precondition(incoming.wait(timeout: .now() + 2) == .success)
    precondition(delegate.recordedIncomingTypes() == [.voIP])
    precondition(delegate.recordedCompletionCalls() == 1)
    precondition(delegate.recordedIncomingDictionaries()[0]["callUUID"] as? String == "abc")

    precondition(registry._portableDeliverIncomingPushDeprecated(payload))
    precondition(deprecated.wait(timeout: .now() + 2) == .success)
    precondition(delegate.recordedDeprecatedIncoming() == 1)

    let requiredOnly = RequiredOnlyDelegate()
    let requiredRegistry = PKPushRegistry(queue: queue)
    let requiredExistential: any PKPushRegistryDelegate = requiredOnly
    requiredRegistry.delegate = requiredExistential
    requiredRegistry.desiredPushTypes = [.fileProvider]
    let fileToken = Foundation.Data([0x11])
    precondition(
        requiredRegistry._portableInstallCredentials(
            PKPushCredentials(type: .fileProvider, token: fileToken)
        )
    )
    precondition(requiredOnly.updateSignal.wait(timeout: .now() + 2) == .success)
    precondition(requiredOnly.recordedUpdateCount() == 1)
    let defaultIncomingDone = DispatchSemaphore(value: 0)
    let defaultPayload = PKPushPayload(
        type: .fileProvider,
        dictionaryPayload: ["provider": "host"]
    )
    precondition(
        requiredRegistry._portableDeliverIncomingPush(defaultPayload) {
            defaultIncomingDone.signal()
        }
    )
    precondition(defaultIncomingDone.wait(timeout: .now() + 2) == .success)

    registry.desiredPushTypes = []
    precondition(invalidated.wait(timeout: .now() + 2) == .success)
    precondition(registry.pushToken(for: .voIP) == nil)
    precondition(delegate.recordedInvalidations() == [.voIP])

    let rejected = PKPushPayload(type: .voIP, dictionaryPayload: [:])
    precondition(!registry._portableDeliverIncomingPush(rejected))
}

private func exerciseWeakDelegate() {
    let registry = PKPushRegistry(queue: DispatchQueue(label: "pushkit.weak"))
    var delegate: RecordingDelegate? = RecordingDelegate()
    registry.delegate = delegate
    precondition(registry.delegate === delegate)
    delegate = nil
    precondition(registry.delegate == nil)
}

exercisePushTypes()
exerciseFailClosedRegistry()
exerciseHostInjectedDispatch()
exerciseWeakDelegate()
print("PUSHKIT_AGENT_RUNTIME_OK")
