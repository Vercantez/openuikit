import Foundation

/// The Communication Limits question topic. `id` is the Linux stand-in for
/// Apple's unpublished topic identifier; see `oracle-questions.tsv`.
public struct CommunicationTopic: QuestionTopic, Codable {
    public static let id = PermissionKitSupport.communicationTopicID

    public enum Action: String, Codable, Hashable, Sendable {
        case friend
        case follow
        case beFollowed
        case call
        case message
        case videoCall
        case audioCall
        case communicate
        case chat
        case connect
    }

    public struct PersonInformation: Codable {
        public var handle: CommunicationHandle
        public var nameComponents: PersonNameComponents?
        public var avatarImage: CGImage?
        /// TBD-exported storage; not in the symbol-graph census.
        public var contactIdentifier: String?

        public init(
            handle: CommunicationHandle,
            nameComponents: PersonNameComponents? = nil,
            avatarImage: CGImage? = nil
        ) {
            self.handle = handle
            self.nameComponents = nameComponents
            self.avatarImage = avatarImage
            self.contactIdentifier = nil
        }

        public init(
            handle: CommunicationHandle,
            contactIdentifier: String?,
            nameComponents: PersonNameComponents? = nil,
            avatarImage: CGImage? = nil
        ) {
            self.handle = handle
            self.nameComponents = nameComponents
            self.avatarImage = avatarImage
            self.contactIdentifier = contactIdentifier
        }

        private enum CodingKeys: String, CodingKey {
            case handle
            case nameComponents
            case contactIdentifier
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            handle = try container.decode(CommunicationHandle.self, forKey: .handle)
            nameComponents = try container.decodeIfPresent(
                PersonNameComponents.self, forKey: .nameComponents
            )
            contactIdentifier = try container.decodeIfPresent(
                String.self, forKey: .contactIdentifier
            )
            avatarImage = nil
        }

        public func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(handle, forKey: .handle)
            try container.encodeIfPresent(nameComponents, forKey: .nameComponents)
            try container.encodeIfPresent(contactIdentifier, forKey: .contactIdentifier)
        }
    }

    public var personInformation: [PersonInformation]
    public var actions: Set<Action>

    public init(
        personInformation: [PersonInformation],
        actions: Set<Action>
    ) {
        self.personInformation = personInformation
        self.actions = actions
    }

    public init(personInformation: [PersonInformation]) {
        self.init(personInformation: personInformation, actions: [])
    }
}

extension CommunicationTopic.Action {
    public static func == (
        a: CommunicationTopic.Action,
        b: CommunicationTopic.Action
    ) -> Bool {
        a.rawValue == b.rawValue
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }
}
