@_spi(OpenUIKitHost) import PushToTalk
import Foundation

private final class PTDelegateSurfaceProbe: NSObject, PTChannelManagerDelegate {
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
    var serviceUpdates = 0
    var lastJoinReason: PTChannelJoinReason?
    var lastLeaveReason: PTChannelLeaveReason?
    var lastBeginSource: PTChannelTransmitRequestSource?
    var lastEndSource: PTChannelTransmitRequestSource?
    var lastToken: Data?
    var lastLeavePush = false
    var lastParticipantName: String?

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
        lastBeginSource = source
    }

    func channelManager(
        _ channelManager: PTChannelManager,
        channelUUID: UUID,
        didEndTransmittingFrom source: PTChannelTransmitRequestSource
    ) {
        _ = channelManager
        _ = channelUUID
        ended += 1
        lastEndSource = source
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
        if pushPayload["leave"] as? Bool == true {
            lastLeavePush = true
            return .leaveChannel
        }
        lastLeavePush = false
        let name = pushPayload["name"] as? String ?? "remote"
        lastParticipantName = name
        return .activeRemoteParticipant(PTParticipant(name: name, image: nil))
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
        _ = error
        failedJoin += 1
    }

    func channelManager(
        _ channelManager: PTChannelManager,
        failedToLeaveChannel channelUUID: UUID,
        error: any Error
    ) {
        _ = channelManager
        _ = channelUUID
        _ = error
        failedLeave += 1
    }

    func channelManager(
        _ channelManager: PTChannelManager,
        failedToBeginTransmittingInChannel channelUUID: UUID,
        error: any Error
    ) {
        _ = channelManager
        _ = channelUUID
        _ = error
        failedBegin += 1
    }

    func channelManager(
        _ channelManager: PTChannelManager,
        failedToStopTransmittingInChannel channelUUID: UUID,
        error: any Error
    ) {
        _ = channelManager
        _ = channelUUID
        _ = error
        failedStop += 1
    }

    func incomingServiceUpdatePush(
        channelManager: PTChannelManager,
        channelUUID: UUID,
        pushPayload: [String: Any],
        isHighPriority: Bool,
        remainingHighPriorityBudget: Int,
        completionHandler: @escaping () -> Void
    ) {
        _ = channelManager
        _ = channelUUID
        _ = pushPayload
        _ = isHighPriority
        _ = remainingHighPriorityBudget
        serviceUpdates += 1
        completionHandler()
    }
}

private final class PTRestorationSurfaceProbe: NSObject, PTChannelRestorationDelegate {
    func channelDescriptor(restoredChannelUUID channelUUID: UUID) -> PTChannelDescriptor {
        PTChannelDescriptor(name: channelUUID.uuidString, image: nil)
    }
}

func testPTChannelManagerDelegateRequiredCallbacks() {
    let probe = PTDelegateSurfaceProbe()
    let restoration = PTRestorationSurfaceProbe()
    let manager = PTChannelManager(hostDelegate: probe, restorationDelegate: restoration)
    let uuid = UUID()

    probe.channelManager(manager, didJoinChannel: uuid, reason: .developerRequest)
    probe.channelManager(manager, didJoinChannel: uuid, reason: .channelRestoration)
    probe.channelManager(manager, didLeaveChannel: uuid, reason: .userRequest)
    probe.channelManager(manager, didLeaveChannel: uuid, reason: .systemPolicy)
    probe.channelManager(manager, channelUUID: uuid, didBeginTransmittingFrom: .userRequest)
    probe.channelManager(manager, channelUUID: uuid, didEndTransmittingFrom: .developerRequest)
    probe.channelManager(manager, receivedEphemeralPushToken: Data([0x01, 0x02]))

    let leave = probe.incomingPushResult(
        channelManager: manager,
        channelUUID: uuid,
        pushPayload: ["leave": true]
    )
    precondition(leave.hostLeavesChannel)

    let participantResult = probe.incomingPushResult(
        channelManager: manager,
        channelUUID: uuid,
        pushPayload: ["name": "Riley"]
    )
    precondition(participantResult.hostActiveParticipant?.name == "Riley")
    precondition(probe.lastParticipantName == "Riley")

    let session = NSObject()
    probe.channelManager(manager, didActivate: session)
    probe.channelManager(manager, didDeactivate: session)

    precondition(probe.joined == 2)
    precondition(probe.lastJoinReason == .channelRestoration)
    precondition(probe.left == 2)
    precondition(probe.lastLeaveReason == .systemPolicy)
    precondition(probe.began == 1)
    precondition(probe.lastBeginSource == .userRequest)
    precondition(probe.ended == 1)
    precondition(probe.lastEndSource == .developerRequest)
    precondition(probe.tokens == 1)
    precondition(probe.lastToken == Data([0x01, 0x02]))
    precondition(probe.lastLeavePush)
    precondition(probe.activated == 1)
    precondition(probe.deactivated == 1)
}

func testPTChannelManagerDelegateOptionalCallbacks() {
    let probe = PTDelegateSurfaceProbe()
    let restoration = PTRestorationSurfaceProbe()
    let manager = PTChannelManager(hostDelegate: probe, restorationDelegate: restoration)
    let uuid = UUID()
    let error = PTChannelError(.unknown)

    probe.channelManager(manager, failedToJoinChannel: uuid, error: error)
    probe.channelManager(manager, failedToLeaveChannel: uuid, error: error)
    probe.channelManager(
        manager,
        failedToBeginTransmittingInChannel: uuid,
        error: PTChannelError(.transmissionNotAllowed)
    )
    probe.channelManager(
        manager,
        failedToStopTransmittingInChannel: uuid,
        error: PTChannelError(.transmissionNotFound)
    )

    var completed = false
    probe.incomingServiceUpdatePush(
        channelManager: manager,
        channelUUID: uuid,
        pushPayload: ["status": "ok"],
        isHighPriority: true,
        remainingHighPriorityBudget: 3
    ) {
        completed = true
    }

    precondition(probe.failedJoin == 1)
    precondition(probe.failedLeave == 1)
    precondition(probe.failedBegin == 1)
    precondition(probe.failedStop == 1)
    precondition(probe.serviceUpdates == 1)
    precondition(completed)
}

func testPTChannelRestorationDelegate() {
    let restoration = PTRestorationSurfaceProbe()
    let uuid = UUID()
    let descriptor = restoration.channelDescriptor(restoredChannelUUID: uuid)
    precondition(descriptor.name == uuid.uuidString)
    precondition(descriptor.image == nil)
}
