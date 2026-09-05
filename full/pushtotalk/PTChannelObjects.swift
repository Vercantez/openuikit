import Foundation

/// Channel metadata shown in the system Push To Talk UI.
///
/// Linux stores `name` and the optional image object. The image is an
/// `NSObject` stand-in because UIKit is not a declared dependency; it is
/// never decoded as a bitmap. Apple's `@NSCopying` copy-on-store behavior
/// is unobserved.
public class PTChannelDescriptor: NSObject {
    public let name: String
    public let image: UIImage?

    @available(*, unavailable)
    public override init() {
        fatalError("PTChannelDescriptor has no public default initializer")
    }

    public init(name: String, image: UIImage?) {
        self.name = name
        self.image = image
        super.init()
    }
}

/// Remote participant shown on an active channel.
///
/// Linux stores `name` and the optional image object. Same UIKit boundary
/// as `PTChannelDescriptor`.
public class PTParticipant: NSObject {
    public let name: String
    public let image: UIImage?

    @available(*, unavailable)
    public override init() {
        fatalError("PTParticipant has no public default initializer")
    }

    public init(name: String, image: UIImage?) {
        self.name = name
        self.image = image
        super.init()
    }
}

/// Result of handling an incoming Push To Talk payload.
///
/// On Darwin this object is produced by
/// `incomingPushResult(channelManager:channelUUID:pushPayload:)` and consumed
/// by the system. Linux constructs the two documented kinds locally; the
/// manager never delivers an incoming Apple push, so returning a result from
/// a host-side delegate call does not join or leave a real channel.
public class PTPushResult: NSObject {
    enum Kind {
        case leaveChannel
        case activeRemoteParticipant(PTParticipant)
    }

    let kind: Kind

    private static let leaveChannelSentinel = PTPushResult(kind: .leaveChannel)

    @available(*, unavailable)
    public override init() {
        fatalError("PTPushResult has no public default initializer")
    }

    private init(kind: Kind) {
        self.kind = kind
        super.init()
    }

    public class var leaveChannel: PTPushResult {
        leaveChannelSentinel
    }

    public class func activeRemoteParticipant(_ participant: PTParticipant) -> PTPushResult {
        PTPushResult(kind: .activeRemoteParticipant(participant))
    }

    @_spi(OpenUIKitHost)
    public var hostLeavesChannel: Bool {
        if case .leaveChannel = kind { return true }
        return false
    }

    @_spi(OpenUIKitHost)
    public var hostActiveParticipant: PTParticipant? {
        if case .activeRemoteParticipant(let participant) = kind {
            return participant
        }
        return nil
    }
}
