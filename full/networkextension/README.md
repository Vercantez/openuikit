# NetworkExtension (Linux starting point)

This directory is a clean-room Linux port of Apple's public `NetworkExtension`
module, seeded from the Xcode 26.1 iPhoneOS SDK symbol graphs. It is not wired
into the shared guest package; that integration is a separate central review
step.

## What is real

- Configuration objects are ordinary in-memory values: `NEVPNProtocol` /
  `NEVPNProtocolIKEv2` / `NEVPNProtocolIPSec` / `NETunnelProviderProtocol`,
  IPv4/IPv6 routes and settings, DNS (including DoH/DoT subclasses), proxy
  settings, on-demand rules, hotspot configuration objects, filter verdicts,
  packets, and the **legacy NetworkExtension-owned** `NWEndpoint` /
  `NWHostEndpoint` / `NWPath` / `NWTCPConnection` / `NWUDPSession` /
  `NWTLSParameters` classes. Those names are target-owned legacy APIs, not
  counterfeit modern `Network` types.
- Managers expose the Apple shared/singleton identity (`NEVPNManager.shared()`,
  `NEFilterManager.shared()`, and the rest). Integer enum cases compile and
  round-trip. Audited raw values match the Xcode 26.1 Apple oracle:
  `NEURLFilter.Verdict` is `unknown=1, allow=2, deny=3`;
  `NEURLFilterManager.Error` is sequential `1...14` ending at `unknown=14`;
  `NEURLFilterManager.Status` remains `0...4`; `NEVPNConnectionError` is
  sequential `1...19` in header declaration order (client certificates before
  `pluginFailed`). Error structs throw typed fail-closed codes.
- Configuration families that Apple marks `NSCopying` implement
  `copy(with:)` with class-preserving in-memory copies. Protocol, on-demand,
  route, DNS, proxy, and packet-tunnel settings also implement
  `NSSecureCoding` using OpenUIKit overlay keys (not Apple's undocumented
  archive layout).
- `NEURLFilter.init` is `@available(*, unavailable)`, matching the pinned
  Apple header. Clients cannot construct `NEURLFilter`; `verdict(for:)` is a
  class method.
- Asynchronous completions and delegate deliveries are enqueued exactly once on
  `NetworkExtensionHostCallback.queue`
  (`org.openuikit.NetworkExtension.host-callback`) after the calling function
  returns. Tests hold that serial delivery gate, invoke the API, record return
  under a lock, then release and prove exactly one callback. That scheduler is a
  Linux host control. It is not Apple's `nesessionmanager` queue and is not
  evidence of Darwin callback identity.
- Graph-absent public constructors for `NWPath`, `NWTCPConnection`,
  `NWUDPSession`, `NEFlowMetaData`, and `NEHotspotNetwork` are `@_spi(OpenUIKitHost)`
  only. Graph-listed inits such as `NWHostEndpoint.init(hostname:port:)` stay
  public.

## Fail-closed boundaries

Linux has no `nesessionmanager`, packet-tunnel utun, Network Extension
entitlements, Hotspot Helper, content filter, encrypted DNS settings manager,
relay daemon, or Apple Push-to-app provider runtime. Those operations never
pretend to succeed:

- `NEVPNManager` personal VPN preferences persist to an on-disk JSON store of
  NSSecureCoding protocol blobs. `loadFromPreferences` succeeds with no
  saved record. `saveToPreferences` throws `configurationStale` before load
  and `configurationInvalid` without a server address. `startVPNTunnel`
  throws `configurationInvalid` when nothing is saved and
  `configurationDisabled` when `isEnabled` is false. A saved, enabled
  personal VPN drives a documented **simulated** status machine
  (`.invalid` → `.disconnected` → `.connecting` → `.connected` /
  `.disconnecting`) and posts `NEVPNStatusDidChange`. This is not a kernel
  tunnel and not `nesessionmanager`.
- `NETunnelProviderSession.startTunnel` / `sendProviderMessage` stay
  fail-closed (`connectionFailed` / `configurationInvalid`): there is no
  extension host on Linux.
- `NEFilterManager`, `NEDNSProxyManager`, `NEDNSSettingsManager`,
  `NERelayManager`, and `NEHotspotConfigurationManager.apply` throw the
  documented configuration / hotspot errors. `NEHotspotNetwork.fetchCurrent`
  returns `nil`.
- Packet writes return `false`. TCP/UDP helper connections stay disconnected.
- `NEURLFilter.verdict(for:)` returns `.unknown`. Filter data providers drop.
- Hotspot apply/register/join throw or return false.

An immediate fail-closed result is not proof of Apple callback semantics. Tests
prove the **Linux host contract**: return-before-callback, queue identity,
exactly-once delivery, cancellation, delegate replacement, weak ownership, and
concurrent safety.

## Still unavailable (not deferred)

Public error-domain strings, start-option keys, remediation map keys,
`NEFilterFlowBytesMax`, and notification name payloads remain C-identifier
placeholders. The symbols compile and are exercised; exact Apple string
payloads are still oracle questions.

Thirty precise IDs that require `Network.NWInterface` / `Network.NWParameters`,
`SecIdentity` / `SecTrust`, `NSXPCConnection`, `LocalizedStringResource`,
`AppExtension`, or AccessorySetupKit+UIKit are `unavailable` on this isolated
Linux compile (`#if canImport`). `ASAccessory` hotspot joins compile only on
iOS or Linux when both real `AccessorySetupKit` and canonical `UIKit` are
importable. This module never defines lookalike `ASAccessory`, `UIKit`,
`Network`, `Security`, or `ExtensionFoundation` types.

`tests/agent/NetworkExtensionDependencyIdentity.swift` is a **future EC2**
probe. It is not compiled by `tests/acceptance/test_host.sh`. Integrated Linux
success requires a cold build with real `Network`, `Security`,
`ExtensionFoundation`, `AccessorySetupKit`, and `UIKit` modules, a load test
of `libNetworkExtension.dylib`, and a passing identity/ABI probe. This isolated
host run is not that evidence.

`tests/acceptance/test_host.sh` is the supplied gate: it seals the seed,
checks coverage, builds `libNetworkExtension.dylib` with warnings-as-errors,
and runs `tests/agent/NetworkExtensionRuntime.swift`.

## Depth pass 2026-09

App-side NetworkExtension surface for Linux, no extension host.

**Public surface implemented**

- `NEVPNManager.shared()`, on-disk preference store, documented
  `NEVPNError` codes (`configurationInvalid=1`, `configurationDisabled=2`,
  `connectionFailed=3`, `configurationStale=4`, `configurationReadWriteFailed=5`,
  `configurationUnknown=6`), value stores for
  `protocolConfiguration` / `localizedDescription` / `isEnabled` /
  `isOnDemandEnabled` / `onDemandRules`.
- Simulated personal-VPN status machine driven by `startVPNTunnel` /
  `stopVPNTunnel`, plus `NEVPNStatusDidChange`.
- `NEVPNProtocolIKEv2` / `NEVPNProtocolIPSec` / `NETunnelProviderProtocol`
  property stores and NSSecureCoding round-trips (OpenUIKit overlay keys).
- `NEOnDemandRuleConnect` / `Disconnect` / `EvaluateConnection` / `Ignore`,
  `interfaceTypeMatch` / `ssidMatch` / `dnsSearchDomainMatch` / `probeURL`,
  `NEEvaluateConnectionRule`.
- `NETunnelProviderManager.loadAllFromPreferences`,
  `providerBundleIdentifier` / `providerConfiguration`, `copyAppRules`.
- `NEPacketTunnelNetworkSettings` / `NEIPv4Settings` / `NEIPv6Settings` /
  `NEDNSSettings` / `NEProxySettings` value semantics and validation
  (`networkSettingsInvalid` on mismatch, then fail-closed
  `networkSettingsFailed` with no utun).
- `NEAppProxyProvider` / `NEFilterDataProvider` shapes,
  legacy `NWTCPConnection` / `NWUDPSession` fail-closed,
  `NEFilterManagerError` / `NEVPNError` raw values.

**Coverage:** 1192 IDs; 1162 `implemented`, 30 `unavailable`, 0 deferred.

**Fail-closed boundaries:** no packet-tunnel provider runtime, no filter/
DNS-proxy/relay/hotspot activation, no Apple entitlements, simulated VPN
only after a saved enabled configuration.

**Tests run:** `bash full/networkextension/tests/acceptance/test_host.sh`
directly on this Linux host (no docker).

**Environment notes:** `git rev-parse HEAD` at start was
`5cc42895aa4277d0ed2103050b64be03fe813c3e`. `swiftc` is Swift 6.2.4
(`x86_64-unknown-linux-gnu`). `.cursor/verify-cloud-environment.sh` failed
on a missing `scratch/ladder-corpus/focus-ios` pin (unrelated to this
isolated module). The campaign marker recorded for the gate is
`CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean`.
Boot build observed: `bld-20260905-9aa65d65-b87d-46a7-b154-e2f1440dbba3`
(campaign expected `bld-20260901-d3266600-d87b-438f-94c1-d1aa48036e87`).

**Unresolved behavioral questions:** see `oracle-questions.tsv` (error-domain
strings, `NEFilterFlowBytesMax`, Darwin vs NSNotification names, exact
plugin-missing `startVPNTunnel` code on iPhoneOS, `NWInterface` overlay
type, AccessorySetupKit compile-time requirement). NSSecureCoding keys are
OpenUIKit identifiers, not Apple's. The simulated tunnel is a Linux host
control.
