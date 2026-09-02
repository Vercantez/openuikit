# Patch 4 — the `_dispatch_sema4_t` backend for a Darwin target without Mach

**Status: implemented and verified on both platforms. NOT YET APPLIED to the
port's tree** — the tooling lives in `~/swiftcore-macho`, which is on this
scope's do-not-edit list; awaiting a ruling on where it should land.

## Why a fourth branch and not a config flag

`src/shims/lock.h` offers `USE_MACH_SEM` / `USE_POSIX_SEM` / `USE_WIN32_SEM`
then `#error "port has to implement _dispatch_sema4_t"` (line 221). We are a
Darwin target without Mach IPC — a combination upstream does not model — so
this is a patch, honestly labelled, rather than a flag.

`USE_POSIX_SEM` looks like the one-line fix and is a trap:

* `_dispatch_sema4_t` is embedded **by value**. `typedef sem_t _dispatch_sema4_t`
  puts Darwin's **4-byte** `sem_t` where glibc's `sem_init` writes **32**. Clean
  link, `0` return, 28 bytes gone — the opaque-pointer audit's first live
  instance, in exactly the path CF needs.
* Darwin does not implement unnamed POSIX semaphores at all: `sem_init` returns
  `-1`/`ENOSYS` on macOS 26 arm64. Selecting it would emulate a configuration
  Apple's own platform never has.
* Darwin's `sem_t` is 4 bytes, so the pointer-handle trick that fixes
  `posix_spawnattr_t` cannot apply — 4 bytes cannot hold a pointer.

## Why mutex+condvar is safe here, measured

* **No overflow, because both are handles.** machorun's `cond_glibc()` stores a
  pointer to a heap glibc cond in the first 8 bytes of Darwin's opaque area, and
  the mutex path does the same through `adopt()`. Nothing is written past the
  guest's allocation regardless of the size disagreement. `sizeof` is 120 on
  both platforms (mutex 64 + cond 48 + long 8).
* **ETIMEDOUT is translated, and I checked the mechanism rather than the
  comment.** `mr_pthread_rc()` wraps `glibc_pthread_cond_timedwait` at the call
  site. A direct probe under machorun returns **`rc=60`**, matching the compiled
  Darwin `ETIMEDOUT`. Without it a guest sees Linux's 110, compares against 60,
  and concludes a wait that EXPIRED had SUCCEEDED.
* **Attributes must be NULL**, and are: `pthread_cond_init` with a non-NULL attr
  bails by design, so no `CLOCK_MONOTONIC` condattr exists. That costs nothing —
  `_dispatch_sema4_timedwait` is handed nanoseconds since the **epoch**, which is
  the realtime clock the default cond already uses. Mutex attrs are NULL too,
  which sidesteps the swapped mutex **type** constants entirely.
* **No static initialisers**, preserving the invariant `dispatch_patches.py`
  asserts: everything is created in `_dispatch_sema4_init`.

## The return value that is easy to get backwards

`_dispatch_sema4_timedwait` returns **`true` when it TIMED OUT**. Inverting it
makes every timed wait report success — the silent-pass shape — so the test
targets exactly that.

## Verification: both platforms, teeth demonstrated

`tests/t4_sema4.c`, built native on macOS and as Darwin Mach-O under machorun.

| case | macOS native | machorun / Linux |
|---|---|---|
| 1 wait blocks until signalled from another thread | PASS (130 ms) | PASS (130 ms) |
| 2 timedwait expires **[negative control]** | PASS (true, 159 ms) | PASS (true, 150 ms) |
| 3 timedwait acquires | PASS (false) | PASS (false) |
| 4 `signal(3)` releases exactly three | PASS | PASS |

Case 1 fails if the waiter returns before the signaller ran, so an inline
no-op cannot pass it. Cases 2 and 3 are a **pair**: a timedwait that always
returned `true` passes 2 and fails 3, one that always returned `false` does the
reverse. Neither alone has teeth.

Mutants, to prove the suite can fail — the first attempt at this check was
itself a false green (exit 1 was the *compiler* failing, not the test):

| mutant | fails |
|---|---|
| A — `timedwait` returns `false` on timeout | **case 2 only**, on macOS *and* under machorun |
| B — `_dispatch_sema4_wait` is a no-op | cases 1 and 4 |

Mutant A is the ETIMEDOUT shape, and it fails the same single case on both
platforms — which is what makes the passing run mean something.

## Not done

The rest of #47's bar: a timer source that actually fires, and async completing
out of line. Those are libdispatch-level and need the library linking, not just
this backend. Patch 5 (runloop eventfd handle) is blocked — see CF_TRIAGE §37.
