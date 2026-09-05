# WebKit for Linux

This directory is a clean-room starting implementation of Apple's public
`WebKit` module, seeded from the Xcode 26.1 iPhoneOS 26.1 symbol graph.
Isolated host compilation produces `libWebKit.dylib` with Foundation only.
There is no Web Content process, network fetch, or renderer on this host.

## What is real

- Navigation follows Apple's `WKNavigationDelegate` tracking order
  (`decidePolicyFor` → `didStartProvisionalNavigation` → `didCommit` →
  `didFinish` / `didFail`). Local documents (`loadHTMLString`,
  `load(_:mimeType:…)`, `loadFileURL` / `loadFileRequest` when the file is
  readable, `loadSimulatedRequest`, registered `WKURLSchemeHandler` tasks
  that complete) commit a back-forward item. `http`/`https` loads fail
  provisionally with `WKError.unknown` because no engine can fetch.
  `WKNavigationActionPolicy.download` / `WKNavigationResponsePolicy.download`
  promote a `WKDownload` without starting a renderer fetch.
- `url` / `title` / `isLoading` / `estimatedProgress` / `canGoBack` /
  `canGoForward` are KVO-observable. Progress is `0.1` at provisional start
  (WebKit `initialProgressValue`) and `1.0` at finish. `loadHTMLString` sets
  `title` from the first `<title>` element.
- `evaluateJavaScript` / `callAsyncJavaScript` evaluate JSON and JS
  primitives (string / number / bool / `null`).
  `window.webkit.messageHandlers.name.postMessage(literal)` delivers to a
  registered `WKScriptMessageHandler` / `WKScriptMessageHandlerWithReply`.
  `alert` / `confirm` / `prompt` literals dispatch the ObjC completion-handler
  `WKUIDelegate` panel callbacks. Anything else fails closed with
  `WKError.javaScriptExceptionOccurred`.
- Content-rule JSON is validated against Apple's "Creating a content blocker"
  schema (`url-filter` required, documented action types, `css-display-none`
  needs `selector`, mutually exclusive domain/top-url/frame-url pairs).
- `WKWebsiteDataStore.removeData` with `WKWebsiteDataTypeCookies` clears that
  store's `WKHTTPCookieStore`. `default()` is a process-wide identity;
  `nonPersistent()` is ephemeral.
- `WKWebViewConfiguration` copies the shell for a web view but shares
  `preferences` / `userContentController` / `websiteDataStore` by identity.
- Option sets, `WKError.Code` (`unknown = 1` … `credentialNotFound = 17`),
  and `URLScheme` lowercasing are in-process values.
- `WKWebExtension` parses a directory `manifest.json` (`manifest_version` 2
  or 3, permissions, host permissions, background, action / browser_action,
  content_scripts, icons, `default_locale` with `_locales` `__MSG_*__`
  substitution). `WKWebExtension.MatchPattern` follows Chrome match-pattern
  semantics (`<all_urls>`, `*://host/path`, `*.host`, file paths).
  `WKWebExtensionContext` tracks grant/deny permission status and URL access
  from granted patterns. `WKWebExtensionController` loads contexts and
  forwards tab/window registry events.

## Fail-closed

There is still no renderer, network stack, or JavaScript VM. Snapshots, PDF,
and web archives fail with `WKError.unknown`. Non-literal /
non-JSON `evaluateJavaScript` fails with `javaScriptExceptionOccurred`.
Cancelled navigation policy does not start. Download policy creates a
`WKDownload` that immediately fails closed (no bytes). Nested network loads
from inside `didFailProvisionalNavigation` record a terminal error without
recursing. `WKWebExtension.init()` without a resource directory records
`WKWebExtension.Error.unknown`. Icons, popup view controllers, and async
tab/window mutations throw or return nil rather than inventing UI.

Do not treat this isolated host run as an integrated Linux product proof.
`tests/agent/WebKitDependencyIdentity.swift` is for a later EC2 build with
real guest Foundation.

## Deferred

These signatures need modules or Apple services this isolated compile does
not have. Substituting a local lookalike for a dependency-owned type is
forbidden:

- `NSAttributedString` HTML import (`DocumentReadingOptionKey` is absent
  from Linux Foundation)
- `SecTrust`, `ProxyConfiguration`, `UTType` / `Transferable`
- `UIWritingToolsBehavior`, `UIConversationContext`, `UIFindInteraction`,
  context-menu configuration / animator UIKit types, `UIInputSuggestion`,
  `UIEditMenuInteractionAnimating`, `UIKeyModifierFlags`

SwiftUI `_WebKit_SwiftUI` / `View` overlay identifiers are `not-applicable`
(owned by the SwiftUI lane), not deferred.

## Depth pass 2026-09 (wave 8)

Second SDK-depth pass on the first-pass Linux module already in this tree.
The first pass kept its navigation state machine, content-rule validator,
cookie store, and fail-closed evaluator; this pass extends them and splits
evidence.

Coverage before: implemented 638 / declared 756 / deferred 839 /
unavailable 0 / not-applicable 0 (2233 precise IDs).

Coverage after: implemented 1133 / declared 261 / deferred 25 /
unavailable 0 / not-applicable 814.

Top-5 `implemented` evidence distribution:

1. `testOptionSetRawValues` (155; option-set / enum members share one
   table-driven value test)
2. `testContextPermissionGrantDenyAndURLAccess` (98)
3. `testControllerTabAndWindowRegistry` (89)
4. `testActionCommandDataRecordAndMessagePort` (76)
5. `testHTMLStringLoadCommitsAndParsesTitle` (67)

Sealed host gate on this Linux host (Swift 6.2.4, `x86_64-unknown-linux-gnu`):

```
CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean
FRAMEWORK_FANOUT_DELIVERABLE_OK module=WebKit lane=medium-full symbols=2233
FRAMEWORK_FANOUT_REFERENCE_OK
WEBKIT_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=WebKit dylib=libWebKit.dylib
```

`.cursor/verify-cloud-environment.sh` did not emit the campaign stamp
because `scratch/ladder-corpus/focus-ios` is missing from this pod.
`swiftc --version` is Swift 6.2.4 targeting linux. The sealed schema-v2
`tests/acceptance/test_host.sh` prints the deliverable / reference / runtime
/ host markers; `products=clean` is the host-inventory token for a tree
without framework-local `.build` products.
