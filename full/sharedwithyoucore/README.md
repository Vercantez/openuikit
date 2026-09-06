# SharedWithYouCore

Linux starting point for Apple's public `SharedWithYouCore` module,
reconstructed from the pinned Xcode 26.1 iPhoneOS 26.1 symbol graph. Isolated
host-gate success is not Messages, CloudKit, or collaboration-daemon success.
This directory is not wired into the shared guest package.

Coverage of the 82 exact public identifiers: **82 implemented / 0 declared /
0 deferred** (above the leaf-full floor of 66).

## What is real

Value types, option trees, person records, and the action state machine:

- `SWCollaborationIdentifier` and `SWLocalCollaborationIdentifier` are
  `String` `RawRepresentable` / `Hashable` / `Sendable` newtypes.
  `init(rawValue:)`, `init(_:)`, `!=`, `hashValue`, and `hash(into:)` store
  and compare the raw string unchanged.
- `SWCollaborationOption`, `SWCollaborationOptionsGroup`,
  `SWCollaborationOptionsPickerGroup`, and `SWCollaborationShareOptions`
  store title, identifier, subtitle, selection, required-option identifiers,
  footer, groups, and summary. Setters copy option arrays. The picker defaults
  `selectedOptionIdentifier` to the first option and mutually excludes siblings.
- `SWCollaborationMetadata` keeps collaboration / local identifiers, title,
  initiator handle, `PersonNameComponents`, and `@NSCopying` share options.
- `SWPerson`, `SWPerson.Identity`, `IdentityProof`, and `SignedIdentityProof`
  store handle, display name, thumbnail bytes, root hash, inclusion hashes,
  public key, public-key index, and signature bytes.
- `SWAction` is a one-shot state machine: `fulfill()` and `fail()` each move
  `isComplete` from `false` to `true`; a second call is a no-op.
- `SWStartCollaborationAction.fulfill(using:collaborationIdentifier:)` records the
  URL and identifier locally, then fulfills. `SWUpdateCollaborationParticipantsAction`
  stores added/removed identities.
- `SWCollaborationCoordinator.shared` is a process-local singleton. Setting
  `actionHandler` does not subscribe to an Apple daemon. Host tests inject
  actions synchronously.
- `NSSecureCoding` round-trips the types above with a host-local key layout.
  Missing keys fail closed (`nil`) on failable `init?(coder:)`.
  `SWCollaborationShareOptions.init(coder:)` is non-failable and uses empty
  groups / empty summary when keys are absent.

`UTCollaborationOptionsTypeIdentifier` is a provisional host UTI
(`com.apple.sharedwithyou.collaboration-options`). Darwin bytes are unobserved.

## Fail-closed boundaries

Linux has no Messages Shared with You daemon, CloudKit sharing sheet,
collaboration identity service, or entitlement.

- `SWCollaborationCoordinator` never invents incoming start or participant
  actions. Delivery happens only through `@_spi(OpenUIKitHost)`.
- `fulfill(using:collaborationIdentifier:)` does not register an iCloud share.
- Identity proofs store caller-supplied bytes and never verify signatures.
- Constructing metadata from one identifier does not mint the other.
- `SWCollaborationShareOptions.init(optionsGroups:)` uses an empty summary
  rather than generating Apple share-sheet copy.
- `SharedWithYouCoreHostError` is a Linux-local `CustomNSError`. It is not
  Apple's private `_SWActionResponseErrorDomain`.

`SWStartCollaborationAction` and `SWUpdateCollaborationParticipantsAction` have
no public Apple initializers. Host tests construct them through
`@_spi(OpenUIKitHost)`. `SWPerson.IdentityProof` likewise has no public designated
initializer.

## Still deferred / unobserved

See `oracle-questions.tsv`. Apple-oracle probes remain for Darwin UTI bytes,
second-call fulfill/fail traps, local-identifier minting, handler queue,
share-URL publication timing, picker required-option cascade, NSCoder key
layout, and `_SWActionResponseErrorDomain` codes.

## Depth pass 2026-09

Fresh seed: no prior implemented/declared split. After this pass:
**82 implemented / 0 declared / 0 deferred**.

Top-5 implemented evidence distribution:

1. `SWCollaborationIdentifierTests.swift#testSWCollaborationIdentifierType` — 1
2. `SWLocalCollaborationIdentifierTests.swift#testSWLocalCollaborationIdentifierType` — 1
3. `UTTypeIdentifierTests.swift#testUTCollaborationOptionsTypeIdentifier` — 1
4. `SWActionTests.swift#testSWActionClass` — 1
5. `SWActionTests.swift#testSWActionFail` — 1

Every implemented row cites its own dedicated top-level `func test*()`.
There are no public enum/option-set members or C `k…`/`err…` constants in this
surface. No test is cited by more than one implemented row (0% bulk-relabel).

`git rev-parse HEAD` at start was
`342dd2ee859ac3c9369653620a0b8835883008ad`. `swiftc` is Swift 6.2.4 targeting
`x86_64-unknown-linux-gnu`. `.cursor/verify-cloud-environment.sh` did not emit
`CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean` on this
snapshot (`scratch/ladder-corpus/focus-ios` is missing). The sealed framework
gate compiles with a clean product tree (`products=clean`). The pod booted
from `bld-20260906-253cd433-7a30-4d11-aad2-8b209b7b2d21` rather than campaign
`bld-20260901-d3266600-d87b-438f-94c1-d1aa48036e87`.
