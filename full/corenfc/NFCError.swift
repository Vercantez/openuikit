import Foundation

/// Bridged CoreNFC `NS_ERROR_ENUM` overlay.
///
/// Numeric codes follow the public `NFCError.h` grouping: reader errors start
/// at 1, transceive errors at 100, session invalidation at 200, tag command
/// configuration at 300, and NDEF session errors at 400. `ineligible` and
/// `accessNotAccepted` occupy 7 and 8 after `radioDisabled` in the first group.
public struct NFCReaderError: Error, CustomNSError, Hashable, Equatable,
    @unchecked Sendable
{
    public enum Code: Int, Hashable, Sendable {
        case readerErrorUnsupportedFeature = 1
        case readerErrorSecurityViolation = 2
        case readerErrorInvalidParameter = 3
        case readerErrorInvalidParameterLength = 4
        case readerErrorParameterOutOfBound = 5
        case readerErrorRadioDisabled = 6
        case readerErrorIneligible = 7
        case readerErrorAccessNotAccepted = 8
        case readerTransceiveErrorTagConnectionLost = 100
        case readerTransceiveErrorRetryExceeded = 101
        case readerTransceiveErrorTagResponseError = 102
        case readerTransceiveErrorSessionInvalidated = 103
        case readerTransceiveErrorTagNotConnected = 104
        case readerTransceiveErrorPacketTooLong = 105
        case readerSessionInvalidationErrorUserCanceled = 200
        case readerSessionInvalidationErrorSessionTimeout = 201
        case readerSessionInvalidationErrorSessionTerminatedUnexpectedly = 202
        case readerSessionInvalidationErrorSystemIsBusy = 203
        case readerSessionInvalidationErrorFirstNDEFTagRead = 204
        case tagCommandConfigurationErrorInvalidParameters = 300
        case ndefReaderSessionErrorTagNotWritable = 400
        case ndefReaderSessionErrorTagUpdateFailure = 401
        case ndefReaderSessionErrorTagSizeTooSmall = 402
        case ndefReaderSessionErrorZeroLengthMessage = 403
    }

    public let code: Code
    public let userInfo: [String: Any]

    public init(_ code: Code, userInfo: [String: Any] = [:]) {
        self.code = code
        self.userInfo = userInfo
    }

    public static var errorDomain: String { NFCErrorDomain }
    public var errorCode: Int { code.rawValue }
    public var errorUserInfo: [String: Any] { userInfo }

    public var localizedDescription: String {
        "NFC reader error \(code.rawValue) (\(NFCErrorDomain))"
    }

    public static func == (lhs: NFCReaderError, rhs: NFCReaderError) -> Bool {
        guard lhs.code == rhs.code else { return false }
        return NSDictionary(dictionary: lhs.userInfo).isEqual(to: rhs.userInfo)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(code)
    }

    public static let readerErrorUnsupportedFeature = Code.readerErrorUnsupportedFeature
    public static let readerErrorSecurityViolation = Code.readerErrorSecurityViolation
    public static let readerErrorInvalidParameter = Code.readerErrorInvalidParameter
    public static let readerErrorInvalidParameterLength = Code.readerErrorInvalidParameterLength
    public static let readerErrorParameterOutOfBound = Code.readerErrorParameterOutOfBound
    public static let readerErrorRadioDisabled = Code.readerErrorRadioDisabled
    public static let readerErrorIneligible = Code.readerErrorIneligible
    public static let readerErrorAccessNotAccepted = Code.readerErrorAccessNotAccepted
    public static let readerTransceiveErrorTagConnectionLost = Code.readerTransceiveErrorTagConnectionLost
    public static let readerTransceiveErrorRetryExceeded = Code.readerTransceiveErrorRetryExceeded
    public static let readerTransceiveErrorTagResponseError = Code.readerTransceiveErrorTagResponseError
    public static let readerTransceiveErrorSessionInvalidated = Code.readerTransceiveErrorSessionInvalidated
    public static let readerTransceiveErrorTagNotConnected = Code.readerTransceiveErrorTagNotConnected
    public static let readerTransceiveErrorPacketTooLong = Code.readerTransceiveErrorPacketTooLong
    public static let readerSessionInvalidationErrorUserCanceled = Code.readerSessionInvalidationErrorUserCanceled
    public static let readerSessionInvalidationErrorSessionTimeout = Code.readerSessionInvalidationErrorSessionTimeout
    public static let readerSessionInvalidationErrorSessionTerminatedUnexpectedly =
        Code.readerSessionInvalidationErrorSessionTerminatedUnexpectedly
    public static let readerSessionInvalidationErrorSystemIsBusy = Code.readerSessionInvalidationErrorSystemIsBusy
    public static let readerSessionInvalidationErrorFirstNDEFTagRead =
        Code.readerSessionInvalidationErrorFirstNDEFTagRead
    public static let tagCommandConfigurationErrorInvalidParameters =
        Code.tagCommandConfigurationErrorInvalidParameters
    public static let ndefReaderSessionErrorTagNotWritable = Code.ndefReaderSessionErrorTagNotWritable
    public static let ndefReaderSessionErrorTagUpdateFailure = Code.ndefReaderSessionErrorTagUpdateFailure
    public static let ndefReaderSessionErrorTagSizeTooSmall = Code.ndefReaderSessionErrorTagSizeTooSmall
    public static let ndefReaderSessionErrorZeroLengthMessage = Code.ndefReaderSessionErrorZeroLengthMessage
}

extension NFCReaderError.Code {
    public static func ~= (match: NFCReaderError.Code, error: any Error) -> Bool {
        (error as? NFCReaderError)?.code == match
    }
}
