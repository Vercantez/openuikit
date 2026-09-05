import Foundation

/// Descriptive payload for a ``GroupActivity``.
///
/// `previewImage` is omitted from this isolated compile: it requires
/// CoreGraphics `CGImage`, which is not a declared host dependency. See
/// `oracle-questions.tsv`.
public struct GroupActivityMetadata: Hashable, Sendable, Codable {
    public struct ActivityType: Hashable, Sendable, Codable {
        let token: String

        public static let generic = ActivityType(token: "generic")
        public static let listenTogether = ActivityType(token: "listenTogether")
        public static let watchTogether = ActivityType(token: "watchTogether")
        public static let readTogether = ActivityType(token: "readTogether")
        public static let shopTogether = ActivityType(token: "shopTogether")
        public static let learnTogether = ActivityType(token: "learnTogether")
        public static let createTogether = ActivityType(token: "createTogether")
        public static let exploreTogether = ActivityType(token: "exploreTogether")
        public static let workoutTogether = ActivityType(token: "workoutTogether")
    }

    /// High-level SharePlay experience. Raw values follow api-digester child
    /// order (`watchTogether = 0`, `listenTogether = 1`) and are not Apple-oracle
    /// observations.
    public enum Experience: Int, Codable, Hashable, Sendable {
        case watchTogether = 0
        case listenTogether = 1
    }

    public struct LifetimePolicy: Hashable, Sendable, Codable {
        let token: String

        public static let automatic = LifetimePolicy(token: "automatic")
        public static let endsWhenInitiatorLeaves = LifetimePolicy(token: "endsWhenInitiatorLeaves")
    }

    public var title: String?
    public var subtitle: String?
    public var localizedTitle: String?
    public var localizedSubtitle: String?
    public var fallbackURL: URL?
    public var type: ActivityType
    public var experience: Experience?
    public var lifetimePolicy: LifetimePolicy
    public var sceneAssociationBehavior: SceneAssociationBehavior
    public var supportsContinuationOnTV: Bool
    public var preferredBroadcastOptions: BroadcastOptions

    public init() {
        self.title = nil
        self.subtitle = nil
        self.localizedTitle = nil
        self.localizedSubtitle = nil
        self.fallbackURL = nil
        self.type = .generic
        self.experience = nil
        self.lifetimePolicy = .automatic
        self.sceneAssociationBehavior = .default
        self.supportsContinuationOnTV = false
        self.preferredBroadcastOptions = []
    }

    enum CodingKeys: String, CodingKey {
        case title
        case subtitle
        case localizedTitle
        case localizedSubtitle
        case fallbackURL
        case type
        case experience
        case lifetimePolicy
        case sceneAssociationBehavior
        case supportsContinuationOnTV
        case preferredBroadcastOptions
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        subtitle = try container.decodeIfPresent(String.self, forKey: .subtitle)
        localizedTitle = try container.decodeIfPresent(String.self, forKey: .localizedTitle)
        localizedSubtitle = try container.decodeIfPresent(String.self, forKey: .localizedSubtitle)
        fallbackURL = try container.decodeIfPresent(URL.self, forKey: .fallbackURL)
        type = try container.decodeIfPresent(ActivityType.self, forKey: .type) ?? .generic
        experience = try container.decodeIfPresent(Experience.self, forKey: .experience)
        lifetimePolicy = try container.decodeIfPresent(LifetimePolicy.self, forKey: .lifetimePolicy) ?? .automatic
        sceneAssociationBehavior =
            try container.decodeIfPresent(
                SceneAssociationBehavior.self,
                forKey: .sceneAssociationBehavior
            ) ?? .default
        supportsContinuationOnTV =
            try container.decodeIfPresent(Bool.self, forKey: .supportsContinuationOnTV) ?? false
        preferredBroadcastOptions =
            try container.decodeIfPresent(
                BroadcastOptions.self,
                forKey: .preferredBroadcastOptions
            ) ?? []
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(title, forKey: .title)
        try container.encodeIfPresent(subtitle, forKey: .subtitle)
        try container.encodeIfPresent(localizedTitle, forKey: .localizedTitle)
        try container.encodeIfPresent(localizedSubtitle, forKey: .localizedSubtitle)
        try container.encodeIfPresent(fallbackURL, forKey: .fallbackURL)
        try container.encode(type, forKey: .type)
        try container.encodeIfPresent(experience, forKey: .experience)
        try container.encode(lifetimePolicy, forKey: .lifetimePolicy)
        try container.encode(sceneAssociationBehavior, forKey: .sceneAssociationBehavior)
        try container.encode(supportsContinuationOnTV, forKey: .supportsContinuationOnTV)
        try container.encode(preferredBroadcastOptions, forKey: .preferredBroadcastOptions)
    }
}

extension BroadcastOptions: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.init(rawValue: try container.decode(Int.self))
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

extension GroupActivityMetadata.ActivityType {
    public static let catalog: [GroupActivityMetadata.ActivityType] = [
        .generic,
        .listenTogether,
        .watchTogether,
        .readTogether,
        .shopTogether,
        .learnTogether,
        .createTogether,
        .exploreTogether,
        .workoutTogether,
    ]
}
