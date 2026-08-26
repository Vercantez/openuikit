# `_Concurrency` for the Mach-O stack — investigation before building

**Finding: dispatch is not a subsystem here. It is 13 symbols.** And there is a
supported build configuration that needs none of them and still schedules for
real. Both routes are viable; they differ in what they cost and what they buy
later.

All of this is measured from Apple's shipped `libswift_Concurrency.dylib`
(iOS 26.1 simruntime, arm64) and from Swift 6.2.4 source. No box was used for
the investigation.

---

## 1. What `libswift_Concurrency` actually requires

Apple's shipped arm64 build has **458 undefined symbols**. Diffed against
everything our stack already exports (machorun's libSystem + libobjc + libc++,
our libswiftCore, our libswiftcompat), **32 are missing, none of them Swift**:

| family | n | notes |
|---|---|---|
| `dispatch_*` | **13** | `_dispatch_main_q`, `_dispatch_source_type_timer` (data) + `dispatch_activate`, `dispatch_after_f`, `dispatch_assert_queue$V2`, **`dispatch_async_swift_job`**, `dispatch_get_global_queue`, `dispatch_main`, `dispatch_release`, `dispatch_set_context`, `dispatch_source_create`, `dispatch_source_set_event_handler_f`, `dispatch_source_set_timer` |
| `os_log`/signpost | 7 | `os_log_create`, `os_release`, `os_signpost_*`, `_os_trace_lazy_init_completed_4swift` — telemetry only |
| pthread | 1 | `pthread_main_np` |
| libc / Darwin misc | 11 | `__cxa_pure_virtual`, `asl_log`, `clock_getres`, `csops`, `malloc_type_malloc`, `memset_s`, `qos_class_self`, `voucher_adopt`, `voucher_copy`, `__ZnwmSt19__type_descriptor_t`, `__swift_FORCE_LOAD_$_swift_Builtin_float` |

`dispatch_once_f` was already needed by libswiftCore and is in
`libswiftcompat.dylib`.

The scheduling core is four things: **`dispatch_async_swift_job`** (enqueue a
Swift `Job` at a QoS — a private SPI that exists specifically for Swift
concurrency), `dispatch_get_global_queue`, `_dispatch_main_q`, and the timer
source quartet for `Task.sleep`. That is a main queue, a worker pool, and a
timer. machorun already has working pthreads and `os_unfair_lock` with proven
Graviton parity.

**It also links CoreFoundation and Foundation** — that comes from
`CFExecutor.swift`, which is compiled *only* in the dispatch configuration.
Choosing a non-dispatch executor removes that dependency entirely, which
matters because we do not have Foundation yet.

## 2. The four executors, and which one is the lie

`SWIFT_CONCURRENCY_GLOBAL_EXECUTOR` takes `none`, `dispatch`, `singlethreaded`,
`hooked` (`StdlibOptions.cmake`). `stdlib/public/Concurrency/CMakeLists.txt`
maps them to sources:

| value | sources | verdict |
|---|---|---|
| `dispatch` | `DispatchGlobalExecutor.cpp`, `DispatchExecutor.swift`, **`CFExecutor.swift`**, `ExecutorImpl.swift` | Apple's default. Needs the 13 symbols + CF. |
| `singlethreaded` | `ExecutorImpl.swift`, `PlatformExecutorCooperative.swift` | **real scheduling, no dispatch** |
| `none` / `hooked` | `ExecutorImpl.swift`, `PlatformExecutorNone.swift` | **the trap — see below** |

All three non-dispatch modes compile with `-DSWIFT_CONCURRENCY_ENABLE_DISPATCH=0`.

### `none`/`hooked` is the "compiles against a lie" failure mode, and Swift names it

`PlatformExecutorNone.swift` declares:

```swift
public static let mainExecutor: any MainExecutor = UnimplementedMainExecutor()
public static let defaultExecutor: any TaskExecutor = UnimplementedTaskExecutor()
```

`hooked` compiles *the same file*. It is only viable if the embedder installs
global-executor hooks at runtime; without them you get the Unimplemented
executors. So the risk raised up front is real, it is not hypothetical, and it
has a name in the source. **We must not ship `none`, and `hooked` only with
hooks actually installed and tested.**

### `singlethreaded` genuinely schedules

`CooperativeExecutor` (`CooperativeExecutor.swift`) is a real run loop, not
inline execution:

* two priority queues — `runQueue` for ready jobs, `waitQueue` sorted by
  deadline;
* implements `RunLoopExecutor` with `run()` and `runUntil(_:)`;
* drains the timer queue into the run queue as deadlines expire, so `Task.sleep`
  and clock-based waits work;
* **blocks** until the next deadline when nothing is runnable, via `_sleep`,
  using `_ClockID.suspending`.

`PlatformExecutorFactory` sets *both* the main and the default executor to the
same `CooperativeExecutor` instance.

**Semantic cost, stated precisely:** no parallelism. Every task runs on one
thread. `async`/`await`, suspension and resumption, `Task.sleep`, task
cancellation and `@MainActor` isolation all behave correctly; what is absent is
tasks running *simultaneously*. For UIKit app code — which is `@MainActor`-
saturated and main-thread-bound by design — that is close to the natural model,
not a degradation. What would break is code that depends on real parallel
progress, e.g. a task busy-waiting for another task to advance.

## 3. Recommendation

**Build `singlethreaded` first.** It needs zero of the 13 dispatch symbols and
zero CoreFoundation, it schedules for real, and it unblocks `@MainActor`/`async`
app source — the actual goal. It is the smallest change that is not a lie.

**Then consider the dispatch shim as a second step**, because it buys something
`singlethreaded` cannot: real parallelism, and a path to running **Apple's
shipped `libswift_Concurrency` unmodified**, which is the project's long-term
goal. 13 symbols is a shim, not a subsystem — a main queue, a small pthread
worker pool, and one timer source. The honest unknown is
`dispatch_async_swift_job`'s exact contract (QoS handling, which thread the job
runs on, re-entrancy), which is private SPI and will need to be derived from
objc4/dispatch headers or behaviour.

**Do not build `none` or `hooked`-without-hooks.**

## 4. How the test must be built to fail

The verification bar is that the test must catch a runtime that compiles and
then does not schedule. A test whose async functions all complete inline proves
nothing — the same shape as the 64 KiB static pool that made every small Swift
program falsely pass the VA-ceiling check.

So the test asserts **happens-before**, not output:

1. **Suspension is observable.** Record a sequence; assert a continuation
   resumes *after* the enqueueing function has returned. An inline
   implementation produces the opposite order and fails.
2. **A real await on something that does not complete synchronously** —
   `Task.sleep` across a deadline, with the elapsed time asserted to be at least
   the requested interval.
3. **A `@MainActor` hop from a non-isolated context**, asserting the hop is a
   real enqueue (ordering), since with one thread it cannot be detected by
   thread identity.
4. **Negative control:** the same test run against a deliberately
   `none`-configured build must FAIL. A verification that cannot fail is not a
   verification.

Interleaving is not compared against macOS directly, because single-threaded
cooperative and dispatch legitimately interleave differently. The differential
is on the happens-before assertions, which must hold under both.
