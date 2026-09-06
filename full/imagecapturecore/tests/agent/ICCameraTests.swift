@_spi(OpenUIKitHost) import ImageCaptureCore
import Foundation

final class HostCameraDelegate: NSObject, ICCameraDeviceDelegate {
    var deleted: [(ICCameraDevice, (any Error)?)] = []
    var added: [[ICCameraItem]] = []
    var removedItems: [[ICCameraItem]] = []
    var renamed: [[ICCameraItem]] = []
    var ptp: [Data] = []
    var capability = 0
    var restrictionEnabled = 0
    var restrictionRemoved = 0
    var catalogReady = 0
    var opened: [(ICDevice, (any Error)?)] = []
    var closed: [(ICDevice, (any Error)?)] = []
    var removedDevices: [ICDevice] = []

    func didRemove(_ device: ICDevice) {
        removedDevices.append(device)
    }

    func device(_ device: ICDevice, didOpenSessionWithError error: (any Error)?) {
        opened.append((device, error))
    }

    func device(_ device: ICDevice, didCloseSessionWithError error: (any Error)?) {
        closed.append((device, error))
    }

    func cameraDevice(_ camera: ICCameraDevice, didAdd items: [ICCameraItem]) {
        added.append(items)
    }

    func cameraDevice(_ camera: ICCameraDevice, didRemove items: [ICCameraItem]) {
        removedItems.append(items)
    }

    func cameraDevice(_ camera: ICCameraDevice, didRenameItems items: [ICCameraItem]) {
        renamed.append(items)
    }

    func cameraDevice(
        _ camera: ICCameraDevice,
        didReceiveMetadata metadata: [AnyHashable: Any]?,
        for item: ICCameraItem,
        error: (any Error)?
    ) {
        _ = camera
        _ = metadata
        _ = item
        _ = error
    }

    func cameraDevice(
        _ camera: ICCameraDevice,
        didReceiveThumbnail thumbnail: CGImage?,
        for item: ICCameraItem,
        error: (any Error)?
    ) {
        _ = camera
        _ = thumbnail
        _ = item
        _ = error
    }

    func cameraDevice(_ camera: ICCameraDevice, didReceivePTPEvent eventData: Data) {
        _ = camera
        ptp.append(eventData)
    }

    func cameraDeviceDidChangeCapability(_ camera: ICCameraDevice) {
        _ = camera
        capability += 1
    }

    func cameraDeviceDidEnableAccessRestriction(_ device: ICDevice) {
        _ = device
        restrictionEnabled += 1
    }

    func cameraDeviceDidRemoveAccessRestriction(_ device: ICDevice) {
        _ = device
        restrictionRemoved += 1
    }

    func deviceDidBecomeReady(withCompleteContentCatalog device: ICCameraDevice) {
        _ = device
        catalogReady += 1
    }

    func cameraDevice(_ camera: ICCameraDevice, didCompleteDeleteFilesWithError error: (any Error)?) {
        deleted.append((camera, error))
    }
}

final class HostDownloadDelegate: NSObject, ICCameraDeviceDownloadDelegate {
    var files: [ICCameraFile] = []
    var errors: [(any Error)?] = []
    var progressCalls = 0

    func didDownloadFile(
        _ file: ICCameraFile,
        error: (any Error)?,
        options: [String: Any],
        contextInfo: UnsafeMutableRawPointer?
    ) {
        _ = options
        _ = contextInfo
        files.append(file)
        errors.append(error)
    }

    func didReceiveDownloadProgress(for file: ICCameraFile, downloadedBytes: ImageCaptureCore.off_t, maxBytes: ImageCaptureCore.off_t) {
        _ = file
        _ = downloadedBytes
        _ = maxBytes
        progressCalls += 1
    }
}

func testICCameraDeviceHostProperties() {
    let camera = ICCameraDevice.hostMakeCamera(
        name: "EOS",
        uuidString: "cam-1",
        capabilities: [ICDeviceCapability.cameraDeviceCanTakePicture.rawValue]
    )
    precondition(camera.type == .camera)
    precondition(camera.name == "EOS")
    precondition(camera.uuidString == "cam-1")
    precondition(camera.capabilities == [ICDeviceCapability.cameraDeviceCanTakePicture.rawValue])
    precondition(!camera.batteryLevelAvailable)
    precondition(camera.batteryLevel == 0)
    precondition(camera.contentCatalogPercentCompleted == 0)
    precondition(camera.contents == nil)
    precondition(camera.mediaFiles == nil)
    precondition(!camera.isEjectable)
    precondition(!camera.isLocked)
    precondition(!camera.isAccessRestrictedAppleDevice)
    precondition(!camera.iCloudPhotosEnabled)
    precondition(!camera.tetheredCaptureEnabled)
    precondition(camera.timeOffset == 0)
    precondition(camera.mediaPresentation == .convertedAssets)
}

func testICCameraDeviceMediaPresentationAndPTPHandler() {
    let camera = ICCameraDevice.hostMakeCamera()
    camera.mediaPresentation = .originalAssets
    precondition(camera.mediaPresentation == .originalAssets)
    var seen = 0
    camera.ptpEventHandler = { data in
        seen = data.count
    }
    camera.ptpEventHandler(Data([1, 2, 3]))
    precondition(seen == 3)
}

func testICCameraDeviceFilesOfTypeEmpty() {
    let camera = ICCameraDevice.hostMakeCamera()
    precondition(camera.files(ofType: "") == nil)
    precondition(camera.files(ofType: "public.jpeg")?.isEmpty == true)
}

func testICCameraDeviceDeleteFilesFailClosed() {
    let camera = ICCameraDevice.hostMakeCamera()
    let delegate = HostCameraDelegate()
    camera.delegate = delegate
    let file = ICCameraFile.hostMakeFile(name: "IMG.JPG", device: camera)
    camera.requestDeleteFiles([file])
    precondition(delegate.deleted.count == 1)
    let error = delegate.deleted[0].1 as? ICReturn
    precondition(error?.code == .deleteFilesFailed)

    var completionError: (any Error)?
    var completionResult: [ICDeleteResult: [ICCameraItem]]?
    let progress = camera.requestDeleteFiles(
        [file],
        deleteFailed: { _ in
            preconditionFailure("deleteFailed must not run without hardware")
        },
        completion: { result, error in
            completionResult = result
            completionError = error
        }
    )
    precondition(progress == nil)
    precondition(completionResult?.isEmpty == true)
    precondition((completionError as? ICReturn)?.code == .deleteFilesFailed)
}

func testICCameraDeviceDownloadFailClosed() {
    let camera = ICCameraDevice.hostMakeCamera()
    let file = ICCameraFile.hostMakeFile(name: "IMG.JPG", device: camera)
    let download = HostDownloadDelegate()
    camera.requestDownloadFile(
        file,
        options: [.overwrite: true],
        downloadDelegate: download,
        didDownloadSelector: Selector("didDownloadFile:error:options:contextInfo:"),
        contextInfo: nil
    )
    precondition(download.files.count == 1)
    precondition((download.errors[0] as? ICReturn)?.code == .downloadFailed)
}

func testICCameraDeviceReadAndPTPSelectorFailClosed() {
    let camera = ICCameraDevice.hostMakeCamera()
    let file = ICCameraFile.hostMakeFile(name: "IMG.JPG", device: camera)
    camera.requestReadData(
        from: file,
        atOffset: 0,
        length: 10,
        readDelegate: NSObject(),
        didReadDataSelector: Selector("didReadData:fromFile:error:contextInfo:"),
        contextInfo: nil
    )
    camera.requestSendPTPCommand(
        Data([0x10]),
        outData: nil,
        sendCommandDelegate: NSObject(),
        didSendCommand: Selector("didSendPTPCommand:inData:response:error:contextInfo:"),
        contextInfo: nil
    )
}

func testICCameraItemHostPropertiesAndCache() {
    let camera = ICCameraDevice.hostMakeCamera(name: "EOS")
    let file = ICCameraFile.hostMakeFile(
        name: "IMG.JPG",
        device: camera,
        uti: "public.jpeg",
        fileSize: 1024,
        width: 100,
        height: 80,
        duration: 0,
        originalFilename: "DCIM.JPG"
    )
    file.hostSetDates(creation: Date(timeIntervalSince1970: 1), modification: Date(timeIntervalSince1970: 2))
    file.hostSetFlags(locked: true, raw: false, temporary: true, addedAfterCatalog: true)
    file.hostSetPTPObjectHandle(7)
    precondition(file.device === camera)
    precondition(file.name == "IMG.JPG")
    precondition(file.uti == "public.jpeg")
    precondition(file.fileSize == 1024)
    precondition(file.width == 100)
    precondition(file.height == 80)
    precondition(file.duration == 0)
    precondition(file.originalFilename == "DCIM.JPG")
    precondition(file.createdFilename == "IMG.JPG")
    precondition(file.isLocked)
    precondition(!file.isRaw)
    precondition(file.isInTemporaryStore)
    precondition(file.wasAddedAfterContentCatalogCompleted)
    precondition(file.ptpObjectHandle == 7)
    precondition(file.thumbnail == nil)
    precondition(file.thumbnailIfAvailable == nil)
    precondition(file.largeThumbnailIfAvailable == nil)
    precondition(file.metadata == nil)
    precondition(file.metadataIfAvailable == nil)
    file.userData?["note"] = 1
    precondition(file.userData?["note"] as? Int == 1)
    file.flushMetadataCache()
    file.flushThumbnailCache()
    file.requestMetadata()
    file.requestThumbnail()
    precondition(file.metadata == nil)
    precondition(file.thumbnail == nil)
}

func testICCameraFileRemainingProperties() {
    let file = ICCameraFile.hostMakeFile(name: "CLIP.MOV", device: nil, uti: "public.mpeg-4")
    precondition(!file.burstFavorite)
    precondition(!file.burstPicked)
    precondition(!file.firstPicked)
    precondition(!file.highFramerate)
    precondition(!file.timeLapse)
    precondition(file.burstUUID == nil)
    precondition(file.originatingAssetID == nil)
    precondition(file.groupUUID == nil)
    precondition(file.relatedUUID == nil)
    precondition(file.gpsString == nil)
    precondition(file.fingerprint == nil)
    precondition(file.pairedRawImage == nil)
    precondition(file.sidecarFiles == nil)
    precondition(file.exifCreationDate == nil)
    precondition(file.exifModificationDate == nil)
    precondition(file.fileCreationDate == nil)
    precondition(file.fileModificationDate == nil)
    file.orientation = .orientation6
    precondition(file.orientation == .orientation6)
}

func testICCameraFileDownloadAndFingerprintFailClosed() {
    let file = ICCameraFile.hostMakeFile(name: "IMG.JPG", device: nil)
    var name: String? = "unset"
    var error: (any Error)?
    let progress = file.requestDownload(options: [.overwrite: true]) { saved, err in
        name = saved
        error = err
    }
    precondition(progress == nil)
    precondition(name == nil)
    precondition((error as? ICReturn)?.code == .downloadFailed)

    var fingerprint: String? = "unset"
    var fingerError: (any Error)?
    file.requestFingerprint { value, err in
        fingerprint = value
        fingerError = err
    }
    precondition(fingerprint == nil)
    precondition((fingerError as? ICReturnObjectError)?.code == .codeObjectCouldNotBeRead)
    precondition(ICCameraFile.fingerprintForFile(at: URL(fileURLWithPath: "/tmp/nope")) == nil)
}

func testICCameraFileReadDataValidation() {
    let file = ICCameraFile.hostMakeFile(name: "IMG.JPG", device: nil)
    precondition(file.hostReadDataError(atOffset: -1, length: 10) == .codeObjectDataOffsetInvalid)
    precondition(file.hostReadDataError(atOffset: 0, length: 0) == .codeObjectDataEmpty)
    precondition(file.hostReadDataError(atOffset: 0, length: -4) == .codeObjectDataEmpty)
    precondition(file.hostReadDataError(atOffset: 0, length: 16) == .codeObjectCouldNotBeRead)
}

func testICCameraFileSecurityScopedURLFailClosed() {
    let file = ICCameraFile.hostMakeFile(name: "IMG.JPG", device: nil)
    var url: URL? = URL(fileURLWithPath: "/")
    var error: (any Error)?
    file.requestSecurityScopedURL { value, err in
        url = value
        error = err
    }
    precondition(url == nil)
    precondition((error as? ICReturn)?.code == .invalidParam)
}

func testICCameraFolderContents() {
    let camera = ICCameraDevice.hostMakeCamera()
    let child = ICCameraFile.hostMakeFile(name: "A.JPG", device: camera)
    let folder = ICCameraFolder.hostMakeFolder(name: "DCIM", device: camera, contents: [child])
    precondition(folder.name == "DCIM")
    precondition(folder.uti == "public.folder")
    precondition(folder.contents?.count == 1)
    precondition(child.parentFolder === folder)
    precondition(folder.device === camera)
}

func testICCameraDelegateOptionalAndRequired() {
    let camera = ICCameraDevice.hostMakeCamera()
    let delegate = HostCameraDelegate()
    let file = ICCameraFile.hostMakeFile(name: "IMG.JPG", device: camera)
    delegate.cameraDevice(camera, didAdd: file)
    delegate.cameraDevice(camera, didRemove: file)
    delegate.cameraDevice(camera, didRenameItems: [file])
    delegate.cameraDevice(camera, didReceivePTPEvent: Data([9]))
    delegate.cameraDeviceDidChangeCapability(camera)
    delegate.cameraDeviceDidEnableAccessRestriction(camera)
    delegate.cameraDeviceDidRemoveAccessRestriction(camera)
    delegate.deviceDidBecomeReady(withCompleteContentCatalog: camera)
    delegate.cameraDevice(camera, didReceiveMetadataFor: file)
    delegate.cameraDevice(camera, didReceiveThumbnailFor: file)
    precondition(delegate.cameraDevice(camera, shouldGetMetadataOf: file) == false)
    precondition(delegate.cameraDevice(camera, shouldGetThumbnailOf: file) == false)
    precondition(delegate.added.count == 1)
    precondition(delegate.removedItems.count == 1)
    precondition(delegate.renamed.count == 1)
    precondition(delegate.ptp.count == 1)
    precondition(delegate.capability == 1)
    precondition(delegate.restrictionEnabled == 1)
    precondition(delegate.restrictionRemoved == 1)
    precondition(delegate.catalogReady == 1)

    let download = HostDownloadDelegate()
    download.didReceiveDownloadProgress(for: file, downloadedBytes: 1, maxBytes: 2)
    precondition(download.progressCalls == 1)
}

func testICDeviceBrowserOptionalDelegateDefaults() {
    final class BrowserDelegate: NSObject, ICDeviceBrowserDelegate {
        var added = 0
        var removed = 0
        func deviceBrowser(_ browser: ICDeviceBrowser, didAdd device: ICDevice, moreComing: Bool) {
            _ = browser
            _ = device
            _ = moreComing
            added += 1
        }
        func deviceBrowser(_ browser: ICDeviceBrowser, didRemove device: ICDevice, moreGoing: Bool) {
            _ = browser
            _ = device
            _ = moreGoing
            removed += 1
        }
    }
    let browser = ICDeviceBrowser()
    let delegate = BrowserDelegate()
    browser.delegate = delegate
    let device = ICDevice.hostMakeDevice(type: .camera)
    delegate.deviceBrowser(browser, didAdd: device, moreComing: false)
    delegate.deviceBrowser(browser, didRemove: device, moreGoing: false)
    delegate.deviceBrowser(browser, deviceDidChangeName: device)
    delegate.deviceBrowser(browser, deviceDidChangeSharingState: device)
    delegate.deviceBrowserDidCancelSuspendOperations(browser)
    delegate.deviceBrowserDidResumeOperations(browser)
    delegate.deviceBrowserDidSuspendOperations(browser)
    delegate.deviceBrowserWillSuspendOperations(browser)
    precondition(delegate.added == 1)
    precondition(delegate.removed == 1)
}
