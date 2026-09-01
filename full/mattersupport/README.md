# MatterSupport

Linux starting point for Apple's public `MatterSupport` surface, reconstructed
from the Xcode 26.1 iPhoneOS symbol graph (124 precise identifiers). This
directory is not wired into the shared guest package.

## What is real

Value types construct, mutate, compare, hash, and round-trip through a **local**
`Codable` representation:

- `MatterAddDeviceRequest` plus `Home`, `Room`, `Topology`, and `DeviceCriteria`
- `MatterAddDeviceExtensionRequestHandler.DeviceCredential`
- `WiFiScanResult` / `ThreadScanResult`
- `WiFiNetworkAssociation` / `ThreadNetworkAssociation` sentinels and factories

`MatterAddDeviceExtensionRequestHandler` is an `open` `NSObject` subclass.
Apps can override `rooms(in:)`, `configureDevice(named:in:)`,
`validateDeviceCredential(_:)`, `selectWiFiNetwork(from:)`,
`selectThreadNetwork(from:)`, and `commissionDevice(in:onboardingPayload:commissioningID:)`.
The default `rooms(in:)` returns `[]`; `configureDevice(named:in:)` is inert.

`MatterAddDeviceRequest.isSupported` is `false`.

## Fail-closed boundaries

Linux has no Apple commissioning UI, Matter fabric, setup-payload entitlement,
device-attestation service, or Wi-Fi/Thread credential store. The following
never fabricate success:

- `MatterAddDeviceRequest.perform()` throws `MatterSupportError`
- Base `validateDeviceCredential`, `selectWiFiNetwork`, `selectThreadNetwork`,
  and `commissionDevice` throw `MatterSupportError`
- A non-nil `setupPayload` is stored only; it is not parsed and is dropped on
  `Codable` round-trip
- `WiFiNetworkAssociation.defaultSystemNetwork` and
  `ThreadNetworkAssociation.defaultSystemNetwork` are sentinels, not joins

`MatterSupportError` is a Linux-local error type. Apple's thrown error identity
is an oracle question.

## Matter stand-ins

There is no `Matter` module in this seed. `MTRSetupPayload`,
`MTRNetworkCommissioningWiFiSecurity`, and `MTRNetworkCommissioningWiFiBand`
are local stand-ins so MatterSupport signatures compile. They are not a Matter
port. Central review should replace them with the real Matter types when that
module exists.

Local `Codable` is for in-process round-trip only. Apple keyed-container layout
is unobserved.

## Tests

`bash tests/acceptance/test_host.sh` compiles `libMatterSupport.dylib` and runs
`tests/agent/MatterSupportRuntime.swift`, which must print
`MATTERSUPPORT_AGENT_RUNTIME_OK`.
