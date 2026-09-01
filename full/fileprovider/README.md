# FileProvider (Linux starting point)

This directory is a clean-room Linux port of Apple's public `FileProvider`
module, seeded from the Xcode 26.1 iPhoneOS SDK graphs. Isolated
`tests/acceptance/test_host.sh` compiles `libFileProvider.dylib` against the
cloud runner's Foundation only. That isolated gate is **not** integrated
Linux success with guest CoreGraphics / UniformTypeIdentifiers / Foundation
XPC types.

## What is real (isolated gate)

- Identifier newtypes, option sets, content policy, testing-operation enums,
  and `NSFileProviderError` with the public `-1000` code series.
- `NSFileProviderDomain` values, monotonic `NSFileProviderDomainVersion`,
  `NSFileProviderItemVersion`, and `NSFileProviderRequest`.
- `NSFileProviderItemProtocol` (except `contentType`, deferred here),
  enumerator / observer protocols, and fail-closed `NSFileProviderExtension`.
- `NSFileProviderManager.placeholderURL(for:)` as a local URL transform.
- Completion-handler APIs (`removeAllDomains`, identifier lookup, `getService`,
  stabilization, download, thumbnails) deliver **asynchronously, exactly once**,
  and fail closed without a host adapter.

## Fail-closed boundaries

Public manager add/remove/list/import and daemon operations throw
`NSFileProviderError.providerNotFound` (or a more specific code) unless a
Linux host installs `@_spi(OpenUIKitHost) FileProviderHostAdapter` via
`NSFileProviderManager._installHostAdapter`. Public APIs do **not** post
`fileProviderDomainDidChange` on the unhosted path and do **not** write
Apple-compatible placeholder files. JSON sidecars live only on
`NSFileProviderManager._writeLinuxPlaceholderJSON` (host SPI).

`NSXPCListenerEndpoint` and `NSFileProviderService` are Foundation types and
are not declared in this module. `makeListenerEndpoint()` and
`contentType: UTType` are compiled in when UniformTypeIdentifiers is on the
search path (future EC2 dependency run), and are deferred in the isolated
Foundation-only configuration.

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
   verify manager registration fails closed without a host adapter.
5. Run with `LD_LIBRARY_PATH` and confirm `libFileProvider.dylib` loaded
   after `FILEPROVIDER_DEPENDENCY_IDENTITY_OK`.

Isolated gate:

```sh
bash full/fileprovider/tests/acceptance/test_host.sh
```
