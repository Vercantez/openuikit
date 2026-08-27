# The TARGET_OS_MAC sweep: 157 gates where Apple's branch is the only way in

The root cause behind the nine own-exports, converted from an open-ended series
of surprises into a list. **We are `TARGET_OS_MAC` by target triple and corelibs
by implementation**, so corelibs branches meaning *"Apple's CoreFoundation
supplies this"* and we take Apple's branch without Apple's code.

`scripts/sweep_target_os_mac.py`, full output in `target-os-mac-sweep.txt`.

## Counts

```
273  TARGET_OS_MAC gates in CF's .c sources
157  where TARGET_OS_MAC is the SOLE way in
117  of those reported (the rest are trivially small with nothing unresolved)
152  distinct names those branches call or take the address of, that neither
     our built objects nor CF's own sources define
```

The 116 gates that also admit `TARGET_OS_LINUX`/`BSD`/`WIN32`/`WASI` are
excluded on purpose: corelibs takes them on Linux too, so their contents are
portable by construction. **Only a gate where `TARGET_OS_MAC` is the sole entry
can hide Apple-only code** — which is what makes 157 the number that matters
rather than 273.

## The families, and they are not evenly distributed

**Mach (8)** — `mach_task_self`, `mach_vm_allocate`, `mach_vm_deallocate`,
`mach_vm_region`, `vm_purgable_control`, `mach_error_string`,
`mach_absolute_time`, `mach_timebase_info`.
Concentrated in `CFUtilities.c:200` and `CFUtilities.c:1180` — the
purgeable-memory allocator, which is where `vm_purgable_control` already
surfaced at CF's link. Exactly where the prediction said to look.

**Darwin malloc zones (5)** — `malloc_default_zone`, `malloc_zone_calloc`,
`malloc_zone_memalign`, `malloc_size`, `round_page`.
Almost all in `CFBase.c:109`, a 146-line block — **the largest single gate in
CF** — implementing CFAllocator on top of Darwin's zone allocator. This is the
one I would look at first: it is allocator infrastructure, not a peripheral
feature, and `malloc_zone_memalign` was already on CF's undefined list.

**Apple diagnostics (2)** — `CRSetCrashLogMessage2`, `os_log_debug`. Cosmetic;
`cf_shims.sh` already stubs the `os_log` family.

**Apple SPI (4)** — `sysctlbyname`, `pthread_is_threaded_np`,
`__byHostIdentifierString`, `__hostUUIDString`. The last two are CFPreferences'
per-host preference identity, which has no Linux meaning at all.

## What this does and does not say

**Does:** the surface is bounded and clustered. Two files — `CFBase.c` and
`CFUtilities.c` — hold the allocator and Mach concentrations, and those are the
two that matter. `CFRunLoop`, `CFSocket` and `CFFileDescriptor` did **not**
dominate, which was the prediction and is worth recording as a prediction that
did not hold: the runloop patches already neutralised its Mach paths.

**Does not:** prove any given gate is reached. These are *link-visible*
references inside Apple-only branches — the same lower-bound shape as everything
else today. A name here is a candidate, not a verdict, and some are local
variables caught by address-of. **The tool reports what it cannot attribute
rather than dropping it**, because a "could not determine" bucket read as noise
is what hid the CFDictionary isa crash for hours.

## Method note

Depth-tracked, not grepped. Reading the *nearest* `#if` gave the wrong enclosing
condition twice in one investigation earlier today — `_CFThreadSetName` looked
guarded by `SWIFT_CORELIBS_FOUNDATION_HAS_THREADS` when the real gate was
`DEPLOYMENT_RUNTIME_SWIFT`, opened 119 lines earlier and closing 537 later.
Grepping for directives would reproduce that error 157 times in a file nobody
re-reads. Each gate's region is likewise delimited by the matching `#else`/
`#endif` **at its own depth**, not by the next one lexically.

The first version of the report was also unusable for the opposite reason: it
extracted every identifier and produced 83 "unresolved" names for one gate,
mostly comment prose and C keywords. **A findings list nobody can act on fails
the same way a noise bucket does.** Narrowed to calls and address-of, after
stripping comments.
