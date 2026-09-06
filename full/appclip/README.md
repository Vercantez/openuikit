# AppClip (Linux starting point)

This directory is a fail-closed portable `AppClip` module for the OpenUIKit
Linux platform. It reconstructs the public Xcode 26.1 iPhoneOS Swift surface
from the sealed symbol graph. It is not wired into the shared guest package;
that integration is a separate central review step.

Coverage: **28 implemented / 0 declared / 0 deferred / 2 unavailable / 30 total**
(above the leaf-full floor of 24 nondeferred).

Isolated host compilation produces `libAppClip.dylib` with Foundation only.

## What is real

- `APActivationPayloadErrorDomain` is `APActivationPayloadErrorDomain`,
  matching the pinned `dotnet/macios` `[ErrorDomain]` annotation.
- `APActivationPayloadError.Code` raw values are `disallowed = 1` and
  `doesNotMatch = 2` (pinned `dotnet/macios` `[Native]` cases, enum child
  order in the API digester). Unknown raw values return `nil`.
- `APActivationPayloadError` is a `@frozen` `Foundation._BridgedStoredNSError`
  wrapper. Static `disallowed` / `doesNotMatch` shortcuts and `errorDomain`
  match the Clang-importer overlay. Typed construction, `userInfo`, equality,
  hashing, `NSError` bridging, and `~=` matching are exercised.
- `APActivationPayload` is an open `NSObject` subclass. `url` is always
  `nil`. `init(coder:)` fails closed. `copy()` yields another empty payload.

## Fail-closed boundaries

Linux has no App Clip invocation, App Clip Card, location-confirmation
daemon, or App Clip entitlement.

- `confirmAcquired(in:)` is **unavailable**. `CLRegion` is owned by
  CoreLocation, which is not a declared dependency. A module-local lookalike
  is forbidden.
- `NSUserActivity.appClipActivationPayload` is **unavailable**. Toolchain
  Foundation on Linux has no `NSUserActivity`; a module-local lookalike is
  forbidden.
- `APActivationPayload.url` never fabricates an invocation URL.
- `init(coder:)` never decodes an Apple archive; the keyed layout is
  unobserved.
- `localizedDescription` is Foundation's NSError wording, not an Apple copy
  string.

A public `APActivationPayload.init()` exists so a host can hold the empty
state. Apple's class is `DisableDefaultCtor`; this is not an invocation
factory.

## Depth pass 2026-09

Fresh seed: no prior implemented/declared split. After this pass:
**28 implemented / 0 declared / 0 deferred / 2 unavailable**.

Top-5 implemented evidence distribution:

| Citations | Evidence |
| ---: | --- |
| 6 | `AppClipErrorTests.swift#testErrorCodeRawValues` |
| 1 | `AppClipErrorTests.swift#testErrorDomainConstant` |
| 1 | `AppClipErrorTests.swift#testCustomNSErrorDomain` |
| 1 | `AppClipErrorTests.swift#testCustomNSErrorUserInfo` |
| 1 | `AppClipErrorTests.swift#testCustomNSErrorCode` |

`testErrorCodeRawValues` is a table-driven enum-member, static shortcut, and
`init(rawValue:)` value test. Every remaining implemented row cites its own
focused test, well under the 40% bulk-relabel bound.

The sealed host gate was run as `bash full/appclip/tests/acceptance/test_host.sh`.

`swiftc --version` is Swift 6.2.4 targeting `x86_64-unknown-linux-gnu`.
`.cursor/verify-cloud-environment.sh` does not print
`CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean` on this
snapshot (`scratch/ladder-corpus/focus-ios` is missing). That campaign token
is the host-inventory stamp; the sealed framework gate prints the four
framework markers and compiles a clean product tree (`products=clean`).
