# UserDefaults — the differential oracle (#78)

**Status: host route DONE. Guest route BLOCKED on two named substrate walls,
neither of them in UserDefaults.**

```
CONTROL-SELF  462/462   real vs real — the instrument check
CORELIBS      245/313   upstream's own rules vs real; 68 failures, and this
                        board MUST fail or the oracle detects nothing
PORT          627/627   ours vs real, including every row CORELIBS fails
CROSS-READ     26/26    the port writes, real Foundation reads
PERSIST       113/113   a FRESH PROCESS re-reads what the port wrote
```

Build and run: `build_ud_host.sh OUT && OUT/ud_runner score`. The other
direction — proof the PORT board can fail — is `mutation_test.sh`: removing any
one deviation from upstream drops it (32 / 4 / 16 / 1 failures).

The port is `~/foundation-macho/src/overlay/UserDefaults.swift`, ONE file in
two configurations: `-DUD_HOST_ORACLE` builds it as module `PortedUserDefaults`
so it coexists with real `Foundation.UserDefaults` in one process; undefined, it
is the Foundation overlay over our own CF.

**The guest route is blocked BELOW UserDefaults, not by it.** CF's preferences
path ran for the first time and stops on (1) `CFLock_t` being an ERRORCHECK
pthread mutex whose signature machorun does not accept, and (2) an
unimplemented `-[__NSCFConstantString _fastCStringContents:]` on the CFBundle
path. Both are reproduced by probes smaller than the thing they explain, in
`~/foundation-macho/docs/CF_PREFERENCES_EXECUTION.md`.

Everything below is the scoping measurement that produced the corrections the
port carries. It is kept because those corrections cite it by row.

## Why a probe before a route

For a Darwin API the oracle is **what Darwin does**, not what a document says
and not what the open-source implementation does. swift-corelibs-foundation's
`UserDefaults.swift` is the only upstream implementation of this class — but
corelibs is what runs on *Linux*, where nothing compares it to Apple's. So its
behaviour is unverified against the thing we have to match, and a port of it
would inherit whatever it gets wrong, invisibly, because **ported code looks
correct because it IS the correct code** (`false-green-verification-pattern`).

Running the probes answered that. See `../census/` for the demand side.

## The files

| file | what it measures |
|---|---|
| `darwin_probe_behaviour.swift` | type round-trips, the coercion grid, absent-key answers, `set(URL)` storage form, `register(defaults:)` layering, `removeObject` fallback, suite isolation, the on-disk format and path. Three phases; **phase 2 is a separate process**, which is the only honest persistence test. |
| `darwin_probe_coercion.swift` | the string→`integer`/`double`/`bool` rules, printed **beside** the `NSString.integerValue`/`.boolValue` answers corelibs uses, so a divergence is a diff and not a claim |
| `darwin_probe_domains.swift` | what `dictionaryRepresentation()` actually contains versus `persistentDomain(forName:)`, and the volatile-domain names |
| `darwin_probe_notifications.swift` | exact `didChangeNotification` name, synchronous sender identity, and the mutation APIs that do and do not post |

Captured output is committed beside each (`darwin-*-2026-08-27.txt`) with the
host OS, build and toolchain in the header, because a behavioural answer
without its configuration is not a measurement.

Every probe writes only into a throwaway suite and removes its persistent
domain afterwards, so the user's own defaults are never touched.

## The headline the probes found

**19 of 42 measured string rows: real `UserDefaults` disagrees with the
`NSString` conversions corelibs' `UserDefaults` is built on.**

- `integer(forKey:)` on a String is a *strict whole-string integer parse* —
  `"3.75"` → `0` (not 3), `"1.0"` → `0`, `"123 "` → `0` (trailing space), and
  it **clamps to Int32**: `"9223372036854775807"` → `2147483647`. corelibs
  calls `NSString.integerValue`, which answers 3, 1, 123 and the full Int64.
- `bool(forKey:)` on a String accepts `YES/Yes/yes/TRUE/True/true` and exactly
  `"1"`, and rejects `"Y"`, `"T"`, `"2"`, `"-1"`, `"123"`. corelibs calls
  `NSString.boolValue`, which says true for all of those.
- On *numbers* the rule is ordinary numeric truth (`2`, `-1`, `0.4` are all
  `true`), and there both agree.

Two more, from the behaviour probe:

- `set(_ url: URL?)` stores a **file** URL as a bare path string and a
  **non-file** URL as archived `Data` (263 bytes of `bplist00`). corelibs
  stores `url.path` for anything that is not a file *reference* URL — so
  `https://example.com/a?b=c` would be stored as `"/a"` and read back as
  `file:///a`.
- `dictionaryRepresentation()` returns the whole **search list** (suite +
  `NSGlobalDomain` + registration + argument), not the suite: 81 keys against
  `persistentDomain(forName:)`'s 2 on the same instance.

## Reading these numbers safely

- The `NSGlobalDomain` counts are **this machine's** and will differ on any
  other Mac. What is load-bearing is the *composition*, never the count.
- Phase 1 reported the on-disk file as 61 bytes while the domain held 30 keys.
  That is not a contradiction: on Darwin, writes go through **`cfprefsd`**, and
  the file is not authoritative in real time. Our stack has no `cfprefsd`, so
  persistence there must come from the file — which makes the separate-process
  phase 2 the test that matters, and makes "it read back correctly" in a single
  process worth nothing.
- The dynamic classes differ between phase 1 (in memory: `_NSInlineData`,
  `__NSArrayI`) and phase 2 (from disk: `__NSCFData`, `__NSCFArray`). Per
  `foundation-macho`'s own record, the invariant is **not** any particular
  class. Do not grade on class names.
