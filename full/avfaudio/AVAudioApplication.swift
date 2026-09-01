import Foundation

public final class AVAudioApplication: NSObject, @unchecked Sendable {
    public enum MicrophoneInjectionPermission: Int, Hashable, Sendable {
        case undetermined = 0
        case denied = 1
        case granted = 2
        case serviceDisabled = 3
    }

    public enum recordPermission: Int, Hashable, Sendable {
        case undetermined = 0
        case denied = 1
        case granted = 2
    }

    public static let inputMuteStateChangeNotification = NSNotification.Name(
        "AVAudioApplicationInputMuteStateChangeNotification"
    )
    public static let muteStateKey = "AVAudioApplicationMuteStateKey"

    public static let shared = AVAudioApplication()
    public private(set) var isInputMuted = true
    public var recordPermission: recordPermission { .denied }
    public var microphoneInjectionPermission: MicrophoneInjectionPermission { .serviceDisabled }

    public class func requestRecordPermission(completionHandler response: @escaping (Bool) -> Void) {
        response(false)
    }

    public class func requestMicrophoneInjectionPermission(
        completionHandler response: @escaping (MicrophoneInjectionPermission) -> Void
    ) {
        response(.serviceDisabled)
    }

    public func setInputMuted(_ muted: Bool) throws {
        isInputMuted = muted
    }
}
