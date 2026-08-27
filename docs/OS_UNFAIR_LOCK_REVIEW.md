# Independent review: machorun's `os_unfair_lock` / direct-TSD

Reviewed by swiftcore-build, which did **not** write this code. Source read at
`darwin/src/libsystem.c:845-900` and `darwin/src/objcsupport.c:141-198`.

**One real defect found. It is not proven to be #50's corruption, and I am not
claiming it is.** Its likely symptom is a hang rather than heap damage. But it is
a genuine divergence from Darwin on the hottest path in the runtime, and the
comment asserting it is safe is unsound.

## What is correct

Most of this is right, and several things I went looking for are already handled:

* **The token can never be 0.** `mr_thread_token()` loops the counter past zero
  on wrap, with the reason stated ("a lock that reads unlocked while held").
  Zero is the unlocked sentinel, so this was the first thing worth checking.
* **Tokens are never reused.** It is a monotonic counter, not a slot index or a
  kernel tid — so the lead's "thread exits and its slot is reused" concern does
  not apply. Uniqueness is by construction over process lifetime, which is
  strictly stronger than a tid.
* **The lock algebra is correct.** CAS 0→me `ACQUIRE`; `expect` reset to 0 after
  each failed CAS (the CAS writes the observed value back, so this is
  necessary and present); release stores 0 with `RELEASE`.
* **Recursive acquisition is detected** (`expect == me`) and traps, matching
  Darwin, which also traps deliberately.
* **Cross-thread unlock is detected** — that is the `"this thread does not own
  the lock"` message seen in two of the 46 failing scenes.
* **Static initialisation is representation-compatible.** `OS_UNFAIR_LOCK_INIT`
  is `{0}` in `sdk/usr/include/os/lock.h`, matching Apple's, and 0 is this
  implementation's unlocked value. A statically initialised lock — objc4 has
  them — starts life correct. This was the `PTHREAD_COND_INITIALIZER`-shaped
  hazard worth checking, and it is clean.

## The defect: taking a lock can allocate

```
os_unfair_lock_lock()
  -> unfair_token()            libsystem.c:858
  -> mr_thread_token()         objcsupport.c:186
  -> dtsd_slots()              objcsupport.c:145
  -> glibc_calloc(...)         objcsupport.c:151   <-- allocates
```

On a thread's **first** lock acquisition, `dtsd_slots()` finds no TSD array and
calls `calloc`. So `os_unfair_lock_lock` is not allocation-free.

**Darwin's is.** Apple's `os_unfair_lock_lock` is a compare-and-swap on a 4-byte
word with a kernel wait; it never allocates, and callers are entitled to rely on
that — it is usable from allocator internals and from contexts where malloc is
not reentrant.

### The comment's safety argument is unsound

`objcsupport.c:180-182` says:

> This must be callable from anywhere a lock can be taken, so it must not take a
> lock itself. **It does not**: the counter is a single atomic, and the TSD path
> underneath is glibc's, which is independent of ours.

The counter part is right. The second half reasons about **whose** lock rather
than **whether there is one**. `glibc_calloc` takes glibc's malloc **arena
mutex**. "Independent of ours" is not "no lock" — and glibc's arena mutex is not
recursive, so a thread already inside glibc malloc that takes an
`os_unfair_lock` for the first time **self-deadlocks**.

This is the same shape as the other findings tonight: a correct-sounding
argument that checks the wrong property.

### Severity, honestly

* **Reachable deadlock** requires first-touch of a lock on a thread that is
  already inside glibc malloc. Narrow, but not obviously impossible: objc4 and
  the Swift runtime both take `os_unfair_lock` on allocation-adjacent paths.
* **Correlates with the #50 profile in one respect**: first-touch happens on
  *new* threads, and larger scenes create more threads — matching "worse on
  larger object graphs".
* **But it does not obviously produce heap corruption.** It produces a hang. I
  am flagging it as a real defect, not as the answer to #50.

### Fix, and it is cheap

Pre-populate the TSD array where the thread is born, so the lock path never
allocates: `mr_thread_trampoline` (`darwin/src/libsystem.c`) already wraps every
guest thread and already runs a malloc probe there. One call to `dtsd_slots()`
in the trampoline, plus one at loader init for the main thread, makes
`mr_thread_token()` a pure TSD read on every path a lock can reach.

Residual after that: any thread not created through our `pthread_create` would
still first-touch inside the lock. Today `pthread_create` bails on a non-NULL
attr and all guest threads go through the trampoline, so the set is closed —
but that is a property worth asserting rather than assuming.

## Question I could not answer: does the stress test exercise this shape?

`stress_unfair_lock.sh` passes 2000 runs, but I could not find its source under
`tests/src/`. **If it creates a fixed thread pool up front, every thread's
first-touch happens before contention begins, and the test cannot reach the
allocate-during-contention path at all.** 2000 clean runs of the wrong shape say
nothing about it.

The shapes that would exercise it: threads created *during* contention; a thread
whose first-ever lock acquisition happens while another thread holds that lock;
and a lock taken for the first time from inside an allocation path. Whoever owns
that gate should confirm which of these it covers.
