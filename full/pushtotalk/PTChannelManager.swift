import Foundation

/// Delegate for channel join, leave, transmit, push, and audio-session events.
///
/// Required methods have no defaults. Optional failure and service-update
/// methods have empty defaults so Swift can express Apple's `optional`
/// ObjC protocol without `@objc`. `PTChannelManager` on Linux never invokes
/// join, leave, transmit, token, or audio-session callbacks.
public protocol PTChannelManagerDelegate: NSObjectProtocol {
    func channelManager(
        _ channelManager: PTChannelManager,
        didJoinChannel channelUUID: UUID,
        reason: PTChannelJoinReason
    )

    func channelManager(
        _ channelManager: PTChannelManager,
        didLeaveChannel channelUUID: UUID,
        reason: PTChannelLeaveReason
    )

    func channelManager(
        _ channelManager: PTChannelManager,
        channelUUID: UUID,
        didBeginTransmittingFrom source: PTChannelTransmitRequestSource
    )

    func channelManager(
        _ channelManager: PTChannelManager,
        channelUUID: UUID,
        didEndTransmittingFrom source: PTChannelTransmitRequestSource
    )

    func channelManager(
        _ channelManager: PTChannelManager,
        receivedEphemeralPushToken pushToken: Data
    )

    func incomingPushResult(
        channelManager: PTChannelManager,
        channelUUID: UUID,
        pushPayload: [String: Any]
    ) -> PTPushResult

    func channelManager(
        _ channelManager: PTChannelManager,
        didActivate audioSession: AVAudioSession
    )

    func channelManager(
        _ channelManager: PTChannelManager,
        didDeactivate audioSession: AVAudioSession
    )

    func channelManager(
        _ channelManager: PTChannelManager,
        failedToBeginTransmittingInChannel channelUUID: UUID,
        error: any Error
    )

    func channelManager(
        _ channelManager: PTChannelManager,
        failedToJoinChannel channelUUID: UUID,
        error: any Error
    )

    func channelManager(
        _ channelManager: PTChannelManager,
        failedToLeaveChannel channelUUID: UUID,
        error: any Error
    )

    func channelManager(
        _ channelManager: PTChannelManager,
        failedToStopTransmittingInChannel channelUUID: UUID,
        error: any Error
    )

    func incomingServiceUpdatePush(
        channelManager: PTChannelManager,
        channelUUID: UUID,
        pushPayload: [String: Any],
        isHighPriority: Bool,
        remainingHighPriorityBudget: Int,
        completionHandler: @escaping () -> Void
    )
}

extension PTChannelManagerDelegate {
    public func channelManager(
        _ channelManager: PTChannelManager,
        failedToBeginTransmittingInChannel channelUUID: UUID,
        error: any Error
    ) {
        _ = channelManager
        _ = channelUUID
        _ = error
    }

    public func channelManager(
        _ channelManager: PTChannelManager,
        failedToJoinChannel channelUUID: UUID,
        error: any Error
    ) {
        _ = channelManager
        _ = channelUUID
        _ = error
    }

    public func channelManager(
        _ channelManager: PTChannelManager,
        failedToLeaveChannel channelUUID: UUID,
        error: any Error
    ) {
        _ = channelManager
        _ = channelUUID
        _ = error
    }

    public func channelManager(
        _ channelManager: PTChannelManager,
        failedToStopTransmittingInChannel channelUUID: UUID,
        error: any Error
    ) {
        _ = channelManager
        _ = channelUUID
        _ = error
    }

    public func incomingServiceUpdatePush(
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
        completionHandler()
    }

    public func incomingServiceUpdatePush(
        channelManager: PTChannelManager,
        channelUUID: UUID,
        pushPayload: [String: Any],
        isHighPriority: Bool,
        remainingHighPriorityBudget: Int
    ) async {
        _ = channelManager
        _ = channelUUID
        _ = pushPayload
        _ = isHighPriority
        _ = remainingHighPriorityBudget
    }
}

/// Restoration delegate asked for a descriptor when the system restores a
/// previously joined channel. Linux never restores a channel.
public protocol PTChannelRestorationDelegate: NSObjectProtocol {
    func channelDescriptor(restoredChannelUUID channelUUID: UUID) -> PTChannelDescriptor
}

/// Process-local Push To Talk channel manager.
///
/// The public factory always fails with `PTInstantiationError.invalidPlatform`
/// because Linux has no PTT daemon, background mode, or entitlement. Host
/// tests construct an instance through `@_spi(OpenUIKitHost)` to exercise
/// the fail-closed instance methods. `activeChannelUUID` stays `nil`. Join,
/// leave, and transmit never succeed and never invent Apple callbacks.
public class PTChannelManager: NSObject {
    public private(set) var activeChannelUUID: UUID?

    private weak var delegate: (any PTChannelManagerDelegate)?
    private weak var restorationDelegate: (any PTChannelRestorationDelegate)?

    @_spi(OpenUIKitHost)
    public private(set) var hostRequestedJoinUUID: UUID?
    @_spi(OpenUIKitHost)
    public private(set) var hostRequestedJoinName: String?
    @_spi(OpenUIKitHost)
    public private(set) var hostRequestedLeaveUUID: UUID?
    @_spi(OpenUIKitHost)
    public private(set) var hostRequestedBeginUUID: UUID?
    @_spi(OpenUIKitHost)
    public private(set) var hostRequestedStopUUID: UUID?

    @available(*, unavailable)
    public override init() {
        fatalError("PTChannelManager has no public default initializer")
    }

    @_spi(OpenUIKitHost)
    public init(
        hostDelegate delegate: any PTChannelManagerDelegate,
        restorationDelegate: any PTChannelRestorationDelegate
    ) {
        self.delegate = delegate
        self.restorationDelegate = restorationDelegate
        self.activeChannelUUID = nil
        super.init()
    }

    public class func channelManager(
        delegate: any PTChannelManagerDelegate,
        restorationDelegate: any PTChannelRestorationDelegate,
        completionHandler: @escaping (PTChannelManager?, (any Error)?) -> Void
    ) {
        _ = delegate
        _ = restorationDelegate
        completionHandler(nil, PTInstantiationError(.invalidPlatform))
    }

    public class func channelManager(
        delegate: any PTChannelManagerDelegate,
        restorationDelegate: any PTChannelRestorationDelegate
    ) async throws -> PTChannelManager {
        throw PTInstantiationError(.invalidPlatform)
    }

    public func requestJoinChannel(channelUUID: UUID, descriptor: PTChannelDescriptor) {
        hostRequestedJoinUUID = channelUUID
        hostRequestedJoinName = descriptor.name
        // Fail-closed: never joins, never sets activeChannelUUID, never
        // delivers didJoinChannel. The optional failure callback's Apple
        // error code is unobserved; Linux does not invent one.
    }

    public func leaveChannel(channelUUID: UUID) {
        hostRequestedLeaveUUID = channelUUID
        // Fail-closed: nothing is joined, so there is nothing to leave.
    }

    public func requestBeginTransmitting(channelUUID: UUID) {
        hostRequestedBeginUUID = channelUUID
        // Fail-closed: no joined channel, no audio session, no transmit.
    }

    public func stopTransmitting(channelUUID: UUID) {
        hostRequestedStopUUID = channelUUID
        // Fail-closed: no transmission is in progress.
    }

    public func setAccessoryButtonEventsEnabled(
        _ enabled: Bool,
        channelUUID: UUID,
        completionHandler: (((any Error)?) -> Void)? = nil
    ) {
        _ = enabled
        _ = channelUUID
        completionHandler?(PTChannelError(.channelNotFound))
    }

    public func setAccessoryButtonEventsEnabled(
        _ enabled: Bool,
        channelUUID: UUID
    ) async throws {
        _ = enabled
        _ = channelUUID
        throw PTChannelError(.channelNotFound)
    }

    public func setActiveRemoteParticipant(
        _ participant: PTParticipant?,
        channelUUID: UUID,
        completionHandler: (((any Error)?) -> Void)? = nil
    ) {
        _ = participant
        _ = channelUUID
        completionHandler?(PTChannelError(.channelNotFound))
    }

    public func setActiveRemoteParticipant(
        _ participant: PTParticipant?,
        channelUUID: UUID
    ) async throws {
        _ = participant
        _ = channelUUID
        throw PTChannelError(.channelNotFound)
    }

    public func setChannelDescriptor(
        _ channelDescriptor: PTChannelDescriptor,
        channelUUID: UUID,
        completionHandler: (((any Error)?) -> Void)? = nil
    ) {
        _ = channelDescriptor
        _ = channelUUID
        completionHandler?(PTChannelError(.channelNotFound))
    }

    public func setChannelDescriptor(
        _ channelDescriptor: PTChannelDescriptor,
        channelUUID: UUID
    ) async throws {
        _ = channelDescriptor
        _ = channelUUID
        throw PTChannelError(.channelNotFound)
    }

    public func setServiceStatus(
        _ status: PTServiceStatus,
        channelUUID: UUID,
        completionHandler: (((any Error)?) -> Void)? = nil
    ) {
        _ = status
        _ = channelUUID
        completionHandler?(PTChannelError(.channelNotFound))
    }

    public func setServiceStatus(
        _ status: PTServiceStatus,
        channelUUID: UUID
    ) async throws {
        _ = status
        _ = channelUUID
        throw PTChannelError(.channelNotFound)
    }

    public func setTransmissionMode(
        _ transmissionMode: PTTransmissionMode,
        channelUUID: UUID,
        completionHandler: (((any Error)?) -> Void)? = nil
    ) {
        _ = transmissionMode
        _ = channelUUID
        completionHandler?(PTChannelError(.channelNotFound))
    }

    public func setTransmissionMode(
        _ transmissionMode: PTTransmissionMode,
        channelUUID: UUID
    ) async throws {
        _ = transmissionMode
        _ = channelUUID
        throw PTChannelError(.channelNotFound)
    }

    @_spi(OpenUIKitHost)
    public var hostRestorationDelegate: (any PTChannelRestorationDelegate)? {
        restorationDelegate
    }

    @_spi(OpenUIKitHost)
    public var hostDelegate: (any PTChannelManagerDelegate)? {
        delegate
    }
}
