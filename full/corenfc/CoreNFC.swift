@_exported import Foundation
import Dispatch

// MARK: - Error domain strings
//
// Darwin string payloads were not measured on device. Linux uses the public
// identifier spelling as a source-compatible fallback (same policy as other
// isolated-host lanes). Exact bytes remain an oracle question.

public let NFCErrorDomain = "NFCErrorDomain"
public let NFCISO15693TagResponseErrorKey = "NFCISO15693TagResponseErrorKey"
public let NFCTagResponseUnexpectedLengthErrorKey = "NFCTagResponseUnexpectedLengthErrorKey"

let coreNFCSessionQueue: DispatchQueue = {
    DispatchQueue(label: "CoreNFC.session", qos: .userInitiated)
}()

func coreNFCUnsupportedError(
    _ code: NFCReaderError.Code = .readerErrorUnsupportedFeature
) -> NFCReaderError {
    NFCReaderError(
        code,
        userInfo: [
            NSLocalizedDescriptionKey:
                "CoreNFC hardware, entitlements, and Apple NFC services are unavailable on this Linux host"
        ]
    )
}

func coreNFCUnsupportedNSError(
    _ code: NFCReaderError.Code = .readerErrorUnsupportedFeature
) -> NSError {
    coreNFCUnsupportedError(code) as NSError
}

// MARK: - NFCReaderError
//
// Nested `Code` raw values follow the public NFCReaderError numbering recorded
// in the pinned `dotnet/macios` CoreNFC bindings (UnsupportedFeature = 1, then
// the documented 100/200/300/400 bands). Those integers are binding-sourced
// Linux fallbacks, not an Apple-runtime ABI measurement.

public struct NFCReaderError: Error, Hashable, CustomNSError, CustomStringConvertible {
    public enum Code: Int, Error, Hashable, Sendable {
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

        public static func ~= (match: Code, error: any Error) -> Bool {
            if let reader = error as? NFCReaderError {
                return reader.code == match
            }
            let nsError = error as NSError
            return nsError.domain == NFCErrorDomain && nsError.code == match.rawValue
        }
    }

    public var code: Code
    public var userInfo: [String: Any]

    public init(_ code: Code, userInfo: [String: Any] = [:]) {
        self.code = code
        self.userInfo = userInfo
    }

    public var errorCode: Int { code.rawValue }
    public var errorUserInfo: [String: Any] { userInfo }
    public static var errorDomain: String { NFCErrorDomain }

    public var hashValue: Int { code.rawValue }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(code.rawValue)
    }

    public static func == (lhs: NFCReaderError, rhs: NFCReaderError) -> Bool {
        lhs.code == rhs.code
    }

    public var localizedDescription: String {
        if let text = userInfo[NSLocalizedDescriptionKey] as? String {
            return text
        }
        return "NFCReaderError(\(code))"
    }

    public var description: String { localizedDescription }

    public static var readerErrorUnsupportedFeature: Code { .readerErrorUnsupportedFeature }
    public static var readerErrorSecurityViolation: Code { .readerErrorSecurityViolation }
    public static var readerErrorInvalidParameter: Code { .readerErrorInvalidParameter }
    public static var readerErrorInvalidParameterLength: Code { .readerErrorInvalidParameterLength }
    public static var readerErrorParameterOutOfBound: Code { .readerErrorParameterOutOfBound }
    public static var readerErrorRadioDisabled: Code { .readerErrorRadioDisabled }
    public static var readerErrorIneligible: Code { .readerErrorIneligible }
    public static var readerErrorAccessNotAccepted: Code { .readerErrorAccessNotAccepted }
    public static var readerTransceiveErrorTagConnectionLost: Code { .readerTransceiveErrorTagConnectionLost }
    public static var readerTransceiveErrorRetryExceeded: Code { .readerTransceiveErrorRetryExceeded }
    public static var readerTransceiveErrorTagResponseError: Code { .readerTransceiveErrorTagResponseError }
    public static var readerTransceiveErrorSessionInvalidated: Code { .readerTransceiveErrorSessionInvalidated }
    public static var readerTransceiveErrorTagNotConnected: Code { .readerTransceiveErrorTagNotConnected }
    public static var readerTransceiveErrorPacketTooLong: Code { .readerTransceiveErrorPacketTooLong }
    public static var readerSessionInvalidationErrorUserCanceled: Code { .readerSessionInvalidationErrorUserCanceled }
    public static var readerSessionInvalidationErrorSessionTimeout: Code { .readerSessionInvalidationErrorSessionTimeout }
    public static var readerSessionInvalidationErrorSessionTerminatedUnexpectedly: Code {
        .readerSessionInvalidationErrorSessionTerminatedUnexpectedly
    }
    public static var readerSessionInvalidationErrorSystemIsBusy: Code { .readerSessionInvalidationErrorSystemIsBusy }
    public static var readerSessionInvalidationErrorFirstNDEFTagRead: Code {
        .readerSessionInvalidationErrorFirstNDEFTagRead
    }
    public static var tagCommandConfigurationErrorInvalidParameters: Code {
        .tagCommandConfigurationErrorInvalidParameters
    }
    public static var ndefReaderSessionErrorTagNotWritable: Code { .ndefReaderSessionErrorTagNotWritable }
    public static var ndefReaderSessionErrorTagUpdateFailure: Code { .ndefReaderSessionErrorTagUpdateFailure }
    public static var ndefReaderSessionErrorTagSizeTooSmall: Code { .ndefReaderSessionErrorTagSizeTooSmall }
    public static var ndefReaderSessionErrorZeroLengthMessage: Code { .ndefReaderSessionErrorZeroLengthMessage }
}

// MARK: - Public enums (NFC Forum / binding-sourced raw values)

public enum NFCTypeNameFormat: UInt8, Sendable, Hashable {
    case empty = 0x00
    case nfcWellKnown = 0x01
    case media = 0x02
    case absoluteURI = 0x03
    case nfcExternal = 0x04
    case unknown = 0x05
    case unchanged = 0x06
}

public enum NFCNDEFStatus: UInt, Sendable, Hashable {
    case notSupported = 1
    case readWrite = 2
    case readOnly = 3
}

public enum NFCMiFareFamily: UInt, Sendable, Hashable {
    case unknown = 1
    case ultralight = 2
    case plus = 3
    case desfire = 4
}

/// FeliCa encryption identifiers. Raw values 0x4F / 0x41 are the public FeliCa
/// AES / AES-DES codes recorded in the pinned macios bindings, not measured on
/// an Apple radio.
public enum NFCFeliCaEncryptionId: Int, Sendable, Hashable {
    case AES = 79
    case AES_DES = 65

    public static var aes: NFCFeliCaEncryptionId { .AES }
    public static var aes_des: NFCFeliCaEncryptionId { .AES_DES }
}

public enum NFCFeliCaPollingRequestCode: Int, Sendable, Hashable {
    case noRequest = 0
    case systemCode = 1
    case communicationPerformance = 2

    public static var PollingRequestCodeNoRequest: NFCFeliCaPollingRequestCode { .noRequest }
    public static var PollingRequestCodeSystemCode: NFCFeliCaPollingRequestCode { .systemCode }
    public static var PollingRequestCodeCommunicationPerformance: NFCFeliCaPollingRequestCode {
        .communicationPerformance
    }
}

public enum NFCFeliCaPollingTimeSlot: Int, Sendable, Hashable {
    case max1 = 0
    case max2 = 1
    case max4 = 3
    case max8 = 7
    case max16 = 15

    public static var PollingTimeSlotMax1: NFCFeliCaPollingTimeSlot { .max1 }
    public static var PollingTimeSlotMax2: NFCFeliCaPollingTimeSlot { .max2 }
    public static var PollingTimeSlotMax4: NFCFeliCaPollingTimeSlot { .max4 }
    public static var PollingTimeSlotMax8: NFCFeliCaPollingTimeSlot { .max8 }
    public static var PollingTimeSlotMax16: NFCFeliCaPollingTimeSlot { .max16 }
}

public struct NFCISO15693RequestFlag: OptionSet, Sendable, Hashable {
    public let rawValue: UInt8

    public init(rawValue: UInt8) {
        self.rawValue = rawValue
    }

    public static let dualSubCarriers = NFCISO15693RequestFlag(rawValue: 1 << 0)
    public static let highDataRate = NFCISO15693RequestFlag(rawValue: 1 << 1)
    public static let protocolExtension = NFCISO15693RequestFlag(rawValue: 1 << 3)
    public static let select = NFCISO15693RequestFlag(rawValue: 1 << 4)
    public static let address = NFCISO15693RequestFlag(rawValue: 1 << 5)
    public static let option = NFCISO15693RequestFlag(rawValue: 1 << 6)
    public static let commandSpecificBit8 = NFCISO15693RequestFlag(rawValue: 1 << 7)

    public static var RequestFlagDualSubCarriers: NFCISO15693RequestFlag { .dualSubCarriers }
    public static var RequestFlagHighDataRate: NFCISO15693RequestFlag { .highDataRate }
    public static var RequestFlagProtocolExtension: NFCISO15693RequestFlag { .protocolExtension }
    public static var RequestFlagSelect: NFCISO15693RequestFlag { .select }
    public static var RequestFlagAddress: NFCISO15693RequestFlag { .address }
    public static var RequestFlagOption: NFCISO15693RequestFlag { .option }
}

public struct NFCISO15693ResponseFlag: OptionSet, Sendable, Hashable {
    public let rawValue: UInt8

    public init(rawValue: UInt8) {
        self.rawValue = rawValue
    }

    public static let error = NFCISO15693ResponseFlag(rawValue: 1 << 0)
    public static let responseBufferValid = NFCISO15693ResponseFlag(rawValue: 1 << 1)
    public static let finalResponse = NFCISO15693ResponseFlag(rawValue: 1 << 2)
    public static let protocolExtension = NFCISO15693ResponseFlag(rawValue: 1 << 3)
    public static let blockSecurityStatusBit5 = NFCISO15693ResponseFlag(rawValue: 1 << 4)
    public static let blockSecurityStatusBit6 = NFCISO15693ResponseFlag(rawValue: 1 << 5)
    public static let waitTimeExtension = NFCISO15693ResponseFlag(rawValue: 1 << 6)
}

public typealias EncryptionId = NFCFeliCaEncryptionId
public typealias PollingRequestCode = NFCFeliCaPollingRequestCode
public typealias PollingTimeSlot = NFCFeliCaPollingTimeSlot
public typealias RequestFlag = NFCISO15693RequestFlag
public typealias VASErrorCode = NFCVASResponse.ErrorCode
public typealias VASMode = NFCVASCommandConfiguration.Mode

// MARK: - Host control

@_spi(OpenUIKitHost)
public enum CoreNFCHostControl {
    public static var sessionQueue: DispatchQueue { coreNFCSessionQueue }

    public static func unsupportedError(
        _ code: NFCReaderError.Code = .readerErrorUnsupportedFeature
    ) -> NFCReaderError {
        coreNFCUnsupportedError(code)
    }
}
