@_exported import Foundation
@_exported import Photos
@_exported import UniformTypeIdentifiers

public struct PHPickerMode: Equatable, Hashable, Sendable {
    private let rawValue: UInt8

    private init(rawValue: UInt8) {
        self.rawValue = rawValue
    }

    public static let `default` = PHPickerMode(rawValue: 0)
    public static let compact = PHPickerMode(rawValue: 1)
}

public struct PHPickerFilter: Equatable, Hashable, Sendable {
    fileprivate indirect enum Storage: Equatable, Hashable, Sendable {
        case images
        case videos
        case livePhotos
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
        case .images:
            return contentTypes.contains { $0.conforms(to: .image) }
        case .videos:
            return contentTypes.contains {
                $0.conforms(to: .movie) || $0.conforms(to: .video)
            }
        case .livePhotos:
            return contentTypes.contains { $0.conforms(to: .image) }
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

    public var preferredAssetRepresentationMode: AssetRepresentationMode
    public var selection: Selection
    public var selectionLimit: Int
    public var filter: PHPickerFilter?
    public var preselectedAssetIdentifiers: [String]
    public var mode: PHPickerMode

    public init() {
        preferredAssetRepresentationMode = .automatic
        selection = .default
        selectionLimit = 1
        filter = nil
        preselectedAssetIdentifiers = []
        mode = .default
    }

    public init(photoLibrary: PHPhotoLibrary) {
        _ = photoLibrary
        self.init()
    }
}
