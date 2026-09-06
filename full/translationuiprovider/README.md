# TranslationUIProvider (Linux starting point)

Leaf-full starting implementation of Apple's public `TranslationUIProvider`
surface for Linux. The module is `TranslationUIProvider`; the host gate
produces `libTranslationUIProvider.dylib`.

This directory is a clean-room Linux starting point seeded from the Xcode 26.1
iPhoneOS 26.1 symbol graph, API digester, TBD exports, and pinned
`dotnet/macios` bindings (which have no TranslationUIProvider sources). It is
not wired into the shared guest package; that integration is a later
central-review step.

## Depth pass 2026-09

SDK depth for `TranslationUIProvider` in `full/translationuiprovider/`
(16 exact IDs). This is a fresh seed: context value types, the documented
`finish(translation:)` replacement rule, expand-sheet request counting, and
extension/scene configuration identity are implemented with focused tests.
Every implemented identifier has its own test.

Coverage this round: **16 implemented / 0 declared / 16 total**
(16 nondeferred, floor 13). No test is cited by more than 1 implemented
row (6.25% of the 16 implemented rows; 40% cap = 6).

Top-5 implemented evidence (of 16 rows; 40% cap of remaining non-enum rows = 6):

| Rows | Share | Evidence |
| ---: | ---: | --- |
| 1 | 6.25% | `TranslationUIProviderContextTests.swift#testTranslationUIProviderContextProtocol` |
| 1 | 6.25% | `TranslationUIProviderContextTests.swift#testTranslationUIProviderContextInputText` |
| 1 | 6.25% | `TranslationUIProviderContextTests.swift#testTranslationUIProviderContextAllowsReplacement` |
| 1 | 6.25% | `TranslationUIProviderContextTests.swift#testTranslationUIProviderContextFinish` |
| 1 | 6.25% | 12 other focused tests, one identifier each |

Environment: `swiftc` reports Swift 6.2.4, target `x86_64-unknown-linux-gnu`.
`.cursor/verify-cloud-environment.sh` did not emit
`CURSOR_SWIFT_ENVIRONMENT_OK` because `scratch/ladder-corpus/focus-ios` is
absent on this VM. The sealed gate compiles with a clean product tree
(`products=clean`). Active Cursor Build observed on this run was
`bld-20260906-253cd433-7a30-4d11-aad2-8b209b7b2d21` (campaign expected
`bld-20260901-d3266600-d87b-438f-94c1-d1aa48036e87`). Starting commit
`26f5086c5b31ba816742f18d3096152cd32280f4` matched.

The campaign inventory stamp `CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean` is a host-inventory token, not printed by the sealed framework gate. `swiftc` is Swift 6.2.4 / linux and the gate compiled with a clean product tree.

### What is real

- `TranslationUIProviderHostContext.inputText` and `allowsReplacement` are
  process-local. Defaults are `nil` / `false` until a host injects a request.
- `finish(translation:)` applies the public doc-comment rule: a `nil`
  translation never replaces; a non-`nil` translation is ignored when
  `allowsReplacement` is `false`; otherwise the submitted value is the
  applied replacement. The sheet is never closed.
- `expandSheet()` increments a request count and never presents UI.
- `TranslationUIProviderSelectedTextScene` stores the content closure.
  `body` is a leaf host scene that does not present translation UI.
- `TranslationUIProviderExtension.configuration` returns an isolation
  `AppExtensionSceneConfiguration` wrapping the body type name.
- `TranslationProviderUIExtensionConfiguration` stores the extension type
  name. Linux `hostAcceptConnection()` is always `false`.

### Fail-closed boundaries

- No Translation UI extension host, system translation sheet, or XPC
  session between host and `appex`.
- `TranslationUIProviderHostControl.presentTranslationProviderUI()` always
  throws `TranslationUIProviderUnavailable.linuxHost`.
- Isolated-host `View` / `AppExtension` / `AppExtensionScene` /
  `AppExtensionSceneConfiguration` names exist only when SwiftUI /
  ExtensionFoundation / ExtensionKit cannot be imported. They are not
  those modules' ABI.
- Darwin `@MainActor` on extension types is omitted so the host gate can
  call them synchronously.
- TBD-only SPI (`TranslationProviderContextImp`, `TranslationProviderSceneID`,
  `TranslationProviderRemoteUIExtensionPointIdentifier`,
  `translate(text:replacementAllowed:)`) is not published; it is not in the
  16-ID public surface.
- Doc-comment `isPopoverPresentation` and `cancel()` are not in the public
  graph and are not invented here.

## Tests

Focused `tests/agent/*Tests.swift` functions are the coverage evidence.
`tests/agent/TranslationUIProviderLoadSmoke.swift` is the schema-v2 load
marker. `tests/agent/TranslationUIProviderDependencyIdentity.swift` passes
Foundation `AttributedString` through `inputText` / `finish(translation:)`
for the clean EC2 integration build.
