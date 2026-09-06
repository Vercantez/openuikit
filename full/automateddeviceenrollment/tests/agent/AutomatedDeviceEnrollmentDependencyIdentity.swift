import AutomatedDeviceEnrollment
import Foundation
@_spi(OpenUIKitHost) import AutomatedDeviceEnrollment

// Future clean EC2 dependency-identity client. Isolated host-gate success
// against toolchain Foundation is not integrated guest success. This file is
// not compiled by the sealed host gate.
//
// Expected EC2 steps (no local Docker):
// 1. Build guest Foundation (and its dylib).
// 2. Build AutomatedDeviceEnrollment with that module on `-I` / `-L`.
// 3. Link this file as a client that imports AutomatedDeviceEnrollment and Foundation.
// 4. Run with `LD_LIBRARY_PATH` covering those dylibs.
// 5. Confirm `AUTOMATEDDEVICEENROLLMENT_DEPENDENCY_IDENTITY_OK` and that
//    `libAutomatedDeviceEnrollment.dylib` was loaded.

private func assertNotAutomatedDeviceEnrollmentType<T>(_ value: T) {
    precondition(!String(reflecting: type(of: value)).hasPrefix("AutomatedDeviceEnrollment."))
}

func assertFoundationIdentity() {
    let box = AutomatedDeviceEnrollmentBoolBox(false)
    let binding = AutomatedDeviceEnrollmentHostControl.boolBinding(to: box)
    let modified = EmptyView().automatedDeviceEnrollmentAddition(isPresented: binding)
    _ = modified
    precondition(box.value == false)

    let payload = Data([0x4f, 0x4b])
    assertNotAutomatedDeviceEnrollmentType(payload)
    precondition(payload.count == 2)
    _ = Foundation.Date.self
    _ = Foundation.Data.self
}

func automatedDeviceEnrollmentDependencyIdentityMain() {
    assertFoundationIdentity()
    print("AUTOMATEDDEVICEENROLLMENT_DEPENDENCY_IDENTITY_OK")
}
