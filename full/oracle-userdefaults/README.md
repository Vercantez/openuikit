# UserDefaults — the Darwin behaviour probes (SCOPING stage, #78)

**Status: this is not yet an oracle. It is the instrument that measured what a
`UserDefaults` oracle would have to grade against, and it has already found a
route-deciding divergence.** The scored runner, the corpus rows and the
host/guest scoreboards do not exist yet and must not be reported as if they do.

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
