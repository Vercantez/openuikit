# Does CoreFoundation's preferences path EXECUTE? — two named walls

Measured 2026-08-28 in the `fm-build` container, driving `libCFTest.dylib`
under machorun on Linux/arm64. Probes: `tests/t16_cfprefs.m`,
`tests/t17_pthread_sig.c`, `tests/t18_bundle_identity.c`.

This is the measurement #78's route ruling turned on. `CFPreferences`,
`CFApplicationPreferences`, `CFXMLPreferencesDomain`, `CFKnownLocations`,
`CFPropertyList`, `CFBinaryPList`, `CFURLAccess` and `CFFileUtilities` all
compile, link, and export from `libCFTest.dylib`. **None of them had ever run.**
Now they have, and they stop in two places.

Neither wall is in UserDefaults, and neither is in the preferences code. Both
are substrate.

---

## WALL 1 — `CFLock_t` is an ERRORCHECK pthread mutex; machorun accepts only the default

T16 dies on its **first** CF preferences call, before any file is touched:

```
  .. CFPreferencesCopyAppValue on a key that was never set (must be NULL)
machorun/libSystem: a pthread object has an unexpected Darwin signature; its
layout was compiled into the guest and cannot be renegotiated
    #1  libSystem.B.dylib  (_pthread_mutex_lock+0xa8)
    #2  libCFTest.dylib    (_CFPreferencesCopyAppValue+0xa8)
```

**Cause, isolated from CoreFoundation entirely by T17** — thirty lines, three
static mutexes, no CF:

```
signatures as compiled into the guest:
  plain      0x32AAABA7      <- machorun's DARWIN_MUTEX_SIG
  errorcheck 0x32AAABA1      <- CF's CFLockInit
  recursive  0x32AAABA2

locking the PLAIN mutex ...        ok
locking the ERRORCHECK mutex ...   machorun/libSystem: unexpected Darwin signature
```

`darwin/src/libsystem.c:1159` defines `DARWIN_MUTEX_SIG 0x32AAABA7` and
`adopt()` bails unless the signature word is that or zero. Apple's
`pthread_impl.h` defines four static initialisers, and CF uses one of the other
three:

```c
// CFLocking.h:19-28, the TARGET_OS_MAC branch — which is OUR branch
typedef pthread_mutex_t CFLock_t;
#define CFLockInit ((pthread_mutex_t)PTHREAD_ERRORCHECK_MUTEX_INITIALIZER)
#define __CFLock(LP) ({ (void)pthread_mutex_lock(LP); })
```

**This is a TARGET_OS_MAC gate the sweep could not have seen.**
`docs/cf-census/target-os-mac-sweep.md` counts "273 `TARGET_OS_MAC` gates in
CF's **`.c` sources**". `CFLocking.h` is a *header*. The gate is real, it is
sole-entry, and it was outside the instrument's scope — the
`gate-scope-excludes-the-answer` shape, in a sweep that was otherwise correct
about everything it looked at. **Any future CF gate audit must include headers.**

It is also not a preferences problem. `CFLock_t` is CF's lock *everywhere*, so
this blocks every CF path that takes one. It has not surfaced before because
T8/T9 exercise `CFString`/`CFArray`/`CFDictionary` paths that do not.

**Fix, and it belongs to machorun, not here.** `adopt()` should accept
`0x32AAABA1` (errorcheck), `0x32AAABA2` (recursive) and `0x32AAABA3`
(firstfit) and set the corresponding glibc type via
`pthread_mutexattr_settype` — `PTHREAD_MUTEX_ERRORCHECK` and
`PTHREAD_MUTEX_RECURSIVE` exist; firstfit is a fairness policy with no glibc
equivalent and mapping it to default should be *recorded* rather than assumed
harmless. Doing it in machorun fixes it for every guest; doing it by editing
`CFLockInit` fixes it for CF only and quietly drops the error-checking
semantics upstream chose.

**A probe that was built and then discarded, because it would have been a
false green.** The obvious experiment is "patch `CFLockInit`, rebuild CF, see
how much further it gets". I did that, and the rebuilt CF **was not the CF that
is running**: 86 objects compiled, but 32 differed from the shipped ones, with
**101 non-cosmetic symbol differences** — `CFLocaleKeys.o` missing the
`kCFNumberFormatter*`/`kCF*Calendar` constants, and `CFRuntime.o` *defining*
`___CFConstantStringClassReference`, which our Foundation is supposed to
supply. Reporting that build's behaviour as "CF's behaviour" would have been a
measurement of a different library. It was deleted.

**Which exposes a third thing worth its own line: `/work/cfobjc` is now
reproducible from `scripts/build_cfobjc.sh`.** The flags that built it used
to exist only in a shell history. `cf_census.sh`'s flags reproduce *one* file
(`CFPreferences.o`, symbol-for-symbol) and diverge on 32 — and checking one
file and generalising is exactly how I got it wrong the first time. The
committed recipe is that census argv **plus** every flag and patch this tree
already named as load-bearing (recipe id `cfobjc.1`). `--print-argv` prints
`CFOBJC_ARGV:` with:

- `-target $TRIPLE` — `guest_arch.inc`; `cf_census.sh`
- `-isysroot $SDK` — `cf_census.sh`
- `-x objective-c` — `patch_cf_objc.py` (76/82 vs 77/82 as C)
- `-fobjc-runtime=macosx-13.0` — `classify_ns_names.sh`, `build_cf_probes.sh`
- `-fno-objc-arc` — every ObjC compile in this lane
- `-DINCLUDE_OBJC=1` — `patch_cf_objc.py`; `CoreFoundation_Prefix.h:87`
- `-DCF_BUILDING_CF` — `cf_census.sh`
- `-DDEPLOYMENT_RUNTIME_SWIFT=0` — `cf_census.sh`; `docs/DECISION.md`
- `-DHAVE_STRUCT_TIMESPEC` — `cf_census.sh`
- `-DSWIFT_CORELIBS_FOUNDATION_HAS_THREADS=1` — `docs/cf-census/nine-own-exports.md`
- `-fblocks -fconstant-cfstrings` — `cf_census.sh`; `NSCF_DESIGN.md`
- `-fdollars-in-identifiers -fno-common` — `cf_census.sh`
- `-fcf-runtime-abi=objc` — `cf_census.sh`; `CF_TRIAGE.md` §7 (NOT `=swift`)
- `-fexceptions -Os` — `cf_census.sh`
- `-include CoreFoundation_Prefix.h` — `cf_census.sh`
- `-include CFShimCarbon.h` — `cf_census.sh`; `cf_shims.sh`
- `-include CFNSForwards.h` — `gen_ns_forwards.py`
- `-include CFFoundationInterfaces.h` — its own comment: FORCE-included
- `-Dd_fileno=d_ino` — `cf_census.sh`
- `-DDISPATCH_APPLY_AUTO=((dispatch_queue_t)0)` — `cf_census.sh`
- `-idirafter $X` — `cf_census.sh` (`cfextra` shims)
- `-I $CF/include -I $CF/internalInclude` — `cf_census.sh`
- `-I $OURINC` — `classify_ns_names.sh`
- `-I $ICU_INC` — `cf_census.sh` (unblocks ICU TUs)

Sources are `$CF/*.c` only (the 86-file census glob). Patches apply to a
**copy** under `$OUT/src`: `patch_cf_objc.py`, `patch_cf_runloop.py`,
`patch_cf_prefs_binary.py`, `patch_cf_knownlocations.py`,
`gen_alias_shims.py`. `build_cftest_harness.sh` remains the only `libCFTest`
linker; it consumes `cfobjc/obj/*.o`. This is no longer
`generator-not-in-the-gates`.

---

## WALL 2 — `-[__NSCFConstantString _fastCStringContents:]` is unimplemented

T18 asks the question the ruling asked for — what `CFBundleGetMainBundle()` /
`CFBundleGetIdentifier()` return here, because `CFPreferences.c:439-442`
resolves `kCFPreferencesCurrentApplication` through them and **silently falls
back to `_CFProcessNameString()`**, which changes the plist *filename* while
every in-process read still passes.

It does not get to an answer. It dies somewhere else entirely:

```
objc: -[__NSCFConstantString _fastCStringContents:]: unrecognized selector
    #5  libCFTest.dylib  (_CFStringFindWithOptionsAndLocale+0xf0)
    #6  libCFTest.dylib  (_CFURLCreateWithFileSystemPath+0x8c)
    #7  libCFTest.dylib  (_CFBundleGetMainBundle+0x74)
```

**The selector was already on the harvested list.** It is
`docs/cf-census/cf-objc-methods.txt:55`. This is not an unknown; it is a known
member of the 151-selector CF→ObjC dispatch surface that nothing implements.

Measured across `src/**/*.m`: **80 of the 151 harvested selectors are
implemented nowhere.** Read that number carefully — it is *not* 80 broken
paths. CF dispatches only when it decides an object is foreign, and T8/T9 show
the common paths never dispatch. It is "80 selectors that abort **if**
reached", and the bundle path reaches one of them.

The extractor was checked before the number was believed: it finds all seven
selectors T8/T9 prove work (`length`, `count`, `objectAtIndex:`,
`objectForKey:`, `characterAtIndex:`, `hash`, `isEqual:`), and the five it calls
missing are absent from `src/` by direct grep.

**So `#51`'s "NS* surface complete" is true of what it set out to do and not
true of this path.** The gap is on `__NSCFConstantString`, which implements 9
selectors — and every `CFSTR()` literal in CF is one.

---

## What this does and does not say about UserDefaults

**Does not:** UserDefaults is not implicated. Both walls are below it, and the
ported `UserDefaults` scores 627/627 against real Foundation on the host route
(`~/swift-macho-linux/full/oracle-userdefaults/`), where the CoreFoundation
underneath is Apple's.

**Does:** the guest route for UserDefaults is blocked on two substrate items,
both now named, attributable and reproduced by a probe smaller than the thing
it explains. Wall 1 is a machorun fix of a few lines. Wall 2 is a Foundation
fix in this repo, and its size is bounded by a list that already exists.

**Not measured, and it stays that way rather than being guessed:** whether
anything is behind those two. T16 stops at the first lock, so the file write —
`mkstemp`/`write`/`fsync`/`chmod`/`rename`, and the `#69` surface it lands on —
has still never executed. The *static* lower bound is five loud stubs directly
referenced by the eight preferences translation units:

| stub | referenced by | reachable on UserDefaults' path? |
|---|---|---|
| `OSAtomicCompareAndSwapPtrBarrier` | `CFPreferences.o`, `CFPlatform.o` | only in the by-host gate and `_CFProcessNameString` |
| `gethostuuid` | `CFPreferences.o` | no — by-host only; UserDefaults passes `kCFPreferencesAnyHost` |
| `chown` | `CFXMLPreferencesDomain.o` | no — guarded by `writingFileAsRoot` |
| `readdir_r` | `CFFileUtilities.o` | not on the read/write path |
| `strtok` | `CFFileUtilities.o` | unknown |

Direct references only. CF calls CF, so a stub three levels down is not in that
set; it is a lower bound and is stated as one.

**One correction to the #78 scope report from this:**
`OSAtomicCompareAndSwapPtrBarrier` was reported there as "already implemented
in `src/compat/OSAtomic.c`". The file exists, but `src/compat` is **not in the
`libCFTest` link** (`build_cftest_harness.sh` links `cfobjc/obj/*.o` and
`nscfobj/*.o` only), so the symbol is a loud stub in the binary that actually
runs. The conclusion it supported — that the by-host gate is unreached — is
unchanged and now rests on the gate, not on the symbol.

And a correction to that sweep's own reading: `__byHostIdentifierString` /
`__hostUUIDString` are **static locals** caught by the sweep's address-of rule,
not symbols. The gate's real dependency is `gethostuuid`, and it has a portable
`#else` returning `CFSTR("")`.
