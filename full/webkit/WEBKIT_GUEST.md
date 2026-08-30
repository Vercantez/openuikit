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

Navigation is fail-closed. An allowed request receives
`didStartProvisionalNavigation`, then
`didFailProvisionalNavigation` with `WKPortableError.engineUnavailable`. It can
never commit, finish, add history, execute JavaScript, fetch bytes, or render a
page. JavaScript evaluation uses its completion handler to report the same
explicit engine boundary. A reentrant local-error-page load is recorded as a
terminal error without recursively redelivering the failure delegate.

`webkit_guest_sources.txt` is the exact ordered production contract. The host
gate rebuilds those sources into a dynamic library, links a client through that
library, exercises the state/callback contract, checks the install ID, and
rejects any load of Apple's WebKit. The core guest-package gate additionally
proves the ARM64 Mach-O dylib, its precise first-party dependency closure, and
execution through the packaged loader on Linux.

Native behavior is pinned to Xcode 26.1 / iOS Simulator 26.1. Those oracles
cover configuration-copy identity, defaults, empty history/view state, and enum
raw values. They are compatibility evidence, not evidence of an engine.
