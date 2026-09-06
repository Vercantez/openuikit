import Foundation

/// An object that represents an audio session.
///
/// Apple graph: `@objc(BEAudioSession) class BEAudioSession` inheriting
/// `NSObject`, iOS 26. The ObjC import is `open class`. Designated
/// `init(audioSession:)` retains the given session. Linux has no
/// `AVAudioSession` routing hardware: `availableOutputs` is empty,
/// `preferredOutput` stays `nil`, and `setPreferredOutput` always throws
/// `BrowserEngineCore.linux.unavailable` / code 1. Darwin's NSError domain
/// and whether ObjC `availableOutputs` is nil versus empty are unobserved.
open class BEAudioSession: NSObject {
    let hostAudioSession: AVAudioSession

    /// Designated initializer. Retains `audioSession` by object identity.
    /// Does not activate an `AVAudioSession` or query hardware ports.
    public init(audioSession: AVAudioSession) {
        hostAudioSession = audioSession
        super.init()
    }

    @available(*, unavailable, message: "Use init(audioSession:)")
    public override init() {
        hostAudioSession = AVAudioSession()
        super.init()
    }

    /// Output ports available for routing.
    ///
    /// Swift overlay (exact-usr): non-optional `Array`. ObjC header is
    /// `nullable NSArray`. Linux has no audio hardware, so this is empty.
    /// An empty array is not a fabricated port list.
    open var availableOutputs: [AVAudioSessionPortDescription] { [] }

    /// Preferred output port. Nil until a preference is successfully set.
    /// Linux never succeeds, so this stays `nil`.
    open var preferredOutput: AVAudioSessionPortDescription? { nil }

    /// Select a preferred output port. Setting nil would clear the preference
    /// on Darwin. Linux has no routing daemon: always throws, including when
    /// `outputPort` is nil. Does not invent a successful route.
    open func setPreferredOutput(_ outputPort: AVAudioSessionPortDescription?) throws {
        _ = outputPort
        throw browserEngineCoreUnavailableError(operation: "BEAudioSession.setPreferredOutput")
    }
}
