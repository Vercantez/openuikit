# MediaPlayer (Linux starting point)

This directory is a fail-closed portable `MediaPlayer` module for the OpenUIKit
Linux platform. It reconstructs a substantial subset of the public Xcode 26.1
iPhoneOS Swift surface from the sealed symbol graph. It is not wired into the
shared guest package.

**Provenance:** the legacy fan-out branch
`cursor/port-mediaplayer-to-linux-9de2` (platform PR #11, ~2564 Swift lines)
could not be fetched: this run's GitHub App token only installs
`Vercantez/openuikit`. This tree is therefore a seed-based deliverable that
follows `FANOUT_TASK.md` and the in-repo PR #11 repair brief
(`full/framework-fanout/repairs-wave1-pr10-18.json`). It is not a byte-copy of
the inaccessible branch.

**Reference dossier:** kept the monorepo `full/mediaplayer/reference/`
(generator `scripts/framework-fanout/generate_seed.py`, SHA256
`2b8230ced5a3ed78f070607346f6a684d9e0fb74a8932b92bc0f5e38f46f0a8e`,
iPhoneOS 26.1 / Xcode 17B55). The platform branch `reference/` could not be
compared (`unavailable`).

## What is real

- Enums and option sets compile and are distinct. Option-set bits follow public
  Apple documentation and are Linux-local, not SDK-extracted.
- `MPError` is a typed error with `~=` matching. `errorDomain` is the
  Linux-local string `MPErrorDomain`.
- `MPMediaLibrary.authorizationStatus` is `.denied`. `requestAuthorization`
  hops asynchronously and never prompts.
- `MPMediaQuery` stores predicates and grouping; `items` / `collections` are
  empty. `MPMediaItem` property getters are inert empties.
- `MPMusicPlayerController.play()` does not invent a playing session.
  `prepareToPlay(completionHandler:)` completes asynchronously with
  `MPError.notSupported`.
- `MPNowPlayingInfoCenter` stores a process-local dictionary. Animated artwork
  keys are empty.
- `MPRemoteCommandCenter` records handler closures. Commands never fire unless
  a host injects `@_spi(OpenUIKitHost) openuikit_invoke`.
- `MPPlayableContentDataSource` / `MPPlayableContentDelegate` optional
  Objective-C methods are protocol requirements with extension defaults so
  existential dispatch honors conformer overrides (PR #11 repair). Defaults
  fail closed (`notFound` / `notSupported`). `MPPlayableContentManagerContext`
  reports no CarPlay endpoint.

## Fail-closed / omitted

- No UIKit types: `MPMediaItemArtwork`, `MPVolumeView`, picker/view-controller
  types, and any API whose declaration needs `UIImage`, `CGSize`, `CGRect`, or
  `UIView` are omitted (`unavailable`).
- `AVPlayer` Now Playing session members and `CMTimeRange` ad ranges are
  omitted.
- Objective-C `Selector` command targets are unavailable on this toolchain.
- Volume-settings alerts never become visible.
- String constants (`MPMediaItemPropertyTitle`, notification names, …) are
  Linux-local identities equal to the Swift name, not claimed Apple NSString
  bytes.

## Tests

`tests/agent/MediaPlayerRuntime.swift` prints `MEDIAPLAYER_AGENT_RUNTIME_OK`.

`tests/agent/MediaPlayerDependencyIdentity.swift` is a future EC2 probe
(`MEDIAPLAYER_DEPENDENCY_IDENTITY_OK`) against real guest Foundation (and
CoreGraphics once artwork exists).
