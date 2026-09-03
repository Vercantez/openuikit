# MessageUI (Linux starting point)

This directory is a fail-closed portable `MessageUI` module for the OpenUIKit
Linux platform. It extends the in-tree mail-composer starting point (composition
state preservation, `canSendMail() == false`, no fabricated send) to the sealed
Xcode 26.1 iPhoneOS public seed. It is not wired into the shared guest package;
that integration is a separate review step.

Isolated host compilation produces `libMessageUI.dylib` with Foundation only.
`UINavigationController` is UIKit-owned and is the superclass only when UIKit
can be imported. The isolated host therefore subclasses `NSObject`. This is not
a public lookalike of UIKit.

## What is real

- `MFMailComposeResult` raw values are `cancelled = 0`, `saved = 1`, `sent = 2`,
  `failed = 3` (pinned `dotnet/macios` `[Native]` order).
- `MessageComposeResult` raw values are `cancelled = 0`, `sent = 1`,
  `failed = 2`.
- `MFMailComposeControllerDeferredAction` raw values are `none = 0`,
  `adjustInsertionPoint = 1`, `addMissingRecipients = 2`.
- `MFMailComposeErrorDomain` is the string `MFMailComposeErrorDomain`, matching
  the pinned `[ErrorDomain ("MFMailComposeErrorDomain")]` annotation.
- `MFMailComposeError` is a `@frozen` `Foundation._BridgedStoredNSError`
  wrapper. `Code` is `saveFailed = 0`, `sendFailed = 1`.
- Notification and attachment-key constants use the ObjC constant names
  exported by the TBD (`…DidChangeNotification`, `…AvailabilityKey`,
  `…AttachmentURL`, `…AttachmentAlternateFilename`).
- `MFMailComposeViewController` stores to/cc/bcc/subject/body/HTML flag,
  preferred sending address, and attachment data. `canSendMail()` is `false`.
- `MFMessageComposeViewController` stores recipients/body/subject and
  attachment dictionaries. `canSendText()`, `canSendAttachments()`,
  `canSendSubject()`, and `isSupportedAttachmentUTI(_:)` are `false`.
- Non-file URLs are rejected by `addAttachmentURL`. Empty filenames are
  rejected by `addAttachmentData(_:typeIdentifier:filename:)`.
- Host hooks `reportPortableServiceUnavailable()` finish with `.failed` and
  never report a successful send.

## Fail-closed boundaries

Linux has no Mail.app, Messages, or Apple collaboration sheet.

- Capability queries never become `true`.
- The availability notification is never posted.
- `insertCollaborationItemProvider` is not declared: `NSItemProvider` is
  Foundation-owned and is absent from this Linux Foundation overlay.
  Substituting a module-local public type is forbidden.
- `MFMessageComposeViewController.message` (`MSMessage`) is not declared:
  Messages is not a declared dependency.
- Darwin `localizedDescription` wording, attachment-dictionary layout on Apple,
  and UIKit presentation/dismissal are unobserved.

## Tests

`tests/agent/MessageUILoadSmoke.swift` is the schema-v2 load marker.
`tests/agent/MessageUITests.swift` holds the sealed focused tests.
`tests/agent/MessageUIRuntime.swift` is a standalone probe
(`MESSAGEUI_AGENT_RUNTIME_OK`).
`tests/agent/MessageUIDependencyIdentity.swift` is prepared for a future
clean EC2 run that builds guest Foundation first.

Run `bash tests/acceptance/test_host.sh` from this directory. Keep generated
products out of the tree.
