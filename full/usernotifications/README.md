# UserNotifications (Linux starting point)

This directory is a clean-room Linux starting point for Apple's public
`UserNotifications` module, seeded from the Xcode 26.1 iPhoneOS 26.1
symbol graph, API digester, and TBD exports. It is not wired into the shared
guest package; that integration is a later central-review step.

The earlier portable module remains: the default center fails authorization
and scheduling closed, and a host may opt into the `OpenUIKitHost` SPI for a
volatile in-process session. Wave-5 adds honest public-surface coverage,
bridged `UNError`, NSSecureCoding overlay archives, and the remaining
Foundation-owned types that do not require CoreLocation or Intents.

## What is real

- `UNErrorDomain` is the string `UNErrorDomain`. `UNError` is a `@frozen`
  `Foundation._BridgedStoredNSError` wrapper around a stored `NSError`.
  `UNError.Code` conforms to `Foundation._ErrorCodeProtocol` with the pinned
  raw values (`notificationsNotAllowed = 1`, attachment codes 100–105,
  notification invalid 1400–1401, content-providing 1500–1501,
  `badgeInputInvalid = 1600`).
- Authorization, presentation, action, and category options are `OptionSet`
  values with the pinned bit masks. Status, setting, preview, alert-style,
  and interruption-level enums use the pinned integer raw values.
- `UNMutableNotificationContent` stores caller-supplied fields. Scheduling
  snapshots content so later mutation of the mutable object does not change
  a pending request.
- File-URL attachments reject non-file URLs with `attachmentInvalidURL`.
  Linux records `type` as the path extension; UTI interpretation of
  attachment option keys is unobserved.
- Time-interval and calendar triggers compute `nextTriggerDate()` with
  Foundation `Date` / `Calendar`. Push triggers have no public initializer
  (system-created on Apple); the OpenUIKitHost SPI can construct a stand-in.
- The default `UNUserNotificationCenter` fails closed: the first
  `requestAuthorization` reports denied with `notificationsNotAllowed`,
  `add` and `setBadgeCount` throw that error until a host authorizes the
  session, and `supportsContentExtensions` is `false`.
- An authorized volatile session supports request replacement, pending and
  delivered queues, category registration, badge validation (`badge < 0`
  throws `badgeInputInvalid`), and async delegate presentation/response
  delivery. It never claims durable scheduling, operating-system UI, push
  transport, or delivery after process exit.
- `UNNotificationServiceExtension.didReceive` delivers the original
  request content to the handler. `serviceExtensionTimeWillExpire` is a
  no-op; there is no extension host.
- NSSecureCoding round-trips a versioned Linux overlay archive and returns
  `nil` for payloads that lack that version key. This is not Apple's
  archive layout.

`tests/UserNotificationsNativeOracle.swift` typechecks against Apple's
installed SDK and then this module. The IceCubes-shaped consumer probe
preserves that app's retroactive `Sendable`, delegate, authorization, and
presentation signatures.

## Fail-closed boundaries

- No notification permission prompt, usernoted daemon, or APNs connection.
- `updating(from:)` throws `contentProvidingObjectNotAllowed` for every
  provider; Intents-backed attributed message contexts are not constructible
  here.
- `UNLocationNotificationTrigger` exists as a type for inheritance checks.
  `init(region:)` and `region` are omitted because `CLRegion` is owned by
  CoreLocation, which is not a declared dependency.
- `UNNotificationAttributedMessageContext.init(sendMessageIntent:attributedContent:)`
  is omitted because `INSendMessageIntent` is owned by Intents.
- `NSString.localizedUserNotificationString` returns the key (or a
  `String(format:)` result) without a UserNotifications strings table.
- Overlay `NSCoder` keys are Linux-local. Apple's keyed-archive layout is
  an oracle question.

## Deferred

Callback queues, exactly-once delivery across process death, CarPlay /
critical-alert entitlement behavior, attachment data-store moves, and
Apple's NSSecureCoding class names remain unobserved. Those facts are
recorded in `oracle-questions.tsv` rather than guessed.
