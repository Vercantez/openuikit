# Model-layer API census

`~/uikit/Tools/apicensus` measures what UIKit real apps use. It **cannot see
the model layer**, by construction: its `SYMBOL_RE` is
`\b((?:UI|NS|CA)[A-Z][A-Za-z0-9_]*)\b`, filtered against UIKit SDK headers, so
`URLSession`, `JSONDecoder`, `Date`, `Data`, `FileManager`, `Codable` and
`UserDefaults` are invisible — they neither start with UI/NS/CA nor appear in
UIKit's headers. That census measured the presentation half and says nothing
about the other one.

This is the same corpus and the same weighting, with Foundation's alphabet.

    ./model_census.py <corpus-dir> <macos-sdk-path> out.json

Corpus (not vendored — four large third-party repos, shallow-cloned):

    artsy/eidolon  duckduckgo/iOS  kickstarter/ios-oss  Automattic/pocket-casts-ios

## The alphabet is deliberately narrow

Foundation's ObjC `@interface`/`@protocol` names from the SDK headers (all
NS*-prefixed, so unambiguous) **plus** the curated Swift value types listed in
`FAMILIES`.

Scraping Foundation's `.swiftinterface` for `public struct X` was tried and
**rejected after measuring**: it sweeps in every nested and generic type name
Foundation happens to declare — `Message`, `Category`, `Field`, `Language`,
`Currency`, `Style`, `Value`, `Code`, `Encoding` — which then match
**app-defined types of the same name**. It inflated "nothing at all" by ~2,900
uses, almost all of them app types being reported as Foundation gaps. A wider
alphabet looked like a more thorough census and was a less accurate one.

## Known imprecision, stated rather than discovered later

Identifier matching cannot distinguish `Foundation.Data` from an app's own
`Data`. The NS*-prefixed names are safe; the curated Swift names are common
words and will over-count somewhat. The families and the ranking are robust to
this; individual counts should be read as "order of magnitude", not exact.

Corpus drift: these are HEAD shallow clones, so file counts differ slightly
from `Tools/apicensus/census-2026-08-25.json` (eidolon 159 = 159 exactly;
pocket-casts-ios 1826 vs 1690). Same repos, later commits.

---

# SwiftUI / Combine scope census (#57)

    ./swiftui_census.py <corpus-dir> out.json

Same corpus. **Deliberately produces no API-use count** — read the module
docstring in `swiftui_census.py` for why, before adding one.

The short version: SwiftUI's type names (`Text`, `Image`, `List`, `Group`,
`Section`, `Path`, `State`, `Binding`, `Color`) collide with app-defined types
far worse than Foundation's did; most of the API is **modifiers**, which are
method calls on opaque types that apps define freely — measured, the first
non-test SwiftUI view in this corpus contains exactly one modifier call and it
is app-defined; and the remainder is syntax (`some View`, result builders),
which is not an identifier at all.

So it counts only the unambiguous: `import` lines, `@`-prefixed attributes
(the sigil plus an exact name makes them SwiftUI's or Combine's and nobody
else's), `: View` / `some View` syntax, and the few Combine type names nobody
reuses.

## The number this CANNOT give you, and what would

`APP_COMPAT.md`'s decisive finding was not that UIKit has 737 types — it was
that apps reference only **~171** of them, which is what made the punch list
finite. **The SwiftUI equivalent is unmeasurable by text**, for the collision
reasons above. Obtaining it needs a **semantic index**: build the corpus and
read the compiler's index store, or use swift-syntax with type resolution.
Until someone does that, "how much of SwiftUI do apps actually use" is unknown,
and it is the single number that would most change any estimate.

---

# Date-formatting / ICU demand (`date-icu-demand-2026-08-27.json`)

Harvested while the corpus existed, because it sizes the ICU question (#48)
from the DEMAND side rather than from ICU's own symbol gaps.

**Precise, because the property name disambiguates:** `.dateFormat = "…"` is
DateFormatter's and nobody else's.

    11 distinct format patterns across only 18 assignments
       yyyy-MM-dd (5), yyyy-MM-dd HH:mm:ss (3), yyyyMMddHHmmss (2), …
     5 distinct setLocalizedDateFormatFromTemplate templates
    24 distinct Locale identifiers: en 20, de 11, es 9, en_US 9, fr 9, ja 8,
       en_US_POSIX 7, en_GB 3 — a long tail, but six dominate
       dateStyle/timeStyle: .medium 4, .short 4, .long 3, .none 3

**WHAT THIS DOES NOT SAY, and the number is small enough that the distinction
matters.** 18 assignments is the count of ONE IDIOM, not of date-formatting
demand. It misses formatters configured indirectly, localization libraries, and
`.formatted()` — the modern `FormatStyle` API, which the member census counts
43 times and which is a *separate* surface with its own ICU dependency. So read
this as "explicit `dateFormat` strings are rare and few", **not** as "ICU demand
is small".

The genuinely ICU-shaped part is not the patterns — it is that
`.short`/`.medium`/`.long` are *locale-dependent by definition*, across 24
locales. A format pattern is a string a portable implementation can interpret;
a *style* requires the locale's own conventions, which is what ICU carries.
