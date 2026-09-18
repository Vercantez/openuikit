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
- **View overlay.** `View.workoutPreview(_:isPresented:)` is an identity
  no-op returning `Self` (renders `EmptyView` on Linux; no modal sheet).
- **Scheduler constants.** `WorkoutScheduler.shared` is a singleton.
  `isSupported` is `false`. `maxAllowedScheduledWorkoutCount` is `50`.
  `AuthorizationState` raw values are 0...3 in digester case order.
  `View.workoutPreview` is an identity overlay (see above).

## Fail-closed boundaries

| Surface | Linux behavior |
| --- | --- |
| `WorkoutScheduler.isSupported` | `false` (no Watch pairing daemon) |
| `requestAuthorization()` | returns `.denied`; never `.authorized` |
| `schedule` / `remove` / `markComplete` | async no-ops; `scheduledWorkouts` is `[]` |
| `HKWorkout.workoutPlan` | throws `StateError.watchNotPaired` |
| Apple `WorkoutPlan` binary | `init(from:)` throws; Linux codec only |
| `View.workoutPreview` | identity no-op returning `Self` (no SwiftUI sheet) |

`HealthKit` types (`HKWorkoutActivityType`, session/swim location,
`HKQuantity`, `HKWorkout`) are imported when the real module is on the
search path. The isolated host gate compiles without HealthKit, so
same-named stand-ins exist only under `#if !canImport(HealthKit)`. They
are not a public HealthKit substitute for the EC2 identity probe.

## Tests

`tests/agent/WorkoutKitLoadSmoke.swift` is the schema-v2 load marker
(`WORKOUTKIT_AGENT_RUNTIME_OK`). Focused checks live in
`tests/agent/*Tests.swift` as top-level `func test*()` (sync or `async`).
`tests/agent/WorkoutKitSchedulerAsyncTests.swift` awaits the eight scheduler /
store witnesses in-process (empty list, `.notDetermined` / `.denied`,
`watchNotPaired` throw); no `RunLoop` / `DispatchQueue.main` / semaphores.
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

Implemented **279** / declared **0** / deferred **0** / unavailable **0** /
not-applicable **0** (279 exact IDs).

The eight `declared` rows are async Watch / HealthKit APIs that cannot be
awaited in the host runner (no run loop): scheduler
`schedule` / `remove` / `markComplete` / `removeAllWorkouts` /
`scheduledWorkouts` / `authorizationState` / `requestAuthorization`, and
`HKWorkout.workoutPlan`. `View.workoutPreview` is `implemented` as an
identity overlay (`testViewOverlayBatch01` renders `EmptyView`).

**Top-5 implemented evidence distribution** (271 implemented rows;
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

## Wave 11 re-examination (2026-09-15)

Before **271** / declared **8** / deferred **0** / unavailable **0** /
not-applicable **0** (279 exact IDs); after **271** / **8** / **0** / **0** /
**0**. Implemented gain **0**.

All eight leftover rows are `async` (`Ya` in the precise mangling)
Watch-daemon / HealthKit-store witnesses: scheduler `schedule` / `remove` /
`markComplete` / `removeAllWorkouts` / `scheduledWorkouts` /
`authorizationState` / `requestAuthorization`, and `HKWorkout.workoutPlan`
(`async throws`). The sealed host runner calls every cited test
synchronously from a generated `main.swift`, and the coverage contract
forbids `await`, semaphore waits, `RunLoop`, and `DispatchQueue.main` in
cited tests — calling an `async` API from a synchronous `func test*()`
is a compile error, so these witnesses are structurally untestable here.
Daemon success stays fail-closed per contract (scheduler returns
`.denied` / `[]` / no-ops; `workoutPlan` throws
`StateError.watchNotPaired`), and each row keeps compiling `declared`
source evidence. The single SwiftUI overlay row (`workoutPreview`) is
already `implemented` as an identity no-op; there are no `not-applicable`
rows to convert.

## Wave 13 re-examination (2026-09-18)

Before **271** / declared **8** / deferred **0** / unavailable **0** /
not-applicable **0** (279 exact IDs); after **279** / **0** / **0** / **0** /
**0**. Implemented gain **+8**.

The sealed host runner is now `@main async` and awaits `func test*() async`,
so the eight previously `declared` async witnesses became testable without
`RunLoop` / `DispatchQueue.main` / semaphores: scheduler `schedule` /
`remove` / `markComplete` / `removeAllWorkouts` (async no-ops, list stays
`[]`), `scheduledWorkouts` (async `[]`), `authorizationState` (async
`.notDetermined`), `requestAuthorization()` (async `.denied`), and
`HKWorkout.workoutPlan` (async throws `StateError.watchNotPaired`). New
coverage cites `tests/agent/WorkoutKitSchedulerAsyncTests.swift`
(`testSchedulerScheduleAsync`, `testSchedulerRemoveAsync`,
`testSchedulerMarkCompleteAsync`, `testSchedulerRemoveAllWorkoutsAsync`,
`testSchedulerScheduledWorkoutsAsync`,
`testSchedulerAuthorizationStateAsync`,
`testSchedulerRequestAuthorizationAsync`, `testHKWorkoutPlanAsync`).
Emulated Linux-gate run (HealthKit/SwiftUI hidden): product dylib plus all
40 cited tests build warnings-as-errors and emit exactly
`WORKOUTKIT_AGENT_RUNTIME_OK`. Daemon success stays fail-closed per contract.

## Wave 12 re-examination (2026-09-15)

Before **271** / declared **8** / deferred **0** / unavailable **0** /
not-applicable **0** (279 exact IDs); after **271** / **8** / **0** / **0** /
**0**. Implemented gain **0**.

Same structural block as wave 11: all eight leftover rows are `async`
(`Ya` in the precise mangling) Watch-daemon / HealthKit-store witnesses
(scheduler `schedule` / `remove` / `markComplete` / `removeAllWorkouts` /
`scheduledWorkouts` / `authorizationState` / `requestAuthorization`, and
`HKWorkout.workoutPlan` async-throws). The sealed host runner calls every
cited test synchronously, and the coverage contract forbids `await`,
semaphore waits, `RunLoop`, and `DispatchQueue.main` in cited tests, so an
`async` API cannot be invoked from a synchronous `func test*()`. Daemon
success stays fail-closed per contract (scheduler returns `.denied` /
`[]` / no-ops; `workoutPlan` throws `StateError.watchNotPaired`), and each
row keeps a compiling `declared` source anchor (verified: `libWorkoutKit.dylib`
builds clean from all 11 manifest sources). The single SwiftUI overlay row
(`workoutPreview`) remains `implemented` as an identity no-op; there are no
`deferred` rows to re-examine and no `not-applicable` rows to convert.
