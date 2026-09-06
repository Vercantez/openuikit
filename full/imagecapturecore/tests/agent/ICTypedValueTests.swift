@_spi(OpenUIKitHost) import ImageCaptureCore
import Foundation

func testICErrorDomainConstant() {
    precondition(ICErrorDomain == "com.apple.ImageCaptureCore")
}

func testICAuthorizationStatusValues() {
    let cases: [(ICAuthorizationStatus, String)] = [
        (.authorized, "ICAuthorizationStatusAuthorized"),
        (.denied, "ICAuthorizationStatusDenied"),
        (.notDetermined, "ICAuthorizationStatusNotDetermined"),
        (.restricted, "ICAuthorizationStatusRestricted"),
    ]
    for (value, raw) in cases {
        precondition(value.rawValue == raw)
        precondition(ICAuthorizationStatus(rawValue: raw) == value)
        _ = value.hashValue
        var hasher = Hasher()
        value.hash(into: &hasher)
        _ = hasher.finalize()
    }
    precondition(ICAuthorizationStatus.authorized != .denied)
}

func testICDeviceCapabilityValues() {
    let cases: [(ICDeviceCapability, String)] = [
        (.canEjectOrDisconnect, "ICDeviceCanEjectOrDisconnect"),
        (.cameraDeviceCanTakePicture, "ICCameraDeviceCanTakePicture"),
        (.cameraDeviceCanTakePictureUsingShutterReleaseOnCamera, "ICCameraDeviceCanTakePictureUsingShutterReleaseOnCamera"),
        (.cameraDeviceCanDeleteOneFile, "ICCameraDeviceCanDeleteOneFile"),
        (.cameraDeviceCanDeleteAllFiles, "ICCameraDeviceCanDeleteAllFiles"),
        (.cameraDeviceCanSyncClock, "ICCameraDeviceCanSyncClock"),
        (.cameraDeviceCanReceiveFile, "ICCameraDeviceCanReceiveFile"),
        (.cameraDeviceCanAcceptPTPCommands, "ICCameraDeviceCanAcceptPTPCommands"),
        (.cameraDeviceSupportsHEIF, "ICCameraDeviceSupportsHEIF"),
    ]
    for (value, raw) in cases {
        precondition(value.rawValue == raw)
        precondition(ICDeviceCapability(rawValue: raw) == value)
        _ = value.hashValue
        var hasher = Hasher()
        value.hash(into: &hasher)
        _ = hasher.finalize()
    }
    precondition(ICDeviceCapability.canEjectOrDisconnect != .cameraDeviceSupportsHEIF)
}

func testICDeviceLocationOptionsValues() {
    let cases: [(ICDeviceLocationOptions, String)] = [
        (.descriptionUSB, "ICDeviceLocationDescriptionUSB"),
        (.descriptionFireWire, "ICDeviceLocationDescriptionFireWire"),
        (.descriptionBluetooth, "ICDeviceLocationDescriptionBluetooth"),
        (.descriptionMassStorage, "ICDeviceLocationDescriptionMassStorage"),
    ]
    for (value, raw) in cases {
        precondition(value.rawValue == raw)
        precondition(ICDeviceLocationOptions(rawValue: raw) == value)
        _ = value.hashValue
        var hasher = Hasher()
        value.hash(into: &hasher)
        _ = hasher.finalize()
    }
    precondition(ICDeviceLocationOptions.descriptionUSB != .descriptionBluetooth)
}

func testICDeviceTransportValues() {
    let cases: [(ICDeviceTransport, String)] = [
        (.transportTypeUSB, "ICTransportTypeUSB"),
        (.transportTypeMassStorage, "ICTransportTypeMassStorage"),
        (.transportTypeTCPIP, "ICTransportTypeTCPIP"),
        (.transportTypeProximity, "ICTransportTypeProximity"),
        (.transportTypeExFAT, "ICTransportTypeExFAT"),
    ]
    for (value, raw) in cases {
        precondition(value.rawValue == raw)
        precondition(ICDeviceTransport(rawValue: raw) == value)
        _ = value.hashValue
        var hasher = Hasher()
        value.hash(into: &hasher)
        _ = hasher.finalize()
    }
    precondition(ICDeviceTransport.transportTypeUSB != .transportTypeExFAT)
}

func testICDownloadOptionValues() {
    let cases: [(ICDownloadOption, String)] = [
        (.downloadsDirectoryURL, "ICDownloadsDirectoryURL"),
        (.saveAsFilename, "ICSaveAsFilename"),
        (.savedFilename, "ICSavedFilename"),
        (.savedAncillaryFiles, "ICSavedAncillaryFiles"),
        (.overwrite, "ICOverwrite"),
        (.deleteAfterSuccessfulDownload, "ICDeleteAfterSuccessfulDownload"),
        (.sidecarFiles, "ICDownloadSidecarFiles"),
        (.truncateAfterSuccessfulDownload, "ICTruncateAfterSuccessfulDownload"),
    ]
    for (value, raw) in cases {
        precondition(value.rawValue == raw)
        precondition(ICDownloadOption(rawValue: raw) == value)
        _ = value.hashValue
        var hasher = Hasher()
        value.hash(into: &hasher)
        _ = hasher.finalize()
    }
    precondition(ICDownloadOption.overwrite != .sidecarFiles)
}

func testICSessionOptionsValues() {
    precondition(ICSessionOptions.enumerationChronologicalOrder.rawValue == "ICEnumerationChronologicalOrder")
    precondition(
        ICSessionOptions(rawValue: "ICEnumerationChronologicalOrder")
            == .enumerationChronologicalOrder
    )
    _ = ICSessionOptions.enumerationChronologicalOrder.hashValue
    var hasher = Hasher()
    ICSessionOptions.enumerationChronologicalOrder.hash(into: &hasher)
    _ = hasher.finalize()
    let other = ICSessionOptions(rawValue: "other")
    precondition(other != .enumerationChronologicalOrder)
}

func testICDeleteErrorValues() {
    let cases: [(ICDeleteError, String)] = [
        (.canceled, "ICDeleteErrorCanceled"),
        (.deviceMissing, "ICDeleteErrorDeviceMissing"),
        (.fileMissing, "ICDeleteErrorFileMissing"),
        (.readOnly, "ICDeleteErrorReadOnly"),
    ]
    for (value, raw) in cases {
        precondition(value.rawValue == raw)
        precondition(ICDeleteError(rawValue: raw) == value)
        _ = value.hashValue
        var hasher = Hasher()
        value.hash(into: &hasher)
        _ = hasher.finalize()
    }
    precondition(ICDeleteError.canceled != .readOnly)
}

func testICDeleteResultValues() {
    let cases: [(ICDeleteResult, String)] = [
        (.canceled, "ICDeleteCanceled"),
        (.failed, "ICDeleteFailed"),
        (.successful, "ICDeleteSuccessful"),
    ]
    for (value, raw) in cases {
        precondition(value.rawValue == raw)
        precondition(ICDeleteResult(rawValue: raw) == value)
        _ = value.hashValue
        var hasher = Hasher()
        value.hash(into: &hasher)
        _ = hasher.finalize()
    }
    precondition(ICDeleteResult.failed != .successful)
}

func testICDeviceStatusValues() {
    precondition(ICDeviceStatus.statusNotificationKey.rawValue == "ICStatusNotificationKey")
    precondition(ICDeviceStatus(rawValue: "ICStatusNotificationKey") == .statusNotificationKey)
    _ = ICDeviceStatus.statusNotificationKey.hashValue
    var hasher = Hasher()
    ICDeviceStatus.statusNotificationKey.hash(into: &hasher)
    _ = hasher.finalize()
    precondition(ICDeviceStatus(rawValue: "other") != .statusNotificationKey)
}

func testICCameraItemThumbnailOptionValues() {
    precondition(ICCameraItemThumbnailOption.imageSourceShouldCache.rawValue == "ICImageSourceShouldCache")
    precondition(
        ICCameraItemThumbnailOption.imageSourceThumbnailMaxPixelSize.rawValue
            == "ICImageSourceThumbnailMaxPixelSize"
    )
    precondition(
        ICCameraItemThumbnailOption(rawValue: "ICImageSourceShouldCache")
            == .imageSourceShouldCache
    )
    precondition(
        ICCameraItemThumbnailOption.imageSourceShouldCache
            != .imageSourceThumbnailMaxPixelSize
    )
    _ = ICCameraItemThumbnailOption.imageSourceShouldCache.hashValue
    var hasher = Hasher()
    ICCameraItemThumbnailOption.imageSourceThumbnailMaxPixelSize.hash(into: &hasher)
    _ = hasher.finalize()
}

func testICCameraItemMetadataOptionInit() {
    let option = ICCameraItemMetadataOption(rawValue: "custom")
    precondition(option.rawValue == "custom")
    precondition(option != ICCameraItemMetadataOption(rawValue: "other"))
    _ = option.hashValue
    var hasher = Hasher()
    option.hash(into: &hasher)
    _ = hasher.finalize()
}

func testICUploadOptionInit() {
    let option = ICUploadOption(rawValue: "upload")
    precondition(option.rawValue == "upload")
    precondition(option != ICUploadOption(rawValue: "other"))
    _ = option.hashValue
    var hasher = Hasher()
    option.hash(into: &hasher)
    _ = hasher.finalize()
}
