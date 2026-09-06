@_spi(OpenUIKitHost) import LockedCameraCapture
import Foundation

// Future clean EC2 dependency-identity client. Isolated host-gate success
// against toolchain Foundation is not integrated guest success. This file is
// not compiled by the sealed host gate.
//
// Expected EC2 steps (no local Docker):
// 1. Build guest Foundation (and its dylib).
// 2. Build LockedCameraCapture with that module on `-I` / `-L`.
// 3. Link this file as a client that imports LockedCameraCapture and Foundation.
// 4. Run with `LD_LIBRARY_PATH` covering those dylibs.
// 5. Confirm `LOCKEDCAMERACAPTURE_DEPENDENCY_IDENTITY_OK` and that
//    `libLockedCameraCapture.dylib` was loaded.

private func assertNotLockedCameraCaptureType<T>(_ value: T) {
    precondition(!String(reflecting: type(of: value)).hasPrefix("LockedCameraCapture."))
}

func assertFoundationIdentity() {
    let session: LockedCameraCaptureSession
    do {
        session = try LockedCameraCaptureSession.hostMakeSession()
    } catch {
        preconditionFailure("session directory")
    }
    let url: URL = session.sessionContentURL
    assertNotLockedCameraCaptureType(url)
    precondition(url.isFileURL)

    let error = LockedCameraCaptureSession.ApplicationLaunchError.unknown as NSError
    precondition(error.domain == LockedCameraCaptureSession.ApplicationLaunchError.errorDomain)
    precondition(error.code == 0)
    _ = Foundation.Date.self
    _ = Foundation.Data.self
}

func lockedCameraCaptureDependencyIdentityMain() {
    assertFoundationIdentity()
    print("LOCKEDCAMERACAPTURE_DEPENDENCY_IDENTITY_OK")
}
