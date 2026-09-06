import Foundation

public enum PHAccessLevel: Int, Sendable {
    case addOnly = 1
    case readWrite = 2
}

public struct PHAssetBurstSelectionType: OptionSet, Sendable {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let autoPick = PHAssetBurstSelectionType(rawValue: 1 << 0)
    public static let userPick = PHAssetBurstSelectionType(rawValue: 1 << 1)
}

public enum PHAssetCollectionSubtype: Int, Sendable {
    case albumRegular = 2
    case albumSyncedEvent = 3
    case albumSyncedFaces = 4
    case albumSyncedAlbum = 5
    case albumImported = 6
    case albumMyPhotoStream = 100
    case albumCloudShared = 101
    case smartAlbumGeneric = 200
    case smartAlbumPanoramas = 201
    case smartAlbumVideos = 202
    case smartAlbumFavorites = 203
    case smartAlbumTimelapses = 204
    case smartAlbumAllHidden = 205
    case smartAlbumRecentlyAdded = 206
    case smartAlbumBursts = 207
    case smartAlbumSlomoVideos = 208
    case smartAlbumUserLibrary = 209
    case smartAlbumSelfPortraits = 210
    case smartAlbumScreenshots = 211
    case smartAlbumDepthEffect = 212
    case smartAlbumLivePhotos = 213
    case smartAlbumAnimated = 214
    case smartAlbumLongExposures = 215
    case smartAlbumUnableToUpload = 216
    case smartAlbumRAW = 217
    case smartAlbumCinematic = 218
    case smartAlbumSpatial = 219
    case smartAlbumScreenRecordings = 220
    case any = 9223372036854775807
}

public enum PHAssetCollectionType: Int, Sendable {
    case album = 1
    case smartAlbum = 2
    case moment = 3
}

public enum PHAssetEditOperation: Int, Sendable {
    case delete = 1
    case content = 2
    case properties = 3
}

public struct PHAssetMediaSubtype: OptionSet, Sendable {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let photoPanorama = PHAssetMediaSubtype(rawValue: 1 << 0)
    public static let photoHDR = PHAssetMediaSubtype(rawValue: 1 << 1)
    public static let photoScreenshot = PHAssetMediaSubtype(rawValue: 1 << 2)
    public static let photoLive = PHAssetMediaSubtype(rawValue: 1 << 3)
    public static let photoDepthEffect = PHAssetMediaSubtype(rawValue: 1 << 4)
    public static let spatialMedia = PHAssetMediaSubtype(rawValue: 1 << 10)
    public static let videoStreamed = PHAssetMediaSubtype(rawValue: 1 << 16)
    public static let videoHighFrameRate = PHAssetMediaSubtype(rawValue: 1 << 17)
    public static let videoTimelapse = PHAssetMediaSubtype(rawValue: 1 << 18)
    public static let videoScreenRecording = PHAssetMediaSubtype(rawValue: 1 << 19)
    public static let videoCinematic = PHAssetMediaSubtype(rawValue: 1 << 21)
}

public enum PHAssetMediaType: Int, Sendable {
    case unknown = 0
    case image = 1
    case video = 2
    case audio = 3
}

public enum PHAssetResourceType: Int, Sendable {
    case photo = 1
    case video = 2
    case audio = 3
    case alternatePhoto = 4
    case fullSizePhoto = 5
    case fullSizeVideo = 6
    case adjustmentData = 7
    case adjustmentBasePhoto = 8
    case pairedVideo = 9
    case fullSizePairedVideo = 10
    case adjustmentBasePairedVideo = 11
    case adjustmentBaseVideo = 12
    case photoProxy = 19
}

public struct PHAssetSourceType: OptionSet, Sendable {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let typeUserLibrary = PHAssetSourceType(rawValue: 1 << 0)
    public static let typeCloudShared = PHAssetSourceType(rawValue: 1 << 1)
    public static let typeiTunesSynced = PHAssetSourceType(rawValue: 1 << 2)
}

public enum PHAuthorizationStatus: Int, Sendable {
    case notDetermined = 0
    case restricted = 1
    case denied = 2
    case authorized = 3
    case limited = 4
}

public enum PHCollectionEditOperation: Int, Sendable {
    case deleteContent = 1
    case removeContent = 2
    case addContent = 3
    case createContent = 4
    case rearrangeContent = 5
    case delete = 6
    case rename = 7
}

public enum PHCollectionListSubtype: Int, Sendable {
    case momentListCluster = 1
    case momentListYear = 2
    case regularFolder = 100
    case smartFolderEvents = 200
    case smartFolderFaces = 201
    case any = 9223372036854775807
}

public enum PHCollectionListType: Int, Sendable {
    case momentList = 1
    case folder = 2
    case smartFolder = 3
}

public enum PHImageContentMode: Int, Sendable {
    case aspectFit = 0
    case aspectFill = 1

    public static var `default`: PHImageContentMode { .aspectFit }
}

public enum PHImageRequestOptionsDeliveryMode: Int, Sendable {
    case opportunistic = 0
    case highQualityFormat = 1
    case fastFormat = 2
}

public enum PHImageRequestOptionsResizeMode: Int, Sendable {
    case none = 0
    case fast = 1
    case exact = 2
}

public enum PHImageRequestOptionsVersion: Int, Sendable {
    case current = 0
    case unadjusted = 1
    case original = 2
}

public enum PHLivePhotoFrameType: Int, Sendable {
    case photo = 0
    case video = 1
}

public enum PHObjectType: Int, Sendable {
    case asset = 1
    case assetCollection = 2
    case collectionList = 3
}

public enum PHVideoRequestOptionsDeliveryMode: Int, Sendable {
    case automatic = 0
    case highQualityFormat = 1
    case mediumQualityFormat = 2
    case fastFormat = 3
}

public enum PHVideoRequestOptionsVersion: Int, Sendable {
    case current = 0
    case original = 1
}

public enum PHBackgroundResourceUploadProcessingResult: Int, Sendable {
    case failure = 0
    case processing = 1
    case completed = 2
}

public struct PHLivePhotoEditingOption: RawRepresentable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let shouldRenderAtPlaybackTime = PHLivePhotoEditingOption(
        rawValue: "PHLivePhotoShouldRenderAtPlaybackTime"
    )
}

public struct PHPhotosError: Error, Hashable {
    public enum Code: Int, Error, Hashable, Sendable {
        case internalError = -1
        case userCancelled = 3072
        case persistentChangeTokenExpired = 3105
        case libraryVolumeOffline = 3114
        case relinquishingLibraryBundleToWriter = 3142
        case switchingSystemPhotoLibrary = 3143
        case networkAccessRequired = 3164
        case networkError = 3169
        case identifierNotFound = 3201
        case multipleIdentifiersFound = 3202
        case persistentChangeDetailsUnavailable = 3210
        case changeNotSupported = 3300
        case operationInterrupted = 3301
        case invalidResource = 3302
        case missingResource = 3303
        case notEnoughSpace = 3305
        case requestNotSupportedForAsset = 3306
        case limitExceeded = 3307
        case accessRestricted = 3310
        case accessUserDenied = 3311
        case libraryInFileProviderSyncRoot = 5423

        // Photos invalid-error probe, iPhone 17 / iOS 26.1 (23B86):
        // Code.invalid.rawValue == -1 and Code.invalid == .internalError.
        // This is an alias, not another raw-value case. SDK diagnostics give
        // the iOS 15 / macOS 12 deprecation and replacement spelling.
        @available(iOS, deprecated: 15.0, renamed: "PHPhotosError.internalError")
        @available(macOS, deprecated: 12.0, renamed: "PHPhotosError.internalError")
        public static var invalid: Self { .internalError }
    }

    public var code: Code
    public var userInfo: [String: Any]

    public init(_ code: Code, userInfo: [String: Any] = [:]) {
        self.code = code
        self.userInfo = userInfo
    }

    public var errorCode: Int { code.rawValue }
    public var errorUserInfo: [String: Any] { userInfo }
    public var hashValue: Int { code.rawValue }
    public var localizedDescription: String {
        "\(PHPhotosErrorDomain)(\(code.rawValue))"
    }

    public static var errorDomain: String { PHPhotosErrorDomain }
    public static var internalError: Code { .internalError }
    // The same iOS 26.1 probe measures PHPhotosError.invalid.rawValue == -1.
    @available(iOS, deprecated: 15.0, renamed: "PHPhotosError.internalError")
    @available(macOS, deprecated: 12.0, renamed: "PHPhotosError.internalError")
    public static var invalid: Code { .internalError }
    public static var userCancelled: Code { .userCancelled }
    public static var persistentChangeTokenExpired: Code { .persistentChangeTokenExpired }
    public static var libraryVolumeOffline: Code { .libraryVolumeOffline }
    public static var relinquishingLibraryBundleToWriter: Code { .relinquishingLibraryBundleToWriter }
    public static var switchingSystemPhotoLibrary: Code { .switchingSystemPhotoLibrary }
    public static var networkAccessRequired: Code { .networkAccessRequired }
    public static var networkError: Code { .networkError }
    public static var identifierNotFound: Code { .identifierNotFound }
    public static var multipleIdentifiersFound: Code { .multipleIdentifiersFound }
    public static var persistentChangeDetailsUnavailable: Code {
        .persistentChangeDetailsUnavailable
    }
    public static var changeNotSupported: Code { .changeNotSupported }
    public static var operationInterrupted: Code { .operationInterrupted }
    public static var invalidResource: Code { .invalidResource }
    public static var missingResource: Code { .missingResource }
    public static var notEnoughSpace: Code { .notEnoughSpace }
    public static var requestNotSupportedForAsset: Code { .requestNotSupportedForAsset }
    public static var limitExceeded: Code { .limitExceeded }
    public static var accessRestricted: Code { .accessRestricted }
    public static var accessUserDenied: Code { .accessUserDenied }
    public static var libraryInFileProviderSyncRoot: Code { .libraryInFileProviderSyncRoot }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(code)
    }

    public static func == (lhs: PHPhotosError, rhs: PHPhotosError) -> Bool {
        lhs.code == rhs.code
    }

}

extension PHPhotosError.Code {
    public var hashValue: Int { rawValue }

    public static func ~= (match: Self, error: any Error) -> Bool {
        (error as? PHPhotosError)?.code == match
            || (error as? Self) == match
            || ((error as NSError).domain == PHPhotosErrorDomain
                && (error as NSError).code == match.rawValue)
    }
}
