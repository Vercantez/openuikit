@_exported import Foundation
#if canImport(Photos)
@_exported import Photos
#endif
#if canImport(UniformTypeIdentifiers)
@_exported import UniformTypeIdentifiers
#endif
#if canImport(UIKit)
import UIKit
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

public struct PHPickerCapabilities: OptionSet, Hashable, Sendable {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static var search: PHPickerCapabilities { PHPickerCapabilities(rawValue: 1 << 0) }
    public static var stagingArea: PHPickerCapabilities { PHPickerCapabilities(rawValue: 1 << 1) }
    public static var collectionNavigation: PHPickerCapabilities { PHPickerCapabilities(rawValue: 1 << 2) }
    public static var selectionActions: PHPickerCapabilities { PHPickerCapabilities(rawValue: 1 << 3) }
    public static var sensitivityAnalysisIntervention: PHPickerCapabilities {
        PHPickerCapabilities(rawValue: 1 << 4)
    }
}

#if !canImport(UIKit)
public struct NSDirectionalRectEdge: OptionSet, Hashable, Sendable {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let top = NSDirectionalRectEdge(rawValue: 1 << 0)
    public static let leading = NSDirectionalRectEdge(rawValue: 1 << 1)
    public static let bottom = NSDirectionalRectEdge(rawValue: 1 << 2)
    public static let trailing = NSDirectionalRectEdge(rawValue: 1 << 3)
    public static let all: NSDirectionalRectEdge = [.top, .leading, .bottom, .trailing]
}
#endif

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

    /// Composition is structural: order of `subfilters` is significant on
    /// Linux (`any(of: [.images, .videos]) != any(of: [.videos, .images])`).
    /// Apple's equality for composed filters is unobserved (oracle-questions.tsv).
    /// Catalog and combinators:
    /// https://developer.apple.com/documentation/photosui/phpickerfilter-swift.struct
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

    /// Evaluate this filter against portable Photos-lane asset attributes.
    /// Linux classifies the stored flags; it is not Apple's Photos-library
    /// media-subtype detector.
    @_spi(OpenUIKitHost)
    public func _matches(_ asset: PHPickerHostAsset) -> Bool {
        storage.matches(asset)
    }
}

/// Host-only Photos-lane asset record used by `PHPickerFilter._matches`
/// and `PHPickerViewController`'s library-driven presentation. Isolated
/// PhotosUI cannot import the Photos module.
public struct PHPickerHostAsset: Equatable, Hashable, Sendable {
    public enum MediaKind: Equatable, Hashable, Sendable {
        case image
        case video
        case unknown
    }

    public var identifier: String
    public var mediaKind: MediaKind
    public var playbackStyle: PHAsset.PlaybackStyle
    public var representsBurst: Bool
    public var isLivePhoto: Bool
    public var isScreenshot: Bool
    public var isPanorama: Bool
    public var isDepthEffect: Bool
    public var isSpatial: Bool
    public var isCinematic: Bool
    public var isSlomo: Bool
    public var isTimelapse: Bool
    public var isScreenRecording: Bool
    public var typeIdentifier: String
    public var payload: Data

    public init(
        identifier: String,
        mediaKind: MediaKind,
        typeIdentifier: String,
        payload: Data,
        playbackStyle: PHAsset.PlaybackStyle = .unsupported,
        representsBurst: Bool = false,
        isLivePhoto: Bool = false,
        isScreenshot: Bool = false,
        isPanorama: Bool = false,
        isDepthEffect: Bool = false,
        isSpatial: Bool = false,
        isCinematic: Bool = false,
        isSlomo: Bool = false,
        isTimelapse: Bool = false,
        isScreenRecording: Bool = false
    ) {
        self.identifier = identifier
        self.mediaKind = mediaKind
        self.playbackStyle = playbackStyle
        self.representsBurst = representsBurst
        self.isLivePhoto = isLivePhoto
        self.isScreenshot = isScreenshot
        self.isPanorama = isPanorama
        self.isDepthEffect = isDepthEffect
        self.isSpatial = isSpatial
        self.isCinematic = isCinematic
        self.isSlomo = isSlomo
        self.isTimelapse = isTimelapse
        self.isScreenRecording = isScreenRecording
        self.typeIdentifier = typeIdentifier
        self.payload = payload
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

    func matches(_ asset: PHPickerHostAsset) -> Bool {
        switch self {
        case .images:
            return asset.mediaKind == .image
        case .videos:
            return asset.mediaKind == .video
        case .livePhotos:
            return asset.isLivePhoto
        case .depthEffectPhotos:
            return asset.isDepthEffect
        case .screenshots:
            return asset.isScreenshot
        case .slomoVideos:
            return asset.isSlomo
        case .spatialMedia:
            return asset.isSpatial
        case .cinematicVideos:
            return asset.isCinematic
        case .timelapseVideos:
            return asset.isTimelapse
        case .screenRecordings:
            return asset.isScreenRecording
        case .bursts:
            return asset.representsBurst
        case .panoramas:
            return asset.isPanorama
        case .playbackStyle(let style):
            return asset.playbackStyle == style
        case .any(let filters):
            return filters.contains { $0.matches(asset) }
        case .all(let filters):
            return filters.allSatisfy { $0.matches(asset) }
        case .not(let filter):
            return !filter.matches(asset)
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
        // Portable default 1, matching Apple's documented PHPickerConfiguration
        // selectionLimit default (developer.apple.com/documentation/photosui/
        // phpickerconfiguration/selectionlimit). iOS 26.1 runtime was not
        // re-measured this round; see oracle-questions.tsv.
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
