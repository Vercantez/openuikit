@_spi(OpenUIKitHost) import ImageCaptureCore
import Foundation

func testICDeviceTypeRawValues() {
    let cases: [(ICDeviceType, UInt)] = [
        (.camera, 0x00000001),
        (.scanner, 0x00000002),
    ]
    for (value, raw) in cases {
        precondition(value.rawValue == raw)
        precondition(ICDeviceType(rawValue: raw) == value)
        _ = value.hashValue
        var hasher = Hasher()
        value.hash(into: &hasher)
        _ = hasher.finalize()
    }
    precondition(ICDeviceType.camera != .scanner)
    precondition(ICDeviceType(rawValue: 0) == nil)
}

func testICDeviceTypeMaskRawValues() {
    let cases: [(ICDeviceTypeMask, UInt)] = [
        (.camera, 0x00000001),
        (.scanner, 0x00000002),
    ]
    for (value, raw) in cases {
        precondition(value.rawValue == raw)
        precondition(ICDeviceTypeMask(rawValue: raw) == value)
        _ = value.hashValue
        var hasher = Hasher()
        value.hash(into: &hasher)
        _ = hasher.finalize()
    }
    precondition(ICDeviceTypeMask.camera != .scanner)
    precondition(ICDeviceTypeMask(rawValue: 99) == nil)
}

func testICDeviceLocationTypeRawValues() {
    let cases: [(ICDeviceLocationType, UInt)] = [
        (.local, 0x00000100),
        (.shared, 0x00000200),
        (.bonjour, 0x00000400),
        (.bluetooth, 0x00000800),
    ]
    for (value, raw) in cases {
        precondition(value.rawValue == raw)
        precondition(ICDeviceLocationType(rawValue: raw) == value)
        _ = value.hashValue
        var hasher = Hasher()
        value.hash(into: &hasher)
        _ = hasher.finalize()
    }
    precondition(ICDeviceLocationType.local != .bluetooth)
    precondition(ICDeviceLocationType(rawValue: 1) == nil)
}

func testICDeviceLocationTypeMaskRawValues() {
    let cases: [(ICDeviceLocationTypeMask, UInt)] = [
        (.local, 0x00000100),
        (.shared, 0x00000200),
        (.bonjour, 0x00000400),
        (.bluetooth, 0x00000800),
        (.remote, 0x0000FE00),
    ]
    for (value, raw) in cases {
        precondition(value.rawValue == raw)
        precondition(ICDeviceLocationTypeMask(rawValue: raw) == value)
        _ = value.hashValue
        var hasher = Hasher()
        value.hash(into: &hasher)
        _ = hasher.finalize()
    }
    precondition(ICDeviceLocationTypeMask.local != .remote)
    precondition(ICDeviceLocationTypeMask(rawValue: 0) == nil)
}

func testICEXIFOrientationTypeRawValues() {
    let cases: [(ICEXIFOrientationType, UInt)] = [
        (.orientation1, 1),
        (.orientation2, 2),
        (.orientation3, 3),
        (.orientation4, 4),
        (.orientation5, 5),
        (.orientation6, 6),
        (.orientation7, 7),
        (.orientation8, 8),
    ]
    for (value, raw) in cases {
        precondition(value.rawValue == raw)
        precondition(ICEXIFOrientationType(rawValue: raw) == value)
        _ = value.hashValue
        var hasher = Hasher()
        value.hash(into: &hasher)
        _ = hasher.finalize()
    }
    precondition(ICEXIFOrientationType.orientation1 != .orientation8)
    precondition(ICEXIFOrientationType(rawValue: 0) == nil)
}

func testICMediaPresentationRawValues() {
    precondition(ICMediaPresentation.convertedAssets.rawValue == 1)
    precondition(ICMediaPresentation.originalAssets.rawValue == 2)
    precondition(ICMediaPresentation(rawValue: 1) == .convertedAssets)
    precondition(ICMediaPresentation(rawValue: 2) == .originalAssets)
    precondition(ICMediaPresentation.convertedAssets != .originalAssets)
    precondition(ICMediaPresentation(rawValue: 0) == nil)
    _ = ICMediaPresentation.convertedAssets.hashValue
    var hasher = Hasher()
    ICMediaPresentation.originalAssets.hash(into: &hasher)
    _ = hasher.finalize()
}

func testICReturnCodeOffsetRawValues() {
    let cases: [(ICReturnCodeOffset, Int)] = [
        (.thumbnailOffset, -21000),
        (.metadataOffset, -21050),
        (.downloadOffset, -21100),
        (.deleteOffset, -21150),
        (.exFATOffset, -21200),
        (.ptpOffset, -21250),
        (.systemOffset, -21300),
        (.deviceOffset, -21350),
        (.deviceConnection, -21400),
        (.objectOffset, -21450),
    ]
    for (value, raw) in cases {
        precondition(value.rawValue == raw)
        precondition(ICReturnCodeOffset(rawValue: raw) == value)
        _ = value.hashValue
        var hasher = Hasher()
        value.hash(into: &hasher)
        _ = hasher.finalize()
    }
    precondition(ICReturnCodeOffset.thumbnailOffset != .objectOffset)
    precondition(ICReturnCodeOffset(rawValue: 0) == nil)
}

func testICLegacyReturnCodeRawValues() {
    let cases: [(ICLegacyReturn.Code, Int)] = [
        (.communicationErr, -9900),
        (.deviceNotFoundErr, -9901),
        (.deviceNotOpenErr, -9902),
        (.fileCorruptedErr, -9903),
        (.ioPendingErr, -9904),
        (.invalidObjectErr, -9905),
        (.invalidPropertyErr, -9906),
        (.indexOutOfRangeErr, -9907),
        (.propertyTypeNotFoundErr, -9908),
        (.cannotYieldDevice, -9909),
        (.dataTypeNotFoundErr, -9910),
        (.deviceMemoryAllocationErr, -9911),
        (.deviceInternalErr, -9912),
        (.deviceInvalidParamErr, -9913),
        (.deviceAlreadyOpenErr, -9914),
        (.deviceLocationIDNotFoundErr, -9915),
        (.deviceGUIDNotFoundErr, -9916),
        (.deviceIOServicePathNotFoundErr, -9917),
        (.deviceUnsupportedErr, -9918),
        (.frameworkInternalErr, -9919),
        (.extensionInternalErr, -9920),
        (.invalidSessionErr, -9921),
    ]
    for (value, raw) in cases {
        precondition(value.rawValue == raw)
        precondition(ICLegacyReturn.Code(rawValue: raw) == value)
        _ = value.hashValue
        var hasher = Hasher()
        value.hash(into: &hasher)
        _ = hasher.finalize()
    }
    precondition(ICLegacyReturn.Code.communicationErr != .invalidSessionErr)
    precondition(ICLegacyReturn.Code(rawValue: 0) == nil)
}

func testICReturnCodeRawValues() {
    let cases: [(ICReturn.Code, Int)] = [
        (.success, 0),
        (.invalidParam, -9922),
        (.communicationTimedOut, -9923),
        (.scanOperationCanceled, -9924),
        (.scannerInUseByLocalUser, -9925),
        (.scannerInUseByRemoteUser, -9926),
        (.deviceFailedToOpenSession, -9927),
        (.deviceFailedToCloseSession, -9928),
        (.scannerFailedToSelectFunctionalUnit, -9929),
        (.scannerFailedToCompleteOverviewScan, -9930),
        (.scannerFailedToCompleteScan, -9931),
        (.receivedUnsolicitedScannerStatusInfo, -9932),
        (.receivedUnsolicitedScannerErrorInfo, -9933),
        (.downloadFailed, -9934),
        (.uploadFailed, -9935),
        (.failedToCompletePassThroughCommand, -9936),
        (.downloadCanceled, -9937),
        (.failedToEnabeTethering, -9938),
        (.failedToDisabeTethering, -9939),
        (.failedToCompleteSendMessageRequest, -9940),
        (.deleteFilesFailed, -9941),
        (.deleteFilesCanceled, -9942),
        (.deviceIsPasscodeLocked, -9943),
        (.deviceFailedToTakePicture, -9944),
        (.deviceSoftwareNotInstalled, -9945),
        (.deviceSoftwareIsBeingInstalled, -9946),
        (.deviceSoftwareInstallationCompleted, -9947),
        (.deviceSoftwareInstallationCanceled, -9948),
        (.deviceSoftwareInstallationFailed, -9949),
        (.deviceSoftwareNotAvailable, -9950),
        (.deviceCouldNotPair, -9951),
        (.deviceCouldNotUnpair, -9952),
        (.deviceNeedsCredentials, -9953),
        (.deviceIsBusyEnumerating, -9954),
        (.deviceCommandGeneralFailure, -9955),
        (.deviceFailedToCompleteTransfer, -9956),
        (.deviceFailedToSendData, -9957),
        (.sessionNotOpened, -9958),
        (.exFATVolumeInvalid, ICReturnCodeOffset.exFATOffset.rawValue),
        (.multiErrorDictionary, -30000),
    ]
    for (value, raw) in cases {
        precondition(value.rawValue == raw)
        precondition(ICReturn.Code(rawValue: raw) == value)
        _ = value.hashValue
        var hasher = Hasher()
        value.hash(into: &hasher)
        _ = hasher.finalize()
    }
    precondition(ICReturn.Code.success != .downloadFailed)
    precondition(ICReturn.Code(rawValue: 1) == nil)
}

func testICReturnConnectionErrorCodeRawValues() {
    let cases: [(ICReturnConnectionError.Code, Int)] = [
        (.driverExited, -21350),
        (.closedSessionSuddenly, -21349),
        (.ejectedSuddenly, -21348),
        (.sessionAlreadyOpen, -21347),
        (.ejectFailed, -21346),
        (.failedToOpen, -21400),
        (.failedToOpenDevice, -21399),
        (.notAuthorizedToOpenDevice, -21398),
    ]
    for (value, raw) in cases {
        precondition(value.rawValue == raw)
        precondition(ICReturnConnectionError.Code(rawValue: raw) == value)
        _ = value.hashValue
        var hasher = Hasher()
        value.hash(into: &hasher)
        _ = hasher.finalize()
    }
    precondition(ICReturnConnectionError.Code.driverExited != .ejectFailed)
    precondition(ICReturnConnectionError.Code(rawValue: 0) == nil)
}

func testICReturnDownloadErrorCodeRawValues() {
    precondition(ICReturnDownloadError.Code.pathInvalid.rawValue == -21100)
    precondition(ICReturnDownloadError.Code.fileWritable.rawValue == -21101)
    precondition(ICReturnDownloadError.Code(rawValue: -21100) == .pathInvalid)
    precondition(ICReturnDownloadError.Code(rawValue: -21101) == .fileWritable)
    precondition(ICReturnDownloadError.Code.pathInvalid != .fileWritable)
    precondition(ICReturnDownloadError.Code(rawValue: 0) == nil)
    _ = ICReturnDownloadError.Code.pathInvalid.hashValue
    var hasher = Hasher()
    ICReturnDownloadError.Code.fileWritable.hash(into: &hasher)
    _ = hasher.finalize()
}

func testICReturnMetadataErrorCodeRawValues() {
    let cases: [(ICReturnMetadataError.Code, Int)] = [
        (.notAvailable, -21050),
        (.alreadyFetching, -21051),
        (.canceled, -21052),
        (.invalid, -21053),
    ]
    for (value, raw) in cases {
        precondition(value.rawValue == raw)
        precondition(ICReturnMetadataError.Code(rawValue: raw) == value)
        _ = value.hashValue
        var hasher = Hasher()
        value.hash(into: &hasher)
        _ = hasher.finalize()
    }
    precondition(ICReturnMetadataError.Code.notAvailable != .invalid)
}

func testICReturnObjectErrorCodeRawValues() {
    let cases: [(ICReturnObjectError.Code, Int)] = [
        (.codeObjectDoesNotExist, -21450),
        (.codeObjectDataOffsetInvalid, -21449),
        (.codeObjectCouldNotBeRead, -21448),
        (.codeObjectDataEmpty, -21447),
        (.codeObjectDataRequestTooLarge, -21446),
    ]
    for (value, raw) in cases {
        precondition(value.rawValue == raw)
        precondition(ICReturnObjectError.Code(rawValue: raw) == value)
        _ = value.hashValue
        var hasher = Hasher()
        value.hash(into: &hasher)
        _ = hasher.finalize()
    }
    precondition(ICReturnObjectError.Code.codeObjectDoesNotExist != .codeObjectDataEmpty)
}

func testICReturnPTPDeviceErrorCodeRawValues() {
    precondition(ICReturnPTPDeviceError.Code.failedToSendCommand.rawValue == -21250)
    precondition(ICReturnPTPDeviceError.Code.notAuthorizedToSendCommand.rawValue == -21249)
    precondition(ICReturnPTPDeviceError.Code(rawValue: -21250) == .failedToSendCommand)
    precondition(ICReturnPTPDeviceError.Code.failedToSendCommand != .notAuthorizedToSendCommand)
    _ = ICReturnPTPDeviceError.Code.failedToSendCommand.hashValue
    var hasher = Hasher()
    ICReturnPTPDeviceError.Code.notAuthorizedToSendCommand.hash(into: &hasher)
    _ = hasher.finalize()
}

func testICReturnThumbnailErrorCodeRawValues() {
    let cases: [(ICReturnThumbnailError.Code, Int)] = [
        (.notAvailable, -21000),
        (.alreadyFetching, -21001),
        (.canceled, -21002),
        (.invalid, -21003),
    ]
    for (value, raw) in cases {
        precondition(value.rawValue == raw)
        precondition(ICReturnThumbnailError.Code(rawValue: raw) == value)
        _ = value.hashValue
        var hasher = Hasher()
        value.hash(into: &hasher)
        _ = hasher.finalize()
    }
    precondition(ICReturnThumbnailError.Code.notAvailable != .canceled)
}
