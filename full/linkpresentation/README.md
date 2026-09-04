# LinkPresentation

Linux starting point for Apple's public `LinkPresentation` module, reconstructed
from the pinned Xcode 26.1 iPhoneOS symbol graph, API digester, and the
existing portable `LPLinkMetadata` object. This directory is not wired into
the shared guest package. A passing isolated host gate is not integrated
Linux success and is not Apple link-preview behavior.

## What is real

The original portable metadata object is preserved and extended:

- Callers can create `LPLinkMetadata`, set `title` / `url` / `originalURL` /
  `remoteVideoURL`, copy it, and round-trip those fields through a Linux
  NSSecureCoding overlay.
- `LPErrorDomain` is `"LPErrorDomain"`, matching the pinned `dotnet/macios`
  `[ErrorDomain]` annotation and TBD export `_LPErrorDomain`.
- `LPError` is a `@frozen` `Foundation._BridgedStoredNSError` wrapper. `Code`
  raw values follow the pinned native order: `unknown = 1`,
  `metadataFetchFailed = 2`, `metadataFetchCancelled = 3`,
  `metadataFetchTimedOut = 4`, `metadataFetchNotAllowed = 5`.
- `LPLinkView` stores a copied `LPLinkMetadata`. `init(url:)` and `init(URL:)`
  record the argument as `originalURL` and do not fetch.
- `LPMetadataProvider` stores `shouldFetchSubresources` and `timeout`. Every
  `startFetchingMetadata` overload throws `LPError.metadataFetchFailed`.
  `cancel()` is a no-op because no Apple fetch is in flight.

Isolated host compilation produces `libLinkPresentation.dylib` with Foundation
and FoundationNetworking (Linux's home for Foundation-owned `URLRequest`).

## Fail-closed boundaries

Linux has no LinkPresentation daemon, preview renderer, or Apple metadata
service.

- Fetches never succeed and never invent Open Graph titles or images.
- `LPLinkView` subclasses `NSObject`, not `UIView`. It does not layout or
  paint Apple's preview chrome.
- `iconProvider`, `imageProvider`, and `videoProvider` are not declared:
  `NSItemProvider` is Foundation-owned and absent from this Linux Foundation
  overlay. Substituting a module-local public type is forbidden.

Darwin `localizedDescription` wording, NSSecureCoding keys, default
`timeout` / `shouldFetchSubresources`, and fetch error mapping are unobserved.

## Tests

`tests/agent/LinkPresentationLoadSmoke.swift` is the schema-v2 load marker.
`tests/agent/LinkPresentationTests.swift` holds the sealed focused tests.
`tests/agent/LinkPresentationRuntime.swift` is a standalone probe
(`LINKPRESENTATION_AGENT_RUNTIME_OK`).
`tests/agent/LinkPresentationDependencyIdentity.swift` is prepared for a future
clean EC2 run that builds guest Foundation first.

Run `bash tests/acceptance/test_host.sh` from this directory. Keep generated
products out of the tree.
