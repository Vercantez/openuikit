# ActivityKit

This directory is an isolated Linux starting point for Apple's public
`ActivityKit` module. It reconstructs the Xcode 26.1 iPhoneOS 26.1 public
surface from the pinned symbol graph. It is not wired into the shared guest
package; that integration is a later central-review step.

The isolated host gate compiles only against toolchain Foundation. Passing
`test_host.sh` is not integrated Linux success and does not load guest
Foundation, SwiftUI, or WidgetKit.

## What is real

The isolated module publishes the graph types that do not require guest
Foundation:

- `ActivityAttributes` and `Activity<Attributes>`
- `ActivityContent`, `ActivityState`, `ActivityStyle`
- `ActivityAuthorizationInfo` and `ActivityAuthorizationError`
- `ActivityUIDismissalPolicy`, `PushType`

Value types construct, compare, and encode as ordinary Swift data.
`ActivityAuthorizationInfo` reports that Live Activities and frequent pushes
are disabled. Its enablement sequences emit `false` once and finish.
`Activity.activities` is empty. Static activity and push-to-start sequences
complete without values. Every isolated `Activity.request` overload throws
`ActivityAuthorizationError.unsupported`.

## Fail-closed boundaries

Linux has no Live Activity daemon, Dynamic Island / Lock Screen presentation,
ActivityKit push token service, broadcast channel, or
`NSSupportsLiveActivities` entitlement check. This port does not fabricate:

- a started Live Activity
- a push-to-start or per-activity push token
- Settings authorization becoming `true`
- UI dismissal, alerts, or WidgetKit / SwiftUI presentation

`Activity.update` and `Activity.end` exist so the class matches the public
surface that can compile without guest Foundation. They are unreachable
because `request` never returns an instance.

`AlertConfiguration` is omitted from the isolated compile. Its public IDs
require `Foundation.LocalizedStringResource`. ActivityKit does not ship a
same-named fallback. A future EC2 guest build must pass `-D OPENUIKIT_GUEST`
and link real guest Foundation so title and body are
`Foundation.LocalizedStringResource`. Prove that with
`tests/agent/ActivityKitDependencyIdentity.swift`.

`ActivityAuthorizationError.errorDomain` is the Swift-shaped
`ActivityKit.ActivityAuthorizationError`. Numeric `errorCode` values are
Linux-local discriminators, not observed Apple NSError codes.

## Still deferred

`AlertConfiguration` (including `AlertSound` and the request/update overloads
that take it) stays deferred until the guest Foundation identity probe runs.
SwiftUI / WidgetKit `ActivityConfiguration`, Dynamic Island views, `#Preview`,
and Apple-service timing remain out of this starting point. See
`oracle-questions.tsv`.
