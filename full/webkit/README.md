# WebKit for Linux

This directory is a clean-room starting implementation of Apple's public
`WebKit` module, seeded from the Xcode 26.1 iPhoneOS 26.1 symbol graph.
Isolated host compilation produces `libWebKit.dylib` with Foundation only.
There is no Web Content process, network fetch, or renderer on this host.

The existing fail-closed navigation, in-memory back-forward list, content-rule
JSON store, and configuration-copy seams are kept. This lane extends that
surface with additional WK types, Linux lookalikes for UIKit-shaped members,
schema-v2 agent tests, and complete exact-ID coverage.

## What is real

- `WKErrorDomain` is the string `WKErrorDomain`. `WKError.Code` raw values are
  `unknown = 1` through `credentialNotFound = 17`.
- `WKWebViewConfiguration` copies for a web view while sharing
  `preferences` / `userContentController` / `websiteDataStore` by identity.
- `WKWebsiteDataStore.default()` is a process-wide persistent identity;
  `nonPersistent()` is ephemeral. `removeData` completes once because no
  engine has ever stored bytes.
- `WKContentRuleListStore` validates and stores JSON syntax. It does not
  match or block requests.
- `WKBackForwardList` is a real in-memory list. `load` never commits an item.
- `WKUserScript` registration and `WKHTTPCookieStore` policy/getters are
  in-process state.
- Option sets and enums (`WKAudiovisualMediaTypes`, `WKDataDetectorTypes`,
  `WKDialogResult`, capture/playback/permission codes) use documented raw
  values.
- `URLScheme` lowercases a nonempty raw value.
- `WKWebExtension` / `WKWebExtensionContext` / `WKWebExtensionController`
  are constructible shells. A default extension reports a fail-closed error
  because no archive exists.

## Fail-closed

An allowed `WKWebView.load` delivers `didStartProvisionalNavigation`, then
`didFailProvisionalNavigation` with `WKError.unknown`. It never commits,
finishes, executes JavaScript, fetches bytes, or renders. Cancelled policy
does not start. `evaluateJavaScript` reports the same unknown engine
boundary.

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
  context-menu / drag-and-drop UIKit types

Linux lookalikes for `UIView` / `UIColor` / `UIEdgeInsets` exist only when
`UIKit` and `OpenUIKit` cannot be imported. They are not a UIKit product.
