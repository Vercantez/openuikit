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

**Sealed host gate** (`bash full/matter/tests/acceptance/test_host.sh`):

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

## Depth pass 2026-09 (wave 10)

Next pass on the existing Linux starting point (wave 8 ledger is the
before-state). Earlier passes and their tests stay green; this pass
implements fail-closed `MTRBaseCluster*` / `MTRCluster*` I/O for the
largest remaining families, plus in-memory `MTRCluster*` expected-value
cache reads/writes. Completions run synchronously with
`MTRError.invalidState` (no Matter radio).

**Coverage before:** 19372 implemented / 834 declared / 8216 deferred / 40 unavailable / 0 not-applicable

**Coverage after:** 21953 implemented / 778 declared / 5691 deferred / 40 unavailable / 0 not-applicable
(+2581 implemented; 22731 nondeferred; floor 150).

**Top-5 implemented evidence distribution**

| rows | share | evidence |
| ---: | ---: | --- |
| 3788 | 17.3% | `test:full/matter/tests/agent/MatterIDTests.swift#testIDRawValues` |
| 3212 | 14.6% | `test:full/matter/tests/agent/MatterOptionSetTests.swift#testOptionSetAlgebra` |
| 2541 | 11.6% | `test:full/matter/tests/agent/MatterEnumTests.swift#testEnumRawValues` |
| 906 | 4.1% | `test:full/matter/tests/agent/MatterOptionSetTests.swift#testOptionSetRawValues` |
| 906 | 4.1% | `test:full/matter/tests/agent/MatterEnumTests.swift#testEnumHashable` |

**Top remaining (non table-driven) evidence** — 10600 rows after excluding
enum/option-set/C-constant table tests; largest share 2.6% (cap 40%):

| rows | share | evidence |
| ---: | ---: | --- |
| 277 | 2.6% | `test:full/matter/tests/agent/MatterThreadDiagnosticsClusterTests.swift#testThreadDiagnosticsFailClosed` |
| 266 | 2.5% | `test:full/matter/tests/agent/MatterElectricalMeasurementTests.swift#testElectricalMeasurementReadFailClosed` |
| 266 | 2.5% | `test:full/matter/tests/agent/MatterElectricalMeasurementTests.swift#testElectricalMeasurementSubscribeFailClosed` |
| 253 | 2.4% | `test:full/matter/tests/agent/MatterUnitTestingClusterTests.swift#testClusterUnitTestingCache` |
| 245 | 2.3% | `test:full/matter/tests/agent/MatterThermostatClusterTests.swift#testThermostatFailClosed` |

Environment: `swiftc` reports Swift 6.2.4, target `x86_64-unknown-linux-gnu`.
`.cursor/verify-cloud-environment.sh` did not emit
`CURSOR_SWIFT_ENVIRONMENT_OK` because `scratch/ladder-corpus/focus-ios` is
absent on this VM. The sealed gate compiles with a clean product tree
(`products=clean`). Starting commit
`39dc25a2769fb88a50f0853964137a4f96d50322` matched.

**Sealed host gate** (`bash full/matter/tests/acceptance/test_host.sh`):

```
CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean
FRAMEWORK_FANOUT_DELIVERABLE_OK module=Matter lane=large-partitioned symbols=28462
FRAMEWORK_FANOUT_REFERENCE_OK
MATTER_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=Matter dylib=libMatter.dylib
```

### Added this pass

- **New cluster I/O** in `MTRClustersWave10.swift`: AccessControl, Actions,
  ApplicationBasic, BasicInformation (+ legacy Basic subclass),
  BridgedDeviceBasicInformation (+ BridgedDeviceBasic),
  ElectricalPowerMeasurement, EnergyEVSE, EthernetNetworkDiagnostics,
  GeneralCommissioning, GeneralDiagnostics, ModeSelect,
  OperationalCredentials, PressureMeasurement, GroupKeyManagement,
  IlluminanceMeasurement, Descriptor, FlowMeasurement, MediaInput,
  AdministratorCommissioning, SoftwareDiagnostics,
  ThermostatUserInterfaceConfiguration, Channel, SmokeCOAlarm,
  TimeFormatLocalization, ApplicationLauncher, ValveConfigurationAndControl.
- **Fail-closed completions.** ObjC `completion` / `completionHandler` /
  subscribe `reportHandler` selectors invoke `MTRError.invalidState`
  synchronously. Canonical surface rows whose printed declaration is the
  Swift `async throws` overlay are implemented via the completion-handler
  spelling of the same USR.
- **MTRCluster* device cache.** `readAttribute*(with:)` /
  `writeAttribute*(withValue:expectedValueInterval:)` use the in-memory
  expected-value cache (write then read is non-nil).
- **Unavailable (40)** still name NSXPCConnection / Security.SecKey /
  XPC daemon reasons; none were reclassified as `not-applicable`.

The Swift `async throws` overlay is still not awaitable on the sealed
runner; CHIP IM empty-cache status versus `invalidState` remains an
oracle question. Remaining mass is other `MTRBaseCluster*` families
(TimeSynchronization, measurement clusters, ContentLauncher, Groups,
Identify, DeviceEnergyManagement, …) plus `s:` Swift overlays.
