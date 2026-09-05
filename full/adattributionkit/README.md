# AdAttributionKit

Linux starting point for Apple's public `AdAttributionKit` module, reconstructed
from the pinned Xcode 26.1 iPhoneOS symbol graph, the in-repo fan-out repair
spec, and Apple public documentation. This directory is not wired into the
shared guest package. A passing isolated host gate is not integrated Linux
success.

## What is real

The public Swift surface that does not require StoreKit compiles to
`libAdAttributionKit.dylib`.

- `AdAttributionKitError` cases from the canonical graph are constructible and
  `Hashable` / `Equatable`.
- `CoarseConversionValue` is a `String` enum (`low`, `medium`, `high`) whose
  raw values match Apple's documented postback field
  `"coarse-conversion-value": "low"` (and the sibling medium/high strings).
  `Codable` round-trips those raw values.
- `PostbackUpdate` stores the graph's fields. The conversion-tag initializer
  records the supplied tag; the other initializer leaves `conversionTag == nil`.
  `PostbackUpdate.ConversionType` is `install` / `reengagement`.
- `Postback.reengagementOpenURLParameter` is `AdAttributionKitReengagementOpen`,
  the query parameter name in Apple's "Receiving ad attributions and postbacks"
  documentation.
- `AppImpression.isSupported` and `Postback.isSupported` are `false`.
- `AppImpression.init(compactJWS:)` never succeeds. Compact JWS strings are
  classified structurally, then rejected:
  - not exactly three `.`-separated components → `invalidImpressionJWSComponents`
  - first component is not base64url JSON object → `invalidImpressionJWSHeader`
  - second component is not base64url JSON object → `invalidImpressionJWSPayload`
  - otherwise (including nonempty forged signatures) → `invalidImpressionJWSSignature`
- `Postback.updateConversionValue` overloads throw `AdAttributionKitError.unknown`.
  Linux has no conversion window or postback daemon. Darwin's exact error
  identity for that situation is unobserved.

## Fail-closed boundaries

Linux has no Apple attribution service, trusted ES256 keys, marketplace
product page, or `UIEventAttributionView`.

- A compact JWS that merely parses as JSON with a nonempty signature is **not**
  a verified impression. There is no cryptographic success path.
- Instance properties and view/tap methods on `AppImpression` are unreachable
  because no verified object is produced. If they were invoked they throw
  (`unknown` for begin/end view; `missingAttributionView` for tap).
- StoreKit overlay APIs (`SKOverlay.AppConfiguration`,
  `SKStoreProductViewController`) are not declared. StoreKit is not a declared
  dependency; this module does not invent same-named substitutes.

## Still open

See `oracle-questions.tsv` for Darwin error-string identity, fine-conversion
range, conversion-tag validation, and StoreKit overlay behavior.

`tests/agent/AdAttributionKitRuntime.swift` is the isolated host probe
(`ADATTRIBUTIONKIT_AGENT_RUNTIME_OK`).
`tests/agent/AdAttributionKitDependencyIdentity.swift` is prepared for a future
clean EC2 run that builds guest Foundation first.

Run `bash tests/acceptance/test_host.sh` from this directory. Keep generated
products out of the tree.

## Depth pass 2026-09

Implemented **53 → 55**. Declared 19 → 17. Deferred 4 (StoreKit overlay) unchanged.
Unavailable / not-applicable remain 0.

Corpus ranking used `reference/corpus-summary.json` (ProtonMail
`CoarseValue` / `ConversionTracker`; DuckDuckGo `MarketplaceAdPostback` /
`MarketplaceAdPostbackUpdater`). `scratch/ladder-corpus` was not present in
this environment, so those two apps’ conversion/postback types were raised
first, then the rest of the documented public API. `AppImpression` instance
properties, `Hashable`, and view/tap methods stay **declared**: the only public
construction path still fail-closes, and inventing a verified impression would
violate the earlier repair. `AdAttributionKitError.description` and
`localizedDescription` moved to **implemented** with Linux-local case-name /
Foundation nonempty checks; Darwin copy remains an oracle question.

Top-5 evidence distribution among 55 implemented rows:

| citations | test | family |
| ---: | --- | --- |
| 10 | `AdAttributionKitErrorTests.swift#testErrorCases` | enum members (allowed table-driven) |
| 5 | `AdAttributionKitConversionTests.swift#testPostbackUpdateUntaggedInit` | PostbackUpdate storage |
| 4 | `AdAttributionKitConversionTests.swift#testCoarseConversionValueCases` | enum members (allowed table-driven) |
| 3 | `AdAttributionKitConversionTests.swift#testPostbackUpdateTaggedInit` | tagged PostbackUpdate |
| 3 | `AdAttributionKitConversionTests.swift#testConversionTypeCases` | enum members (allowed table-driven) |

Tied at 3 citations: `testConversionTypeRawValue` and `testCoarseConversionValueRawValue`. No non-enum test cites more than 5 of 55 implemented rows (40% cap is 22).

Focused tests live under `tests/agent/*Tests.swift`. The sealed v1 host gate
still runs `AdAttributionKitRuntime.swift` for `ADATTRIBUTIONKIT_AGENT_RUNTIME_OK`.
