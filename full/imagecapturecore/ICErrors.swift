import Foundation

/// Legacy ICA error codes (`-9900` … `-9921`), matching the historical `kICA*` aliases imported as `ICLegacyReturn.Code`.
public struct ICLegacyReturn: Error, CustomNSError, Hashable, Equatable, @unchecked Sendable {
    public enum Code: Int, Hashable, Sendable {
        case communicationErr = -9900
        case deviceNotFoundErr = -9901
        case deviceNotOpenErr = -9902
        case fileCorruptedErr = -9903
        case ioPendingErr = -9904
        case invalidObjectErr = -9905
        case invalidPropertyErr = -9906
        case indexOutOfRangeErr = -9907
        case propertyTypeNotFoundErr = -9908
        case cannotYieldDevice = -9909
        case dataTypeNotFoundErr = -9910
        case deviceMemoryAllocationErr = -9911
        case deviceInternalErr = -9912
        case deviceInvalidParamErr = -9913
        case deviceAlreadyOpenErr = -9914
        case deviceLocationIDNotFoundErr = -9915
        case deviceGUIDNotFoundErr = -9916
        case deviceIOServicePathNotFoundErr = -9917
        case deviceUnsupportedErr = -9918
        case frameworkInternalErr = -9919
        case extensionInternalErr = -9920
        case invalidSessionErr = -9921
    }

    public let code: Code
    public let userInfo: [String: Any]

    public init(_ code: Code, userInfo: [String: Any] = [:]) {
        self.code = code
        self.userInfo = userInfo
    }

    public static var errorDomain: String { ICErrorDomain }
    public var errorCode: Int { code.rawValue }
    public var errorUserInfo: [String: Any] { userInfo }

    public static let communicationErr = Code.communicationErr
    public static let deviceNotFoundErr = Code.deviceNotFoundErr
    public static let deviceNotOpenErr = Code.deviceNotOpenErr
    public static let fileCorruptedErr = Code.fileCorruptedErr
    public static let ioPendingErr = Code.ioPendingErr
    public static let invalidObjectErr = Code.invalidObjectErr
    public static let invalidPropertyErr = Code.invalidPropertyErr
    public static let indexOutOfRangeErr = Code.indexOutOfRangeErr
    public static let propertyTypeNotFoundErr = Code.propertyTypeNotFoundErr
    public static let cannotYieldDevice = Code.cannotYieldDevice
    public static let dataTypeNotFoundErr = Code.dataTypeNotFoundErr
    public static let deviceMemoryAllocationErr = Code.deviceMemoryAllocationErr
    public static let deviceInternalErr = Code.deviceInternalErr
    public static let deviceInvalidParamErr = Code.deviceInvalidParamErr
    public static let deviceAlreadyOpenErr = Code.deviceAlreadyOpenErr
    public static let deviceLocationIDNotFoundErr = Code.deviceLocationIDNotFoundErr
    public static let deviceGUIDNotFoundErr = Code.deviceGUIDNotFoundErr
    public static let deviceIOServicePathNotFoundErr = Code.deviceIOServicePathNotFoundErr
    public static let deviceUnsupportedErr = Code.deviceUnsupportedErr
    public static let frameworkInternalErr = Code.frameworkInternalErr
    public static let extensionInternalErr = Code.extensionInternalErr
    public static let invalidSessionErr = Code.invalidSessionErr

    public static func == (lhs: ICLegacyReturn, rhs: ICLegacyReturn) -> Bool {
        guard lhs.code == rhs.code else { return false }
        return NSDictionary(dictionary: lhs.userInfo).isEqual(to: rhs.userInfo)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(code)
    }

    public var hashValue: Int {
        var hasher = Hasher()
        hash(into: &hasher)
        return hasher.finalize()
    }
}

extension ICLegacyReturn.Code {
    public static func ~= (match: ICLegacyReturn.Code, error: any Error) -> Bool {
        if let typed = error as? ICLegacyReturn {
            return typed.code == match
        }
        let nsError = error as NSError
        return nsError.domain == ICErrorDomain && nsError.code == match.rawValue
    }
}

/// Primary ImageCaptureCore return codes. Sequential `-9922` … `-9958` continue the ICA range; `exFATVolumeInvalid` uses `ICReturnCodeOffset.exFATOffset`; `multiErrorDictionary` is `-30000`.
public struct ICReturn: Error, CustomNSError, Hashable, Equatable, @unchecked Sendable {
    public enum Code: Int, Hashable, Sendable {
        case success = 0
        case invalidParam = -9922
        case communicationTimedOut = -9923
        case scanOperationCanceled = -9924
        case scannerInUseByLocalUser = -9925
        case scannerInUseByRemoteUser = -9926
        case deviceFailedToOpenSession = -9927
        case deviceFailedToCloseSession = -9928
        case scannerFailedToSelectFunctionalUnit = -9929
        case scannerFailedToCompleteOverviewScan = -9930
        case scannerFailedToCompleteScan = -9931
        case receivedUnsolicitedScannerStatusInfo = -9932
        case receivedUnsolicitedScannerErrorInfo = -9933
        case downloadFailed = -9934
        case uploadFailed = -9935
        case failedToCompletePassThroughCommand = -9936
        case downloadCanceled = -9937
        case failedToEnabeTethering = -9938
        case failedToDisabeTethering = -9939
        case failedToCompleteSendMessageRequest = -9940
        case deleteFilesFailed = -9941
        case deleteFilesCanceled = -9942
        case deviceIsPasscodeLocked = -9943
        case deviceFailedToTakePicture = -9944
        case deviceSoftwareNotInstalled = -9945
        case deviceSoftwareIsBeingInstalled = -9946
        case deviceSoftwareInstallationCompleted = -9947
        case deviceSoftwareInstallationCanceled = -9948
        case deviceSoftwareInstallationFailed = -9949
        case deviceSoftwareNotAvailable = -9950
        case deviceCouldNotPair = -9951
        case deviceCouldNotUnpair = -9952
        case deviceNeedsCredentials = -9953
        case deviceIsBusyEnumerating = -9954
        case deviceCommandGeneralFailure = -9955
        case deviceFailedToCompleteTransfer = -9956
        case deviceFailedToSendData = -9957
        case sessionNotOpened = -9958
        case exFATVolumeInvalid = -21200
        case multiErrorDictionary = -30000
    }

    public let code: Code
    public let userInfo: [String: Any]

    public init(_ code: Code, userInfo: [String: Any] = [:]) {
        self.code = code
        self.userInfo = userInfo
    }

    public static var errorDomain: String { ICErrorDomain }
    public var errorCode: Int { code.rawValue }
    public var errorUserInfo: [String: Any] { userInfo }

    public static let success = Code.success
    public static let invalidParam = Code.invalidParam
    public static let communicationTimedOut = Code.communicationTimedOut
    public static let scanOperationCanceled = Code.scanOperationCanceled
    public static let scannerInUseByLocalUser = Code.scannerInUseByLocalUser
    public static let scannerInUseByRemoteUser = Code.scannerInUseByRemoteUser
    public static let deviceFailedToOpenSession = Code.deviceFailedToOpenSession
    public static let deviceFailedToCloseSession = Code.deviceFailedToCloseSession
    public static let scannerFailedToSelectFunctionalUnit = Code.scannerFailedToSelectFunctionalUnit
    public static let scannerFailedToCompleteOverviewScan = Code.scannerFailedToCompleteOverviewScan
    public static let scannerFailedToCompleteScan = Code.scannerFailedToCompleteScan
    public static let receivedUnsolicitedScannerStatusInfo = Code.receivedUnsolicitedScannerStatusInfo
    public static let receivedUnsolicitedScannerErrorInfo = Code.receivedUnsolicitedScannerErrorInfo
    public static let downloadFailed = Code.downloadFailed
    public static let uploadFailed = Code.uploadFailed
    public static let failedToCompletePassThroughCommand = Code.failedToCompletePassThroughCommand
    public static let downloadCanceled = Code.downloadCanceled
    public static let failedToEnabeTethering = Code.failedToEnabeTethering
    public static let failedToDisabeTethering = Code.failedToDisabeTethering
    public static let failedToCompleteSendMessageRequest = Code.failedToCompleteSendMessageRequest
    public static let deleteFilesFailed = Code.deleteFilesFailed
    public static let deleteFilesCanceled = Code.deleteFilesCanceled
    public static let deviceIsPasscodeLocked = Code.deviceIsPasscodeLocked
    public static let deviceFailedToTakePicture = Code.deviceFailedToTakePicture
    public static let deviceSoftwareNotInstalled = Code.deviceSoftwareNotInstalled
    public static let deviceSoftwareIsBeingInstalled = Code.deviceSoftwareIsBeingInstalled
    public static let deviceSoftwareInstallationCompleted = Code.deviceSoftwareInstallationCompleted
    public static let deviceSoftwareInstallationCanceled = Code.deviceSoftwareInstallationCanceled
    public static let deviceSoftwareInstallationFailed = Code.deviceSoftwareInstallationFailed
    public static let deviceSoftwareNotAvailable = Code.deviceSoftwareNotAvailable
    public static let deviceCouldNotPair = Code.deviceCouldNotPair
    public static let deviceCouldNotUnpair = Code.deviceCouldNotUnpair
    public static let deviceNeedsCredentials = Code.deviceNeedsCredentials
    public static let deviceIsBusyEnumerating = Code.deviceIsBusyEnumerating
    public static let deviceCommandGeneralFailure = Code.deviceCommandGeneralFailure
    public static let deviceFailedToCompleteTransfer = Code.deviceFailedToCompleteTransfer
    public static let deviceFailedToSendData = Code.deviceFailedToSendData
    public static let sessionNotOpened = Code.sessionNotOpened
    public static let exFATVolumeInvalid = Code.exFATVolumeInvalid
    public static let multiErrorDictionary = Code.multiErrorDictionary

    public static func == (lhs: ICReturn, rhs: ICReturn) -> Bool {
        guard lhs.code == rhs.code else { return false }
        return NSDictionary(dictionary: lhs.userInfo).isEqual(to: rhs.userInfo)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(code)
    }

    public var hashValue: Int {
        var hasher = Hasher()
        hash(into: &hasher)
        return hasher.finalize()
    }
}

extension ICReturn.Code {
    public static func ~= (match: ICReturn.Code, error: any Error) -> Bool {
        if let typed = error as? ICReturn {
            return typed.code == match
        }
        let nsError = error as NSError
        return nsError.domain == ICErrorDomain && nsError.code == match.rawValue
    }
}

/// Connection errors. `driverExited`…`ejectFailed` use `deviceOffset` minus 0…4; `failedToOpen` uses `deviceConnection`, then minus 1 and 2.
public struct ICReturnConnectionError: Error, CustomNSError, Hashable, Equatable, @unchecked Sendable {
    public enum Code: Int, Hashable, Sendable {
        case driverExited = -21350
        case closedSessionSuddenly = -21349
        case ejectedSuddenly = -21348
        case sessionAlreadyOpen = -21347
        case ejectFailed = -21346
        case failedToOpen = -21400
        case failedToOpenDevice = -21399
        case notAuthorizedToOpenDevice = -21398
    }

    public let code: Code
    public let userInfo: [String: Any]

    public init(_ code: Code, userInfo: [String: Any] = [:]) {
        self.code = code
        self.userInfo = userInfo
    }

    public static var errorDomain: String { ICErrorDomain }
    public var errorCode: Int { code.rawValue }
    public var errorUserInfo: [String: Any] { userInfo }

    public static let driverExited = Code.driverExited
    public static let closedSessionSuddenly = Code.closedSessionSuddenly
    public static let ejectedSuddenly = Code.ejectedSuddenly
    public static let sessionAlreadyOpen = Code.sessionAlreadyOpen
    public static let ejectFailed = Code.ejectFailed
    public static let failedToOpen = Code.failedToOpen
    public static let failedToOpenDevice = Code.failedToOpenDevice
    public static let notAuthorizedToOpenDevice = Code.notAuthorizedToOpenDevice

    public static func == (lhs: ICReturnConnectionError, rhs: ICReturnConnectionError) -> Bool {
        guard lhs.code == rhs.code else { return false }
        return NSDictionary(dictionary: lhs.userInfo).isEqual(to: rhs.userInfo)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(code)
    }

    public var hashValue: Int {
        var hasher = Hasher()
        hash(into: &hasher)
        return hasher.finalize()
    }
}

extension ICReturnConnectionError.Code {
    public static func ~= (match: ICReturnConnectionError.Code, error: any Error) -> Bool {
        if let typed = error as? ICReturnConnectionError {
            return typed.code == match
        }
        let nsError = error as NSError
        return nsError.domain == ICErrorDomain && nsError.code == match.rawValue
    }
}

/// Download-path errors at `downloadOffset` and `downloadOffset - 1`.
public struct ICReturnDownloadError: Error, CustomNSError, Hashable, Equatable, @unchecked Sendable {
    public enum Code: Int, Hashable, Sendable {
        case pathInvalid = -21100
        case fileWritable = -21101
    }

    public let code: Code
    public let userInfo: [String: Any]

    public init(_ code: Code, userInfo: [String: Any] = [:]) {
        self.code = code
        self.userInfo = userInfo
    }

    public static var errorDomain: String { ICErrorDomain }
    public var errorCode: Int { code.rawValue }
    public var errorUserInfo: [String: Any] { userInfo }

    public static let pathInvalid = Code.pathInvalid
    public static let fileWritable = Code.fileWritable

    public static func == (lhs: ICReturnDownloadError, rhs: ICReturnDownloadError) -> Bool {
        guard lhs.code == rhs.code else { return false }
        return NSDictionary(dictionary: lhs.userInfo).isEqual(to: rhs.userInfo)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(code)
    }

    public var hashValue: Int {
        var hasher = Hasher()
        hash(into: &hasher)
        return hasher.finalize()
    }
}

extension ICReturnDownloadError.Code {
    public static func ~= (match: ICReturnDownloadError.Code, error: any Error) -> Bool {
        if let typed = error as? ICReturnDownloadError {
            return typed.code == match
        }
        let nsError = error as NSError
        return nsError.domain == ICErrorDomain && nsError.code == match.rawValue
    }
}

/// Metadata errors at `metadataOffset` minus 0…3.
public struct ICReturnMetadataError: Error, CustomNSError, Hashable, Equatable, @unchecked Sendable {
    public enum Code: Int, Hashable, Sendable {
        case notAvailable = -21050
        case alreadyFetching = -21051
        case canceled = -21052
        case invalid = -21053
    }

    public let code: Code
    public let userInfo: [String: Any]

    public init(_ code: Code, userInfo: [String: Any] = [:]) {
        self.code = code
        self.userInfo = userInfo
    }

    public static var errorDomain: String { ICErrorDomain }
    public var errorCode: Int { code.rawValue }
    public var errorUserInfo: [String: Any] { userInfo }

    public static let notAvailable = Code.notAvailable
    public static let alreadyFetching = Code.alreadyFetching
    public static let canceled = Code.canceled
    public static let invalid = Code.invalid

    public static func == (lhs: ICReturnMetadataError, rhs: ICReturnMetadataError) -> Bool {
        guard lhs.code == rhs.code else { return false }
        return NSDictionary(dictionary: lhs.userInfo).isEqual(to: rhs.userInfo)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(code)
    }

    public var hashValue: Int {
        var hasher = Hasher()
        hash(into: &hasher)
        return hasher.finalize()
    }
}

extension ICReturnMetadataError.Code {
    public static func ~= (match: ICReturnMetadataError.Code, error: any Error) -> Bool {
        if let typed = error as? ICReturnMetadataError {
            return typed.code == match
        }
        let nsError = error as NSError
        return nsError.domain == ICErrorDomain && nsError.code == match.rawValue
    }
}

/// Object-read errors at `objectOffset` minus 0…4.
public struct ICReturnObjectError: Error, CustomNSError, Hashable, Equatable, @unchecked Sendable {
    public enum Code: Int, Hashable, Sendable {
        case codeObjectDoesNotExist = -21450
        case codeObjectDataOffsetInvalid = -21449
        case codeObjectCouldNotBeRead = -21448
        case codeObjectDataEmpty = -21447
        case codeObjectDataRequestTooLarge = -21446
    }

    public let code: Code
    public let userInfo: [String: Any]

    public init(_ code: Code, userInfo: [String: Any] = [:]) {
        self.code = code
        self.userInfo = userInfo
    }

    public static var errorDomain: String { ICErrorDomain }
    public var errorCode: Int { code.rawValue }
    public var errorUserInfo: [String: Any] { userInfo }

    public static let codeObjectDoesNotExist = Code.codeObjectDoesNotExist
    public static let codeObjectDataOffsetInvalid = Code.codeObjectDataOffsetInvalid
    public static let codeObjectCouldNotBeRead = Code.codeObjectCouldNotBeRead
    public static let codeObjectDataEmpty = Code.codeObjectDataEmpty
    public static let codeObjectDataRequestTooLarge = Code.codeObjectDataRequestTooLarge

    public static func == (lhs: ICReturnObjectError, rhs: ICReturnObjectError) -> Bool {
        guard lhs.code == rhs.code else { return false }
        return NSDictionary(dictionary: lhs.userInfo).isEqual(to: rhs.userInfo)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(code)
    }

    public var hashValue: Int {
        var hasher = Hasher()
        hash(into: &hasher)
        return hasher.finalize()
    }
}

extension ICReturnObjectError.Code {
    public static func ~= (match: ICReturnObjectError.Code, error: any Error) -> Bool {
        if let typed = error as? ICReturnObjectError {
            return typed.code == match
        }
        let nsError = error as NSError
        return nsError.domain == ICErrorDomain && nsError.code == match.rawValue
    }
}

/// PTP command errors at `ptpOffset` and `ptpOffset - 1`.
public struct ICReturnPTPDeviceError: Error, CustomNSError, Hashable, Equatable, @unchecked Sendable {
    public enum Code: Int, Hashable, Sendable {
        case failedToSendCommand = -21250
        case notAuthorizedToSendCommand = -21249
    }

    public let code: Code
    public let userInfo: [String: Any]

    public init(_ code: Code, userInfo: [String: Any] = [:]) {
        self.code = code
        self.userInfo = userInfo
    }

    public static var errorDomain: String { ICErrorDomain }
    public var errorCode: Int { code.rawValue }
    public var errorUserInfo: [String: Any] { userInfo }

    public static let failedToSendCommand = Code.failedToSendCommand
    public static let notAuthorizedToSendCommand = Code.notAuthorizedToSendCommand

    public static func == (lhs: ICReturnPTPDeviceError, rhs: ICReturnPTPDeviceError) -> Bool {
        guard lhs.code == rhs.code else { return false }
        return NSDictionary(dictionary: lhs.userInfo).isEqual(to: rhs.userInfo)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(code)
    }

    public var hashValue: Int {
        var hasher = Hasher()
        hash(into: &hasher)
        return hasher.finalize()
    }
}

extension ICReturnPTPDeviceError.Code {
    public static func ~= (match: ICReturnPTPDeviceError.Code, error: any Error) -> Bool {
        if let typed = error as? ICReturnPTPDeviceError {
            return typed.code == match
        }
        let nsError = error as NSError
        return nsError.domain == ICErrorDomain && nsError.code == match.rawValue
    }
}

/// Thumbnail errors at `thumbnailOffset` minus 0…3.
public struct ICReturnThumbnailError: Error, CustomNSError, Hashable, Equatable, @unchecked Sendable {
    public enum Code: Int, Hashable, Sendable {
        case notAvailable = -21000
        case alreadyFetching = -21001
        case canceled = -21002
        case invalid = -21003
    }

    public let code: Code
    public let userInfo: [String: Any]

    public init(_ code: Code, userInfo: [String: Any] = [:]) {
        self.code = code
        self.userInfo = userInfo
    }

    public static var errorDomain: String { ICErrorDomain }
    public var errorCode: Int { code.rawValue }
    public var errorUserInfo: [String: Any] { userInfo }

    public static let notAvailable = Code.notAvailable
    public static let alreadyFetching = Code.alreadyFetching
    public static let canceled = Code.canceled
    public static let invalid = Code.invalid

    public static func == (lhs: ICReturnThumbnailError, rhs: ICReturnThumbnailError) -> Bool {
        guard lhs.code == rhs.code else { return false }
        return NSDictionary(dictionary: lhs.userInfo).isEqual(to: rhs.userInfo)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(code)
    }

    public var hashValue: Int {
        var hasher = Hasher()
        hash(into: &hasher)
        return hasher.finalize()
    }
}

extension ICReturnThumbnailError.Code {
    public static func ~= (match: ICReturnThumbnailError.Code, error: any Error) -> Bool {
        if let typed = error as? ICReturnThumbnailError {
            return typed.code == match
        }
        let nsError = error as NSError
        return nsError.domain == ICErrorDomain && nsError.code == match.rawValue
    }
}
