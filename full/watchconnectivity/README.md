# WatchConnectivity

This directory is a fail-closed portable `WatchConnectivity` starting point for
Linux. It reconstructs the public Xcode 26.1 iPhoneOS Swift surface from the
pinned symbol graph. It is not wired into a shared guest package; that
integration is a separate central review step.

Linux has no Apple Watch pairing, WatchConnectivity daemon, or complication
push budget. `WCSession.isSupported()` is therefore `false`. The default
session stays in `WCSessionActivationState.notActivated`. Pairing,
reachability, watch-app install, complication, and pending-content flags are
all `false`. `watchDirectoryURL` is `nil`. Application context stays empty.
Outstanding transfer lists stay empty.

`activate()` never transitions the session. When a delegate is set, it is
told `activationDidCompleteWith: .notActivated` plus
`WCError.sessionNotSupported` on one dedicated serial non-main delegate
queue, matching the public WCSession header contract. Callbacks are not
inline on the caller, are never the main queue, keep FIFO order, and never
overlap. `sessionDidBecomeInactive` and `sessionDidDeactivate` are never
invoked. Incoming message, user-info, file, and application-context
delegate callbacks never fire: there is no counterpart device. Optional
delegate defaults are no-ops and never invent a reply.

`sendMessage` and `sendMessageData` never invoke a reply handler. Error
handlers run on the same serial delegate queue with `sessionNotSupported`,
or `payloadUnsupportedTypes` when the dictionary is not a Foundation
property list (`NSString`, `NSNumber`, `NSDate`, `NSData`, `NSArray`, and
`NSDictionary` with `NSString` keys). `NSNull` and non-string keys are
rejected. `updateApplicationContext` throws the same errors synchronously
and does not store a context. `transferUserInfo`,
`transferCurrentComplicationUserInfo`, and `transferFile` return objects
whose `isTransferring` is `false` and report failure through `didFinish` on
the delegate queue. Missing files fail with `fileAccessDenied`; non-file
URLs fail with `invalidParameter`. `cancel()` is inert because a transfer
never starts. `WCSessionUserInfoTransfer.init(coder:)` returns `nil`
because Apple's archive keys are not in the public graph.

`WCError` equality compares Foundation dictionary values by wrapping both
`userInfo` dictionaries as `NSDictionary`, so integer and other bridged
plist values compare equal to themselves. Hashing still uses only the error
code.

Private TBD types (`WCXPCManager`, `WCQueueManager`, payload size-limit
symbols, and sandbox helpers) are explicit exclusions.

Apple localized strings, payload size limits, activate-with-nil-delegate
behavior, and the exact Apple queue QoS/label remain oracle questions.

## Depth pass 2026-09

Coverage before: **108 implemented / 11 declared / 0 deferred / 0 unavailable / 0 not-applicable**

Coverage after: **119 implemented / 0 declared / 0 deferred / 0 unavailable / 0 not-applicable**

The remaining 11 `declared` identifiers were incoming or lifecycle
`WCSessionDelegate` callbacks used by the corpus apps (home-assistant-ios,
pocket-casts-ios, vlc-ios, Telegram-iOS). They are now `implemented` as
fail-closed defaults: Linux never delivers counterpart payloads, never
replies, and never transitions activation, pairing, or reachability.
Hardware, daemon, and Apple-service success is not invented.

Every `implemented` row cites a top-level synchronous `func test*()` under
`tests/agent/*Tests.swift`. Enum `WCError.Code` members share one
table-driven raw-value test. No other test is cited by more than 40% of
implemented rows.

Top-5 evidence distribution (119 implemented rows):

1. `WCErrorTests.swift#testWCErrorCodeRawValues` — 21 (17.6%, enum/raw-value table)
2. `WCErrorTests.swift#testWCErrorStaticCodeAliases` — 19 (16.0%)
3. `WCSessionActivationStateTests.swift#testWCSessionActivationStateRawValues` — 8 (6.7%)
4. `WCErrorTests.swift#testWCErrorInitUserInfoAndCustomNSError` — 8 (6.7%)
5. `WCSessionTransferTests.swift#testWCSessionFileTransferCancel` — 5 (4.2%)
