# Status

Independent verification, 2026-08-25. Everything below was re-run from a
**fresh clone into an empty directory** by an agent that did not build the
port, against the numbers the implementing agent reported. Nothing here is
taken from the previous report; where a claim is repeated it is because it was
re-measured.

Host: macOS 26.1, arm64, Apple clang 17 (oracle side).
Target: Ubuntu 24.04 aarch64 in Docker, clang 18.1.3 (port side).

---

## 1. Does it reproduce?

Yes, exactly.

```
$ git clone <repo> /tmp/clean && cd /tmp/clean
$ ./scripts/build_linux.sh
==> applying patches
apply-patches: 9 patch(es) applied -> build/objc4-src
[69/69] Building CXX object .../objc-runtime-new.mm.o
                                                    real 5.4s

$ ./scripts/difftest.sh
44 tests: 44 PASS, 0 FAIL, 0 SKIPPED
```

Run three times from scratch (`rm -rf build` between runs), plus eight extra
repeats of the concurrency-sensitive tests (`037-synchronized`,
`042-dlopen`, `043-threads`) — 44/44 every time, no flakes. `git status` in
the clone is clean afterwards: `vendor/` is untouched, as the rules require.

| Claim | Verified |
|---|---|
| 9 patches re-apply to pristine vendor | yes, three times |
| 33/33 translation units compile | yes (`build_linux.sh inventory`) |
| `libobjc.so` links with nothing unresolved | yes (`ldd -r` clean) |
| exported symbols | 426 by the inventory's own link; **383** by `nm -D --defined-only` on the `libobjc.so` the tests actually load. Two different link lines; the 426 figure is not the shipped library's. |
| 44/44 differential PASS | yes |

---

## 2. Are the baselines real?

This was the sharpest question, because a suite that regenerated its own
expectations from the port under test would prove nothing.

They are real, on three independent grounds:

1. **The harness re-checks the oracle on every run.** `difftest.sh` runs the
   live macOS binary and diffs it against `tests/expected/` before it looks at
   Linux at all; a mismatch reports `BASELINE-DRIFT`, not `PASS`. In the
   verification run every test's macOS column reads `ok` — the recorded
   baselines still match what Apple's shipping runtime prints today.
2. **`--record` is gated to Darwin.** `difftest.sh --record` exits 64 on any
   non-Darwin host. There is no code path that can write a baseline from the
   Linux side.
3. **Git history agrees.** The 40 original baselines were committed in
   `408ed44`, two commits *before* `bcd139c` ("objc4 compiles, links and
   loads") — recorded when the port could not run at all.

One baseline was edited after recording: `033-type-encoding`, one line,
`sizeof.longdouble=8` → `sizeof.longdouble.ge.double=yes` (`0c3ff38`). That is
a genuine ABI divergence — `long double` is 8 bytes on Darwin/arm64 and 16 on
AArch64 Linux, with no flag to change it — and it is disclosed in the commit
message and `docs/ABI_DIVERGENCE.md`. It is still a **weakened assertion**:
that one line is now trivially true on both sides and discriminates nothing.
Everything else in that test still compares exact strings.

---

## 3. Do the tests have teeth?

Passing tests are worthless if a broken runtime would also pass them. Checked
by attacking the suite:

**Mutation 1 — reverse category attach order.** Changed `attachCategories()`
to walk `cats_list` backwards: a plausible-looking one-line "cleanup" that
silently inverts category override precedence.

```
44 tests: 43 PASS, 1 FAIL, 0 SKIPPED
not passing: 011-category-collision
```

Caught, by exactly the test named for it, and by nothing else — so the suite is
both sensitive and specific.

**Mutation 2 — restore Apple's `FAST_DATA_MASK`.** Put back
`0x0f007ffffffffff8`, the value that assumes a 2^47 VA ceiling and would
silently truncate bit 47 of every `class_rw_t` pointer on Linux. It does not
compile:

```
objc-runtime-new.h:150: error: static assertion failed:
    "FAST_DATA_MASK must not mask off pointer bits"
```

The port added that guard. The dangerous assumption is enforced at build time,
not trusted.

**Other checks:**

* **Zero platform conditionals in the corpus.** No `#ifdef __APPLE__`, no
  `__linux__`, nothing. `grep` over all of `tests/*.m` and `testsupport.h`
  finds only include guards and one environment-variable name. The two sides
  compile literally the same source.
* **No empty or degenerate outputs.** 1155 baseline lines across 44 files,
  smallest is 7 lines. No baseline contains `unsupported`, `skip`, `n/a`,
  `error` or similar.
* **stderr is clean.** Only one test writes to stderr at all
  (`034-runtime-lookup`, `class 'T4LNoSuchClass' not linked into
  application`) and both sides write it identically. Nothing is passing while
  quietly complaining.
* **Dispatch really goes through the ported assembly.** 35 of 44 test binaries
  have an undefined reference to `objc_msgSend`, and `objc_msgSend` in our
  `libobjc.so` disassembles to the real hand-written aarch64 messenger
  (`cmp x0,#0` / `ldr x14,[x0]` / `and x16,x14,#0x7ffffffffffff8` / cache
  probe). The nine that do not are the pure-introspection tests — selectors,
  `respondsToSelector:`, method/property/protocol introspection, type
  encoding, symbol presence, `+load` ordering — which have no reason to send a
  message.
* **`042-dlopen` is not passing via its skip path.** Its baseline begins
  `libpath=nonnull`; the `SKIP=` branch is not taken on either side.

**One harness weakness found.** `difftest.sh` exits **0** when every Linux run
is SKIPPED:

```
$ OBJC4_SKIP_LINUX=1 ./scripts/difftest.sh 001 002
2 tests: 0 PASS, 0 FAIL, 2 SKIPPED     ; echo $? -> 0
```

`run_linux.sh` also reports SKIPPED (not failure) when `libobjc.so` is missing
or Docker is unreachable. That was a sensible day-one design — the skip count
was the progress metric — but now that the port runs it means CI wired to this
script goes green with the runtime entirely absent. One line
(`[ "$n_skip" -eq 0 ]` in the final conjunction) fixes it. Not changed here,
because changing a test harness's pass/fail semantics is the user's call.

---

## 4. New findings — things the 44 tests do not cover

Everything in this section is a fresh differential measurement made during
verification, not a repeat of an existing claim.

### 4.1 Tagged pointers are enabled and broken — the headline

`README` said "tagged pointers are untested". That understates it. They are
compiled **on**, and they are measurably wrong.

```
SUPPORT_TAGGED_POINTERS=1      SUPPORT_MSB_TAGGED_POINTERS=1
objc_debug_taggedpointer_mask = 0x8000000000000000   (both sides)
```

Same source, both sides, `_objc_registerTaggedPointerClass(1, TR)` then
`object_getClass` on the tagged bit pattern and one message send:

| | macOS (real objc4) | Linux (this port) |
|---|---|---|
| `object_getClass` | `TR` | `(nil)` |
| message send | `42` | **SIGSEGV** |

And the class table lands in a different slot for the same registration:

```
macOS : slot[5]=TR   slot[7]=__NSUnrecognizedTaggedPointer
Linux : slot[6]=TR
```

(`slot[7]` on macOS is registered by CoreFoundation and is not our concern.
`slot[5]` vs `slot[6]` for the identical call is.)

A third-order detail with real consequences: the linker warns that
`objc_debug_taggedpointer_classes` has no type or size in our dynamic symbol
table. lldb and the Swift runtime read these `objc_debug_*` symbols directly.

Any Foundation/CoreFoundation layer would use tagged pointers on the first
`NSNumber`. This is the highest-value correctness gap in the port.

### 4.2 The method-cache leak now has a number

`docs/UNIMPLEMENTED.md` B1 documents the leak and says "not measured yet.
Measure it before fixing it, so the fix has a number attached." Measured.

Workload: a class with a 256-entry warm cache, then N rounds of
`class_addMethod` (which flushes the cache) followed by 256 sends (which
refill it).

| rounds | Linux RSS growth | Linux peak RSS | macOS peak RSS |
|---:|---:|---:|---:|
| 1,000 | 11.6 MB | 15.3 MB | 2.0 MB |
| 5,000 | 47.3 MB | 51.0 MB | — |
| 20,000 | 173.1 MB | 176.8 MB | 4.7 MB |

**~8.7 KB leaked per cache invalidation, linear, unbounded** — which is
exactly one abandoned 512-bucket array (512 × 16 B = 8 KB), so the mechanism
is confirmed as well as the magnitude. At 20,000 rounds the port uses **38×**
the peak RSS of the real runtime.

The shape matters more than the number: the leak is proportional to cache
*invalidations*, not to live classes. A program that realizes its classes and
runs pays a bounded one-off cost of roughly one extra cache's worth of memory.
A program that swizzles, adds methods at runtime, or `dlopen`s categories in a
loop grows without bound.

### 4.3 `imp_implementationWithBlock` aborts loudly, as documented

Verified rather than assumed. No silent stub:

```
objc[11]: couldn't dlopen libobjc-trampolines.dylib: ... No such file or directory
objc4-linux: abort_with_reason(ns=19 code=1): ...
Aborted (exit 134)
```

### 4.4 Things that turn out to work, and are not tested

Three blind spots probed differentially; all three matched macOS exactly.

* **Full ARC codegen.** The entire corpus compiles `-fno-objc-arc`. A
  `-fobjc-arc` program using `strong`/`copy`/`weak`/`assign` properties,
  `@autoreleasepool`, `__weak`, `isKindOfClass:`, `respondsToSelector:` and
  `-dealloc` counting produced **byte-identical output** on both sides.
* **objc4's own `NSObject`.** Not Foundation's — the one in `NSObject.mm`,
  which this port builds and exports. `+new`, `-hash`, `-isEqual:`, `-release`
  all behave. (`-description` returns nil, which is objc4's own behaviour, not
  a port bug: Foundation overrides it.) No test in the corpus uses `NSObject`;
  they all use `TestRoot`.
* **ARC return-value elision.** The
  `objc_autoreleaseReturnValue`/`objc_retainAutoreleasedReturnValue`
  handshake, which depends on the ported arm64 assembly, matches macOS.

That these pass is good news, but they passed *untested* — which is the point
of listing them.

### 4.5 How much of the runtime the corpus actually touches

310 exported entry points with public-facing names
(`objc_*`, `class_*`, `object_*`, `method_*`, `ivar_*`, `protocol_*`,
`property_*`, `sel_*`, `imp_*`). The corpus references **135** of them (44%);
**175 are never touched**, or 108 excluding the 46 `objc_retain_x<N>` /
`objc_release_x<N>` register variants and the `objc_debug_*` data symbols.

Notable names in the untouched set: `objc_getProperty` / `objc_setProperty*`
(the accessor helpers clang emits for synthesized properties),
`objc_copyStruct`, `objc_enumerationMutation` (fast enumeration),
`objc_setExceptionMatcher` / `objc_setExceptionPreprocessor` /
`objc_setUncaughtExceptionHandler`, `class_getIvarLayout` /
`class_setIvarLayout` (ARC layout strings), `objc_getFutureClass`,
`object_isClass`, `object_getIndexedIvars`, `sel_isMapped`, the
`_objc_atfork_*` handlers, and every tagged-pointer entry point.

---

## 5. Swift interop: the honest verdict

This is the motivating goal, so it gets re-measured rather than repeated.

### The section-name claim holds

**Clang** — `clang-18 -target aarch64-unknown-linux-gnu
-fobjc-runtime=macosx-10.15`, ELF sections in both the `.o` and the linked
executable:

```
objc_classlist  objc_catlist  objc_nlclslist  objc_protolist  objc_imageinfo
```

**Swift** — `swiftc 6.2.4 -Xfrontend -enable-objc-interop`, same target, same
question:

```
objc_classlist  objc_imageinfo          (and swift5_* alongside)
```

Without `-enable-objc-interop`: no `objc_*` sections at all.

**The names agree.** This was the load-bearing assumption of the whole project
and it survives independent measurement. One `dl_iterate_phdr` + ELF
section-header discovery path serves both compilers, and the port's discovery
code needs nothing Swift-specific.

### The next wall, newly measured

Section names agreeing is necessary, not sufficient. Trying to actually link a
Swift file compiled with interop against this runtime fails one step earlier
than "Foundation is missing":

```
$ swiftc -Xfrontend -enable-objc-interop -c p.swift        # a plain class, no @objc
$ clang main.o p.o -lobjc -lswiftCore
undefined reference to 'OBJC_METACLASS_$__TtCs12_SwiftObject'
undefined reference to 'OBJC_CLASS_$__TtCs12_SwiftObject'
```

Every interop-enabled Swift class roots at `SwiftObject`, whose Objective-C
class symbols live in a libswiftCore built *with* interop. The shipped Linux
one is not:

```
$ nm -D --defined-only /usr/lib/swift/linux/libswiftCore.so | grep -c 'OBJC_\(META\)\?CLASS'
0
$ nm -D -u /usr/lib/swift/linux/libswiftCore.so | grep -c objc_
0
$ readelf -S /usr/lib/swift/linux/libswiftCore.so | grep -c objc
0
```

Zero ObjC class symbols, zero `objc_*` imports, no `objc_*` sections. And
`@objc` itself is refused outright without Foundation:

```
error: @objc attribute used without importing module 'Foundation'
error: only classes that inherit from NSObject can be declared '@objc'
```

So the real ordering is:

1. **objc4 on Linux** — done, this project.
2. **An Objective-C Foundation + CoreFoundation whose internals match what
   Swift's bridging expects** (`_CFStringGetCStringPtr`, `__SwiftValue`,
   `_SwiftNativeNSArrayBase`). Not started, explicitly out of scope, and the
   wall.
3. **Rebuild the Swift standard library with `-enable-objc-interop`** against
   (1) and (2). Previously implicit; now known to be *mandatory* — not one
   interop-enabled Swift file links without it.
4. Verify.

The README's caveat was right and is now sharper: step 3 is a hard,
never-done-on-Linux prerequisite sitting behind a step 2 that nobody has
built. **A complete objc4 on Linux does not get you measurably closer to
running Swift interop code than it did before — it gets you a runtime worth
having on its own terms, which is the honest reason to do it.**

---

## 6. Ranked: what stands between here and a complete runtime

| # | Item | Why it ranks here | Estimate |
|---|---|---|---|
| 1 | **Tagged pointers** (§4.1) | On by default, wrong answer, then a crash. Any Foundation hits it on the first `NSNumber`. Contained: a slot/obfuscator computation plus tests. | 1–2 days |
| 2 | **Block trampolines** / `imp_implementationWithBlock` | The largest *new code* item. `objc-blocktramps-arm64.s` is not in the vendored tree; it must be written from scratch, per architecture, matching the page layout `TrampolinePointerWrapper` asserts. The `memfd_create` + dual-`mmap` half is mechanical. | 1–2 weeks per arch |
| 3 | **x86-64** | Genuinely not started. CMake accepts the arch, warns, and builds with `OBJC4_ASM` empty — i.e. no messenger, link failure. Needs `objc-msg-x86_64.s` through `gen-elf-asm.py`, the isa/`FAST_DATA_MASK`/cache-mask work redone for x86-64's VA layout, and the whole corpus re-run. | 1–2 weeks |
| 4 | **Method-cache garbage collection** (§4.2) | Now quantified: unbounded for swizzling workloads. Fix is the `/proc/self/task` thread-PC scan sketched in UNIMPLEMENTED B1. | 2–3 days |
| 5 | **Corpus coverage** (§4.5) | 175 untouched entry points; no ARC-compiled test despite ARC working; no `NSObject` test; no fast enumeration, exception hooks, or fork safety. §4.4's blind spots should become tests 045–050 first, since they already pass. | ~1 week to ~100 tests |
| 6 | **Harness exit code** (§3) | One line. Do it before anyone wires CI. | minutes |
| 7 | `+load` ordering vs images that use ObjC without linking libobjc (UNIMPLEMENTED C3) | The riskiest *unknown*, but only reachable by unusual link setups. Narrowed, not resolved. | unknown; measure first |
| 8 | Long tail | `RESTORE_REGS` epilogue CFI (async unwind only), `dlmopen` namespaces, `_dyld_get_image_uuid` via `NT_GNU_BUILD_ID`, `_dyld_is_memory_immutable`, dtrace/SystemTap probes, structured crash reports. | days each, low value |

**Revised effort estimate.** To a complete, trustworthy runtime on both
aarch64 and x86-64, with a corpus that covers what it claims: **5–8 weeks** of
focused work, with items 2 and 3 dominating. The confidence in that number is
much higher than it would have been a session ago, because the hard structural
unknowns — ELF image discovery, the assembly messenger, exception unwinding
through hand-written frames, the 48-bit address assumption — are now resolved
and measured rather than estimated. What remains is largely known-shaped work.

The Swift-interop follow-on (§5) is **not** in that estimate and should not be
folded into it. It is gated on a Foundation that does not exist and a stdlib
rebuild nobody has done; months, and the honest answer is that its cost is
still unknown.

---

## 7. Verdict

The reported numbers are real. 44/44 reproduces from a clean clone, the
baselines genuinely come from Apple's shipping runtime, the corpus is
sensitive to subtle semantic breakage, and the load-bearing ELF section-name
claim survives independent measurement on both compilers.

The gap between the report and reality is one of *scope*, not of honesty:
44 passing tests touch 44% of the runtime's exported surface, and the first
thing probed outside that surface — tagged pointers — was broken. The
project's own discipline is what found it, applied one step further out.
