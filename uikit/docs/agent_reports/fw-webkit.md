# WebKit SDK depth (`agent/fw-webkit`)

## Before / after

| | implemented | declared | deferred | total |
|---|---:|---:|---:|---:|
| before | 151 | 1242 | 840 | 2233 |
| after | 638 | 756 | 839 | 2233 |

Target was implemented ≥ 600 with the WKWebView / WKNavigationDelegate /
WKUIDelegate / WKUserContentController / WKWebsiteDataStore families
nondeferred except members that need foreign types this isolated compile
cannot import (SecTrust, UIFindInteraction, UIConversationContext,
UIEditMenuInteractionAnimating, UIInputSuggestion, UIContextMenuConfiguration,
Network.ProxyConfiguration). Those stay deferred with notes.

## What was measured (not guessed)

Navigation tracking order is Apple's `WKNavigationDelegate` overview:
`didStartProvisionalNavigation` (after provisional approval, before a
response) → `didCommit` (after navigation-response policy, immediately
before the main frame updates) → `didFinish`.
https://developer.apple.com/documentation/webkit/wknavigationdelegate

`estimatedProgress` is documented as 0.0…1.0 on `WKWebView`. Open-source
WebKit uses `initialProgressValue = 0.1` at provisional start
(`Source/WebKit/UIProcess/API/Cocoa/WKWebView.mm`). Linux fires 0.1 at
`didStartProvisionalNavigation` and 1.0 at `didFinish`. Whether iOS 26.1
resets to 0 after finish is an open question.

Content-blocker JSON is Apple's "Creating a content blocker" schema:
array of `{trigger, action}`; trigger requires `url-filter`; action `type`
in `{block, block-cookies, css-display-none, ignore-previous-rules, make-https}`;
`css-display-none` requires `selector`; `if-domain` is mutually exclusive
with `unless-domain` (same for top-url / frame-url).
https://developer.apple.com/documentation/safariservices/creating-a-content-blocker

`WKError.javaScriptExceptionOccurred` is code 4 (`WKError.h` / existing
`testWKErrorDomainAndCodes`). Non-literal `evaluateJavaScript` uses that
code. Literals (string / number / bool / null) resolve without an engine.

Sample (sealed tests on `docker exec uikit-linux` Swift 6.2.4):

- `loadHTMLString("<title>Hello</title>", baseURL: https://example.invalid/)`
  events `action, start, response, commit, finish`; `title == "Hello"`;
  `estimatedProgress` 0.1 then 1.0; history current item committed.
- `load(https://example.invalid/)` (no engine): `didStart` then
  `didFailProvisional` with `WKError.unknown`; no commit.
- Policy `.cancel`: no start.
- `evaluateJavaScript("\"ok\"")` → `"ok"`; `"42"` → `42`; `"true"` → `true`;
  `"null"` → `NSNull`; `"document.title"` → javaScriptExceptionOccurred.
- Cookie `setCookie` then `removeData(ofTypes: [WKWebsiteDataTypeCookies])`
  leaves `getAllCookies` empty.
- `css-display-none` without `selector`, and `if-domain`+`unless-domain`,
  compile-fail.

## What is still fail-closed / open

No renderer, network fetch, or JS VM. Snapshots, PDF, and web archives fail.
Custom-scheme handlers that return without `didFinish`/`didFail` are an
oracle question. `.download` action policy is treated like cancel (unobserved
on Apple). `_WebKit_SwiftUI` stays deferred.

## Gate

- Isolated Linux: `libWebKit.dylib` + 16 cited `test*` functions →
  `WEBKIT_AGENT_RUNTIME_OK` (`docker exec uikit-linux`, Swift 6.2.4).
- Full `tests/acceptance/test_host.sh` also wants
  `scripts/framework-fanout/generate_seed_v2.py` at the seed's provenance
  digest (`e44f6bde…`); this worktree's copy is `e56ee6e7…` (later
  framework-fanout commits). Compile + sealed tests were run with the
  same swiftc/Glibc runner the gate generates.
- No uikit pixel change; Catalyst / ios_suite / real-app screens not
  re-run.
