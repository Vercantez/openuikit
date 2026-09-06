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
  `WKError.javaScriptExceptionOccurred` in the agent module, or
  `WKError.unknown` when compiled with `PORTABLE_WEBKIT_HOST` (the first-pass
  host runtime asserts that spelling for `document.title`).
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
(owned by the SwiftUI lane). The synthesized stdlib witness
`Equatable.!=` on `WebView.ActivatedElementInfo`
(`s:SQsE2neoiySbx_xtFZ::SYNTHESIZED::s:15_WebKit_SwiftUI0A4ViewV20ActivatedElementInfoV`)
is `deferred`, not `not-applicable`: its precise ID is not a SwiftUI
overlay re-export.

## Depth pass 2026-09 (wave 8)

### Local continuation: agent/fw-webkit-c

This continuation adds **111 implemented identifiers**, preserving all earlier
implementation and tests. Only `full/webkit/` changes.

| Status | Before | After |
| --- | ---: | ---: |
| implemented | 1133 | 1244 |
| declared | 261 | 150 |
| deferred | 26 | 26 |
| unavailable | 0 | 0 |
| not-applicable | 813 | 813 |
| Total | 2233 | 2233 |

The new behavior is `WebPage` value semantics: navigation preferences and
configuration copy isolation, dialog results with exact string/file-selection
payloads, sensor-permission discriminants, CSS media values, navigation event
and fullscreen cases, and navigation errors with preserved underlying errors.
`defaultNavigationPreferences` now uses the SDK's value type rather than the
previous shared `WKWebpagePreferences` object. `mediaType` now uses
`CSSMediaType?`; `title` has the SDK's nonoptional `String` shape. The user-agent
setter implements the measured nil reset. Sensor permissions are values only:
no camera, microphone, motion, entitlement, renderer, or daemon is enabled.

Declaration facts were reconciled against exact `public-surface.tsv` IDs and
matching declaration USRs in `api-digester.json`, including nested nominal types,
case payloads, property types and Hashable/Sendable conformances. Synthesized
stdlib witnesses are exercised via equality, inequality and hashing. Foundation
owns URL and NSError; this pass introduces no dependency substitutes. Native
compilation uses the pinned 26.1 SDK, not the newer surface in online docs.

Measurements: Xcode 26.1 (17B55), iPhoneSimulator SDK 26.1 (23B77), private
`OpenUIKit-fw-webkit-c` iPhone 17 Pro simulator running iOS 26.1 (23B86).
`WebKitPageValueTests.swift` contains **15 top-level synchronous tests**, run
unchanged against both Apple WebKit and the Linux module. The tests check
payload preservation, selection order/duplicates, copy mutation, defaults,
setters/resetters, dictionary lookup, and NSError bridging; they perform no
network requests, sensor operations, main-queue waits or run-loop pumping.

| Measurement | Before port | iOS 26.1 and after port |
| --- | --- | --- |
| Original JavaScript preference after changing a configuration copy | false (shared reference) | true (value copy) |
| Initial custom user agent | nil | Optional("") |
| User agent after setting a string then nil | nil | Optional("") |
| Navigation preference defaults | shared WKWebpagePreferences object | recommended / true / keepAsRequested / false |
| NavigationError NSError codes | type absent | failedProvisionalNavigation=0; pageClosed=1; webContentProcessTerminated=2; invalidURL=3 |
| NavigationError NSError domain | type absent | WebKit.WebPage.NavigationError |
| Prompt/file result payloads | types absent | exact strings; file order and duplicates preserved |
| CSS media raw values | all / print / screen | unchanged; custom values round-trip case-sensitively |

The before values were measured by compiling the original `WebKitPage.swift`
from baseline `3e9bada0` with the original source set in an isolated Linux temporary directory.
All 15 new shared tests pass on both authorities. The Linux sealed gate was
also green before the changes and remains green after them.

Top-5 implemented evidence distribution after this continuation (1244 rows):

| Test | Rows | Share |
| --- | ---: | ---: |
| testOptionSetRawValues | 155 | 12.46% |
| testContextPermissionGrantDenyAndURLAccess | 98 | 7.88% |
| testControllerTabAndWindowRegistry | 89 | 7.15% |
| testActionCommandDataRecordAndMessagePort | 76 | 6.11% |
| testHTMLStringLoadCommitsAndParsesTitle | 67 | 5.39% |

The same five counts were 155/98/89/76/67 before this continuation, out of 1133
implemented rows. New evidence spans 15 tests; the largest new test covers 14
rows (12.61% of the 111 additions). No existing evidence was bulk relabeled;
no deferred or overlay rows were reclassified.

Validation:

- `python3 -B full/framework-fanout/validate_seed.py --framework full/webkit --phase deliverable`:
  `FRAMEWORK_FANOUT_DELIVERABLE_OK module=WebKit lane=medium-full symbols=2233`.
- Operator container, `/work-fw-webkit-c`, Swift 6.2.4:
  `tests/acceptance/test_host.sh` ends
  `FRAMEWORK_FANOUT_HOST_OK module=WebKit dylib=libWebKit.dylib`.
- First-pass Linux `tests/test_webkit_host.sh` remains green:
  `WEBKIT_HOST_GATE_OK`, 13 product sources, 3487 exported WK symbols.
- First-pass `tests/test_webkit_native_26_1.sh` passes on the private simulator:
  `WEBKIT_NATIVE_26_1_OK sdk-build=23B77`.
- New `tests/test_webkit_page_values_native_26_1.sh` runs the exact shared tests:
  `WEBKIT_PAGE_VALUE_NATIVE_OK tests=15`. Set `WEBKIT_ORACLE_DEVICE` to a private
  booted simulator and `SIM_DEVICE_SUFFIX` to its name suffix. It does not create,
  boot, or access any other device.

WebPage navigation streams/history, async dialogs and sensor authorization
remain outside the implemented gain. Exploratory native local-document probes
showed no history item after an HTML-string load, but one after a simulated
request. History snapshots also showed equality differences that require a
separate isolated identity probe. These observations are recorded in
`oracle-questions.tsv`; the placeholder history model is not promoted.
The original Foundation/UI dependency deferrals and fail-closed engine paths
remain as documented above.

### Prior wave-8 implementation and repair

Second SDK-depth pass on the first-pass Linux module already in this tree.
The first pass kept its navigation state machine, content-rule validator,
cookie store, and fail-closed evaluator; this pass extends them and splits
evidence.

Coverage before this depth pass: implemented 638 / declared 756 /
deferred 839 / unavailable 0 / not-applicable 0 (2233 precise IDs).

Refused ledger at `c3688351`: implemented 1133 / declared 261 /
deferred 25 / unavailable 0 / not-applicable 814. FW_MERGE refused one
`not-applicable` row whose precise ID is synthesized `Equatable.!=` on
SwiftUI `WebView.ActivatedElementInfo`, not a SwiftUI overlay re-export.

Coverage after this repair: implemented 1133 / declared 261 /
deferred 26 / unavailable 0 / not-applicable 813.

Top-5 `implemented` evidence distribution (1133 implemented rows; no
non-member test exceeds 40%):

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

First-pass `tests/test_webkit_host.sh` remains green
(`WEBKIT_HOST_GATE_OK`). Nested `didFailProvisionalNavigation` error
documents do not start a second provisional cycle; `goBack` to a
host-recorded network URL stays fail-closed, while locally committed HTML
history items restore. `tests/test_webkit_native_26_1.sh` exits 2 here
(no pinned Xcode).
