# Linux XCTest — drain DispatchQueue.main while XCTest waits

LINUX PROGRAM. This round did not close an iOS-oracle pixel gap. It
stops the Linux XCTest bundle stalling inside `awaitUsingExpectation`
so `scripts/linux_realapp_verify.sh` can run the ink and selector
lists once, without retries.

`SIM_DEVICE_SUFFIX=-linux-xctest`. Proofs used `docker exec uikit-linux`
(Swift **6.2.4**, `aarch64-unknown-linux-gnu`). `/src` is still a
read-only mount of a different tree; the worktree was tar-copied to
`/work-linux-xctest`.

## Mechanism

corelibs XCTest 6.2.4 (`XCTestCase.performSetUpSequence` /
`performTearDownSequence`) wraps every test's async `setUp()` /
`tearDown()` in `awaitUsingExpectation`:

```
Task { try await closure(); expectation.fulfill() }
XCTWaiter.wait(timeout: asyncTestTimeout)   // 30 days
```

`XCTWaiter.primitiveWait` then runs `RunLoop.run(mode:before:)` for
`min(0.1 s, remaining)` slices. On Linux the before-date is armed as a
libdispatch timer whose `CFRunLoopWakeUp` often never lands, so
`__CFRunLoopServiceFileDescriptors` sits in `ppoll` with a **NULL**
timeout (swift-corelibs-xctest#504, rdar://139710145). An lldb snapshot
mid-stall has exactly two threads: main in `ppoll`, libdispatch manager
in `epoll_pwait`. No worker is running the test body.

The Test `Task` is enqueued on the **global** Swift executor (and any
MainActor hop goes to `DispatchQueue.main`, which bypasses
`swift_task_enqueueMainExecutor_hook` — swiftlang/swift#63104). If that
work has not been drained before the waiter enters `ppoll`, or if
`fulfill`/`CFRunLoopStop` does not wake the loop, the process sleeps
until an external `timeout`.

This is a race, not a leftover CADisplayLink / CATransaction source:
empty tests hang (weissi #504); the ink list stalled at a different
class each run, including `ColorTests.testGoldenTableLoaded` and
`GlyphInkTableTests.testOffscreenCoverageForButtonStates`.

## Evidence

### Baseline (no pump)

Ink list as `linux_realapp_verify.sh` runs it, timeout 20 s,
`/work-diag` bundle (main at the operator's 45f6395b tree):

| run | result |
|---|---|
| 1 | hang 20.0 s |
| 2 | **90 tests, 0 failures, 0.455 s** |
| 3 | hang 20.0 s |
| 4 | hang 20.0 s |
| 5 | **90 tests, 0 failures, 0.761 s** |

3/5 hung. Operator: ink 4/4, selector 3/4 under `timeout 60`.

### (a) Which executor

`OPENUIKIT_XCTEST_TRACE=1` installed `swift_task_enqueueGlobal_hook` /
`swift_task_enqueueMainExecutor_hook` (C CC). One ink run:

- **0** `enqueue MAIN` (MainActor does not call that hook)
- **110+** `enqueue GLOBAL` from tid==pid (the main thread)
- C calling convention ≠ `SWIFT_CC(swift)`: that hooked run hung at
  `GlyphInkTableTests.testIOSMaskKeyFormatAndHarvestedHit` after 30 s.
  Hooks were **removed**; they are not the pump.

The stalled job sits on `DispatchQueue.main` / the MainActor executor,
which is why the backtrace has no worker.

### (b) Is the main queue drained during `RunLoop.run`?

LD_PRELOAD of a 200 ms `DISPATCH_SOURCE_TYPE_TIMER` on the **global**
queue whose handler `dispatch_async`'s to main:

```
xctest-preload: timer#N tid=<worker> (not main queue)
xctest-preload: MAIN-QUEUE-DRAINED #N tid=<pid>
```

6/6 ink runs **90/90** in 0.6–1.0 s. So: a non-main dispatch timer
**does** fire while XCTest is in `ppoll`, and `dispatch_async` onto
main **does** run on tid==pid once that work is posted. CFRunLoop is
watching the **main-queue eventfd**, not its own limit-date timer.

A first pump that only called `CFRunLoopWakeUp` (plus a BeforeWaiting
observer draining `_dispatch_main_queue_callback_4CF`) still hung 2/2
and printed the last test `started` twice (re-entrant drain). That
path was discarded.

### (c) Correlation

Not `@MainActor` on the class (Linux tests drop it). Not the first
actor hop. Not CoreAnimation / ConformanceClock leftover sources —
`GeometryTests`+`ColorTests` flake at the same rate, and weissi
reproduces with empty `setUp`/`tearDown`. Order inside one process
does not isolate it: the hang is whichever test's `awaitUsingExpectation`
loses the race with `ppoll`.

## Fix

Linux-only C target `CLinuxXCTestSupport`, linked into the three test
targets. A constructor installs a 10 ms `DISPATCH_SOURCE_TYPE_TIMER` on
`dispatch_get_global_queue` whose handler `dispatch_async_f`s a tick
onto `_dispatch_main_q`. That is the preload, in-tree.

10 ms is 10× finer than `primitiveWait`'s 0.1 s slice; the preload
already proved 200 ms is enough. No CFRunLoopTimer (that clock does
not wake). No timeout/retry bump.

`Package.swift` is `#if os(Linux)`: Darwin does not grow a target or a
test. `LinuxXCTestPumpTests` is `#if os(Linux)` so the Mac bundle
count is unchanged.

`linux_realapp_verify.sh` / `linux_selector_verify.sh` run each list
**once**. `swift test` (the SPM harness, no TTY) still needs the
direct bundle invoke.

## Proof

uikit-linux, `/work-linux-xctest`, Swift 6.2.4, timeout 20 s, 0 stalls:

| list | runs | tests | wall time per run |
|---|---|---|---|
| ink (GlyphInk+CA+Registry+Geometry+Color+ABI+SwiftUI stub) | **20/20** | 90, 0 failures | 0.444–0.501 s |
| selector (Name+Action+Dispatch+Control+Gesture+Demo+AppShell) | **20/20** | 35, 0 failures | 0.007–0.028 s |

`LinuxXCTestPumpTests.testPumpConstructorInstalled` passed (installed=1).

Mac `swift test`: 101 tests filtered (GlyphInk+CA+Registry+Color+Geometry+ABI+SelectorName), 0 failures; `LinuxXCTestPumpTests` is `#if os(Linux)` and does not appear in the 1464-name Darwin list. Catalyst **124/124**. Real-app floors **99.137 / 98.535 / 98.548 / 99.469 / 98.639 / 98.133 / 97.516 / 99.511 / 82.170 / 99.760 / 99.689 / 85.393**. `docker run swift:6.2-noble` openrender **198.18 s**. `scripts/linux_realapp_verify.sh /tmp/linux_realapp-linux-xctest` **rc=0** (selector 35 tests 0.117 s, ink 90 tests 0.471 s, first try; Hello 505 opaque px; miss `I|system-regular|17|light|F0.0|81`; headless 12/12 + live 10/10 byte-identical vs Mac). No `Package.resolved`.

## Files

- `Sources/CLinuxXCTestSupport/pump.c`, `include/linux_xctest_pump.h`
- `Tests/OpenUIKitTests/LinuxXCTestPumpTests.swift`
- `Package.swift` (Linux-only target + test deps; test targets pulled
  out of the `Package()` expression so 6.2.4 can type-check it)
- `scripts/linux_realapp_verify.sh`, `scripts/linux_selector_verify.sh`
- `docs/PORTABILITY.md`, `docs/REAL_APP_TEST.md`
