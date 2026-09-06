import Foundation

/// Camera catalog item. Linux never enumerates hardware files;
/// host SPI constructs records for property and fail-closed I/O tests.
open class ICCameraItem: NSObject {
    private weak var _device: ICCameraDevice?
    private weak var _parentFolder: ICCameraFolder?
    private var _name: String?
    private var _uti: String?
    private var _isLocked = false
    private var _isRaw = false
    private var _isInTemporaryStore = false
    private var _wasAddedAfterContentCatalogCompleted = false
    private var _creationDate: Date?
    private var _modificationDate: Date?
    private var _metadata: [AnyHashable: Any]?
    private var _metadataIfAvailable: [String: Any]?
    private var _userData: NSMutableDictionary?
    private var _ptpObjectHandle: UInt32 = 0
    private var _thumbnail: CGImage?
    private var _thumbnailIfAvailable: CGImage?
    private var _largeThumbnailIfAvailable: CGImage?

    @available(*, unavailable, message: "ICCameraItem is created by ICCameraDevice")
    public override init() {
        fatalError("ICCameraItem.init is unsupported")
    }

    init(hostName name: String?, device: ICCameraDevice?, uti: String? = nil) {
        _name = name
        _device = device
        _uti = uti
        super.init()
    }

    open var device: ICCameraDevice? { _device }
    open var parentFolder: ICCameraFolder? { _parentFolder }
    open var name: String? { _name }
    open var uti: String? { _uti }
    open var isLocked: Bool { _isLocked }
    open var isRaw: Bool { _isRaw }
    open var isInTemporaryStore: Bool { _isInTemporaryStore }
    open var wasAddedAfterContentCatalogCompleted: Bool { _wasAddedAfterContentCatalogCompleted }
    open var creationDate: Date? { _creationDate }
    open var modificationDate: Date? { _modificationDate }
    open var metadata: [AnyHashable: Any]? { _metadata }
    open var metadataIfAvailable: [String: Any]? { _metadataIfAvailable }
    open var ptpObjectHandle: UInt32 { _ptpObjectHandle }
    open var thumbnail: CGImage? { _thumbnail }
    open var thumbnailIfAvailable: CGImage? { _thumbnailIfAvailable }
    open var largeThumbnailIfAvailable: CGImage? { _largeThumbnailIfAvailable }

    open var userData: NSMutableDictionary? {
        if _userData == nil {
            _userData = NSMutableDictionary()
        }
        return _userData
    }

    func hostSetParentFolder(_ folder: ICCameraFolder?) {
        _parentFolder = folder
    }

    @_spi(OpenUIKitHost)
    public func hostSetDates(creation: Date?, modification: Date?) {
        _creationDate = creation
        _modificationDate = modification
    }

    @_spi(OpenUIKitHost)
    public func hostSetFlags(locked: Bool, raw: Bool, temporary: Bool, addedAfterCatalog: Bool) {
        _isLocked = locked
        _isRaw = raw
        _isInTemporaryStore = temporary
        _wasAddedAfterContentCatalogCompleted = addedAfterCatalog
    }

    @_spi(OpenUIKitHost)
    public func hostSetPTPObjectHandle(_ handle: UInt32) {
        _ptpObjectHandle = handle
    }

    /// Drops any cached metadata dictionary. Linux never fetches
    /// camera metadata, so this is a local no-op on empty storage.
    open func flushMetadataCache() {
        _metadata = nil
        _metadataIfAvailable = nil
    }

    /// Drops any cached thumbnail. Linux never fetches camera
    /// thumbnails.
    open func flushThumbnailCache() {
        _thumbnail = nil
        _thumbnailIfAvailable = nil
        _largeThumbnailIfAvailable = nil
    }

    /// Fail-closed: no metadata pipeline. Delegate is not invoked with
    /// invented dictionaries.
    open func requestMetadata() {}

    /// Fail-closed: no thumbnail pipeline.
    open func requestThumbnail() {}
}

/// Camera folder.
open class ICCameraFolder: ICCameraItem {
    private var _contents: [ICCameraItem]?

    @_spi(OpenUIKitHost)
    public static func hostMakeFolder(
        name: String?,
        device: ICCameraDevice?,
        contents: [ICCameraItem]? = nil
    ) -> ICCameraFolder {
        let folder = ICCameraFolder(hostName: name, device: device, uti: "public.folder")
        folder._contents = contents
        if let items = contents {
            for item in items {
                item.hostSetParentFolder(folder)
            }
        }
        return folder
    }

    open var contents: [ICCameraItem]? { _contents }
}

/// Camera file. I/O, fingerprinting, and security-scoped URLs are
/// fail-closed. Offset/length arguments are validated before the
/// hardware boundary.
open class ICCameraFile: ICCameraItem {
    private var _fileSize: off_t = 0
    private var _width: Int = 0
    private var _height: Int = 0
    private var _duration: Double = 0
    private var _orientation: ICEXIFOrientationType = .orientation1
    private var _burstFavorite = false
    private var _burstPicked = false
    private var _firstPicked = false
    private var _highFramerate = false
    private var _timeLapse = false
    private var _burstUUID: String?
    private var _createdFilename: String?
    private var _originalFilename: String?
    private var _originatingAssetID: String?
    private var _groupUUID: String?
    private var _relatedUUID: String?
    private var _gpsString: String?
    private var _fingerprint: String?
    private var _pairedRawImage: ICCameraFile?
    private var _sidecarFiles: [ICCameraItem]?
    private var _exifCreationDate: Date?
    private var _exifModificationDate: Date?
    private var _fileCreationDate: Date?
    private var _fileModificationDate: Date?

    @_spi(OpenUIKitHost)
    public static func hostMakeFile(
        name: String?,
        device: ICCameraDevice?,
        uti: String? = "public.jpeg",
        fileSize: off_t = 0,
        width: Int = 0,
        height: Int = 0,
        duration: Double = 0,
        originalFilename: String? = nil
    ) -> ICCameraFile {
        let file = ICCameraFile(hostName: name, device: device, uti: uti)
        file._fileSize = fileSize
        file._width = width
        file._height = height
        file._duration = duration
        file._originalFilename = originalFilename
        file._createdFilename = name
        return file
    }

    open var fileSize: off_t { _fileSize }
    open var width: Int { _width }
    open var height: Int { _height }
    open var duration: Double { _duration }
    open var burstFavorite: Bool { _burstFavorite }
    open var burstPicked: Bool { _burstPicked }
    open var firstPicked: Bool { _firstPicked }
    open var highFramerate: Bool { _highFramerate }
    open var timeLapse: Bool { _timeLapse }
    open var burstUUID: String? { _burstUUID }
    open var createdFilename: String? { _createdFilename }
    open var originalFilename: String? { _originalFilename }
    open var originatingAssetID: String? { _originatingAssetID }
    open var groupUUID: String? { _groupUUID }
    open var relatedUUID: String? { _relatedUUID }
    open var gpsString: String? { _gpsString }
    open var fingerprint: String? { _fingerprint }
    open var pairedRawImage: ICCameraFile? { _pairedRawImage }
    open var sidecarFiles: [ICCameraItem]? { _sidecarFiles }
    open var exifCreationDate: Date? { _exifCreationDate }
    open var exifModificationDate: Date? { _exifModificationDate }
    open var fileCreationDate: Date? { _fileCreationDate }
    open var fileModificationDate: Date? { _fileModificationDate }

    open var orientation: ICEXIFOrientationType {
        get { _orientation }
        set { _orientation = newValue }
    }

    /// Apple's fingerprint algorithm is unobserved. Always `nil`.
    open class func fingerprintForFile(at url: URL) -> String? {
        _ = url
        return nil
    }

    open func requestDownload(
        options: [ICDownloadOption: Any]? = nil,
        completion: @escaping (String?, (any Error)?) -> Void
    ) -> Progress? {
        _ = options
        completion(nil, ICReturn(.downloadFailed))
        return nil
    }

    open func requestFingerprint(completion: @escaping (String?, (any Error)?) -> Void) {
        completion(nil, ICReturnObjectError(.codeObjectCouldNotBeRead))
    }

    open func requestMetadataDictionary(options: [ICCameraItemMetadataOption: Any]? = nil) async throws -> [AnyHashable: Any] {
        _ = options
        throw ICReturnMetadataError(.notAvailable)
    }

    /// Validates offset/length, then fail-closes: no camera bytes.
    open func requestReadData(atOffset offset: off_t, length: off_t) async throws -> Data {
        if offset < 0 {
            throw ICReturnObjectError(.codeObjectDataOffsetInvalid)
        }
        if length <= 0 {
            throw ICReturnObjectError(.codeObjectDataEmpty)
        }
        throw ICReturnObjectError(.codeObjectCouldNotBeRead)
    }

    /// Synchronous validation used by tests (the async overlay cannot
    /// run without a run loop). Same arithmetic as `requestReadData`.
    @_spi(OpenUIKitHost)
    public func hostReadDataError(atOffset offset: off_t, length: off_t) -> ICReturnObjectError.Code {
        if offset < 0 {
            return .codeObjectDataOffsetInvalid
        }
        if length <= 0 {
            return .codeObjectDataEmpty
        }
        return .codeObjectCouldNotBeRead
    }

    open func requestSecurityScopedURL(completion: @escaping (URL?, (any Error)?) -> Void) {
        completion(nil, ICReturn(.invalidParam))
    }

    open func requestThumbnailData(options: [ICCameraItemThumbnailOption: Any]? = nil) async throws -> Data {
        _ = options
        throw ICReturnThumbnailError(.notAvailable)
    }
}
