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

The committed evidence names `_DCErrorDomain` but does not record the string
payload. This tranche uses `"DCErrorDomain"`, matching the `NS_ERROR_ENUM`
identifier. Numeric `DCError.Code` values follow the public header
enumeration. This cloud runner has no Apple runtime oracle, so the exact
Apple domain-string bytes and Apple-side callback timing are not claimed.

`tests/test_devicecheck_host.sh` typechecks the committed source-surface
program, cold-runs the committed guest runtime on Linux `swiftc`, audits the
public/private boundary, and checks provenance plus corpus required-surface
coverage without modifying reference evidence or application sources.
