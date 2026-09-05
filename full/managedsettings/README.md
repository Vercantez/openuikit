# ManagedSettings (Linux starting point)

This directory is a clean-room Linux starting point for Apple's public
`ManagedSettings` module, seeded from the Xcode 26.1 iPhoneOS 26.1
symbol graph, API digester, TBD exports, and corpus metadata. It is not
wired into the shared guest package; that integration is a later
central-review step.

Linux has no Screen Time / Family Controls authorization, Managed
Settings daemon, or shield-configuration extension host. Writing a
store never becomes an operating-system restriction. Token bytes from
Apple Family Controls are not decoded.

## What is real

- Value types `Application`, `WebDomain`, `ActivityCategory`, and
  opaque `Token<T>` (`ApplicationToken`, `WebDomainToken`,
  `ActivityCategoryToken`). Tokens round-trip a Linux-only keyed
  `linuxOpaqueID` UUID through `JSONEncoder` / `JSONDecoder` and fail
  closed on any other payload.
- Every `ManagedSettingsGroup` settings struct with optional instance
  properties (unset is `nil`) and `SettingMetadata` /
  `BoundedSettingMetadata` statics using documented defaults:
  `false` for deny/lock Booleans, empty sets, `FilterPolicy.none`,
  `CookiePolicy.always`, movie/TV bounds `0...1000` default `1000`,
  App Store rating bounds `0...2000` default `1000`.
- `WebContentSettings.FilterPolicy` and
  `ShieldSettings.ActivityCategoryPolicy` equality, including default
  empty associated sets.
- `SafariSettings.CookiePolicy` as a `String` enum with implicit case
  names, `Comparable` rank `never < currentWebsite < visitedWebsites
  < always`, and `description == rawValue`.
- `ShieldAction` / `ShieldActionResponse` as `Int` enums in
  declaration order (`0/1` and `0/1/2`).
- `ManagedSettingsStore` named in-process bags. Same `Name` shares
  settings; `clearAllSettings()` resets that name. `init()` uses
  `Name.default` (`rawValue` `"default"`, unobserved on Apple).
- `effectiveDenyExplicitContent`, `effectiveMaximumMovieRating`, and
  `effectiveMaximumTVShowRating` report metadata defaults because no
  Family Controls policy is active, even if this process wrote local
  `media.*` values.
- `ShieldActionDelegate` subclasses `NSObject`. Default `handle`
  methods invoke the completion handler synchronously with `.none`.

`tests/agent/ManagedSettingsLoadSmoke.swift` is the schema-v2 import
marker. The sealed gate derives its runner from `implemented` coverage.

## Fail-closed boundaries

- No OS restriction, Safari private-browsing change, shield UI, or
  parental merge is applied.
- `Token.init(from:)` rejects payloads that are not the Linux
  `linuxOpaqueID` keyed container (`DecodingError.dataCorrupted`).
- Shield completions never return `.close` unless a subclass overrides
  (tests cover that override). The default is `.none`.
- Combine `ObservableObject` / `@Published` projected publishers are
  **unavailable**: Combine is not a declared dependency, and a
  framework-local `ObservableObjectPublisher` stand-in is forbidden.
- Settings are process-local. They are not written to disk and do not
  survive process exit.

## Depth pass 2026-09

Fresh seed: no prior implemented/declared split. After this pass:
**195 implemented / 0 declared / 5 unavailable**.

Top-5 implemented evidence distribution:

| Citations | Evidence |
| ---: | --- |
| 8 | `ManagedSettingsEnumTests.swift#testCookiePolicyRawValues` |
| 7 | `ManagedSettingsEnumTests.swift#testShieldActionResponseRawValues` |
| 6 | `ManagedSettingsEnumTests.swift#testFilterPolicyEquality` |
| 6 | `ManagedSettingsEnumTests.swift#testShieldActionRawValues` |
| 5 | `ManagedSettingsEnumTests.swift#testActivityCategoryPolicyEquality` |

`testCookiePolicyRawValues`, `testShieldActionResponseRawValues`, and
`testShieldActionRawValues` are table-driven enum-member value tests.
`testFilterPolicyEquality` and `testActivityCategoryPolicyEquality`
exercise associated-value equality for those enums. Remaining
non-enum tests stay well under the 40% bulk-relabel bound.

The sealed host gate was run as `bash full/managedsettings/tests/acceptance/test_host.sh`
and ended:

```
FRAMEWORK_FANOUT_DELIVERABLE_OK module=ManagedSettings lane=medium-full symbols=200
FRAMEWORK_FANOUT_REFERENCE_OK
MANAGEDSETTINGS_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=ManagedSettings dylib=libManagedSettings.dylib
```

`swiftc --version` is Swift 6.2.4 targeting `x86_64-unknown-linux-gnu`.
`.cursor/verify-cloud-environment.sh` does not print
`CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean`
on this snapshot (`scratch/ladder-corpus/focus-ios` is missing). That
campaign token is the host-inventory stamp; the sealed framework gate
prints the four lines above.
