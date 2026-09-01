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
  packets, and the legacy `NWHostEndpoint` / `NWTCPConnection` types that
  NetworkExtension still publishes.
- Public error domains, notification names, start-option keys, and integer
  enum cases compile and round-trip. Managers expose the Apple shared/singleton
  identity (`NEVPNManager.shared()`, `NEFilterManager.shared()`, and the rest).
- The DuckDuckGo-shaped VPN/tunnel surface (`NETunnelProviderManager`,
  `NETunnelProviderSession`, `NEPacketTunnelProvider`, `NEPacketTunnelNetworkSettings`)
  and the Home Assistant-shaped `NEAppPushManager` / `NEAppPushProvider` types
  exist so application code can type-check against this module.

## Fail-closed boundaries

Linux has no `nesessionmanager`, packet-tunnel utun, Network Extension
entitlements, Hotspot Helper, content filter, encrypted DNS settings manager,
relay daemon, or Apple Push-to-app provider runtime. Those operations never
pretend to succeed:

- Preference load/save/remove completes or throws a typed configuration error
  (`NEVPNError.configurationReadWriteFailed`, `NEFilterManagerError`,
  `NEAppPushManagerError`, and the DNS/relay/hotspot/URL-filter equivalents).
- `NEVPNConnection.startVPNTunnel` and `NETunnelProviderSession.startTunnel`
  throw `NEVPNError.connectionFailed`.
- Packet reads complete empty; packet writes return `false`.
- TCP/UDP helper connections stay disconnected and complete with
  `NEAppProxyFlowError.notConnected`.
- `NEURLFilter.verdict(for:)` returns `.unknown`. Filter data providers drop.
- Hotspot apply/register/join and accessory hotspot APIs are omitted or throw.
- `NEFilterDataProvider` defaults to drop rather than allow.

No connected VPN, joined SSID, or Apple network-relay session is fabricated.

## Still deferred

Members that require `SecIdentity` / `SecTrust`, `NWInterface` /
`NWParameters` / `nw_interface_t`, `ASAccessory`, `NSXPCConnection`,
`LocalizedStringResource`, or `AppExtension` are omitted from this isolated
compile (see `coverage.tsv` `deferred` rows and `oracle-questions.tsv`).
Numeric raw values that the pinned graphs do not record are taken from public
Apple header enumerations and called out as oracle questions where the graph is
silent.

`tests/acceptance/test_host.sh` is the supplied gate: it seals the seed,
checks coverage, builds `libNetworkExtension.dylib` with warnings-as-errors,
and runs `tests/agent/NetworkExtensionRuntime.swift`.
