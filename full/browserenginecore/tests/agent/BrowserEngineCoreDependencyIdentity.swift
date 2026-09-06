import BrowserEngineCore
import CoreFoundation
import Foundation

// Future clean EC2 dependency-identity client. Isolated host-gate success
// against toolchain Foundation/CoreFoundation is not integrated guest
// CoreFoundation success. This file is not compiled by the sealed host gate.
//
// Expected EC2 steps (no local Docker):
// 1. Build guest CoreFoundation and Foundation modules and dylibs.
// 2. Build BrowserEngineCore with those modules on `-I` / `-L`.
// 3. Link this file as a client that imports BrowserEngineCore and
//    CoreFoundation.
// 4. Pass genuine CoreFoundation.CFString / Foundation.NSError values through
//    public BrowserEngineCore APIs (BEAudioSession wrapping and the
//    fail-closed setPreferredOutput NSError).
// 5. Confirm `setPreferredOutput` still fails closed and `be_kevent` still
//    returns -1.
// 6. Run with `LD_LIBRARY_PATH` covering those dylibs.
// 7. Confirm `BROWSERENGINECORE_DEPENDENCY_IDENTITY_OK` and that
//    `libBrowserEngineCore.dylib` was loaded.

private func assertNotBrowserEngineCoreType<T>(_ value: T) {
    precondition(!String(reflecting: type(of: value)).hasPrefix("BrowserEngineCore."))
}

func assertCoreFoundationIdentity() {
    let cfString: CFString = "browserenginecore-identity" as CFString
    assertNotBrowserEngineCoreType(cfString)
    precondition(CFGetTypeID(cfString) == CFStringGetTypeID())

    let session = AVAudioSession()
    assertNotBrowserEngineCoreType(session)
    let wrapper = BEAudioSession(audioSession: session)
    do {
        try wrapper.setPreferredOutput(nil)
        preconditionFailure("Linux must not invent AVAudioSession routing")
    } catch let error as NSError {
        assertNotBrowserEngineCoreType(error)
        precondition(error.domain == "BrowserEngineCore.linux.unavailable")
        precondition(error.code == 1)
        let description = error.userInfo[NSLocalizedDescriptionKey] as? String
        precondition(description?.contains("setPreferredOutput") == true)
        _ = (description as CFString?)
    } catch {
        preconditionFailure("unexpected error type \(error)")
    }
}

func browserEngineCoreDependencyIdentityMain() {
    assertCoreFoundationIdentity()
    print("BROWSERENGINECORE_DEPENDENCY_IDENTITY_OK")
}
