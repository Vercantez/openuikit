# Network (Linux starting point)

This directory is a clean-room Linux starting point for Apple's public
`Network` module, seeded from the Xcode 26.1 iPhoneOS 26.1 symbol graph, API
digester, and TBD exports. It is not wired into the shared guest package; that
integration is a later central-review step.

## What is real

- IPv4 / IPv6 parsing is local. RFC 1122 `127.0.0.0/8` is loopback, RFC 3927
  `169.254.0.0/16` is link-local, RFC 1112 `224.0.0.0/4` is multicast. IPv6
  `init?(String)` accepts a `%zone` suffix and `debugDescription` reprints it.
- `NWEndpoint.Host("127.0.0.1")` / `"::1"` become `.ipv4` / `.ipv6`. Port
  strings that are IANA names (`http`) map to the same numbers as the statics.
- `NWPathMonitor` snapshots `getifaddrs`. Status is `.satisfied` when a
  non-loopback interface has an address, otherwise `.unsatisfied`.
  `isExpensive` / `isConstrained` are false. `supportsIPv4` / `supportsIPv6`
  follow the filtered interface list. `gateways` is filled from
  `/proc/net/route` when that file is readable (empty on Darwin).
- `NWConnection` / `NWListener` speak POSIX TCP and UDP on loopback. A listener
  on `.any` assigns an ephemeral port via `getsockname`. Tests exchange bytes
  between a listener and a client on `127.0.0.1`.
- `NWParameters.tcp` / `.udp` / `.tls` presets and the builder flags are stored
  on the object. `allowLocalEndpointReuse` sets `SO_REUSEADDR`.
- C-imported `nw_*_t` enum structs use raw values corroborated by the pinned
  `dotnet/macios` bindings (for example `nw_connection_state_ready == 3` and
  `nw_error_domain_posix == 1`).
- `NWTXTRecord` dictionary get/set and Collection iteration are in-process
  only; they do not query mDNS.

## Fail-closed boundaries

Linux has no Network.framework daemon, Apple TLS/QUIC stack, or mDNS responder.

- TLS parameters (`NWParameters.tls`, any `NWProtocolTLS.Options` on the stack)
  fail with `NWError.tls(-9800)` (`errSSLProtocol`). No handshake is attempted.
- `NWBrowser.start` fails with `NWError.posix(.EOPNOTSUPP)` and never fabricates
  Bonjour peers.
- `NWConnectionGroup.start` and `NWMulticastGroup` init fail closed the same
  way. Service / opaque endpoints wait then fail with `EOPNOTSUPP`.
- C `nw_*` functions that would otherwise hang a completion handler invoke that
  completion with a fail-closed error object, or return nil/false/zero.

## Deferred

- iOS 26 `NetworkConnection` / `NetworkChannel` / result-builder protocol stack
  types are not in this partition.
- Wi-Fi Aware, ethernet-channel hardware, and Security `sec_protocol_*`
  identity beyond opaque stand-ins need an Apple-oracle probe.
- Stdlib integer protocol witnesses that the extractor attributed to Network
  are `not-applicable`.
- Dispatch queue identity and after-return timing on Apple are unobserved;
  Linux tags the supplied queue and invokes start-time handlers via `sync`
  (or inline when already on that queue) so a host test can observe the first
  snapshot before `start` returns.
