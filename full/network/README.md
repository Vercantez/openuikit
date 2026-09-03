# Network (Linux starting point)

This directory is a clean-room Linux starting point for Apple's public
`Network` module, seeded from the Xcode 26.1 iPhoneOS 26.1 symbol graph, API
digester, and TBD exports. It is not wired into the shared guest package; that
integration is a later central-review step.

## What is real

- IPv4 and IPv6 address parsing is local and deterministic. Constructing an
  address does not imply that an interface, route, or resolver exists.
- Well-known `NWEndpoint.Port` values (ssh/http/https/…) match their IANA
  numbers. Host/port, unix, service, URL, and opaque endpoint cases compile.
- C-imported `nw_*_t` enum structs use raw values corroborated by the pinned
  `dotnet/macios` bindings (for example `nw_connection_state_ready == 3` and
  `nw_error_domain_posix == 1`).
- `NWTXTRecord` dictionary get/set and Collection iteration are in-process
  only; they do not query mDNS.
- `NWParameters` builder flags are stored locally on the object.

## Fail-closed boundaries

Linux has no Network.framework daemon, path evaluator, or Apple TLS/QUIC stack.
This starting point never fabricates connectivity, discovered peers, or
application bytes.

- `NWPathMonitor.start` delivers exactly one `unsatisfied` snapshot with
  `unsatisfiedReason == .notAvailable` and an empty interface list.
- `NWConnection.start` transitions `setup → preparing → failed(.posix(.EOPNOTSUPP))`
  and reports `viability == false`. `send` / `receive` complete with that error
  and no payload.
- `NWListener.start` and `NWBrowser.start` fail the same way and never accept
  or browse peers.
- C `nw_*` functions that would otherwise hang a completion handler invoke that
  completion with a fail-closed error object, or return nil/false/zero.

## Deferred

- iOS 26 `NetworkConnection` / `NetworkChannel` / result-builder protocol stack
  types are not in this partition.
- Wi-Fi Aware, ethernet-channel hardware, and Security `sec_protocol_*`
  identity beyond opaque stand-ins need an Apple-oracle probe.
- Stdlib integer protocol witnesses that the extractor attributed to Network
  are `not-applicable`.
- Dispatch queue identity, callback timing, and exactly-once delivery on Apple
  are unobserved; Linux invokes path/connection handlers synchronously from
  `start` as a port choice, not as an Apple observation.
