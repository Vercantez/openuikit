# The differential oracle harness

macOS has the real objc4. This project has a port that does not exist yet. The
harness exists so that every claim the port makes is checkable by running the
same program on both and diffing the bytes.

**`tests/expected/*.txt` is the oracle.** Each file is stdout from that test
compiled by Apple clang against the system `libobjc` on macOS. It is recorded,
not written. If you find yourself editing one by hand to make something pass,
stop: you are editing the specification of Objective-C.

---

## Layout

```
tests/testsupport.h      shared scaffolding: TestRoot, say(), event log
tests/NNN-name.m         one test, one translation unit, compiles on both sides
tests/expected/NNN-name.txt   recorded macOS output -- the oracle
harness/run_macos.sh     compile + run one test against the SYSTEM runtime
harness/run_linux.sh     compile + run one test in Docker against OUR libobjc
scripts/difftest.sh      run the corpus both ways, diff, print the table
build/difftest/          actual outputs from the last run (gitignored)
```

## Running

```sh
scripts/difftest.sh                 # everything, both sides
scripts/difftest.sh 019 027         # only tests whose name contains these
scripts/difftest.sh --macos         # check the baseline still reproduces
scripts/difftest.sh --linux         # our port only
scripts/difftest.sh -v              # print a unified diff for every FAIL
scripts/difftest.sh --record        # re-record the oracle (macOS only)
```

One test at a time, for iterating:

```sh
harness/run_macos.sh tests/019-properties.m
harness/run_linux.sh tests/019-properties.m
```

### Result taxonomy

| result | meaning |
|---|---|
| `PASS` | Linux output is byte-identical to the oracle. |
| `FAIL` | Linux ran but printed something else, or crashed, or would not compile. This is the signal. |
| `SKIPPED` | No `libobjc.so` to test against yet, or Docker is unavailable. The skip count is a progress metric. |
| `BASELINE-DRIFT` | **macOS** no longer matches its own recorded baseline. The oracle moved -- new OS, or an edited test. Nothing about the port is being measured until this is resolved. |
| `MACOS-BROKEN` | The test no longer compiles or runs on macOS at all. |
| `NO-BASELINE` | A test exists with no recorded expectation. Run `--record`. |

### What `run_linux.sh` needs from the build

It takes two paths and does not care how they are produced:

| variable | meaning | default |
|---|---|---|
| `OBJC4_LINUX_LIBDIR` | directory containing `libobjc.so` | first of `build/linux`, `build/linux-aarch64`, `build`, `out` that has one |
| `OBJC4_LINUX_INCLUDE` | directory containing `objc/*.h` | `$LIBDIR/include`, `build/include`, `include` |
| `OBJC4_DOCKER_IMAGE` | container to build in | `swift:6.2-noble` |
| `OBJC4_LINUX_TARGET` | clang target triple | `aarch64-unknown-linux-gnu` |
| `OBJC4_SKIP_LINUX=1` | force SKIPPED without touching Docker | unset |

Both sides compile with the *same* flags apart from the target and the runtime:
`-O0 -g0 -fno-objc-arc -fobjc-exceptions`. The Linux side adds
`-fobjc-runtime=macosx-10.15`, which is the flag that makes clang emit
Apple-ABI class metadata and `objc_classlist` sections on ELF. Without it clang
emits the GNUstep ABI and none of this corpus means anything.

`-O0` is not laziness. Optimisation changes ARC and message-send codegen
(`objc_retainAutoreleasedReturnValue` elision, in particular), and that must not
be free to vary between the two sides of a diff.

---

## Adding a test

1. Create `tests/NNN-short-name.m`. Start with the next free number; the number
   is only for ordering the table.
2. `#include "testsupport.h"`. Subclass `TestRoot`, never `NSObject`.
3. Print one `key=value` line per fact through `say()`.
4. Run it on macOS: `harness/run_macos.sh tests/NNN-short-name.m`.
5. Record it: `scripts/difftest.sh --record NNN`.
6. Commit the `.m` **and** the `tests/expected/NNN-short-name.txt` together. A
   test without a recorded baseline is not an oracle.

Prefer many small tests to a few large ones. When a test with sixty assertions
fails, the diff tells you sixty things at once and you read none of them.

### Determinism rules

These are not style preferences. A single nondeterministic line makes the whole
test useless as an oracle, and the failure looks like a port bug.

1. **Never print a pointer.** Print `NULLNESS(p)` (`null`/`nonnull`) or a
   comparison (`YN(a == b)`). Addresses differ per run, per platform, per ASLR
   roll.
2. **Never print a size or offset you did not intend as ABI.** Instance sizes
   and ivar offsets *are* the ABI and should be printed absolutely --
   disagreement there is a real defect. Anything else (malloc sizes, page
   counts) is not.
3. **Sort every list the runtime hands you.** `class_copyMethodList`,
   `class_copyIvarList`, `class_copyPropertyList`, `class_copyProtocolList`
   and `protocol_copyMethodDescriptionList` return emission order, which is a
   linker artifact. Use `print_sorted_strings()`.
4. **Never enumerate the whole runtime.** `objc_getClassList` on macOS returns
   every class in libSystem. Name only classes the test defines.
5. **No timing, no thread scheduling, no addresses of C globals.** Anything
   whose value depends on when it ran does not belong in stdout.
6. **No file paths.** `class_getImageName` returns a path that differs by
   construction.
7. **stdout only.** The runtime writes diagnostics to stderr (for example
   ``objc[123]: class `X' not linked into application``) and stderr is not
   compared. Do not print test results there.
8. **Every line flushes.** `say()` does this; do not `printf` directly.
9. **Floating point gets an explicit precision.** `%.4f`, never `%f`.
10. **Balance your reference counts.** An over-release crashes only sometimes,
    which is worse than crashing always. Two tests in this corpus were written
    wrong the first time and caught exactly this way.

### The no-Foundation constraint

objc4 alone has no `NSObject`. Every test brings its own root class, and that
constraint is itself worth verifying -- it is the configuration a bare
`libobjc.so` on Linux will actually be used in first.

`TestRoot` in `testsupport.h` implements `-retain/-release/-autorelease/`
`-retainCount/-allowsWeakReference/-retainWeakReference` by forwarding to
`_objc_rootRetain` and friends. That is **not optional**: objc4 gives every
non-`NSObject` root class the custom-RR/AWZ/Core bits unconditionally (the
"Custom root class" branch of `scanAddedClassImpl` in `objc-runtime-new.mm`),
so `objc_retain()` and `objc_release()` `objc_msgSend` rather than touching the
refcount inline. Without those methods the first `objc_release()` aborts with
`-[X release]: unrecognized selector`. That abort is what the first draft of
`testsupport.h` actually produced; `tests/028-arc-custom-rr.m` now pins the
behaviour as an oracle fact.

Tests compile `-fno-objc-arc` and call the ARC entry points
(`objc_retain`, `objc_storeWeak`, `objc_autoreleasePoolPush`, ...) directly,
because those C functions *are* the runtime contract. ARC codegen would only
put a layer between the test and the thing being measured. Entry points Apple
keeps in the private `<objc/objc-internal.h>` are declared by hand in
`testsupport.h` rather than included, so one source file compiles unchanged on
both sides.

---

## Coverage

40 tests, 3,743 lines of test source, 1,101 recorded output lines. Every one of
those lines is a measured fact about Apple's runtime.

| tests | area |
|---|---|
| 001, 002 | root class, metaclass topology, inheritance chains |
| 003 | selector uniquing and round-tripping |
| 004, 005, 040 | dispatch: inherited/overridden/super, every ABI return shape, `objc_msgSendSuper2`, `method_invoke`, IMP caching |
| 006, 007 | `+load` absolute order and the contractual orderings |
| 008, 009 | `+initialize` timing, which APIs trigger it, inheritance cascade |
| 010, 011 | categories: addition, override precedence, multi-category collision |
| 012 | `respondsToSelector` across the class/metaclass split |
| 013, 014, 015 | `class_addMethod`, `class_replaceMethod`, `method_exchangeImplementations` |
| 016 | `Method` introspection and type encodings |
| 017, 018 | ivar lookup, get/set, non-fragile layout |
| 019 | property attribute strings |
| 020, 021, 022 | protocol conformance, method descriptions, protocol properties |
| 023, 024 | `objc_allocateClassPair` / `objc_registerClassPair`, runtime subclassing, isa-swizzling |
| 025 | the private-symbol export surface Swift depends on |
| 026, 027 | associated objects and all five association policies |
| 028, 029, 030 | ARC entry points, reference counts, autorelease pool nesting |
| 031, 032 | weak references, zeroing on dealloc, `copyWeak`/`moveWeak` |
| 033 | `@encode` |
| 034 | class lookup by name, `objc_duplicateClass` |
| 035 | `+resolveInstanceMethod:` / `+resolveClassMethod:` |
| 036 | messaging nil on every return path |
| 037 | `@synchronized` / `objc_sync_*` |
| 038 | exceptions, `@finally` ordering, unwinding through `objc_msgSend` |
| 039 | `objc_setForwardHandler` and the end of the lookup chain |

### Things the oracle said that we would have got wrong by reading

Recorded here because each one was a surprise, and each is now pinned:

- A non-`NSObject` root class is **always** custom-RR. (`028`)
- `class_getMethodImplementation` triggers `+initialize`; `class_createInstance`,
  `class_respondsToSelector`, `class_copyMethodList` and `class_addMethod` do
  not. (`008`)
- `class_respondsToSelector` **does** invoke `+resolveInstanceMethod:`. (`035`)
- An inherited `+initialize` body runs once per subclass, with `self` bound to
  each subclass in turn. (`009`)
- The `COPY` association policies send `-copy`, not `-copyWithZone:`. (`027`)
- `OBJC_ASSOCIATION_RETAIN` (the atomic one) makes the **getter**
  retain+autorelease, so association lifetime tests are meaningless without a
  pool in scope. (`027`)
- `objc_setAssociatedObject(nil, key, nonNilValue, policy)` segfaults; only the
  all-nil case is defended. (`026`)
- `objc_duplicateClass` publishes its new name immediately;
  `objc_allocateClassPair` does not, and a second pair with the same name can be
  allocated while the first is still unregistered. (`023`, `034`)
- `@optional` protocol *properties* are stored in the **required** list with a
  `?` attribute -- clang does not split them the way it splits methods. (`022`)
- `objc_allocateClassPair`'s `extraBytes` does not appear in
  `class_getInstanceSize`. (`023`)
- `objc_loadWeak` is `objc_autorelease(objc_loadWeakRetained(...))`, so it
  perturbs the retain count of what it loads. (`031`)

### Deliberately not covered yet

- Threads. Nothing in the corpus is multithreaded, because contention order is
  not deterministic and this harness compares bytes. `+load` under concurrency
  (`vendor/objc4/test/03-load-parallel.m`) belongs to phase 3.
- `dlopen` after startup, and multi-image programs generally. Every test is a
  single executable image; that is exactly the case the phase-1 constructor
  handles, and it hides the hardest ordering question in the project.
- Tagged pointers, blocks-as-IMPs (`imp_implementationWithBlock`), and cache
  garbage collection -- all stubbed in phase 1 by plan, so testing them now
  would only record that they are stubbed.
- `objc_readClassPair` is probed for existence in `025` but never called:
  calling it requires a hand-built `objc_class` + `class_ro_t`, whose layout is
  private, and encoding one objc4 vintage's layout into the corpus would make
  the corpus wrong the next time vendor is updated.
- Apple's own `vendor/objc4/test/` suite (265 files). That is phase 2 and it is
  a better oracle than anything written here; this corpus is the thing that has
  to work *before* those can even be attempted.
