# Timer / RunLoop unification

**Date:** 2026-09-22
**Branch:** `agent/timer-unify` (from main bb773f63)

## Problem

OpenUIKit declared its own `Timer` and `RunLoop` classes. They are a
host-clock shadow of Foundation's, which keeps scripted renders
deterministic. Because both names were visible, any file importing UIKit and
Foundation failed with "'Timer' is ambiguous for type lookup in this
context". NetNewsWire hits this on the iOS triple at
`CurrentActivityViewModel.swift:27`, `ArticleStatusSyncTimer.swift:20`
and `ArticleStatusSyncTimer.swift:80`. Timer.swift's documented workaround,
`private typealias Timer = OpenUIKit.Timer`, is not available to an
unmodified app.

## Measured first: what the deterministic renders depend on

I added a temporary trace of every `_schedule` and `_fire` (not committed)
and ran the gate's renders with it:

* **Zero timers** were scheduled during the gate's 124 scenes (178 captures)
  and 15 real-app screens (`openrender`, iOS 3x).
* The conformance apps never name `Timer`.

So the renders depend on the host clock (`UIWindow.tick`), not on app
timers. OpenUIKit's own users of that clock are:

* `UIWindow.tick` stepping it;
* UIDatePicker reading `currentTime`;
* SwiftUI's deferred state delivery (`State.swift`, a zero-delay timer);
* openrender and host_full resetting it between scenes.

## Change

* **Wherever Foundation exists** (Apple toolchain, Linux corelibs):
  `OpenUIKit.Timer` and `OpenUIKit.RunLoop` are typealiases of
  Foundation's, the same pattern as attrstring-unify.
  * `Timer` now names one type whether a file imports UIKit, Foundation,
    or both.
  * An app's timers run on Foundation's run loop.
  * The UIKit shim's `Timer` alias and Blockzilla's generated alias now
    resolve to Foundation's.
* **The host-clock machinery** is `_HostClockTimer`, `_HostClockRunLoop`
  and `_HostClockRunLoopMode`, unchanged in behaviour. OpenUIKit's own
  clock users call it directly on every build.
* **The Foundation-hidden Mach-O guest** has no Foundation run loop. There
  `OpenUIKit.Timer` and `RunLoop` still name the host-clock types, and the
  guest's app-facing Foundation (`full/appshim`) aliases them, unchanged.
  Focus's timers in the guest therefore still run on the scripted clock.

## Verification

* **`Tests/TimerUnifyTests`**, new:
  * `OpenUIKit.Timer`, `UIKit.Timer` and `Foundation.Timer` are the same
    type.
  * A NetNewsWire-shaped `Timer?` with
    `scheduledTimer(timeInterval:target:selector:…)`, `#selector`, and an
    `@objc` target taking `Timer?` fires on Foundation's run loop.
  * A host-clock timer ignores wall time and the run loop, and fires only
    when `UIWindow.tick` passes its fire date.
  * Before the change the file did not compile (ambiguous `Timer`).
* **Existing host-clock tests** (TimerTests, DatePicker, SwiftUI deferred
  delivery, actor isolation) address `_HostClockTimer` explicitly.
* **`swift test`**: 2021 tests. The failing set is exactly main's (12
  classes).
* **Renders**: all 193 PNGs (15 real-app screens, 178 scene captures) are
  byte-identical to main's.
* **Gate** (`CHECK_ONLY=1 agent_merge.sh agent/timer-unify`): 124/124
  scenes pass, `GUEST_ROUTE_CHECK_OK`, conformance and real-app floors held,
  Linux build OK, **`checks passed (CHECK_ONLY)`**.
* **Guest** (`local_guest_verify.sh`):
  * `FOCUS_REAL_APPDELEGATE_LAUNCHED root=BrowserViewController`
  * 14/14 byte-identical
  * `REAL-APP SCREEN VERIFIED ON LINUX`
  * interaction replay: 10 captures byte-identical across 2 runs,
    `GUEST HOST INTERACTION VERIFIED ON LINUX`

## Open and risks

* **openhost** (the macOS SDL host) does not turn Foundation's run loop, so
  an app's Foundation timers do not fire there. Before this change, the
  app's OpenUIKit timers fired on the host tick.
  * No conformance app uses timers, so replays are unaffected.
  * NetNewsWire's headless entry spins the CFRunLoop itself.
  * Turning the run loop per host turn would put wall-clock time into
    interactive replays; I left it out on purpose.
* **App code on Apple or Linux that relied on OpenUIKit's timer extensions**
  (`_step`, `_reset`, the `TimeInterval` `fireDate`) must use
  `_HostClockTimer`. In-repo, only tests did.
