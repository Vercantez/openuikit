# MatterSupport

Linux starting point for Apple's public `MatterSupport` module, reconstructed
from the pinned Xcode 26.1 iPhoneOS symbol graph, the in-repo fan-out repair
spec (`full/framework-fanout/repairs-wave2-pr30-40.json` MatterSupport entry),
and Apple public documentation. The private platform branch
`cursor/port-mattersupport-to-linux-2f6c` (legacy PR #30) could not be fetched
with this token. This directory is not wired into the shared guest package. A
passing isolated host gate is not integrated Linux success.

## What is real

The public Swift surface that does not require Matter compiles to
`libMatterSupport.dylib`.

- `MatterAddDeviceRequest.Home`, `Room`, and `Topology` store `displayName` /
  `ecosystemName` / `homes` and are `Hashable` / `Equatable`.
- `MatterAddDeviceRequest.DeviceCriteria` cases from the canonical graph
  (`allDevices`, `fabricNode`, `serialNumber`, `commissioningID`, `vendorID`,
  `productID`, `all`, `any`, `not`) compare and hash by their associated values.
- `MatterAddDeviceRequest.isSupported` is `false`.
- `MatterAddDeviceRequest.perform()` always throws
  `NSError(domain: "MatterSupport.linux.unavailable", code: 1)`. It does not
  present UI.
- `MatterAddDeviceExtensionRequestHandler` is an `open` `NSObject` subclass.
  Base `rooms(in:)` returns `[]`. Base `configureDevice` is a no-op. Base
  `commissionDevice`, `validateDeviceCredential`, `selectWiFiNetwork`, and
  `selectThreadNetwork` throw the same unavailable `NSError`. Subclass
  overrides dispatch through the existential/`open` method table.
- `DeviceCredential` and `ThreadScanResult` store the graph fields.
- `WiFiNetworkAssociation.defaultSystemNetwork` is distinct from
  `network(ssid:credentials:)`. `ThreadNetworkAssociation.defaultSystemNetwork`
  is distinct from `network(extendedPANID:)`.
- `Codable` round-trips a Linux-local tagged layout so the graph surface
  compiles. Darwin keys are unobserved and those rows are `declared`.

## Fail-closed boundaries

Linux has no Apple commissioning sheet, MatterSupport app extension, or
(in this isolated host) Matter module.

- There is no public `MatterSupportError` type; the canonical graph has none.
- `MTRSetupPayload`, `MTRNetworkCommissioningWiFiSecurity`, and
  `MTRNetworkCommissioningWiFiBand` are not redeclared here. The six public
  signatures that mention those types are compiled only under
  `canImport(Matter)` and are `deferred` in this configuration.
- Host-only `@_spi(OpenUIKitHost)` inits construct `MatterAddDeviceRequest`
  and `WiFiScanResult` without those types. They are not canonical API.

## Still open

See `oracle-questions.tsv` for Darwin `perform()` error identity, `isSupported`
platform matrix, Codable keys, base-class throw identities, and Matter
option-set raw values.

`tests/agent/MatterSupportRuntime.swift` is the isolated host probe
(`MATTERSUPPORT_AGENT_RUNTIME_OK`).
`tests/agent/MatterSupportDependencyIdentity.swift` is prepared for a future
clean EC2 run that builds guest Matter first (`import Matter`).

Run `bash tests/acceptance/test_host.sh` from this directory. Keep generated
products out of the tree.
