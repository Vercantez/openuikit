# Social

Linux starting point for Apple's public `Social` module, seeded from the
Xcode 26.1 iPhoneOS Swift overlay (67 public precise identifiers). This
directory is not wired into the shared guest package.

## Production ABI

Social imports the canonical `UIKit` module. OpenUIKit is only a staged
implementation dependency of that UIKit module, never imported by Social
sources. `SLRequest` imports `Accounts`. `FoundationNetworking` is imported
only where URL types live on Linux.

Host-only types (`SocialServiceError`, `SocialServiceType`,
`SLRequest.MultipartPart`, `host*` draft inspectors, `completeDraft`) are
`@_spi(OpenUIKitHost)`, not Apple surface.

`SLComposeSheetConfigurationItem.init()` is a stronger nonfailable override
of `NSObject.init()` because Swift forbids a failable `init!()` override of
a nonfailable superclass initializer. Other `init!` overlays stay failable.

## What is real

- `SLRequestMethod` and `SLComposeViewControllerResult` are `Int` enums with
  synthesized `Equatable` / `Hashable`.
- `SLComposeSheetConfigurationItem` stores title, value, pending flag, and tap
  handler as local state.
- `SLComposeServiceViewController` implements local compose-sheet state,
  `UITextViewDelegate` conformance (text view `delegate` is wired), at most one
  pushed configuration controller, and `cancel()` → `didSelectCancel()` without
  recursion. Extension-context completion is absent and recorded as partial.
- `SLComposeViewController` records a local draft. `isAvailable` is `false`.
  Invoking the host completion SPI clears `completionHandler`.
- `SLRequest` constructs, stores parameters, rejects CR/LF/quote multipart
  metadata, and builds an unsigned `URLRequest` when `account` is nil. GET/DELETE
  use the query string; POST/PUT use form-urlencoded (`+` for spaces) or a
  collision-checked multipart boundary.

## Fail-closed / partial boundaries

- Service-type constants are declared pending an Apple-runtime dump.
- `SLComposeViewController.isAvailable(forServiceType:)` is always `false`.
- `didSelectPost` / `didSelectCancel` are partial host hooks, not
  Apple-equivalent `NSExtensionContext` completion.
- `loadPreviewView()` returns `nil`.
- `preparedURLRequest()` returns `nil` when `account` is non-nil (no OAuth
  signer/token backend). `perform(handler:)` never networks.
- The sealed leaf gate compiles without UIKit/Accounts. Fallback types in
  `SocialHostTypes.swift` / `SLRequest.swift` exist only in that isolated
  standalone configuration and are not production Social ABI. That gate's
  runtime prints `SOCIAL_AGENT_RUNTIME_STANDALONE_ONLY`. Standalone tests are
  not evidence of UIKit or Accounts identity.

## Staged identity gate

`tests/agent/test_platform_identity.sh` stages Foundation (toolchain), a
canonical `UIKit` module whose implementation is `OpenUIKit`, and an
`Accounts` module, then builds Social with no fallback path. A consumer
importing Social+UIKit+Accounts proves `SLComposeServiceViewController` is
`UIKit.UIViewController` and `UIKit.UITextViewDelegate`, and that
`textView` / images / controllers / `SLRequest.account` are the canonical
module types. The emitted interface must not contain `Social.UIView*`,
`Social.UITextViewDelegate`, or `Social.ACAccount`.

The OpenUIKit checkout is not present in this leaf workspace; the identity
gate therefore stages the canonical module names from
`tests/agent/staging/`. That is not Apple UIKit/Accounts behavior.

See `oracle-questions.tsv`.
