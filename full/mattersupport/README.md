# MatterSupport

Linux starting point for Apple's public `MatterSupport` surface, reconstructed
from the Xcode 26.1 iPhoneOS symbol graph (124 precise identifiers). This
directory is not wired into the shared guest package. A passing isolated host
gate is not integrated Linux success.

## What is real

Value types construct, mutate, compare, and hash:

- `MatterAddDeviceRequest` plus `Home`, `Room`, `Topology`, and `DeviceCriteria`
- `MatterAddDeviceExtensionRequestHandler.DeviceCredential`
- `ThreadScanResult`
- `WiFiScanResult` `ssid` / `rssi`
- `WiFiNetworkAssociation` / `ThreadNetworkAssociation` sentinels and factories

`MatterAddDeviceExtensionRequestHandler` is an `open` `NSObject` subclass.
The default `rooms(in:)` returns `[]`; `configureDevice(named:in:)` is inert.
`MatterAddDeviceRequest.isSupported` is `false`. `perform()` fails closed.

`Codable` declarations exist so the types compile as `Codable`. Keyed layouts
are unobserved on Apple and are not claimed.

## Fail-closed boundaries

Linux has no Apple commissioning UI, Matter fabric, setup-payload entitlement,
device-attestation service, or Wi-Fi/Thread credential store:

- `perform()` throws an internal unavailable error
- Base `validateDeviceCredential`, `selectWiFiNetwork`, `selectThreadNetwork`,
  and `commissionDevice` throw the same internal error
- Association `defaultSystemNetwork` values are sentinels, not joins

Apple's thrown error identity is not public in the graph and is not exposed.

## Matter dependency

Public signatures that mention `MTRSetupPayload`,
`MTRNetworkCommissioningWiFiSecurity`, or `MTRNetworkCommissioningWiFiBand`
are compiled only when `canImport(Matter)` and they use Matter's nominal
types. This isolated host configuration does not import Matter, so those APIs
are omitted and marked unavailable. There are no module-local substitutes.

`tests/agent/MatterSupportDependencyIdentity.swift` is a probe for a future
clean EC2 run that builds guest Matter and Foundation first, then builds
MatterSupport against those modules.

## Tests

`bash tests/acceptance/test_host.sh` compiles `libMatterSupport.dylib` and runs
`tests/agent/MatterSupportRuntime.swift`, which must print
`MATTERSUPPORT_AGENT_RUNTIME_OK`.
