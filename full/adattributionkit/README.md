# AdAttributionKit (Linux starting point)

This directory is a clean-room Linux port of the public Swift `AdAttributionKit`
surface taken from the Xcode 26.1 iPhoneOS SDK seed. It is not wired into a
shared guest package; that integration is a later central-review step.

## What is real

- `AdAttributionKitError` cases, equality, hashing, and `description`.
- `CoarseConversionValue` (`low` / `medium` / `high`) as a `String` raw
  representable, `Hashable`, and `Codable` value. This matches the SKAdNetwork
  coarse-value vocabulary used by corpus apps.
- `PostbackUpdate` and `PostbackUpdate.ConversionType` (`install`,
  `reengagement`) including both documented initializers and defaulted
  coarse/conversion-type arguments.
- `Postback.isSupported` is `false` on Linux.
- `Postback.reengagementOpenURLParameter` is the documented query key
  `AdAttributionKitReengagementOpen`.
- `AppImpression` compact-JWS *claim decoding* for the documented header
  (`alg=ES256`, `kid`) and payload fields (`impression-identifier`,
  `publisher-item-identifier`, `impression-type=app-impression`,
  `ad-network-identifier`, `source-identifier`, `timestamp` in milliseconds
  since 1970, `advertised-item-identifier`, optional
  `eligible-for-re-engagement`). Malformed JWS values throw the matching
  `AdAttributionKitError` cases.

## Fail-closed boundaries

Linux has no Apple attribution service, no attribution view, and no postback
pipeline. The implementation never records a view-through or click-through
impression, never opens a reengagement URL, and never transmits a conversion
value.

- `AppImpression.isSupported` and `Postback.isSupported` are `false`.
- `beginView()`, `endView()`, `handleTap()`, and
  `handleTap(reengagementURL:)` throw `missingAttributionView`.
- `Postback.updateConversionValue` throws `unknown`. Updates that include a
  conversion tag throw `conversionTagNotSupported` instead of inventing tag
  acceptance.
- Compact JWS decoding does **not** verify ES256 signatures against Apple
  ad-network keys. Signature *format* must still be a non-empty base64url
  component; cryptographic success is not claimed.
- StoreKit extensions (`SKOverlay.AppConfiguration` impression properties and
  `SKStoreProductViewController.loadProduct` overloads) are unavailable: this
  leaf depends only on Foundation, and Linux has no StoreKit overlay UI.

## Still deferred / not in this public graph

Developer Mode, Token Handoff, Purchase Intake, Impression Intake, Billing
Event, and related TBD exports are present in the ABI dump but are not public
precise identifiers in `reference/public-surface.tsv`. They are not part of
this starting module.

Open behavioral questions for an Apple-oracle probe are listed in
`oracle-questions.tsv`.

## Gate

`bash tests/acceptance/test_host.sh` (from this directory or via
`bash full/adattributionkit/tests/acceptance/test_host.sh`) must print
`FRAMEWORK_FANOUT_REFERENCE_OK`, `ADATTRIBUTIONKIT_AGENT_RUNTIME_OK`, and
`FRAMEWORK_FANOUT_HOST_OK module=AdAttributionKit dylib=libAdAttributionKit.dylib`.
