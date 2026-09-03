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
delegate callbacks never fire: there is no counterpart device.

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

`WCErrorDomain` is `WCErrorDomain`. Numeric `WCError.Code` values follow the
public `WCErrorCode` enumeration (`7001...7019`). Equality uses Foundation
dictionary value equality. Hashing uses only the error code.

Private TBD types (`WCXPCManager`, `WCQueueManager`, payload size-limit
symbols, and sandbox helpers) are explicit exclusions.

Apple localized strings, payload size limits, activate-with-nil-delegate
behavior, and the exact Apple queue QoS/label remain oracle questions.
