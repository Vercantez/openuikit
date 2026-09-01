# Social

Linux starting point for Apple's public `Social` module, seeded from the
Xcode 26.1 iPhoneOS Swift overlay (67 public precise identifiers). This
directory is not wired into the shared guest package.

## Production ABI

Social imports the canonical `UIKit` module. OpenUIKit is only a staged
implementation dependency of that UIKit module, never imported by Social
sources. `SLRequest` imports `Accounts`. `FoundationNetworking` is imported
only where URL types live on Linux.

Ordinary production compilation without UIKit or Accounts fails with a
dependency blocker. Fallback `Social.UIView*` types are emitted only when
compiling with `-D SOCIAL_STANDALONE_TEST_FIXTURES` and UIKit is absent.
The same flag takes precedence over `canImport(Accounts)` so the fixture
`Social.ACAccount` is used instead of a deprecated system Accounts import.
That dylib is `standalone-unit-fixture-only` and is not production Social ABI.
Without the flag, Social imports real Accounts when available.

Host-only types (`SocialServiceError`, `SocialServiceType`,
`SLRequest.MultipartPart`, `host*` draft inspectors, `completeDraft`,
`hostMultipartBoundaryCandidates`) are `@_spi(OpenUIKitHost)`, not Apple
surface.

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
  field names (including parameter-derived `Content-Disposition` names), and
  builds an unsigned `URLRequest` when `account` is nil. GET/DELETE use the
  query string; POST/PUT use form-urlencoded (`+` for spaces) or a
  collision-tested multipart boundary. Every returned boundary has been checked
  against parameter names/values and part metadata/data.

## Fail-closed / partial boundaries

- Service-type constants are declared pending an Apple-runtime dump.
- `SLComposeViewController.isAvailable(forServiceType:)` is always `false`.
- `didSelectPost` / `didSelectCancel` are partial host hooks, not
  Apple-equivalent `NSExtensionContext` completion.
- `loadPreviewView()` returns `nil`.
- `preparedURLRequest()` returns `nil` when `account` is non-nil (no OAuth
  signer/token backend). `perform(handler:)` never networks.
- The sealed leaf gate compiles guest sources without UIKit, Accounts, or
  `-D SOCIAL_STANDALONE_TEST_FIXTURES`, so it is a production missing-dependency
  blocker. Isolated runtime evidence comes from
  `tests/agent/test_standalone_unit_fixtures.sh`.

## Gates / markers

Standalone unit fixtures (`bash tests/agent/test_standalone_unit_fixtures.sh`):

```
SOCIAL_DYLIB_KIND=standalone-unit-fixture-only
SOCIAL_STANDALONE_UNIT_FIXTURE_ONLY
SOCIAL_AGENT_RUNTIME_OK
SOCIAL_MULTIPART_HARDENING_OK
SOCIAL_PRODUCTION_MISSING_DEPENDENCY_BLOCKER_OK
SOCIAL_UNIT_FIXTURE_LOOKALIKE_NOT_PLATFORM_IDENTITY
SOCIAL_STANDALONE_UNIT_FIXTURE_GATE_OK
```

Real integration (`bash tests/agent/test_real_integration.sh`, also invoked by
`tests/agent/test_platform_identity.sh`) consumes staged platform Foundation,
UIKit/OpenUIKit, and Accounts from the repository or guest layout. It never
compiles `tests/agent/staging/` replacement APIs. Its client accepts dependency
values without a fake zero-argument `ACAccount()` initializer. Unique success
marker: `SOCIAL_REAL_INTEGRATION_OK`.

Accounts is not staged in the shared platform. That is an integration blocker
(`SOCIAL_REAL_INTEGRATION_BLOCKED dependency=Accounts reason=not-staged-in-shared-platform`).
Lookalike `tests/agent/staging` modules are unit fixtures only and must not
turn that blocker green.

A fixture-only runtime cannot prove UIKit/Accounts integration or Apple host
behavior. See `oracle-questions.tsv`.
