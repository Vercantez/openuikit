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
  on this host. JSON `CodableRepresentation` round-trips through
  `JSONEncoder` / `JSONDecoder`.
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
are absent. `tests/agent/CoreTransferableDependencyIdentity.swift`
imports the real `CoreTransferable` and `Foundation` modules for the
later EC2 build and must not be used to justify public substitutes
for Foundation-owned types.

## Fail-closed / unobserved

- `Never.transferRepresentation` and `Never.body` trap. They exist
  so `typealias Body = Never` compiles; they are not Apple runtime
  evidence.
- `TupleTransferRepresentation.body` traps. Tuple walking uses the
  builder-captured node, not `body`.
- `NSItemProvider.register` / `loadTransferable` are not declared:
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
