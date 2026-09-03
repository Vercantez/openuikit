@_exported import Foundation
#if canImport(Photos)
@_exported import Photos
#endif
#if canImport(UniformTypeIdentifiers)
@_exported import UniformTypeIdentifiers
#endif

public struct PHPickerMode: Equatable, Hashable, Sendable {
    private let rawValue: UInt8

    private init(rawValue: UInt8) {
        self.rawValue = rawValue
    }

    public static let `default` = PHPickerMode(rawValue: 0)
    public static var compact: PHPickerMode { PHPickerMode(rawValue: 1) }
}

public enum PHPickerConfigurationAssetRepresentationMode: Int, Hashable, Sendable {
    case automatic = 0
    case current = 1
    case compatible = 2
}

public enum PHPickerConfigurationSelection: Int, Hashable, Sendable {
    case `default` = 0
    case ordered = 1
    case continuous = 2
    case continuousAndOrdered = 3
}

public struct PHPickerFilter: Equatable, Hashable, Sendable {
    fileprivate indirect enum Storage: Equatable, Hashable, Sendable {
        case images
        case videos
        case livePhotos
        case depthEffectPhotos
        case screenshots
        case slomoVideos
        case spatialMedia
        case cinematicVideos
        case timelapseVideos
        case screenRecordings
        case bursts
        case panoramas
        case playbackStyle(PHAsset.PlaybackStyle)
        case any([Storage])
        case all([Storage])
        case not(Storage)
    }

    private let storage: Storage

    private init(_ storage: Storage) {
        self.storage = storage
    }

    public static let images = PHPickerFilter(.images)
    public static let videos = PHPickerFilter(.videos)
    public static let livePhotos = PHPickerFilter(.livePhotos)
    public static let depthEffectPhotos = PHPickerFilter(.depthEffectPhotos)
    public static let screenshots = PHPickerFilter(.screenshots)
    public static let slomoVideos = PHPickerFilter(.slomoVideos)
    public static let spatialMedia = PHPickerFilter(.spatialMedia)
    public static let cinematicVideos = PHPickerFilter(.cinematicVideos)
    public static let timelapseVideos = PHPickerFilter(.timelapseVideos)
    public static let screenRecordings = PHPickerFilter(.screenRecordings)
    public static let bursts = PHPickerFilter(.bursts)
    public static let panoramas = PHPickerFilter(.panoramas)

    public static func playbackStyle(_ playbackStyle: PHAsset.PlaybackStyle) -> PHPickerFilter {
        PHPickerFilter(.playbackStyle(playbackStyle))
    }

    public static func any(of subfilters: [PHPickerFilter]) -> PHPickerFilter {
        PHPickerFilter(.any(subfilters.map(\.storage)))
    }

    public static func all(of subfilters: [PHPickerFilter]) -> PHPickerFilter {
        PHPickerFilter(.all(subfilters.map(\.storage)))
    }

    public static func not(_ filter: PHPickerFilter) -> PHPickerFilter {
        PHPickerFilter(.not(filter.storage))
    }

    @_spi(OpenUIKitHost)
    public func _matches(_ contentTypes: [UTType]) -> Bool {
        storage.matches(contentTypes)
    }
}

private extension PHPickerFilter.Storage {
    func matches(_ contentTypes: [UTType]) -> Bool {
        switch self {
        case .images, .livePhotos, .depthEffectPhotos, .screenshots, .bursts, .panoramas, .spatialMedia:
            return contentTypes.contains { $0.conforms(to: .image) }
        case .videos, .slomoVideos, .cinematicVideos, .timelapseVideos, .screenRecordings:
            return contentTypes.contains {
                $0.conforms(to: .movie) || $0.conforms(to: .video)
            }
        case .playbackStyle(let style):
            switch style {
            case .image, .imageAnimated, .livePhoto:
                return contentTypes.contains { $0.conforms(to: .image) }
            case .video, .videoLooping:
                return contentTypes.contains {
                    $0.conforms(to: .movie) || $0.conforms(to: .video)
                }
            case .unsupported:
                return false
            }
        case .any(let filters):
            return filters.contains { $0.matches(contentTypes) }
        case .all(let filters):
            return filters.allSatisfy { $0.matches(contentTypes) }
        case .not(let filter):
            return !filter.matches(contentTypes)
        }
    }
}

public struct PHPickerConfiguration: Equatable, Hashable, Sendable {
    public enum AssetRepresentationMode: Equatable, Hashable, Sendable {
        case automatic
        case current
        case compatible
    }

    public enum Selection: Equatable, Hashable, Sendable {
        case `default`
        case ordered
        case continuous
        case continuousAndOrdered
    }

    public struct Update: Equatable, Hashable, Sendable {
        public var selectionLimit: Int?
        public var edgesWithoutContentMargins: NSDirectionalRectEdge?

        public init() {
            selectionLimit = nil
            edgesWithoutContentMargins = nil
        }
    }

    public var preferredAssetRepresentationMode: AssetRepresentationMode
    public var selection: Selection
    public var selectionLimit: Int
    public var filter: PHPickerFilter?
    public var preselectedAssetIdentifiers: [String]
    public var mode: PHPickerMode
    public var disabledCapabilities: PHPickerCapabilities
    public var edgesWithoutContentMargins: NSDirectionalRectEdge

    public init() {
        preferredAssetRepresentationMode = .automatic
        selection = .default
        selectionLimit = 1
        filter = nil
        preselectedAssetIdentifiers = []
        mode = .default
        disabledCapabilities = []
        edgesWithoutContentMargins = []
    }

    public init(photoLibrary: PHPhotoLibrary) {
        self.init()
        _ = photoLibrary
    }
}
