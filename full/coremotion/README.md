# CoreMotion (Linux starting point)

This directory is a clean-room Linux starting implementation of Apple's public
`CoreMotion` overlay from the iPhoneOS 26.1 SDK seed. It produces a real
`CoreMotion` Swift module and `libCoreMotion.dylib` without copying SDK headers,
TBD bytes, or claiming Apple sensor, privacy, or numeric-ABI parity.

Coverage is mixed `implemented` / `declared`. Named constants and default
numeric layouts that the seed does not observe are **declared** Linux fallbacks.
`implemented` rows have focused runtime evidence in
`tests/agent/CoreMotionRuntime.swift`.

## What is real

- Public value types (`CMAcceleration`, `CMRotationRate`, `CMMagneticField`,
  `CMQuaternion`, `CMRotationMatrix`, `CMCalibratedMagneticField`) with
  memberwise initializers from the symbol graph.
- `CMError` as an `Error` / `Hashable` overlay, `CMAuthorizationStatus`,
  attitude `OptionSet` algebra on named members, and activity / pedometer /
  headphone / water enumerations as distinct cases.
- Data classes in the `CMLogItem` tree plus NSCoding types. Host tests may
  construct samples through `@_spi(OpenUIKitHost)` initializers. Those SPI
  constructors are not a claim that hardware produced the sample.
- Managers used by the 20-app corpus (`CMMotionManager`, `CMAltimeter`,
  `CMMotionActivityManager`, `CMPedometer`, plus headphone, batched, recorder,
  step-counter, and water-submersion types).

`CMAttitude.multiply(byInverseOf:)` and Euler/matrix extraction exist for
internal mathematical consistency (identity quaternion stays identity). They
are **declared**, not Apple-convention parity.

## Fail-closed boundaries

Linux has no IMU, barometer, pedometer coprocessor, headphone motion accessory,
or motion-privacy prompt:

- Every `is*Available` / `*Supported` query is `false`.
- Authorization APIs return `denied` (Linux policy; Apple first-launch is
  unobserved).
- `start*` does **not** fabricate an active sensor session. `is*Active` stays
  `false`. Where the API supplies an `OperationQueue` and an error channel, the
  handler is invoked on that queue with `nil` data and `CMErrorNotAvailable`.
- `CMMotionActivityManager.startActivityUpdates` stays inert (no error channel).
- Assigning `CMWaterSubmersionManager.delegate` only stores the delegate. It
  does not invent a hardware `errorOccurred` callback.
- `availableAttitudeReferenceFrames()` is empty. `showsDeviceMovementDisplay`
  is stored and has no UI.
- `CMError` raw codes, default update intervals, heading sentinels, and
  quaternion/Euler convention are Linux fallbacks recorded as `declared`.

## Foundation identity probe

`tests/agent/CoreMotionDependencyIdentity.swift` is prepared for a future EC2
run that builds guest Foundation first, then this framework, then a client that
imports both and passes real `OperationQueue`, `Date`, `Measurement`, `NSCoder`,
and `NSError` values through public CoreMotion APIs. The isolated
`tests/acceptance/test_host.sh` gate does not compile that file and is not an
integrated Linux sysroot claim.

Run the isolated gate with:

```sh
bash full/coremotion/tests/acceptance/test_host.sh
```
