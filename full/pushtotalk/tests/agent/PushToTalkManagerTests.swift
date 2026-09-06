@_spi(OpenUIKitHost) import PushToTalk
import Foundation

private final class PTManagerDelegateProbe: NSObject, PTChannelManagerDelegate {
    var joined = 0
    var left = 0
    var began = 0
    var ended = 0
    var tokens = 0
    var activated = 0
    var deactivated = 0
    var failedJoin = 0
    var failedLeave = 0
    var failedBegin = 0
    var failedStop = 0
    var lastJoinReason: PTChannelJoinReason?
    var lastLeaveReason: PTChannelLeaveReason?
    var lastTransmitSource: PTChannelTransmitRequestSource?
    var lastToken: Data?
    var lastPayload: [String: Any] = [:]
    var lastPushResultKindLeave = false
    var lastServiceUpdateCompleted = false
    var lastFailedJoinError: (any Error)?

    func channelManager(
        _ channelManager: PTChannelManager,
        didJoinChannel channelUUID: UUID,
        reason: PTChannelJoinReason
    ) {
        _ = channelManager
        _ = channelUUID
        joined += 1
        lastJoinReason = reason
    }

    func channelManager(
        _ channelManager: PTChannelManager,
        didLeaveChannel channelUUID: UUID,
        reason: PTChannelLeaveReason
    ) {
        _ = channelManager
        _ = channelUUID
        left += 1
        lastLeaveReason = reason
    }

    func channelManager(
        _ channelManager: PTChannelManager,
        channelUUID: UUID,
        didBeginTransmittingFrom source: PTChannelTransmitRequestSource
    ) {
        _ = channelManager
        _ = channelUUID
        began += 1
        lastTransmitSource = source
    }

    func channelManager(
        _ channelManager: PTChannelManager,
        channelUUID: UUID,
        didEndTransmittingFrom source: PTChannelTransmitRequestSource
    ) {
        _ = channelManager
        _ = channelUUID
        ended += 1
        lastTransmitSource = source
    }

    func channelManager(
        _ channelManager: PTChannelManager,
        receivedEphemeralPushToken pushToken: Data
    ) {
        _ = channelManager
        tokens += 1
        lastToken = pushToken
    }

    func incomingPushResult(
        channelManager: PTChannelManager,
        channelUUID: UUID,
        pushPayload: [String: Any]
    ) -> PTPushResult {
        _ = channelManager
        _ = channelUUID
        lastPayload = pushPayload
        if pushPayload["leave"] as? Bool == true {
            lastPushResultKindLeave = true
            return .leaveChannel
        }
        lastPushResultKindLeave = false
        return .activeRemoteParticipant(PTParticipant(name: "payload", image: nil))
    }

    func channelManager(
        _ channelManager: PTChannelManager,
        didActivate audioSession: AVAudioSession
    ) {
        _ = channelManager
        _ = audioSession
        activated += 1
    }

    func channelManager(
        _ channelManager: PTChannelManager,
        didDeactivate audioSession: AVAudioSession
    ) {
        _ = channelManager
        _ = audioSession
        deactivated += 1
    }

    func channelManager(
        _ channelManager: PTChannelManager,
        failedToJoinChannel channelUUID: UUID,
        error: any Error
    ) {
        _ = channelManager
        _ = channelUUID
        failedJoin += 1
        lastFailedJoinError = error
    }

    func channelManager(
        _ channelManager: PTChannelManager,
        failedToLeaveChannel channelUUID: UUID,
        error: any Error
    ) {
        _ = channelManager
        _ = channelUUID
        failedLeave += 1
    }

    func channelManager(
        _ channelManager: PTChannelManager,
        failedToBeginTransmittingInChannel channelUUID: UUID,
        error: any Error
    ) {
        _ = channelManager
        _ = channelUUID
        failedBegin += 1
    }

    func channelManager(
        _ channelManager: PTChannelManager,
        failedToStopTransmittingInChannel channelUUID: UUID,
        error: any Error
    ) {
        _ = channelManager
        _ = channelUUID
        failedStop += 1
    }
}

private final class PTRestorationProbe: NSObject, PTChannelRestorationDelegate {
    var restored: UUID?
    func channelDescriptor(restoredChannelUUID channelUUID: UUID) -> PTChannelDescriptor {
        restored = channelUUID
        return PTChannelDescriptor(name: "restored", image: nil)
    }
}

private func hostManager() -> (PTChannelManager, PTManagerDelegateProbe, PTRestorationProbe) {
    let delegate = PTManagerDelegateProbe()
    let restoration = PTRestorationProbe()
    let manager = PTChannelManager(hostDelegate: delegate, restorationDelegate: restoration)
    return (manager, delegate, restoration)
}

func testChannelManagerFactoryFailsClosed() {
    let delegate = PTManagerDelegateProbe()
    let restoration = PTRestorationProbe()
    var receivedManager: PTChannelManager?
    var receivedError: (any Error)?
    PTChannelManager.channelManager(
        delegate: delegate,
        restorationDelegate: restoration
    ) { manager, error in
        receivedManager = manager
        receivedError = error
    }
    precondition(receivedManager == nil)
    guard let receivedError else {
        preconditionFailure("factory must report PTInstantiationError.invalidPlatform")
    }
    let ns = receivedError as NSError
    precondition(ns.domain == PTInstantiationErrorDomain)
    precondition(ns.code == PTInstantiationError.Code.invalidPlatform.rawValue)
    precondition(PTInstantiationError.Code.invalidPlatform ~= receivedError)
}

func testChannelManagerHostInitActiveChannelNil() {
    let (manager, delegate, restoration) = hostManager()
    precondition(manager.activeChannelUUID == nil)
    precondition(manager.hostDelegate != nil)
    precondition(manager.hostRestorationDelegate != nil)
    _ = delegate
    let uuid = UUID()
    let descriptor = restoration.channelDescriptor(restoredChannelUUID: uuid)
    precondition(restoration.restored == uuid)
    precondition(descriptor.name == "restored")
}

func testRequestJoinChannelDoesNotJoin() {
    let (manager, probe, _) = hostManager()
    let uuid = UUID()
    let descriptor = PTChannelDescriptor(name: "field", image: nil)
    manager.requestJoinChannel(channelUUID: uuid, descriptor: descriptor)
    precondition(manager.hostRequestedJoinUUID == uuid)
    precondition(manager.hostRequestedJoinName == "field")
    precondition(manager.activeChannelUUID == nil)
    precondition(probe.joined == 0)
    precondition(probe.failedJoin == 0)
}

func testLeaveChannelDoesNotLeave() {
    let (manager, probe, _) = hostManager()
    let uuid = UUID()
    manager.leaveChannel(channelUUID: uuid)
    precondition(manager.hostRequestedLeaveUUID == uuid)
    precondition(manager.activeChannelUUID == nil)
    precondition(probe.left == 0)
    precondition(probe.failedLeave == 0)
}

func testRequestBeginTransmittingDoesNotTransmit() {
    let (manager, probe, _) = hostManager()
    let uuid = UUID()
    manager.requestBeginTransmitting(channelUUID: uuid)
    precondition(manager.hostRequestedBeginUUID == uuid)
    precondition(probe.began == 0)
    precondition(probe.failedBegin == 0)
}

func testStopTransmittingNoOp() {
    let (manager, probe, _) = hostManager()
    let uuid = UUID()
    manager.stopTransmitting(channelUUID: uuid)
    precondition(manager.hostRequestedStopUUID == uuid)
    precondition(probe.ended == 0)
    precondition(probe.failedStop == 0)
}

func testSetChannelDescriptorFailsChannelNotFound() {
    let (manager, _, _) = hostManager()
    let descriptor = PTChannelDescriptor(name: "rename", image: nil)
    var seen: (any Error)?
    manager.setChannelDescriptor(descriptor, channelUUID: UUID()) { error in
        seen = error
    }
    precondition(PTChannelError.Code.channelNotFound ~= seen!)
}

func testSetActiveRemoteParticipantFailsChannelNotFound() {
    let (manager, _, _) = hostManager()
    let participant = PTParticipant(name: "Dana", image: nil)
    var seen: (any Error)?
    manager.setActiveRemoteParticipant(participant, channelUUID: UUID()) { error in
        seen = error
    }
    precondition(PTChannelError.Code.channelNotFound ~= seen!)

    var seenNil: (any Error)?
    manager.setActiveRemoteParticipant(nil, channelUUID: UUID()) { error in
        seenNil = error
    }
    precondition(PTChannelError.Code.channelNotFound ~= seenNil!)
}

func testSetServiceStatusFailsChannelNotFound() {
    let (manager, _, _) = hostManager()
    var seen: (any Error)?
    manager.setServiceStatus(.connecting, channelUUID: UUID()) { error in
        seen = error
    }
    precondition(PTChannelError.Code.channelNotFound ~= seen!)
    seen = nil
    manager.setServiceStatus(.ready, channelUUID: UUID()) { error in
        seen = error
    }
    precondition(PTChannelError.Code.channelNotFound ~= seen!)
    seen = nil
    manager.setServiceStatus(.unavailable, channelUUID: UUID()) { error in
        seen = error
    }
    precondition(PTChannelError.Code.channelNotFound ~= seen!)
}

func testSetTransmissionModeFailsChannelNotFound() {
    let (manager, _, _) = hostManager()
    var seen: (any Error)?
    manager.setTransmissionMode(.fullDuplex, channelUUID: UUID()) { error in
        seen = error
    }
    precondition(PTChannelError.Code.channelNotFound ~= seen!)
    seen = nil
    manager.setTransmissionMode(.halfDuplex, channelUUID: UUID()) { error in
        seen = error
    }
    precondition(PTChannelError.Code.channelNotFound ~= seen!)
    seen = nil
    manager.setTransmissionMode(.listenOnly, channelUUID: UUID()) { error in
        seen = error
    }
    precondition(PTChannelError.Code.channelNotFound ~= seen!)
}

func testSetAccessoryButtonEventsEnabledFailsChannelNotFound() {
    let (manager, _, _) = hostManager()
    var seen: (any Error)?
    manager.setAccessoryButtonEventsEnabled(true, channelUUID: UUID()) { error in
        seen = error
    }
    precondition(PTChannelError.Code.channelNotFound ~= seen!)
    seen = nil
    manager.setAccessoryButtonEventsEnabled(false, channelUUID: UUID()) { error in
        seen = error
    }
    precondition(PTChannelError.Code.channelNotFound ~= seen!)
}
