# DeviceCheck

This directory is a fail-closed portable `DeviceCheck` framework tranche. It
reconstructs the public Xcode 26.1 Swift surface from the committed symbol
graph and public dynamic boundary. It is not wired into the shared guest
package; that integration is a separate central review step.

Linux has no Apple DeviceCheck token service, App Attest, or Secure Enclave
attestation. `DCDevice.current.isSupported` and
`DCAppAttestService.shared.isSupported` are therefore `false`. Every callback
completes once with a nil result and a typed `DCError(.featureUnsupported)`.
The native async overloads throw the same error. The implementation never
fabricates a device token, key identifier, attestation, or assertion.

`DCDevice.current` and `DCAppAttestService.shared` are stable singleton
identities. Private TBD classes (`DCAppAttestDeviceService`,
`DCAppAttestServicePriv`, `DCAppAttestWebAuthService`) are explicit
exclusions and are not part of this module.

`DCErrorDomain` and `DCError.errorDomain` are
`com.apple.devicecheck.error`, matching the Xcode 26.1 macOS runtime.
`DCError` preserves the caller-supplied `userInfo` on both `userInfo` and
`errorUserInfo`; the default initializer leaves both dictionaries empty and
does not insert a localized-description mapping. Equality uses Foundation
dictionary value equality, so `["x": 1]` is not `["x": "1"]`. Hashing uses
only the error code, matching the Xcode 26.1 runtime. Numeric
`DCError.Code` values follow the public header enumeration.

This cloud runner still has no Apple DeviceCheck/App Attest service, so Apple
callback timing and cryptographic success are not claimed.

`tests/test_devicecheck_host.sh` typechecks the committed source-surface
program, cold-runs the committed guest runtime on Linux `swiftc`, runs the
`DCError` domain/userInfo parity helper, and audits the public/private
boundary plus provenance and corpus required-surface coverage without
modifying reference evidence or application sources.
