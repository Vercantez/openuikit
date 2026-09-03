# MultipeerConnectivity

Linux starting point for Apple's public `MultipeerConnectivity` module. This
promotion could not byte-copy `full/multipeerconnectivity/` from legacy
`github.com/Vercantez/openuikit-linux-platform` branch
`cursor/port-multipeerconnectivity-to-linux-ca7c` (PR #37): this run's GitHub
token cannot fetch that private repository. The lane was reconstructed from the
monorepo seed, the in-repo PR #37 repair brief, and pinned
`dotnet/macios` declaration annotations. It is not a byte-copy of the 1503
Swift lines on that inaccessible branch.

The monorepo `full/multipeerconnectivity/reference/` dossier is kept (generator
`scripts/framework-fanout/generate_seed.py`, SHA256
`2b8230ced5a3ed78f070607346f6a684d9e0fb74a8932b92bc0f5e38f46f0a8e`, iPhoneOS
26.1 / Xcode 17B55). The platform branch `reference/` could not be compared.

This directory is not wired into the shared guest package. A passing isolated
host gate is not integrated Linux success.

## What is real

The public Swift surface that does not require UIKit compiles to
`libMultipeerConnectivity.dylib`.

Binding-sourced constants (asserted in `MultipeerConnectivityRuntime.swift`):

- `MCErrorDomain == "MCErrorDomain"`
- `kMCSessionMinimumNumberOfPeers == 2`
- `kMCSessionMaximumNumberOfPeers == 8`
- `MCEncryptionPreference`: optional=0, required=1, none=2
- `MCSessionSendDataMode`: reliable=0, unreliable=1
- `MCSessionState`: notConnected=0, connecting=1, connected=2
- `MCError.Code`: unknown=0 through unavailable=6 in macios Native order
  (timedOut=4, cancelled=5)

Also implemented:

- `MCPeerID` with a nonempty `displayName`; `NSSecureCoding` decode fails closed
- `MCSession` local configuration (`myPeerID`, `encryptionPreference`,
  `securityIdentity` storage, empty `connectedPeers`)
- `MCNearbyServiceAdvertiser` / `MCNearbyServiceBrowser` /
  `MCAdvertiserAssistant` stored properties
- Fail-closed `send`, `startStream`, `sendResource`, `nearbyConnectionData`
- Advertiser/browser start failures delivered asynchronously exactly once

## Fail-closed boundaries

Linux has no Bonjour/AWDL stack, peer invitation UI, or encrypted nearby
session. The implementation never fabricates a connected peer, discovered peer,
invitation presentation, resource transfer, or stream.

- `connectedPeers` stays empty. `connectPeer` / `cancelConnectPeer` /
  `disconnect` / `invitePeer` do not change session membership and do not
  invent `MCSessionDelegate` state callbacks.
- `send` and `startStream` throw `MCError.notConnected`.
- `sendResource` returns `nil` and hops its completion once onto the private
  serial queue `MultipeerConnectivity.completion` with `MCError.notConnected`.
- `nearbyConnectionData(forPeer:)` hops the same queue and throws
  `MCError.unavailable`.
- `startAdvertisingPeer` / `startBrowsingForPeers` hop that queue and call the
  optional `didNotStart*` delegate with `MCError.unavailable` exactly once per
  invocation. They never call `foundPeer` / invitation handlers.
- `MCAdvertiserAssistant.start()` is inert: no invitation UI.
- `MCPeerID.init(coder:)` returns `nil`. Encode writes no guessed Apple archive
  keys.
- `MCBrowserViewController` is compiled only when UIKit is importable. The
  isolated host gate has no UIKit module; those rows are `deferred`. There is
  no NSObject substitute.

Completions use `DispatchQueue.async` (never `sync`). Tests occupy the queue
through `@_spi(OpenUIKitHost) MultipeerConnectivityHostControl` to prove
non-inline exactly-once delivery. That SPI is not part of Apple's surface.

## Still open

See `oracle-questions.tsv` for Darwin error mapping, archive keys, and
callback-queue identity. UIKit `MCBrowserViewController` identity is prepared
in `tests/agent/MultipeerConnectivityDependencyIdentity.swift` for a future
clean EC2 run that builds guest Foundation and UIKit first.

Run `bash tests/acceptance/test_host.sh` from this directory. Keep generated
products out of the tree.
