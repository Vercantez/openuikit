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
- `NWTXTRecord` dictionary get/set, Collection iteration, and RFC 6763
  length-prefixed `data` encode/decode are in-process only; they do not
  query mDNS.
- `NWProtocolWebSocket.Frame` encodes and decodes RFC 6455 frames (masking,
  opcodes, fragmentation, 16/64-bit lengths, close codes) against the
  §5.7 vectors. No HTTP/TLS handshake is performed.
- `NWProtocolFramer.Instance.parseInput` / `writeOutput` / `handleInput` run
  through `NWProtocolFramerHostDriver` with a length-prefixed host framer.

## Fail-closed boundaries

Linux has no Network.framework daemon, Apple TLS/QUIC stack, or mDNS responder.

- TLS parameters (`NWParameters.tls`, any `NWProtocolTLS.Options` on the stack)
  fail with `NWError.tls(-9800)` (`errSSLProtocol`). No handshake is attempted.
  `sec_protocol_options.encodedData` is stored locally only.
- QUIC connections (`NWParameters.quic` / `.quicDatagram`) fail with
  `NWError.posix(.EOPNOTSUPP)`. `NWProtocolQUIC.Options` remains a data model.
- `NWListener` with a Bonjour/application `Service` fails start with
  `EOPNOTSUPP` (no mDNS advertisement). Port-only listeners still bind.
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

## Depth pass 2026-09 (wave 8)

Second pass over the existing first-pass tree (3047 precise IDs). Coverage
before this pass: **1182 implemented / 872 declared / 333 deferred / 0
unavailable / 660 not-applicable**.

This pass keeps the POSIX TCP/UDP loopback transport and extends it with RFC
6455 WebSocket framing, RFC 6763 TXT encode/decode, a framer host driver,
QUIC/TLS/mDNS fail-closed paths, viability/betterPath updates, and documented
TCP/UDP/IP option defaults. New evidence lives in focused
`tests/agent/*Tests.swift` files. First-pass tests remain.

Coverage after this pass: **1215 implemented / 862 declared / 310 deferred /
0 unavailable / 660 not-applicable** (2077 nondeferred).

Top-5 `implemented` evidence distribution (of 1215):

1. `NetworkTests.swift#testCEnumRawValuesFromMacios` — 191 rows (15.7%)
   (C `nw_*` / `k…` enum constants; table-driven raw values)
2. `NetworkTests.swift#testNWInterfaceAndPathFromGetifaddrs` — 110 (9.1%)
3. `NetworkTests.swift#testNWParametersPresetsAndBuilders` — 94 (7.7%)
4. `NetworkTests.swift#testCAPITypealiasesAndSmoke` — 92 (7.6%)
5. `NetworkTests.swift#testTCPLoopbackRoundTrip` — 72 (5.9%)

No non-exempt test is cited by more than 40% of implemented rows (largest
remaining family test: `testBrowserDescriptorsFailClosedWithPOSIXError` at
54/1215 = 4.4%).

Environment: `swiftc` reports Swift 6.2.4, target `x86_64-unknown-linux-gnu`.
`.cursor/verify-cloud-environment.sh` did not emit
`CURSOR_SWIFT_ENVIRONMENT_OK` because `scratch/ladder-corpus/focus-ios` is
absent on this VM. The sealed gate compiles with a clean product tree
(`products=clean`). Active Cursor Build observed on this run was
`bld-20260905-9aa65d65-b87d-46a7-b154-e2f1440dbba3` (campaign expected
`bld-20260901-d3266600-d87b-438f-94c1-d1aa48036e87`). Starting commit
`dd4c8bca7e8735289928bbd1abd44f4b35815308` matched.
