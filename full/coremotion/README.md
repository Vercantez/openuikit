# CoreMotion

Linux starting point for Apple's public `CoreMotion` module, reconstructed from
the pinned Xcode 26.1 iPhoneOS symbol graph. This directory is not wired into
the shared guest package. A passing isolated host gate is not integrated Linux
success.

The monorepo `full/coremotion/reference/` dossier is the current seed (generator
SHA `2b8230ced5a3ed78f070607346f6a684d9e0fb74a8932b92bc0f5e38f46f0a8e`); it was
kept as-is.

## What is real

The public Swift surface compiles to `libCoreMotion.dylib`.

Implemented and exercised:

- Value types `CMAcceleration`, `CMRotationRate`, `CMMagneticField`,
  `CMCalibratedMagneticField`, `CMQuaternion`, `CMRotationMatrix` (inits and
  fields)
- `CMAttitude` quaternion multiply-by-inverse, rotation-matrix conversion, and
  internal ZYX Euler extraction (mathematical consistency only)
- `CMLogItem` and sample classes, including NSSecureCoding round-trips for
  types that advertise `init(coder:)`
- `CMAttitudeReferenceFrame` OptionSet algebra
- Enum constructibility, inequality, hashing, and `rawValue` round-trip
- `CMError` named constants with documented `CMError.h` raw values
  (`CMErrorNULL = 100` … `CMErrorSize = 113`, with `CMErrorNotAvailable = 109`)
- `CMMotionManager` / altimeter / pedometer / activity / step-counter /
  batched / headphone / sensor-recorder availability flags (all false) and
  fail-closed `start*` / `query*` handlers delivered on the supplied
  `OperationQueue` (never inline)
- `CMWaterSubmersionManager.delegate` assignment without a synchronous
  hardware-error callback
- Foundation `OperationQueue`, `Date`, `Measurement`, `NSCoder`, and `NSError`
  bridging through public APIs

## Fail-closed boundaries

Linux has no Apple motion coprocessor, privacy prompt, or headphone IMU.

- Every `is*Available` / `is*Supported` / `waterSubmersionAvailable` property
  is `false`. Authorization is `.denied`.
- Pull-model `start*` methods that have no error channel stay inactive and
  never invent `accelerometerData` / `deviceMotion` samples.
- Handler-based `start*` / `query*` methods stay inactive and deliver
  `(nil, NSError)` (or `(0, error)` for step counts) on the supplied queue.
  `CMMotionActivityHandler` has no error channel; that path is not invoked.
- Fail-closed `NSError` uses domain `CMErrorDomain` and code
  `CMErrorNotAvailable` (documented raw value 109).
- Default update intervals, heading sentinel (`-1`), and quaternion/Euler
  convention are **not** claimed as measured Darwin ABI.

## Depth pass 2026-09

Coverage before: **420 implemented / 15 declared / 0 deferred / 0 unavailable /
0 not-applicable**.

Coverage after: **435 implemented / 0 declared / 0 deferred / 0 unavailable /
0 not-applicable**.

The remaining 15 declared rows were the `CMErrorDomain` string and the 14
named `CMError*` constants. Those now use the documented `CMError.h` C
enumeration (`NULL = 100`, then sequential members, with later `NilData` /
`Size` appended after `NotAuthorized`). Focused `tests/agent/*Tests.swift`
functions provide evidence in the
`test:full/coremotion/tests/agent/<File>Tests.swift#testName` form. Enum,
option-set, and C error constants share table-driven value tests; no other
single test is cited by more than 4.8% of implemented rows.

Top-5 evidence distribution (implemented rows):

1. `CMGeometryTests.swift#testAttitudeReferenceFrameAlgebra` — 28
2. `CMErrorTests.swift#testCMErrorRawValues` — 21
3. `CMOtherManagerTests.swift#testHeadphoneMotionManagerFailClosed` — 16
4. `CMOtherManagerTests.swift#testBatchedSensorManagerFailClosed` — 16
5. `CMPedometerTests.swift#testOdometerData` — 14

## Still open

See `oracle-questions.tsv`. Hardware streams, Apple activity classification,
water-submersion hardware, headphone IMU, and sensor recording remain
unavailable. Private TBD types stay out of scope.

`tests/agent/CoreMotionRuntime.swift` is the isolated host probe
(`COREMOTION_AGENT_RUNTIME_OK`). `tests/agent/CoreMotionDependencyIdentity.swift`
is prepared for a future clean EC2 run that builds guest Foundation first.

Run `bash tests/acceptance/test_host.sh` from this directory. Keep generated
products out of the tree.
