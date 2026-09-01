# AdAttributionKit (Linux starting point)

This directory is a clean-room Linux port of the public Swift `AdAttributionKit`
surface taken from the Xcode 26.1 iPhoneOS SDK seed. It is not wired into a
shared guest package; that integration is a later central-review step. A
successful isolated `test_host.sh` run is not integrated guest-Foundation
success.

## What is real

- `AdAttributionKitError` cases, equality, and hashing. `description` is a
  Linux case-name string, not Apple copy.
- `CoarseConversionValue` cases `low` / `medium` / `high` as a `String` raw
  representable, `Hashable`, and `Codable` value. Raw literals are Swift case
  names from the public graph, not observed Apple ABI strings.
- `PostbackUpdate` and `PostbackUpdate.ConversionType` (`install`,
  `reengagement`) including both documented initializers.
- `Postback.isSupported` is `false` on Linux.
- `Postback.reengagementOpenURLParameter` is the documented query key
  `AdAttributionKitReengagementOpen`.
- `AppImpression.isSupported` is `false`.
- `AppImpression.init(compactJWS:)` classifies malformed compact JWS values
  (`invalidImpressionJWSComponents` / `Header` / `Payload` / `Signature`) and
  **rejects every structurally valid JWS** with `invalidImpressionJWSSignature`.
  It never returns an instance after parsing base64url JSON. Linux has no
  trusted ad-network key source and does not implement ES256 verification.

## Fail-closed boundaries

- No view-through or click-through recording, no reengagement URL open, no
  conversion-value postback.
- `Postback.updateConversionValue` throws `unknown`. Tagged updates throw
  `conversionTagNotSupported`.
- StoreKit extensions (`SKOverlay.AppConfiguration`,
  `SKStoreProductViewController.loadProduct`) are unavailable: this leaf
  depends only on Foundation.
- Instance properties, `Hashable` comparison, and `beginView` / `endView` /
  `handleTap` on `AppImpression` compile but are unreachable without a verified
  object.

## Still deferred / not in this public graph

Developer Mode, Token Handoff, Purchase Intake, Impression Intake, and Billing
Event TBD exports are not public precise identifiers in
`reference/public-surface.tsv`.

Open behavioral questions are in `oracle-questions.tsv`.

## Gate and future EC2 probe

`bash tests/acceptance/test_host.sh` must print `FRAMEWORK_FANOUT_REFERENCE_OK`,
`ADATTRIBUTIONKIT_AGENT_RUNTIME_OK`, and
`FRAMEWORK_FANOUT_HOST_OK module=AdAttributionKit dylib=libAdAttributionKit.dylib`.

`tests/agent/AdAttributionKitDependencyIdentity.swift` is prepared for a future
clean EC2 run that builds guest Foundation first, compiles AdAttributionKit
against those `-I`/`-L` paths, links a client importing both modules, runs
with `LD_LIBRARY_PATH`, and confirms `libAdAttributionKit.dylib` was loaded.
That probe is not executed by the isolated host gate.
