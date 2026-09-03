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

    public init?(livePhotoEditingInput livePhotoInput: PHContentEditingInput) {
        _ = livePhotoInput
        return nil
    }

    public func cancel() {}

    public func livePhotoForPlayback(
        targetSize: CGSize,
        options: [String: Any]? = nil
    ) async throws -> PHLivePhoto {
        _ = targetSize
        _ = options
        throw PHPhotosError(.requestNotSupportedForAsset)
    }

    public func saveLivePhoto(
        to output: PHContentEditingOutput,
        options: [String: Any]? = nil
    ) async throws {
        _ = output
        _ = options
        throw PHPhotosError(.requestNotSupportedForAsset)
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
        guard asset.portableData != nil || asset.portableImage != nil else { return [] }
        return [
            PHAssetResource(
                type: asset.mediaType == .video ? .video : .photo,
                assetLocalIdentifier: asset.localIdentifier,
                originalFilename: "\(asset.localIdentifier).bin",
                uniformTypeIdentifier: "public.data",
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

    private override init() {
        super.init()
    }

    public class func `default`() -> PHAssetResourceManager {
        sharedManager
    }

    public func cancelDataRequest(_ requestID: PHAssetResourceDataRequestID) {
        _ = requestID
    }

    @discardableResult
    public func requestData(
        for resource: PHAssetResource,
        options: PHAssetResourceRequestOptions?,
        dataReceivedHandler handler: @escaping (Data) -> Void,
        completionHandler: @escaping ((any Error)?) -> Void
    ) -> PHAssetResourceDataRequestID {
        _ = resource
        _ = options
        let requestID = lock.withLock { () -> PHAssetResourceDataRequestID in
            defer { nextRequestID &+= 1 }
            return nextRequestID
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
        _ = resource
        _ = fileURL
        _ = options
        throw PHPhotosError(.missingResource)
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
    static let hostToken = PHPersistentChangeToken(tokenValue: 0)

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

    init(changeToken: PHPersistentChangeToken) {
        self.changeToken = changeToken
        super.init()
    }

    public func changeDetails(for objectType: PHObjectType) throws -> PHPersistentObjectChangeDetails {
        _ = objectType
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
    public convenience init?(for job: PHAssetResourceUploadJob) {
        _ = job
        return nil
    }

    public convenience init?(forUploadJob job: PHAssetResourceUploadJob) {
        self.init(for: job)
    }

    public func acknowledge() {}
}
