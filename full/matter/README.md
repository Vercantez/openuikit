# Matter (Linux starting point)

This directory is a clean-room Linux starting implementation of Apple's public
`Matter` module, reconstructed from the sealed Xcode 26.1 iPhoneOS symbol
graph. Isolated host compilation produces `libMatter.dylib`. It is not a claim
of Matter fabric, commissioning, BLE/IP rendezvous, or Apple daemon parity.

## Depth pass 2026-09

Fresh seed: `full/matter/` had `AGENTS.md`, `FANOUT_TASK.md`, and `reference/`
only. This pass builds the starting implementation (28462 exact IDs) and adds
real Linux behavior for every family whose semantics are documented.

Coverage: **11913 implemented / 1039 declared / 15470 deferred / 40 unavailable / 0 not-applicable / 28462 total**
(12952 nondeferred; floor 150).

Every `implemented` row cites
`test:full/matter/tests/agent/<File>Tests.swift#testName` naming a real
top-level synchronous no-argument `func testName()` that returns. Enum /
option-set members and C `MTR*` constants share table-driven value tests.
Other APIs are split across focused tests; no non-table test is cited by
more than 40% of the remaining implemented rows.

**Top-5 implemented evidence distribution**

| rows | share | evidence |
| ---: | ---: | --- |
| 3788 | 31.8% | `test:full/matter/tests/agent/MatterIDTests.swift#testIDRawValues` |
| 3212 | 27.0% | `test:full/matter/tests/agent/MatterOptionSetTests.swift#testOptionSetAlgebra` |
| 2541 | 21.3% | `test:full/matter/tests/agent/MatterEnumTests.swift#testEnumRawValues` |
| 906 | 7.6% | `test:full/matter/tests/agent/MatterOptionSetTests.swift#testOptionSetRawValues` |
| 906 | 7.6% | `test:full/matter/tests/agent/MatterEnumTests.swift#testEnumHashable` |

Environment: `swiftc` reports Swift 6.2.4, target `x86_64-unknown-linux-gnu`.
`.cursor/verify-cloud-environment.sh` did not emit
`CURSOR_SWIFT_ENVIRONMENT_OK` because `scratch/ladder-corpus/focus-ios` is
absent on this VM. The sealed gate compiles with a clean product tree
(`products=clean`). Starting commit
`342dd2ee859ac3c9369653620a0b8835883008ad` matched.

### Public surface that is real on Linux

- **Native enumerations.** Documented Darwin enums use pinned CHIP values:
  `MTRError.Code` 1…19, Matter IM status (`failure = 0x01` … `noCommandResponse = 0xCC`),
  `MTRDeviceState` (unknown=0, reachable=1, unreachable=2), `MTRTransportType`
  (undefined=0, UDP=1, BLE=2, TCP=3), `MTRLogType`, access-control privilege
  (view=1 … administer=5) and auth mode (PASE=1, CASE=2, group=3). Other
  cluster enums use C-default sequential values in graph occurrence order.
- **Identifier enums.** `MTRClusterIDType`, `MTRAttributeIDType`,
  `MTRCommandIDType`, `MTREventIDType`, and `MTRDeviceTypeIDType` use CHIP
  Darwin `MTRClusterConstants.h` integers. Per-cluster global attributes map to
  0xFFF8…0xFFFD. Duplicate numeric IDs (legal in C, illegal as distinct Swift
  cases) become static aliases.
- **Option sets.** Feature / bitmap types are `OptionSet` values. Discovery
  capabilities are softAP=1, BLE=2, onNetwork=4, allMask=7. Day-of-week masks
  use the Matter spec bits. SetAlgebra witnesses are covered.
- **String / size constants.** Data-value dictionary keys match CHIP
  `MTRBaseDevice` comments (`type`, `value`, `Array`, `Boolean`, …). Thread
  field sizes are 16/8/16/16/2/16.
- **Setup payload.** Manual 11/21-digit codes with Verhoeff10, QR `MT:` +
  base38 88-bit payload, passcode validation (invalid 0 / repeating /
  12345678 / 87654321), vendor elements, and a deterministic LCG for
  `generateRandomSetupPasscode`.
- **Paths, reports, params.** Cluster/attribute/event/command paths are
  equality/hash value types. `MTRSubscribeParams` inherits `MTRReadParams`.
  Attribute reports parse data-value dictionaries.
- **Thread operational dataset.** MeshCoP-style TLV encode/decode with
  documented field sizes.
- **Device type lookup.** Spec device-type IDs used by the 20-app corpus
  (root node, on/off light, thermostat, door lock, …).
- **In-memory work queue.** `MTRAsyncCallbackWorkQueue.enqueue` invokes the
  ready handler on the calling thread (the sealed runner has no run loop).
- **Log callback.** `MTRSetLogCallback` stores a host callback; unrecognized
  onboarding payloads emit `.error` synchronously.

### Fail-closed boundaries

These paths need a Matter fabric, BLE/IP radio, DNS-SD, Security.SecKey,
an XPC controller daemon, or Apple entitlements. They never invent success:

- `MTRDeviceController` commissioning / session setup throws `invalidState`
  (cancel throws `cancelled`; missing commissionee throws `notFound`).
- `MTRDevice` / `MTRBaseDevice` reads and commands throw `invalidState`.
  `state` stays `.unknown`; transport is `.undefined`.
- `MTRDeviceControllerFactory.start` and create-controller APIs throw
  `invalidState`. `running` is false.
- `MTRCertificates` byte equality is real; CSR / root / public-key
  extraction throws. `keypair(_:matchesCertificate:)` returns false.
- `MTROTAHeaderParser` throws `unknownSchema`.
- `SecKey` and `NSXPCConnection` APIs are **unavailable**.
- `MTRSetMessageReliabilityParameters` is deferred (would invent radio timing).

### Deferred / oracle

Generated `MTRBaseCluster*` / `MTRCluster*` I/O, NSCoder round-trips, and
sparse cluster-enum integers that are not sequential C defaults remain
deferred or listed in `oracle-questions.tsv`.
