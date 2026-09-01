@_exported import Foundation
@_exported import ImageIO

#if canImport(UIKit)
@_exported import UIKit
#elseif canImport(AppKit)
@_exported import AppKit
public typealias UIImage = NSImage
#endif

public enum PHAuthorizationStatus: Int, Sendable {
    case notDetermined = 0
    case restricted = 1
    case denied = 2
    case authorized = 3
    case limited = 4
}

public enum PHAccessLevel: Int, Sendable {
    case addOnly = 1
    case readWrite = 2
}

public enum PHAssetMediaType: Int, Sendable {
    case unknown = 0
    case image = 1
    case video = 2
    case audio = 3
}

public enum PHImageContentMode: Int, Sendable {
    case aspectFit = 0
    case aspectFill = 1
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

public typealias PHImageRequestID = Int32

public final class PHImageRequestOptions: @unchecked Sendable {
    public var isNetworkAccessAllowed = false
    public var deliveryMode = PHImageRequestOptionsDeliveryMode.opportunistic
    public var resizeMode = PHImageRequestOptionsResizeMode.fast
    public var isSynchronous = false

    public init() {}
}

public final class PHFetchOptions: @unchecked Sendable {
    public var sortDescriptors: [NSSortDescriptor]?
    public var fetchLimit = 0

    public init() {}
}

public final class PHAsset: @unchecked Sendable {
    public let localIdentifier: String
    public let mediaType: PHAssetMediaType
    public let creationDate: Date?

    let portableData: Data?
    let portableImage: UIImage?

    @_spi(OpenUIKitHost)
    public init(
        localIdentifier: String,
        mediaType: PHAssetMediaType,
        creationDate: Date? = nil,
        data: Data? = nil,
        image: UIImage? = nil
    ) {
        self.localIdentifier = localIdentifier
        self.mediaType = mediaType
        self.creationDate = creationDate
        portableData = data
        portableImage = image
    }

    public static func fetchAssets(
        with mediaType: PHAssetMediaType,
        options: PHFetchOptions?
    ) -> PHFetchResult<PHAsset> {
        guard PHPhotoLibrary.authorizationStatus(for: .readWrite) == .authorized
            || PHPhotoLibrary.authorizationStatus(for: .readWrite) == .limited
        else {
            return PHFetchResult([])
        }
        var assets = PHPhotoLibraryPortable.assets().filter {
            $0.mediaType == mediaType
        }
        if let descriptor = options?.sortDescriptors?.first,
            descriptor.key == "creationDate"
        {
            assets.sort {
                let left = $0.creationDate ?? .distantPast
                let right = $1.creationDate ?? .distantPast
                return descriptor.ascending ? left < right : left > right
            }
        }
        if let limit = options?.fetchLimit, limit > 0, assets.count > limit {
            assets.removeLast(assets.count - limit)
        }
        return PHFetchResult(assets)
    }
}

public final class PHFetchResult<Object>: @unchecked Sendable {
    private let objects: [Object]

    init(_ objects: [Object]) {
        self.objects = objects
    }

    public var count: Int { objects.count }

    public subscript(index: Int) -> Object {
        objects[index]
    }

    public func enumerateObjects(
        _ block: (Object, Int, UnsafeMutablePointer<ObjCBool>) -> Void
    ) {
        var stop = ObjCBool(false)
        withUnsafeMutablePointer(to: &stop) { pointer in
            for (index, object) in objects.enumerated() {
                block(object, index, pointer)
                if pointer.pointee.boolValue { break }
            }
        }
    }
}

public enum PHPhotoLibraryPortable {
    public typealias AuthorizationHandler =
        @Sendable (PHAccessLevel) async -> PHAuthorizationStatus

    private static let lock = NSLock()
    nonisolated(unsafe) private static var statuses: [PHAccessLevel:
        PHAuthorizationStatus] = [:]
    nonisolated(unsafe) private static var authorizationHandler:
        AuthorizationHandler?
    nonisolated(unsafe) private static var storedAssets: [PHAsset] = []

    static func status(for level: PHAccessLevel) -> PHAuthorizationStatus {
        lock.withLock { statuses[level] ?? .notDetermined }
    }

    static func store(
        _ status: PHAuthorizationStatus,
        for level: PHAccessLevel
    ) {
        lock.withLock { statuses[level] = status }
    }

    static func handler() -> AuthorizationHandler? {
        lock.withLock { authorizationHandler }
    }

    static func assets() -> [PHAsset] {
        lock.withLock { storedAssets }
    }

    @_spi(OpenUIKitHost)
    public static func _installAuthorizationHandler(
        _ handler: AuthorizationHandler?
    ) {
        lock.withLock { authorizationHandler = handler }
    }

    @_spi(OpenUIKitHost)
    public static func _installAssets(_ assets: [PHAsset]) {
        lock.withLock { storedAssets = assets }
    }

    @_spi(OpenUIKitHost)
    public static func _reset() {
        lock.withLock {
            statuses = [:]
            authorizationHandler = nil
            storedAssets = []
        }
    }
}

public final class PHPhotoLibrary: @unchecked Sendable {
    private static let sharedLibrary = PHPhotoLibrary()

    private init() {}

    public static func shared() -> PHPhotoLibrary {
        sharedLibrary
    }

    public static func authorizationStatus(
        for accessLevel: PHAccessLevel
    ) -> PHAuthorizationStatus {
        PHPhotoLibraryPortable.status(for: accessLevel)
    }

    public static func requestAuthorization(
        for accessLevel: PHAccessLevel
    ) async -> PHAuthorizationStatus {
        let status = await PHPhotoLibraryPortable.handler()?(accessLevel)
            ?? .denied
        PHPhotoLibraryPortable.store(status, for: accessLevel)
        return status
    }
}

public final class PHImageManager: @unchecked Sendable {
    private static let sharedManager = PHImageManager()
    private let lock = NSLock()
    private var nextRequestID: PHImageRequestID = 1

    private init() {}

    public static func `default`() -> PHImageManager {
        sharedManager
    }

    @discardableResult
    public func requestImageDataAndOrientation(
        for asset: PHAsset,
        options: PHImageRequestOptions?,
        resultHandler: (
            Data?, String?, CGImagePropertyOrientation,
            [AnyHashable: Any]?
        ) -> Void
    ) -> PHImageRequestID {
        let requestID = claimRequestID()
        resultHandler(asset.portableData, nil, .up, nil)
        return requestID
    }

    @discardableResult
    public func requestImage(
        for asset: PHAsset,
        targetSize: CGSize,
        contentMode: PHImageContentMode,
        options: PHImageRequestOptions?,
        resultHandler: (UIImage?, [AnyHashable: Any]?) -> Void
    ) -> PHImageRequestID {
        let requestID = claimRequestID()
        resultHandler(asset.portableImage, nil)
        return requestID
    }

    private func claimRequestID() -> PHImageRequestID {
        lock.withLock {
            defer { nextRequestID &+= 1 }
            return nextRequestID
        }
    }
}
