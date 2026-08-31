# Foundation guest services

`foundation_guest_sources.txt` is the single production source manifest for
the app-facing `Foundation` facade. Entries are ordered, repository-relative
regular Swift files. The manifest has no comments, blank lines, probes, tests,
or generated sources. `build_focus_onboarding_guest.sh` rejects any change to
that grammar before compiling it; reusable package builders consume the same
file rather than maintaining a second list.

The facade re-exports FoundationEssentials and therefore uses its `Date`,
`Data`, `URL`, `UUID`, `JSONEncoder`, `JSONDecoder`, `Calendar`, `Locale`,
`TimeZone`, and `IndexPath` identities. The eighteen-source facade adds:

- `CharacterSet`, including Darwin-measured whitespace and URL component sets,
  its mutable bridge, scalar-boundary trimming/search, percent coding, legacy
  String search/replacement/comparison/path/format APIs, `Scanner` hexadecimal
  scanning, and `Error.localizedDescription`. The text gate contains 86 Apple
  differential rows: the original 51 plus a 35-row URL/text/format oracle.
- Single OpenUIKit identities for attributed strings and paragraph styles,
  `Timer`, `RunLoop`, and `NSUserActivity`. Compile-time metatype assignments
  make a facade lookalike fail at the framework boundary.
- OpenUIKit's filesystem-backed `Bundle` identity extended with XML Info.plist
  metadata, localization discovery and `.strings` lookup, conventional receipt
  URLs, and `NSLocalizedString`. A fresh fixture runs against Apple and the
  portable implementation; a separate adversarial fixture requires an unknown
  XML entity to fail closed in the portable parser.
- Stateful `URLRequest` request metadata used by first-party networking
  boundaries, including case-insensitive HTTP header replacement and lookup.
- `DateFormatter`, backed by FoundationEssentials `Calendar` and `TimeZone`.
  It implements Gregorian `G y Y M L d D E e c H k K h m s S a Z X x z`
  pattern fields, quoted literals, English and French month/weekday names, and
  the five date/time styles. The host gate compares 93 fixed-locale/time-zone
  rows byte-for-byte with Apple Foundation.
- `UserDefaults`, with process-wide registration values, named suites, typed
  getters/setters, volatile domains, nested property-list values, and atomic
  persistence. Publication uses a uniquely named, fsynced same-directory file
  followed by `rename`, avoiding FoundationEssentials' unavailable `mktemp`
  path on the guest. Its storage envelope is JSON under
  `/tmp/open-foundation-userdefaults-<sanitized-domain>.json`; `Data` values
  round-trip unchanged, so Codable application models persist across guest
  processes. The host gate performs the write and cold read in separate
  processes.
- A shared `NSNumber`/`NSError`/`NSNull` value and error bridge,
  `JSONSerialization`, and UTF-16 `NSRegularExpression` surface. Its exact
  behavior and bounded exclusions are documented in
  `FOUNDATION_GUEST_STRUCTURED_DATA.md`.
- A real immutable, NSObject-backed `NSString` reference plus Swift `String`
  bridging, UTF-16 indexing/substrings, comparison/equality/hash, UTF-8, path,
  and NSCopying-style behavior. Its Apple differential and UTF-8-only boundary
  are documented in `FOUNDATION_GUEST_NSSTRING.md`.

## Reproduce the host gates

```bash
PYTHONDONTWRITEBYTECODE=1 \
  python3 full/foundation/tests/test_foundation_guest_services.py
bash full/foundation/tests/test_foundation_guest_services_host.sh
bash full/foundation/tests/test_foundation_guest_text_host.sh
```

## Bounded behavior

This is not yet the complete Apple Foundation framework. The bundle parser
accepts well-formed UTF-8 XML plists, not binary plists, and `.strings` files
are UTF-8 only. The formatting
initializer is exact for Focus's measured string/object placeholders,
positional arguments, percent escapes, and basic integer conversions; it is
not a complete locale-aware printf implementation. `DateFormatter`
does not yet use FoundationInternationalization/ICU, so localized symbol
tables beyond English and French and date parsing are outside this slice.
Unsupported Unicode pattern letters are rendered literally instead of being
silently discarded. `UserDefaults` does not claim `cfprefsd`, managed-domain,
NSGlobalDomain, Objective-C KVO, or Apple binary-plist storage compatibility;
its persistence path and encoding are intentionally project-owned. The public
value behavior exercised here is useful without pretending those system
services exist.
