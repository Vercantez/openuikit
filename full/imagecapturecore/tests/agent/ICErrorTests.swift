@_spi(OpenUIKitHost) import ImageCaptureCore
import Foundation


func testICReturnConstruction() {
    let empty = ICReturn(.downloadFailed)
    precondition(empty.code == .downloadFailed)
    precondition(empty.errorCode == ICReturn.Code.downloadFailed.rawValue)
    precondition(ICReturn.errorDomain == ICErrorDomain)
    precondition(!empty.localizedDescription.isEmpty)
    precondition(empty.userInfo.isEmpty)
    precondition(empty.errorUserInfo.isEmpty)

    let sentinel = ICReturn(.invalidParam, userInfo: ["sentinel": "value"])
    precondition(sentinel.userInfo["sentinel"] as? String == "value")
    precondition(sentinel.errorUserInfo["sentinel"] as? String == "value")
    precondition(sentinel.code == .invalidParam)
    precondition(sentinel.errorCode == ICReturn.Code.invalidParam.rawValue)
}

func testICReturnEqualityAndHash() {
    let a = ICReturn(.downloadFailed)
    let b = ICReturn(.downloadFailed)
    let c = ICReturn(.invalidParam)
    precondition(a == b)
    precondition(a != c)
    let withInfo = ICReturn(.downloadFailed, userInfo: ["k": "v"])
    precondition(a != withInfo)
    var hasherA = Hasher()
    var hasherB = Hasher()
    a.hash(into: &hasherA)
    b.hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())
    precondition(a.hashValue == b.hashValue)
}

func testICReturnPatternMatch() {
    let typed = ICReturn(.downloadFailed)
    precondition(ICReturn.Code.downloadFailed ~= typed)
    let ns = typed as NSError
    precondition(ns.domain == ICErrorDomain)
    precondition(ns.code == ICReturn.Code.downloadFailed.rawValue)
    precondition(ICReturn.Code.downloadFailed ~= ns)
    precondition(!(ICReturn.Code.invalidParam ~= typed))
}

func testICReturnStaticCodeAliases() {
    precondition(ICReturn.success == ICReturn.Code.success)
    precondition(ICReturn.invalidParam == ICReturn.Code.invalidParam)
    precondition(ICReturn.communicationTimedOut == ICReturn.Code.communicationTimedOut)
    precondition(ICReturn.scanOperationCanceled == ICReturn.Code.scanOperationCanceled)
    precondition(ICReturn.scannerInUseByLocalUser == ICReturn.Code.scannerInUseByLocalUser)
    precondition(ICReturn.scannerInUseByRemoteUser == ICReturn.Code.scannerInUseByRemoteUser)
    precondition(ICReturn.deviceFailedToOpenSession == ICReturn.Code.deviceFailedToOpenSession)
    precondition(ICReturn.deviceFailedToCloseSession == ICReturn.Code.deviceFailedToCloseSession)
    precondition(ICReturn.scannerFailedToSelectFunctionalUnit == ICReturn.Code.scannerFailedToSelectFunctionalUnit)
    precondition(ICReturn.scannerFailedToCompleteOverviewScan == ICReturn.Code.scannerFailedToCompleteOverviewScan)
    precondition(ICReturn.scannerFailedToCompleteScan == ICReturn.Code.scannerFailedToCompleteScan)
    precondition(ICReturn.receivedUnsolicitedScannerStatusInfo == ICReturn.Code.receivedUnsolicitedScannerStatusInfo)
    precondition(ICReturn.receivedUnsolicitedScannerErrorInfo == ICReturn.Code.receivedUnsolicitedScannerErrorInfo)
    precondition(ICReturn.downloadFailed == ICReturn.Code.downloadFailed)
    precondition(ICReturn.uploadFailed == ICReturn.Code.uploadFailed)
    precondition(ICReturn.failedToCompletePassThroughCommand == ICReturn.Code.failedToCompletePassThroughCommand)
    precondition(ICReturn.downloadCanceled == ICReturn.Code.downloadCanceled)
    precondition(ICReturn.failedToEnabeTethering == ICReturn.Code.failedToEnabeTethering)
    precondition(ICReturn.failedToDisabeTethering == ICReturn.Code.failedToDisabeTethering)
    precondition(ICReturn.failedToCompleteSendMessageRequest == ICReturn.Code.failedToCompleteSendMessageRequest)
    precondition(ICReturn.deleteFilesFailed == ICReturn.Code.deleteFilesFailed)
    precondition(ICReturn.deleteFilesCanceled == ICReturn.Code.deleteFilesCanceled)
    precondition(ICReturn.deviceIsPasscodeLocked == ICReturn.Code.deviceIsPasscodeLocked)
    precondition(ICReturn.deviceFailedToTakePicture == ICReturn.Code.deviceFailedToTakePicture)
    precondition(ICReturn.deviceSoftwareNotInstalled == ICReturn.Code.deviceSoftwareNotInstalled)
    precondition(ICReturn.deviceSoftwareIsBeingInstalled == ICReturn.Code.deviceSoftwareIsBeingInstalled)
    precondition(ICReturn.deviceSoftwareInstallationCompleted == ICReturn.Code.deviceSoftwareInstallationCompleted)
    precondition(ICReturn.deviceSoftwareInstallationCanceled == ICReturn.Code.deviceSoftwareInstallationCanceled)
    precondition(ICReturn.deviceSoftwareInstallationFailed == ICReturn.Code.deviceSoftwareInstallationFailed)
    precondition(ICReturn.deviceSoftwareNotAvailable == ICReturn.Code.deviceSoftwareNotAvailable)
    precondition(ICReturn.deviceCouldNotPair == ICReturn.Code.deviceCouldNotPair)
    precondition(ICReturn.deviceCouldNotUnpair == ICReturn.Code.deviceCouldNotUnpair)
    precondition(ICReturn.deviceNeedsCredentials == ICReturn.Code.deviceNeedsCredentials)
    precondition(ICReturn.deviceIsBusyEnumerating == ICReturn.Code.deviceIsBusyEnumerating)
    precondition(ICReturn.deviceCommandGeneralFailure == ICReturn.Code.deviceCommandGeneralFailure)
    precondition(ICReturn.deviceFailedToCompleteTransfer == ICReturn.Code.deviceFailedToCompleteTransfer)
    precondition(ICReturn.deviceFailedToSendData == ICReturn.Code.deviceFailedToSendData)
    precondition(ICReturn.sessionNotOpened == ICReturn.Code.sessionNotOpened)
    precondition(ICReturn.exFATVolumeInvalid == ICReturn.Code.exFATVolumeInvalid)
    precondition(ICReturn.multiErrorDictionary == ICReturn.Code.multiErrorDictionary)
}


func testICLegacyReturnConstruction() {
    let empty = ICLegacyReturn(.communicationErr)
    precondition(empty.code == .communicationErr)
    precondition(empty.errorCode == ICLegacyReturn.Code.communicationErr.rawValue)
    precondition(ICLegacyReturn.errorDomain == ICErrorDomain)
    precondition(!empty.localizedDescription.isEmpty)
    precondition(empty.userInfo.isEmpty)
    precondition(empty.errorUserInfo.isEmpty)

    let sentinel = ICLegacyReturn(.deviceNotFoundErr, userInfo: ["sentinel": "value"])
    precondition(sentinel.userInfo["sentinel"] as? String == "value")
    precondition(sentinel.errorUserInfo["sentinel"] as? String == "value")
    precondition(sentinel.code == .deviceNotFoundErr)
    precondition(sentinel.errorCode == ICLegacyReturn.Code.deviceNotFoundErr.rawValue)
}

func testICLegacyReturnEqualityAndHash() {
    let a = ICLegacyReturn(.communicationErr)
    let b = ICLegacyReturn(.communicationErr)
    let c = ICLegacyReturn(.deviceNotFoundErr)
    precondition(a == b)
    precondition(a != c)
    let withInfo = ICLegacyReturn(.communicationErr, userInfo: ["k": "v"])
    precondition(a != withInfo)
    var hasherA = Hasher()
    var hasherB = Hasher()
    a.hash(into: &hasherA)
    b.hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())
    precondition(a.hashValue == b.hashValue)
}

func testICLegacyReturnPatternMatch() {
    let typed = ICLegacyReturn(.communicationErr)
    precondition(ICLegacyReturn.Code.communicationErr ~= typed)
    let ns = typed as NSError
    precondition(ns.domain == ICErrorDomain)
    precondition(ns.code == ICLegacyReturn.Code.communicationErr.rawValue)
    precondition(ICLegacyReturn.Code.communicationErr ~= ns)
    precondition(!(ICLegacyReturn.Code.deviceNotFoundErr ~= typed))
}

func testICLegacyReturnStaticCodeAliases() {
    precondition(ICLegacyReturn.communicationErr == ICLegacyReturn.Code.communicationErr)
    precondition(ICLegacyReturn.deviceNotFoundErr == ICLegacyReturn.Code.deviceNotFoundErr)
    precondition(ICLegacyReturn.deviceNotOpenErr == ICLegacyReturn.Code.deviceNotOpenErr)
    precondition(ICLegacyReturn.fileCorruptedErr == ICLegacyReturn.Code.fileCorruptedErr)
    precondition(ICLegacyReturn.ioPendingErr == ICLegacyReturn.Code.ioPendingErr)
    precondition(ICLegacyReturn.invalidObjectErr == ICLegacyReturn.Code.invalidObjectErr)
    precondition(ICLegacyReturn.invalidPropertyErr == ICLegacyReturn.Code.invalidPropertyErr)
    precondition(ICLegacyReturn.indexOutOfRangeErr == ICLegacyReturn.Code.indexOutOfRangeErr)
    precondition(ICLegacyReturn.propertyTypeNotFoundErr == ICLegacyReturn.Code.propertyTypeNotFoundErr)
    precondition(ICLegacyReturn.cannotYieldDevice == ICLegacyReturn.Code.cannotYieldDevice)
    precondition(ICLegacyReturn.dataTypeNotFoundErr == ICLegacyReturn.Code.dataTypeNotFoundErr)
    precondition(ICLegacyReturn.deviceMemoryAllocationErr == ICLegacyReturn.Code.deviceMemoryAllocationErr)
    precondition(ICLegacyReturn.deviceInternalErr == ICLegacyReturn.Code.deviceInternalErr)
    precondition(ICLegacyReturn.deviceInvalidParamErr == ICLegacyReturn.Code.deviceInvalidParamErr)
    precondition(ICLegacyReturn.deviceAlreadyOpenErr == ICLegacyReturn.Code.deviceAlreadyOpenErr)
    precondition(ICLegacyReturn.deviceLocationIDNotFoundErr == ICLegacyReturn.Code.deviceLocationIDNotFoundErr)
    precondition(ICLegacyReturn.deviceGUIDNotFoundErr == ICLegacyReturn.Code.deviceGUIDNotFoundErr)
    precondition(ICLegacyReturn.deviceIOServicePathNotFoundErr == ICLegacyReturn.Code.deviceIOServicePathNotFoundErr)
    precondition(ICLegacyReturn.deviceUnsupportedErr == ICLegacyReturn.Code.deviceUnsupportedErr)
    precondition(ICLegacyReturn.frameworkInternalErr == ICLegacyReturn.Code.frameworkInternalErr)
    precondition(ICLegacyReturn.extensionInternalErr == ICLegacyReturn.Code.extensionInternalErr)
    precondition(ICLegacyReturn.invalidSessionErr == ICLegacyReturn.Code.invalidSessionErr)
}


func testICReturnConnectionErrorConstruction() {
    let empty = ICReturnConnectionError(.ejectFailed)
    precondition(empty.code == .ejectFailed)
    precondition(empty.errorCode == ICReturnConnectionError.Code.ejectFailed.rawValue)
    precondition(ICReturnConnectionError.errorDomain == ICErrorDomain)
    precondition(!empty.localizedDescription.isEmpty)
    precondition(empty.userInfo.isEmpty)
    precondition(empty.errorUserInfo.isEmpty)

    let sentinel = ICReturnConnectionError(.driverExited, userInfo: ["sentinel": "value"])
    precondition(sentinel.userInfo["sentinel"] as? String == "value")
    precondition(sentinel.errorUserInfo["sentinel"] as? String == "value")
    precondition(sentinel.code == .driverExited)
    precondition(sentinel.errorCode == ICReturnConnectionError.Code.driverExited.rawValue)
}

func testICReturnConnectionErrorEqualityAndHash() {
    let a = ICReturnConnectionError(.ejectFailed)
    let b = ICReturnConnectionError(.ejectFailed)
    let c = ICReturnConnectionError(.driverExited)
    precondition(a == b)
    precondition(a != c)
    let withInfo = ICReturnConnectionError(.ejectFailed, userInfo: ["k": "v"])
    precondition(a != withInfo)
    var hasherA = Hasher()
    var hasherB = Hasher()
    a.hash(into: &hasherA)
    b.hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())
    precondition(a.hashValue == b.hashValue)
}

func testICReturnConnectionErrorPatternMatch() {
    let typed = ICReturnConnectionError(.ejectFailed)
    precondition(ICReturnConnectionError.Code.ejectFailed ~= typed)
    let ns = typed as NSError
    precondition(ns.domain == ICErrorDomain)
    precondition(ns.code == ICReturnConnectionError.Code.ejectFailed.rawValue)
    precondition(ICReturnConnectionError.Code.ejectFailed ~= ns)
    precondition(!(ICReturnConnectionError.Code.driverExited ~= typed))
}

func testICReturnConnectionErrorStaticCodeAliases() {
    precondition(ICReturnConnectionError.driverExited == ICReturnConnectionError.Code.driverExited)
    precondition(ICReturnConnectionError.closedSessionSuddenly == ICReturnConnectionError.Code.closedSessionSuddenly)
    precondition(ICReturnConnectionError.ejectedSuddenly == ICReturnConnectionError.Code.ejectedSuddenly)
    precondition(ICReturnConnectionError.sessionAlreadyOpen == ICReturnConnectionError.Code.sessionAlreadyOpen)
    precondition(ICReturnConnectionError.ejectFailed == ICReturnConnectionError.Code.ejectFailed)
    precondition(ICReturnConnectionError.failedToOpen == ICReturnConnectionError.Code.failedToOpen)
    precondition(ICReturnConnectionError.failedToOpenDevice == ICReturnConnectionError.Code.failedToOpenDevice)
    precondition(ICReturnConnectionError.notAuthorizedToOpenDevice == ICReturnConnectionError.Code.notAuthorizedToOpenDevice)
}


func testICReturnDownloadErrorConstruction() {
    let empty = ICReturnDownloadError(.pathInvalid)
    precondition(empty.code == .pathInvalid)
    precondition(empty.errorCode == ICReturnDownloadError.Code.pathInvalid.rawValue)
    precondition(ICReturnDownloadError.errorDomain == ICErrorDomain)
    precondition(!empty.localizedDescription.isEmpty)
    precondition(empty.userInfo.isEmpty)
    precondition(empty.errorUserInfo.isEmpty)

    let sentinel = ICReturnDownloadError(.fileWritable, userInfo: ["sentinel": "value"])
    precondition(sentinel.userInfo["sentinel"] as? String == "value")
    precondition(sentinel.errorUserInfo["sentinel"] as? String == "value")
    precondition(sentinel.code == .fileWritable)
    precondition(sentinel.errorCode == ICReturnDownloadError.Code.fileWritable.rawValue)
}

func testICReturnDownloadErrorEqualityAndHash() {
    let a = ICReturnDownloadError(.pathInvalid)
    let b = ICReturnDownloadError(.pathInvalid)
    let c = ICReturnDownloadError(.fileWritable)
    precondition(a == b)
    precondition(a != c)
    let withInfo = ICReturnDownloadError(.pathInvalid, userInfo: ["k": "v"])
    precondition(a != withInfo)
    var hasherA = Hasher()
    var hasherB = Hasher()
    a.hash(into: &hasherA)
    b.hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())
    precondition(a.hashValue == b.hashValue)
}

func testICReturnDownloadErrorPatternMatch() {
    let typed = ICReturnDownloadError(.pathInvalid)
    precondition(ICReturnDownloadError.Code.pathInvalid ~= typed)
    let ns = typed as NSError
    precondition(ns.domain == ICErrorDomain)
    precondition(ns.code == ICReturnDownloadError.Code.pathInvalid.rawValue)
    precondition(ICReturnDownloadError.Code.pathInvalid ~= ns)
    precondition(!(ICReturnDownloadError.Code.fileWritable ~= typed))
}

func testICReturnDownloadErrorStaticCodeAliases() {
    precondition(ICReturnDownloadError.pathInvalid == ICReturnDownloadError.Code.pathInvalid)
    precondition(ICReturnDownloadError.fileWritable == ICReturnDownloadError.Code.fileWritable)
}


func testICReturnMetadataErrorConstruction() {
    let empty = ICReturnMetadataError(.notAvailable)
    precondition(empty.code == .notAvailable)
    precondition(empty.errorCode == ICReturnMetadataError.Code.notAvailable.rawValue)
    precondition(ICReturnMetadataError.errorDomain == ICErrorDomain)
    precondition(!empty.localizedDescription.isEmpty)
    precondition(empty.userInfo.isEmpty)
    precondition(empty.errorUserInfo.isEmpty)

    let sentinel = ICReturnMetadataError(.canceled, userInfo: ["sentinel": "value"])
    precondition(sentinel.userInfo["sentinel"] as? String == "value")
    precondition(sentinel.errorUserInfo["sentinel"] as? String == "value")
    precondition(sentinel.code == .canceled)
    precondition(sentinel.errorCode == ICReturnMetadataError.Code.canceled.rawValue)
}

func testICReturnMetadataErrorEqualityAndHash() {
    let a = ICReturnMetadataError(.notAvailable)
    let b = ICReturnMetadataError(.notAvailable)
    let c = ICReturnMetadataError(.canceled)
    precondition(a == b)
    precondition(a != c)
    let withInfo = ICReturnMetadataError(.notAvailable, userInfo: ["k": "v"])
    precondition(a != withInfo)
    var hasherA = Hasher()
    var hasherB = Hasher()
    a.hash(into: &hasherA)
    b.hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())
    precondition(a.hashValue == b.hashValue)
}

func testICReturnMetadataErrorPatternMatch() {
    let typed = ICReturnMetadataError(.notAvailable)
    precondition(ICReturnMetadataError.Code.notAvailable ~= typed)
    let ns = typed as NSError
    precondition(ns.domain == ICErrorDomain)
    precondition(ns.code == ICReturnMetadataError.Code.notAvailable.rawValue)
    precondition(ICReturnMetadataError.Code.notAvailable ~= ns)
    precondition(!(ICReturnMetadataError.Code.canceled ~= typed))
}

func testICReturnMetadataErrorStaticCodeAliases() {
    precondition(ICReturnMetadataError.notAvailable == ICReturnMetadataError.Code.notAvailable)
    precondition(ICReturnMetadataError.alreadyFetching == ICReturnMetadataError.Code.alreadyFetching)
    precondition(ICReturnMetadataError.canceled == ICReturnMetadataError.Code.canceled)
    precondition(ICReturnMetadataError.invalid == ICReturnMetadataError.Code.invalid)
}


func testICReturnObjectErrorConstruction() {
    let empty = ICReturnObjectError(.codeObjectCouldNotBeRead)
    precondition(empty.code == .codeObjectCouldNotBeRead)
    precondition(empty.errorCode == ICReturnObjectError.Code.codeObjectCouldNotBeRead.rawValue)
    precondition(ICReturnObjectError.errorDomain == ICErrorDomain)
    precondition(!empty.localizedDescription.isEmpty)
    precondition(empty.userInfo.isEmpty)
    precondition(empty.errorUserInfo.isEmpty)

    let sentinel = ICReturnObjectError(.codeObjectDataEmpty, userInfo: ["sentinel": "value"])
    precondition(sentinel.userInfo["sentinel"] as? String == "value")
    precondition(sentinel.errorUserInfo["sentinel"] as? String == "value")
    precondition(sentinel.code == .codeObjectDataEmpty)
    precondition(sentinel.errorCode == ICReturnObjectError.Code.codeObjectDataEmpty.rawValue)
}

func testICReturnObjectErrorEqualityAndHash() {
    let a = ICReturnObjectError(.codeObjectCouldNotBeRead)
    let b = ICReturnObjectError(.codeObjectCouldNotBeRead)
    let c = ICReturnObjectError(.codeObjectDataEmpty)
    precondition(a == b)
    precondition(a != c)
    let withInfo = ICReturnObjectError(.codeObjectCouldNotBeRead, userInfo: ["k": "v"])
    precondition(a != withInfo)
    var hasherA = Hasher()
    var hasherB = Hasher()
    a.hash(into: &hasherA)
    b.hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())
    precondition(a.hashValue == b.hashValue)
}

func testICReturnObjectErrorPatternMatch() {
    let typed = ICReturnObjectError(.codeObjectCouldNotBeRead)
    precondition(ICReturnObjectError.Code.codeObjectCouldNotBeRead ~= typed)
    let ns = typed as NSError
    precondition(ns.domain == ICErrorDomain)
    precondition(ns.code == ICReturnObjectError.Code.codeObjectCouldNotBeRead.rawValue)
    precondition(ICReturnObjectError.Code.codeObjectCouldNotBeRead ~= ns)
    precondition(!(ICReturnObjectError.Code.codeObjectDataEmpty ~= typed))
}

func testICReturnObjectErrorStaticCodeAliases() {
    precondition(ICReturnObjectError.codeObjectDoesNotExist == ICReturnObjectError.Code.codeObjectDoesNotExist)
    precondition(ICReturnObjectError.codeObjectDataOffsetInvalid == ICReturnObjectError.Code.codeObjectDataOffsetInvalid)
    precondition(ICReturnObjectError.codeObjectCouldNotBeRead == ICReturnObjectError.Code.codeObjectCouldNotBeRead)
    precondition(ICReturnObjectError.codeObjectDataEmpty == ICReturnObjectError.Code.codeObjectDataEmpty)
    precondition(ICReturnObjectError.codeObjectDataRequestTooLarge == ICReturnObjectError.Code.codeObjectDataRequestTooLarge)
}


func testICReturnPTPDeviceErrorConstruction() {
    let empty = ICReturnPTPDeviceError(.failedToSendCommand)
    precondition(empty.code == .failedToSendCommand)
    precondition(empty.errorCode == ICReturnPTPDeviceError.Code.failedToSendCommand.rawValue)
    precondition(ICReturnPTPDeviceError.errorDomain == ICErrorDomain)
    precondition(!empty.localizedDescription.isEmpty)
    precondition(empty.userInfo.isEmpty)
    precondition(empty.errorUserInfo.isEmpty)

    let sentinel = ICReturnPTPDeviceError(.notAuthorizedToSendCommand, userInfo: ["sentinel": "value"])
    precondition(sentinel.userInfo["sentinel"] as? String == "value")
    precondition(sentinel.errorUserInfo["sentinel"] as? String == "value")
    precondition(sentinel.code == .notAuthorizedToSendCommand)
    precondition(sentinel.errorCode == ICReturnPTPDeviceError.Code.notAuthorizedToSendCommand.rawValue)
}

func testICReturnPTPDeviceErrorEqualityAndHash() {
    let a = ICReturnPTPDeviceError(.failedToSendCommand)
    let b = ICReturnPTPDeviceError(.failedToSendCommand)
    let c = ICReturnPTPDeviceError(.notAuthorizedToSendCommand)
    precondition(a == b)
    precondition(a != c)
    let withInfo = ICReturnPTPDeviceError(.failedToSendCommand, userInfo: ["k": "v"])
    precondition(a != withInfo)
    var hasherA = Hasher()
    var hasherB = Hasher()
    a.hash(into: &hasherA)
    b.hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())
    precondition(a.hashValue == b.hashValue)
}

func testICReturnPTPDeviceErrorPatternMatch() {
    let typed = ICReturnPTPDeviceError(.failedToSendCommand)
    precondition(ICReturnPTPDeviceError.Code.failedToSendCommand ~= typed)
    let ns = typed as NSError
    precondition(ns.domain == ICErrorDomain)
    precondition(ns.code == ICReturnPTPDeviceError.Code.failedToSendCommand.rawValue)
    precondition(ICReturnPTPDeviceError.Code.failedToSendCommand ~= ns)
    precondition(!(ICReturnPTPDeviceError.Code.notAuthorizedToSendCommand ~= typed))
}

func testICReturnPTPDeviceErrorStaticCodeAliases() {
    precondition(ICReturnPTPDeviceError.failedToSendCommand == ICReturnPTPDeviceError.Code.failedToSendCommand)
    precondition(ICReturnPTPDeviceError.notAuthorizedToSendCommand == ICReturnPTPDeviceError.Code.notAuthorizedToSendCommand)
}


func testICReturnThumbnailErrorConstruction() {
    let empty = ICReturnThumbnailError(.notAvailable)
    precondition(empty.code == .notAvailable)
    precondition(empty.errorCode == ICReturnThumbnailError.Code.notAvailable.rawValue)
    precondition(ICReturnThumbnailError.errorDomain == ICErrorDomain)
    precondition(!empty.localizedDescription.isEmpty)
    precondition(empty.userInfo.isEmpty)
    precondition(empty.errorUserInfo.isEmpty)

    let sentinel = ICReturnThumbnailError(.invalid, userInfo: ["sentinel": "value"])
    precondition(sentinel.userInfo["sentinel"] as? String == "value")
    precondition(sentinel.errorUserInfo["sentinel"] as? String == "value")
    precondition(sentinel.code == .invalid)
    precondition(sentinel.errorCode == ICReturnThumbnailError.Code.invalid.rawValue)
}

func testICReturnThumbnailErrorEqualityAndHash() {
    let a = ICReturnThumbnailError(.notAvailable)
    let b = ICReturnThumbnailError(.notAvailable)
    let c = ICReturnThumbnailError(.invalid)
    precondition(a == b)
    precondition(a != c)
    let withInfo = ICReturnThumbnailError(.notAvailable, userInfo: ["k": "v"])
    precondition(a != withInfo)
    var hasherA = Hasher()
    var hasherB = Hasher()
    a.hash(into: &hasherA)
    b.hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())
    precondition(a.hashValue == b.hashValue)
}

func testICReturnThumbnailErrorPatternMatch() {
    let typed = ICReturnThumbnailError(.notAvailable)
    precondition(ICReturnThumbnailError.Code.notAvailable ~= typed)
    let ns = typed as NSError
    precondition(ns.domain == ICErrorDomain)
    precondition(ns.code == ICReturnThumbnailError.Code.notAvailable.rawValue)
    precondition(ICReturnThumbnailError.Code.notAvailable ~= ns)
    precondition(!(ICReturnThumbnailError.Code.invalid ~= typed))
}

func testICReturnThumbnailErrorStaticCodeAliases() {
    precondition(ICReturnThumbnailError.notAvailable == ICReturnThumbnailError.Code.notAvailable)
    precondition(ICReturnThumbnailError.alreadyFetching == ICReturnThumbnailError.Code.alreadyFetching)
    precondition(ICReturnThumbnailError.canceled == ICReturnThumbnailError.Code.canceled)
    precondition(ICReturnThumbnailError.invalid == ICReturnThumbnailError.Code.invalid)
}
