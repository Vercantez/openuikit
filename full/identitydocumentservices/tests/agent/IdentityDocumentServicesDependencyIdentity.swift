import Foundation
import IdentityDocumentServices

// Isolated host-gate success against toolchain Foundation is not integrated
// guest-Foundation success. This probe is for a future clean EC2 run that
// builds guest Foundation first, then IdentityDocumentServices with that `-I` / `-L`.
// The host gate does not compile this file.

func identityDocumentServicesDependencyIdentityProbe() {
    let data = Data("identity-document-services".utf8)
    let url = URL(string: "https://example.invalid/presentment")!
    let date = Date(timeIntervalSince1970: 1_700_000_000)
    let uuid = UUID()
    precondition(type(of: data) == Data.self)
    precondition(type(of: url) == URL.self)
    precondition(type(of: date) == Date.self)
    precondition(type(of: uuid) == UUID.self)
    precondition(!String(reflecting: type(of: data)).hasPrefix("IdentityDocumentServices."))
    precondition(!String(reflecting: type(of: url)).hasPrefix("IdentityDocumentServices."))
    precondition(!String(reflecting: type(of: date)).hasPrefix("IdentityDocumentServices."))

    let response = ISO18013MobileDocumentResponse(responseData: data)
    precondition(response.responseData == data)

    let raw = IdentityDocumentWebPresentmentRawRequest(
        requestType: .iso18013MobileDocument,
        requestData: data
    )
    precondition(raw.requestData == data)

    let registration = MobileDocumentRegistration(
        mobileDocumentType: "org.iso.18013.5.mDL",
        supportedAuthorityKeyIdentifiers: [data],
        documentIdentifier: uuid.uuidString,
        invalidationDate: date
    )
    precondition(registration.supportedAuthorityKeyIdentifiers == [data])
    precondition(registration.invalidationDate == date)
    precondition(registration.documentIdentifier == uuid.uuidString)

    let origin = url
    let validator = IdentityDocumentWebPresentmentRawRequestValidator()
    do {
        _ = try validator.validateISO18013MobileDocumentRequest(data, origin: origin)
        preconditionFailure("Linux validator must not succeed")
    } catch IdentityDocumentPresentmentError.notEntitled {
        ()
    } catch {
        preconditionFailure("expected notEntitled, got \(error)")
    }
}

#if IDENTITYDOCUMENTSERVICES_IDENTITY_MAIN
identityDocumentServicesDependencyIdentityProbe()
print("IDENTITYDOCUMENTSERVICES_DEPENDENCY_IDENTITY_OK")
#endif
