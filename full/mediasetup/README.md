# MediaSetup

Linux starting point for Apple's public `MediaSetup` module, reconstructed
from the pinned Xcode 26.1 iPhoneOS 26.1 symbol graph. Isolated host-gate
success is not integrated Darwin HomePod / Apple TV media-service setup.

## Depth pass 2026-09

This is a fresh seed: **17 exact public identifiers**, floor 14 nondeferred
(`ceil(80% of 17)`). Every identifier is `implemented` with a focused
top-level synchronous `func test*()`. There are no enum, option-set, or
`k…`/`err…` members, so no table-driven value sharing.

Coverage after this pass: **17 implemented / 0 declared / 0 deferred /
0 unavailable / 0 not-applicable**.

Top-5 implemented evidence distribution (17 implemented rows; no test
exceeds 40%):

| rows | share | evidence |
| ---: | ---: | --- |
| 1 | 5.9% | `MSPresentationAnchorTests.swift#testPresentationAnchorTypealias` |
| 1 | 5.9% | `MSServiceAccountTests.swift#testServiceAccountIsNSObjectSubclass` |
| 1 | 5.9% | `MSServiceAccountTests.swift#testServiceAccountInitStoresNames` |
| 1 | 5.9% | `MSServiceAccountTests.swift#testServiceAccountAccountNameReadonly` |
| 1 | 5.9% | `MSServiceAccountTests.swift#testServiceAccountAuthorizationScopeRoundTrip` |

The remaining twelve implemented rows each have their own test (client
secret / URLs / service name, session class / init / start / account /
weak context, presentation-context protocol and `presentationAnchor()`).

Environment: `swiftc` reports Swift 6.2.4, target `x86_64-unknown-linux-gnu`.
`.cursor/verify-cloud-environment.sh` did not emit
`CURSOR_SWIFT_ENVIRONMENT_OK` because `scratch/ladder-corpus/focus-ios` is
absent on this VM. The sealed gate compiles with a clean product tree
(`products=clean`). Active Cursor Build observed on this run was
`bld-20260906-253cd433-7a30-4d11-aad2-8b209b7b2d21` (campaign expected
`bld-20260901-d3266600-d87b-438f-94c1-d1aa48036e87`). Starting commit
`342dd2ee859ac3c9369653620a0b8835883008ad` matched.

The campaign inventory stamp
`CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean`
is a host-inventory token, not printed by the sealed framework gate.

## What is real

- `MSServiceAccount` is an `NSObject` subclass. Designated
  `init(serviceName:accountName:)` stores both readonly strings as given
  (including empty and whitespace). Optional `clientID`, `clientSecret`,
  `configurationURL`, `authorizationTokenURL`, and `authorizationScope`
  start `nil` and round-trip get/set. URL fields are Swift `URL` values.
- `MSSetupSession` retains the `MSServiceAccount` by object identity.
  `presentationContext` is weak and defaults to `nil`.
- `MSAuthenticationPresentationContext` is an `NSObjectProtocol` with
  `func presentationAnchor() -> MSPresentationAnchor?` (Apple graph form).
- Isolated-host `MSPresentationAnchor` is `NSObject`. When UIKit is
  importable, it is `UIWindow`. No public `UIWindow` lookalike is declared.

## Fail-closed boundaries

- `MSSetupSession.start()` always throws `NSError` domain
  `MediaSetup.linux.unavailable` code `1`, with or without a presentation
  context. Linux never presents an authentication sheet and never talks to
  an Apple media-setup daemon.
- Assigning `presentationContext` does not present UI.
- Returning a presentation anchor does not make `start()` succeed.

## Still deferred / unobserved

See `oracle-questions.tsv` for Darwin `start()` NSError domain/code, whether
a presentation context is required, the graph-vs-macios `presentationAnchor`
method/property conflict, designated-init optional defaults, and hidden TBD
CloudKit helpers that are not public Swift-surface identifiers.

Focused checks live in `tests/agent/*Tests.swift` as top-level `func test*()`.
The sealed gate prints `MEDIASETUP_AGENT_RUNTIME_OK` after calling each
cited test once.

```
CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean
FRAMEWORK_FANOUT_DELIVERABLE_OK module=MediaSetup lane=leaf-full symbols=17
FRAMEWORK_FANOUT_REFERENCE_OK
MEDIASETUP_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=MediaSetup dylib=libMediaSetup.dylib
```

Run `bash full/mediasetup/tests/acceptance/test_host.sh` from the repo root.
Keep generated products out of the tree.
