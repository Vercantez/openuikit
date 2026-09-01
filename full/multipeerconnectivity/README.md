# MultipeerConnectivity

Linux starting implementation of Apple's public `MultipeerConnectivity` surface,
seeded from the Xcode 26.1 iPhoneOS symbol graph (132 unique public precise
identifiers). This directory is not wired into the shared guest package.

## What is real

- Typed public surface for `MCPeerID`, `MCSession`, `MCNearbyServiceAdvertiser`,
  `MCNearbyServiceBrowser`, `MCAdvertiserAssistant`, `MCBrowserViewController`,
  their delegates, session/encryption enums, `MCError`, `MCErrorDomain`, and
  the documented peer-limit constants (`kMCSessionMinimumNumberOfPeers` = 2,
  `kMCSessionMaximumNumberOfPeers` = 8).
- `MCPeerID` identity, `NSCopying`, and `NSSecureCoding` round-trip of a
  portable UUID plus display name. Separately constructed peers with the same
  display name are not equal; a copy is equal to its source.
- `MCError` as a `CustomNSError` overlay: codes `unknown` (0) through
  `unavailable` (6), preserved `userInfo`, code-only hashing, dictionary-value
  equality.
- Session construction stores `myPeerID`, optional `securityIdentity`, and
  `encryptionPreference` (convenience init defaults to `.optional`).
- Parameter validation that is locally observable: empty send-peer lists and
  empty stream names throw `invalidParameter`; Bonjour-style service type
  (1...15 `a-z`, `0-9`, `-`) is checked when advertising/browsing starts.

## Fail-closed boundaries

Linux has no Apple MultipeerConnectivity transport, Bonjour/AWDL discovery,
encryption identity, nearby-connection data format, or invitation UI.

- `startAdvertisingPeer` / `startBrowsingForPeers` never find or publish
  peers. They notify the optional start-failure callback with
  `MCError.unavailable` (or `invalidParameter` for a malformed service type).
- `invitePeer`, `connectPeer`, and `cancelConnectPeer` do not mutate
  `connectedPeers`.
- `send`, `sendResource`, and `startStream` fail with `notConnected`.
- `nearbyConnectionData(forPeer:)` fails with `unavailable`.
- `MCAdvertiserAssistant.start()` is inert: no invitation sheet, no
  advertising, no delegate presentation callbacks.
- `MCBrowserViewController` keeps min/max peer limits and session/browser
  identity but does not present Apple's picker. When UIKit cannot be imported
  it subclasses `NSObject` rather than `UIViewController`.
- Optional certificate handler defaults to `false` (do not auto-trust).

Do not treat a successful compile or empty `connectedPeers` array as Apple
network, discovery, or privacy parity.

## Still deferred / unobserved

Exact `MCErrorDomain` string, Apple `MCPeerID` archive keys, callback queues,
discoveryInfo size limits, and nearby-connection data layout are recorded in
`oracle-questions.tsv` and kept fail-closed until a central Apple-oracle probe
observes them.

`bash tests/acceptance/test_host.sh` is the supplied gate. It validates
evidence, coverage, the source manifest, warnings-as-errors compilation, dylib
creation, import, linking, and the runtime marker
`MULTIPEERCONNECTIVITY_AGENT_RUNTIME_OK`.
