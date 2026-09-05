# CoreTransferable (Linux starting point)

This directory is a clean-room Linux starting point for Apple's public
`CoreTransferable` module, seeded from the Xcode 26.1 iPhoneOS 26.1
symbol graph, API digester, and TBD exports. It is not wired into the
shared guest package; that integration is a later central-review step.

The earlier lane's portable `DataRepresentation` / `FileRepresentation`
surface is kept, including `TransferableError` fail-closed cases used by
the Darwin host runtime. This wave-6 pass adds the remaining
medium-full census types, schema-v2 coverage accounting, and the sealed
host-gate probes.

## What is real

- `Transferable` and `TransferRepresentation` compile, including
  `Representation` / `Item` / `Body` associated types.
- `DataRepresentation`, `FileRepresentation`, `ProxyRepresentation`,
  and `CodableRepresentation` store exporters/importers and run them
  on this host. `CodableRepresentation` round-trips through toolchain
  `JSONEncoder`/`JSONDecoder` and `PropertyListEncoder`/`PropertyListDecoder`.
- `TransferRepresentationBuilder` composes one through ten
  representations into `TupleTransferRepresentation`. First matching
  representation wins for export/import.
- `TransferRepresentationVisibility` has `.all`, `.team`, and
  `.ownProcess` (the graph does not include `.group`).
- `.visibility`, `.suggestedFileName`, and `.exportingCondition`
  wrap a representation. `exportedContentTypes(visibility:)` returns
  types from representations visible at that level; `.all` returns
  every export type. `exportingCondition` skips a representation
  when the predicate is false.
- `Data`, `String`, `URL`, and `AttributedString` conform to
  `Transferable` with portable `DataRepresentation` payloads:
  `public.data`, `public.utf8-plain-text`, `public.url`, and UTF-8
  text of `AttributedString` characters respectively.
- `exported(as:)`, `export(to:contentType:)`,
  `withExportedFile(contentType:fileHandler:)`, and
  `init(importing:contentType:)` walk the representation tree on
  this host.
- `SentTransferredFile` defaults `allowAccessingOriginalFile` to
  `false`. `ReceivedTransferredFile` remains constructible through
  `@_spi(OpenUIKitHost)` because the graph has no public initializer.
- Export-only / import-only representations still fail closed with
  `TransferableError.exportNotSupported` /
  `importNotSupported`, matching the existing Darwin host test.

`tests/agent/CoreTransferableRuntime.swift` is a standalone probe.
The sealed schema-v2 gate derives its runner from `implemented`
coverage and `*Tests.swift`.

## Lookalikes

Isolated host sources import Foundation only. `UTType` and Combine's
`TopLevelEncoder` / `TopLevelDecoder` are module-local stand-ins in
`CoreTransferableLookalikes.swift`, compiled only when those modules
are absent. The lookalike encoder protocol is also conformed by
toolchain `PropertyListEncoder` / `PropertyListDecoder`.
`tests/agent/CoreTransferableDependencyIdentity.swift`
imports the real `CoreTransferable` and `Foundation` modules for the
later EC2 build and must not be used to justify public substitutes
for Foundation-owned types.

## Fail-closed / unobserved

- `Never.transferRepresentation` and `Never.body` trap if invoked.
  They exist so `typealias Body = Never` compiles; they are not Apple
  runtime evidence. `Never.withExportedFile` and the two
  `Never.suggestedFileName` overloads remain declared because forming a
  typed function reference needs a `Never` value or an escaping
  conversion the compiler rejects.
- `TupleTransferRepresentation.body` returns a host
  `_HostNodeRepresentation` that forwards the same builder-captured
  node used for export/import. Apple's opaque `Body` identity is
  unobserved.
- `NSItemProvider.register` / `loadTransferable` stay deferred:
  Linux Foundation has no `NSItemProvider`, and a public
  framework-local substitute for that Foundation type is forbidden.
- Visibility filtering, AttributedString UTI (RTF vs plain text),
  and URL file-url vs public.url behavior are portable host rules,
  not Apple-oracle results.
- Swift/Foundation protocol witnesses synthesized onto `Data` and
  `URL` (`Sequence`, `Collection`, `Equatable.!=` on `URL`/`Data`,
  and so on) are owned by those modules; this lane does not
  redeclare them.

## Existing Darwin host gate

```sh
bash full/coretransferable/tests/test_coretransferable_host.sh
```

That script is Apple-only (`xcrun`, IceCubes consumer). Keep it
green on Darwin; the Linux deliverable gate is
`tests/acceptance/test_host.sh`.

## Depth pass 2026-09

Coverage after this pass: **152 implemented / 3 declared / 2 deferred /
148 unavailable** (155 nondeferred, floor 153). Every iOS-available
census row is nondeferred except the two `NSItemProvider` overlays,
which remain deferred because isolated Linux Foundation has no
`NSItemProvider`. The 148 unavailable rows are Swift/Foundation
witnesses synthesized onto `Data`/`URL`, not macOS/visionOS-only
API; they stay unavailable so this module does not redeclare them.

### Implemented on this host

- `Transferable` plus `exported(as:)`, `export(to:contentType:)`,
  `withExportedFile(contentType:fileHandler:)`, and
  `init(importing:contentType:)` for both `Data` and file `URL`.
- `TransferRepresentationBuilder` `buildBlock` arities 1–10,
  `buildExpression`, `buildLimitedAvailability`, and host
  `buildOptional` / `buildEither` so `#available` and `if` blocks
  compile. First matching representation wins: jpeg-then-png export
  requested as `public.image` returns the jpeg payload.
- UTType matching uses identifier equality or
  `have.conforms(to: requested)`. `String.exported(as: .text)` and
  `Data.exported(as: .item)` succeed because `public.utf8-plain-text`
  / `public.data` conform to those supertypes. Isolated host sources
  still compile a Foundation-only `UTType` lookalike; the later EC2
  build can import the real `UniformTypeIdentifiers` port.
- `CodableRepresentation` round-trips through toolchain
  `JSONEncoder`/`JSONDecoder` and `PropertyListEncoder`/`PropertyListDecoder`.
- `FileRepresentation` import copies the incoming file into a unique
  temporary directory and reports `isOriginalFile = false`. In-place
  delivery (`shouldAttemptToOpenInPlace` plus
  `allowAccessingOriginalFile`) is unobserved on Linux, so this host
  does not pretend to hand out the original file.
- `ProxyRepresentation` exports/imports by running the proxy type's
  `Transferable` chain (`String` in the tests).
- Seed `Transferable` defaults: `Data`, `String`, `URL`,
  `AttributedString`. The census does not include an `Image` or
  `DefaultTransferRepresentation` identifier, so those names are not
  invented.

### Fail-closed / still open

- No public `Image` transferable: not in the pinned 305-ID census.
- No public `DefaultTransferRepresentation` type: not in the
  census or API digester.
- `NSItemProvider` overlays stay deferred.
- `Never` instance methods that cannot be referenced without a
  `Never` value stay declared.
- Visibility is a stored token plus `exportedContentTypes` filter; it
  does not consult a pasteboard, share sheet, or signing team.

### Gate

Run `bash full/coretransferable/tests/acceptance/test_host.sh` on this
Linux host (no docker). Expected markers:

```
CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean
FRAMEWORK_FANOUT_DELIVERABLE_OK module=CoreTransferable lane=medium-full symbols=305
FRAMEWORK_FANOUT_REFERENCE_OK
CORETRANSFERABLE_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=CoreTransferable dylib=libCoreTransferable.dylib
```
