import Foundation
import CoreNFC

func testNFCErrorDomainStrings() {
    precondition(NFCErrorDomain == "NFCErrorDomain")
    precondition(NFCISO15693TagResponseErrorKey == "NFCISO15693TagResponseErrorKey")
    precondition(NFCTagResponseUnexpectedLengthErrorKey == "NFCTagResponseUnexpectedLengthErrorKey")
    precondition(NFCReaderError.errorDomain == NFCErrorDomain)
}

func testNFCReaderErrorCodeRawValues() {
    let codes: [(NFCReaderError.Code, Int)] = [
        (.readerErrorUnsupportedFeature, 1),
        (.readerErrorSecurityViolation, 2),
        (.readerErrorInvalidParameter, 3),
        (.readerErrorInvalidParameterLength, 4),
        (.readerErrorParameterOutOfBound, 5),
        (.readerErrorRadioDisabled, 6),
        (.readerErrorIneligible, 7),
        (.readerErrorAccessNotAccepted, 8),
        (.readerTransceiveErrorTagConnectionLost, 100),
        (.readerTransceiveErrorRetryExceeded, 101),
        (.readerTransceiveErrorTagResponseError, 102),
        (.readerTransceiveErrorSessionInvalidated, 103),
        (.readerTransceiveErrorTagNotConnected, 104),
        (.readerTransceiveErrorPacketTooLong, 105),
        (.readerSessionInvalidationErrorUserCanceled, 200),
        (.readerSessionInvalidationErrorSessionTimeout, 201),
        (.readerSessionInvalidationErrorSessionTerminatedUnexpectedly, 202),
        (.readerSessionInvalidationErrorSystemIsBusy, 203),
        (.readerSessionInvalidationErrorFirstNDEFTagRead, 204),
        (.tagCommandConfigurationErrorInvalidParameters, 300),
        (.ndefReaderSessionErrorTagNotWritable, 400),
        (.ndefReaderSessionErrorTagUpdateFailure, 401),
        (.ndefReaderSessionErrorTagSizeTooSmall, 402),
        (.ndefReaderSessionErrorZeroLengthMessage, 403),
    ]
    for (value, raw) in codes {
        precondition(value.rawValue == raw)
        precondition(NFCReaderError.Code(rawValue: raw) == value)
    }
    precondition(NFCReaderError.Code(rawValue: 0) == nil)
    precondition(NFCReaderError.Code.readerErrorUnsupportedFeature != .readerErrorRadioDisabled)
    _ = NFCReaderError.Code.readerErrorUnsupportedFeature.hashValue
    var hasher = Hasher()
    hasher.combine(NFCReaderError.Code.ndefReaderSessionErrorZeroLengthMessage)
    _ = hasher.finalize()
}

func testNFCReaderErrorStaticCodeProperties() {
    precondition(NFCReaderError.readerErrorUnsupportedFeature == .readerErrorUnsupportedFeature)
    precondition(NFCReaderError.readerErrorSecurityViolation == .readerErrorSecurityViolation)
    precondition(NFCReaderError.readerErrorInvalidParameter == .readerErrorInvalidParameter)
    precondition(NFCReaderError.readerErrorInvalidParameterLength == .readerErrorInvalidParameterLength)
    precondition(NFCReaderError.readerErrorParameterOutOfBound == .readerErrorParameterOutOfBound)
    precondition(NFCReaderError.readerErrorRadioDisabled == .readerErrorRadioDisabled)
    precondition(NFCReaderError.readerErrorIneligible == .readerErrorIneligible)
    precondition(NFCReaderError.readerErrorAccessNotAccepted == .readerErrorAccessNotAccepted)
    precondition(NFCReaderError.readerTransceiveErrorTagConnectionLost == .readerTransceiveErrorTagConnectionLost)
    precondition(NFCReaderError.readerTransceiveErrorRetryExceeded == .readerTransceiveErrorRetryExceeded)
    precondition(NFCReaderError.readerTransceiveErrorTagResponseError == .readerTransceiveErrorTagResponseError)
    precondition(NFCReaderError.readerTransceiveErrorSessionInvalidated == .readerTransceiveErrorSessionInvalidated)
    precondition(NFCReaderError.readerTransceiveErrorTagNotConnected == .readerTransceiveErrorTagNotConnected)
    precondition(NFCReaderError.readerTransceiveErrorPacketTooLong == .readerTransceiveErrorPacketTooLong)
    precondition(NFCReaderError.readerSessionInvalidationErrorUserCanceled == .readerSessionInvalidationErrorUserCanceled)
    precondition(NFCReaderError.readerSessionInvalidationErrorSessionTimeout == .readerSessionInvalidationErrorSessionTimeout)
    precondition(
        NFCReaderError.readerSessionInvalidationErrorSessionTerminatedUnexpectedly
            == .readerSessionInvalidationErrorSessionTerminatedUnexpectedly
    )
    precondition(NFCReaderError.readerSessionInvalidationErrorSystemIsBusy == .readerSessionInvalidationErrorSystemIsBusy)
    precondition(
        NFCReaderError.readerSessionInvalidationErrorFirstNDEFTagRead
            == .readerSessionInvalidationErrorFirstNDEFTagRead
    )
    precondition(
        NFCReaderError.tagCommandConfigurationErrorInvalidParameters
            == .tagCommandConfigurationErrorInvalidParameters
    )
    precondition(NFCReaderError.ndefReaderSessionErrorTagNotWritable == .ndefReaderSessionErrorTagNotWritable)
    precondition(NFCReaderError.ndefReaderSessionErrorTagUpdateFailure == .ndefReaderSessionErrorTagUpdateFailure)
    precondition(NFCReaderError.ndefReaderSessionErrorTagSizeTooSmall == .ndefReaderSessionErrorTagSizeTooSmall)
    precondition(NFCReaderError.ndefReaderSessionErrorZeroLengthMessage == .ndefReaderSessionErrorZeroLengthMessage)
}

func testNFCReaderErrorConstruction() {
    let error = NFCReaderError(.readerErrorUnsupportedFeature)
    precondition(error.errorCode == 1)
    precondition(error.code == .readerErrorUnsupportedFeature)
    precondition(error.userInfo.isEmpty)
    precondition(error.errorUserInfo.isEmpty)
    precondition(!error.localizedDescription.isEmpty)
    precondition(error.description.contains("NFCReaderError"))
    precondition(error == NFCReaderError(.readerErrorUnsupportedFeature))
    precondition(error != NFCReaderError(.readerErrorRadioDisabled))
    _ = error.hashValue
    var hasher = Hasher()
    error.hash(into: &hasher)
    _ = hasher.finalize()

    let labeled = NFCReaderError(
        .readerErrorInvalidParameter,
        userInfo: [NSLocalizedDescriptionKey: "bad length"]
    )
    precondition(labeled.localizedDescription == "bad length")
    precondition((labeled.errorUserInfo[NSLocalizedDescriptionKey] as? String) == "bad length")
}

func testNFCReaderErrorPatternMatch() {
    let error: any Error = NFCReaderError(.readerErrorUnsupportedFeature)
    precondition(NFCReaderError.Code.readerErrorUnsupportedFeature ~= error)
    precondition(!(NFCReaderError.Code.readerErrorRadioDisabled ~= error))
    let nsError = NSError(domain: NFCErrorDomain, code: 6, userInfo: nil)
    precondition(NFCReaderError.Code.readerErrorRadioDisabled ~= nsError)
    precondition(!(NFCReaderError.Code.readerErrorUnsupportedFeature ~= nsError))
}
