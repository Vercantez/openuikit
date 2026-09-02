# Portable WebKit guest boundary

This directory owns a reusable first-party `WebKit` Swift module. The core
guest-package builder emits it as an independent ARM64 Mach-O
`libWebKit.dylib`; Focus is only the first unchanged consumer. No application
or vendored source participates in the implementation.

The current boundary is deliberately useful without pretending to contain a
browser engine. Configuration, preferences, data-store identity, user scripts,
message-handler registration, content-rule-list storage, navigation policy,
history state, request/response metadata, and completion/delegate delivery are
real stateful APIs. Content-rule compilation validates and stores JSON syntax;
it does not claim to enforce rules. The empty data store completes deletion
because no engine has ever persisted data.

The web-view state surface includes retained non-negative obscured-content
insets, opaque-white/null-resettable under-page color, and paired media
suspension. Media completion is scheduled asynchronously on the main actor and
delivered exactly once after each state commit. URL, title, loading, history,
and under-page values participate in the portable Foundation typed-observation
substrate. Registration and mutation delivery preserve `.initial`, `.prior`,
`.old`, and `.new` payload semantics while observation tokens remain alive.
Focus's classic `addObserver(_:forKeyPath:options:context:)` seam is a real
in-process registry delivered on the same mutations.

`WKBackForwardList` is a real in-memory list of `WKBackForwardListItem` values
(`url`, `title`, `initialURL`, `backList` / `forwardList` / `item(at:)`).
`load` never commits an item: a silent fake success puts a URL bar into
browsing mode over a blank page. `goBack` / `goForward` / `go(to:)` consult
that list and, when an item exists, start the same fail-closed navigation.

Navigation is fail-closed. An allowed request receives
`didStartProvisionalNavigation`, then
`didFailProvisionalNavigation` with typed `WKError.unknown` (`WKErrorDomain`,
code 1). It can never commit, finish, add history, execute JavaScript, fetch
bytes, or render a page. JavaScript evaluation reports the same unknown engine
boundary. Invalid content-rule JSON fails with
`WKError.contentRuleListStoreCompileFailed`; a missing lookup fails with
`WKError.contentRuleListStoreLookUpFailed`. A reentrant local-error-page load
is recorded as a terminal error without recursively redelivering the failure
delegate.

Host-only control seams (`WebKitHostControl`, `_portableLastError`,
`_portableCopyForWebView`) are `internal` or `@_spi(WebKitHost)`. Ordinary
`import WebKit` cannot see them; the host gate's negative typecheck proves it.

`webkit_guest_sources.txt` is the exact ordered production contract. The host
gate rebuilds those sources with `-warnings-as-errors`, links a client through
that library, exercises the state/callback contract, checks the install ID on
Darwin, and rejects any load of Apple's WebKit. A missing toolchain, guest
source, or `nm` refuses loudly. The core guest-package gate additionally
proves the ARM64 Mach-O dylib, its precise first-party dependency closure, and
execution through the packaged loader on Linux.

Native behavior is pinned to Xcode 26.1 / iOS Simulator 26.1. Those oracles
cover configuration-copy identity, defaults, empty history/view state, media
completion ordering, inset/background behavior, typed observation payloads,
and enum raw values. They are compatibility evidence, not evidence of an
engine.

## Untouched Focus result

The exact 129-present-source Blockzilla target was measured at
`arm64-apple-macos15.0` with Focus, SnapKit, UIKit, and both support trees
commit/tree pinned and clean before and after compilation. The placeholder
baseline produced 218 primary diagnostics. Replacing only its compile-time
WebKit boundary with the five attested production sources produced 204: 14
removed and zero added. WebKit itself emitted with zero primary diagnostics.

`tests/focus-webkit-exact-delta.tsv` preserves every removed diagnostic with
multiplicity. `webkit-provenance.json` freezes the control and candidate
commit/tree IDs, the 129-present plus two-generated-missing denominator, and
the raw-log, normalized-result, and delta SHA-256 values. The production
provenance gate verifies that evidence alongside the source and native-oracle
subjects. The remaining 204 diagnostics are unrelated platform gaps; this is
not a claim that Focus already links or launches.
