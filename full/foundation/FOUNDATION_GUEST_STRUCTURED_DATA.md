# Foundation guest structured data, errors, and regex

This production slice extends the standalone app-facing `Foundation` module
with four corpus-shaped families. It is framework code shared by applications;
no application source or schema is embedded in it.

## Production surface

- `NSNumber.swift` provides one Objective-C-runtime `NSObject` identity,
  Boolean/signed/unsigned/floating/Decimal storage, Apple-measured scalar
  conversion and comparison behavior, and Swift `_ObjectiveCBridgeable`
  conformances for Bool, every fixed-width integer, Int/UInt, Float, and
  Double. This is the reference value used by JSON graphs and generated
  Intents properties.
- `NSError.swift` provides domain/code/userInfo storage, localized metadata,
  underlying errors, `CustomNSError`, `RecoverableError`, `NSNull`, and the
  compiler-known `_convertErrorToNSError`/`_convertNSErrorToError` entry points.
  An NSError carried through `any Error` preserves its object identity.
- `JSONSerialization.swift` decodes and encodes heterogeneous Swift graphs
  through the pinned FoundationEssentials JSON engine. Numbers and Booleans
  are returned as the shared `NSNumber` reference type; null is `NSNull`.
  Reading and writing fragments, sorted/pretty output, slash escaping, graph
  validation, non-finite rejection, and Cocoa-domain error propagation are
  implemented. The two mutable reading flags produce ordinary Swift arrays
  and dictionaries, which are mutable value containers after a `var` cast;
  Objective-C `NSMutableArray`/`NSMutableDictionary` reference identity is not
  claimed by this slice.
- `NSRegularExpression.swift` and `NSTextCheckingResult` provide UTF-16
  `NSRange` boundaries, numbered and named captures, matching/count/first/range
  queries, enumeration with stop/completion behavior, template replacement,
  escaping, and zero-width matches using Swift's first-party
  `_StringProcessing` engine. The corpus-used initializer modes
  case-insensitive, comments/whitespace, literal metacharacters, dot-all, and
  multiline anchors are implemented. `useUnixLineSeparators`,
  `useUnicodeWordBoundaries`, and unknown option bits throw Cocoa error 2048;
  they are never accepted as no-ops.

The ordered production manifest is
`full/foundation/foundation_guest_sources.txt`. Its 16 entries place the shared
OpenUIKit value aliases before these concrete types and are consumed by both
the Focus onboarding builder and the reusable core package builder.

## Differential and adversarial evidence

`tests/FoundationGuestStructuredDataOracle.swift` is compiled once against
Apple Foundation and once against a fresh literal module named `Foundation`
that uses a newly rebuilt, pinned 202-source FoundationEssentials. The 77-line
outputs are byte-identical to
`tests/foundation-guest-structured-data-apple-2026-08-30.txt`, SHA-256
`5ceca8b4b92d4fe59ecee2751bb0996cc20b453309f6a9d75105e7517ac8d46e`.
It covers numeric width/sign truncation and Swift bridges, JSON option/error
behavior, NSError localization/custom/recovery/identity behavior, Unicode
capture ranges, named captures, replacement, enumeration stop, and zero-width
matching. A portable-only negative executable proves that three unsupported
regex modes and non-finite JSON data refuse rather than report success.

The fresh host gate ends with:

```text
FOUNDATION_GUEST_TEXT_HOST_OK rows=86 characters=26 runtime=2 identity=8 structured=77 structured-negatives=4 uikit-reexport=1 adversarial=4
```

The same freshly built facade object's names-only undefined inventory is
19 `_StringProcessing`, two `Synchronization`, and zero `_RegexParser`
records. `_RegexParser` therefore remains a transitive dependency of the
shipped `_StringProcessing` runtime rather than a direct Foundation link.

This host evidence proves behavior and public symbols without loading Apple
Foundation/CoreFoundation in portable binaries. It does not by itself prove
the Linux-built ARM64 `libFoundation.dylib`; the serialized core-package guest
gate remains mandatory before that binary/runtime claim is made.

## Corpus scope and next boundary

The measured 20-app source corpus uses JSONSerialization in 19 applications,
NSError in 19, NSRegularExpression in 18, and NSTextCheckingResult in 10.
Focus is pinned at commit `a2832521c1daa0c23419c73705ae043ed60c9791`,
tree `065d8e374c9caa3be2915165ba7cbbe4b1d61d7e`; its exact 129-source main
manifest has digest
`8327bf020dc5171167d687a6bf3f107ec2b123f5dc3658236ddbfea894b8123a`.
Within that exact subject, JSONSerialization occurs three times in three
files, NSRegularExpression 12 times in three files, NSTextCheckingResult once,
NSError ten times in four files, and NSNumber four times in four files.

The current exact host census has 218 primary diagnostics after the separately
attributed UIKit launch-core removal of 68. It intentionally imports native
Apple Foundation, so those 218 rows are a UIKit/adjunct wall and cannot be
misreported as this facade's compile delta. The source-site inventory and
fresh literal-module compile/oracle prove this batch now; an exact guest-module
Focus delta remains part of the serialized ARM64 core-package replay.

This slice does not implement archives/coders, networking, data detectors,
ICU's complete regex option matrix, Objective-C mutable collection identity,
or `NSString`. The immediate Foundation successor needs real `NSString`
identity/value bridging because Apple-generated dynamic String Intents expose
`INObjectCollection<NSString>`; no placeholder alias is supplied here.
