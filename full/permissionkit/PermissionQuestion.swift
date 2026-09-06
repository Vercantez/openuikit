import Foundation

public protocol QuestionTopic: Decodable, Encodable {
    static var id: String { get }
}

/// A permission prompt payload. Linux convenience initializers fill
/// `choices` with `[.approve, .decline]` and `defaultChoice` with `.approve`.
/// Apple's exact default titles, subtitles, and choice lists are unknown.
public final class PermissionQuestion<Topic: QuestionTopic>: Identifiable, Codable {
    public typealias ID = UUID

    public let id: UUID
    public let topic: Topic
    public private(set) var storedChoices: [PermissionChoice]
    public private(set) var storedDefaultChoice: PermissionChoice
    public var expirationDate: Date?
    /// TBD-exported; not in the symbol-graph census.
    public var title: String
    /// TBD-exported; not in the symbol-graph census.
    public var subtitle: String

    public var choices: [PermissionChoice] { storedChoices }
    public var defaultChoice: PermissionChoice { storedDefaultChoice }

    public init(
        id: UUID = UUID(),
        title: String = "",
        subtitle: String = "",
        topic: Topic,
        choices: [PermissionChoice] = [.approve, .decline],
        defaultChoice: PermissionChoice = .approve,
        expirationDate: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.topic = topic
        self.storedChoices = choices
        self.storedDefaultChoice = defaultChoice
        self.expirationDate = expirationDate
    }

    private enum CodingKeys: String, CodingKey {
        case id, topic, choices, defaultChoice, expirationDate, title, subtitle
    }

    public required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        topic = try container.decode(Topic.self, forKey: .topic)
        storedChoices = try container.decode([PermissionChoice].self, forKey: .choices)
        storedDefaultChoice = try container.decode(
            PermissionChoice.self, forKey: .defaultChoice
        )
        expirationDate = try container.decodeIfPresent(Date.self, forKey: .expirationDate)
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        subtitle = try container.decodeIfPresent(String.self, forKey: .subtitle) ?? ""
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(topic, forKey: .topic)
        try container.encode(storedChoices, forKey: .choices)
        try container.encode(storedDefaultChoice, forKey: .defaultChoice)
        try container.encodeIfPresent(expirationDate, forKey: .expirationDate)
        try container.encode(title, forKey: .title)
        try container.encode(subtitle, forKey: .subtitle)
    }
}

extension PermissionQuestion where Topic == CommunicationTopic {
    public convenience init(communicationTopic: Topic) {
        self.init(topic: communicationTopic)
    }

    public convenience init(handles: [CommunicationHandle]) {
        let people = handles.map {
            CommunicationTopic.PersonInformation(handle: $0)
        }
        self.init(communicationTopic: CommunicationTopic(personInformation: people))
    }

    public convenience init(handle: CommunicationHandle) {
        self.init(handles: [handle])
    }
}
