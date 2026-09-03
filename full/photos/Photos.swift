@_exported import Foundation

#if canImport(ImageIO)
@_exported import ImageIO
#endif

#if canImport(UIKit)
@_exported import UIKit
#elseif canImport(AppKit)
@_exported import AppKit
public typealias UIImage = NSImage
#endif

#if !canImport(UIKit) && !canImport(AppKit)
/// Linux host lookalike for the isolated gate. Not UIKit identity.
public final class UIImage: NSObject, @unchecked Sendable {
    public override init() {
        super.init()
    }
}
#endif

#if !canImport(ImageIO)
/// Linux host lookalike for ImageIO's orientation. Not ImageIO identity.
public enum CGImagePropertyOrientation: UInt32, Sendable {
    case up = 1
    case upMirrored = 2
    case down = 3
    case downMirrored = 4
    case leftMirrored = 5
    case right = 6
    case rightMirrored = 7
    case left = 8
}
#endif

open class PHObject: NSObject, NSCopying, @unchecked Sendable {
    public let localIdentifier: String

    public init(localIdentifier: String) {
        self.localIdentifier = localIdentifier
        super.init()
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        self
    }
}

public final class PHImageRequestOptions: NSObject, @unchecked Sendable {
    public var isNetworkAccessAllowed = false
    public var deliveryMode = PHImageRequestOptionsDeliveryMode.opportunistic
    public var resizeMode = PHImageRequestOptionsResizeMode.fast
    public var isSynchronous = false
    public var version = PHImageRequestOptionsVersion.current
    public var normalizedCropRect = CGRect.zero
    public var allowSecondaryDegradedImage = false
    public var progressHandler: PHAssetImageProgressHandler?

    public override init() {
        super.init()
    }
}

public final class PHFetchOptions: NSObject, @unchecked Sendable {
    public var sortDescriptors: [NSSortDescriptor]?
    public var fetchLimit = 0
    public var includeAllBurstAssets = false
    public var includeHiddenAssets = false
    public var includeAssetSourceTypes = PHAssetSourceType.typeUserLibrary
    public var predicate: NSPredicate?
    public var wantsIncrementalChangeDetails = true

    @_spi(OpenUIKitHost)
    public var hostSortsByCreationDateAscending: Bool?

    public override init() {
        super.init()
    }
}

public final class PHAsset: PHObject, @unchecked Sendable {
    public enum PlaybackStyle: Int, Sendable {
        case unsupported = 0
        case image = 1
        case imageAnimated = 2
        case livePhoto = 3
        case video = 4
        case videoLooping = 5
    }

    public let mediaType: PHAssetMediaType
    public let creationDate: Date?
    public let addedDate: Date
    public let modificationDate: Date?
    public let duration: TimeInterval
    public let pixelWidth: Int
    public let pixelHeight: Int
    public let isFavorite: Bool
    public let isHidden: Bool
    public let hasAdjustments: Bool
    public let representsBurst: Bool
    public let burstIdentifier: String?
    public let burstSelectionTypes: PHAssetBurstSelectionType
    public let mediaSubtypes: PHAssetMediaSubtype
    public let sourceType: PHAssetSourceType
    public let playbackStyle: PlaybackStyle
    public let adjustmentFormatIdentifier: String?

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
        self.mediaType = mediaType
        self.creationDate = creationDate
        addedDate = creationDate ?? Date.distantPast
        modificationDate = creationDate
        duration = 0
        pixelWidth = 0
        pixelHeight = 0
        isFavorite = false
        isHidden = false
        hasAdjustments = false
        representsBurst = false
        burstIdentifier = nil
        burstSelectionTypes = []
        mediaSubtypes = []
        sourceType = .typeUserLibrary
        switch mediaType {
        case .video:
            playbackStyle = .video
        case .image:
            playbackStyle = .image
        default:
            playbackStyle = .unsupported
        }
        adjustmentFormatIdentifier = nil
        portableData = data
        portableImage = image
        super.init(localIdentifier: localIdentifier)
    }

    public static func fetchAssets(
        with mediaType: PHAssetMediaType,
        options: PHFetchOptions?
    ) -> PHFetchResult<PHAsset> {
        photosFetchAssets(matching: { $0.mediaType == mediaType }, options: options)
    }

    public static func fetchAssets(with options: PHFetchOptions?) -> PHFetchResult<PHAsset> {
        photosFetchAssets(matching: { _ in true }, options: options)
    }

    public static func fetchAssets(
        withLocalIdentifiers identifiers: [String],
        options: PHFetchOptions?
    ) -> PHFetchResult<PHAsset> {
        let wanted = Set(identifiers)
        return photosFetchAssets(
            matching: { wanted.contains($0.localIdentifier) },
            options: options
        )
    }

    public static func fetchAssets(
        withBurstIdentifier burstIdentifier: String,
        options: PHFetchOptions?
    ) -> PHFetchResult<PHAsset> {
        photosFetchAssets(
            matching: { $0.burstIdentifier == burstIdentifier },
            options: options
        )
    }

    public static func fetchAssets(
        withALAssetURLs assetURLs: [URL],
        options: PHFetchOptions?
    ) -> PHFetchResult<PHAsset> {
        _ = assetURLs
        return photosFetchAssets(matching: { _ in false }, options: options)
    }

    public static func fetchAssets(
        in assetCollection: PHAssetCollection,
        options: PHFetchOptions?
    ) -> PHFetchResult<PHAsset> {
        let identifiers = Set(assetCollection.transientAssetIdentifiers)
        if identifiers.isEmpty {
            return photosFetchAssets(matching: { _ in false }, options: options)
        }
        return photosFetchAssets(
            matching: { identifiers.contains($0.localIdentifier) },
            options: options
        )
    }

    public static func fetchKeyAssets(
        in assetCollection: PHAssetCollection,
        options: PHFetchOptions?
    ) -> PHFetchResult<PHAsset>? {
        let result = fetchAssets(in: assetCollection, options: options)
        return result.count == 0 ? nil : result
    }

    public func canPerform(_ editOperation: PHAssetEditOperation) -> Bool {
        _ = editOperation
        return false
    }

    public func cancelContentEditingInputRequest(_ requestID: PHContentEditingInputRequestID) {
        _ = requestID
    }

    @discardableResult
    public func requestContentEditingInput(
        with options: PHContentEditingInputRequestOptions?,
        completionHandler: @escaping (PHContentEditingInput?, [AnyHashable: Any]) -> Void
    ) -> PHContentEditingInputRequestID {
        _ = options
        completionHandler(nil, [PHContentEditingInputErrorKey: PHPhotosError(.requestNotSupportedForAsset)])
        return 0
    }
}

public final class PHFetchResult<ObjectType: AnyObject>: NSObject, @unchecked Sendable {
    let objects: [ObjectType]

    init(_ objects: [ObjectType]) {
        self.objects = objects
        super.init()
    }

    public var count: Int { objects.count }
    public var firstObject: ObjectType? { objects.first }
    public var lastObject: ObjectType? { objects.last }

    public subscript(idx: Int) -> ObjectType {
        objects[idx]
    }

    public func object(at index: Int) -> ObjectType {
        objects[index]
    }

    public func objects(at indexes: IndexSet) -> [ObjectType] {
        indexes.compactMap { index in
            guard objects.indices.contains(index) else { return nil }
            return objects[index]
        }
    }

    public func contains(_ anObject: ObjectType) -> Bool {
        objects.contains { $0 === anObject }
    }

    public func index(of anObject: ObjectType) -> Int {
        objects.firstIndex { $0 === anObject } ?? NSNotFound
    }

    public func index(of anObject: ObjectType, in range: NSRange) -> Int {
        let start = max(range.location, 0)
        let end = min(range.location + range.length, objects.count)
        guard start < end else { return NSNotFound }
        if let index = objects[start..<end].firstIndex(where: { $0 === anObject }) {
            return index
        }
        return NSNotFound
    }

    public func countOfAssets(with mediaType: PHAssetMediaType) -> Int {
        objects.compactMap { $0 as? PHAsset }.filter { $0.mediaType == mediaType }.count
    }

    public func enumerateObjects(
        _ block: @escaping (ObjectType, Int, UnsafeMutablePointer<ObjCBool>) -> Void
    ) {
        enumerateObjects(options: [], using: block)
    }

    public func enumerateObjects(
        options opts: NSEnumerationOptions = [],
        using block: @escaping (ObjectType, Int, UnsafeMutablePointer<ObjCBool>) -> Void
    ) {
        var stop = ObjCBool(false)
        withUnsafeMutablePointer(to: &stop) { pointer in
            if opts.contains(.reverse) {
                for (index, object) in objects.enumerated().reversed() {
                    block(object, index, pointer)
                    if pointer.pointee.boolValue { break }
                }
            } else {
                for (index, object) in objects.enumerated() {
                    block(object, index, pointer)
                    if pointer.pointee.boolValue { break }
                }
            }
        }
    }

    public func enumerateObjects(
        at s: IndexSet,
        options opts: NSEnumerationOptions = [],
        using block: @escaping (ObjectType, Int, UnsafeMutablePointer<ObjCBool>) -> Void
    ) {
        let subset = PHFetchResult(objects(at: s))
        subset.enumerateObjects(options: opts, using: block)
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
    nonisolated(unsafe) private static var storedCollections: [PHAssetCollection] = []
    nonisolated(unsafe) private static var changeObservers: [ObjectIdentifier:
        PHPhotoLibraryChangeObserver] = [:]
    nonisolated(unsafe) private static var availabilityObservers: [ObjectIdentifier:
        PHPhotoLibraryAvailabilityObserver] = [:]
    nonisolated(unsafe) private static var uploadJobExtensionEnabled = false

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

    static func collections() -> [PHAssetCollection] {
        lock.withLock { storedCollections }
    }

    static func isUploadJobExtensionEnabled() -> Bool {
        lock.withLock { uploadJobExtensionEnabled }
    }

    static func setUploadJobExtensionEnabled(_ enable: Bool) {
        lock.withLock { uploadJobExtensionEnabled = enable }
    }

    static func registerChangeObserver(_ observer: PHPhotoLibraryChangeObserver) {
        lock.withLock {
            changeObservers[ObjectIdentifier(observer)] = observer
        }
    }

    static func unregisterChangeObserver(_ observer: PHPhotoLibraryChangeObserver) {
        lock.withLock {
            _ = changeObservers.removeValue(forKey: ObjectIdentifier(observer))
        }
    }

    static func registerAvailabilityObserver(_ observer: PHPhotoLibraryAvailabilityObserver) {
        lock.withLock {
            availabilityObservers[ObjectIdentifier(observer)] = observer
        }
    }

    static func unregisterAvailabilityObserver(_ observer: PHPhotoLibraryAvailabilityObserver) {
        lock.withLock {
            _ = availabilityObservers.removeValue(forKey: ObjectIdentifier(observer))
        }
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
    public static func _installCollections(_ collections: [PHAssetCollection]) {
        lock.withLock { storedCollections = collections }
    }

    @_spi(OpenUIKitHost)
    public static func _reset() {
        lock.withLock {
            statuses = [:]
            authorizationHandler = nil
            storedAssets = []
            storedCollections = []
            changeObservers = [:]
            availabilityObservers = [:]
            uploadJobExtensionEnabled = false
        }
    }
}

public final class PHPhotoLibrary: NSObject, @unchecked Sendable {
    private static let sharedLibrary = PHPhotoLibrary()
    private static let callbackQueue = DispatchQueue(
        label: "org.openuikit.Photos.host-callback"
    )

    private override init() {
        super.init()
    }

    public static func shared() -> PHPhotoLibrary {
        sharedLibrary
    }

    public static func authorizationStatus() -> PHAuthorizationStatus {
        authorizationStatus(for: .readWrite)
    }

    public static func authorizationStatus(
        for accessLevel: PHAccessLevel
    ) -> PHAuthorizationStatus {
        PHPhotoLibraryPortable.status(for: accessLevel)
    }

    public static func requestAuthorization(
        _ handler: @escaping (PHAuthorizationStatus) -> Void
    ) {
        requestAuthorization(for: .readWrite, handler: handler)
    }

    public static func requestAuthorization(
        for accessLevel: PHAccessLevel,
        handler: @escaping (PHAuthorizationStatus) -> Void
    ) {
        callbackQueue.async {
            Task {
                let status = await requestAuthorization(for: accessLevel)
                handler(status)
            }
        }
    }

    public static func requestAuthorization(
        for accessLevel: PHAccessLevel
    ) async -> PHAuthorizationStatus {
        let status = await PHPhotoLibraryPortable.handler()?(accessLevel)
            ?? .denied
        PHPhotoLibraryPortable.store(status, for: accessLevel)
        return status
    }

    public var unavailabilityReason: (any Error)? { nil }

    public var uploadJobExtensionEnabled: Bool {
        PHPhotoLibraryPortable.isUploadJobExtensionEnabled()
    }

    public var currentChangeToken: PHPersistentChangeToken {
        PHPersistentChangeToken.hostToken
    }

    public func register(_ observer: any PHPhotoLibraryChangeObserver) {
        PHPhotoLibraryPortable.registerChangeObserver(observer)
    }

    public func unregisterChangeObserver(_ observer: any PHPhotoLibraryChangeObserver) {
        PHPhotoLibraryPortable.unregisterChangeObserver(observer)
    }

    public func register(_ observer: any PHPhotoLibraryAvailabilityObserver) {
        PHPhotoLibraryPortable.registerAvailabilityObserver(observer)
    }

    public func unregisterAvailabilityObserver(
        _ observer: any PHPhotoLibraryAvailabilityObserver
    ) {
        PHPhotoLibraryPortable.unregisterAvailabilityObserver(observer)
    }

    public func setUploadJobExtensionEnabled(_ enable: Bool) throws {
        _ = enable
        throw PHPhotosError(.changeNotSupported)
    }

    public func performChangesAndWait(_ changeBlock: @escaping () -> Void) throws {
        _ = changeBlock
        throw PHPhotosError(.changeNotSupported)
    }

    public func performChanges(_ changeBlock: @escaping () -> Void) async throws {
        _ = changeBlock
        throw PHPhotosError(.changeNotSupported)
    }

    public func fetchPersistentChanges(
        since token: PHPersistentChangeToken
    ) throws -> PHPersistentChangeFetchResult {
        _ = token
        throw PHPhotosError(.persistentChangeDetailsUnavailable)
    }

    public func cloudIdentifierMappings(
        forLocalIdentifiers localIdentifiers: [String]
    ) -> [String: Result<PHCloudIdentifier, any Error>] {
        var mappings: [String: Result<PHCloudIdentifier, any Error>] = [:]
        for identifier in localIdentifiers {
            mappings[identifier] = .failure(PHPhotosError(.identifierNotFound))
        }
        return mappings
    }

    public func localIdentifierMappings(
        for cloudIdentifiers: [PHCloudIdentifier]
    ) -> [PHCloudIdentifier: Result<String, any Error>] {
        var mappings: [PHCloudIdentifier: Result<String, any Error>] = [:]
        for identifier in cloudIdentifiers {
            mappings[identifier] = .failure(PHPhotosError(.identifierNotFound))
        }
        return mappings
    }
}

open class PHImageManager: NSObject, @unchecked Sendable {
    private static let sharedManager = PHImageManager()
    private let lock = NSLock()
    private var nextRequestID: PHImageRequestID = 1
    private var cancelled = Set<PHImageRequestID>()

    public override init() {
        super.init()
    }

    public static func `default`() -> PHImageManager {
        sharedManager
    }

    public func cancelImageRequest(_ requestID: PHImageRequestID) {
        lock.withLock { _ = cancelled.insert(requestID) }
    }

    func isCancelled(_ requestID: PHImageRequestID) -> Bool {
        lock.withLock { cancelled.contains(requestID) }
    }

    @discardableResult
    public func requestImageDataAndOrientation(
        for asset: PHAsset,
        options: PHImageRequestOptions?,
        resultHandler: @escaping (
            Data?, String?, CGImagePropertyOrientation,
            [AnyHashable: Any]?
        ) -> Void
    ) -> PHImageRequestID {
        _ = options
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
        resultHandler: @escaping (UIImage?, [AnyHashable: Any]?) -> Void
    ) -> PHImageRequestID {
        _ = targetSize
        _ = contentMode
        _ = options
        let requestID = claimRequestID()
        resultHandler(asset.portableImage, nil)
        return requestID
    }

    @discardableResult
    public func requestLivePhoto(
        for asset: PHAsset,
        targetSize: CGSize,
        contentMode: PHImageContentMode,
        options: PHLivePhotoRequestOptions?,
        resultHandler: @escaping (PHLivePhoto?, [AnyHashable: Any]?) -> Void
    ) -> PHImageRequestID {
        _ = asset
        _ = targetSize
        _ = contentMode
        _ = options
        let requestID = claimRequestID()
        resultHandler(nil, [PHImageErrorKey: PHPhotosError(.requestNotSupportedForAsset)])
        return requestID
    }

    func claimRequestID() -> PHImageRequestID {
        lock.withLock {
            defer { nextRequestID &+= 1 }
            return nextRequestID
        }
    }
}

func photosReadAccessGranted() -> Bool {
    let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    return status == .authorized || status == .limited
}

func photosFetchAssets(
    matching predicate: (PHAsset) -> Bool,
    options: PHFetchOptions?
) -> PHFetchResult<PHAsset> {
    guard photosReadAccessGranted() else {
        return PHFetchResult([])
    }
    var assets = PHPhotoLibraryPortable.assets().filter(predicate)
    #if os(Linux)
    if let ascending = options?.hostSortsByCreationDateAscending {
        assets.sort {
            let left = $0.creationDate ?? .distantPast
            let right = $1.creationDate ?? .distantPast
            return ascending ? left < right : left > right
        }
    }
    #else
    if let descriptor = options?.sortDescriptors?.first,
        descriptor.key == "creationDate"
    {
        assets.sort {
            let left = $0.creationDate ?? .distantPast
            let right = $1.creationDate ?? .distantPast
            return descriptor.ascending ? left < right : left > right
        }
    }
    #endif
    if let limit = options?.fetchLimit, limit > 0, assets.count > limit {
        assets.removeLast(assets.count - limit)
    }
    return PHFetchResult(assets)
}
