@_spi(OpenUIKitHost) import Speech
import Foundation

func testSFSpeechErrorCodes() {
    let table: [(SFSpeechError.Code, Int)] = [
        (.internalServiceError, 1),
        (.audioReadFailed, 2),
        (.undefinedTemplateClassName, 7),
        (.malformedSupplementalModel, 8),
        (.timeout, 12),
        (.missingParameter, 13),
        (.audioDisordered, 1001),
        (.moduleOutputFailed, 1002),
        (.insufficientResources, 1003),
        (.unexpectedAudioFormat, 1004),
        (.assetLocaleNotAllocated, 1005),
        (.incompatibleAudioFormats, 1006),
        (.tooManyAssetLocalesAllocated, 1007),
        (.cannotAllocateUnsupportedLocale, 1008),
        (.noModel, 1009),
    ]
    for (code, raw) in table {
        precondition(code.rawValue == raw)
        precondition(SFSpeechError.Code(rawValue: raw) == code)
        _ = speechHash(code)
        _ = code.hashValue
    }
    precondition(SFSpeechError.Code(rawValue: 1) != .timeout)
    precondition(SFSpeechError.audioReadFailed == .audioReadFailed)
    precondition(SFSpeechError.internalServiceError == .internalServiceError)
    precondition(SFSpeechError.malformedSupplementalModel == .malformedSupplementalModel)
    precondition(SFSpeechError.missingParameter == .missingParameter)
    precondition(SFSpeechError.timeout == .timeout)
    precondition(SFSpeechError.undefinedTemplateClassName == .undefinedTemplateClassName)
    precondition(SFSpeechErrorDomain == "SFSpeechErrorDomain")
    precondition(SFSpeechError.errorDomain == SFSpeechErrorDomain)

    let error = SFSpeechError(.internalServiceError, userInfo: ["x": 1])
    precondition(error.code == .internalServiceError)
    precondition(error.errorCode == 1)
    precondition(error.errorUserInfo[NSLocalizedDescriptionKey] as? String != nil)
    precondition(error.userInfo[NSLocalizedDescriptionKey] as? String != nil)
    precondition(error.localizedDescription.isEmpty == false)
    precondition((error as NSError).domain == SFSpeechErrorDomain)
    precondition(error == SFSpeechError(.internalServiceError))
    precondition(error != SFSpeechError(.timeout))
    _ = speechHash(error)
    _ = error.hashValue

    let code: SFSpeechError.Code = .timeout
    switch code {
    case .timeout:
        break
    default:
        fatalError("timeout mismatch")
    }
}
