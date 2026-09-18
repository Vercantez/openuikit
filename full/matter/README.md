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
- `MTRBaseDevice` reads and commands throw `invalidState`. Transport is
  `.undefined`. `MTRDevice` starts in `.unknown`; a host inject can move
  `state` for delegate-order tests only.
- `MTRDeviceControllerFactory.start` and create-controller APIs throw
  `invalidState` after `MTRDeviceControllerStartupParams` validation.
  `isRunning` stays false.
- `MTRBaseCluster*` completion/subscribe I/O invokes the handler
  synchronously with `invalidState`. Async Swift overlays stay deferred
  (the sealed runner cannot await).
- `MTRCertificates` byte equality is real; CSR / root / public-key
  extraction throws. `keypair(_:matchesCertificate:)` returns false.
- `MTROTAHeaderParser` throws `unknownSchema`.
- `SecKey` and `NSXPCConnection` APIs are **unavailable**.
- `MTRSetMessageReliabilityParameters` is deferred (would invent radio timing).

### Deferred / oracle

Remaining `MTRBaseCluster*` / `MTRCluster*` **async** overlays, NSCoder
round-trips, and sparse cluster-enum integers that are not sequential C
defaults remain deferred or listed in `oracle-questions.tsv`.

## Depth pass 2026-09 (wave 8)

Next pass on the existing Linux starting point. Earlier passes and their
tests stay green; this pass extends fail-closed cluster I/O and the
in-memory `MTRCluster*` expected-value cache.

**Coverage before:** 15645 implemented / 854 declared / 11923 deferred / 40 unavailable / 0 not-applicable

**Coverage after:** 19372 implemented / 834 declared / 8216 deferred / 40 unavailable / 0 not-applicable
(+3727 implemented; 20206 nondeferred; floor 150).

**Top-5 implemented evidence distribution**

| rows | share | evidence |
| ---: | ---: | --- |
| 3788 | 19.6% | `test:full/matter/tests/agent/MatterIDTests.swift#testIDRawValues` |
| 3212 | 16.6% | `test:full/matter/tests/agent/MatterOptionSetTests.swift#testOptionSetAlgebra` |
| 2541 | 13.1% | `test:full/matter/tests/agent/MatterEnumTests.swift#testEnumRawValues` |
| 906 | 4.7% | `test:full/matter/tests/agent/MatterOptionSetTests.swift#testOptionSetRawValues` |
| 906 | 4.7% | `test:full/matter/tests/agent/MatterEnumTests.swift#testEnumHashable` |

Largest new families this pass: OccupancySensing, FanControl, BarrierControl,
MediaPlayback, OnOff, WiFiNetworkDiagnostics, BinaryInputBasic,
NetworkCommissioning (full `MTRBaseCluster*` completion I/O + `MTRCluster*`
cache), plus class-func attribute-cache readers and remaining instance writes
on ElectricalMeasurement, TestCluster/UnitTesting, Thermostat, ColorControl,
DoorLock, ThreadNetworkDiagnostics, and `MTRClusterThermostat` /
`MTRClusterDoorLock` / `MTRClusterColorControl` device-cache read/write.

### Evidence repair (merge refusal at 08c2f15c)

The earlier checked merge refused `testClusterParamsInitCodingDescription` as
evidence concentration (899 of 4659 remaining implemented rows). That repair
is kept: Params/Response/Event/Struct rows still cite per-family tests.

**Top remaining (non table-driven) evidence** — 8019 rows after excluding
enum/option-set/C-constant table tests; largest share 3.5% (cap 40%):

| rows | share | evidence |
| ---: | ---: | --- |
| 277 | 3.5% | `test:full/matter/tests/agent/MatterThreadDiagnosticsClusterTests.swift#testThreadDiagnosticsFailClosed` |
| 266 | 3.3% | `test:full/matter/tests/agent/MatterElectricalMeasurementTests.swift#testElectricalMeasurementReadFailClosed` |
| 266 | 3.3% | `test:full/matter/tests/agent/MatterElectricalMeasurementTests.swift#testElectricalMeasurementSubscribeFailClosed` |
| 253 | 3.2% | `test:full/matter/tests/agent/MatterUnitTestingClusterTests.swift#testClusterUnitTestingCache` |
| 245 | 3.1% | `test:full/matter/tests/agent/MatterThermostatClusterTests.swift#testThermostatFailClosed` |

Environment: `swiftc` reports Swift 6.2.4, target `x86_64-unknown-linux-gnu`.
`.cursor/verify-cloud-environment.sh` did not emit
`CURSOR_SWIFT_ENVIRONMENT_OK` because `scratch/ladder-corpus/focus-ios` is
absent on this VM. The sealed gate compiles with a clean product tree
(`products=clean`). Starting commit
`6bf18072f4bc9ca119f4b0ad49dd8478f92dd5f0` matched.

**Sealed host gate** (`bash full/matter/tests/acceptance/test_host.sh`, exit 0,
~1897s):

```
FRAMEWORK_FANOUT_DELIVERABLE_OK module=Matter lane=large-partitioned symbols=28462
FRAMEWORK_FANOUT_REFERENCE_OK
MATTER_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=Matter dylib=libMatter.dylib
```

Host inventory token expected by the campaign (not printed by the gate):
`CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean`.

### Added this pass

- **New cluster I/O.** `MTRBaseClusterOccupancySensing`, `FanControl`,
  `BarrierControl`, `MediaPlayback`, `OnOff`, `WiFiNetworkDiagnostics`,
  `BinaryInputBasic`, and `NetworkCommissioning` now have documented inits,
  completion/subscribe/write/command methods. Completions run synchronously
  with `MTRError.invalidState` (no radio).
- **Class-func cache readers.** ObjC `readAttribute*WithAttributeCache:` /
  `WithClusterStateCache:` selectors on ElectricalMeasurement, UnitTesting,
  TestCluster, Thermostat, ColorControl, DoorLock, ThreadNetworkDiagnostics,
  and the new clusters are implemented as completion-handler fail-closed
  class methods (the canonical surface row is often the Swift async overlay
  of the same USR; tests call the completion spelling).
- **MTRCluster* device cache.** OccupancySensing, FanControl, BarrierControl,
  MediaPlayback, Thermostat, DoorLock, ColorControl, ThreadNetworkDiagnostics,
  OnOff, WiFiNetworkDiagnostics, BinaryInputBasic, and NetworkCommissioning
  `readAttribute*(with:)` / `writeAttribute*(withValue:expectedValueInterval:)`
  use the in-memory expected-value cache (write then read is non-nil).
- Remaining BaseCluster instance **writes** on ElectricalMeasurement,
  UnitTesting, TestCluster, Thermostat, ColorControl, DoorLock, LevelControl,
  BallastConfiguration, WindowCovering, Pump, and PowerSource fail closed
  through `completion` / `completionHandler`.

The Swift `async throws` overlay spelling of those ObjC selectors is still
not awaitable on the sealed runner; Apple's empty-cache error (CHIP IM vs
`invalidState`) remains an oracle question.

## Depth pass 2026-09 (wave 18 / local evidence repair)

Merged current `origin/main` (`c1973365`) into the Cursor cloud head
`platform/cursor/port-matter-to-linux-e694` (`7220aac4`) on
`agent/fw-matter-r`. Main already has the larger wave-10 cluster implementation
and its repaired cache tests. Conflict resolution preserves that superset and
all 22,588 implemented rows from main, plus the cloud AccessControl oracle
question. Deduplicated the `MTRClustersWave10.swift` source-manifest entry
introduced by the merge; the resulting manifest matches main.

The supplied `/tmp/fw_merge_gate-matter.log` contained four success markers,
including `FRAMEWORK_FANOUT_HOST_OK`, when inspected on this Mac; there were no
`error:` or `REFUSING` lines to attribute an earlier rejection to. The cloud
head has 21,953 implemented rows, below current main's 22,588, so replaying
that ledger would lose depth.

The cloud ledger also has 49 implemented claims that main correctly reduced
to declared: their broad controller/factory/certificate tests do not exercise
the cited identifiers (some methods do not exist in either source tree).
This repair restores nine of those claims with direct behavioral evidence;
the other 40 retain main's declared classification. No untested claim is
promoted merely to preserve the cloud count.

Six new synchronous, no-argument tests in `MatterParameterEvidenceTests.swift`
exercise certificate-array assignment/clearing and instance isolation, OTA
delegate assignment/clearing, operational flags and subscription limits,
storage-configuration assignment/clearing, and abstract-parameter suspension.
They use local values, make assertions after each mutation, and have no
semaphore, run-loop, main-queue, network, or device waits. The existing
startSuspended row now cites the focused suspension test as well. No product
behavior or declaration changed; these are host storage checks, not evidence
of Apple defaults, certificate validation, NSCopying, or service success.

| Measurement | Current main | Repaired merge |
| --- | ---: | ---: |
| Implemented | 22,588 | 22,597 (+9) |
| Declared | 809 | 800 |
| Deferred | 5,025 | 5,025 |
| Unavailable | 40 | 40 |
| Not applicable | 0 | 0 |
| Unique cited synchronous tests | 474 | 480 |
| Main implemented rows lost | — | 0 |

Top five implemented evidence counts (22,597 total):

| Rows | Share | Test |
| ---: | ---: | --- |
| 3,788 | 16.76% | `MatterIDTests.swift#testIDRawValues` |
| 3,212 | 14.21% | `MatterOptionSetTests.swift#testOptionSetAlgebra` |
| 2,541 | 11.25% | `MatterEnumTests.swift#testEnumRawValues` |
| 906 | 4.01% | `MatterOptionSetTests.swift#testOptionSetRawValues` |
| 906 | 4.01% | `MatterEnumTests.swift#testEnumHashable` |

The largest remaining test is
`MatterThreadDiagnosticsClusterTests.swift#testThreadDiagnosticsFailClosed`
(277 rows), well below the 40% non-table cap. All 480 cited anchors resolve
to top-level synchronous no-argument functions. The immutable inputs and
acceptance gate are unchanged; all changes relative to main are confined to
`full/matter/`.

**Local sealed gate: PASS (exit 0).** Ran the unmodified
`timeout 3600 bash full/matter/tests/acceptance/test_host.sh` in the operator's
`uikit-linux` container at `/gate-codex-matter`, using Swift 6.2.4 targeting
`aarch64-unknown-linux-gnu`. Both library and runner compiled with
`-warnings-as-errors`; the generated runner completed all 480 cited tests.
All 151 local Swift/evidence/manifest/oracle-question files match the tested
container snapshot byte-for-byte. Log: `/tmp/fw-matter-r-sealed-gate.log`.

```text
FRAMEWORK_FANOUT_DELIVERABLE_OK module=Matter lane=large-partitioned symbols=28462
FRAMEWORK_FANOUT_REFERENCE_OK
MATTER_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=Matter dylib=libMatter.dylib
```

## Depth pass 2026-09 (wave 10 / evidence repair)

Checked merge refused `4adf0f09` with **no depth gain** (implemented 19372 → 19372).
This pass repairs the ledger and adds real fail-closed cluster I/O.

`MatterDeviceRuntimeTests` was split into focused tests (startup-params inits,
factory create, controller shutdown, delegate order, device cache, optional
delegate callbacks). `MatterFailClosedTests` was split per family (commissioning,
base-device read/write/subscribe/command, certificates, factory aliases, OTA)
and each cited identifier is invoked in the named `func test*()`. Rows whose
tests did not name the identifier were reclassified to `declared` with
`source:full/matter/<file>.swift#Symbol`.

Wave-10 product work fills the next empty stub clusters (BasicInformation,
GeneralDiagnostics, EthernetNetworkDiagnostics, PressureMeasurement,
OperationalCredentials, EnergyEVSE, AccessControl, Identify, Descriptor,
and matching `MTRCluster*` cache types, plus `MTRClusterLevelControl` /
`MTRClusterWindowCovering`) with synchronous completion-handler I/O and
in-memory expected-value cache. Completions still return `invalidState`;
there is no Matter radio.

**Coverage before:** 19372 implemented / 834 declared / 8216 deferred / 40 unavailable / 0 not-applicable

**Coverage after:** 22586 implemented / 811 declared / 5025 deferred / 40 unavailable / 0 not-applicable
(+3214 implemented; 23397 nondeferred; floor 150). Unique implemented tests: 474.

Host-gate repair after the first wave-10 ledger: three `MTRError` operator
rows had been recast to `declared` with a missing `MTRClustersWave10.swift#MTRError`
anchor. They now cite `MatterErrorTests.swift#testErrorOverlay`, which already
exercises `~=`, `==`, and `!=`. Matching `MTRInteractionError` operator rows
use the same test.

**Top-5 implemented evidence distribution**

| rows | share | evidence |
| ---: | ---: | --- |
| 3788 | 16.8% | `test:full/matter/tests/agent/MatterIDTests.swift#testIDRawValues` |
| 3212 | 14.2% | `test:full/matter/tests/agent/MatterOptionSetTests.swift#testOptionSetAlgebra` |
| 2541 | 11.3% | `test:full/matter/tests/agent/MatterEnumTests.swift#testEnumRawValues` |
| 906 | 4.0% | `test:full/matter/tests/agent/MatterOptionSetTests.swift#testOptionSetRawValues` |
| 906 | 4.0% | `test:full/matter/tests/agent/MatterEnumTests.swift#testEnumHashable` |

**Top remaining (non table-driven) evidence** — 11140 rows after excluding
enum/option-set/C-constant table tests; largest share 2.5% (cap 40%):

| rows | share | evidence |
| ---: | ---: | --- |
| 277 | 2.5% | `test:full/matter/tests/agent/MatterThreadDiagnosticsClusterTests.swift#testThreadDiagnosticsFailClosed` |
| 266 | 2.4% | `test:full/matter/tests/agent/MatterElectricalMeasurementTests.swift#testElectricalMeasurementReadFailClosed` |
| 266 | 2.4% | `test:full/matter/tests/agent/MatterElectricalMeasurementTests.swift#testElectricalMeasurementSubscribeFailClosed` |
| 253 | 2.3% | `test:full/matter/tests/agent/MatterUnitTestingClusterTests.swift#testClusterUnitTestingCache` |
| 245 | 2.2% | `test:full/matter/tests/agent/MatterThermostatClusterTests.swift#testThermostatFailClosed` |

Environment: `swiftc` reports Swift 6.2.4, target `x86_64-unknown-linux-gnu`.
Isolated `swiftc -warnings-as-errors` of `libMatter.dylib` and every
`tests/agent/*Tests.swift` succeeded before the sealed host gate.
`.cursor/verify-cloud-environment.sh` did not emit
`CURSOR_SWIFT_ENVIRONMENT_OK` because `scratch/ladder-corpus/focus-ios` is
absent on this VM. The sealed gate compiles with a clean product tree
(`products=clean`).

Wave-10 cache tests that wrote one writable attribute and then read
`AcceptedCommandList` were corrected to read the attribute they wrote.

**Sealed host gate** (`bash full/matter/tests/acceptance/test_host.sh`, exit 0,
~1922s):

```
FRAMEWORK_FANOUT_DELIVERABLE_OK module=Matter lane=large-partitioned symbols=28462
FRAMEWORK_FANOUT_REFERENCE_OK
MATTER_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=Matter dylib=libMatter.dylib
```

Host inventory token expected by the campaign (not printed by the gate):
`CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean`.

## Depth pass 2026-09 (wave 11)

Converts the remaining `MTRBaseCluster*` / `MTRCluster*` data-model surface,
the stub Params/Response/Event/Struct value types, deprecated enum aliases,
and the hand-written core data containers to implemented with synchronous
in-process tests. No Matter fabric, radio, daemon, or `await` is introduced;
all I/O completions still run synchronously with `MTRError.invalidState`.

**Coverage before:** 22597 implemented / 800 declared / 5025 deferred / 40 unavailable / 0 not-applicable

**Coverage after:** 28259 implemented / 130 declared / 33 deferred / 40 unavailable / 0 not-applicable
(+5662 implemented; 28389 nondeferred; floor 150).

**Top-5 implemented evidence distribution**

| rows | share | evidence |
| ---: | ---: | --- |
| 3788 | 13.4% | `test:full/matter/tests/agent/MatterIDTests.swift#testIDRawValues` |
| 3212 | 11.4% | `test:full/matter/tests/agent/MatterOptionSetTests.swift#testOptionSetAlgebra` |
| 2541 | 9.0% | `test:full/matter/tests/agent/MatterEnumTests.swift#testEnumRawValues` |
| 906 | 3.2% | `test:full/matter/tests/agent/MatterOptionSetTests.swift#testOptionSetRawValues` |
| 906 | 3.2% | `test:full/matter/tests/agent/MatterEnumTests.swift#testEnumHashable` |

**Top remaining (non table-driven) evidence** — 16906 rows after excluding
enum/option-set/C-constant table tests; largest share 1.6% (cap 40%):

| rows | share | evidence |
| ---: | ---: | --- |
| 277 | 1.6% | `test:full/matter/tests/agent/MatterThreadDiagnosticsClusterTests.swift#testThreadDiagnosticsFailClosed` |
| 266 | 1.6% | `test:full/matter/tests/agent/MatterElectricalMeasurementTests.swift#testElectricalMeasurementReadFailClosed` |
| 266 | 1.6% | `test:full/matter/tests/agent/MatterElectricalMeasurementTests.swift#testElectricalMeasurementSubscribeFailClosed` |
| 253 | 1.5% | `test:full/matter/tests/agent/MatterUnitTestingClusterTests.swift#testClusterUnitTestingCache` |
| 245 | 1.4% | `test:full/matter/tests/agent/MatterThermostatClusterTests.swift#testThermostatFailClosed` |

Largest new families this pass (per-cluster/per-class tests, each cited by
well under 1% of implemented rows): the 64 remaining `MTRBaseCluster*`
classes (class-func cache readers, inits, instance read/subscribe/write, and
commands, including the `Ota*`/`WakeOnLan` legacy spellings with their own
command params types and the `MTRClusterTestCluster` alias), the 69 remaining
`MTRCluster*` device-cache classes (inits, expected-value reads/writes with a
write-then-read round trip, fail-closed commands, plus the 29
`MTRClusterUnitTesting` closure-spelling command twins of the async overlay),
408 generated Params/Response/Event/Struct value types with typed stored
properties and throwing `init(responseValue:)` where Apple declares it (88
more alias classes covered through inheritance), 26 deprecated enum-alias
statics, and the hand-written core containers (`MTRServerAttribute`,
`MTRServerCluster`, `MTRServerEndpoint`, `MTRDeviceStorageBehaviorConfiguration`,
`MTROperationalCSRInfo`, `MTROperationalCertificateChain`,
`MTRCommandWithRequiredResponse`, attestation/CSR/metric types, and the
`MTRClusterStateCacheContainer` fail-closed read).

New product files (in `matter_guest_sources.txt`): `MTRClustersWave11.swift`,
`MTRClusterParamsWave11.swift`, `MTREnumAliasesWave11.swift`. New tests:
`MatterBaseWave11[A-D]Tests.swift`, `MatterClusterWave11[A-C]Tests.swift`,
`MatterClusterParamsWave11[A-F]Tests.swift`,
`MatterDeprecatedEnumAliasTests.swift`, `MatterCoreWave11Tests.swift`,
`MatterMiscWave11Tests.swift`.

### Leftover deferred (33) and declared (130)

- 19 non-deprecated enum statics whose raw values need an Apple probe
  (`MTRTimeSynchronizationTimeSource` x10, `MTRThermostatSetpointAdjustMode`
  x3 cross-enum aliases, `MTRWiFiNetworkDiagnosticsWiFiVersionType` x6
  cross-enum aliases); see `oracle-questions.tsv`.
- `MTRSetMessageReliabilityParameters` (would invent radio timing),
  `MTRAttributeCacheContainer.readAttributeWithEndpointId:...` (generic cache
  read needs a cache-store design), and 10 `NSCoding.initWithCoder` rows
  (NSCoder round-trips stay deferred by design).
- Declared rows are compiling surface that still needs a live fabric/daemon:
  `MTRDeviceController` pairing/commissioning/XPC members, delegate/keypair/
  storage protocol members, the 20 callback typealiases, and empty event types
  already covered where constructible.

Environment: local `swiftc` is Apple Swift 6.2.1 targeting
`arm64-apple-macosx26.0` (this Mac). The sealed gate was run in the
`uikit-linux` container (Swift 6.2.4, `aarch64-unknown-linux-gnu`) with a
clean product tree (`products=clean`).

## Depth pass 2026-09 (wave 8, isolated worktree)

Converts the leftover compiling containers and Apple-oracle enum statics.
No product behavior changes beyond additive static aliases; no fabric,
daemon, radio, `await`, or success invention.

**Coverage before:** 28259 implemented / 130 declared / 33 deferred / 40 unavailable / 0 not-applicable

**Coverage after:** 28320 implemented / 90 declared / 12 deferred / 40 unavailable / 0 not-applicable
(+61 implemented; 28410 nondeferred; floor 150).

**Top-5 implemented evidence distribution**

| rows | share | evidence |
| ---: | ---: | --- |
| 3788 | 13.4% | `test:full/matter/tests/agent/MatterIDTests.swift#testIDRawValues` |
| 3212 | 11.3% | `test:full/matter/tests/agent/MatterOptionSetTests.swift#testOptionSetAlgebra` |
| 2541 | 9.0% | `test:full/matter/tests/agent/MatterEnumTests.swift#testEnumRawValues` |
| 906 | 3.2% | `test:full/matter/tests/agent/MatterOptionSetTests.swift#testOptionSetRawValues` |
| 906 | 3.2% | `test:full/matter/tests/agent/MatterEnumTests.swift#testEnumHashable` |

Largest new evidence citation is 12 rows
(`MatterWave8EvidenceTests.swift#testTimeSynchronizationLegacySourceAliasesWave8`),
far below the 40% cap.

**Added this pass**

- **Apple-oracle legacy enum spellings (21 deferred → implemented).**
  Values pinned from the Xcode 26.1 `Matter.framework` headers
  (`MTRBaseClusters.h`) and confirmed by a macOS runtime probe built with
  `xcrun swiftc` against the 26.1 SDK: TimeSynchronization legacy sources
  nonFabricSntp/nonFabricNtp/fabricSntp/fabricNtp/mixedNtp = 4/5/6/7/8,
  NTS variants = 9/10/11/12/13, ptp = 15, gnss = 16;
  `MTRThermostatSetpointAdjustMode` heatSetpoint/coolSetpoint/
  heatAndCoolSetpoints = 0/1/2; `MTRWiFiNetworkDiagnosticsWiFiVersionType`
  type80211a/b/g/n/ac/ax = 0/1/2/3/4/5 (Swift names from
  `Matter.apinotes`). Each duplicates a newer enumerator, so the Linux port
  models them as `static var` aliases in `MTREnumAliasesWave11.swift`
  (duplicate raw-value cases are illegal in Swift). The three related
  `oracle-questions.tsv` rows are marked resolved with the pinned values.
- **Callback typealias containers (20 declared → implemented).** All 20
  `MTR*`/`StatusCompletion`/`ResponseHandler`/`SubscriptionEstablishedHandler`
  aliases in `MTRError.swift` are assigned to host closures and invoked
  synchronously in `MatterWave8EvidenceTests.swift`; no fabric behavior is
  claimed.
- **Protocol containers (20 declared → implemented).** Each of the 20
  delegate/storage/keypair/XPC protocols in `MTRProtocols.swift` gains a host
  stub (in-memory storage for `MTRStorage`, echo signers for `MTRKeypair`,
  recording delegate for `MTRDeviceDelegate`) with conformance checked
  synchronously via an existential. Callbacks stay host-inert; no daemon
  invokes them.

### Leftover deferred (12) and declared (90)

- `MTRSetMessageReliabilityParameters` (would invent radio timing),
  `MTRAttributeCacheContainer.readAttributeWithEndpointId:...` (generic cache
  read needs a cache-store design), and 10 `NSCoding.initWithCoder` rows
  (NSCoder round-trips stay deferred by design).
- Declared rows are live fabric/daemon surface that stays fail-closed:
  `MTRDeviceController` pairing/commissioning/XPC members (11 class, 20
  instance, 4 property rows), 2 `MTRDeviceControllerParameters`
  OTA/issuer setters, and 53 delegate/keypair/storage/XPC protocol
  requirement rows. Individual requirement rows are not promoted on
  container evidence alone.

Environment: local `swiftc` is Apple Swift 6.2.1 targeting
`arm64-apple-macosx26.0` (this Mac). Product `libMatter.dylib` and the full
`tests/agent/*Tests.swift` set compile clean under `-warnings-as-errors`;
the 13 new `MatterWave8EvidenceTests` functions pass in-process on this Mac.
The sealed gate runs in the `uikit-linux` container (Swift 6.2.4,
`aarch64-unknown-linux-gnu`) with a clean product tree (`products=clean`).

## Depth pass 2026-09 (wave 9, isolated worktree)

Converts the legacy `MTRDeviceController` pairing/commissioning spellings,
the synchronous XPC params/response codecs, and the already-compiling
`MTRDeviceControllerParameters` delegate setters to implemented with
focused fail-closed tests. No fabric, daemon, radio, `await`, or success
invention: throwing paths raise `MTRError.invalidState` (`.notFound` for
the commissionee lookup), lookups return nil, browse/start calls return
false, delegate setters accept-and-ignore, and the XPC codecs are pure
dictionary transforms.

**Coverage before:** 28320 implemented / 90 declared / 12 deferred / 40 unavailable / 0 not-applicable

**Coverage after:** 28353 implemented / 57 declared / 12 deferred / 40 unavailable / 0 not-applicable
(+33 implemented; 28410 nondeferred; floor 150).

New product file (in `matter_guest_sources.txt`):
`MTRControllerPairingWave9.swift`. New tests:
`tests/agent/MatterWave9PairingTests.swift` (6 functions, max 7 rows each;
largest share of implemented rows is far below the 40% cap).

### Leftover deferred (12) and declared (57)

- Deferred is unchanged: `MTRSetMessageReliabilityParameters` (would invent
  radio timing), `MTRAttributeCacheContainer.readAttributeWithEndpointId:...`
  (generic cache read needs a cache-store design), and 10
  `NSCoding.initWithCoder` rows (NSCoder round-trips stay deferred by design).
- Declared rows are live fabric/daemon surface that stays fail-closed:
  `MTRDeviceController.sharedController` x2 (needs `MTRXPCConnectBlock`,
  which is unavailable without NSXPCConnection),
  `xpcInterfaceForServerProtocol` / `xpcInterfaceForClientProtocol`
  (return NSXPCInterface, unavailable), and 53 delegate/keypair/storage/XPC
  protocol requirement rows. The requirements are `@objc optional` on Apple
  and cannot be expressed in portable Swift; per the earlier pass policy,
  individual requirement rows are not promoted on container evidence alone.

Environment: local `swiftc` is Apple Swift 6.2.1 targeting
`arm64-apple-macosx26.0` (this Mac). Product `libMatter.dylib` and the full
`tests/agent/*Tests.swift` set compile clean under `-warnings-as-errors`;
the 6 new `MatterWave9PairingTests` functions pass in-process on this Mac.
The sealed gate runs in the `uikit-linux` container (Swift 6.2.4,
`aarch64-unknown-linux-gnu`) with a clean product tree (`products=clean`).

## Depth pass 2026-09 (wave 10, isolated worktree)

Converts the 53 delegate/storage/keypair/XPC protocol-requirement rows from
declared to implemented with per-requirement dispatch evidence. No fabric,
daemon, radio, `await`, or success invention: every requirement is invoked
on a host recording stub through an `any` existential on the calling thread,
and assertions check the recorded arguments. Daemon queue choice, delivery
count, and retention remain an oracle question.

**Coverage before:** 28353 implemented / 57 declared / 12 deferred / 40 unavailable / 0 not-applicable

**Coverage after:** 28406 implemented / 4 declared / 12 deferred / 40 unavailable / 0 not-applicable
(+53 implemented; 28410 nondeferred; floor 150).

New product file (in `matter_guest_sources.txt`):
`MTRProtocolRequirementsWave10.swift`. New tests:
`tests/agent/MatterProtocolDelegatesWave10Tests.swift` (7 functions, 27 rows)
and `tests/agent/MatterProtocolFabricWave10Tests.swift` (6 functions,
26 rows); no new test is cited by more than 6 rows, far below the 40% cap.

### Added this pass

- **Protocol requirements with exact graph spellings.** The 12 protocols in
  `MTRProtocols.swift` now declare the 53 Apple `@objc optional`
  requirements using the Xcode 26.1 symbol-graph Swift signatures verbatim
  (path components, labels, optionality, `@escaping` closures, and the
  `MTROta*` legacy overload twins). Portable Swift has no `@objc optional`,
  so `MTRProtocolRequirementsWave10.swift` provides host-inert defaults
  (accept-and-ignore; `false`/`nil` for value returns) mirroring Apple's
  optional semantics; existing empty stubs keep compiling unchanged.
- **Per-requirement dispatch tests.** Pairing (4), controller commissioning
  (6) and info (4) callbacks, browser + attestation completion (4) and
  attestation failure (2), storage delegate round-trip (5), keypair RAW/DER
  echo (2), XPC client report (1), XPC server reads (5) and writes (5), NOC
  + operational issuers with the validation flag (3), OTA query/notify (6)
  and BDX (6). The storage stub is a functional in-memory box; all other
  stubs record invocations without invoking completions (no daemon exists).

### Leftover deferred (12) and declared (4)

- Deferred is unchanged: `MTRSetMessageReliabilityParameters` (would invent
  radio timing), `MTRAttributeCacheContainer.readAttributeWithEndpointId:...`
  (generic cache read needs a cache-store design), and 10
  `NSCoding.initWithCoder` rows (NSCoder round-trips stay deferred by design).
- Declared rows are XPC surface that cannot compile without
  NSXPCConnection: `MTRDeviceController.sharedController` x2 (needs
  `MTRXPCConnectBlock`) and `xpcInterfaceForServerProtocol` /
  `xpcInterfaceForClientProtocol` (return NSXPCInterface).
- The guest-source manifest was re-sorted to byte order (the gate requires
  a path-sorted manifest; `MTRControllerPairingWave9.swift` now precedes
  `MTRControllers.swift`).
- New oracle question on `controller:commissioningComplete:` covering daemon
  queue choice, exactly-once delivery, and controller retention.

Environment: local `swiftc` is Apple Swift 6.2.1 targeting
`arm64-apple-macosx26.0` (this Mac). Product `libMatter.dylib` and the full
`tests/agent/*Tests.swift` set compile clean under `-warnings-as-errors`;
the 13 new protocol tests pass in-process on this Mac. The sealed gate runs
in the `uikit-linux` container (Swift 6.2.4,
`aarch64-unknown-linux-gnu`) with a clean product tree (`products=clean`).

## Depth pass 2026-09 (wave 11, isolated worktree)

Converts the one leftover deferred row whose Linux spelling compiles, and
documents why the remaining 15 leftovers stay. No fabric, daemon, radio,
`await`, or success invention.

**Coverage before:** 28406 implemented / 4 declared / 12 deferred / 40 unavailable / 0 not-applicable

**Coverage after:** 28407 implemented / 4 declared / 11 deferred / 40 unavailable / 0 not-applicable
(+1 implemented; 28411 nondeferred; floor 150).

**Added this pass**

- `MTRAttributeCacheContainer.readAttribute(withEndpointId:clusterId:attributeId:clientQueue:completion:)`
  (in `MTRControllers.swift`) fails closed with `MTRError.invalidState` on
  the calling thread: no fabric primes this cache on Linux. This is the
  completion-handler spelling of the deferred async overlay row, following
  the established precedent (`MTRBaseDevice` async rows cite completion
  spelling tests; `MTRClusterStateCacheContainer.readAttributes` already
  fails closed the same way). New test
  `tests/agent/MatterWave11CacheTests.swift#testAttributeCacheContainerReadWave11`
  cites the single row, far below the 40% cap. No manifest change (existing
  product file).

**Leftover deferred (11) and declared (4) — unchanged by design**

- `MTRSetMessageReliabilityParameters` (a no-op would invent radio timing).
- 10 `NSCoding.initWithCoder` rows (NSCoder round-trips stay deferred by
  design; Linux Foundation has no Apple daemon data to decode).
- Declared rows are XPC surface that cannot compile without
  NSXPCConnection/NSXPCInterface: `MTRDeviceController.sharedController`
  x2 (needs `MTRXPCConnectBlock = () -> NSXPCConnection`, itself
  unavailable) and `xpcInterfaceForServerProtocol` /
  `xpcInterfaceForClientProtocol` (return NSXPCInterface). Framework-local
  stand-ins for dependency-owned NSXPC types are forbidden, so these stay
  declared rather than inventing signatures.

Environment: local `swiftc` is Apple Swift 6.2.1 targeting
`arm64-apple-macosx26.0` (this Mac). Product `libMatter.dylib` and the full
`tests/agent/*Tests.swift` set (151 files) compile clean under
`-warnings-as-errors`; the new cache test passes in-process on this Mac.
The sealed gate runs in the `uikit-linux` container (Swift 6.2.4,
`aarch64-unknown-linux-gnu`) with a clean product tree (`products=clean`).

## Depth pass 2026-09 (wave 12, isolated worktree)

Re-examines the 15 leftover rows for in-process conversion. No fabric,
daemon, radio, `await`, or success invention is available, so the ledger is
unchanged. No product, test, manifest, or oracle change.

**Coverage before:** 28407 implemented / 4 declared / 11 deferred / 40 unavailable / 0 not-applicable

**Coverage after:** 28407 implemented / 4 declared / 11 deferred / 40 unavailable / 0 not-applicable
(+0 implemented; 28411 nondeferred; floor 150).

Ledger re-validated: 28462 data rows, every status in the allowed set,
all 28407 implemented rows cite well-formed
`test:full/matter/tests/agent/*Tests.swift#testName` evidence, all 4
declared rows cite an existing `MTRControllers.swift#MTRDeviceController`
anchor, and every deferred/unavailable row carries an explanatory note.

### Why nothing converts

- Overlay OVERRIDE has no Matter targets: the census holds 0
  not-applicable rows, and the only "View" identifiers are the Groups
  cluster `ViewGroup` params and the AccessControl `view`/`proxyView`
  privilege enumerators -- not SwiftUI `View` modifiers. There are no
  stdlib/Foundation protocol-witness rows to protect.
- The 4 declared rows are XPC surface that cannot compile on Linux:
  both `sharedController` spellings need `MTRXPCConnectBlock`
  (itself unavailable without NSXPCConnection) and both
  `xpcInterfaceFor*Protocol` selectors return NSXPCInterface.
  Framework-local stand-ins for dependency-owned NSXPC types are
  forbidden, so these stay declared.
- The 11 deferred rows stay deferred by design:
  `MTRSetMessageReliabilityParameters` (a no-op would invent radio
  timing) and the 10 `NSCoding.initWithCoder` rows (returning nil
  would fabricate failure; decoding real state would invent Apple's
  archive format; Linux Foundation has no Apple daemon data to decode).
- Hardware/daemon success paths (commissioning, reads/commands, CSR/
  certificate issuance, OTA parsing) remain fail-closed or deferred per
  the contract.

## Depth pass 2026-09 (wave 13, isolated worktree)

Audits the 15 leftover rows for async-shaped surface that completes
in-process now that the sealed runner awaits top-level
`func test*() async` (empty AsyncSequence, immediate throw). No fabric,
daemon, radio, `await`, or success invention is available, so the ledger
is unchanged. No product, test, manifest, or oracle change.

**Coverage before:** 28407 implemented / 4 declared / 11 deferred / 40 unavailable / 0 not-applicable

**Coverage after:** 28407 implemented / 4 declared / 11 deferred / 40 unavailable / 0 not-applicable
(+0 implemented; 28411 nondeferred; floor 150).

### Why nothing converts

- Async-shaped leftover is zero: `coverage.tsv` holds no
  AsyncSequence/AsyncStream/AsyncThrowing identifiers, and none of the 15
  leftover rows has an async Apple spelling. Earlier async overlays were
  already implemented citing their completion-handler spellings (same USR).
- Overlay OVERRIDE has no Matter targets: 0 not-applicable rows and no
  SwiftUI `View` modifiers (only Groups `ViewGroup` params and
  AccessControl `view`/`proxyView` privilege enumerators).
- The 4 declared rows are XPC surface that cannot compile on Linux
  (`sharedController` needs unavailable `MTRXPCConnectBlock`;
  `xpcInterfaceFor*Protocol` return NSXPCInterface). Framework-local
  stand-ins for dependency-owned NSXPC types are forbidden.
- The 11 deferred rows stay deferred by design:
  `MTRSetMessageReliabilityParameters` (a no-op would invent radio
  timing) and the 10 `NSCoding.initWithCoder` rows (Linux Foundation has
  no Apple daemon data to decode; decoding real state would invent
  Apple's archive format).
- Hardware/daemon/Siri/Apple Pay/Screen Time success stays fail-closed
  or deferred per the contract.
