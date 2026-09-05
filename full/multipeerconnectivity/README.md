# MultipeerConnectivity

Linux starting point for Apple's public `MultipeerConnectivity` module from the
Xcode 26.1 iPhoneOS seed (132 exact public identifiers). This directory is not
wired into the shared guest package. A passing isolated host gate is not
integrated Linux success.

Corpus ranking (`reference/corpus-summary.json`): Signal-iOS Device Transfer
uses advertiser, browser, peer ID, and session files. Those families were
finished first. Isolated Linux has no Bonjour/AWDL stack, so discovery and
session transport stay fail-closed.

## What is real

The public Swift surface compiles to `libMultipeerConnectivity.dylib`.

Binding-sourced constants (pinned `dotnet/macios` Native / Field values):

- `MCErrorDomain == "MCErrorDomain"`
- `kMCSessionMinimumNumberOfPeers == 2`
- `kMCSessionMaximumNumberOfPeers == 8`
- `MCEncryptionPreference`: optional=0, required=1, none=2
- `MCSessionSendDataMode`: reliable=0, unreliable=1
- `MCSessionState`: notConnected=0, connecting=1, connected=2
- `MCError.Code`: unknown=0 through unavailable=6 (timedOut=4, cancelled=5)

Also implemented:

- `MCPeerID` with a nonempty `displayName`; `NSSecureCoding` decode fails closed
- `MCSession` local configuration (`myPeerID`, `encryptionPreference` default
  `.optional`, `securityIdentity` storage, empty `connectedPeers`)
- `MCNearbyServiceAdvertiser` / `MCNearbyServiceBrowser` /
  `MCAdvertiserAssistant` stored properties
- `MCBrowserViewController` as an `NSObject` host on isolated Linux (Darwin
  subclasses `UIKit.UIViewController`); min/max peers clamp to 2...8
- Fail-closed `send`, `startStream`, `sendResource`, `nearbyConnectionData`
- Advertiser/browser start failures delivered on the caller thread exactly once

## Fail-closed boundaries

Linux has no Bonjour/AWDL stack, peer invitation UI, or encrypted nearby
session. The implementation never fabricates a connected peer, discovered peer,
invitation presentation, resource transfer, or stream.

- `connectedPeers` stays empty. `connectPeer` / `cancelConnectPeer` /
  `disconnect` / `invitePeer` do not change session membership and do not
  invent `MCSessionDelegate` state callbacks.
- `send` throws `MCError.notConnected` (empty peer list throws
  `MCError.invalidParameter`). `startStream` throws `MCError.notConnected`.
- `sendResource` returns `nil` and invokes its completion on the caller with
  `MCError.notConnected`.
- `nearbyConnectionData(forPeer:)` (ObjC completion-handler form and the Swift
  async overlay) fails with `MCError.unavailable` on the caller thread.
- `startAdvertisingPeer` / `startBrowsingForPeers` call the optional
  `didNotStart*` delegate with `MCError.unavailable` on the caller thread.
  They never call `foundPeer` / invitation handlers.
- `MCAdvertiserAssistant.start()` is inert: no invitation UI.
- `MCPeerID.init(coder:)` returns `nil`. Encode writes no guessed Apple archive
  keys.
- `MCBrowserViewController` never presents a peer list. Isolated Linux does
  not subclass `UIKit.UIViewController` (no UIKit module in the host gate).

Delegate methods that Darwin would fire for certificates, invitations, found
peers, and browser finish/cancel are implemented and test-callable. Linux
never produces those Apple events.

## Depth pass 2026-09

Coverage before this pass: **109 implemented / 11 declared / 12 deferred /
0 unavailable / 0 not-applicable**.

Coverage after: **132 implemented / 0 declared / 0 deferred / 0 unavailable /
0 not-applicable**.

Raised from `declared`: session, advertiser, browser, and advertiser-assistant
delegate methods that Linux never fires; tests invoke them through existentials
and assert documented defaults (certificate handler refuses; `shouldPresent`
defaults to true).

Raised from `deferred`: `MCBrowserViewController` and
`MCBrowserViewControllerDelegate` as an `NSObject` host with documented
peer-limit clamping. UIKit inheritance remains an identity question for a
guest UIKit build.

Top-5 evidence distribution (implemented rows):

1. `MCErrorAndConstantsTests.swift#testMCEnumRawValuesAndConstants` — 38 (28.8%),
   table-driven enum/option-set members and `k…` constants
2. `MCErrorOverlayTests.swift#testMCErrorStructAndNSErrorBridging` — 22 (16.7%)
3. `MCAdvertiserAssistantTests.swift#testMCAdvertiserAssistantConfiguration` — 7 (5.3%)
4. `MCNearbyAdvertiserTests.swift#testMCNearbyServiceAdvertiserConfiguration` — 7 (5.3%)
5. `MCSessionTests.swift#testMCSessionInitAndProperties` — 7 (5.3%)

## Still open

See `oracle-questions.tsv` for Darwin error mapping, archive keys, callback-queue
identity, and UIKit `MCBrowserViewController` inheritance. Identity probe
`tests/agent/MultipeerConnectivityDependencyIdentity.swift` is prepared for a
future clean EC2 run that builds guest Foundation and UIKit first.

Run `bash tests/acceptance/test_host.sh` from this directory. Keep generated
products out of the tree.
