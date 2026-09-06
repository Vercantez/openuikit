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

    open override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? PHObject else {
            return super.isEqual(object)
        }
        return localIdentifier == other.localIdentifier
    }

    open override var hash: Int { localIdentifier.hashValue }
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

    /// Linux corelibs has no `NSPredicate(format:)`. Darwin tests still use
    /// format strings over the documented keys; the isolated host uses this
    /// closure instead (PhotosLibraryTests.testFetchOptionsPredicateSortAndHidden).
    @_spi(OpenUIKitHost)
    public var hostPredicateEvaluates: ((PHAsset) -> Bool)?

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
    public let originalFilename: String
    public let uniformTypeIdentifier: String

    let portableData: Data?
    let portableImage: UIImage?

    init(
        localIdentifier: String,
        mediaType: PHAssetMediaType,
        creationDate: Date?,
        addedDate: Date,
        modificationDate: Date?,
        duration: TimeInterval,
        pixelWidth: Int,
        pixelHeight: Int,
        isFavorite: Bool,
        isHidden: Bool,
        hasAdjustments: Bool,
        representsBurst: Bool,
        burstIdentifier: String?,
        burstSelectionTypes: PHAssetBurstSelectionType,
        mediaSubtypes: PHAssetMediaSubtype,
        sourceType: PHAssetSourceType,
        playbackStyle: PlaybackStyle,
        adjustmentFormatIdentifier: String?,
        data: Data?,
        image: UIImage?,
        originalFilename: String,
        uniformTypeIdentifier: String
    ) {
        self.mediaType = mediaType
        self.creationDate = creationDate
        self.addedDate = addedDate
        self.modificationDate = modificationDate
        self.duration = duration
        self.pixelWidth = pixelWidth
        self.pixelHeight = pixelHeight
        self.isFavorite = isFavorite
        self.isHidden = isHidden
        self.hasAdjustments = hasAdjustments
        self.representsBurst = representsBurst
        self.burstIdentifier = burstIdentifier
        self.burstSelectionTypes = burstSelectionTypes
        self.mediaSubtypes = mediaSubtypes
        self.sourceType = sourceType
        self.playbackStyle = playbackStyle
        self.adjustmentFormatIdentifier = adjustmentFormatIdentifier
        self.originalFilename = originalFilename
        self.uniformTypeIdentifier = uniformTypeIdentifier
        portableData = data
        portableImage = image
        super.init(localIdentifier: localIdentifier)
    }

    @_spi(OpenUIKitHost)
    public init(
        localIdentifier: String,
        mediaType: PHAssetMediaType,
        creationDate: Date? = nil,
        data: Data? = nil,
        image: UIImage? = nil
    ) {
        let size = data.flatMap(photosImagePixelSize) ?? (0, 0)
        self.mediaType = mediaType
        self.creationDate = creationDate
        addedDate = creationDate ?? Date.distantPast
        modificationDate = creationDate
        duration = 0
        pixelWidth = size.0
        pixelHeight = size.1
        isFavorite = false
        isHidden = false
        hasAdjustments = false
        representsBurst = false
        burstIdentifier = nil
        burstSelectionTypes = []
        mediaSubtypes = []
        sourceType = .typeUserLibrary
        playbackStyle = photosPlaybackStyle(for: mediaType)
        adjustmentFormatIdentifier = nil
        originalFilename = "\(localIdentifier).bin"
        uniformTypeIdentifier = "public.data"
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
        if assetCollection.assetCollectionType == .smartAlbum {
            return photosFetchAssets(
                matching: {
                    photosAssetMatchesSmartAlbum(
                        $0,
                        subtype: assetCollection.assetCollectionSubtype
                    )
                },
                options: options
            )
        }
        if let live = PhotosLibraryStore.album(identifier: assetCollection.localIdentifier) {
            let identifiers = Set(live.transientAssetIdentifiers)
            return photosFetchAssets(
                matching: { identifiers.contains($0.localIdentifier) },
                options: options
            )
        }
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
        return photosReadAccessGranted()
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
    let refetch: (() -> [ObjectType])?

    init(_ objects: [ObjectType], refetch: (() -> [ObjectType])? = nil) {
        self.objects = objects
        self.refetch = refetch
        super.init()
    }

    @_spi(OpenUIKitHost)
    public convenience init(hostObjects objects: [ObjectType]) {
        self.init(objects)
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
        if let object = anObject as? PHObject {
            return objects.contains { ($0 as? PHObject)?.localIdentifier == object.localIdentifier }
        }
        return objects.contains { $0 === anObject }
    }

    public func index(of anObject: ObjectType) -> Int {
        if let object = anObject as? PHObject {
            return objects.firstIndex {
                ($0 as? PHObject)?.localIdentifier == object.localIdentifier
            } ?? NSNotFound
        }
        return objects.firstIndex { $0 === anObject } ?? NSNotFound
    }

    public func index(of anObject: ObjectType, in range: NSRange) -> Int {
        let start = max(range.location, 0)
        let end = min(range.location + range.length, objects.count)
        guard start < end else { return NSNotFound }
        let slice = objects[start..<end]
        if let object = anObject as? PHObject {
            if let index = slice.firstIndex(where: {
                ($0 as? PHObject)?.localIdentifier == object.localIdentifier
            }) {
                return index
            }
            return NSNotFound
        }
        if let index = slice.firstIndex(where: { $0 === anObject }) {
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

    static func status(for level: PHAccessLevel) -> PHAuthorizationStatus {
        PhotosLibraryStore.status(for: level)
    }

    static func store(
        _ status: PHAuthorizationStatus,
        for level: PHAccessLevel
    ) {
        PhotosLibraryStore.store(status, for: level)
    }

    static func handler() -> AuthorizationHandler? {
        PhotosLibraryStore.handler()
    }

    static func assets() -> [PHAsset] {
        PhotosLibraryStore.allAssets()
    }

    static func collections() -> [PHAssetCollection] {
        PhotosLibraryStore.userAlbums()
    }

    static func isUploadJobExtensionEnabled() -> Bool {
        PhotosLibraryStore.isUploadJobExtensionEnabled()
    }

    static func setUploadJobExtensionEnabled(_ enable: Bool) {
        PhotosLibraryStore.setUploadJobExtensionEnabled(enable)
    }

    static func registerChangeObserver(_ observer: PHPhotoLibraryChangeObserver) {
        PhotosLibraryStore.registerChangeObserver(observer)
    }

    static func unregisterChangeObserver(_ observer: PHPhotoLibraryChangeObserver) {
        PhotosLibraryStore.unregisterChangeObserver(observer)
    }

    static func registerAvailabilityObserver(_ observer: PHPhotoLibraryAvailabilityObserver) {
        PhotosLibraryStore.registerAvailabilityObserver(observer)
    }

    static func unregisterAvailabilityObserver(_ observer: PHPhotoLibraryAvailabilityObserver) {
        PhotosLibraryStore.unregisterAvailabilityObserver(observer)
    }

    /// Documented test hook: `requestAuthorization(for:)` delivers this
    /// handler's status instead of fail-closing to `.denied`.
    @_spi(OpenUIKitHost)
    public static func _installAuthorizationHandler(
        _ handler: AuthorizationHandler?
    ) {
        PhotosLibraryStore.setHandler(handler)
    }

    @_spi(OpenUIKitHost)
    public static func _installAssets(_ assets: [PHAsset]) {
        PhotosLibraryStore.installAssets(assets)
    }

    @_spi(OpenUIKitHost)
    public static func _installCollections(_ collections: [PHAssetCollection]) {
        PhotosLibraryStore.installCollections(collections)
    }

    @_spi(OpenUIKitHost)
    public static func _reset() {
        PhotosLibraryStore.reset()
    }

    /// Documented test hook: set an already-determined authorization status
    /// without the async `requestAuthorization` path.
    @_spi(OpenUIKitHost)
    public static func _setStatus(
        _ status: PHAuthorizationStatus,
        for level: PHAccessLevel
    ) {
        PhotosLibraryStore.store(status, for: level)
    }
}

public final class PHPhotoLibrary: NSObject, @unchecked Sendable {
    private static let sharedLibrary = PHPhotoLibrary()

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

    /// Photos documents an arbitrary serial queue for the handler. This port
    /// uses `org.openuikit.Photos.host-callback`.
    public static func requestAuthorization(
        for accessLevel: PHAccessLevel,
        handler: @escaping (PHAuthorizationStatus) -> Void
    ) {
        PhotosLibraryStore.callbackQueue.async {
            Task {
                let status = await requestAuthorization(for: accessLevel)
                handler(status)
            }
        }
    }

    public static func requestAuthorization(
        for accessLevel: PHAccessLevel
    ) async -> PHAuthorizationStatus {
        let existing = authorizationStatus(for: accessLevel)
        if existing != .notDetermined {
            return existing
        }
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
        PhotosLibraryStore.currentChangeToken()
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
        guard photosWriteAccessGranted() else {
            throw PHPhotosError(.accessUserDenied)
        }
        PhotosChangeSession.begin(allowsDelete: photosReadAccessGranted())
        changeBlock()
        let operations = PhotosChangeSession.take()
        if operations.contains(where: { operation in
            if case .deleteAssets = operation { return true }
            if case .deleteAlbums = operation { return true }
            if case .deleteLists = operation { return true }
            return false
        }), !photosReadAccessGranted() {
            throw PHPhotosError(.accessUserDenied)
        }
        let applied = try PhotosLibraryStore.apply(operations)
        photosNotifyObservers(applied)
    }

    public func performChanges(_ changeBlock: @escaping () -> Void) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            PhotosLibraryStore.callbackQueue.async {
                do {
                    try self.performChangesAndWait(changeBlock)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    public func fetchPersistentChanges(
        since token: PHPersistentChangeToken
    ) throws -> PHPersistentChangeFetchResult {
        let changes = try PhotosLibraryStore.persistentChanges(since: token)
        return PHPersistentChangeFetchResult(changes: changes)
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
        let requestID = claimRequestID()
        deliver(options: options) {
            if self.isCancelled(requestID) {
                resultHandler(
                    nil,
                    nil,
                    .up,
                    [
                        PHImageCancelledKey: true,
                        PHImageResultRequestIDKey: requestID,
                    ]
                )
                return
            }
            if let denied = self.networkDeniedInfo(options: options, requestID: requestID) {
                resultHandler(nil, nil, .up, denied)
                return
            }
            if self.invokeProgressHandler(options?.progressHandler, requestID: requestID) {
                resultHandler(
                    nil,
                    nil,
                    .up,
                    [
                        PHImageCancelledKey: true,
                        PHImageResultRequestIDKey: requestID,
                    ]
                )
                return
            }
            let data = asset.portableData
                ?? PhotosLibraryStore.resourceData(forAssetIdentifier: asset.localIdentifier)
            var info: [AnyHashable: Any] = [
                PHImageResultRequestIDKey: requestID,
                PHImageResultIsDegradedKey: false,
                PHImageResultIsInCloudKey: false,
            ]
            if data == nil {
                info[PHImageErrorKey] = PHPhotosError(.missingResource)
            }
            resultHandler(data, asset.uniformTypeIdentifier, .up, info)
        }
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
        let requestID = claimRequestID()
        deliver(options: options) {
            if self.isCancelled(requestID) {
                resultHandler(
                    nil,
                    [
                        PHImageCancelledKey: true,
                        PHImageResultRequestIDKey: requestID,
                    ]
                )
                return
            }
            if let denied = self.networkDeniedInfo(options: options, requestID: requestID) {
                resultHandler(nil, denied)
                return
            }
            if self.invokeProgressHandler(options?.progressHandler, requestID: requestID) {
                resultHandler(
                    nil,
                    [
                        PHImageCancelledKey: true,
                        PHImageResultRequestIDKey: requestID,
                    ]
                )
                return
            }
            var info: [AnyHashable: Any] = [
                PHImageResultRequestIDKey: requestID,
                PHImageResultIsDegradedKey: false,
                PHImageResultIsInCloudKey: false,
            ]
            if let image = asset.portableImage {
                resultHandler(image, info)
                return
            }
            #if canImport(UIKit)
            if let data = asset.portableData
                ?? PhotosLibraryStore.resourceData(forAssetIdentifier: asset.localIdentifier),
                let image = UIImage(data: data)
            {
                resultHandler(image, info)
                return
            }
            #endif
            info[PHImageErrorKey] = PHPhotosError(.requestNotSupportedForAsset)
            resultHandler(nil, info)
        }
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
        resultHandler(
            nil,
            [
                PHLivePhotoInfoErrorKey: PHPhotosError(.requestNotSupportedForAsset),
                PHImageErrorKey: PHPhotosError(.requestNotSupportedForAsset),
                PHImageResultRequestIDKey: requestID,
            ]
        )
        return requestID
    }

    private func networkDeniedInfo(
        options: PHImageRequestOptions?,
        requestID: PHImageRequestID
    ) -> [AnyHashable: Any]? {
        _ = options
        _ = requestID
        return nil
    }

    /// Ice Cubes / PhotosHostRuntime deliver inline even when
    /// `isSynchronous == false`. Darwin queue identity is unobserved
    /// (`oracle-questions.tsv`).
    private func deliver(options: PHImageRequestOptions?, body: @escaping () -> Void) {
        _ = options?.isSynchronous
        body()
    }

    /// Returns `true` when the progress handler sets the stop flag.
    private func invokeProgressHandler(
        _ handler: PHAssetImageProgressHandler?,
        requestID: PHImageRequestID
    ) -> Bool {
        guard let handler else { return false }
        var stop = ObjCBool(false)
        return withUnsafeMutablePointer(to: &stop) { pointer in
            handler(0.0, nil, pointer, [PHImageResultRequestIDKey: requestID])
            if pointer.pointee.boolValue { return true }
            handler(1.0, nil, pointer, [PHImageResultRequestIDKey: requestID])
            return pointer.pointee.boolValue
        }
    }

    func claimRequestID() -> PHImageRequestID {
        lock.withLock {
            defer { nextRequestID &+= 1 }
            return nextRequestID
        }
    }
}

