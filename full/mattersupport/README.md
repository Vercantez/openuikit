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
- `Codable` round-trips a Linux-local tagged layout (Home/Room `displayName`,
  DeviceCriteria `kind` tags, association `kind` tags). Darwin coding keys
  remain unobserved; those rows are now `implemented` against the Linux layout
  only.

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

## Depth pass 2026-09

Coverage of the 124 exact public identifiers:

| status | before | after |
| --- | --- | --- |
| implemented | 98 | 118 |
| declared | 20 | 0 |
| deferred | 6 | 6 |
| unavailable | 0 | 0 |
| not-applicable | 0 | 0 |

The 20-app corpus touches MatterSupport only in home-assistant-ios
(`MatterRequestHandler` subclass + `MatterAddDeviceRequest(topology:shouldScanNetworks:)`
then `perform()`). Those handler hooks, topology/home/room values, scan-result
fields (`networkName` / `extendedPANID` / `extendedAddress`), and the two
`ThreadNetworkAssociation` factories are implemented. The canonical inits that
take `MTRSetupPayload?` stay deferred; Home Assistant's call site typechecks
against the host SPI init that omits that Matter type.

Raised to `implemented`: the 20 Linux-local `Codable` encode/from pairs, each
with a focused round-trip test. Still deferred: the six Matter-typed members
(`setupPayload`, two request inits, `WiFiScanResult.security` / `band` / canonical
ssid-rssi-security-band init).

Top-5 evidence distribution among 118 implemented rows (40% cap = 47):

| citations | share | test |
| --- | --- | --- |
| 14 | 11.9% | `testDeviceCriteriaCases` (table-driven enum members) |
| 14 | 11.9% | `testThreadScanResultStorage` |
| 9 | 7.6% | `testDeviceCredentialStorage` |
| 8 | 6.8% | `testAddDeviceRequestStorage` |
| 8 | 6.8% | `testTopologyValueSemantics` |

No non-enum test exceeds the bulk-relabel cap. Evidence form is
`test:full/mattersupport/tests/agent/<File>Tests.swift#testName`.
