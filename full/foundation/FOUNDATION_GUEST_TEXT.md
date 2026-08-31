# Foundation guest text/error slice

This directory contains the first dependency-light, production-shaped text and
error surface for the literal `Foundation` module used by Linux-hosted Mach-O
guests. It is a general framework slice, not a Reminder source adaptation.

## Public boundary

The dependency-light production inputs are explicit:

1. `CharacterSet.swift`
   - empty initialization;
   - initialization from the Unicode scalars in any Swift string;
   - scalar membership;
   - Darwin-measured `whitespaces`, `whitespacesAndNewlines`, and URL component
     sets;
   - value set algebra and a mutable bridge used by unchanged URL builders.
2. `String+CharacterSet.swift`
   - scalar-boundary trimming and `rangeOfCharacter`.
3. `String+FoundationCompatibility.swift`
   - literal/case-insensitive/backwards/anchored/regex search, compare, and
     replacement;
   - UTF-8 percent encoding/decoding and encoding-detecting file reads;
   - the measured `String(format:)`, `NSLog`, NSString path, and NSLocale
     compatibility spellings.
4. `Scanner.swift`
   - persistent string/current-index state;
   - optional arbitrary skip set and nonmutating `isAtEnd`;
   - `scanHexInt64`, including `0x`, partial scans, unchanged state on
     failure, and saturating overflow while consuming the complete digit run.
5. `Error+LocalizedDescription.swift`
   - `LocalizedError.errorDescription` and `failureReason` customization;
   - the canonical NSError domain/code/userInfo bridge documented in
     `FOUNDATION_GUEST_STRUCTURED_DATA.md`.
6. `FoundationOpenUIKitValueAliases.swift`
   - the complete `NSRange` arithmetic family (`NSMaxRange`, membership,
     equality, union, and intersection) over the canonical OpenUIKit-owned
     range identity;
   - Foundation's markdown `InlinePresentationIntent` option set and
     `AttributedString` dynamic-member key, which upstream swift-foundation
     intentionally places behind its Apple-only `FOUNDATION_FRAMEWORK` build.

The inline-presentation raw values and `NSInlinePresentationIntent` attribute
name are measured against Apple Foundation. Empty range intersections are
canonicalized to `{0, 0}`, matching Darwin rather than retaining either input
location. This slice supports semantic emphasis, strong emphasis, inline code,
strikethrough, soft and hard line breaks, and inline HTML; it does not claim
Foundation's full markdown parser or `PresentationIntent` block hierarchy.

`Bundle+Localization.swift` is the companion filesystem service documented in
`FOUNDATION_GUEST_SERVICES.md`; OpenUIKit owns its identity. APIs outside these
lists remain absent rather than returning plausible dummy values. In
particular, this does not claim the complete named CharacterSet catalog, all
Scanner operations, locale-sensitive collation, or a complete printf engine.

`String+CharacterSet.swift` derives its boundary-walk algorithm from the pinned
swift-foundation source and retains the upstream Apache 2.0 with Runtime
Library Exception header. The other implementations were written for this
project from measured API behavior.

## Differential evidence

`tests/FoundationGuestTextOracle.swift` and
`tests/FoundationGuestCompatibilityOracle.swift` are each compiled twice:

- against Apple Foundation;
- against a fresh literal module named `Foundation` containing the production
  text files above and a newly built pinned FoundationEssentials.

The checked goldens were recorded on macOS 26.5.2 (25F84), Apple Swift 6.2.1.
Their 86 rows cover:

- all 1,112,064 Unicode scalar code points, yielding the exact 26-member Darwin
  `whitespacesAndNewlines` inventory, including compatibility member U+200B;
- empty/all-boundary/interior/custom/supplementary-scalar trimming and
  membership;
- lower/uppercase hexadecimal, prefixes, invalid leading characters, partial
  results, default/nil/custom skip sets, optional result storage, cursor
  preservation, and UInt64 overflow;
- `LocalizedError` description, failure-reason, and empty-description cases;
- the exact whitespace and six URL-component inventories, mutable bridge,
  valid/malformed percent sequences, search options, regex, replacement,
  comparison, Focus-shaped formatting, and NSString path conveniences.

Both outputs are byte-identical to
`tests/foundation-guest-text-apple-2026-08-30.txt`, SHA-256
`da4a06b171c7474c8f3eec6febec9f217dffe47c28feaa42bb8346ddaab5f980`,
and `tests/foundation-guest-compatibility-apple-2026-08-30.txt`, SHA-256
`07a1d25c7707614ae7cf8b18d847f7da2fd008e4c3879ded01830085985611ac`.
The separate runtime probe exercises the NSError bridge with a plain Swift
error and a real JSON decoding failure; both must remain descriptive and
nonempty.

Run the native gate with clean pinned inputs:

```sh
SF=/path/to/swift-foundation \
SC=/path/to/swift-collections \
bash full/foundation/tests/test_foundation_guest_text_host.sh
```

Every invocation creates a new physical output root and module caches, verifies
the pinned repositories and source digest, rebuilds all 202 FoundationEssentials
files plus the exact collections/C-shim manifests, verifies the Apple and port
oracles, runs text and Bundle/localization behavioral probes, proves eight
OpenUIKit/Foundation service identities, and compiles/runs a client whose only
import is literal `UIKit`. It rejects Apple Foundation/CoreFoundation load
commands on the portable binaries. Its adversarial controls omit Scanner,
remove U+200B, reject an unknown XML entity, and exercise zero-width regex
replacement progress.

The lightweight structural tests are:

```sh
python3 full/foundation/tests/test_foundation_guest_text.py
```

## Integration order

OpenUIKit must continue compiling while the literal Foundation module is
invisible. The production order is:

```text
FoundationEssentials -> OpenUIKit -> Foundation facade -> literal UIKit -> app
```

That keeps OpenUIKit on its canonical FoundationEssentials identities. The
facade can then alias OpenUIKit-owned compatibility identities, and compiling
UIKit last selects its real `@_exported import Foundation` branch so UIKit-only
app files see CharacterSet, Scanner, and the String/Error extensions.

Application diagnostic measurements must be regenerated from fresh products
after composing this facade with the current OpenUIKit commit; older logs and
the host-native Foundation census are not guest-runtime evidence.
