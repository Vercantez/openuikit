# BackgroundTasks (Linux starting point)

This directory is a clean-room Linux starting point for Apple's public
`BackgroundTasks` module, seeded from the Xcode 26.1 iPhoneOS 26.1 symbol
graph, API digester, TBD exports, and pinned `dotnet/macios` bindings. It is
not wired into the shared guest package; that integration is a later
central-review step.

Unchanged application source continues to import `BackgroundTasks`. Linux has
no Apple background-task daemon: availability and permitted identifiers are
host policy, state is process-local, and launches happen through
`@_spi(OpenUIKitHost)` rather than an OS scheduler.

## What is real

- `BGTaskRequest` and its subclasses are copy-on-submit values.
  `NSCopying.copy(with:)` returns a snapshot; mutating the caller's request
  after `submit` does not change pending work.
- `BGAppRefreshTaskRequest` / `BGProcessingTaskRequest` keep the existing
  identifier, `earliestBeginDate`, and processing flags.
- `BGContinuedProcessingTaskRequest` stores `title`, `subtitle`, `strategy`,
  and `requiredResources`. `Resources.gpu` is `1 << 0` (pinned macios
  `Gpu = (1L << 0)`). `SubmissionStrategy.fail = 0`, `.queue = 1`.
- `BGHealthResearchTaskRequest` subclasses `BGProcessingTaskRequest` and
  stores `protectionTypeOfRequiredData` as `NSString`.
- `BGTask` / `BGAppRefreshTask` / `BGProcessingTask` / `BGHealthResearchTask`
  / `BGContinuedProcessingTask` are launched through host SPI.
  `setTaskCompleted(success:)` sticks the first result. Expiration runs the
  handler once.
- `BGContinuedProcessingTask` conforms to `ProgressReporting` with a
  `Progress` object (`totalUnitCount == 1`). `updateTitle(_:subtitle:)`
  updates the stored strings immediately.
- `BGTaskScheduler.shared` is a process-local singleton.
- `BGTaskScheduler.errorDomain` is `BGTaskSchedulerErrorDomain`.
- `BGTaskScheduler.Error` is a `@unchecked Sendable`
  `Foundation._BridgedStoredNSError` wrapper. `Code` raw values are
  `unavailable = 1`, `tooManyPendingTaskRequests = 2`, `notPermitted = 3`,
  `immediateRunIneligible = 4` (pinned macios).
- `register` rejects empty identifiers, duplicate identifiers, and
  identifiers outside an optional host-permitted set.
- `submit` copies the request, throws `.unavailable` / `.notPermitted`, and
  enforces a portable pending cap of 10.
- `getPendingTaskRequests` invokes its completion handler synchronously with
  copies. The `async` overlay `pendingTaskRequests()` returns the same
  snapshot.
- Registered handlers run on the supplied `DispatchQueue` when one is given,
  otherwise on the launch caller.

## Fail-closed boundaries

- `supportedResources` is the empty set. Linux does not advertise `.gpu`.
- `immediateRunIneligible` is constructible and bridged; the portable
  scheduler never throws it. When Apple emits that code is an oracle
  question.
- There is no Info.plist, entitlement, or `dasd` integration. Permitted
  identifiers are host SPI.
- Title/subtitle updates do not talk to a system continued-processing UI.
- Health-research protection types are stored strings only; no HealthKit
  data-protection session is created.

## Existing Darwin host gate

The combined BackgroundTasks + CoreSpotlight host script remains:

```sh
bash full/backgroundtasks/tests/test_background_spotlight_host.sh
```

That script typechecks against an iPhoneOS SDK and is Darwin-only. The
wave-5 Linux deliverable gate is `tests/acceptance/test_host.sh`.
