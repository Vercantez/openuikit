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
