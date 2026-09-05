# WebKit for Linux

This directory is a clean-room starting implementation of Apple's public
`WebKit` module, seeded from the Xcode 26.1 iPhoneOS 26.1 symbol graph.
Isolated host compilation produces `libWebKit.dylib` with Foundation only.
There is no Web Content process, network fetch, or renderer on this host.

## What is real

- Navigation follows Apple's `WKNavigationDelegate` tracking order
  (`didStartProvisionalNavigation` → `didCommit` → `didFinish`). Local
  documents (`loadHTMLString`, `load(_:mimeType:…)`, `loadFileURL` when the
  file is readable, `loadSimulatedRequest`, registered `WKURLSchemeHandler`
  tasks that complete) commit a back-forward item. `http`/`https` loads fail
  provisionally with `WKError.unknown` because no engine can fetch.
- `url` / `title` / `isLoading` / `estimatedProgress` are KVO-observable.
  Progress is `0.1` at provisional start (WebKit `initialProgressValue`) and
  `1.0` at finish. `loadHTMLString` sets `title` from the first `<title>` element.
- `evaluateJavaScript` resolves string / number / bool / `null` literals and
  fails closed with `WKError.javaScriptExceptionOccurred` otherwise.
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

## Fail-closed

There is still no renderer, network stack, or JavaScript VM. Snapshots, PDF,
web archives, and non-literal `evaluateJavaScript` fail with `WKError`.
Cancelled navigation policy does not start. Nested network loads from inside
`didFailProvisionalNavigation` record a terminal error without recursing.

Do not treat this isolated host run as an integrated Linux product proof.
`tests/agent/WebKitDependencyIdentity.swift` is for a later EC2 build with
real guest Foundation.

## Deferred

These signatures need modules or Apple services this isolated compile does
not have. Substituting a local lookalike for a dependency-owned type is
forbidden:

- `_WebKit_SwiftUI.WebView` and SwiftUI `View` extensions (~805 IDs)
- `NSAttributedString` HTML import (`DocumentReadingOptionKey` is absent
  from Linux Foundation)
- `SecTrust`, `ProxyConfiguration`, `UTType` / `Transferable`
- `UIWritingToolsBehavior`, `UIConversationContext`, `UIFindInteraction`,
  context-menu configuration / animator UIKit types, `UIInputSuggestion`,
  `UIEditMenuInteractionAnimating`, `UIKeyModifierFlags`
