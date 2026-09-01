# AppTrackingTransparency

This directory is a fail-closed Linux starting point for Apple's public
`AppTrackingTransparency` module. It reconstructs the Xcode 26.1 iPhoneOS
Swift surface from the sealed symbol graph. It is not wired into the shared
guest package; that integration is a separate central review step.

## What is real

- `ATTrackingManager` is an `open` `NSObject` subclass.
- `ATTrackingManager.AuthorizationStatus` is a `UInt` `RawRepresentable`
  enum with `notDetermined` (0), `restricted` (1), `denied` (2), and
  `authorized` (3).
- Synthesized `Equatable` (`!=`), `Hashable` (`hashValue`, `hash(into:)`),
  and `init?(rawValue:)` behave as ordinary Swift enum witnesses.
- `trackingAuthorizationStatus` and both `requestTrackingAuthorization`
  overloads (completion-handler and async; same precise identifier) compile
  and run on Linux.

## Fail-closed boundary

Linux has no ATT system prompt, no advertising identifier, and no user
consent UI. Tracking is never authorized:

- `trackingAuthorizationStatus` is always `.denied`.
- `requestTrackingAuthorization(completionHandler:)` returns first, then
  delivers `.denied` exactly once on the serial queue
  `org.openuikit.AppTrackingTransparency.authorization-status`. The handler
  is never invoked inline and does not use the main run loop.
- The async overload awaits that same completion-handler path, so it cannot
  double-complete or deadlock on the delivery queue.
- The implementation never returns `.authorized` or `.notDetermined`.
- Missing `NSUserTrackingUsageDescription` does not crash the process.

Private TBD symbols (`ATTrackingEnforcementManager`, version number/string
exports) are not part of the public Swift graph and are not exposed.

## Still deferred / oracle

Whether Linux should report `.denied` versus `.restricted`, Apple's actual
completion-queue identity, and whether a missing usage-description key
should crash are recorded in `oracle-questions.tsv`. Those paths stay
fail-closed until a central Apple-oracle probe observes them.

The isolated host gate compiles `tests/agent/AppTrackingTransparencyRuntime.swift`
only. `tests/agent/AppTrackingTransparencyDependencyIdentity.swift` is a
future clean-EC2 probe: it imports actual Foundation, Dispatch, and
AppTrackingTransparency, checks `NSObject` identity, and exercises
concurrent callback/async delivery. Passing the isolated gate is not
integrated Linux success.

Run `bash tests/acceptance/test_host.sh` from this directory, or
`bash full/apptrackingtransparency/tests/acceptance/test_host.sh` from the
repository root. Keep generated products out of this tree.
