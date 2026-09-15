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
- iOS 26 typed overlay (`TCP`/`UDP`/`IP`/`TLS`/`QUIC`/`WebSocket`/`Framer`/
  `Coder`, `NetworkConnection`/`NetworkChannel`/`NetworkListener`/`NetworkBrowser`)
  wraps the POSIX transport. `start()` reports the first state before returning.
  Loopback TCP/UDP `sendIdempotent` is real.

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

- iOS 26 async `NetworkConnection.run` / `NetworkChannel.send` / `receive` /
  `openStream` / `NetworkListener.run` / `NetworkBrowser.run` stay deferred:
  a blocking wait with no run loop hangs the sealed gate. Linux exposes a
  synchronous `start()` on the typed types instead.
- Wi-Fi Aware, ethernet-channel hardware, and Security `sec_protocol_*`
  identity beyond opaque stand-ins need an Apple-oracle probe.
- Remaining stdlib integer protocol witnesses that the extractor attributed to Network
  are `deferred` (they are not SwiftUI cross-import overlays, so they cannot
  be `not-applicable`).
- Dispatch queue identity and after-return timing on Apple are unobserved;
  Linux tags the supplied queue and invokes start-time handlers via `sync`
  (or inline when already on that queue) so a host test can observe the first
  snapshot before `start` returns.

## Earlier depth repair

Second pass over the existing first-pass tree (3047 precise IDs). Coverage
before this pass: **1182 implemented / 872 declared / 333 deferred / 0
unavailable / 660 not-applicable**.

This pass keeps the POSIX TCP/UDP loopback transport and extends it with RFC
6455 WebSocket framing, RFC 6763 TXT encode/decode, a framer host driver,
QUIC/TLS/mDNS fail-closed paths, viability/betterPath updates, and documented
TCP/UDP/IP option defaults. New evidence lives in focused
`tests/agent/*Tests.swift` files. First-pass tests remain.

The 2026-09-05 merge check refused `9723f04bbedd` because those 660
`not-applicable` rows are stdlib `Int`/`UInt` synthesized witnesses (for
example `s:SLsE1goiySbx_xtFZ::SYNTHESIZED::s:s4Int8V`), not SwiftUI
cross-import overlay IDs. Relabeling them `deferred` (they cannot be
`not-applicable`) produced `439384b4`, which the merge check then refused
for **no depth gain**: implemented **1182 → 968**. Reclassifying overlay
rows is bookkeeping; the depth task is real behaviour with per-identifier
tests.

This repair adds focused `tests/agent/*Tests.swift` functions that actually
call the identifiers they cite (C parameter get/set round-trips, TCP option
setters, TXT dictionary APIs, EstablishmentReport data model, ConnectionGroup
send/message, protocol-definition equality, path DNS/endpoints). Rows without
such a test stay `declared` with `source:full/network/<file>.swift#Symbol`.
C `nw_*` typealiases without a named test stay `declared`. Stdlib integer
and Collection synthesized witnesses stay `deferred`.

Coverage before this depth repair (`439384b4`): **968 implemented / 1051
declared / 1028 deferred / 0 unavailable / 0 not-applicable** (2019
nondeferred). First-pass baseline was **1182 implemented**.

Coverage after this depth repair: **1266 implemented / 754 declared /
1027 deferred / 0 unavailable / 0 not-applicable** (2020 nondeferred).

Top-5 `implemented` evidence distribution (of 1266):

1. `NetworkTests.swift#testCEnumRawValuesFromMacios` — 191 rows (15.1%)
   (C `nw_*` / `k…` enum constants; table-driven raw values)
2. `NetworkTests.swift#testNWInterfaceAndPathFromGetifaddrs` — 87 (6.9%)
3. `NetworkTests.swift#testNWParametersPresetsAndBuilders` — 71 (5.6%)
4. `NetworkTransportTests.swift#testBrowserDescriptorsFailClosedWithPOSIXError`
   — 54 (4.3%)
5. `NetworkWebSocketTests.swift#testWebSocketCloseCodesAndOptions` — 53 (4.2%)

No non-exempt test is cited by more than 40% of implemented rows (largest
remaining family test: `testNWInterfaceAndPathFromGetifaddrs` at 87/1266 =
6.9%). Enum/option-set members share family tests; C `nw_*` typealiases
without a named test are `declared`.

### Third pass (this run)

Before: **1266 implemented / 754 declared / 1027 deferred / 0 unavailable /
0 not-applicable** (2020 nondeferred).

This pass keeps the existing POSIX transport and tests green and adds real
Linux behaviour:

- `NWConnection.localEndpoint` / `remoteEndpoint` / `currentPath` from
  `getsockname` / `getpeername` after TCP and UDP loopback connect.
- C `nw_endpoint_*` host/url/address/bonjour create/get/copy round-trips.
- C QUIC option/metadata get/set storage, WebSocket options/metadata/response,
  IP metadata, proxy/privacy/resolver data model, TXT-adjacent browse
  descriptors, connection-group fail-closed start, data-transfer report
  collect with zero counts plus a real `getifaddrs` loopback interface, and
  a C framer host (`parseInput`/`writeOutput`/`mark_ready`/`wakeup`).
- TLS handshake remains fail-closed with `NWError.tls(-9800)`. QUIC
  connections remain `EOPNOTSUPP`. Bonjour browse/advertise remains
  fail-closed empty.

After: **1548 implemented / 472 declared / 1027 deferred / 0 unavailable /
0 not-applicable** (2020 nondeferred). Implemented gain **+282**.

Top-5 `implemented` evidence distribution (of 1548):

1. `NetworkTests.swift#testCEnumRawValuesFromMacios` — 191 (12.3%)
2. `NetworkTests.swift#testNWInterfaceAndPathFromGetifaddrs` — 87 (5.6%)
3. `NetworkCStructInitTests.swift#testCStructRawValueInitializers` — 83 (5.4%)
   (C imported struct `init(rawValue:)` / `.rawValue` table)
4. `NetworkTests.swift#testNWParametersPresetsAndBuilders` — 71 (4.6%)
5. `NetworkTransportTests.swift#testBrowserDescriptorsFailClosedWithPOSIXError`
   — 54 (3.5%)

Environment: `swiftc` reports Swift 6.2.4, target `x86_64-unknown-linux-gnu`.
`.cursor/verify-cloud-environment.sh` did not emit
`CURSOR_SWIFT_ENVIRONMENT_OK` because `scratch/ladder-corpus/focus-ios` is
absent on this VM. The sealed gate compiles with a clean product tree
(`products=clean`). Active Cursor Build observed on this run was
`bld-20260906-253cd433-7a30-4d11-aad2-8b209b7b2d21` (campaign expected
`bld-20260901-d3266600-d87b-438f-94c1-d1aa48036e87`). Starting commit
`bff8535c68425cc39fb45cb00d447b0981b57242` matched.

`bash full/network/tests/acceptance/test_host.sh` ended:

```
FRAMEWORK_FANOUT_DELIVERABLE_OK module=Network lane=medium-full symbols=3047
FRAMEWORK_FANOUT_REFERENCE_OK
NETWORK_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=Network dylib=libNetwork.dylib
```

The campaign inventory stamp `CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean` is a host-inventory token, not printed by the sealed framework gate. Swift 6.2.4 / linux compiled `libNetwork.dylib` with a clean product tree.

## Depth pass 2026-09 (wave 8)

Before: **1921 implemented / 241 declared / 885 deferred / 0 unavailable /
0 not-applicable** (2162 nondeferred).

This pass adds focused runtime coverage for 304 synthesized
`FixedWidthInteger` witnesses that the pinned Network symbol graph exposes for
the eight concrete signed and unsigned integer widths. The tests exercise bit
width, endian values and initializers, truncation, byte swapping, remainder,
wrapping addition/subtraction, comparisons, range expressions, bitwise
operations, quotient/remainder, strides, shifts, and descriptions for every
concrete type. These are genuine
Swift standard-library behaviors imported into the graph; they do not pretend
to provide an Apple network service. Existing POSIX TCP/UDP, listener, path,
TXT, WebSocket, and framer behavior is unchanged. TLS, QUIC, Bonjour/mDNS, and
browser service discovery retain their explicit fail-closed boundaries.

After: **2225 implemented / 241 declared / 581 deferred / 0 unavailable /
0 not-applicable** (2466 nondeferred). Implemented gain **+304**.

Top-5 `implemented` evidence distribution (of 2225):

1. `NetworkTests.swift#testCEnumRawValuesFromMacios` — 191 (8.6%)
2. `NetworkIntegerWitnessTests.swift#testFixedWidthIntegerComparableWitnesses`
   — 88 (4.0%)
3. `NetworkTests.swift#testNWInterfaceAndPathFromGetifaddrs` — 87 (3.9%)
4. `NetworkCStructInitTests.swift#testCStructRawValueInitializers` — 83 (3.7%)
5. `NetworkTests.swift#testNWParametersPresetsAndBuilders` — 71 (3.2%)

The required environment probe emitted
`CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=scratch-corpus evidence=dotnet-macios`.
The sealed host gate then ended with the deliverable, reference, runtime, and
host markers recorded below:

```
FRAMEWORK_FANOUT_DELIVERABLE_OK module=Network lane=medium-full symbols=3047
FRAMEWORK_FANOUT_REFERENCE_OK
NETWORK_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=Network dylib=libNetwork.dylib
```

Unresolved behavioral questions remain recorded in `oracle-questions.tsv`;
in particular, callback timing and Apple service behavior remain deferred
rather than inferred from declarations or independent bindings.

### Fourth pass (this run)

Before: **1548 implemented / 472 declared / 1027 deferred / 0 unavailable /
0 not-applicable** (2020 nondeferred).

This pass keeps the POSIX TCP/UDP loopback transport, RFC 6455 WebSocket
framer, RFC 6763 TXT encode/decode, framer host driver, and TLS/QUIC/mDNS
fail-closed paths, and adds the iOS 26 typed overlay in
`NetworkTyped.swift`:

- `TCP` / `UDP` / `IP` / `TLS` / `QUIC` / `WebSocket` / `Framer` / `Coder`
  protocol-stack option types with documented defaults and result-builder
  stacking (`ProtocolStackBuilder`, `NWParametersBuilder`,
  `NWParametersProvider` fluent builders).
- `NetworkConnection` / `NetworkChannel` / `NetworkListener` wrapping POSIX
  `NWConnection` / `NWListener` with a synchronous `start()` that reports
  the first state before returning. Loopback TCP/UDP bind, connect, and
  `sendIdempotent` are real. QUIC `start` and `openStream` fail closed with
  `EOPNOTSUPP`. TLS handshake remains `NWError.tls(-9800)`.
- `NetworkBrowser` / `BonjourListenerProvider` fail closed without mDNS.
- C establishment/resolution report snapshots from
  `nw_connection_access_establishment_report` (zero-duration, no proxy)
  and WebSocket client-request header/subprotocol enumeration.

Stdlib `FixedWidthInteger` / `AdditiveArithmetic` synthesized witnesses stay
`deferred`. SwiftUI overlay IDs are not present. Async `run` / `send` /
`receive` / `openStream` USRs stay deferred (a blocking wait would hang the
sealed gate).

After: **1921 implemented / 241 declared / 885 deferred / 0 unavailable /
0 not-applicable** (2162 nondeferred). Implemented gain **+373**.

Top-5 `implemented` evidence distribution (of 1921):

1. `NetworkTests.swift#testCEnumRawValuesFromMacios` — 191 (9.9%)
   (C `nw_*` / `k…` enum constants; table-driven raw values)
2. `NetworkTests.swift#testNWInterfaceAndPathFromGetifaddrs` — 87 (4.5%)
3. `NetworkCStructInitTests.swift#testCStructRawValueInitializers` — 83 (4.3%)
4. `NetworkTests.swift#testNWParametersPresetsAndBuilders` — 71 (3.7%)
5. `NetworkTypedTransportTests.swift#testNWParametersProviderFluentBuildersOnTCP`
   — 66 (3.4%)

No non-exempt test is cited by more than 40% of implemented rows (largest
share 191/1921 = 9.9%). Enum/option-set members share family tests; C `nw_*`
typealiases without a named test stay `declared`.

Environment: `swiftc` reports Swift 6.2.4, target `x86_64-unknown-linux-gnu`.
`.cursor/verify-cloud-environment.sh` did not emit
`CURSOR_SWIFT_ENVIRONMENT_OK` because `scratch/ladder-corpus/focus-ios` is
absent on this VM. The sealed gate compiles with a clean product tree
(`products=clean`). Active Cursor Build observed on this run was
`bld-20260906-253cd433-7a30-4d11-aad2-8b209b7b2d21` (campaign expected
`bld-20260901-d3266600-d87b-438f-94c1-d1aa48036e87`). Starting commit
`2de7152a12f3beb34a4c1e92dc0e849af9a1d88b` matched.

`bash full/network/tests/acceptance/test_host.sh` ended:

```
FRAMEWORK_FANOUT_DELIVERABLE_OK module=Network lane=medium-full symbols=3047
FRAMEWORK_FANOUT_REFERENCE_OK
NETWORK_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=Network dylib=libNetwork.dylib
```

The campaign inventory stamp `CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean` is a host-inventory token, not printed by the sealed framework gate. Swift 6.2.4 / linux compiled `libNetwork.dylib` with a clean product tree.

## Depth pass 2026-09 (wave 9)

Before: **2225 implemented / 241 declared / 581 deferred / 0 unavailable /
0 not-applicable** (2466 nondeferred).

This pass adds focused, synchronous runtime checks for a further 300 concrete
fixed-width-integer witnesses present in the pinned Network graph. The checks
exercise arithmetic and shift assignment, exact/clamping/radix/string
conversions, signed and unsigned bounds, multiplicity, literals, deterministic
one-element random ranges (including explicit generators), and Foundation's
default integer formatting across all eight fixed-width integer types. These
are real standard-library and Foundation behaviors attributed to Network by
the immutable graph, not simulated network behavior. Existing POSIX transport,
WebSocket, TXT, framer, path-monitor, and explicit TLS/QUIC/mDNS fail-closed
boundaries are unchanged.

After: **2525 implemented / 241 declared / 281 deferred / 0 unavailable /
0 not-applicable** (2766 nondeferred). Implemented gain **+300**.

Top-5 `implemented` evidence distribution (of 2525):

1. `NetworkTests.swift#testCEnumRawValuesFromMacios` — 191 (7.6%)
2. `NetworkIntegerWitnessTests.swift#testIntegerBasicArithmeticWitnesses` — 96 (3.8%)
3. `NetworkIntegerWitnessTests.swift#testFixedWidthIntegerComparableWitnesses` — 88 (3.5%)
4. `NetworkTests.swift#testNWInterfaceAndPathFromGetifaddrs` — 87 (3.4%)
5. `NetworkCStructInitTests.swift#testCStructRawValueInitializers` — 83 (3.3%)

The required cloud-environment probe and sealed host gate pass together. The
remaining behavioral questions are recorded in `oracle-questions.tsv`; Apple
TLS/QUIC, Bonjour/mDNS, service discovery, and callback timing remain
fail-closed or deferred rather than fabricated.

## Depth pass 2026-09-14 (Apple Network oracle)

Before: **2525 implemented / 241 declared / 281 deferred / 0 unavailable /
0 not-applicable** (2766 nondeferred).

This pass matches the 2026-09-14 Apple Network oracle (Xcode 26.1 / macOS 26.1)
for endpoint and address classification, then converts remaining declared
rows that a sealed synchronous test can actually call.

- IPv4 / IPv6 `isLoopback` / `isLinkLocal` / `isMulticast` follow the captured
  table (RFC 1122 `127/8`, RFC 3927 `169.254/16`, RFC 1112 `224/4`; IPv6 `::1`,
  `fe80::/10`, `ff00::/8`). IPv6 `debugDescription` is RFC 5952 compressed.
  Zoned `fe80::1%lo0` stays link-local; Linux does not invent a `lo0`
  interface. Zoned `127.0.0.1%lo0` parses as IPv4 and is not loopback, matching
  Darwin.
- Named ports `http`/`https`/`ssh` and `"8080"` plus IANA statics remain
  local. TXT `["a":"1","b":"hello"]` subscript and RFC 6763 length-prefixed
  `data` match the oracle hex.
- `NWConnection.State` has no `.invalid`. `waiting(posix ECONNREFUSED)` debug
  contains `POSIXErrorCode` and the host raw value (61 on Darwin, 111 on Linux).
- TCP `allowLocalEndpointReuse` / `acceptLocalOnly` / `includePeerToPeer`
  default false as captured.
- In-process WebSocket ping/pong/close frame encode/decode and TLV
  type/length/value encode/decode. C `nw_*` enum `Hashable`/`!=` witnesses
  and object typealiases are exercised. Async `NetworkChannel.send` /
  `receive` / `ping` stay declared (a blocking wait would hang the gate).
  QUIC/TLS remain fail-closed (`EOPNOTSUPP` / `tls(-9800)`). Foundation
  FormatStyle / SortComparator overlays stay deferred.

After: **2753 implemented / 20 declared / 274 deferred / 0 unavailable /
0 not-applicable** (2773 nondeferred). Implemented gain **+228**.

Top-5 `implemented` evidence distribution (of 2753):

1. `NetworkTests.swift#testCEnumRawValuesFromMacios` — 191 (6.9%)
2. `NetworkCAPITests.swift#testCObjectTypealiasesAndOSProtocols` — 113 (4.1%)
3. `NetworkIntegerWitnessTests.swift#testIntegerBasicArithmeticWitnesses` — 96 (3.5%)
4. `NetworkIntegerWitnessTests.swift#testFixedWidthIntegerComparableWitnesses` — 88 (3.2%)
5. `NetworkTests.swift#testNWInterfaceAndPathFromGetifaddrs` — 87 (3.2%)

No non-exempt test is cited by more than 40% of implemented rows.

## Depth pass 2026-09-15 (declared storage sweep)

Before: **2753 implemented / 20 declared / 274 deferred / 0 unavailable /
0 not-applicable** (2773 nondeferred).

This pass converts the synchronous storage / fail-closed rows the sealed
gate can actually exercise, and leaves every async row untouched:

- `ProxyConfiguration.matchDomains` / `excludedDomains` / `allowFailover`
  plus `applyCredential(username:password:)` are stored locally only; Linux
  performs no proxy failover or credential handshake.
- `NWConnectionGroup.setReceiveHandler(maximumMessageSize:rejectOversizedMessages:handler:)`
  retains the handler without a group transport daemon driving it.
- `NWConnectionGroup.Message.extractConnection()` returns nil,
  `reply(content:message:)` is a no-op, `extract(connectionTo:using:)`
  returns nil, and `reinsert(connection:)` returns false (fail-closed, no
  group transport to extract from or rejoin).
- `NWProtocolFramerImplementation.label` defaults to
  `String(describing: Self.self)`; existing conformers inherit it.
- New evidence lives in `tests/agent/NetworkStorageModelTests.swift`; each
  test actually calls the identifiers it cites and performs no `await`,
  queue hop, or semaphore wait.
- The 20 `declared` rows stay declared: 19 async `NetworkChannel`
  send/receive/ping/pong/close overloads plus async
  `NWPathMonitor.Iterator.next()` cannot be cited by a synchronous test
  without hanging the sealed gate.
- Also retargeted one `oracle-questions.tsv` row to the exact graph ID
  `NWError.posix` case (`...6Darwin14POSIXErrorCodeOc...`), which the
  deliverable validator requires.

After: **2763 implemented / 20 declared / 264 deferred / 0 unavailable /
0 not-applicable** (2783 nondeferred). Implemented gain **+10**.

Top-5 `implemented` evidence distribution (of 2763):

1. `NetworkTests.swift#testCEnumRawValuesFromMacios` — 191 (6.9%)
2. `NetworkCAPITests.swift#testCObjectTypealiasesAndOSProtocols` — 113 (4.1%)
3. `NetworkIntegerWitnessTests.swift#testIntegerBasicArithmeticWitnesses` — 96 (3.5%)
4. `NetworkIntegerWitnessTests.swift#testFixedWidthIntegerComparableWitnesses` — 88 (3.2%)
5. `NetworkTests.swift#testNWInterfaceAndPathFromGetifaddrs` — 87 (3.1%)

No non-exempt test is cited by more than 40% of implemented rows.

## Depth pass 2026-09-15 (deferred witness sweep)

Before: **2763 implemented / 20 declared / 264 deferred / 0 unavailable /
0 not-applicable** (2783 nondeferred).

Zero `View` overlay rows exist in this framework, so the overlay override
does not apply. All 20 `declared` rows are `async` (`NetworkChannel`
send/receive/ping/pong/close plus `NWPathMonitor.Iterator.next()`) and
cannot be cited by a synchronous sealed test, so they stay declared.

This pass converts the deferred rows a synchronous in-process test can
actually call, demangling each precise ID first so every citation names a
call the test really performs:

- 12 `Hashable.hashValue` witnesses now cite the existing
  `testNetworkHashValueWitnesses`, which hashes each of those values.
- 29 typed-overlay associated types (`BelowProtocol` / `ProtocolStorage` /
  `ContentType` / `LegacyMessage` across `TCP`/`UDP`/`IP`/`TLS`/`QUIC`/
  `QUICStream`/`QUICDatagram`/`WebSocket`/`Framer`/`Coder`) cite the
  existing `testTypedProtocolAssociatedTypes`, which names each one and
  was previously cited by zero rows. The 6 overlay protocols
  (`OneToOne`/`Stream`/`Message`/`Datagram`/`Multiplex`/`Connectable`)
  cite `testTypedProtocolHierarchy` the same way.
- `NWTXTRecord.SubSequence`, `Bonjour.Endpoint.ID`, `NetworkChannel.ID`,
  the listener/browser `StateUpdateHandler` aliases,
  `NetworkFixedWidthInteger` + `bigEndian`, the JSON/property-list
  coder witnesses, `NetworkEncoder.encode`, and the sync TLV
  `sendIdempotent` cite their matching existing tests.
- `NWTXTRecord.Index` comparison and range operators (`>`, `>=`, `<=`,
  postfix/prefix/infix `...`) cite the extended
  `testNWTXTRecordIndexComparable`, which now also slices with
  `...`/`..<` ranges.
- 21 already-exercised `Sequence`/`Collection` witnesses plus
  `makeIterator` cite the collection and dictionary round-trip tests;
  30 more cite the new `testNWTXTRecordSequenceWitnessBatch`
  (compactMap, elementsEqual, lexicographicallyPrecedes, contiguous
  storage, min/max, lazy, count(where:), filter, reduce, starts(with:),
  flatMap-sequence, forEach, reversed, shuffled, randomElement,
  underestimatedCount, drop(while:)/dropLast, formIndex variants,
  indices, RangeSet removal, trimmingPrefix).
- 25 `NWBrowser.Result.Change.Flags` witnesses cite the new
  `testBrowserFlagsSetAlgebraWitnesses`.
- 2 `NWEndpoint.Host` literal witnesses cite the new
  `testNWEndpointHostLiteralWitnesses`, which calls both initializers
  directly.
- 56 Foundation `BinaryInteger` format/parse witnesses cite the new
  `testIntegerFormatStyleParseWitnesses` (exact- and cross-width
  `formatted(_:)`, three `init(_:format:lenient:)` shapes, two
  `init(_:strategy:)` shapes, round-tripped for all eight widths).
- `TLS.certificateValidator` / `QUIC.TLS.certificateValidator` are
  synchronous builder stores (the async closure value is never invoked
  on Linux) and cite the new `testTLSCertificateValidatorBuilders`.
- `NWGroupDescriptor.members` / `NWMultiplexGroup.members` are new
  fail-closed product API (multiplex reports its wrapped endpoint) cited
  by `testGroupDescriptorMembers`. `NWProtocolWebSocket.Options`
  `setClientRequestHandler` and `Metadata.setPongHandler` are new
  store-only product API cited by `testWebSocketHandlerSetters`.
  `NWProtocolDefinition.!=` cites `testProtocolDefinitionInequality`.

One investigated row stays deferred: the deprecated optional-returning
`Sequence.flatMap` witness cannot be called under warnings-as-errors.
The deprecated call was removed from the batch test.

After: **2974 implemented / 20 declared / 53 deferred / 0 unavailable /
0 not-applicable** (2994 nondeferred). Implemented gain **+211**.

Top-5 `implemented` evidence distribution (of 2974):

1. `NetworkTests.swift#testCEnumRawValuesFromMacios` — 191 (6.4%)
2. `NetworkCAPITests.swift#testCObjectTypealiasesAndOSProtocols` — 113 (3.8%)
3. `NetworkIntegerWitnessTests.swift#testIntegerBasicArithmeticWitnesses` — 96 (3.2%)
4. `NetworkIntegerWitnessTests.swift#testFixedWidthIntegerComparableWitnesses` — 88 (3.0%)
5. `NetworkTests.swift#testNWInterfaceAndPathFromGetifaddrs` — 87 (2.9%)

No non-exempt test is cited by more than 40% of implemented rows
(largest share 191/2974 = 6.4%).

Verification on this Mac (Xcode 26.1): the shared deliverable and
reference phases pass (`FRAMEWORK_FANOUT_DELIVERABLE_OK`,
`FRAMEWORK_FANOUT_REFERENCE_OK`), the product compiles warning-clean,
and all 21 new or re-cited tests run green with the runtime marker.
The sealed `test_host.sh` runner itself imports `Glibc` and targets
Linux, so the full gate must run on Linux; on macOS the pre-existing
`testIPv6AddressParsing` zone assertion fails identically with and
without this change (macOS names loopback `lo0`, the test fixtures
Linux `lo`), and the host runner links the system Network framework.
Remaining deferred rows are async-only APIs, unconstructible multicast
state, declarations with no source-compatible form, stdlib/Combine/
Foundation witnesses with no in-process behavior, and one deprecated
witness.

## Depth pass 2026-09-15 (wave 8 leftover sweep)

Before: **2974 implemented / 20 declared / 53 deferred / 0 unavailable /
0 not-applicable** (2994 nondeferred).

Zero `View` overlay rows exist in this framework, so the overlay override
does not apply. All 20 `declared` rows are `async` (19 `NetworkChannel`
send/receive/ping/pong/close overloads plus async
`NWPathMonitor.Iterator.next()`); a synchronous sealed test cannot call
them without `await`, which the gate forbids, and zero `async` rows are
`implemented` anywhere in this coverage, so they stay `declared` at
their maximum honest status. The product still compiles warning-clean
(`swiftc -warnings-as-errors`, `libNetwork.dylib` produced) and every
`declared` anchor remains present in its cited product source. The 53
`deferred` rows stay deferred: async-only typed-overlay APIs
(`withNetworkConnection`, QUIC `openStream`/`inboundStreams`, `Browser`/
`Listener` `run`, channel reports, WebSocket `startSend`/`startReceive`),
the `async throws` QUIC `datagrams` getter, unconstructible
`NWMulticastGroup` state (both public inits fail closed, so the sync
`sourceFilter`/`isUnicastDisabled`/`members` getters have no instance to
exercise; succeeding would fabricate a daemon join), one deprecated
`flatMap` witness (warnings-as-errors), and stdlib/Combine/Foundation/
Concurrency witnesses that are not Network-owned declarations.

After: **2974 implemented / 20 declared / 53 deferred / 0 unavailable /
0 not-applicable** (2994 nondeferred). Implemented gain **+0**.

No non-exempt test is cited by more than 40% of implemented rows
(largest share 191/2974 = 6.4%).

## Depth pass 2026-09-15 (wave 9 multicast/datagrams oracle sweep)

Before: **2974 implemented / 20 declared / 53 deferred / 0 unavailable /
0 not-applicable** (2994 nondeferred).

Zero `View` overlay rows exist in this framework, so the overlay override
does not apply. All 20 `declared` rows are `async` (19 `NetworkChannel`
send/receive/ping/pong/close overloads plus async
`NWPathMonitor.Iterator.next()`); a synchronous sealed test cannot call
them without `await`, which the gate forbids, and zero `async` rows are
`implemented` anywhere in this coverage, so they stay `declared`.

This pass overturns two wave-8 deferral reasons with a fresh Apple oracle
probe (`xcrun swiftc`, macOS 26.1 Network framework):

- `NWMulticastGroup(for: [loopback])` throws `EINVAL` on Apple, while
  `NWMulticastGroup(for: [224.0.0.1], from: source, disableUnicast: true)`
  succeeds with `members == [endpoint]`, the source filter echoed, and
  `isUnicastDisabled == true`. Construction is a pure data model on
  Apple too; the IGMP/MLD join happens at group use, which stays
  fail-closed here (`NWConnectionGroup.start` with a multicast
  descriptor still fails). `init(for:from:disableUnicast:)` is therefore
  now a validating data-model init: literal IPv4/IPv6 multicast members
  succeed, everything else (including the empty array) throws `EINVAL`.
  The census shapes are matched exactly (`final let sourceFilter`,
  `final let isUnicastDisabled`, get-only `members`), and the non-census
  `init?(with:)` keeps its loopback-returns-nil contract while
  succeeding for multicast. Unprobed edges (empty array on Apple,
  non-address endpoints, hostname resolution) are recorded in
  `oracle-questions.tsv`.
- `NetworkConnection<QUIC>.datagrams` is a *synchronous* getter
  (digester: extension `where ApplicationProtocol == QUIC`, type
  `QUIC.Datagrams<QUICDatagram>`; the wave-8 note calling it async was
  wrong, and the declaration already existed in `NetworkTyped.swift`).
  It cites the existing `testQUICProtocolStackDataModelAndFailClosedStart`
  call, now with a parent-identity assertion; no product change needed.

New evidence: `testMulticastGroupDataModel` (renamed from
`testMulticastGroupInitFailsClosed`; the 5 rows citing the old name now
cite the new one) exercises `members` / `sourceFilter` /
`isUnicastDisabled` on both inits plus the still-fail-closed group use.

After: **2978 implemented / 20 declared / 49 deferred / 0 unavailable /
0 not-applicable** (2998 nondeferred). Implemented gain **+4**.

No non-exempt test is cited by more than 40% of implemented rows
(largest share 191/2978 = 6.4%).

## Depth pass 2026-09-15 (wave 10 leftover sweep)

Before: **2978 implemented / 20 declared / 49 deferred / 0 unavailable /
0 not-applicable** (2998 nondeferred). Leftover = 69.

Zero `View` overlay rows exist in this framework, so the overlay override
does not apply. All 20 `declared` rows are `async` (19 `NetworkChannel`
send/receive/ping/pong/close overloads plus async
`NWPathMonitor.Iterator.next()`); a synchronous sealed test cannot call
them without `await`, which the gate forbids, and zero `async` rows are
`implemented` anywhere in this coverage, so they stay `declared` at
their maximum honest status — every anchor still compiles in
`NetworkTyped.swift` / `Network.swift`. The 49 `deferred` rows stay
deferred: 4 `withNetworkConnection` overloads with no source-compatible
declaration, async-only typed-overlay APIs (QUIC `openStream`/
`inboundStreams`, `Browser`/`Listener` `run`, channel reports, WebSocket
`startSend`/`startReceive`), one deprecated `flatMap` witness
(warnings-as-errors), and stdlib/Combine/Foundation/Concurrency
witnesses that are not Network-owned declarations. Hardware/daemon
(TLS handshake, QUIC transport, mDNS/Bonjour) stays fail-closed.

After: **2978 implemented / 20 declared / 49 deferred / 0 unavailable /
0 not-applicable** (2998 nondeferred). Implemented gain **+0**.

No non-exempt test is cited by more than 40% of implemented rows
(largest share 191/2978 = 6.4%).

## Depth pass 2026-09-15 (wave 11 leftover sweep)

Before: **2978 implemented / 20 declared / 49 deferred / 0 unavailable /
0 not-applicable** (2998 nondeferred). Leftover = 69.

Re-verified every leftover row against the contract. Zero `View` overlay
rows exist in this framework, so the overlay override does not apply.
All 20 `declared` rows are `async` (19 `NetworkChannel`
send/receive/ping/pong/close overloads in `NetworkTyped.swift` plus async
`NWPathMonitor.Iterator.next()` in `Network.swift`); a synchronous sealed
test cannot call them without `await`, which the contract forbids, so they
stay `declared` at their maximum honest status. The 49 `deferred` rows
stay deferred: 4 `withNWConnection` overloads with no source-compatible
declaration, async-only typed-overlay APIs (QUIC `openStream`/
`inboundStreams`, `Browser`/`Listener` `run`, channel reports, WebSocket
`startSend`/`startReceive`), one deprecated `flatMap` witness
(warnings-as-errors), and stdlib/Combine/Foundation/Concurrency witnesses
that are not Network-owned declarations (the contract forbids converting
those). Hardware/daemon (TLS handshake, QUIC transport, mDNS/Bonjour)
stays fail-closed.

Verification this run (no product/test edits): coverage holds all 3047
public-surface IDs exactly once; every `declared` anchor is present in its
manifest-listed product source; all 163 cited `test*` functions are defined
as top-level synchronous no-argument functions; largest evidence share
191/2978 = 6.4%. Product and test trees compile clean under
`swiftc -warnings-as-errors` (macOS host). The full `test_host.sh` gate is
blocked before compilation in this sparse worktree by a missing repo-level
`full/framework-roadmap/framework-roadmap.json` (pre-existing environment
gap, unrelated to this framework); the macOS host run of the same test set
additionally trips only macOS-only artifacts (system `Network.framework`
class-name collision and no `lo` interface for the `%lo` zone test), both
inapplicable to the Linux sealed gate.

After: **2978 implemented / 20 declared / 49 deferred / 0 unavailable /
0 not-applicable** (2998 nondeferred). Implemented gain **+0**.

No non-exempt test is cited by more than 40% of implemented rows
(largest share 191/2978 = 6.4%).
