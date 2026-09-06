import Foundation

/// Camera device.
///
/// Linux never attaches a PTP/USB camera. Catalog, tethered capture,
/// delete, download, and PTP commands fail-closed. `mediaPresentation`
/// and `ptpEventHandler` are stored process-locally.
open class ICCameraDevice: ICDevice {
    private var _batteryLevelAvailable = false
    private var _batteryLevel: UInt = 0
    private var _contentCatalogPercentCompleted: UInt = 0
    private var _contents: [ICCameraItem]?
    private var _mediaFiles: [ICCameraItem]?
    private var _isEjectable = false
    private var _isLocked = false
    private var _isAccessRestrictedAppleDevice = false
    private var _iCloudPhotosEnabled = false
    private var _tetheredCaptureEnabled = false
    private var _timeOffset: TimeInterval = 0
    private var _mediaPresentation: ICMediaPresentation = .convertedAssets
    private var _ptpEventHandler: (Data) -> Void = { _ in }

    @_spi(OpenUIKitHost)
    public static func hostMakeCamera(
        name: String? = nil,
        uuidString: String? = nil,
        capabilities: [String] = [],
        mediaPresentation: ICMediaPresentation = .convertedAssets,
        contents: [ICCameraItem]? = nil,
        mediaFiles: [ICCameraItem]? = nil
    ) -> ICCameraDevice {
        let camera = ICCameraDevice(hostType: .camera)
        camera.hostApplyIdentity(
            name: name,
            uuidString: uuidString,
            capabilities: capabilities
        )
        camera._mediaPresentation = mediaPresentation
        camera._contents = contents
        camera._mediaFiles = mediaFiles
        return camera
    }

    open var batteryLevelAvailable: Bool { _batteryLevelAvailable }
    open var batteryLevel: UInt { _batteryLevel }
    open var contentCatalogPercentCompleted: UInt { _contentCatalogPercentCompleted }
    open var contents: [ICCameraItem]? { _contents }
    open var mediaFiles: [ICCameraItem]? { _mediaFiles }
    open var isEjectable: Bool { _isEjectable }
    open var isLocked: Bool { _isLocked }
    open var isAccessRestrictedAppleDevice: Bool { _isAccessRestrictedAppleDevice }
    open var iCloudPhotosEnabled: Bool { _iCloudPhotosEnabled }
    open var tetheredCaptureEnabled: Bool { _tetheredCaptureEnabled }
    open var timeOffset: TimeInterval { _timeOffset }

    open var mediaPresentation: ICMediaPresentation {
        get { _mediaPresentation }
        set { _mediaPresentation = newValue }
    }

    open var ptpEventHandler: (Data) -> Void {
        get { _ptpEventHandler }
        set { _ptpEventHandler = newValue }
    }

    /// Empty catalog: no matching filenames. Empty UTI returns `nil`.
    open func files(ofType fileUTType: String) -> [String]? {
        if fileUTType.isEmpty {
            return nil
        }
        return []
    }

    open func requestDeleteFiles(_ files: [ICCameraItem]) {
        _ = files
        if let cameraDelegate = delegate as? any ICCameraDeviceDelegate {
            cameraDelegate.cameraDevice(self, didCompleteDeleteFilesWithError: ICReturn(.deleteFilesFailed))
        }
    }

    open func requestDeleteFiles(
        _ files: [ICCameraItem],
        deleteFailed: @escaping ([ICDeleteError: ICCameraItem]) -> Void,
        completion: @escaping ([ICDeleteResult: [ICCameraItem]], (any Error)?) -> Void
    ) -> Progress? {
        _ = files
        _ = deleteFailed
        completion([:], ICReturn(.deleteFilesFailed))
        return nil
    }

    open func requestDownloadFile(
        _ file: ICCameraFile,
        options: [ICDownloadOption: Any] = [:],
        downloadDelegate: any ICCameraDeviceDownloadDelegate,
        didDownloadSelector selector: Selector,
        contextInfo: UnsafeMutableRawPointer?
    ) {
        _ = options
        _ = selector
        let error = ICReturn(.downloadFailed)
        downloadDelegate.didDownloadFile(file, error: error, options: [:], contextInfo: contextInfo)
    }

    open func requestReadData(
        from file: ICCameraFile,
        atOffset offset: off_t,
        length: off_t,
        readDelegate: Any,
        didReadDataSelector selector: Selector,
        contextInfo: UnsafeMutableRawPointer?
    ) {
        _ = file
        _ = offset
        _ = length
        _ = readDelegate
        _ = selector
        _ = contextInfo
    }

    open func requestSendPTPCommand(_ ptpCommand: Data, outData ptpData: Data?) async throws -> (Data, Data) {
        _ = ptpCommand
        _ = ptpData
        throw ICReturnPTPDeviceError(.failedToSendCommand)
    }

    open func requestSendPTPCommand(
        _ command: Data,
        outData data: Data?,
        sendCommandDelegate: Any,
        didSendCommand selector: Selector,
        contextInfo: UnsafeMutableRawPointer?
    ) {
        _ = command
        _ = data
        _ = sendCommandDelegate
        _ = selector
        _ = contextInfo
    }
}

/// Camera item / file / folder delegate.
public protocol ICCameraDeviceDelegate: ICDeviceDelegate {
    func cameraDevice(_ camera: ICCameraDevice, didAdd items: [ICCameraItem])
    func cameraDevice(_ camera: ICCameraDevice, didRemove items: [ICCameraItem])
    func cameraDevice(_ camera: ICCameraDevice, didRenameItems items: [ICCameraItem])
    func cameraDevice(
        _ camera: ICCameraDevice,
        didReceiveMetadata metadata: [AnyHashable: Any]?,
        for item: ICCameraItem,
        error: (any Error)?
    )
    func cameraDevice(
        _ camera: ICCameraDevice,
        didReceiveThumbnail thumbnail: CGImage?,
        for item: ICCameraItem,
        error: (any Error)?
    )
    func cameraDevice(_ camera: ICCameraDevice, didReceivePTPEvent eventData: Data)
    func cameraDeviceDidChangeCapability(_ camera: ICCameraDevice)
    func cameraDeviceDidEnableAccessRestriction(_ device: ICDevice)
    func cameraDeviceDidRemoveAccessRestriction(_ device: ICDevice)
    func deviceDidBecomeReady(withCompleteContentCatalog device: ICCameraDevice)
    func cameraDevice(_ camera: ICCameraDevice, didAdd item: ICCameraItem)
    func cameraDevice(_ camera: ICCameraDevice, didRemove item: ICCameraItem)
    func cameraDevice(_ camera: ICCameraDevice, didCompleteDeleteFilesWithError error: (any Error)?)
    func cameraDevice(_ camera: ICCameraDevice, didReceiveMetadataFor item: ICCameraItem)
    func cameraDevice(_ camera: ICCameraDevice, didReceiveThumbnailFor item: ICCameraItem)
    func cameraDevice(_ cameraDevice: ICCameraDevice, shouldGetMetadataOf item: ICCameraItem) -> Bool
    func cameraDevice(_ cameraDevice: ICCameraDevice, shouldGetThumbnailOf item: ICCameraItem) -> Bool
}

extension ICCameraDeviceDelegate {
    public func cameraDevice(_ camera: ICCameraDevice, didAdd item: ICCameraItem) {
        cameraDevice(camera, didAdd: [item])
    }

    public func cameraDevice(_ camera: ICCameraDevice, didRemove item: ICCameraItem) {
        cameraDevice(camera, didRemove: [item])
    }

    public func cameraDevice(_ camera: ICCameraDevice, didCompleteDeleteFilesWithError error: (any Error)?) {
        _ = camera
        _ = error
    }

    public func cameraDevice(_ camera: ICCameraDevice, didReceiveMetadataFor item: ICCameraItem) {
        _ = camera
        _ = item
    }

    public func cameraDevice(_ camera: ICCameraDevice, didReceiveThumbnailFor item: ICCameraItem) {
        _ = camera
        _ = item
    }

    public func cameraDevice(_ cameraDevice: ICCameraDevice, shouldGetMetadataOf item: ICCameraItem) -> Bool {
        _ = cameraDevice
        _ = item
        return false
    }

    public func cameraDevice(_ cameraDevice: ICCameraDevice, shouldGetThumbnailOf item: ICCameraItem) -> Bool {
        _ = cameraDevice
        _ = item
        return false
    }
}

/// Download callbacks. Optional on Apple; empty defaults here.
public protocol ICCameraDeviceDownloadDelegate: NSObjectProtocol {
    func didDownloadFile(
        _ file: ICCameraFile,
        error: (any Error)?,
        options: [String: Any],
        contextInfo: UnsafeMutableRawPointer?
    )
    func didReceiveDownloadProgress(for file: ICCameraFile, downloadedBytes: off_t, maxBytes: off_t)
}

extension ICCameraDeviceDownloadDelegate {
    public func didDownloadFile(
        _ file: ICCameraFile,
        error: (any Error)?,
        options: [String: Any] = [:],
        contextInfo: UnsafeMutableRawPointer?
    ) {
        _ = file
        _ = error
        _ = options
        _ = contextInfo
    }

    public func didReceiveDownloadProgress(for file: ICCameraFile, downloadedBytes: off_t, maxBytes: off_t) {
        _ = file
        _ = downloadedBytes
        _ = maxBytes
    }
}
