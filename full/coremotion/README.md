# CoreMotion (Linux starting point)

This directory is a clean-room Linux starting implementation of Apple's public
`CoreMotion` overlay from the iPhoneOS 26.1 SDK seed. It produces a real
`CoreMotion` Swift module and `libCoreMotion.dylib` without copying SDK headers,
TBD bytes, or claiming Apple sensor/privacy daemon behavior.

## What is real

- Public value types (`CMAcceleration`, `CMRotationRate`, `CMMagneticField`,
  `CMQuaternion`, `CMRotationMatrix`, `CMCalibratedMagneticField`) with
  zero-init and memberwise initializers from the symbol graph.
- `CMError` / `CMErrorDomain` plus the documented `NS_ERROR_ENUM` constants,
  `CMAuthorizationStatus`, attitude reference-frame `OptionSet`, activity /
  pedometer / headphone / water / heart-rate enumerations.
- Data classes in the `CMLogItem` tree (`CMAccelerometerData`, `CMGyroData`,
  `CMMagnetometerData`, `CMDeviceMotion`, altitude/pressure records, activity)
  and NSCoding types (`CMPedometerData`, `CMOdometerData`, water and clinical
  results). `CMAttitude.multiply(byInverseOf:)` is implemented with quaternion
  math; Euler angles and the rotation matrix are derived from the stored
  quaternion.
- Managers used by the 20-app corpus (`CMMotionManager`, `CMAltimeter`,
  `CMMotionActivityManager`, `CMPedometer`, plus headphone, batched, recorder,
  step-counter, and water-submersion types). Availability, authorization, and
  pull samples are deterministic.

Host tests may construct samples through `@_spi(OpenUIKitHost)` initializers.
Those SPI constructors are not a claim that hardware produced the sample.

## Fail-closed boundaries

Linux has no IMU, barometer, pedometer coprocessor, headphone motion accessory,
or motion-privacy prompt. The implementation therefore:

- Returns `false` from every `is*Available` / `*Supported` / `*Available` query.
- Returns `CMAuthorizationStatus.denied` from every authorization API (no
  prompt path exists).
- Never fabricates accelerometer, gyro, magnetometer, device-motion, altitude,
  activity, pedometer, or water-submersion samples.
- Delivers `CMErrorNotAvailable` on push/query handlers.
- Leaves `CMMotionActivityManager.startActivityUpdates` inert (that handler has
  no error channel).
- Stores requested `CMAttitudeReferenceFrame` and update intervals but reports
  `availableAttitudeReferenceFrames()` as the empty set.
- Ignores `showsDeviceMovementDisplay` (no UI host).
- Does not implement Apple Watch fall-detection or movement-disorder managers;
  they are absent from this seed's public Swift graph.

## Deferred / out of seed

- Live Linux IIO/HID sensor bridging (host-driven; needs an attested host SPI).
- Privacy prompt / Info.plist entitlement mapping.
- Exact Apple timestamp epoch, Euler convention, default update interval, and
  `CMError` numeric ABI — recorded in `oracle-questions.tsv`.
- Swift `AsyncSequence` overlays that appear only in the TBD, not in
  `reference/public-surface.tsv`.

Run the gate with:

```sh
bash full/coremotion/tests/acceptance/test_host.sh
```
