import Foundation
import SafariServices

// Future clean EC2 dependency-identity client. Isolated host-gate success
// against toolchain Foundation is not integrated guest-Foundation success.
//
// Expected EC2 steps:
// 1. Build the actual guest Foundation module and `libFoundation.dylib`.
// 2. Build SafariServices with that Foundation on `-I` / `-L`.
// 3. Link this file as a client that imports SafariServices and Foundation.
// 4. Run with `LD_LIBRARY_PATH` covering both dylibs.
// 5. Confirm `SAFARISERVICES_DEPENDENCY_IDENTITY_OK` and that
//    `libSafariServices.dylib` was loaded.

func safariServicesDependencyIdentityProbe() {
    let url = URL(string: "https://example.invalid/identity")!
    precondition(url.isFileURL == false)

    let schemeOK = SSReadingList.supportsURL(url)
    precondition(schemeOK)

    let configuration = SFSafariViewControllerConfiguration()
    configuration.entersReaderIfAvailable = true
    let copied: SFSafariViewControllerConfiguration = configuration.copy()
    precondition(copied.entersReaderIfAvailable)

    let error: any Error = SFError(.missingEntitlement, userInfo: ["id": url.absoluteString])
    let nsError = error as NSError
    precondition(type(of: nsError) == NSError.self)
    precondition(nsError.domain == SFErrorDomain)
    precondition(nsError.code == SFError.Code.missingEntitlement.rawValue)
    precondition(nsError.userInfo["id"] as? String == url.absoluteString)

    print("SAFARISERVICES_DEPENDENCY_IDENTITY_OK")
}
