@_exported import Foundation
import Dispatch

/// Apple's public CoreNFC error domain constant.
///
/// The string value matches the exported `NFCErrorDomain` symbol name recorded
/// in the SDK TBD. Exact Apple `userInfo` payload keys beyond the two public
/// constants below remain an oracle question.
public let NFCErrorDomain = "NFCErrorDomain"

/// `userInfo` key used by ISO 15693 transceive failures for the tag status byte.
public let NFCISO15693TagResponseErrorKey = "NFCISO15693TagResponseErrorKey"

/// `userInfo` key used when a tag response length does not match the command.
public let NFCTagResponseUnexpectedLengthErrorKey = "NFCTagResponseUnexpectedLengthErrorKey"

public typealias EncryptionId = NFCFeliCaEncryptionId
public typealias PollingRequestCode = NFCFeliCaPollingRequestCode
public typealias PollingTimeSlot = NFCFeliCaPollingTimeSlot
public typealias RequestFlag = NFCISO15693RequestFlag
public typealias VASErrorCode = NFCVASResponse.ErrorCode
public typealias VASMode = NFCVASCommandConfiguration.Mode

/// Linux has no NFC controller, entitlement broker, or privacy prompt.
/// Hardware, payment, VAS, and card-emulation entry points fail with this error.
func _nfcUnsupportedError(
    _ code: NFCReaderError.Code = .readerErrorUnsupportedFeature,
    userInfo: [String: Any] = [:]
) -> NFCReaderError {
    NFCReaderError(code, userInfo: userInfo)
}

func _nfcCompleteUnsupported(_ completion: @escaping ((any Error)?) -> Void) {
    completion(_nfcUnsupportedError())
}

func _nfcCompleteUnsupported<Value>(
    _ completion: @escaping (Value, (any Error)?) -> Void,
    placeholder: Value
) {
    completion(placeholder, _nfcUnsupportedError())
}

func _nfcThrowUnsupported() throws -> Never {
    throw _nfcUnsupportedError()
}

func _nfcDefaultSessionQueue(_ queue: DispatchQueue?) -> DispatchQueue {
    queue ?? DispatchQueue(label: "com.openuikit.corenfc.session")
}

/// NFC scene events from the `_CoreNFC_UIKit` overlay. The enum itself does not
/// require UIKit; delivering it to a `UIWindowScene` stays not-applicable.
public enum NFCWindowSceneEvent: String, Hashable, Codable, Sendable,
    CustomStringConvertible
{
    case readerDetected
    case presentation

    public var description: String { rawValue }
}
