# Social

Linux starting point for Apple's public `Social` module, reconstructed from
the pinned Xcode 26.1 iPhoneOS symbol graph. The legacy platform branch
`cursor/port-social-to-linux-fd3a` (fan-out PR #9) was **unavailable** to this
run (private `openuikit-linux-platform` 404), so this is not a byte-copy of
those 1553 Swift lines. Behavior follows the in-repo repair briefs
(`full/framework-fanout/repairs-wave1-pr4-9.json` and
`repairs-wave1-pr4-9-r2.json`).

The isolated host gate compiles **without** UIKit or Accounts on the module
path. That configuration is the standalone-unit-fixture path: fallback
`UIView` / `UIViewController` / `UIImage` / `UITextView` / `UITextViewDelegate`
and `ACAccount` types live in this module only when those dependencies cannot
be imported. A build that `canImport` the canonical modules does not emit
`Social.UIView*` or `Social.ACAccount`.

## What is real

- `SLComposeViewControllerResult` and `SLRequestMethod` (Int `NS_ENUM` overlays,
  Hashable / Equatable / `init(rawValue:)`).
- `SLComposeSheetConfigurationItem` title/value/pending/tapHandler.
- `SLComposeServiceViewController` local sheet state: `textView` +
  `UITextViewDelegate` wiring, `contentText`, placeholder, characters
  remaining, `isContentValid` / `validateContent`, configuration item reload,
  at most one pushed configuration controller, `cancel` → `didSelectCancel`
  without recursion.
- `SLComposeViewController.isAvailable(forServiceType:)` is always `false`.
  `init(forServiceType:)` therefore returns nil.
- Draft helpers (`setInitialText`, `add` image/URL, `removeAll*`, completion
  handler clearing) on an `@_spi(OpenUIKitHost)` isolated-host instance.
- `SLRequest` URLRequest construction (query/urlencoded and multipart), CR/LF/quote
  rejection, collision-checked multipart boundaries. `preparedURLRequest()` is
  nil when `account` is set (no OAuth signer). `perform(handler:)` does not
  network.

## Fail-closed boundaries

Linux has no Twitter/Facebook/Weibo/LinkedIn compose UI, account OAuth, or
share-extension host.

- `didSelectPost` / `didSelectCancel` are **partial**: they increment local
  counters and do not complete an `NSExtensionContext`.
- `SLRequest.perform` hops once onto `Social.SLRequest.perform` and delivers
  `NSError` domain `Social.linux.fail-closed` with nil data/response.
- Service-type constant **payloads** are the commonly documented
  `com.apple.social.*` strings and remain `declared` pending oracle.

## Still open

See `oracle-questions.tsv`. UIKit/Accounts identity is not proven by this
standalone fixture. Real integration must consume staged platform UIKit and
Accounts dylibs and must not treat `Social.UIView` / `Social.ACAccount` as
success.

`tests/agent/SocialRuntime.swift` prints `SOCIAL_AGENT_RUNTIME_OK`.
`tests/agent/SocialDependencyIdentity.swift` is prepared for a future clean
EC2 run; compiling it against fixture types is not platform-identity success.

Run `bash tests/acceptance/test_host.sh` from this directory. Keep generated
products out of the tree.
