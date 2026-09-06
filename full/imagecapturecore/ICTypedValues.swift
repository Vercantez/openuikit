import Foundation

/// Authorization status strings. Raw values use the TBD export names.
public struct ICAuthorizationStatus: RawRepresentable, Hashable, Equatable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let authorized = ICAuthorizationStatus(rawValue: "ICAuthorizationStatusAuthorized")
    public static let denied = ICAuthorizationStatus(rawValue: "ICAuthorizationStatusDenied")
    public static let notDetermined = ICAuthorizationStatus(rawValue: "ICAuthorizationStatusNotDetermined")
    public static let restricted = ICAuthorizationStatus(rawValue: "ICAuthorizationStatusRestricted")
}

/// Device capability key. Raw values use the TBD export names.
public struct ICDeviceCapability: RawRepresentable, Hashable, Equatable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let canEjectOrDisconnect = ICDeviceCapability(rawValue: "ICDeviceCanEjectOrDisconnect")
    public static let cameraDeviceCanTakePicture = ICDeviceCapability(rawValue: "ICCameraDeviceCanTakePicture")
    public static let cameraDeviceCanTakePictureUsingShutterReleaseOnCamera = ICDeviceCapability(
        rawValue: "ICCameraDeviceCanTakePictureUsingShutterReleaseOnCamera"
    )
    public static let cameraDeviceCanDeleteOneFile = ICDeviceCapability(rawValue: "ICCameraDeviceCanDeleteOneFile")
    public static let cameraDeviceCanDeleteAllFiles = ICDeviceCapability(rawValue: "ICCameraDeviceCanDeleteAllFiles")
    public static let cameraDeviceCanSyncClock = ICDeviceCapability(rawValue: "ICCameraDeviceCanSyncClock")
    public static let cameraDeviceCanReceiveFile = ICDeviceCapability(rawValue: "ICCameraDeviceCanReceiveFile")
    public static let cameraDeviceCanAcceptPTPCommands = ICDeviceCapability(rawValue: "ICCameraDeviceCanAcceptPTPCommands")
    public static let cameraDeviceSupportsHEIF = ICDeviceCapability(rawValue: "ICCameraDeviceSupportsHEIF")
}

/// Location-description strings.
public struct ICDeviceLocationOptions: RawRepresentable, Hashable, Equatable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let descriptionUSB = ICDeviceLocationOptions(rawValue: "ICDeviceLocationDescriptionUSB")
    public static let descriptionFireWire = ICDeviceLocationOptions(rawValue: "ICDeviceLocationDescriptionFireWire")
    public static let descriptionBluetooth = ICDeviceLocationOptions(rawValue: "ICDeviceLocationDescriptionBluetooth")
    public static let descriptionMassStorage = ICDeviceLocationOptions(rawValue: "ICDeviceLocationDescriptionMassStorage")
}

/// Transport-type strings.
public struct ICDeviceTransport: RawRepresentable, Hashable, Equatable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let transportTypeUSB = ICDeviceTransport(rawValue: "ICTransportTypeUSB")
    public static let transportTypeMassStorage = ICDeviceTransport(rawValue: "ICTransportTypeMassStorage")
    public static let transportTypeTCPIP = ICDeviceTransport(rawValue: "ICTransportTypeTCPIP")
    public static let transportTypeProximity = ICDeviceTransport(rawValue: "ICTransportTypeProximity")
    public static let transportTypeExFAT = ICDeviceTransport(rawValue: "ICTransportTypeExFAT")
}

/// Download-option dictionary keys.
public struct ICDownloadOption: RawRepresentable, Hashable, Equatable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let downloadsDirectoryURL = ICDownloadOption(rawValue: "ICDownloadsDirectoryURL")
    public static let saveAsFilename = ICDownloadOption(rawValue: "ICSaveAsFilename")
    public static let savedFilename = ICDownloadOption(rawValue: "ICSavedFilename")
    public static let savedAncillaryFiles = ICDownloadOption(rawValue: "ICSavedAncillaryFiles")
    public static let overwrite = ICDownloadOption(rawValue: "ICOverwrite")
    public static let deleteAfterSuccessfulDownload = ICDownloadOption(rawValue: "ICDeleteAfterSuccessfulDownload")
    public static let sidecarFiles = ICDownloadOption(rawValue: "ICDownloadSidecarFiles")
    public static let truncateAfterSuccessfulDownload = ICDownloadOption(rawValue: "ICTruncateAfterSuccessfulDownload")
}

/// Session-option dictionary keys.
public struct ICSessionOptions: RawRepresentable, Hashable, Equatable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let enumerationChronologicalOrder = ICSessionOptions(rawValue: "ICEnumerationChronologicalOrder")
}

/// Upload-option dictionary keys. The iOS 26.1 overlay exports the type
/// and initializer without additional static members.
public struct ICUploadOption: RawRepresentable, Hashable, Equatable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

/// Per-file delete error keys.
public struct ICDeleteError: RawRepresentable, Hashable, Equatable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let canceled = ICDeleteError(rawValue: "ICDeleteErrorCanceled")
    public static let deviceMissing = ICDeleteError(rawValue: "ICDeleteErrorDeviceMissing")
    public static let fileMissing = ICDeleteError(rawValue: "ICDeleteErrorFileMissing")
    public static let readOnly = ICDeleteError(rawValue: "ICDeleteErrorReadOnly")
}

/// Delete-operation result keys.
public struct ICDeleteResult: RawRepresentable, Hashable, Equatable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let canceled = ICDeleteResult(rawValue: "ICDeleteCanceled")
    public static let failed = ICDeleteResult(rawValue: "ICDeleteFailed")
    public static let successful = ICDeleteResult(rawValue: "ICDeleteSuccessful")
}

/// Device status-dictionary keys.
public struct ICDeviceStatus: RawRepresentable, Hashable, Equatable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let statusNotificationKey = ICDeviceStatus(rawValue: "ICStatusNotificationKey")
}

/// Metadata-request option keys. The iOS overlay exports the type
/// without additional public static members.
public struct ICCameraItemMetadataOption: RawRepresentable, Hashable, Equatable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

/// Thumbnail-request option keys.
public struct ICCameraItemThumbnailOption: RawRepresentable, Hashable, Equatable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let imageSourceShouldCache = ICCameraItemThumbnailOption(rawValue: "ICImageSourceShouldCache")
    public static let imageSourceThumbnailMaxPixelSize = ICCameraItemThumbnailOption(
        rawValue: "ICImageSourceThumbnailMaxPixelSize"
    )
}
