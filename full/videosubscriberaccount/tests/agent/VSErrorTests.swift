import Foundation
import VideoSubscriberAccount

func testErrorDomainConstant() {
    precondition(VSErrorDomain == "VSErrorDomain")
    precondition(VSError.errorDomain == VSErrorDomain)
}

func testErrorInfoKeys() {
    precondition(VSErrorInfoKeySAMLResponse == "VSErrorInfoKeySAMLResponse")
    precondition(VSErrorInfoKeySAMLResponseStatus == "VSErrorInfoKeySAMLResponseStatus")
    precondition(
        VSErrorInfoKeyUnsupportedProviderIdentifier
            == "VSErrorInfoKeyUnsupportedProviderIdentifier"
    )
    precondition(
        VSErrorInfoKeyAccountProviderResponse == "VSErrorInfoKeyAccountProviderResponse"
    )
}

func testErrorCodeRawValues() {
    precondition(VSError.Code.accessNotGranted.rawValue == 0)
    precondition(VSError.Code.unsupportedProvider.rawValue == 1)
    precondition(VSError.Code.userCancelled.rawValue == 2)
    precondition(VSError.Code.serviceTemporarilyUnavailable.rawValue == 3)
    precondition(VSError.Code.providerRejected.rawValue == 4)
    precondition(VSError.Code.invalidVerificationToken.rawValue == 5)
    precondition(VSError.Code.rejected.rawValue == 6)
    precondition(VSError.Code.unsupported.rawValue == 7)
    precondition(VSError.Code(rawValue: 0) == VSError.Code.accessNotGranted)
    precondition(VSError.Code(rawValue: 7) == .unsupported)
    precondition(VSError.Code(rawValue: 8) == nil)
    precondition(VSError.Code.accessNotGranted != .unsupported)
    precondition(VSError.Code.rejected.hashValue == VSError.Code.rejected.hashValue)
    var hasher = Hasher()
    VSError.Code.unsupported.hash(into: &hasher)
    _ = hasher.finalize()
}

func testErrorStaticCodes() {
    precondition(VSError.accessNotGranted == .accessNotGranted)
    precondition(VSError.unsupportedProvider == .unsupportedProvider)
    precondition(VSError.userCancelled == .userCancelled)
    precondition(VSError.serviceTemporarilyUnavailable == .serviceTemporarilyUnavailable)
    precondition(VSError.providerRejected == .providerRejected)
    precondition(VSError.invalidVerificationToken == .invalidVerificationToken)
    precondition(VSError.rejected == .rejected)
    precondition(VSError.unsupported == .unsupported)
}

func testErrorStruct() {
    let error = VSError(
        .unsupportedProvider,
        userInfo: [
            NSLocalizedDescriptionKey: "no provider",
            VSErrorInfoKeyUnsupportedProviderIdentifier: "com.example.tv",
        ]
    )
    precondition(error.code == .unsupportedProvider)
    precondition(error.errorCode == 1)
    precondition(error.errorUserInfo[NSLocalizedDescriptionKey] as? String == "no provider")
    precondition(error.userInfo[NSLocalizedDescriptionKey] as? String == "no provider")
    precondition(error.localizedDescription == "no provider")
    precondition(error == VSError(.unsupportedProvider))
    precondition(error != VSError(.unsupported))
    precondition(error.hashValue == VSError(.unsupportedProvider).hashValue)
    var hasher = Hasher()
    error.hash(into: &hasher)
    _ = hasher.finalize()
    precondition(VSError.Code.unsupportedProvider ~= error)
    precondition(!(VSError.Code.unsupported ~= error))
    let fallback = VSError(.unsupported)
    precondition(fallback.localizedDescription.contains("unsupported"))
    precondition(fallback.errorCode == 7)
}
