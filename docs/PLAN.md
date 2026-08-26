# PLAN

The decision and its evidence live in `docs/DECISION.md`. This is the build plan
that follows from it.

**Chosen path:** our own Foundation (Objective-C `NS*` clusters + a Swift
overlay) over swift-corelibs-foundation's CoreFoundation with its Objective-C
toll-free-bridging macros restored. Darwin deployment mode. See DECISION §0.

---

## Status

**M0 — scope and prove: DONE (2026-08-26).**
A minimal slice builds as Darwin Mach-O arm64 on Linux and passes two
differential tests byte-for-byte against real macOS 26.5.2 Foundation:

```
pass 2  fail 0  no-oracle 0
```

`"hi" as NSString` → `length=2` and `NSArray(array: [1,2,3])` → `count=3`, under
machorun, matching the macOS oracle. The bridging risk this project was gated on
is retired.

---

## Reproducing M0

```sh
# on the Mac, natively — captures the oracle from Apple's real Foundation
scripts/oracle_macos.sh

# in the container (see scripts/container.sh for the mounts)
scripts/stage_sdk.sh      # Darwin sysroot: 1364 headers, 7 .tbds
scripts/build_slice.sh    # libFoundationSlice.dylib  (Objective-C)
scripts/build_overlay.sh  # libFoundation.dylib       (Swift overlay)
scripts/run_tests.sh      # build tests, run under machorun, diff vs oracle
```

`scripts/run_tests.sh` sets `ulimit -s unlimited`. That is load-bearing, not
hygiene — see DECISION §3.

---

## Milestones

Order is chosen so the riskiest unknowns land early and ICU never blocks
anything.

### M1 — machorun address-space fix *(dependency, not ours)*
Map images below 2^47 so libswiftCore's inlined 47-bit `ISA_MASK` decodes class
pointers correctly, instead of relying on `ulimit -s unlimited`. DECISION §3.
**Do this first**: it is small, it is upstream, and it exposes every Swift object
path, not just Foundation's.

### M2 — CoreFoundation as Darwin Mach-O
corelibs' 88 `.c` files / 98K lines, cross-built `arm64-apple-macos`. Restore the
five stubbed ObjC dispatch macros (`CF_IS_OBJC`, `CF_OBJC_FUNCDISPATCHV`,
`CF_OBJC_RETAINED_FUNCDISPATCHV`, `CF_OBJC_CALLV`, `CFTYPE_OBJC_FUNCDISPATCH0/1`)
and wire `_CFRuntimeBridgeClasses` for each bridged class. The 294 call sites are
already there and waiting. Exit: `CFStringGetTypeID()`, `CFGetTypeID()`,
`CFStringHashNSString()`, `CFStringHashCString()` exported from a real CF, with
the slice's hand-written versions deleted and the tests still passing.

### M3 — value and collection classes over CF
NSString, NSArray, NSMutableArray, NSDictionary, NSSet, NSEnumerator, NSNumber,
NSData, NSDate, NSValue, NSNull, NSError — re-based onto CF storage, keeping the
ivar-less cluster shape (DECISION §1.2). The slice is the template and its tests
are the regression net.

### M4 — the bridging layer, properly
All the `_ObjectiveCBridgeable` conformances; `__SwiftValue` boxing; NSError↔Error;
**lazy** NSString→String (the slice copies eagerly — DECISION §9.2); an apinotes
file rather than scattered `swift_bridge` attributes (DECISION §2.1c). Grow the
differential suite alongside; every conformance gets an oracle-diffed case.

### M5 — OS-facing classes
Census order (DECISION §7): IndexPath, URL, Data, JSONSerialization, FileManager,
Bundle first; then Timer, RunLoop, Notification/NotificationCenter; then Process,
Pipe, Thread, Operation/OperationQueue, UserDefaults. RunLoop and Process touch
machorun's syscall surface and should get slack.

### M6 — formatters and ICU *(deferred, off the critical path)*
DateFormatter, NumberFormatter, Locale, Calendar, CharacterSet, collation. 21 CF
files touch ICU. The app census shows 2 uses each of Locale/DateFormatter/Calendar
across `~/uikit`, so this waits until M2–M5 are real.

---

## Method

Unchanged from what worked in `~/machorun` and `~/swiftcore-macho`:

- **Differential against macOS, always.** Baselines come from a native macOS run
  (`scripts/oracle_macos.sh`) and never from the Linux side. A baseline captured
  from the thing under test proves nothing.
- **Honest walls are results.** Each of the four walls in DECISION §2.1 is worth
  more than a page of speculation; record them with the measurement that found
  them.
- **Read the disassembly.** Every important fact in DECISION §1 came from
  `otool`/`nm` on libswiftCore, not from documentation or memory. The contract is
  not written down anywhere else.
- **Scope locally, build big.** Docker on the Apple-silicon host, arm64-native,
  is enough for everything except full rebuilds (DECISION §8).
