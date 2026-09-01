# Foundation guest services

`foundation_guest_sources.txt` is the single production source manifest for
the app-facing `Foundation` facade. Entries are ordered, repository-relative
regular Swift files. The manifest has no comments, blank lines, probes, tests,
or generated sources. `build_focus_onboarding_guest.sh` rejects any change to
that grammar before compiling it; reusable package builders consume the same
file rather than maintaining a second list.

The facade re-exports FoundationEssentials and therefore uses its `Date`,
`Data`, `URL`, `UUID`, `JSONEncoder`, `JSONDecoder`, `Calendar`, `Locale`,
`TimeZone`, and `IndexPath` identities. It also re-exports OpenCoreGraphics and
the guest `os` module, so a source file importing only Foundation sees the
platform `CGFloat` and `os_unfair_lock` APIs. The thirty-three-source facade adds:

- `CharacterSet`, including Darwin-measured whitespace and URL component sets,
  Unicode-category-backed uppercase, lowercase, letter, alphanumeric, symbol,
  and decimal-digit sets, its mutable bridge, scalar-boundary trimming/search,
  percent coding, legacy String search/replacement/comparison/path/format APIs,
  `Scanner` hexadecimal scanning, and `Error.localizedDescription`. The text
  gate contains 86 Apple differential rows: the original 51 plus a 35-row
  URL/text/format oracle. Named sets intentionally follow the Unicode tables in
  the pinned Swift runtime; this includes newly assigned letters and marks that
  an older Apple SDK's frozen CharacterSet tables may not yet contain.
- Single OpenUIKit identities for attributed strings and paragraph styles,
  `Timer`, `RunLoop`, and `NSUserActivity`. Compile-time metatype assignments
  make a facade lookalike fail at the framework boundary.
- OpenUIKit's filesystem-backed `Bundle` identity extended with XML Info.plist
  metadata, localization discovery and `.strings` lookup, conventional receipt
  URLs, and `NSLocalizedString`. A fresh fixture runs against Apple and the
  portable implementation; a separate adversarial fixture requires an unknown
  XML entity to fail closed in the portable parser.
- Stateful `URLRequest` request metadata and bounded `InputStream` request
  bodies, including case-insensitive HTTP header replacement and lookup.
- A real asynchronous `URLSession` transport with HTTP response metadata,
  guest-owned redirects, cookie domain/path/expiry handling, memory caching,
  custom `URLProtocol` interception, deterministic cancellation/error mapping,
  and a fixed-width Mach-O-to-Linux libcurl boundary. TLS peer/host verification
  remains enabled and request/response sizes are hard bounded.
- A real NSObject-backed `NSURL` reference bridge for `URL`, preserving
  relative/base state, equality, hashing, component access, and two-way Swift
  bridging without an application wrapper.
- A lock-protected, equality-keyed `NSCache` with lookup recency, count and
  cost limits, immediate trimming, strong key/value ownership, a weak
  delegate, and Apple-measured eviction callback ordering. Its full native
  differential is documented in `FOUNDATION_GUEST_CACHE.md`.
- `ByteCountFormatter`, with decimal/file and binary/memory scales, constrained
  unit selection, adaptive or fixed fraction precision, numeric/word zero
  rendering, composable count/unit/actual-byte flags, and signed grouped output.
- `NSLocking` and an NSObject-backed `NSLock` implemented by the guest
  `os_unfair_lock` substrate, including nonblocking acquisition, bounded
  date-based acquisition, names, and throwing `withLock` critical sections.
- A descriptor-backed synchronous `FileHandle` that performs real libSystem
  open/read/write/seek/truncate/fsync/close operations, exposes standard and
  null-device handles, and reports modern throwing write/seek failures instead
  of turning them into successful no-ops.
- `Data.range(of:options:in:)` over the real FoundationEssentials `Data`
  storage, including forward, backward, anchored, and bounded byte searches.
  Empty needles fail to match, consistent with Darwin Foundation.
- The narrow CoreFoundation spellings used by SwiftSoup:
  `CFString`, `CFURL`, and `CFURLCreateWithString`. They bridge directly to the
  FoundationEssentials `String` and `URL` values, preserve valid percent
  escapes, encode CFURL-compatible query brackets, and reject other invalid
  input instead of inventing a URL or loading Apple's CoreFoundation.
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
  processes. `didChangeNotification` uses Apple's exact raw name, is posted
  synchronously with the mutated defaults instance as its object, and covers
  the Apple-measured set/remove/register/persistent/volatile mutation classes.
  The host gate performs the write and cold read in separate processes.
- `NotificationCenter.Publisher` on the same canonical center and notification
  identities exported by OpenUIKit. It conforms directly to OpenCombine's
  `Publisher` protocol, filters posting objects by identity, honors bounded
  demand, serializes concurrent downstream calls while permitting recursive
  posts, and removes its observer immediately on idempotent cancellation.
- `Progress` with Darwin-compatible determinate/indeterminate fraction rules,
  cancellation, pause/resume, completion, and typed key-path observation.
  The same process-local typed observation substrate is available to every
  portable `NSObject` subclass: framework owners bracket real mutations and
  receive synchronous Apple-shaped initial/prior/old/new delivery.
  `NSKeyValueObservation` tokens have identity hashing, weakly attach to the
  observed object, invalidate idempotently, and never depend on an unavailable
  automatic Objective-C KVO runtime.
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
bash full/foundation/tests/test_foundation_progress_host.sh
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
NSGlobalDomain, general NSObject automatic KVO, cross-process Darwin notification delivery,
or Apple binary-plist storage compatibility;
its persistence path and encoding are intentionally project-owned. The public
value behavior exercised here is useful without pretending those system
services exist. `FileHandle` is intentionally synchronous and descriptor
backed; asynchronous readability/writeability handlers and Objective-C
exception behavior remain outside this slice. The lock slice does not yet
claim `NSRecursiveLock`, `NSCondition`, or `NSConditionLock`. The CoreFoundation
surface supports only the nil/default allocator and the URL creation spelling
above; it is not a general CoreFoundation object model.
