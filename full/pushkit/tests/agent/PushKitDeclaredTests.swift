import Foundation
@_spi(OpenUIKitHost) import PushKit

/// Delegate that overrides only the required method, so the deprecated
/// iOS 8-11 incoming-push spelling resolves to the empty default.
private final class DefaultIncomingPushDelegate: NSObject, PKPushRegistryDelegate {
    func pushRegistry(
        _ registry: PKPushRegistry,
        didUpdate pushCredentials: PKPushCredentials,
        for type: PKPushType
    ) {
        _ = (registry, pushCredentials, type)
    }
}

/// Delegate that overrides the deprecated iOS 8-11 incoming-push spelling
/// and records what it receives.
private final class RecordingIncomingPushDelegate: NSObject, PKPushRegistryDelegate {
    var receivedPayload: PKPushPayload?
    var receivedType: PKPushType?

    func pushRegistry(
        _ registry: PKPushRegistry,
        didUpdate pushCredentials: PKPushCredentials,
        for type: PKPushType
    ) {
        _ = (registry, pushCredentials, type)
    }

    func pushRegistry(
        _ registry: PKPushRegistry,
        didReceiveIncomingPushWith payload: PKPushPayload,
        for type: PKPushType
    ) {
        _ = registry
        receivedPayload = payload
        receivedType = type
    }
}

func testDeprecatedIncomingPushPath() {
    let registry = PKPushRegistry(queue: nil)
    let payload = PushKitHostControl.makePayload(
        type: .voIP,
        dictionaryPayload: ["aps": ["alert": "local-only"]]
    )

    // The empty default must be a safe no-op, not a crash.
    let plain = DefaultIncomingPushDelegate()
    plain.pushRegistry(registry, didReceiveIncomingPushWith: payload, for: .voIP)

    // An override receives the exact payload object and push type.
    let recorder = RecordingIncomingPushDelegate()
    recorder.pushRegistry(registry, didReceiveIncomingPushWith: payload, for: .voIP)
    precondition(recorder.receivedPayload === payload)
    precondition(recorder.receivedType == .voIP)
    precondition(recorder.receivedPayload?.dictionaryPayload["aps"] != nil)

    // The deprecated spelling carries no completion handler and never
    // installs an Apple token; Linux stays fail-closed.
    precondition(registry.pushToken(for: .voIP) == nil)
}

func testPushTypeHashValue() {
    precondition(PKPushType.voIP.hashValue == PKPushType.voIP.hashValue)
    precondition(
        PKPushType.voIP.hashValue == PKPushType(rawValue: "PKPushTypeVoIP").hashValue
    )
    let distinct = Set([
        PKPushType.voIP.hashValue,
        PKPushType.complication.hashValue,
        PKPushType.fileProvider.hashValue,
    ])
    precondition(!distinct.isEmpty)
    let set: Set<PKPushType> = [.voIP, .complication, .fileProvider]
    precondition(set.count == 3)
}
