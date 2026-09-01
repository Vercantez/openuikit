# MultipeerConnectivity

Linux starting implementation of Apple's public `MultipeerConnectivity` surface,
seeded from the Xcode 26.1 iPhoneOS symbol graph (132 unique public precise
identifiers). This directory is not wired into the shared guest package.

The isolated `tests/acceptance/test_host.sh` gate compiles against Foundation
only. That result is not integrated Linux success with guest Foundation/UIKit
dylibs. `tests/agent/MultipeerConnectivityDependencyIdentity.swift` is the
client for a future clean EC2 run that builds those real dependency modules
first.

## What is real on the isolated Foundation compile

- Typed public surface for `MCPeerID`, `MCSession`, `MCNearbyServiceAdvertiser`,
  `MCNearbyServiceBrowser`, `MCAdvertiserAssistant`, their delegates,
  session/encryption enums, `MCError`, and the documented peer-limit constants
  (`kMCSessionMinimumNumberOfPeers` = 2, `kMCSessionMaximumNumberOfPeers` = 8).
- `MCPeerID` display name, `NSCopying`, and portable UUID equality. Separately
  constructed peers with the same display name are not equal; a copy is equal
  to its source.
- `MCError` as a `CustomNSError` overlay: codes `unknown` (0) through
  `unavailable` (6), preserved `userInfo`, code-only hashing, dictionary-value
  equality. `MCErrorDomain` is a portable OpenUIKit string, not an observed
  Apple runtime value.
- Session construction stores `myPeerID`, optional `securityIdentity`, and
  `encryptionPreference` (convenience init defaults to `.optional`).
- Empty send-peer lists and empty stream names throw `invalidParameter`
  inline. Bonjour-style service type (1...15 `a-z`, `0-9`, `-`) is checked
  when advertising/browsing starts.
- Start-advertiser, start-browser, resource-send, and nearby-connection
  failures are delivered asynchronously exactly once on a private queue. The
  async `nearbyConnectionData(forPeer:)` overlay uses that same completion
  path.

## Fail-closed boundaries

Linux has no Apple MultipeerConnectivity transport, Bonjour/AWDL discovery,
encryption identity, nearby-connection data format, or invitation UI.

- `startAdvertisingPeer` / `startBrowsingForPeers` never find or publish
  peers. They enqueue one `didNotStart…` callback with `MCError.unavailable`
  (or `invalidParameter` for a malformed service type).
- `invitePeer`, `connectPeer`, and `cancelConnectPeer` do not mutate
  `connectedPeers`.
- `send` and `startStream` throw `notConnected`. `sendResource` returns nil
  `Progress` and completes asynchronously with `notConnected`.
- `nearbyConnectionData(forPeer:)` completes asynchronously with
  `unavailable`.
- `MCAdvertiserAssistant.start()` is inert: no invitation sheet, no
  advertising, no delegate presentation callbacks.
- `MCPeerID.init(coder:)` returns nil. Apple archive keys are unobserved;
  encode writes no guessed ABI keys.
- Optional certificate handler defaults to `false` (do not auto-trust).

## UIKit-bearing surface

`MCBrowserViewController` is compiled only when `canImport(UIKit)` is true,
and then it subclasses `UIKit.UIViewController`. The isolated host gate omits
that type entirely (coverage: `deferred`). An `NSObject` stand-in is
forbidden. The future EC2 identity client assigns the controller to
`UIKit.UIViewController` and passes real `Data`, `Progress`, `InputStream`,
and `OutputStream` values through public APIs.

## Still deferred / unobserved

Exact `MCErrorDomain` string, Apple `MCPeerID` archive keys, Apple callback
queues, discoveryInfo size limits, nearby-connection data layout, and
browser-controller auto-browse-on-appear are recorded in
`oracle-questions.tsv`.

`bash tests/acceptance/test_host.sh` is the supplied isolated gate. It is not
a claim that guest Foundation/UIKit dylibs were linked.
