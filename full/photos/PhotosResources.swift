import Foundation

public protocol PHPhotoLibraryChangeObserver: AnyObject {
    func photoLibraryDidChange(_ changeInstance: PHChange)
}

public protocol PHPhotoLibraryAvailabilityObserver: AnyObject {
    func photoLibraryDidBecomeUnavailable(_ photoLibrary: PHPhotoLibrary)
}

public final class PHAdjustmentData: NSObject, @unchecked Sendable {
    public let formatIdentifier: String
    public let formatVersion: String
    public let data: Data

    public init(formatIdentifier: String, formatVersion: String, data: Data) {
        self.formatIdentifier = formatIdentifier
        self.formatVersion = formatVersion
        self.data = data
        super.init()
    }
}

public final class PHContentEditingInput: NSObject, @unchecked Sendable {
    public var adjustmentData: PHAdjustmentData?
    public var creationDate: Date?
    public var displaySizeImage: UIImage?
    public var fullSizeImageOrientation: Int32 = 1
    public var fullSizeImageURL: URL?
    public var livePhoto: PHLivePhoto?
    public var mediaSubtypes: PHAssetMediaSubtype = []
    public var mediaType: PHAssetMediaType = .unknown
    public var playbackStyle: PHAsset.PlaybackStyle = .unsupported
    public var uniformTypeIdentifier: String?

    public override init() {
        super.init()
    }
}

public final class PHContentEditingInputRequestOptions: NSObject, @unchecked Sendable {
    public var canHandleAdjustmentData: (PHAdjustmentData) -> Bool = { _ in false }
    public var isNetworkAccessAllowed = false
    public var progressHandler: ((Double, UnsafeMutablePointer<ObjCBool>) -> Void)?

    public override init() {
        super.init()
    }
}

public final class PHContentEditingOutput: NSObject, @unchecked Sendable {
    public var adjustmentData: PHAdjustmentData?
    public let renderedContentURL: URL

    public init(contentEditingInput: PHContentEditingInput) {
        renderedContentURL = contentEditingInput.fullSizeImageURL
            ?? URL(fileURLWithPath: "/tmp/photos-rendered-unavailable")
        super.init()
    }

    public init(placeholderForCreatedAsset: PHObjectPlaceholder) {
        _ = placeholderForCreatedAsset
        renderedContentURL = URL(fileURLWithPath: "/tmp/photos-rendered-unavailable")
        super.init()
    }
}

public final class PHLivePhoto: NSObject, @unchecked Sendable {
    public let size: CGSize

    public override init() {
        size = .zero
        super.init()
    }

    public init?(coder: NSCoder) {
        _ = coder
        return nil
    }

    public class func cancelRequest(withRequestID requestID: PHLivePhotoRequestID) {
        _ = requestID
    }

    @discardableResult
    public class func request(
        withResourceFileURLs fileURLs: [URL],
        placeholderImage image: UIImage?,
        targetSize: CGSize,
        contentMode: PHImageContentMode,
        resultHandler: @escaping (PHLivePhoto?, [AnyHashable: Any]) -> Void
    ) -> PHLivePhotoRequestID {
        _ = fileURLs
        _ = image
        _ = targetSize
        _ = contentMode
        resultHandler(nil, [PHLivePhotoInfoErrorKey: PHPhotosError(.requestNotSupportedForAsset)])
        return PHLivePhotoRequestIDInvalid
    }
}

public final class PHLivePhotoRequestOptions: NSObject, @unchecked Sendable {
    public var deliveryMode = PHImageRequestOptionsDeliveryMode.opportunistic
    public var isNetworkAccessAllowed = false
    public var version = PHImageRequestOptionsVersion.current
    public var progressHandler: PHAssetImageProgressHandler?

    public override init() {
        super.init()
    }
}

public final class PHLivePhotoEditingContext: NSObject, @unchecked Sendable {
    public var audioVolume: Float = 1
    public var orientation: CGImagePropertyOrientation = .up
    private var cancelled = false
    private let input: PHContentEditingInput

    /// Constructs a wrapper around a live-photo editing input. Rendering still
    /// fail-closes: Linux has no Live Photo compositor, ImageIO pair, or
    /// `photolibraryd`. Returns `nil` when `livePhoto` is absent.
    public init?(livePhotoEditingInput livePhotoInput: PHContentEditingInput) {
        guard livePhotoInput.livePhoto != nil else {
            return nil
        }
        input = livePhotoInput
        super.init()
    }

    public func cancel() {
        cancelled = true
    }

    public func prepareLivePhotoForPlayback(
        withTargetSize targetSize: CGSize,
        options: [PHLivePhotoEditingOption: Any]? = nil,
        completionHandler: @escaping (PHLivePhoto?, (any Error)?) -> Void
    ) {
        _ = targetSize
        _ = options
        _ = input
        if cancelled {
            completionHandler(nil, PHPhotosError(.operationInterrupted))
            return
        }
        completionHandler(nil, PHPhotosError(.requestNotSupportedForAsset))
    }

    public func saveLivePhoto(
        to output: PHContentEditingOutput,
        options: [PHLivePhotoEditingOption: Any]? = nil,
        completionHandler: @escaping (Bool, (any Error)?) -> Void
    ) {
        _ = output
        _ = options
        if cancelled {
            completionHandler(false, PHPhotosError(.operationInterrupted))
            return
        }
        completionHandler(false, PHPhotosError(.requestNotSupportedForAsset))
    }

    public func livePhotoForPlayback(
        targetSize: CGSize,
        options: [String: Any]? = nil
    ) async throws -> PHLivePhoto {
        try await withCheckedThrowingContinuation { continuation in
            var mapped: [PHLivePhotoEditingOption: Any] = [:]
            if let options {
                for (key, value) in options {
                    mapped[PHLivePhotoEditingOption(rawValue: key)] = value
                }
            }
            prepareLivePhotoForPlayback(
                withTargetSize: targetSize,
                options: mapped
            ) { photo, error in
                if let photo {
                    continuation.resume(returning: photo)
                } else {
                    continuation.resume(throwing: error ?? PHPhotosError(.requestNotSupportedForAsset))
                }
            }
        }
    }

    public func saveLivePhoto(
        to output: PHContentEditingOutput,
        options: [String: Any]? = nil
    ) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            var mapped: [PHLivePhotoEditingOption: Any] = [:]
            if let options {
                for (key, value) in options {
                    mapped[PHLivePhotoEditingOption(rawValue: key)] = value
                }
            }
            saveLivePhoto(to: output, options: mapped) { success, error in
                if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: error ?? PHPhotosError(.requestNotSupportedForAsset))
                }
            }
        }
    }
}

public final class PHVideoRequestOptions: NSObject, @unchecked Sendable {
    public var deliveryMode = PHVideoRequestOptionsDeliveryMode.automatic
    public var isNetworkAccessAllowed = false
    public var version = PHVideoRequestOptionsVersion.current
    public var progressHandler: PHAssetVideoProgressHandler?

    public override init() {
        super.init()
    }
}

public final class PHCachingImageManager: PHImageManager, @unchecked Sendable {
    public var allowsCachingHighQualityImages = true

    public func startCachingImages(
        for assets: [PHAsset],
        targetSize: CGSize,
        contentMode: PHImageContentMode,
        options: PHImageRequestOptions?
    ) {
        _ = assets
        _ = targetSize
        _ = contentMode
        _ = options
    }

    public func stopCachingImages(
        for assets: [PHAsset],
        targetSize: CGSize,
        contentMode: PHImageContentMode,
        options: PHImageRequestOptions?
    ) {
        _ = assets
        _ = targetSize
        _ = contentMode
        _ = options
    }

    public func stopCachingImagesForAllAssets() {}
}

public final class PHAssetResource: NSObject, @unchecked Sendable {
    public let type: PHAssetResourceType
    public let assetLocalIdentifier: String
    public let originalFilename: String
    public let uniformTypeIdentifier: String
    public let pixelWidth: Int
    public let pixelHeight: Int

    init(
        type: PHAssetResourceType,
        assetLocalIdentifier: String,
        originalFilename: String,
        uniformTypeIdentifier: String,
        pixelWidth: Int,
        pixelHeight: Int
    ) {
        self.type = type
        self.assetLocalIdentifier = assetLocalIdentifier
        self.originalFilename = originalFilename
        self.uniformTypeIdentifier = uniformTypeIdentifier
        self.pixelWidth = pixelWidth
        self.pixelHeight = pixelHeight
        super.init()
    }

    public class func assetResources(for asset: PHAsset) -> [PHAssetResource] {
        guard photosReadAccessGranted() else { return [] }
        let data = asset.portableData
            ?? PhotosLibraryStore.resourceData(forAssetIdentifier: asset.localIdentifier)
        guard data != nil || asset.portableImage != nil else { return [] }
        return [
            PHAssetResource(
                type: asset.mediaType == .video ? .video : .photo,
                assetLocalIdentifier: asset.localIdentifier,
                originalFilename: asset.originalFilename,
                uniformTypeIdentifier: asset.uniformTypeIdentifier,
                pixelWidth: asset.pixelWidth,
                pixelHeight: asset.pixelHeight
            )
        ]
    }

    public class func assetResources(for livePhoto: PHLivePhoto) -> [PHAssetResource] {
        _ = livePhoto
        return []
    }
}

public final class PHAssetResourceCreationOptions: NSObject, @unchecked Sendable {
    public var originalFilename: String?
    public var shouldMoveFile = false
    public var uniformTypeIdentifier: String?

    public override init() {
        super.init()
    }
}

public final class PHAssetResourceRequestOptions: NSObject, @unchecked Sendable {
    public var isNetworkAccessAllowed = false
    public var progressHandler: PHAssetResourceProgressHandler?

    public override init() {
        super.init()
    }
}

public final class PHAssetResourceManager: NSObject, @unchecked Sendable {
    private static let sharedManager = PHAssetResourceManager()
    private let lock = NSLock()
    private var nextRequestID: PHAssetResourceDataRequestID = 1
    private var cancelled = Set<PHAssetResourceDataRequestID>()

    private override init() {
        super.init()
    }

    public class func `default`() -> PHAssetResourceManager {
        sharedManager
    }

    public func cancelDataRequest(_ requestID: PHAssetResourceDataRequestID) {
        lock.withLock { _ = cancelled.insert(requestID) }
    }

    @discardableResult
    public func requestData(
        for resource: PHAssetResource,
        options: PHAssetResourceRequestOptions?,
        dataReceivedHandler handler: @escaping (Data) -> Void,
        completionHandler: @escaping ((any Error)?) -> Void
    ) -> PHAssetResourceDataRequestID {
        let requestID = lock.withLock { () -> PHAssetResourceDataRequestID in
            defer { nextRequestID &+= 1 }
            return nextRequestID
        }
        if lock.withLock({ cancelled.contains(requestID) }) {
            completionHandler(PHPhotosError(.operationInterrupted))
            return requestID
        }
        options?.progressHandler?(1.0)
        if lock.withLock({ cancelled.contains(requestID) }) {
            completionHandler(PHPhotosError(.operationInterrupted))
            return requestID
        }
        if let data = PhotosLibraryStore.resourceData(
            forAssetIdentifier: resource.assetLocalIdentifier
        ) {
            handler(data)
            completionHandler(nil)
            return requestID
        }
        handler(Data())
        completionHandler(PHPhotosError(.missingResource))
        return requestID
    }

    public func writeData(
        for resource: PHAssetResource,
        toFile fileURL: URL,
        options: PHAssetResourceRequestOptions?
    ) async throws {
        _ = options
        guard let data = PhotosLibraryStore.resourceData(
            forAssetIdentifier: resource.assetLocalIdentifier
        ) else {
            throw PHPhotosError(.missingResource)
        }
        try data.write(to: fileURL, options: .atomic)
    }
}

public final class PHCloudIdentifier: NSObject, @unchecked Sendable {
    public let stringValue: String

    public init(stringValue: String) {
        self.stringValue = stringValue
        super.init()
    }

    public init?(coder: NSCoder) {
        _ = coder
        return nil
    }
}

public final class PHPersistentChangeToken: NSObject, @unchecked Sendable {
    let tokenValue: Int

    init(tokenValue: Int) {
        self.tokenValue = tokenValue
        super.init()
    }

    public init?(coder: NSCoder) {
        _ = coder
        return nil
    }
}

public final class PHPersistentChange: NSObject, @unchecked Sendable {
    public let changeToken: PHPersistentChangeToken
    var assetDetails: PHPersistentObjectChangeDetails?
    var collectionDetails: PHPersistentObjectChangeDetails?
    var listDetails: PHPersistentObjectChangeDetails?

    init(changeToken: PHPersistentChangeToken) {
        self.changeToken = changeToken
        super.init()
    }

    public func changeDetails(for objectType: PHObjectType) throws -> PHPersistentObjectChangeDetails {
        switch objectType {
        case .asset:
            if let assetDetails { return assetDetails }
        case .assetCollection:
            if let collectionDetails { return collectionDetails }
        case .collectionList:
            if let listDetails { return listDetails }
        }
        throw PHPhotosError(.persistentChangeDetailsUnavailable)
    }
}

public final class PHPersistentObjectChangeDetails: NSObject, @unchecked Sendable {
    public let objectType: PHObjectType
    public let insertedLocalIdentifiers: Set<String>
    public let updatedLocalIdentifiers: Set<String>
    public let deletedLocalIdentifiers: Set<String>

    init(
        objectType: PHObjectType,
        insertedLocalIdentifiers: Set<String> = [],
        updatedLocalIdentifiers: Set<String> = [],
        deletedLocalIdentifiers: Set<String> = []
    ) {
        self.objectType = objectType
        self.insertedLocalIdentifiers = insertedLocalIdentifiers
        self.updatedLocalIdentifiers = updatedLocalIdentifiers
        self.deletedLocalIdentifiers = deletedLocalIdentifiers
        super.init()
    }
}

public final class PHPersistentChangeFetchResult: NSObject, @unchecked Sendable, Sequence {
    public typealias Element = PHPersistentChange

    let changes: [PHPersistentChange]

    init(changes: [PHPersistentChange] = []) {
        self.changes = changes
        super.init()
    }

    public func makeIterator() -> Iterator {
        Iterator(fetchResult: self)
    }

    public final class Iterator: IteratorProtocol {
        public typealias Element = PHPersistentChange
        private var remaining: [PHPersistentChange]

        public init(fetchResult: PHPersistentChangeFetchResult) {
            remaining = fetchResult.changes
        }

        public func next() -> PHPersistentChange? {
            guard remaining.isEmpty == false else { return nil }
            return remaining.removeFirst()
        }
    }
}

public final class PHAssetResourceUploadJob: PHObject, @unchecked Sendable {
    public enum Action: Int, Sendable {
        case acknowledge = 0
        case retry = 1
    }

    public enum State: Int, Sendable {
        case pending = 0
        case registered = 1
        case failed = 2
        case succeeded = 3
    }

    public let resource: PHAssetResource
    public let state: State
    public class var jobLimit: Int { 0 }

    init(resource: PHAssetResource, state: State) {
        self.resource = resource
        self.state = state
        super.init(localIdentifier: resource.assetLocalIdentifier)
    }

    @_spi(OpenUIKitHost)
    public static func _hostJob(
        resource: PHAssetResource,
        state: State
    ) -> PHAssetResourceUploadJob {
        PHAssetResourceUploadJob(resource: resource, state: state)
    }

    public class func fetchJobs(
        action: Action,
        options: PHFetchOptions?
    ) -> PHFetchResult<PHAssetResourceUploadJob> {
        _ = action
        _ = options
        return PHFetchResult([])
    }
}

public final class PHAssetResourceUploadJobChangeRequest: PHChangeRequest, @unchecked Sendable {
    var jobIdentifier: String?

    public convenience init?(for job: PHAssetResourceUploadJob) {
        self.init()
        jobIdentifier = job.localIdentifier
        // No photolibraryd / iCloud Photos upload pipeline on Linux. The
        // request object exists so callers can invoke `acknowledge()`, but
        // `fetchJobs` remains empty.
    }

    public convenience init?(forUploadJob job: PHAssetResourceUploadJob) {
        self.init(for: job)
    }

    public func acknowledge() {
        _ = jobIdentifier
    }
}
