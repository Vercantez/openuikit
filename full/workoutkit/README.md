# WorkoutKit (Linux starting point)

This directory is a clean-room Linux starting implementation of Apple's
public `WorkoutKit` module, seeded from the Xcode 26.1 iPhoneOS symbol
graph (279 exact IDs). Isolated host compilation produces `libWorkoutKit.dylib`.
It is not a claim of Apple Watch, Workout app, or HealthKit store parity.

## What is real

- **Goals and alerts.** `WorkoutGoal`, `WorkoutAlertMetric` (`count/min`),
  the `WorkoutAlert` protocol, and all nine alert structs (heart-rate /
  power / speed / cadence range, threshold, and zone). Protocol factories
  (`WorkoutAlert.heartRate`, `.power`, `.speed`, `.cadence`) construct the
  matching `Self`. `targetQuantity*` values are `HKQuantity` projections
  of the stored `Measurement`.
- **Composition.** `WorkoutStep`, `IntervalStep` (`.work` / `.recovery`),
  and `IntervalBlock` (get-only `steps`, settable `iterations`).
- **Workout shapes.** `SingleGoalWorkout`, `PacerWorkout`, `CustomWorkout`,
  and `SwimBikeRunWorkout` with documented support matrices:
  structured activities exclude `.play`, `.preparationAndRecovery`,
  `.transition`, `.cooldown`, and `.swimBikeRun`; pacer sports are
  running / walking / cycling / swimming / wheelchair walk-run; triathlon
  ordering requires exactly one swim, one bike, and one run; pool-swim
  distance+time goals require swimming with a non-outdoor session
  location; power alerts require cycling or hand-cycling.
- **Plans.** `WorkoutPlan` is `Identifiable` (`ID = UUID`).
  `dataRepresentation` / `init(from:)` round-trip a Linux JSON codec
  (`OpenUIKit.WorkoutKit.WorkoutPlan.v1`) and reject unknown formats.
  `ScheduledWorkoutPlan.complete` starts `false`.
- **Scheduler constants.** `WorkoutScheduler.shared` is a singleton.
  `isSupported` is `false`. `maxAllowedScheduledWorkoutCount` is `50`.
  `AuthorizationState` raw values are 0...3 in digester case order.

## Fail-closed boundaries

| Surface | Linux behavior |
| --- | --- |
| `WorkoutScheduler.isSupported` | `false` (no Watch pairing daemon) |
| `requestAuthorization()` | returns `.denied`; never `.authorized` |
| `schedule` / `remove` / `markComplete` | async no-ops; `scheduledWorkouts` is `[]` |
| `HKWorkout.workoutPlan` | throws `StateError.watchNotPaired` |
| Apple `WorkoutPlan` binary | `init(from:)` throws; Linux codec only |
| `View.workoutPreview` | not compiled (no SwiftUI) |

`HealthKit` types (`HKWorkoutActivityType`, session/swim location,
`HKQuantity`, `HKWorkout`) are imported when the real module is on the
search path. The isolated host gate compiles without HealthKit, so
same-named stand-ins exist only under `#if !canImport(HealthKit)`. They
are not a public HealthKit substitute for the EC2 identity probe.

## Tests

`tests/agent/WorkoutKitLoadSmoke.swift` is the schema-v2 load marker
(`WORKOUTKIT_AGENT_RUNTIME_OK`). Focused checks live in
`tests/agent/*Tests.swift` as top-level synchronous `func test*()`.
`tests/agent/WorkoutKitDependencyIdentity.swift` imports `Foundation`,
`HealthKit`, and `WorkoutKit` for a future clean EC2 probe; it is not
part of the isolated host gate.

The campaign inventory stamp
`CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean`
is printed by `.cursor/verify-cloud-environment.sh`, not by the sealed
framework gate. This snapshot's verifier failed
(`missing corpus checkout: scratch/ladder-corpus/focus-ios`; Cursor
Build `bld-20260905-9aa65d65-b87d-46a7-b154-e2f1440dbba3` vs campaign
`bld-20260901-d3266600-d87b-438f-94c1-d1aa48036e87`). Swift 6.2.4 / linux
compiled `libWorkoutKit.dylib`. The sealed gate was not weakened.

## Depth pass 2026-09

Implemented **270** / declared **8** / deferred **0** / unavailable **0** /
not-applicable **1** (279 exact IDs).

The eight `declared` rows are async Watch / HealthKit APIs that cannot be
awaited in the host runner (no run loop): scheduler
`schedule` / `remove` / `markComplete` / `removeAllWorkouts` /
`scheduledWorkouts` / `authorizationState` / `requestAuthorization`, and
`HKWorkout.workoutPlan`. `View.workoutPreview` is `not-applicable`.

**Top-5 implemented evidence distribution** (270 implemented rows;
40% cap of remaining after enum-member table tests ≈ 87):

| rows | evidence |
| ---: | --- |
| 20 | `test:full/workoutkit/tests/agent/WorkoutKitPlanTests.swift#testWorkoutPlanIdentityAndRoundTrip` |
| 17 | `test:full/workoutkit/tests/agent/WorkoutKitCompositionTests.swift#testIntervalStepAndBlock` |
| 15 | `test:full/workoutkit/tests/agent/WorkoutKitWorkoutTypeTests.swift#testCustomWorkout` |
| 11 | `test:full/workoutkit/tests/agent/WorkoutKitWorkoutTypeTests.swift#testPacerWorkout` |
| 11 | `test:full/workoutkit/tests/agent/WorkoutKitEnumTests.swift#testAuthorizationStateRawValues` |

`testAuthorizationStateRawValues` is the allowed table-driven enum /
raw-value test. No non-enum test exceeds 40% of remaining implemented rows.
