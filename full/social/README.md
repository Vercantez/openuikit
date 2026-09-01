# Social

Linux starting point for Apple's public `Social` module, seeded from the
Xcode 26.1 iPhoneOS Swift overlay (67 public precise identifiers). This
directory is not wired into the shared guest package; that integration is a
separate central-review step.

## What is real

- `SLServiceTypeTwitter`, `SLServiceTypeFacebook`, `SLServiceTypeSinaWeibo`,
  `SLServiceTypeTencentWeibo`, and `SLServiceTypeLinkedIn` are public string
  constants. Values follow the long-standing `com.apple.social.*` identifiers
  and are queued for an Apple-runtime dump.
- `SLRequestMethod` and `SLComposeViewControllerResult` are `Int` enums with
  synthesized `Equatable` / `Hashable` (including `!=`, `hashValue`,
  `hash(into:)`, and `init(rawValue:)`).
- `SLComposeSheetConfigurationItem` stores title, value, pending flag, and tap
  handler as local state.
- `SLComposeServiceViewController` is the share-extension compose surface used
  by the 20-app corpus. Text, placeholder, character count, validity,
  configuration items, and a local configuration-view stack work. Subclasses
  can override `isContentValid()`, `configurationItems()`, `didSelectPost()`,
  and `didSelectCancel()` as on Apple.
- `SLComposeViewController` records a local draft (initial text, images, URLs)
  for a non-empty service type.
- `SLRequest` constructs, stores parameters and multipart parts, and builds an
  unsigned `URLRequest` (`preparedURLRequest()`). GET/DELETE encode parameters
  in the query string; POST/PUT encode a form body, or multipart when parts
  exist.

## Fail-closed boundaries

- `SLComposeViewController.isAvailable(forServiceType:)` is always `false`.
  Linux has no Apple Twitter/Facebook/Weibo/LinkedIn account service.
- `SLComposeViewController` never posts. Hosts may call `completeDraft(with:)`
  with `.cancelled`; `.done` is not reported as a successful Apple-network post.
- `SLComposeServiceViewController.didSelectPost()` does not send. The default
  is empty, matching Apple's documented "subclasses perform the post" hook.
- `loadPreviewView()` returns `nil` because this host has no
  `NSExtensionContext` attachments.
- `SLRequest.perform(handler:)` never performs I/O. It invokes the handler
  synchronously with `nil` data, `nil` response, and
  `SocialServiceError.accountServiceUnavailable`.
- `SLRequest.account` accepts a fail-closed `ACAccount` stand-in.
  Accounts.framework is not a declared dependency; assigning an account does
  not sign or authorize the request.
- UIKit is a declared dependency but is not on the leaf `swiftc` search path.
  `SocialHostTypes.swift` supplies local `UIView`, `UIViewController`,
  `UIImage`, and `UITextView` stand-ins unless `UIKit` or `OpenUIKit` can be
  imported.

## Deferred / not claimed

- OAuth signing, Apple social HTTP endpoints, and live account stores.
- System compose UI layout, presentation animation, and character-limit
  chrome.
- Default preview-image generation from share-extension items.
- `_SLErrorDomain` and other TBD-only symbols that are not in the public
  Swift surface.
- Service-specific attachment limits (image/URL/video counts).

See `oracle-questions.tsv` for the Apple-oracle probes this starting point
needs before anyone should treat remaining behavior as parity.
