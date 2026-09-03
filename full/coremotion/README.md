# CoreMotion

Linux starting point for Apple's public `CoreMotion` module, reconstructed from
the pinned Xcode 26.1 iPhoneOS symbol graph. This directory is not wired into
the shared guest package. A passing isolated host gate is not integrated Linux
success.

The legacy fan-out branch `cursor/port-coremotion-to-linux-2716` (platform PR
#16) was not readable from this GitHub App token (scoped to
`Vercantez/openuikit` only). This tree is a seed-based deliverable that follows
the in-repo repair brief for PR #16: keep the value/model surface, stop
claiming unobserved numeric ABI as Apple parity, and fail closed when every
availability property is false.

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
- Enum constructibility, inequality, hashing, and `rawValue` round-trip using
  Linux sequential fallbacks
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
- Fail-closed `NSError` uses domain `CMErrorDomain` (Linux fallback spelling)
  and code `CMErrorNotAvailable` (Linux fallback 110).
- Named `CMError*` raw values, default update intervals, heading sentinel
  (`-1`), and quaternion/Euler convention are **not** claimed as Apple ABI.

## Still open

See `oracle-questions.tsv`. Hardware streams, Apple activity classification,
water-submersion hardware, headphone IMU, and sensor recording remain
unavailable. Private TBD types stay out of scope.

`tests/agent/CoreMotionRuntime.swift` is the isolated host probe
(`COREMOTION_AGENT_RUNTIME_OK`). `tests/agent/CoreMotionDependencyIdentity.swift`
is prepared for a future clean EC2 run that builds guest Foundation first.

Run `bash tests/acceptance/test_host.sh` from this directory. Keep generated
products out of the tree.
