# ActivityKit

This directory is an isolated Linux starting point for Apple's public
`ActivityKit` module. It reconstructs the Xcode 26.1 iPhoneOS 26.1 public
surface from the pinned symbol graph. It is not wired into the shared guest
package; that integration is a later central-review step.

## What is real

The module publishes the graph's public types:

- `ActivityAttributes` and `Activity<Attributes>`
- `ActivityContent`, `ActivityState`, `ActivityStyle`
- `ActivityAuthorizationInfo` and `ActivityAuthorizationError`
- `ActivityUIDismissalPolicy`, `AlertConfiguration`, `PushType`

Value types construct, compare, and encode as ordinary Swift data.
`ActivityAuthorizationInfo` reports that Live Activities and frequent pushes
are disabled. Its enablement sequences emit `false` once and finish.
`Activity.activities` is empty. Static activity and push-to-start sequences
complete without values. Every `Activity.request` overload throws
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
surface. They are unreachable because `request` never returns an instance.

`AlertConfiguration` uses a module-local `LocalizedStringResource` stand-in
because toolchain Foundation does not publish that type. Guest Foundation
already has a real implementation; integration should switch to it.

`ActivityAuthorizationError.errorDomain` is the Swift-shaped
`ActivityKit.ActivityAuthorizationError`. Numeric `errorCode` values are
Linux-local discriminators, not observed Apple NSError codes.

## Still deferred

SwiftUI / WidgetKit `ActivityConfiguration`, Dynamic Island views, `#Preview`,
and any Apple-service timing, payload limits, and background-start rules stay
out of this starting point. See `oracle-questions.tsv`.
