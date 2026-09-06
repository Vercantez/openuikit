import BrowserKit
import Foundation

// Future clean EC2 dependency-identity client. Isolated host-gate success
// against toolchain Foundation is not integrated guest-Foundation success.
//
// Expected EC2 steps (no local Docker):
// 1. Build the actual guest Foundation module and `libFoundation.dylib`.
// 2. Build BrowserKit with that Foundation on `-I` / `-L` (and rpath as needed).
// 3. Link this file as a client that imports BrowserKit and Foundation.
// 4. Run with `LD_LIBRARY_PATH` covering both dylibs.
// 5. Confirm `BROWSERKIT_DEPENDENCY_IDENTITY_OK` and that `libBrowserKit.dylib`
//    was loaded.

private func assertNotBrowserKitType<T>(_ value: T) {
    precondition(!String(reflecting: type(of: value)).hasPrefix("BrowserKit."))
}

func browserKitDependencyIdentityProbe() {
    let availability = BEAvailability()
    precondition(availability is NSObject)
    let nsObject: NSObject = availability
    assertNotBrowserKitType(type(of: nsObject).description())
    precondition((nsObject as AnyObject) === availability)

    var deliveredError: (any Error)?
    BEAvailability.isEligible(for: .webBrowser) { eligible, error in
        precondition(eligible == false)
        deliveredError = error
    }
    let nsError = deliveredError as NSError?
    precondition(nsError != nil)
    let domain = nsError!.domain
    let code = nsError!.code
    assertNotBrowserKitType(domain)
    precondition(type(of: domain) == String.self)
    precondition(type(of: code) == Int.self)
    precondition(domain == BrowserKitHostError.errorDomain)
    precondition(code == BrowserKitHostError.eligibilityUnavailable.errorCode)

    let userInfo = nsError!.userInfo
    assertNotBrowserKitType(userInfo)
    _ = Foundation.NSObject.self
    _ = Foundation.NSError.self
}

#if BROWSERKIT_IDENTITY_MAIN
browserKitDependencyIdentityProbe()
print("BROWSERKIT_DEPENDENCY_IDENTITY_OK")
#endif
