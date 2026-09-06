import Foundation

// Linux starting point for Apple's LiveCommunicationKit. There is no CallKit
// daemon, telephony stack, VoIP Push entitlement, or call-history database on
// this host. Value types, option sets, action state machines, and
// process-local conversation objects are implemented and tested here.
// Methods that require Apple services fail closed with
// `CocoaError.featureUnsupported`. Do not treat a compiling selector as
// evidence of Apple runtime behavior.

/// AVFoundation is not a declared dependency. Delegate audio-session
/// callbacks type-check as `NSObject` and are never delivered by
/// `ConversationManager` on Linux.
public typealias AVAudioSession = NSObject

enum LiveCommunicationKitSupport {
    static func unsupported(_ operation: String) -> CocoaError {
        CocoaError(
            .featureUnsupported,
            userInfo: [
                NSLocalizedDescriptionKey:
                    "LiveCommunicationKit.\(operation) requires Apple telephony, CallKit, or call-history services that are not available on Linux"
            ]
        )
    }
}

/// Host-only constructors so tests can exercise `Conversation` without
/// claiming that an incoming call was reported to an Apple daemon.
@_spi(OpenUIKitHost)
public enum LiveCommunicationKitHost {
    public static func conversation(
        uuid: UUID = UUID(),
        state: Conversation.State = .idle,
        localMember: Handle? = nil
    ) -> Conversation {
        Conversation(uuid: uuid, state: state, localMember: localMember)
    }

    public static func translationEngine(
        on action: SetTranslatingAction
    ) -> SetTranslatingAction.TranslationEngine? {
        action.hostTranslationEngine
    }

    public static func dateConnected(on action: JoinConversationAction) -> Date? {
        action.hostDateConnected
    }

    public static func dateEnded(on action: EndConversationAction) -> Date? {
        action.hostDateEnded
    }

    public static func dateStarted(on action: StartConversationAction) -> Date? {
        action.hostDateStarted
    }
}
