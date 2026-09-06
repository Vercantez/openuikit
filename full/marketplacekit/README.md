# MarketplaceKit (Linux starting point)

This directory is a fail-closed portable `MarketplaceKit` module for the
OpenUIKit Linux platform, seeded from the Xcode 26.1 iPhoneOS public surface
(207 exact IDs). Isolated host compilation produces `libMarketplaceKit.dylib`
with Foundation only. Linux splits `HTTPURLResponse` into
`FoundationNetworking`; that module is imported as the Foundation overlay
split, not as an extra Apple framework. `ExtensionFoundation.AppExtension`,
UIKit, and LocalAuthentication are not imported: this module does not publish
those foreign types as if they were Darwin's. When UIKit / CoreGraphics /
LocalAuthentication cannot be imported, module-local stand-ins let the
`_MarketplaceKit_UIKit` overlay compile.

Linux has no alternative-distribution install daemon, no Core Technology
Commission token service, no marketplace entitlement, and no age-exception
in-person sheet. Install, update, license-renewal, and transaction-reporting
APIs never report success.

## What is real

- `MarketplaceKitURIScheme` is `marketplace-kit`, matching Apple's documented
  `marketplace-kit://install?...` install-link examples.
- `AppleItemID` and `AppleVersionID` are `UInt64` typealiases.
- `AppVersion` stores item/version IDs; Linux `description` is `itemID:versionID`.
- `AutomaticUpdate` and `AppLibrary.InstallationRequest` store package URL,
  account, verification token, and optional share URL.
- `InstallRequirements` is Codable. Empty (all-nil) requirements are vacuously
  `satisfiedByDevice() == true`. Any `requiredDeviceCapabilities`,
  `minimumSystemVersion`, or `ageRatingRank` fails closed. `expectedInstallSize`
  compares against home-volume free space when Foundation reports it.
- `MarketplaceKitError` has the 23 graph cases (ordered as in the API
  digester) with documentation-derived `description` strings and a Linux
  Codable layout (`linuxCase` plus associated payloads).
- `AppLibrary.ExceptionRequest.Status` raw values follow digester child order:
  `pending = 0`, `approved = 1`, `declined = 2`.
- `ActionButton.ButtonImagePlacement` raw values follow the UIKit overlay
  graph child order: `top = 0`, `leading = 1`, `bottom = 2`, `trailing = 3`.
- `AppDistributor` cases and `TransactionReporting.TokenType` (string raw
  representable, `coreTechnology` payload `coreTechnology` until observed).
- `AppLibrary.current` is a process-local singleton. `installedApps` /
  `installingApps` are mutable in-process sets. `app(forAppleItemID:)` caches
  identity by ID. `isLoading` is always `false`. `maximumAllowedAgeRating` is
  `0`.
- `MarketplaceExtension.requestFailed(with:)` is true for HTTP status `>= 400`.
- Overlay value types: `InstallMetadata`, `InstallConfiguration`,
  `BatchInstallConfiguration`, `MarketplaceDisplayOption` (Codable),
  `InstallConfirmationResult`, `BatchInstallConfirmationResult` (Equatable).
- `ActionButton` stores action, label, image, placement, size, and border
  style on a `UIControl` stand-in without presenting Apple chrome.

## Fail-closed boundaries

- `AppLibrary` install/update APIs throw after URL/token checks:
  non-http(s)/non-`marketplace-kit` schemes → `invalidURL`; empty verification
  token → `missingInstallVerificationToken`; otherwise `unsupportedPlatform`.
- `requestLicenseRenewal` throws `invalidLicense`.
- `presentAgeExceptionApproveInPersonSheet` and `TransactionReporting.token(for:)`
  throw `featureUnavailable`.
- `AppDistributor.current` throws `unsupportedPlatform`.
- `currentAgeExceptionRequests()` returns `[]` (no Apple requests exist).
- `didAuthenticate` is a no-op.
- `MarketplaceAppExtension` / `MarketplaceExtension` do not inherit
  `AppExtension`. `MarketplaceExtensionConfiguration` does not inherit
  `AppExtensionConfiguration`.
- `UIScene.ConnectionOptions.marketplaceDisplayOption` is always `nil`.
- No fabricated Apple service, entitlement, privacy, or UI success.

## Depth pass 2026-09

Implemented **189** of 207 exact IDs (18 `declared` async service methods).
Nondeferred count 207, above the medium-full floor of 104.

Top-5 `implemented` evidence distribution:

1. `testMarketplaceKitErrorCases` — 24 rows (enum table + Codable/localizedDescription)
2. `testActionButtonStoresActionAndStyle` — 16 rows (button style properties)
3. `testExceptionRequestStatusRawValues` — 12 rows (enum table)
4. `testActionButtonImagePlacementRawValues` — 11 rows (enum table)
5. `testInstallMetadataInits` — 9 rows

No non-enum test is cited by more than 16 implemented rows (well under 40%).

## Tests

`tests/agent/MarketplaceKitLoadSmoke.swift` is the schema-v2 load marker.
`tests/agent/*Tests.swift` holds the sealed focused tests.
`tests/agent/MarketplaceKitDependencyIdentity.swift` is prepared for a future
clean EC2 run that builds guest Foundation first.

Run `bash tests/acceptance/test_host.sh` from this directory. Keep generated
products out of the tree.

Environment: `swiftc` reports Swift 6.2.4, target `x86_64-unknown-linux-gnu`.
`.cursor/verify-cloud-environment.sh` did not emit
`CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean` on this
snapshot because `scratch/ladder-corpus/focus-ios` is absent (Cursor Build
`bld-20260906-253cd433-7a30-4d11-aad2-8b209b7b2d21` vs campaign seed
`bld-20260901-d3266600-d87b-438f-94c1-d1aa48036e87`). The sealed gate compiles
with a clean product tree (`products=clean`).
