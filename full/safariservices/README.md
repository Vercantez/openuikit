# SafariServices (Linux starting point)

This directory is a fail-closed portable `SafariServices` module for the
OpenUIKit Linux platform. It reconstructs the public Xcode 26.1 iPhoneOS Swift
surface from the sealed symbol graph. It is not wired into the shared guest
package; a passing isolated host gate is not integrated Linux success and is
not Apple Safari behavior.

The lane already had a Foundation/UIKit presentation shell on main
(`SafariServicesPortableError`, `SFContentBlockerState`,
`SFContentBlockerManager`, `SFSafariViewController` plus configuration and
delegate). This wave-5 pass keeps those types, compiles them on the isolated
host with Foundation only, and extends them to the sealed 158-identifier
surface.

## What is real (isolated host: Foundation)

- Error domain globals `SFAuthenticationErrorDomain`, `SFErrorDomain`,
  `SFContentBlockerErrorDomain`, and `SSReadingListErrorDomain` use the
  exported symbol names recorded in `reference/tbd-exports.tsv` and the
  pinned `dotnet/macios` `[ErrorDomain ("...")]` annotations. Localized
  payloads are unobserved.
- `SFExtensionMessageKey` and `SFExtensionProfileKey` use the pinned
  `dotnet/macios` `[Field]` names. Apple's runtime string contents are
  unobserved.
- `SFAuthenticationError`, `SFError`, and `SSReadingListError` are `@frozen`
  `Foundation._BridgedStoredNSError` overlays. Code raw values come from the
  pinned bindings (`canceledLogin = 1`, `SSReadingListError.urlSchemeNotAllowed = 1`,
  `SFError` 1...5, deprecated `SFContentBlockerErrorCode` 1...3). macios also
  lists `ok = 0` and `maximumAttemptsExceeded = 6`; those cases are not in
  the sealed public surface and are not implemented.
- `SFSafariViewController.DismissButtonStyle` is `done = 0`, `close = 1`,
  `cancel = 2` (existing lane values, matching the pinned native enum order).
- `SFContentBlockerManager.getStateOfContentBlocker` and
  `reloadContentBlocker` fail closed with
  `SafariServicesPortableError.contentBlockerServiceUnavailable` on the
  calling thread. The async overlay of `reloadContentBlocker` shares that
  path. Apple's callback queue is unobserved.
- `SFSafariViewController` records the requested URL and a copied
  `Configuration`. It never loads a page. `reportPortableInitialLoadFailure()`
  still reports `didCompleteInitialLoad(false)` to the delegate.
- `SSReadingList.supportsURL` is true only for `http` and `https` (publicly
  documented Safari Reading List schemes). `addItem` throws
  `urlSchemeNotAllowed` for other schemes and
  `SafariServicesPortableError.browserServiceUnavailable` for allowed schemes;
  nothing is persisted.
- `SFAuthenticationSession.start()` returns `false` and does not invoke the
  completion handler (no Safari authentication UI).
- `SFSafariSettings.openExportBrowsingDataSettings` fail-closes with
  `browserServiceUnavailable` on the calling thread.
- `SFSafariViewController.DataStore.clearWebsiteData` is a no-op that still
  invokes its completion on the calling thread (there is no website data).
- `prewarmConnections(to:)` returns a token whose `invalidate()` is local
  only; no sockets are opened.

On Darwin / OpenUIKit, `SFSafariViewController` still subclasses
`UIViewController`, is `@MainActor`, and keeps `preferredBarTintColor` /
`preferredControlTintColor`. On the isolated host it subclasses `NSObject`
and drops `@MainActor` because there is no UI run loop.

## Fail-closed / deferred

Linux has no Safari process, content-blocker extension host, Reading List
daemon, or Settings app. Success is never invented.

Deferred because the signature requires a foreign type the isolated host
cannot import (no public lookalike):

- `preferredBarTintColor` / `preferredControlTintColor` (`UIColor`)
- `SFSafariViewController.ActivityButton` and `Configuration.activityButton`
  (`UIImage`)
- `Configuration.eventAttribution` (`UIEventAttribution`)
- `SFAddToHomeScreenInfo` and home-screen methods that take
  `BEWebAppManifest`
- `iconItemProvider` (`NSItemProvider`; also `HTTPCookie` lives in
  FoundationNetworking on this toolchain)
- Delegate methods returning `[UIActivity]` / `[UIActivity.ActivityType]`

`SFAddToHomeScreenActivityItem` is declared with the Foundation-only
requirements `url` and `title`.

`tests/agent/SafariServicesLoadSmoke.swift` is the canonical schema-v2 marker
source. Focused checks live in `tests/agent/SafariServicesErrorTests.swift`,
`SafariServicesViewControllerTests.swift`, and
`SafariServicesServicesTests.swift`. `tests/agent/SafariServicesRuntime.swift`
is a standalone probe (not compiled by the sealed gate).
`tests/agent/SafariServicesDependencyIdentity.swift` passes real Foundation
`URL` / `NSError` values through public APIs for a future EC2 integration
build.

See `oracle-questions.tsv` for Darwin probes. Run
`bash tests/acceptance/test_host.sh` from this directory. Keep generated
products out of the tree.

## Depth pass 2026-09

Implemented before: 140. Implemented after: 140. Declared: 0. Deferred: 18
(unchanged). Unavailable: 0. Not-applicable: 0.

The remaining 18 identifiers all require a foreign type this seed cannot
import (`UIColor`, `UIImage`, `UIEventAttribution`, `UIActivity`,
`BEWebAppManifest`, `NSItemProvider`, `[HTTPCookie]` on a class whose
designated initializer is `BEWebAppManifest`). None are documented value
types, state machines, parsing, arithmetic, notifications, or error codes
with exact raw values, so they stay `deferred` rather than invented.

This pass rewrote fail-closed completions to run on the calling thread and
split evidence into family tests that return without `DispatchQueue.main`,
semaphore, or `RunLoop` waits.

Top-5 evidence distribution (implemented rows):

1. `testSFErrorCodes` — 16
2. `testSFAuthenticationErrorBridgedMembers` — 12
3. `testSFErrorBridgedMembers` — 12
4. `testSSReadingListErrorBridgedMembers` — 12
5. `testErrorDomainConstants` — 10
