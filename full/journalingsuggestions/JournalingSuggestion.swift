import Foundation

public protocol JournalingSuggestionAsset {
    associatedtype JournalingSuggestionContent: JournalingSuggestionAsset = Self
}

private struct AssetBox: @unchecked Sendable {
    let typeID: ObjectIdentifier
    let metatype: any JournalingSuggestionAsset.Type
    let value: Any
}

public struct JournalingSuggestion: Equatable, Hashable, Sendable {
    public let title: String
    public let date: DateInterval?
    public let items: [ItemContent]

    @_spi(OpenUIKitHost)
    public init(title: String, date: DateInterval?, items: [ItemContent]) {
        self.title = title
        self.date = date
        self.items = items
    }

    public static func == (lhs: JournalingSuggestion, rhs: JournalingSuggestion) -> Bool {
        lhs.title == rhs.title
            && lhs.date == rhs.date
            && lhs.items.map(\.id) == rhs.items.map(\.id)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(title)
        hasher.combine(date)
        hasher.combine(items.map(\.id))
    }

    /// Linux host: returns installed payloads of `Content`. Apple's method is
    /// `async` and loads from the journaling suggestion service.
    public func content<Content: JournalingSuggestionAsset>(
        forType type: Content.Type
    ) async -> [Content] {
        _contents(ofType: type)
    }

    @_spi(OpenUIKitHost)
    public func _contents<Content: JournalingSuggestionAsset>(
        ofType type: Content.Type
    ) -> [Content] {
        items.compactMap { try? $0._content(forType: type) }
    }
}

extension JournalingSuggestion {
    public struct Reflection: Equatable, Hashable, Sendable, JournalingSuggestionAsset {
        public typealias JournalingSuggestionContent = Reflection

        public var prompt: String
        public var color: Color?

        @_spi(OpenUIKitHost)
        public init(prompt: String, color: Color? = nil) {
            self.prompt = prompt
            self.color = color
        }
    }

    public struct EventPoster: Equatable, Hashable, Sendable, JournalingSuggestionAsset {
        public typealias JournalingSuggestionContent = EventPoster

        public var title: AttributedString
        public var eventStart: Date?
        public var eventEnd: Date?
        public var image: URL?
        public var isHost: Bool?
        public var placeName: String?

        @_spi(OpenUIKitHost)
        public init(
            title: AttributedString,
            eventStart: Date? = nil,
            eventEnd: Date? = nil,
            image: URL? = nil,
            isHost: Bool? = nil,
            placeName: String? = nil
        ) {
            self.title = title
            self.eventStart = eventStart
            self.eventEnd = eventEnd
            self.image = image
            self.isHost = isHost
            self.placeName = placeName
        }
    }

    public struct ItemContent: Identifiable, Sendable {
        public typealias ID = UUID

        public let id: UUID
        private let assets: [AssetBox]

        public var representations: [any JournalingSuggestionAsset.Type] {
            assets.map(\.metatype)
        }

        @_spi(OpenUIKitHost)
        public init(id: UUID = UUID(), assets: [any JournalingSuggestionAsset] = []) {
            self.id = id
            self.assets = assets.map { asset in
                AssetBox(
                    typeID: ObjectIdentifier(type(of: asset)),
                    metatype: type(of: asset),
                    value: asset
                )
            }
        }

        public func hasContent<Content: JournalingSuggestionAsset>(
            ofType content: Content.Type
        ) -> Bool {
            assets.contains { $0.typeID == ObjectIdentifier(content) }
        }

        public func content<Content: JournalingSuggestionAsset>(
            forType type: Content.Type
        ) async throws -> Content? {
            try _content(forType: type)
        }

        @_spi(OpenUIKitHost)
        public func _content<Content: JournalingSuggestionAsset>(
            forType type: Content.Type
        ) throws -> Content? {
            guard let box = assets.first(where: { $0.typeID == ObjectIdentifier(type) }) else {
                return nil
            }
            guard let typed = box.value as? Content else {
                throw JournalingSuggestionsUnavailable.linuxHost(
                    operation: "ItemContent.content(forType:)"
                )
            }
            return typed
        }
    }

    public struct StateOfMind: Sendable, JournalingSuggestionAsset {
        public typealias JournalingSuggestionContent = StateOfMind

        public var state: HKStateOfMind
        public var icon: URL?
        public var lightBackground: Gradient?
        public var darkBackground: Gradient?

        @_spi(OpenUIKitHost)
        public init(
            state: HKStateOfMind,
            icon: URL? = nil,
            lightBackground: Gradient? = nil,
            darkBackground: Gradient? = nil
        ) {
            self.state = state
            self.icon = icon
            self.lightBackground = lightBackground
            self.darkBackground = darkBackground
        }
    }

    public struct GenericMedia: Equatable, Hashable, Sendable, JournalingSuggestionAsset {
        public typealias JournalingSuggestionContent = GenericMedia

        public var title: String?
        public var artist: String?
        public var album: String?
        public var date: Date?
        public var appIcon: URL?

        @_spi(OpenUIKitHost)
        public init(
            title: String? = nil,
            artist: String? = nil,
            album: String? = nil,
            date: Date? = nil,
            appIcon: URL? = nil
        ) {
            self.title = title
            self.artist = artist
            self.album = album
            self.date = date
            self.appIcon = appIcon
        }
    }

    public struct WorkoutGroup: Sendable, JournalingSuggestionAsset {
        public typealias JournalingSuggestionContent = WorkoutGroup

        public var workouts: [Workout]
        public var duration: TimeInterval?
        public var icon: URL?
        public var averageHeartRate: HKQuantity?
        public var activeEnergyBurned: HKQuantity?

        @_spi(OpenUIKitHost)
        public init(
            workouts: [Workout],
            duration: TimeInterval? = nil,
            icon: URL? = nil,
            averageHeartRate: HKQuantity? = nil,
            activeEnergyBurned: HKQuantity? = nil
        ) {
            self.workouts = workouts
            self.duration = duration
            self.icon = icon
            self.averageHeartRate = averageHeartRate
            self.activeEnergyBurned = activeEnergyBurned
        }
    }

    public struct LocationGroup: Sendable, JournalingSuggestionAsset {
        public typealias JournalingSuggestionContent = LocationGroup

        public var locations: [Location]

        @_spi(OpenUIKitHost)
        public init(locations: [Location]) {
            self.locations = locations
        }
    }

    public struct MotionActivity: Equatable, Hashable, Sendable, JournalingSuggestionAsset {
        public typealias JournalingSuggestionContent = MotionActivity

        public struct MovementType: Equatable, Hashable, Codable, Sendable {
            public let rawValue: String

            private init(rawValue: String) {
                self.rawValue = rawValue
            }

            public static let runningWalking = MovementType(rawValue: "runningWalking")
            public static let running = MovementType(rawValue: "running")
            public static let walking = MovementType(rawValue: "walking")

            public static func == (a: MovementType, b: MovementType) -> Bool {
                a.rawValue == b.rawValue
            }

            public func hash(into hasher: inout Hasher) {
                hasher.combine(rawValue)
            }

            public init(from decoder: any Decoder) throws {
                let container = try decoder.singleValueContainer()
                let value = try container.decode(String.self)
                switch value {
                case MovementType.runningWalking.rawValue:
                    self = .runningWalking
                case MovementType.running.rawValue:
                    self = .running
                case MovementType.walking.rawValue:
                    self = .walking
                default:
                    throw DecodingError.dataCorruptedError(
                        in: container,
                        debugDescription: "unknown MovementType token \(value)"
                    )
                }
            }

            public func encode(to encoder: any Encoder) throws {
                var container = encoder.singleValueContainer()
                try container.encode(rawValue)
            }
        }

        public var movementType: MovementType?
        public var date: DateInterval?
        public var icon: URL?
        public var steps: Int

        @_spi(OpenUIKitHost)
        public init(
            movementType: MovementType? = nil,
            date: DateInterval? = nil,
            icon: URL? = nil,
            steps: Int = 0
        ) {
            self.movementType = movementType
            self.date = date
            self.icon = icon
            self.steps = steps
        }
    }

    public struct Song: Equatable, Hashable, Sendable, JournalingSuggestionAsset {
        public typealias JournalingSuggestionContent = Song

        public var song: String?
        public var artist: String?
        public var album: String?
        public var date: Date?
        public var artwork: URL?

        @_spi(OpenUIKitHost)
        public init(
            song: String? = nil,
            artist: String? = nil,
            album: String? = nil,
            date: Date? = nil,
            artwork: URL? = nil
        ) {
            self.song = song
            self.artist = artist
            self.album = album
            self.date = date
            self.artwork = artwork
        }
    }

    public struct Photo: Equatable, Hashable, Sendable, JournalingSuggestionAsset {
        public typealias JournalingSuggestionContent = Photo

        public var photo: URL
        public var date: Date?

        @_spi(OpenUIKitHost)
        public init(photo: URL, date: Date? = nil) {
            self.photo = photo
            self.date = date
        }
    }

    public struct Video: Equatable, Hashable, Sendable, JournalingSuggestionAsset {
        public typealias JournalingSuggestionContent = Video

        public var url: URL
        public var date: Date?

        @_spi(OpenUIKitHost)
        public init(url: URL, date: Date? = nil) {
            self.url = url
            self.date = date
        }
    }

    public struct Contact: Equatable, Hashable, Sendable, JournalingSuggestionAsset {
        public typealias JournalingSuggestionContent = Contact

        public var name: String
        public let photo: URL?

        @_spi(OpenUIKitHost)
        public init(name: String, photo: URL? = nil) {
            self.name = name
            self.photo = photo
        }
    }

    public struct Podcast: Equatable, Hashable, Sendable, JournalingSuggestionAsset {
        public typealias JournalingSuggestionContent = Podcast

        public var show: String?
        public var episode: String?
        public var date: Date?
        public var artwork: URL?

        @_spi(OpenUIKitHost)
        public init(
            show: String? = nil,
            episode: String? = nil,
            date: Date? = nil,
            artwork: URL? = nil
        ) {
            self.show = show
            self.episode = episode
            self.date = date
            self.artwork = artwork
        }
    }

    public struct Workout: Sendable, JournalingSuggestionAsset {
        public typealias JournalingSuggestionContent = Workout

        public struct Details: Sendable, JournalingSuggestionAsset {
            public typealias JournalingSuggestionContent = Details

            public var activityType: HKWorkoutActivityType
            public var localizedName: String?
            public var date: DateInterval?
            public var distance: HKQuantity?
            public var averageHeartRate: HKQuantity?
            public var activeEnergyBurned: HKQuantity?

            @_spi(OpenUIKitHost)
            public init(
                activityType: HKWorkoutActivityType,
                localizedName: String? = nil,
                date: DateInterval? = nil,
                distance: HKQuantity? = nil,
                averageHeartRate: HKQuantity? = nil,
                activeEnergyBurned: HKQuantity? = nil
            ) {
                self.activityType = activityType
                self.localizedName = localizedName
                self.date = date
                self.distance = distance
                self.averageHeartRate = averageHeartRate
                self.activeEnergyBurned = activeEnergyBurned
            }
        }

        public var icon: URL?
        public var route: [CLLocation]?
        public var details: Details?

        @_spi(OpenUIKitHost)
        public init(icon: URL? = nil, route: [CLLocation]? = nil, details: Details? = nil) {
            self.icon = icon
            self.route = route
            self.details = details
        }
    }

    public struct Location: Sendable, JournalingSuggestionAsset {
        public typealias JournalingSuggestionContent = Location

        public var place: String?
        public var city: String?
        public var date: Date?
        public var isWorkLocation: Bool?
        public var location: CLLocation?
        public var mapKitItemIdentifier: MKMapItem.Identifier?

        @_spi(OpenUIKitHost)
        public init(
            place: String? = nil,
            city: String? = nil,
            date: Date? = nil,
            isWorkLocation: Bool? = nil,
            location: CLLocation? = nil,
            mapKitItemIdentifier: MKMapItem.Identifier? = nil
        ) {
            self.place = place
            self.city = city
            self.date = date
            self.isWorkLocation = isWorkLocation
            self.location = location
            self.mapKitItemIdentifier = mapKitItemIdentifier
        }
    }

    public struct LivePhoto: Equatable, Hashable, Sendable, JournalingSuggestionAsset {
        public typealias JournalingSuggestionContent = LivePhoto

        public var image: URL
        public var video: URL
        public var date: Date?

        @_spi(OpenUIKitHost)
        public init(image: URL, video: URL, date: Date? = nil) {
            self.image = image
            self.video = video
            self.date = date
        }
    }
}

#if !canImport(SwiftUI)
extension Image: JournalingSuggestionAsset {
    public typealias JournalingSuggestionContent = Image
}
#endif
