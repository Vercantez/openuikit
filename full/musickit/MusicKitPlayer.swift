import Foundation

open class MusicPlayer {
    public enum RepeatMode: Hashable, Sendable {
        case none
        case one
        case all
    }

    public enum ShuffleMode: Hashable, Sendable {
        case off
        case songs
    }

    public enum PlaybackStatus: Hashable, Sendable {
        case interrupted
        case seekingForward
        case seekingBackward
        case paused
        case playing
        case stopped
    }

    public enum Transition: Hashable, Sendable, CustomStringConvertible, CustomDebugStringConvertible {
        public struct CrossfadeOptions: Hashable, Sendable, CustomStringConvertible, CustomDebugStringConvertible {
            public var duration: TimeInterval?
            public init(duration: TimeInterval? = nil) { self.duration = duration }
            public var description: String {
                duration.map { "crossfade(\($0)s)" } ?? "crossfade"
            }
            public var debugDescription: String { description }
        }

        case none
        case crossfade(options: CrossfadeOptions)

        public static let crossfade = Transition.crossfade(options: CrossfadeOptions())

        public static func crossfade(duration: TimeInterval?) -> Transition {
            .crossfade(options: CrossfadeOptions(duration: duration))
        }

        public var description: String {
            switch self {
            case .none: return "none"
            case .crossfade(let options): return options.description
            }
        }

        public var debugDescription: String { description }
    }

    public final class State {
        public var repeatMode: RepeatMode?
        public var shuffleMode: ShuffleMode?
        public var audioVariant: AudioVariant?
        public var playbackRate: Float = 1
        public internal(set) var playbackStatus: PlaybackStatus = .stopped
        public var objectWillChange: AnyPublisher<Void, Never> = AnyPublisher()
        public typealias ObjectWillChangePublisher = AnyPublisher<Void, Never>
    }

    public class Queue: Hashable, ExpressibleByArrayLiteral {
        public typealias ArrayLiteralElement = any PlayableMusicItem
        public typealias ObjectWillChangePublisher = AnyPublisher<Void, Never>

        public enum EntryInsertionPosition: Hashable, Sendable {
            case afterCurrentEntry
            case tail
        }

        public struct Entry: Hashable, Sendable, Identifiable, CustomStringConvertible {
            public typealias ID = String
            public let id: String
            public var isTransient: Bool
            public var transientItem: (any PlayableMusicItem)?
            public var item: Item?
            public var title: String
            public var artwork: Artwork?
            public var endTime: TimeInterval?
            public var subtitle: String?
            public var startTime: TimeInterval?

            public enum Item: MusicItem, PlayableMusicItem, Hashable, Sendable, Codable,
                CustomStringConvertible, CustomDebugStringConvertible
            {
                case musicVideo(MusicVideo)
                case song(Song)

                public typealias ID = MusicItemID
                public var id: MusicItemID {
                    switch self {
                    case .musicVideo(let item): return item.id
                    case .song(let item): return item.id
                    }
                }
                public var playParameters: PlayParameters? {
                    switch self {
                    case .musicVideo(let item): return item.playParameters
                    case .song(let item): return item.playParameters
                    }
                }
                public var description: String {
                    switch self {
                    case .musicVideo(let item): return item.title
                    case .song(let item): return item.title
                    }
                }
                public var debugDescription: String { description }
            }

            public init(
                _ playableMusicItem: any PlayableMusicItem,
                startTime: TimeInterval? = nil,
                endTime: TimeInterval? = nil
            ) {
                self.id = playableMusicItem.id.rawValue
                self.isTransient = true
                self.transientItem = playableMusicItem
                if let song = playableMusicItem as? Song {
                    self.item = .song(song)
                    self.title = song.title
                    self.subtitle = song.artistName
                    self.artwork = song.artwork
                } else if let video = playableMusicItem as? MusicVideo {
                    self.item = .musicVideo(video)
                    self.title = video.title
                    self.subtitle = video.artistName
                    self.artwork = video.artwork
                } else {
                    self.item = nil
                    self.title = playableMusicItem.id.rawValue
                }
                self.startTime = startTime
                self.endTime = endTime
            }

            public var description: String { title }

            public static func == (a: Entry, b: Entry) -> Bool { a.id == b.id }
            public func hash(into hasher: inout Hasher) { hasher.combine(id) }
        }

        var entriesStorage: [Entry]
        public var currentEntry: Entry?
        public var objectWillChange: AnyPublisher<Void, Never> = AnyPublisher()

        public required init(arrayLiteral elements: any PlayableMusicItem...) {
            entriesStorage = elements.map { Entry($0) }
            currentEntry = entriesStorage.first
        }

        public required init<S, PlayableMusicItemType>(
            for playableItems: S,
            startingAt startPlayableItem: S.Element? = nil
        ) where S: Sequence, PlayableMusicItemType: PlayableMusicItem, S.Element == PlayableMusicItemType {
            entriesStorage = playableItems.map { Entry($0) }
            if let startPlayableItem {
                currentEntry = entriesStorage.first { $0.id == startPlayableItem.id.rawValue }
                    ?? entriesStorage.first
            } else {
                currentEntry = entriesStorage.first
            }
        }

        public required init(album: Album, startingAt startTrack: Track) {
            if let tracks = album.tracks {
                entriesStorage = tracks.compactMap { track -> Entry? in
                    switch track {
                    case .song(let song): return Entry(song)
                    case .musicVideo(let video): return Entry(video)
                    }
                }
            } else {
                entriesStorage = []
            }
            currentEntry = entriesStorage.first { $0.id == startTrack.id.rawValue } ?? entriesStorage.first
        }

        public required init(playlist: Playlist, startingAt startPlaylistEntry: Playlist.Entry) {
            if let entries = playlist.entries {
                entriesStorage = entries.map { entry in
                    if let song = unwrapSong(entry.item) {
                        return Entry(song, startTime: nil, endTime: entry.duration)
                    }
                    return Entry(
                        Song(id: entry.id, title: entry.title, artistName: entry.artistName),
                        startTime: nil,
                        endTime: entry.duration
                    )
                }
            } else {
                entriesStorage = []
            }
            currentEntry = entriesStorage.first { $0.id == startPlaylistEntry.id.rawValue }
                ?? entriesStorage.first
        }

        public required init<S>(_ entries: S, startingAt startEntry: S.Element? = nil)
            where S: Sequence, S.Element == Entry
        {
            entriesStorage = Array(entries)
            if let startEntry {
                currentEntry = entriesStorage.first { $0.id == startEntry.id } ?? entriesStorage.first
            } else {
                currentEntry = entriesStorage.first
            }
        }

        public func insert(_ entry: Entry, position: EntryInsertionPosition) async throws {
            insertSync(entry, position: position)
        }

        public func insert<PlayableMusicItemType: PlayableMusicItem>(
            _ playableItem: PlayableMusicItemType,
            position: EntryInsertionPosition
        ) async throws {
            insertSync(Entry(playableItem), position: position)
        }

        public func insert<S, PlayableMusicItemType>(
            _ playableItems: S,
            position: EntryInsertionPosition
        ) async throws
            where S: Sequence, PlayableMusicItemType: PlayableMusicItem, S.Element == PlayableMusicItemType
        {
            for item in playableItems {
                insertSync(Entry(item), position: position)
            }
        }

        public func insert<S>(_ entries: S, position: EntryInsertionPosition) async throws
            where S: Sequence, S.Element == Entry
        {
            for entry in entries {
                insertSync(entry, position: position)
            }
        }

        func insertSync(_ entry: Entry, position: EntryInsertionPosition) {
            switch position {
            case .tail:
                entriesStorage.append(entry)
            case .afterCurrentEntry:
                if let current = currentEntry,
                   let index = entriesStorage.firstIndex(where: { $0.id == current.id })
                {
                    entriesStorage.insert(entry, at: index + 1)
                } else {
                    entriesStorage.append(entry)
                }
            }
            if currentEntry == nil {
                currentEntry = entry
            }
        }

        public static func == (left: Queue, right: Queue) -> Bool {
            left.entriesStorage.map(\.id) == right.entriesStorage.map(\.id)
                && left.currentEntry?.id == right.currentEntry?.id
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(entriesStorage.map(\.id))
            hasher.combine(currentEntry?.id)
        }
    }

    public var playbackTime: TimeInterval = 0
    public private(set) var isPreparedToPlay = false
    public let state = State()

    public init() {}

    public func endSeeking() {
        if state.playbackStatus == .seekingForward || state.playbackStatus == .seekingBackward {
            state.playbackStatus = .paused
        }
    }

    public func beginSeekingForward() {
        state.playbackStatus = .seekingForward
    }

    public func beginSeekingBackward() {
        state.playbackStatus = .seekingBackward
    }

    public func restartCurrentEntry() {
        playbackTime = 0
    }

    public func pause() {
        if state.playbackStatus == .playing || state.playbackStatus == .seekingForward
            || state.playbackStatus == .seekingBackward
        {
            state.playbackStatus = .paused
        }
    }

    public func stop() {
        state.playbackStatus = .stopped
        playbackTime = 0
        isPreparedToPlay = false
    }

    public func prepareToPlay() async throws {
        throw MusicKitPortableError.playbackUnavailable
    }

    public func skipToNextEntry() async throws {
        throw MusicKitPortableError.playbackUnavailable
    }

    public func skipToPreviousEntry() async throws {
        throw MusicKitPortableError.playbackUnavailable
    }

    public func play() async throws {
        throw MusicKitPortableError.playbackUnavailable
    }
}

private func unwrapSong(_ item: Playlist.Entry.Item?) -> Song? {
    guard case .song(let song) = item else { return nil }
    return song
}

public final class ApplicationMusicPlayer: MusicPlayer {
    public static let shared = ApplicationMusicPlayer()

    public var transition: Transition = .none
    public var queue: Queue = Queue([] as [MusicPlayer.Queue.Entry])

    public final class Queue: MusicPlayer.Queue {
        public struct Entries: RandomAccessCollection, RangeReplaceableCollection, Hashable,
            ExpressibleByArrayLiteral
        {
            public typealias Index = Int
            public typealias Element = MusicPlayer.Queue.Entry
            public typealias SubSequence = Array<MusicPlayer.Queue.Entry>.SubSequence
            public typealias ArrayLiteralElement = MusicPlayer.Queue.Entry
            public typealias Indices = Range<Int>
            public typealias Iterator = Array<MusicPlayer.Queue.Entry>.Iterator

            var values: [MusicPlayer.Queue.Entry]

            public init() { values = [] }
            public init(arrayLiteral elements: MusicPlayer.Queue.Entry...) { values = elements }
            public init<S>(_ elements: S) where S: Sequence, S.Element == MusicPlayer.Queue.Entry {
                values = Array(elements)
            }

            public var startIndex: Int { values.startIndex }
            public var endIndex: Int { values.endIndex }
            public var indices: Range<Int> { values.indices }
            public subscript(position: Int) -> MusicPlayer.Queue.Entry {
                get { values[position] }
                set { values[position] = newValue }
            }
            public subscript(bounds: Range<Int>) -> Array<MusicPlayer.Queue.Entry>.SubSequence {
                get { values[bounds] }
                set { values.replaceSubrange(bounds, with: newValue) }
            }
            public func index(after i: Int) -> Int { values.index(after: i) }
            public func index(before i: Int) -> Int { values.index(before: i) }
            public func index(_ i: Int, offsetBy distance: Int) -> Int {
                values.index(i, offsetBy: distance)
            }
            public func index(_ i: Int, offsetBy distance: Int, limitedBy limit: Int) -> Int? {
                values.index(i, offsetBy: distance, limitedBy: limit)
            }
            public func distance(from start: Int, to end: Int) -> Int {
                values.distance(from: start, to: end)
            }
            public func formIndex(after i: inout Int) { values.formIndex(after: &i) }
            public func formIndex(before i: inout Int) { values.formIndex(before: &i) }
            public func makeIterator() -> Array<MusicPlayer.Queue.Entry>.Iterator {
                values.makeIterator()
            }
            public mutating func replaceSubrange<C>(_ subrange: Range<Int>, with newElements: C)
                where C: Collection, C.Element == MusicPlayer.Queue.Entry
            {
                values.replaceSubrange(subrange, with: newElements)
            }
        }

        public var entries: Entries {
            get { Entries(entriesStorage) }
            set {
                entriesStorage = Array(newValue)
                if currentEntry == nil {
                    currentEntry = entriesStorage.first
                }
            }
        }

        public required init(arrayLiteral elements: any PlayableMusicItem...) {
            super.init(for: elements.map { AnyPlayable($0) }, startingAt: nil)
        }

        public required init<S, PlayableMusicItemType>(
            for playableItems: S,
            startingAt startPlayableItem: S.Element? = nil
        ) where S: Sequence, PlayableMusicItemType: PlayableMusicItem, S.Element == PlayableMusicItemType {
            super.init(for: playableItems, startingAt: startPlayableItem)
        }

        public required init(album: Album, startingAt startTrack: Track) {
            super.init(album: album, startingAt: startTrack)
        }

        public required init(playlist: Playlist, startingAt startPlaylistEntry: Playlist.Entry) {
            super.init(playlist: playlist, startingAt: startPlaylistEntry)
        }

        public required init<S>(_ entries: S, startingAt startEntry: S.Element? = nil)
            where S: Sequence, S.Element == MusicPlayer.Queue.Entry
        {
            super.init(entries, startingAt: startEntry)
        }
    }
}

private struct AnyPlayable: PlayableMusicItem {
    let id: MusicItemID
    let playParameters: PlayParameters?
    init(_ item: any PlayableMusicItem) {
        id = item.id
        playParameters = item.playParameters
    }
}

public final class SystemMusicPlayer: MusicPlayer {
    public static let shared = SystemMusicPlayer()
    public var queue: MusicPlayer.Queue = MusicPlayer.Queue([] as [MusicPlayer.Queue.Entry])
}
