# `_Concurrency` for the Mach-O stack — investigation before building

> ## CURRENT STATE — read this before any Part below
>
> **The Parts are CHRONOLOGICAL. They are a log, not a status.** A "blocked on
> X" written in Part 5 stays on the page after Part 6 unblocks it, so anyone
> reading front-to-back inherits the oldest claim that was true at the time.
> This has now misled two readers. Anything below is history unless it also
> appears here.
>
> | patch | state |
> |---|---|
> | 1 build system selects the event backend | **landed** |
> | 2 no `sysctlbyname` on a Linux host | **landed** |
> | 3 defer to real Mach headers for types | **landed** |
> | 4 pthread semaphore backend | **landed** 2026-08-27, verified both platforms |
> | 5 runloop eventfd handle | **scoped to exact sites, not written** |
> | 6 QoS private headers | **withdrawn** — they are in tags we already pin |
>
> **Superseded claims, explicitly struck:**
>
> * *Part 5, "blocked on making Mach headers opt-in in machorun's sysroot"* —
>   **NO LONGER TRUE.** Patch 3 superseded it by including the real Mach headers
>   rather than restubbing them, with `HAVE_MACH 0` still governing whether IPC
>   compiles. machorun still stages all 67 Mach headers and that is now fine.
> * *Part 7, "we have `sys/eventfd.h` staged … pinned by
>   `sdk/tests/epoll_abi_probe.c`"* — **true, but not where it reads.** Those
>   artifacts live in **this** repo (`sdk/tests/epoll_abi_probe.c`,
>   `scripts/stage_linux_abi.sh`), which stages the declarations into the BUILD
>   sysroot at build time. They were never committed to machorun's `sdk/`, and
>   the proposed merge of the two probes never happened. Checking machorun for
>   them finds nothing, in any ref — which is exactly what one reader did.
>
> **Verified end to end:** the semaphore, and only the semaphore.
> `_dispatch_sema4_*` blocks and is signalled across threads, its timed wait
> both expires and acquires correctly, and `signal(3)` releases exactly three —
> native on macOS and as a Darwin Mach-O under machorun, with teeth shown by
> mutation. See foundation-macho `docs/DISPATCH_PATCH4.md`.
>
> **Not verified:** everything else. No timer source has fired, no async work
> has completed out of line, and libdispatch does not link. Patch 4's own TU
> (`src/shims/lock.c`) does not compile yet either — `src/internal.h` pulls
> `sys/socket.h`, which is broken in the staged sysroot by the
> `constrained_ctypes.h` / `machine/_param.h` / `sys/_types/*` gap chain that
> also blocks 3 CoreFoundation files. That gap is machorun's, not this port's.

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

---

# Part 2 — libdispatch as Darwin Mach-O (#47)

The question was escalated: CF needs GCD structurally (21 symbols), so dispatch
is required regardless of what `_Concurrency` chooses. Taking
`swift-corelibs-libdispatch` (the tree with the completed Linux port), forcing
the epoll backend, emitting Mach-O.

**Status: configure exits 0; the build is partially through and every wall so
far has been config or SDK, not a fork. One source patch. Not finished.**

## Walls hit, in order

| # | wall | category | cost |
|---|---|---|---|
| 1 | backend chosen by `#if defined(__linux__)` / `#elif __has_include(<sys/event.h>)`, with no override hook | **1 source patch** | build system selects the backend |
| 2 | glibc's `<sys/epoll.h>` cannot be included against our sysroot | SDK | 6 clean-room headers, 0 patches |
| 3 | `check_include_files("mach/mach.h" HAVE_MACH)` would turn Mach **on** | config | pre-seed `HAVE_MACH=0` so the check is skipped |
| 4 | Ninja refuses install-RPATH relink on a non-ELF platform | config | `CMAKE_BUILD_WITH_INSTALL_RPATH` |
| 5 | `HAVE_OBJC` arrives **defined-but-empty** → `#if ... && HAVE_OBJC` is a syntax error | config | give it a value |
| 6 | `<firehose/tracepoint_private.h>` — Apple's tracing, no open-source counterpart | config | `OS_VOUCHER_ACTIVITY_SPI=0`, as the Linux build does |
| 7 | ordinary Darwin headers absent from our minimal SDK: `crt_externs.h`, `netdb.h`, `netinet/in.h`, `spawn.h`, `sys/mount.h` | SDK | **open** — same supply-a-header category as `setjmp.h`/`MacTypes.h` |

Wall 3 is the trap in concrete form: our sysroot *does* carry `mach/mach.h`
(machorun staged it for objc4), so detection would have enabled Mach silently.
Wall 6 is the same shape — the firehose include is reached only because
`__has_include(<mach/mach_time.h>)` succeeds against our sysroot.

**Patch count so far: 1**, and it says "this is not a Mac" (the host kernel's
event loop is not implied by the target's object format). Nothing yet says
"this is not Mach-O".

## The Linux-ABI headers, and why they are not patches

glibc's `<sys/epoll.h>` needs glibc's `<sys/cdefs.h>` for `__THROW`; our sysroot
owns that path with Apple's version, so including glibc's headers produces 20
syntax errors inside glibc's own declarations. The two libcs cannot share the
include namespace.

So `scripts/stage_linux_abi.sh` declares the Linux ABI into our sysroot with
`GLIBCSYM` asm labels (`_glibc_<name>`), the mechanism machorun's loader already
resolves via `dlsym(RTLD_DEFAULT, name)`. libdispatch's sources are untouched —
this is an SDK addition, which is the right place for it.

**Every constant and layout was read off the host, not written from memory, and
is pinned with `_Static_assert`.** That mattered: `struct epoll_event` is packed
and 12 bytes on x86_64 but **unpacked and 16 bytes on aarch64**, data at offset
8. Writing the x86 layout would have silently corrupted every event. The
assertions make a wrong guess a build failure instead.

## Layout decision: ship `libdispatch.dylib` separately

Asked for explicitly, so: **separate dylib, not folded into libSystem.**

1. It needs Linux syscall forwarders (epoll/eventfd/timerfd/signalfd) that
   Darwin's libSystem does not have and should not pretend to have.
2. Folding it in means adding those symbols to `libSystem.tbd`. **A `.tbd` is a
   promise, and an unbacked promise fails at load, not at link** — the trap that
   already bit this project when a staged `libSystem.tbd` advertised
   `_swift_release` with nothing behind it. A separate dylib keeps the promise
   surface equal to the implementation surface by construction.
3. Darwin re-exports libdispatch *from* libSystem, and we can reproduce that
   visible contract later with a reexport once implementations exist. Doing it
   first would be advertising before implementing.

## Not yet answered

The `_4CF` entry points (`_dispatch_main_queue_callback_4CF`,
`_dispatch_get_main_queue_port_4CF`) exist so CFRunLoop and the dispatch main
queue can share a thread. Whether the epoll backend can supply a main-queue
integration CFRunLoop can drive **without Mach ports** is not yet established —
`_4CF` naming suggests the port variant is Mach-shaped. This is flagged rather
than resolved, because it feeds back into the RunLoop fork decision.

## Verification still owed

Nothing here is verified to *schedule*. The bar stands and has not been met: a
semaphore that genuinely blocks and is signalled from another thread, a timer
source that actually fires, async work completing out of line. Compiling and
linking proves nothing — which is the whole lesson of the 64 KiB pool.

---

## Part 2b — the header surface is exactly six, and `config_ac.h` replaces the flag soup

Scoped further with a local clone and a probe TU (`#include <internal.h>`),
**no box** — the box was terminated before this section and none was needed.

### `config/config_ac.h` is the right lever, and the checked-in config is a trap

`src/internal.h:30` reads:

```c
#if __has_include(<config/config_ac.h>)
#include <config/config_ac.h>
#else
#include <config/config.h>
#endif
```

`config/config.h` is **checked into the repo** and is a *Darwin* config:
`HAVE_MACH 1`, `HAVE_OBJC 1`, `HAVE_PTHREAD_WORKQUEUES 1`. It is the fallback
whenever a generated config is not found first on the include path — so the
Mach machinery we are avoiding can arrive silently, from the source tree, with
no configure step involved.

It also explains wall #5 from Part 2: CMake's `config.h.in` uses `#cmakedefine
HAVE_OBJC` (no `@VALUE@`), which emits `#define HAVE_OBJC` with **no value**, so
`#if !defined(USE_OBJC) && HAVE_OBJC` became `#if ... &&`. Passing `-DHAVE_OBJC=0`
then collides with it (`macro redefined`, and we build `-Werror`).

**Supplying our own `config/config_ac.h` fixes all of it with zero patches**,
using upstream's own escape hatch, and puts every setting in one auditable file
instead of a growing `-D` list that can collide with a generated header.
Committed at `sdk/dispatch-config/config_ac.h`.

### The six headers, and what they actually need

With `config_ac.h` in place, iterating the preprocessor to a fixed point gives
the complete list of headers `internal.h` reaches that our SDK lacks:

| header | uses in `src/` | needs |
|---|---|---|
| `sys/mount.h` | **0** | documented empty stub |
| `sys/socket.h` | **0** | documented empty stub |
| `netinet/in.h` | **0** | documented empty stub |
| `sys/queue.h` | **0** | documented empty stub |
| `search.h` | **0** | documented empty stub |
| `sys/sysctl.h` | **1** (`sysctlbyname`, `hw_config.h:206`) | see below |

Five of six are **include-only with zero uses**, so empty stubs are correct
rather than expedient — no struct layouts to get wrong, no ABI risk. That is a
much better position than writing `sockaddr_in` and `struct statfs` by hand,
which is what the naive reading of "5 missing headers" implied.

### The next layer, identified and not yet solved

With all six stubbed, `internal.h` preprocesses cleanly and two real issues
appear:

1. **`src/shims/mach.h` collides with our SDK.** With `HAVE_MACH 0`, libdispatch
   defines its own placeholder `mach_port_t`/`mach_error_t`/`mach_msg_header_t`
   — but our sysroot carries the *real* Mach headers (machorun staged them for
   objc4), so these are `typedef redefinition with different types`. This is the
   sysroot-has-Mach trap for the third time: first it turned `HAVE_MACH` on,
   then it pulled in firehose, now it collides with the no-Mach shim. The fix is
   a scoping decision — either keep Mach headers out of dispatch's include path,
   or let it use the real types.

2. **`sysctlbyname` on a Linux host.** `hw_config.h` sets `name =
   "hw.logicalcpu_max"` on Darwin and calls `sysctlbyname`; Linux has no such
   function. Upstream **already has the right code** in the `else` branch —
   `sysconf(_SC_NPROCESSORS_ONLN)`. So this is a one-line patch that says "this
   is not a Mac", not a shim: don't set `name`, take the fallback that exists.

**Patch count trending to 2–3**, and every one so far says "this is not a Mac".
Nothing says "this is not Mach-O", which remains the signal that the approach is
sound.

### Still owed, unchanged

Nothing is verified to schedule. Compiling and linking prove nothing.

---

## Part 3 — building `singlethreaded`, and what that flag actually costs

`SWIFT_CONCURRENCY_GLOBAL_EXECUTOR=singlethreaded` is rejected on its own:

```
Cannot enable the single-threaded global executor without enabling
SWIFT_STDLIB_SINGLE_THREADED_CONCURRENCY
```

That second flag sounds like it might elide synchronization — which would be
fatal for us, because machorun guests do use pthreads. **Checked rather than
assumed.** It is consumed in exactly two places, both in
`stdlib/public/Concurrency/Actor.cpp`:

```c++
static bool isExecutingOnMainThread() {
#if SWIFT_STDLIB_SINGLE_THREADED_CONCURRENCY
  return true;                     // line 296
#else
  return Thread::onMainThread();
#endif
}

JobPriority swift::swift_task_getCurrentThreadPriority() {
#if SWIFT_STDLIB_SINGLE_THREADED_CONCURRENCY
  return JobPriority::UserInitiated;   // line 344
#elif ...
```

**Neither elides synchronization.** No locks removed, no atomics weakened, no
data-structure changes. The flag only changes main-thread *identity* and
priority *reporting*.

**The honest limitation to carry forward:** `isExecutingOnMainThread()` returns
`true` unconditionally, so under this build **`@MainActor` assertions cannot
detect a wrong thread**. If a raw guest pthread called into the concurrency
runtime, the runtime would believe it is the main thread. For `@MainActor`-
saturated UIKit code — where everything is supposed to be on the main actor
anyway — that is benign and arguably what you want. It is *not* a safety net,
and nobody should later read a passing `MainActor.assertIsolated()` as evidence
of correct threading on this configuration.

Configure exits 0 with `Concurrency Support: ON`.

---

## Part 4 — RESULT: `_Concurrency` schedules under machorun, matching macOS exactly

```
                                   macOS (dispatch)      machorun (cooperative)
1 suspension is observable         PASS                  PASS
2 resume happened out of line      PASS                  PASS
3 Task.sleep waits (50ms request)  PASS  51.06ms         PASS  50.07ms
4 @MainActor hop, nonisolated      PASS                  PASS
5 200 tasks all completed          PASS                  PASS
                                   ALL PASSED, exit 0    ALL PASSED, exit 0
```

**Differential: identical** — same verdicts, same trace strings, same exit code.
`tests/expected/concurrency_probe.{macos,machorun}.txt`.

And the negative control fails **on both**: `-D INLINE_MUTANT` resumes the
continuation inline, and checks 1 and 2 fail with exit 1 under macOS *and* under
machorun. That second half matters — a test whose teeth were only demonstrated
on the oracle would not prove anything about the target. Exit codes propagate
through machorun correctly (verified: mutant returns 1, real returns 0).

### The one real wall, and it is a genuine upstream gap

`singlethreaded` on a Darwin target does not build, because
`stdlib/public/Concurrency/CMakeLists.txt` compiles **every** `PlatformExecutor*.swift`
unconditionally and lets each guard itself — but
`PlatformExecutorDarwin.swift`'s guard is `os(macOS) || os(iOS) || ...` and never
consults `SWIFT_CONCURRENCY_GLOBAL_EXECUTOR`, while
`PlatformExecutorCooperative.swift` has no guard at all. Both then define
`PlatformExecutorFactory`:

```
error: invalid redeclaration of 'PlatformExecutorFactory'
error: cannot find 'CFMainExecutor' in scope
error: cannot find 'DispatchMainExecutor' in scope
```

Upstream assumes **Darwin implies dispatch**. Patch 7 moves the Darwin executor
into the dispatch branch where its dependencies actually exist. Two hunks, one
file, and it says "a Darwin target need not imply the dispatch executor" — not
"this is not Mach-O".

### Cost

**7 patches total** to swift-6.2.4 (37 inserted lines), of which patch 7 is the
only concurrency-specific one; patch 6 is opt-in and not policy. Plus 14 symbols
added to `libswiftcompat.dylib` (44 total): `__cxa_pure_virtual`, a fifth
`__cxxabiv1` vtable (`__vmi_class_type_info` — _Concurrency has deeper class
hierarchies than libswiftCore), `pthread_main_np`, `qos_class_self`, `memset_s`,
`clock_getres`, `malloc_type_malloc`, the os_log/signpost no-ops, the voucher
no-ops, `csops`.

**Zero dispatch symbols were needed.** That is itself a check on the build: had
the wrong executor been compiled in, `dispatch_async_swift_job` and friends would
have appeared in the undefined set. They did not.

### What this does and does not mean

It means `async`/`await`, suspension and resumption, `Task.sleep`, `@MainActor`
isolation, task groups and 200 concurrent tasks all work, from a Darwin Mach-O
binary, on Linux, with no libdispatch and no Foundation.

It does **not** mean parallelism. Everything runs on one thread by construction.
And per Part 3, `@MainActor` assertions cannot detect a wrong thread here.

---

## Part 5 — libdispatch link-and-run attempt: two corrections to my own record

### Correction 1: `config_ac.h` is generated by CMake, so supplying one does not win

Part 2b said `internal.h` prefers `<config/config_ac.h>` and that supplying ours
fixes the configuration at zero patches. The mechanism was right; the conclusion
was wrong. **CMake generates a file of exactly that name into the build
directory**, and `-I<build-dir>` precedes any `-I` we add — so ours is shadowed
and CMake's valueless `#cmakedefine HAVE_OBJC` still wins. The 89-errors bug
survived a "fix" that looked correct.

It has to **replace** the generated file, not sit beside it.
`configure_dispatch.sh` now copies ours over `$B/config/config_ac.h`
post-configure. Once it actually took effect the error *kinds* changed
completely, which is how I know the earlier version was inert.

That is the same shape as everything else in `false-green-verification-pattern`:
a change that appears to work, with a plausible mechanism, that is doing nothing.

### Correction 2: "five of six headers have zero uses" was measured too narrowly

Part 2b iterated the preprocessor over a single probe TU (`#include
<internal.h>`) and concluded six missing headers, five unused. The **full**
build reaches eleven and reports `socket`, `bind`, `listen`, `connect`,
`getsockname` as undeclared — which looked like the empty `sys/socket.h` stub
being wrong.

Chasing it to file:line rather than accepting it: those calls are in
`tests/dispatch_io_muxed.c`, **not the library**. So the `src/` measurement was
right, and the stub is fine. The real defect was that `-DENABLE_TESTING=OFF` is
**silently ignored** — libdispatch honours CTest's `BUILD_TESTING`, and
`ENABLE_TESTING` appeared only in CMake's "manually-specified variables were not
used" warning, which I had already seen once and not chased. Second time that
warning mattered; the first was `DISPATCH_EVENT_BACKEND_EPOLL` passed as a CMake
variable when it is a preprocessor define.

**Lesson worth keeping: treat CMake's unused-variable warning as an error.** A
`-D` that does nothing is indistinguishable from a `-D` that worked, and both
produce a clean configure.

### Where it now stands, and what blocks it

With tests excluded and the config actually applied, the remaining errors are
dominated by:

```
error: 'MACH_PORT_NULL' macro redefined
error: 'MACH_PORT_DEAD' macro redefined
```

libdispatch's own no-Mach shim (`src/shims/mach.h`) versus the **real** Mach
headers our sysroot stages for objc4. This is the sysroot-Mach back door for the
**fourth** time — after `check_include_files(mach/mach.h HAVE_MACH)`, after the
firehose `__has_include(<mach/mach_time.h>)`, after the `typedef redefinition`
of `mach_port_t`.

**So this port is now blocked on the decision already made and routed:** making
Mach headers opt-in in machorun's sysroot rather than default. Once the header
is absent when the capability is absent, libdispatch's no-Mach shim works as
designed and these collisions disappear without a patch. Forcing Mach off
explicitly does not help here — the collision is between two *definitions*, not
a detection result.

Patch count remains **2**, both saying "this is not a Mac".

### Still owed, unchanged

Nothing is verified to schedule. No semaphore, no timer, no out-of-line
completion. And the `_4CF` main-queue question is still open and still
unguessed.

---

## Appendix — authoritative sizes for the two dispatch DATA symbols

Asked to settle whether a 256-byte hand-written stub for `_dispatch_main_q` and
`_dispatch_source_type_timer` could overflow and produce heap-metadata
corruption. **It cannot: both are well under 256 bytes.**

| symbol | type | size | section | writable? |
|---|---|---|---|---|
| `_dispatch_main_q` | `struct dispatch_queue_s` | **128** | `__DATA_DIRTY,__data` | yes — dispatch mutates queue state |
| `_dispatch_source_type_timer` | `struct dispatch_source_type_s` | **64** | `__DATA_CONST,__const` | **no** — read-only descriptor |

Two independent methods, agreeing:

* **Apple's shipped arm64 `libdispatch.dylib`** (iOS 26.1 simruntime): symbol-gap
  to the next symbol in the same section — `_dispatch_main_q` @ `0x64dc0` →
  `_dispatch_mgr_q` @ `0x64e40` (two queues of the same type laid out
  consecutively), and `_dispatch_source_type_timer` @ `0x589c0` →
  `_dispatch_source_type_timer_with_clock` @ `0x58a00`.
* **Upstream's own assertion**: `src/queue_internal.h:697`
  `dispatch_static_assert(sizeof(struct dispatch_queue_s) <= 128);`

Symbol-gap alone is only an *upper* bound — padding or a non-adjacent next
symbol inflates it — so it would not have been enough on its own. The static
assert lands on the same number from a different direction, which is what makes
128 assertable.

**The measurement had to come from Apple's binary, not ours.** The consumer is
Apple's shipped `libswift_Concurrency`, so Apple's Darwin layout is what binds.
Our epoll/no-Mach configuration can produce a different `dispatch_queue_s`, and
quoting our build's number would have been confidently wrong. When the question
is what a shipped binary expects, measure the shipped binary.

---

## Part 6 — Mach collision solved; and a live instance of the "closed" ABI hazard

### Patch 3 works: zero Mach collisions

`src/shims/mach.h` says it exists to "stub out defines for some mach types" —
i.e. for platforms where Mach is *absent*. So the stubs collided with the
genuine articles.

**Correction to my first account of this, measured by machorun-isamask.** I
originally framed it as our sysroot being unusual — staging Mach headers that a
normal Darwin build would not have. That is wrong, and the correction makes the
patch *more* clearly right rather than less. Apple's real MacOSX15.4 SDK has
`dispatch/source.h` include `<mach/port.h>` and `<mach/message.h>` exactly as
ours does, and a program including only `<dispatch/dispatch.h>` comes out with
`MACH_PORT_NULL` already defined. **On any Darwin target, including Apple's own,
dispatch's umbrella header defines these macros.**

So the collision is not "our headers are present". It is that
`src/shims/mach.h` — the LINUX path, for a platform with no Mach headers at all
— is being compiled for a Darwin target. It would collide identically against
Apple's SDK. That is a genuine upstream portability gap, not a machorun artifact.

(Of 85 staged `mach/` headers, 56 are reachable from ordinary non-Mach headers
and only 29 are pure Mach API; `mach/port.h`, which defines both colliding
macros, is in the required 56 — reached from `sys/mount.h`, `<malloc/malloc.h>`,
`bsm/audit.h`, `os/workgroup_base.h` and `dispatch/dispatch.h` itself.)

Patch 3 makes the shim defer to the real headers when `__has_include(<mach/mach.h>)`
succeeds, keeping only `dispatch_mach_msg_t` and `firehose_activity_id_t`, which
are libdispatch's own types rather than Mach's. `HAVE_MACH=0` continues to govern
whether any Mach IPC code path compiles.

That keeps the two questions apart, which is this port's own lesson inverted:
**whether the TYPES exist is a header question; whether Mach IPC is USABLE is a
capability question.** Header presence is not capability — and here it cuts the
other way, because the types are real even though the IPC is not implemented.

Verified locally against our sysroot: `MACH_PORT` collisions **0**. No box.

**Why `__has_include` rather than `#ifndef MACH_PORT_NULL`.** The narrower guard
fixes the two *macros* but cannot fix the four *typedef* redefinitions
(`mach_port_t`, `mach_error_t`, `mach_msg_return_t`, `mach_msg_header_t`) —
there is no `#ifndef` for a typedef. Deferring to the real headers fixes both
classes at once, and states the actual condition: the types are available.

### The semaphore backend is a live ABI hazard — do NOT take `USE_POSIX_SEM`

With Mach out of the way, `src/shims/lock.h` reaches its own `#error`:

```
#error "port has to implement _dispatch_sema4_t"
```

The chain is `USE_MACH_SEM` / `USE_POSIX_SEM` / `USE_WIN32_SEM`, and none is set.
`USE_POSIX_SEM` looks like a one-line config fix. **It is a trap, and taking it
would create the first live instance of the hazard class the opaque-pointer audit
just closed.**

```
typedef sem_t _dispatch_sema4_t;     // src/shims/lock.h, USE_POSIX_SEM branch
```

`_dispatch_sema4_t` is embedded **by value** in libdispatch's own structures. And:

| | size | source |
|---|---|---|
| Darwin `sem_t` | **4** | audit table (one of the eight OVERFLOWING types) |
| glibc `sem_t` | **32** | measured in `machorun-testbed:24.04`, align 8 |

A forwarded `sem_init` writes 32 bytes into 4. Every symbol resolves, the link is
clean, the call returns 0, and 28 bytes past the object are gone — in exactly the
path CoreFoundation needs, since `dispatch_semaphore_*` is among CF's 21 symbols.

The audit's "zero live bugs" verdict is correct **and conditional**: it holds
because the eight overflowing types are not forwarded by libSystem *today*. This
is the first concrete case where someone would have added a forward. The verdict
was never "these types are safe" — it was "nobody is using them yet".

Two further facts sharpen it:

* Our sysroot **has no `semaphore.h` at all**, so `USE_POSIX_SEM` fails at the
  include before the ABI question is even reached. The loud failure precedes the
  silent one, which is luck rather than design.
* Darwin's `sem_t` is 4 bytes, so the pointer-handle trick that fixes
  `posix_spawnattr_t` (Darwin's 8 bytes are already a pointer) **cannot work
  here** — 4 bytes cannot hold a pointer.

**Recommended backend: pthread mutex + condition variable**, which the audit
already measured as size-compatible in the safe direction (Darwin
`pthread_mutex_t` 64 vs glibc 48; `pthread_cond_t` 48 vs 48 — both fit). That is
a fourth branch in the `#if` chain: a patch, not a config, and it says "this is
not a Mac" honestly.

**Not implemented here.** Flagging before building is the point — this is exactly
the class of thing that compiles, links, returns success and corrupts memory.

### Both conditions on the pthread backend, checked

**Darwin genuinely does not support unnamed POSIX semaphores — confirmed, not
assumed.** On macOS 26 arm64:

```
sem_init -> -1, errno=78 (Function not implemented)
```

So `USE_POSIX_SEM` was never a configuration Darwin builds take, which is why
libdispatch reaches for Mach semaphores there. Choosing it for a Darwin target
would emulate a configuration Apple's own platform does not have. **That makes a
fourth branch the faithful choice rather than a workaround** — we are a Darwin
target without Mach IPC, a combination upstream does not model.

**No static initialisers — the 48-vs-48 coincidence is not a trap here.**
`grep -rE 'PTHREAD_[A-Z]+_INITIALIZER' src/` returns **zero**, and there are no
statically initialised semaphore globals. libdispatch creates every lock and
semaphore at runtime through `_dispatch_sema4_init`, so a forwarder that
allocates properly is safe.

That mattered because `pthread_cond_t` is 48 bytes on *both* platforms. The
equal size makes a forwarder look correct and pass every runtime check, while
being wrong for a statically initialised one: `PTHREAD_COND_INITIALIZER` is a
compile-time constant carrying Darwin's field layout, and **no size check can
catch that** — it is a content problem wearing a size problem's clothes.

Because it is a property of libdispatch as it stands rather than a guarantee,
`dispatch_patches.py` now **asserts** it on every run instead of noting it in a
comment.

---

## Part 7 — the `_4CF` question, answered: **CFRunLoop does not need Mach ports**

Asked whether CFRunLoop's dispatch main-queue integration requires port receive
rights, since `_dispatch_get_main_queue_port_4CF` is Mach-shaped by its name.
**It does not.** The naming is legacy; upstream already implements the non-Mach
path, and it is an **eventfd**.

### 1. "port" is an alias, not a mechanism

`src/queue.c:6949`:

```c
dispatch_runloop_handle_t
_dispatch_get_main_queue_port_4CF(void)
{
	return _dispatch_get_main_queue_handle_4CF();
}
```

The port entry point is a one-line forward to the *handle* entry point. `handle`
is the real name; `port` is the Darwin-era alias kept for source compatibility.
So the port variant is **not separately load-bearing** — there is only one path,
and it is parameterised by what a "handle" is.

### 2. A handle is a file descriptor off Darwin

`private/private.h:190-198`:

```c
#if TARGET_OS_MAC
typedef mach_port_t dispatch_runloop_handle_t;
#elif defined(__linux__) || defined(__FreeBSD__)
typedef int dispatch_runloop_handle_t;          /* a file descriptor */
#elif defined(_WIN32)
typedef void *dispatch_runloop_handle_t;
#else
#error "runloop support not implemented on this platform"
#endif
```

### 3. And that descriptor is an eventfd

`_dispatch_runloop_queue_handle_init`, `src/queue.c:6525-6544`:

```c
#if TARGET_OS_MAC
	kr = mach_port_construct(mach_task_self(), &opts, guard, &mp);
	handle = mp;
#else
	int fd = eventfd(0, EFD_CLOEXEC | EFD_NONBLOCK);
```

So the run loop waits on an eventfd, which is exactly the "non-Mach mechanism
presenting the same semantics" the question hoped for — and precisely what the
epoll backend already uses for its own poke path. We have `sys/eventfd.h` staged
with `EFD_CLOEXEC`/`EFD_NONBLOCK` pinned against real glibc by
`sdk/tests/epoll_abi_probe.c`.

### Verdict

**The deferral of Mach port emulation is confirmed safe, and the RunLoop fork
does not need reopening.** foundation-scope can build the epoll RunLoop; nothing
about CFRunLoop's dispatch integration requires port receive rights, and the
`_4CF` naming does not imply Mach semantics.

### The one thing it costs us: patch 5

Predictably, `TARGET_OS_MAC` is 1 for our target, so the typedef and the handle
init both select the Mach branch — `mach_port_construct` is one of the four
entry points machorun exports as a self-naming abort. Same shape as every other
wall in this port: **upstream's non-Mach path is right for us, and our Darwin
target selects the Mach one.**

That is patch 5, and it is the same "this is not a Mac" statement as patches 1–4:
we are a Darwin target without Mach IPC, a combination upstream does not model.
Had `mach_port_construct` not been implemented as a *named* abort, this would
have surfaced as a runtime failure inside CFRunLoop's first main-queue wakeup
instead of at the call — a good argument for machorun's choice to make the four
unimplemented Mach entry points announce themselves.

---

## Part 8 — QoS: the third case upstream doesn't model, and a defect in my own patch 3

### Compiling found a bug in patch 3 that reading did not

Patch 3's first version kept `typedef void *dispatch_mach_msg_t;` in the
real-headers branch. But dispatch's **own public headers** already declare it as
`struct dispatch_mach_msg_s *`, so that was the same collision one layer up —
I had removed the Mach-type collision and introduced a dispatch-type one.

Only `firehose_activity_id_t` is genuinely absent. Fixed. Worth recording *how*
it was found: by compiling the TUs, not by re-reading the patch. The patch looked
right.

### QoS is the same shape as Mach, with a sharper edge

`src/shims/priority.h` guards on:

```c
#if HAVE_PTHREAD_QOS_H && __has_include(<pthread/qos_private.h>)
```

Upstream models two worlds — **both** QoS headers present, or **neither**. Our
sysroot is a third it does not model: Darwin's **public** `<pthread/qos.h>` is
staged (so `qos_class_t` and its enumerators already exist) but Apple's
**private** `<pthread/qos_private.h>` is not.

Falling to the `#else` redefines every enumerator on top of the real ones:

```
error: redefinition of enumerator 'QOS_CLASS_USER_INTERACTIVE'
```

**But taking the public header is not sufficient either**, and this is the part
worth knowing before someone repeats it. Setting `HAVE_PTHREAD_QOS_H=1` gets the
enum and then demands Apple's private *priority-encoding* SPI:

```
error: unknown type name 'pthread_priority_t'
error: use of undeclared identifier '_PTHREAD_PRIORITY_QOS_CLASS_MASK'
error: use of undeclared identifier '_PTHREAD_PRIORITY_QOS_CLASS_SHIFT'
```

20 errors in one TU. `QOS_CLASS_MAINTENANCE` is also private SPI (`0x05`), not in
the public header.

So the two halves must be **split**, which upstream's single condition prevents:
take the real `qos_class_t` **enum** from the public header (it exists, it is
correct, redefining it collides), and keep libdispatch's **own** priority
encoding (`pthread_priority_t` and the mask/shift constants), because that is
Apple-private SPI we do not have and should not invent.

That is the remaining shape of patch 6. It is the same type-vs-capability split
as patch 3 — the *type* is real, the *encoding SPI* is not — but it needs the
condition broken into two rather than a header swapped.

**Not finished.** Recorded precisely rather than half-implemented, because the
wrong version of this patch invents Apple SPI values, and a wrong
`_PTHREAD_PRIORITY_QOS_CLASS_SHIFT` would mis-encode every queue priority
silently rather than failing to build.

### Patch 6 withdrawn — the "private SPI" is open source, in releases we already pin

Checked before writing it, and the answer removes the patch entirely. All three
headers libdispatch wants are published, in tags machorun already pins:

| header | release (already pinned) | path |
|---|---|---|
| `pthread/qos_private.h` | `libpthread-539.100.4` | `private/pthread/qos_private.h` |
| `sys/qos_private.h` | `libpthread-539.100.4` | `private/sys/qos_private.h` |
| `pthread/priority_private.h` | `xnu-12377.121.6` | `bsd/pthread/priority_private.h` |

`qos_private.h` alone is not enough — it includes the other two. With all three
staged, `HAVE_PTHREAD_QOS_H && __has_include(<pthread/qos_private.h>)` becomes
true, upstream's "both headers" case is satisfied, and **the third case
libdispatch does not model stops being a case at all**. No patch, no split
condition, and the encoding values come from Apple's source rather than anyone's
inference.

**And the inference would have been wrong.** The constants, read from xnu:

```c
typedef unsigned long pthread_priority_t;              /* :152 */
#define _PTHREAD_PRIORITY_QOS_CLASS_MASK   0x003fff00u /* :174 */
#define _PTHREAD_PRIORITY_QOS_CLASS_SHIFT  (8ull)      /* :175 */
```

The mask is **14 bits**, not the 8 that a shift of 8 and a plausible guess would
suggest. Every queue priority would have been mis-encoded — silently, since
nothing checks an encoding against a value it produced itself. `QOS_CLASS_MAINTENANCE`
is `((qos_class_t)0x05)` (`libpthread private/sys/qos_private.h:38`), which my
guess happened to match; the mask is the one that would have cost.

That is the argument for checking before inventing, in one number.

### Patch 6: closed. Headers landed 2026-08-27 (machorun master `2340749`)

All three staged with provenance; `sdk/` is now 379 headers. **Patch 6 stays
withdrawn permanently** — upstream's `HAVE_PTHREAD_QOS_H && __has_include(<pthread/qos_private.h>)`
is now simply true, and the third case libdispatch does not model has stopped
being a case.

**A constraint on our path, found by the probe rather than by us.**
`priority_private.h:232` uses **`THREAD_QOS_LAST`**, which is defined in *no
published Apple source* — not `osfmk/mach/thread_policy.h`, not
`osfmk/kern/kern_types.h`. It is kernel-private. The three `static inline`
encoders in that header therefore **compile** (nothing instantiates them) but
**cannot be called** from a guest.

libdispatch does not call them, so nothing here is blocked. But if a future
patch reaches `_pthread_priority_make_from_thread_qos()` the failure is an
undeclared-identifier error **at our own call site** — loud, local, and now
expected rather than surprising. Patch 5 (runloop eventfd handle) does not touch
the QoS encoders, so it is unaffected.

**`semaphore.h` is deliberately NOT staged**, and that is now a standing
agreement rather than an accident. Its absence is the only thing making the loud
failure precede the silent one for `USE_POSIX_SEM` (32 bytes into Darwin's 4,
clean link, zero return). Anyone needing `semaphore.h` for another consumer must
flag it to machorun-isamask **before** staging it — staging it silently arms
that path.

**Also landed and relevant to the eventual link step:** `struct kinfo_proc` /
`KERN_PROC_PID`, `struct tzhead` and their closure; the directory family with
real translation (`opendir`/`readdir`/`closedir`/`rewinddir`/`dirfd`) plus
`bsearch`, `div`, `ldiv`, `strncat`, `strnlen`, `getprogname`, `dlclose`,
`timezone`/`daylight`/`tzname`.

---

## Part 9 — patch 5 scoped to its exact sites (2026-08-27)

Measured against a pristine `release/6.2` checkout, so the anchor list is real
rather than remembered.

**The gate is wrong, not the code.** Every site selects Mach with
`#if TARGET_OS_MAC` and offers the eventfd path as `#elif defined(__linux__)`.
We are `TARGET_OS_MAC = 1` with no `__linux__`, so we take the Mach branch
every time — `mach_port_construct` is one of machorun's four self-naming
aborts, which is why this surfaces at the call rather than as a mystery.

The honest replacement is `TARGET_OS_MAC && HAVE_MACH`, because that states the
true condition: a Mac target *without* Mach IPC. `HAVE_MACH` is already 0 in
`sdk/dispatch-config/config_ac.h`, so nothing new has to be invented — the
config already knows, and only these guards fail to ask it.

**Six sites, and no others.**

| file | line | what |
|---|---|---|
| `private/private.h` | 190 | `typedef mach_port_t dispatch_runloop_handle_t` (the `int` branch is right there) |
| `src/queue.c` | 6473 | runloop handle helpers |
| `src/queue.c` | 6488 | " |
| `src/queue.c` | 6505 | " |
| `src/queue.c` | 6525 | `_dispatch_runloop_queue_handle_init` — `mach_port_construct` vs `eventfd` |
| `src/queue.c` | 6590 | `_dispatch_runloop_queue_handle_dispose` |

`src/queue.c`'s other `TARGET_OS_MAC` guards (3932–4152, 6923) are voucher and
QoS, **not** runloop handles, and must be left alone. That distinction is the
whole reason for scoping this by line rather than by a global substitution.

`eventfd` itself needs no staged Linux header: `scripts/stage_linux_abi.sh`
already declares it with a `GLIBCSYM` asm label and pins `EFD_CLOEXEC` /
`EFD_NONBLOCK` in `sdk/tests/epoll_abi_probe.c`.

**Deliberately not written yet.** Patch 5's TU cannot be compiled today — the
staged `sys/socket.h` is broken by the `constrained_ctypes.h` →
`machine/_param.h` → `net/net_kev.h` → `sys/_types/{_sa_family_t,_socklen_t,
_iovec_t}.h` chain, which also blocks 3 CoreFoundation files. Writing six
coordinated guard edits that nothing can compile would be the "compiles, links,
unverified" position this port exists to avoid. **That sysroot chain is now the
critical path for two consumers and is machorun's to fix.**

## Re-check, 2026-08-27: `sysctl` landed, but not the one patch 2 needs

machorun grew `sysctl` (machorun-isamask, for the five MIBs CoreFoundation's
`__CFInitialize` needs), and swift-loader-fixes flagged that any measurement
which failed earlier for un-localised reasons deserves re-running rather than
trusting. Two of mine were candidates. Both came back **unchanged**, recorded
precisely because a null result stated vaguely is worse than not running it.

**Patch 2 stands.** machorun exports **`_sysctl`** and *not* `_sysctlbyname`, in
the dylib and the `.tbd` alike. libdispatch's `hw_config.h` calls
`sysctlbyname` specifically, so the premise — "Linux has no such function, take
upstream's own `sysconf(_SC_NPROCESSORS_ONLN)` fallback" — is intact.

**But it is now a patch with an expiry date, and that is new.** If
`sysctlbyname` arrives, patch 2 stops being "this is not a Mac" and becomes a
divergence maintained for no reason — at which point the answer is to **delete
it**, not keep it correct in two places. That is the same call §12 made about
the shim's duplicates. Re-check when machorun-isamask's sysctl work finishes.

**libswiftCore's closure is unchanged**, re-measured against the *current*
userland (6 dylibs, 2,032 symbols) rather than this morning's number: 184
undefined, the same **two** unsatisfied, neither in any machorun dylib —
`_dyld_image_path_containing_address` and `_dyld_program_sdk_at_least`, both
dyld-surface rather than libSystem's. Guest `dlopen` landing did not touch them;
libswiftCore's `_dlopen`/`_dlsym`/`_dladdr`/`_dlerror` were already satisfied.

**And the re-check script mis-stated its own denominator.** It printed
`userland dylibs read: 0` while collecting 2,032 symbols — the counter was
incremented inside a subshell created by a pipe and discarded at the end of it.
The number was wrong and **detectably** so, because a second number in the same
output contradicted it. Sixth lost-counter zero of the day; the second caught
only because something adjacent disagreed. **Two numbers that must agree are
worth more than one number you trust** — the finding stood, the label did not.
