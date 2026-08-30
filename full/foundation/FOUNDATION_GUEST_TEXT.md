# Foundation guest text/error slice

This directory contains the first dependency-light, production-shaped text and
error surface for the literal `Foundation` module used by Linux-hosted Mach-O
guests. It is a general framework slice, not a Reminder source adaptation.

## Public boundary

The four production inputs are explicit:

1. `CharacterSet.swift`
   - empty initialization;
   - initialization from the Unicode scalars in any Swift string;
   - scalar membership;
   - `whitespacesAndNewlines`.
2. `String+CharacterSet.swift`
   - scalar-boundary `trimmingCharacters(in:)`.
3. `Scanner.swift`
   - persistent string/current-index state;
   - optional arbitrary skip set and nonmutating `isAtEnd`;
   - `scanHexInt64`, including `0x`, partial scans, unchanged state on
     failure, and saturating overflow while consuming the complete digit run.
4. `Error+LocalizedDescription.swift`
   - `LocalizedError.errorDescription` and `failureReason` customization;
   - a stable descriptive Swift fallback while the NSError domain/code bridge
     remains unavailable.

APIs outside that list remain absent rather than returning plausible dummy
values. In particular, this does not claim the complete named CharacterSet
catalog, all Scanner operations, or NSError-compatible localization.

`String+CharacterSet.swift` derives its boundary-walk algorithm from the pinned
swift-foundation source and retains the upstream Apache 2.0 with Runtime
Library Exception header. The other implementations were written for this
project from measured API behavior.

## Differential evidence

`tests/FoundationGuestTextOracle.swift` is compiled twice:

- against Apple Foundation;
- against a fresh literal module named `Foundation` containing the four files
  above and a newly built pinned FoundationEssentials.

The checked golden was recorded on macOS 26.5.2 (25F84), Apple Swift 6.2.1. Its
51 rows cover:

- all 1,112,064 Unicode scalar code points, yielding the exact 26-member Darwin
  `whitespacesAndNewlines` inventory, including compatibility member U+200B;
- empty/all-boundary/interior/custom/supplementary-scalar trimming and
  membership;
- lower/uppercase hexadecimal, prefixes, invalid leading characters, partial
  results, default/nil/custom skip sets, optional result storage, cursor
  preservation, and UInt64 overflow;
- `LocalizedError` description, failure-reason, and empty-description cases.

Both outputs are byte-identical to
`tests/foundation-guest-text-apple-2026-08-30.txt`, SHA-256
`da4a06b171c7474c8f3eec6febec9f217dffe47c28feaa42bb8346ddaab5f980`.
The separate runtime probe exercises the intentionally non-Apple NSError
fallback with a plain Swift error and a real JSON decoding failure; both must
remain descriptive and nonempty.

Run the native gate with clean pinned inputs:

```sh
SF=/path/to/swift-foundation \
SC=/path/to/swift-collections \
bash full/foundation/tests/test_foundation_guest_text_host.sh
```

Every invocation creates a new physical output root and module caches, verifies
the pinned repositories and source digest, rebuilds all 202 FoundationEssentials
files plus the exact collections/C-shim manifests, verifies the Apple and port
oracles, runs the behavioral probe, and compiles/runs a client whose only import
is literal `UIKit`. It rejects Apple Foundation/CoreFoundation load commands on
the portable binaries. Its two adversarial controls omit Scanner from the
facade and remove U+200B from CharacterSet; both must be detected.

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

The Reminder measurement must be regenerated after composing this slice with
the Notification alias candidate and UIKit commit
`83fbcbe2204eb836968d4e73ecfecec7b20c68ef`; older diagnostic artifacts are not
evidence for the current graph.
