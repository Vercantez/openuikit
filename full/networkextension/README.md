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
  round-trip. Error structs throw typed fail-closed codes.
- Asynchronous completions and delegate deliveries are enqueued exactly once on
  `NetworkExtensionHostCallback.queue`
  (`org.openuikit.NetworkExtension.host-callback`) after the calling function
  returns. That scheduler is a Linux host control. It is not Apple's
  `nesessionmanager` queue and is not evidence of Darwin callback identity.
- Graph-absent public constructors for `NWPath`, `NWTCPConnection`,
  `NWUDPSession`, `NEFlowMetaData`, and `NEHotspotNetwork` are `@_spi(OpenUIKitHost)`
  only. Graph-listed inits such as `NWHostEndpoint.init(hostname:port:)` stay
  public.

## Fail-closed boundaries

Linux has no `nesessionmanager`, packet-tunnel utun, Network Extension
entitlements, Hotspot Helper, content filter, encrypted DNS settings manager,
relay daemon, or Apple Push-to-app provider runtime. Those operations never
pretend to succeed:

- Preference load/save/remove completes or throws a typed configuration error.
- `NEVPNConnection.startVPNTunnel` and `NETunnelProviderSession.startTunnel`
  throw `NEVPNError.connectionFailed`.
- Packet writes return `false`. TCP/UDP helper connections stay disconnected.
- `NEURLFilter.verdict(for:)` returns `.unknown`. Filter data providers drop.
- Hotspot apply/register/join throw or return false.

An immediate fail-closed result is not proof of Apple callback semantics. Tests
prove the **Linux host contract**: return-before-callback, queue identity,
exactly-once delivery, cancellation, delegate replacement, weak ownership, and
concurrent safety.

## Still deferred

Public error-domain strings, start-option keys, remediation map keys,
`NEFilterFlowBytesMax`, and notification name payloads are C-identifier
placeholders. Coverage for those symbols is `declared` until an Apple-oracle
probe records the exact strings.

Members that require `Network.NWInterface` / `Network.NWParameters`,
`SecIdentity` / `SecTrust`, `ASAccessory`, `NSXPCConnection`,
`LocalizedStringResource`, or `AppExtension` are omitted from this isolated
compile (`#if canImport`). This module never defines lookalike modern
`Network` or `Security` types.

`tests/agent/NetworkExtensionDependencyIdentity.swift` is a **future EC2**
probe. It is not compiled by `tests/acceptance/test_host.sh`. Integrated Linux
success requires a cold build with real `Network`, `Security`, and
`ExtensionFoundation` modules, a load test of `libNetworkExtension.dylib`, and
a passing identity/ABI probe. This isolated host run is not that evidence.

`tests/acceptance/test_host.sh` is the supplied gate: it seals the seed,
checks coverage, builds `libNetworkExtension.dylib` with warnings-as-errors,
and runs `tests/agent/NetworkExtensionRuntime.swift`.
