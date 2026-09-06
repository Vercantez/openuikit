# PHASE (Linux starting point)

This directory is a fail-closed portable `PHASE` module for the OpenUIKit
Linux platform. It reconstructs the public Xcode 26.1 iPhoneOS Swift surface
from the sealed symbol graph. It is not wired into the shared guest package;
that integration is a separate central review step.

Coverage: **609 implemented / 2 declared / 28 deferred / 639 total**
(above the large-partitioned floor of 64).

Declared dependency: `Foundation` only. AVFAudio, ModelIO, and CoreAudio are
not declared for this seed. Those types are compiled only under
`#if canImport(...)` and the corresponding identifiers are `deferred`. Isolated
Linux hosts use `@_spi(OpenUIKitHost)` constructors so mixer/node/shape tests
can run without lookalike `AVAudioFormat` / `MDLMesh` types.

## What is real

- `PHASEError` / `PHASEAssetError` / `PHASESoundEventError` with NS_ERROR_ENUM
  integers corroborated by pinned `dotnet/macios` bindings
  (`initializeFailed = 1346913633` … `outOfMemory = 1346925670`). Typed
  construction, `userInfo`, equality, hashing, `NSError` bridging, and `~=`
  matching are exercised. Domain strings use the exported C identifier spelling.
- Sequential and FourCC enumerations (`PHASECurveType`, `PHASEReverbPreset`,
  `PHASEMaterialPreset`, `PHASEMedium.Preset`, calibration/cull/playback/
  spatialization/asset/rendering/prepare/start/seek modes) with those raw
  values, plus OptionSet bit layouts for head-tracking, push-stream buffers,
  and spatial-pipeline flags.
- `PHASEEnvelope` piecewise evaluation (`linear`, `squared`/`cubed` and
  inverses, `sine`/`inverseSine`, logistic `sigmoid` scale 12, hold/jump),
  `PHASENumericPair` storage, and domain/range extrema.
- Object graph: parent/child links, cycle/`self` rejection as
  `PHASEError.invalidObject`, local/world `simd_float4x4` compose and invert.
  Listener/source/occluder/material/shape element bookkeeping.
- Engine/group/ducker/preset/asset-registry state machines that stay in
  process: mute/solo, register/unregister, preset apply, global meta-parameters,
  sound-event node assets, duplicate → `alreadyExists`, missing event →
  `notFound`.
- Sampler/container/blend/switch/random/stream node definitions (host SPI
  where AVAudio format is required). Spatial-pipeline entries per flag.
  Directivity and distance-model parameter objects.

Isolated-host SIMD spellings (`simd_float3`, `simd_double2`, `simd_float4x4`,
`simd_quatf`) live in this module because Darwin `simd` is not a declared
dependency. They are not Darwin ABI.

## Fail-closed boundaries

Linux has no Apple PHASE renderer, spatializer, head tracker, audio decoder,
or PHASE daemon.

- `PHASEEngine.start()` throws `PHASEError.initializeFailed` and leaves
  `renderingState == .stopped`. No audible graph is created.
- `PHASESoundEvent.prepare` / `start(completion:)` invoke the handler
  synchronously with `.failure`. State stays not-started / stopped.
- Sound-asset URL/data register APIs are not compiled on the isolated host
  (`AVAudioChannelLayout` / `AVAudioFormat`). They remain `deferred`.
- Group `fadeGain` / `fadeRate` and number meta-parameter `fade` snap the
  value immediately; duration is ignored (no render clock).
- `PHASEDucker.activate()` is a local boolean. It does not duck other groups.
- Head-tracking flags are stored only. `PHASEObject.forward` is `(0, 0, -1)`
  as a local convention, not a tracked pose.
- Async `unregisterAsset(identifier:)` and `seek(to:)` compile and fail
  closed but are **declared**, not implemented: the sealed runner has no run
  loop and cannot `await`.

## Tests

Focused `tests/agent/*Tests.swift` functions are top-level, synchronous, and
cited by `coverage.tsv`. `PHASELoadSmoke.swift` is the canonical import/marker
file. `PHASEDependencyIdentity.swift` passes Foundation `URL` / `TimeInterval`
/ `NSError` values through public PHASE APIs.

Run the immutable host gate:

```sh
bash full/phase/tests/acceptance/test_host.sh
```

## Depth pass 2026-09

Fresh seed: `full/phase/` had `AGENTS.md`, `FANOUT_TASK.md`, and `reference/`
but no sources, `coverage.tsv`, or agent tests. After this pass:
**609 implemented / 2 declared / 28 deferred**.

Top-5 implemented evidence distribution:

| Citations | Evidence |
| ---: | --- |
| 22 | `PHASEOptionSetTests.swift#testSpatialPipelineFlagAlgebra` |
| 21 | `PHASEOptionSetTests.swift#testAutomaticHeadTrackingAlgebra` |
| 21 | `PHASEOptionSetTests.swift#testPushStreamBufferAlgebra` |
| 19 | `PHASEAssetErrorTests.swift#testPHASEAssetErrorCodeRawValues` |
| 19 | `PHASESoundEventErrorTests.swift#testPHASESoundEventErrorCodeRawValues` |

The three algebra tests cover OptionSet protocol members on one flags type
each. The two `*CodeRawValues` tests are table-driven error-code members.
No non-enum/non-option-set test approaches the 40% bulk-relabel bound on the
remaining implemented rows (next families are sampler-node defaults and
ducker/stream host construction).

The sealed host gate is `bash full/phase/tests/acceptance/test_host.sh`.
Expected ending markers:

```
FRAMEWORK_FANOUT_DELIVERABLE_OK module=PHASE lane=large-partitioned symbols=639
FRAMEWORK_FANOUT_REFERENCE_OK
PHASE_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=PHASE dylib=libPHASE.dylib
```

`swiftc --version` is Swift 6.2.4 targeting `x86_64-unknown-linux-gnu`.
`.cursor/verify-cloud-environment.sh` does not print
`CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean` on this
snapshot (`scratch/ladder-corpus/focus-ios` is missing). That campaign token
is the host-inventory stamp; the sealed framework gate prints the four lines
above. Swift 6.2.4 / linux compiled `libPHASE.dylib` with a clean product tree.
