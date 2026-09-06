import Foundation

// Linux starting point for Apple's PermissionKit. There is no Screen Time
// daemon, Communication Limits entitlement, contact-sync service, or
// system permission prompt UI on this host. Value types, Codable
// round trips, and fail-closed CommunicationLimits queries are implemented
// and tested here. Methods that require Apple services throw AskError or
// return empty results. Do not treat a compiling selector as evidence of
// Apple runtime behavior.

enum PermissionKitSupport {
    static let communicationTopicID = "CommunicationTopic"
}

/// Host-only constructors so tests can build questions without claiming
/// that an Apple permission prompt was presented.
@_spi(OpenUIKitHost)
public enum PermissionKitHost {
    public static func permissionChoice(
        id: String,
        title: String,
        answer: PermissionChoice.Answer
    ) -> PermissionChoice {
        PermissionChoice(id: id, title: title, answer: answer)
    }

    public static func permissionQuestion<Topic: QuestionTopic>(
        id: UUID = UUID(),
        title: String = "",
        subtitle: String = "",
        topic: Topic,
        choices: [PermissionChoice] = [.approve, .decline],
        defaultChoice: PermissionChoice = .approve,
        expirationDate: Date? = nil
    ) -> PermissionQuestion<Topic> {
        PermissionQuestion(
            id: id,
            title: title,
            subtitle: subtitle,
            topic: topic,
            choices: choices,
            defaultChoice: defaultChoice,
            expirationDate: expirationDate
        )
    }
}
