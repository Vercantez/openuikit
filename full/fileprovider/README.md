# FileProvider (Linux starting point)

This directory is a clean-room Linux port of Apple's public `FileProvider`
module, seeded from the Xcode 26.1 iPhoneOS SDK graphs. Isolated
`tests/acceptance/test_host.sh` compiles `libFileProvider.dylib` against the
cloud runner's Foundation only. That isolated gate is **not** integrated
Linux success with guest CoreGraphics / UniformTypeIdentifiers / Foundation
XPC types.

## Depth pass 2026-09

This pass implements the app-side manager and a **process-local in-process
provider host**. It is not `fileproviderd`, Files.app, or an NSExtension.

Coverage ledger (merge-repair):

- Before: 568 `implemented` / 2 `deferred`, but every implemented row cited
  `tests/agent/FileProviderRuntime.swift` (file path, not
  `test:full/fileprovider/tests/agent/<File>Tests.swift#testName`).
- After: **568 `implemented` / 2 `deferred`** of 570 exact IDs. Every
  implemented row cites a real top-level synchronous `func testName()` in a
  focused `*Tests.swift` file. The two deferred IDs are unchanged
  (`contentType`, `makeListenerEndpoint`).

Top-5 implemented evidence distribution (568 rows):

1. `FileProviderValueTests.swift#testEnumAndOptionSetValues` — 111 (19.5%),
   table-driven enum / option-set members / C constants
2. `FileProviderValueTests.swift#testHashableInequality` — 43 (7.6%)
3. `FileProviderValueTests.swift#testIdentifierAndPageValues` — 37 (6.5%)
4. `FileProviderTestingTests.swift#testTestingOperations` — 37 (6.5%)
5. `FileProviderItemTests.swift#testItemProtocolProperties` — 36 (6.3%)

No non-table-driven test exceeds 40% of the remaining implemented rows.

What the local host does:

- `NSFileProviderManager.add` / `remove` / `domains()` /
  `getDomainsWithCompletionHandler` persist domains as JSON under the port
  documents directory and post `NSFileProviderDomainDidChange`.
- `init(for:)` / `init(forDomain:)` return a manager only for a registered
  domain. `temporaryDirectoryURL` is a real directory under provider storage.
- `getUserVisibleURL` / `getIdentifierForUserVisibleFile` map items to a
  per-domain mount under that documents tree. Paths outside the mount fail
  closed with `noSuchItem` / `providerDomainNotFound`.
- `signalEnumerator(for:)` delivers `enumerateChanges` to enumerators created
  by the local replicated extension. `waitForChanges` / `waitForStabilization`
  drain in-flight mutations.
- `reimportItems`, `evictItem`, `requestModification`, and
  `requestDownloadForItem` call the local `NSFileProviderReplicatedExtension`.
- Create / modify / delete honor `NSFileProviderItemFields`,
  `mayAlreadyExist`, `deletionConflicted`, `failOnConflict`, recursive delete,
  `directoryNotEmpty`, and `filenameCollision`.
- `NSFileProviderPage.initialPageSortedByName` / `SortedByDate` are the UTF-8
  ObjC symbol names; enumerators sort and page from those sentinels.
- `NSFileProviderItemIdentifier.rootContainer` /
  `trashContainer` / `workingSet` use the exact ObjC identifier strings.
- Testing-mode domains (`alwaysEnabled` / `interactive`) list and run the
  declared `NSFileProviderTestingOperation` shapes.
- `NSFileProviderDomain` / `NSFileProviderDomainIdentifier` /
  `NSFileProviderDomainVersion` use identifier/generation value equality;
  domain versions round-trip `NSSecureCoding`.

Fail-closed in this pass (unchanged honesty):

- `getService` / `NSFileProviderServiceSource` XPC. No local
  `NSFileProviderService` class. `makeListenerEndpoint` stays deferred until
  guest Foundation vends `NSXPCListenerEndpoint`.
- `NSFileProviderItem.contentType` stays deferred until
  UniformTypeIdentifiers is on the compile path.
- `NSFileProviderExtension` action methods (legacy appex) still throw
  `applicationExtensionNotFound` / `providerNotFound`. Thumbnails return no
  image data.
- `fileProviderMaterializedSetDidChange` and
  `fileProviderPendingSetDidChange` are never posted.
- Placeholder writes persist Linux JSON sidecars, not Apple placeholder
  files. Exact Apple page/anchor bytes and `beforeFirstSyncComponent` remain
  oracle questions.

## What is real (isolated gate)

- Identifier newtypes, option sets, content policy, testing-operation enums,
  and `NSFileProviderError` with the public `-1000` code series.
- `NSFileProviderDomain` values, monotonic `NSFileProviderDomainVersion`,
  `NSFileProviderItemVersion`, and `NSFileProviderRequest`.
- `NSFileProviderItemProtocol` (except `contentType`, deferred here),
  enumerator / observer protocols, and fail-closed `NSFileProviderExtension`
  appex actions.
- `NSFileProviderManager.placeholderURL(for:)` as a local URL transform.
- Completion-handler APIs deliver **asynchronously, exactly once**.

## Fail-closed boundaries

XPC services, Files.app materialized/pending daemon notifications, and the
legacy application-extension host are not fabricated. Public `getService`
throws `NSFileProviderError.providerNotFound`. Extension create/rename/
trash/import paths throw `applicationExtensionNotFound`.

`NSXPCListenerEndpoint` and `NSFileProviderService` are not FileProvider-owned
in the canonical graph (no class identifier, no TBD export) and are not
declared here. When guest Foundation vends `Foundation.NSXPCListenerEndpoint`
and `Foundation.NSFileProviderService` (the UniformTypeIdentifiers-linked
configuration used by the future EC2 identity run), service-source and
`getService` signatures use those Foundation types directly.

Testing helpers absent from the graph (`NSFileProviderMemoryEnumerator`,
`NSFileProviderCollectingObserver`, `NSFileProviderEnumeratedItem`) are not
part of this module.

A host may still replace the local registry through
`@_spi(OpenUIKitHost) FileProviderHostAdapter` via
`NSFileProviderManager._installHostAdapter`. Passing `nil` restores the
process-local host.

## Future EC2 dependency identity

`tests/agent/FileProviderDependencyIdentity.swift` is not compiled by the
isolated host gate. A later clean EC2 run must:

1. Build guest Foundation, CoreGraphics, and UniformTypeIdentifiers modules
   and dylibs.
2. Build FileProvider with those `-I` and `-L` paths.
3. Link a client that imports Foundation, CoreGraphics,
   UniformTypeIdentifiers, and FileProvider.
4. Pass `Foundation.NSXPCListenerEndpoint`, `CoreGraphics.CGSize`, and
   `UniformTypeIdentifiers.UTType` through public APIs, exercise protocol
   existentials, prove callback non-reentrancy / exactly-once delivery, and
   verify `getService` remains fail-closed without XPC.
5. Run with `LD_LIBRARY_PATH` and confirm `libFileProvider.dylib` loaded
   after `FILEPROVIDER_DEPENDENCY_IDENTITY_OK`.

Isolated gate (Linux host, no docker):

```sh
bash full/fileprovider/tests/acceptance/test_host.sh
```

Exact marker output from this depth pass:

```
FRAMEWORK_FANOUT_REFERENCE_OK
CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean
FILEPROVIDER_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=FileProvider dylib=libFileProvider.dylib
```

`.cursor/verify-cloud-environment.sh` still fails on a missing
`scratch/ladder-corpus/focus-ios` checkout; the sealed FileProvider gate
prints the Swift environment marker from the runtime probe instead.
