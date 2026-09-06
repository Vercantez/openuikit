import Foundation

public struct MusicSubscription: Hashable, Sendable, CustomStringConvertible {
    public let canBecomeSubscriber: Bool
    public let canPlayCatalogContent: Bool
    public let hasCloudLibraryEnabled: Bool

    public init(
        canBecomeSubscriber: Bool = false,
        canPlayCatalogContent: Bool = false,
        hasCloudLibraryEnabled: Bool = false
    ) {
        self.canBecomeSubscriber = canBecomeSubscriber
        self.canPlayCatalogContent = canPlayCatalogContent
        self.hasCloudLibraryEnabled = hasCloudLibraryEnabled
    }

    public var description: String {
        "MusicSubscription(canPlayCatalogContent: \(canPlayCatalogContent))"
    }

    public static var current: MusicSubscription {
        get async throws {
            throw Error.permissionDenied
        }
    }

    public static var subscriptionUpdates: Updates { Updates() }

    public enum Error: String, Swift.Error, Sendable, LocalizedError, CustomStringConvertible {
        case permissionDenied
        case privacyAcknowledgementRequired
        case unknown

        public typealias RawValue = String
        public var description: String { rawValue }
        public var errorDescription: String? { rawValue }
        public var failureReason: String? { rawValue }
        public var recoverySuggestion: String? { nil }
        public var helpAnchor: String? { nil }
    }

    public struct Updates: AsyncSequence {
        public typealias Element = MusicSubscription
        public typealias AsyncIterator = Iterator

        public init() {}

        public func makeAsyncIterator() -> Iterator { Iterator() }

        public struct Iterator: AsyncIteratorProtocol {
            public typealias Element = MusicSubscription
            public init() {}
            public mutating func next() async -> MusicSubscription? { nil }
        }
    }
}

public struct MusicSubscriptionOffer {
    public struct MessageIdentifier: Hashable, Sendable, RawRepresentable, CustomStringConvertible {
        public typealias RawValue = String
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }
        public init(_ rawValue: String) { self.rawValue = rawValue }
        public var description: String { rawValue }
        public static let addMusic = MessageIdentifier("addMusic")
        public static let playMusic = MessageIdentifier("playMusic")
        public static let join = MessageIdentifier("join")
    }

    public struct Action: Hashable, Sendable, RawRepresentable, CustomStringConvertible {
        public typealias RawValue = String
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }
        public init(_ rawValue: String) { self.rawValue = rawValue }
        public var description: String { rawValue }
        public static let subscribe = Action("subscribe")
    }

    public struct Options: Hashable, Sendable, CustomStringConvertible {
        public var action: Action
        public var messageIdentifier: MessageIdentifier
        public var itemID: MusicItemID?
        public var affiliateToken: String?
        public var campaignToken: String?

        public init(
            action: Action = .subscribe,
            messageIdentifier: MessageIdentifier = .join,
            itemID: MusicItemID? = nil,
            affiliateToken: String? = nil,
            campaignToken: String? = nil
        ) {
            self.action = action
            self.messageIdentifier = messageIdentifier
            self.itemID = itemID
            self.affiliateToken = affiliateToken
            self.campaignToken = campaignToken
        }

        public static let `default` = Options()
        public var description: String {
            "MusicSubscriptionOffer.Options(\(action.rawValue), \(messageIdentifier.rawValue))"
        }
    }
}

public struct ArtworkImage: View {
    public var artwork: Artwork
    public var width: CGFloat?
    public var height: CGFloat?

    public init(_ artwork: Artwork, width: CGFloat, height: CGFloat) {
        self.artwork = artwork
        self.width = width
        self.height = height
    }

    public init(_ artwork: Artwork, width: CGFloat) {
        self.artwork = artwork
        self.width = width
        self.height = nil
    }

    public init(_ artwork: Artwork, height: CGFloat) {
        self.artwork = artwork
        self.width = nil
        self.height = height
    }

    public typealias Body = EmptyView
    public var body: EmptyView { EmptyView() }
}

extension View {
    public func musicSubscriptionOffer(
        isPresented: Binding<Bool>,
        options: MusicSubscriptionOffer.Options = .default,
        onLoadCompletion: @escaping ((any Error)?) -> Void = { _ in }
    ) -> Self {
        _ = (isPresented.wrappedValue, options)
        onLoadCompletion(MusicKitPortableError.subscriptionUnavailable)
        return self
    }
}
