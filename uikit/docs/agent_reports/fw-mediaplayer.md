# fw-mediaplayer — MediaPlayer corpus surface

Worktree `agent/fw-mediaplayer`. SDK depth in `full/mediaplayer/` (895 IDs).
No scene pixel rule.

## Before / after

| | before | after |
|---|---|---|
| implemented | 255 | **869** |
| declared | 482 | 0 |
| deferred | 100 | **5** |
| unavailable | 58 | **21** |
| now-playing / remote-command / media-item / query / music-player | mixed deferred | **nondeferred** |

Oracle: `/tmp/mp_oracle.json`, `com.openuikit.mporacle`, iPhone SE 3rd gen
2x / iOS 26.1 (`OpenUIKit-2x-fw-mediaplayer`). Isolated gate
`bash tests/acceptance/test_host.sh` → `MEDIAPLAYER_AGENT_RUNTIME_OK`.

Pixel gates (no MediaPlayer scene rule; floors must not drop): Catalyst
**124/124**; iOS suite **112/113** (known `corner_radius`); real-app
**99.137 / 98.535 / 98.548 / 99.469 / 98.639 / 98.133 / 97.516 / 99.511 /
82.170 / 99.760 / 99.689 / 85.393**. Linux `swift:6.2-noble` openrender
release build green.

## Measured rules (cited next to the constants)

- `MPErrorDomain` = `MPErrorDomain`; `MPError.Code` 0…7 with `notSupported=5`.
- `MPRemoteCommandHandlerStatus`: 0 / 100 / 110 / 120 / 200.
- `MPNowPlayingPlaybackState`: unknown=0, playing=1, paused=2, stopped=3, interrupted=4.
- `MPMusicPlaybackState`: stopped=0 … seekingBackward=5.
- Player rest: `repeatMode=.none` (1), `shuffleMode=.off` (1), `currentPlaybackRate=0`. Empty `play()` stays stopped.
- `MPMediaItemPropertyTitle` = `title`, `…AlbumPersistentID` = `albumPID`, playlist name = `name`, author = `externalVendorDisplayName`.
- `MPNowPlayingInfoPropertyCurrentLanguageOptions` Darwin bytes are singular `…LanguageOption`.
- Language characteristics are `public.main-program-content` etc.
- Notification names end in `Notification`.
- `supportedAnimatedArtworkKeys` = `[MPNowPlayingInfoProperty3x4AnimatedArtwork]`.
- Skip intervals default `[10]`; rating min/max 0.
- Unauthorized `MPMediaQuery.items` is `nil`. `canFilter` true for title/artist/…, false for artwork/lyrics/duration (item class); entity class only `persistentID`.
- `MPVolumeView()` frame `.zero`, `showsRouteButton=false`, `showsVolumeSlider=true`.
- Picker: `allowsPickingMultipleItems=false`, `showsCloudItems=true`, `showsItemsWithProtectedAssets=true`.
- Artwork `init(boundsSize: 100×80)` bounds `(0,0,100,80)`; `image(at: 50×40)` returns 50×40.

## Still open (oracle-questions.tsv)

AVPlayer now-playing overlays, animated-artwork 1×1 geometry, volume route-button rect vs bounds, automatic language-option identities, `indexOfNowPlayingItem` vs NSNotFound on a signed-in device.

## Out of scope / unavailable

`MPAdTimeRange` (CMTimeRange), `AVPlayer` session players, `MPMediaItemAnimatedArtwork`, movie-player `view`/thumbnail/`MPMoviePlayerViewController`, NSUserActivity media identifier.
