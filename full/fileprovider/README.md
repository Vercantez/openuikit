# FileProvider (Linux starting point)

This directory is a clean-room Linux port of Apple's public `FileProvider`
module, seeded from the Xcode 26.1 iPhoneOS SDK graphs. It builds
`libFileProvider.dylib` from the sources listed in
`fileprovider_guest_sources.txt`.

## What is real

- Identifier newtypes (`NSFileProviderItemIdentifier` and friends), option
  sets, content policy, testing-operation enums, and `NSFileProviderError`
  with the public `-1000` code series.
- Process-local `NSFileProviderDomain` values, monotonic
  `NSFileProviderDomainVersion`, `NSFileProviderItemVersion`, and
  `NSFileProviderRequest`.
- `NSFileProviderItemProtocol` (except `contentType: UTType`, which is
  deferred), a concrete `NSFileProviderEnumeratedItem`, and an in-memory
  enumerator plus collecting observer.
- `NSFileProviderManager` process-local domain add/remove/list,
  `documentStorageURL` / `temporaryDirectoryURL()`, placeholder URL
  construction, and JSON placeholder writes.
- `NSFileProviderExtension` as an overridable class: local URL mapping and
  placeholder helpers work; default item/enumerator/CRUD/thumbnail methods
  fail closed.

## Fail-closed boundaries

Linux has no Apple File Provider daemon, Files.app, application-extension
host, or XPC service runtime. These paths return typed
`NSFileProviderError` and never invent success:

- User-visible URL lookup and identifier mapping (`privacy`, `host-service`)
- Evict / reimport / signal enumerator / wait-for-stabilization / download
  request (`storage`, `host-service`)
- Default extension CRUD, `startProvidingItem`, and thumbnails (`extension`)
- Testing operations and replicated-provider harness (`host-service`)
- `NSFileProviderServiceSource.makeListenerEndpoint()` stand-in (`host-service`)

Domain registration is **process-local**. Adding a domain does not publish
it to an Apple Files UI.

## Deferred

- `NSFileProviderItemProtocol.contentType` (`UTType`) — UniformTypeIdentifiers
  is not a seed dependency and is not on the host-gate import path.
- Exact Apple placeholder file format, initial-page `NSData` bytes, and
  `beforeFirstSyncComponent` bytes (see `oracle-questions.tsv`).

Run the gate:

```sh
bash full/fileprovider/tests/acceptance/test_host.sh
```
