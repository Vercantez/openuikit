import Foundation

/// Marker protocol for a participant that may become the preferred
/// external-playback owner.
///
/// Apple graph: empty protocol, iOS 26. `preferredParticipantForExternalPlayback`
/// is `weak`, so the Linux overlay is class-bound (`AnyObject`). Darwin
/// class-boundedness is unobserved.
public protocol AVRoutingPlaybackParticipant: AnyObject {}

/// Shared arbiter for preferred external-playback participants.
///
/// Linux stores the weak participant pointer and otherwise does nothing.
/// It does not talk to AVFoundation playback, AirPlay, or a media
/// server. `init` is unavailable; use `shared()`.
///
/// Apple graph: `open class AVRoutingPlaybackArbiter: NSObject`, iOS 26.
/// Pinned macios marks `DisableDefaultCtor` and
/// `sharedRoutingPlaybackArbiter`.
open class AVRoutingPlaybackArbiter: NSObject {
    private static let sharedInstance = AVRoutingPlaybackArbiter()

    public weak var preferredParticipantForExternalPlayback:
        (any AVRoutingPlaybackParticipant)?

    private override init() {
        super.init()
    }

    public static func shared() -> AVRoutingPlaybackArbiter {
        sharedInstance
    }
}
