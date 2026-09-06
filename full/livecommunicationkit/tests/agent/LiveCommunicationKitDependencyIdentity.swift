import Foundation
import LiveCommunicationKit

func liveCommunicationKitDependencyIdentityProbe() {
    let uuid = UUID()
    let data = Data("live-communication-kit".utf8)
    let date = Date(timeIntervalSince1970: 1_700_000_000)
    precondition(type(of: uuid) == UUID.self)
    precondition(type(of: data) == Data.self)
    precondition(type(of: date) == Date.self)
    precondition(!String(reflecting: type(of: uuid)).hasPrefix("LiveCommunicationKit."))
    precondition(!String(reflecting: type(of: data)).hasPrefix("LiveCommunicationKit."))
    precondition(!String(reflecting: type(of: date)).hasPrefix("LiveCommunicationKit."))

    let handle = Handle(type: .phoneNumber, value: "+15555550199", displayName: "Identity")
    precondition(handle.value == "+15555550199")

    let configuration = ConversationManager.Configuration(
        ringtoneName: String(data: data, encoding: .utf8),
        iconTemplateImageData: data,
        maximumConversationGroups: 2,
        maximumConversationsPerConversationGroup: 5,
        includesConversationInRecents: true,
        supportsVideo: false,
        supportedHandleTypes: [.phoneNumber],
        supportsAudioTranslation: false
    )
    precondition(configuration.iconTemplateImageData == data)
    precondition(configuration.ringtoneName == "live-communication-kit")

    let action = ConversationAction(conversationUUID: uuid, timeoutDate: date)
    precondition(action.conversationUUID == uuid)
    precondition(action.timeoutDate == date)

    let language = Locale.Language(identifier: "en")
    let translating = SetTranslatingAction(
        conversationID: uuid,
        isTranslating: true,
        localLanguage: language,
        remoteLanguage: language
    )
    precondition(translating.conversationUUID == uuid)
}

#if LIVECOMMUNICATIONKIT_IDENTITY_MAIN
liveCommunicationKitDependencyIdentityProbe()
print("LIVECOMMUNICATIONKIT_DEPENDENCY_IDENTITY_OK")
#endif
