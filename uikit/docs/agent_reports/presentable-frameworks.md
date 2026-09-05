# Presentable frameworks — SafariServices, MessageUI, LinkPresentation

Ninth conformance app `Sources/ConformanceApps/Present/` plus three SwiftPM
targets under `Sources/` so unchanged app source can `import SafariServices`,
`import MessageUI`, and `import LinkPresentation`. Chrome is painted under
the iOS cut from PresentProbe captures on iPhone SE 2x (`OpenUIKit-2x-presentable-frameworks`)
and iPhone 16 3x (`OpenUIKit-Chrome-presentable-frameworks`) / iOS 26.1.
Catalyst and the macOS font cut stay a plain white `SFSafariViewController`
so fixture goldens do not move.

## Corpus surface (grep `scratch/ladder-corpus`)

| module | apps | symbols covered |
|---|---|---|
| SafariServices | 16 | `SFSafariViewController.init(url:)`, `init(url:configuration:)`, `Configuration.entersReaderIfAvailable` / `barCollapsingEnabled`, `dismissButtonStyle` (`.done` / `.close` / `.cancel`), `SFSafariViewControllerDelegate` (`didFinish`, `didCompleteInitialLoad`), `SSReadingList.default()?.addItem`, `SFContentBlockerManager.getStateOfContentBlocker` / `reloadContentBlocker`, `SFContentBlockerState.isEnabled`, `SFAuthenticationSession.start()` |
| MessageUI | 12 | `MFMailComposeViewController` (`UINavigationController`), `canSendMail`, `setToRecipients`, `setSubject`, `setMessageBody`, `addAttachmentData`, `setBccRecipients`, `mailComposeDelegate`, `MFMailComposeResult`; `MFMessageComposeViewController`, `canSendText`, `recipients`, `body`, `messageComposeDelegate`, `MessageComposeResult` |
| LinkPresentation | 6 | `LPLinkMetadata.title` / `url` / `originalURL` / `imageProvider` / `iconProvider`; `LPMetadataProvider.startFetchingMetadata` (URL + `URLRequest` completion, async URL); `shouldFetchSubresources`; `LPLinkView` (brief requires paint; almost no app constructs one) |

Everything else fails closed and is listed under OPEN.

## Measurements

### SFSafariViewController

`data:` and `file:` URLs throw `NSInvalidArgumentException`. Probe used
`http://127.0.0.1/` (no external net; page fails; chrome still paints).

| | SE 2x | iPhone 16 3x |
|---|---|---|
| `modalPresentationStyle` | rawValue 0 = `.fullScreen` | same |
| view | `[0,0,375,667]` | `[0,0,393,852]` |
| `safariSafeArea` | `[0,0,0,0]` (status bar hidden) | `[59,0,34,0]` |
| dismiss (checkmark, 44 pt circle) | `(16, 8, 44, 44)` | `(16, 67, 44, 44)` = `(16, SA.top+8, 44, 44)` |
| back (chevron, 48 pt circle) | y **603** | y **786** = `H − max(16, SA.bottom − 16) − 48` |
| trailing capsule | height 48, trailing 16, width **174** pt (3x peak 174.33) | same rule |

Chrome lives in a remote `_UISceneHostingView` — no dumpable button frames;
geometry is from the PNG plus those two view frames. **No address field**
when the page fails to load (OPEN: may appear only with a real host/title).

`.done` = harvested `checkmark`. `.close` / `.cancel` glyphs were not on
the PNG (element-ios / Pocket Casts set the style); `xmark` is used and
listed OPEN. Capsule icons: `square.and.arrow.up`, `arrow.clockwise`,
`safari`.

### MFMailComposeViewController

`canSendMail() == false` on the simulator (`mail.flag`, 17 bytes
`canSendMail=false`). `present` hung ~40 s with no completion. After a hung
present, `drawHierarchy(afterScreenUpdates: true)` can wedge the sim.

**Do not present mail on the simulator.** The compose Cancel/Send pixels
are unobserved. The port still paints a form from already-measured nav-bar
title items and grouped-table fill (`systemGroupedBackground`, Forms t200)
if an app presents anyway. The Present app shows the boolean on the root
and never presents.

`canSendText()` is the same class of capability query and is also false
(unmeasured Messages service; fail closed).

### LPLinkView

Constrained width 343 (= 375−32), iPhone SE 2x / iOS 26.1
(`link.layout.json` after `linkplain`; with-image numbers from the PNG
before that overwrite).

| | no image (`linkplain`) | with image (`link.png`) |
|---|---|---|
| size | 343×53 | 343×53 |
| `LPFlippedView.cornerRadius` | 10 | 10 |
| intrinsic | (186, 53) | (186, 53) |
| card fill | **(0.915, 0.915, 0.920, 1)** = RGB (233, 233, 235) — not `systemGray6` | **(0.004, 0.48, 0.90, 1)** ≈ RGB (1, 122, 230) |
| image slot | `LPImageView` 30×30 at `(301, 11.5)`; inner `UIImageView` cornerRadius 3, imageSize 20×19 | 30×30 photo in the same slot |
| title | `.SFUI-Semibold` 15, `(16, 8, 269, 18)`, text "Example Article" | same frames, white on blue |
| host | `.SFUI-Regular` 13, `(16, 28, 269, 16)`, text **`example.com`** (`URL.host`, not the full URL) | same frames |

Present builds metadata by hand (title + URL only) so Linux compiles
without `NSItemProvider`. A non-nil `imageProvider` (Darwin) selects the
blue card; the async bitmap is OPEN.

## Rules (iOS cut)

1. **Safari is fullScreen.** `modalPresentationStyle = .fullScreen`
   (rawValue 0). Guard: always, matching both devices.
2. **Dismiss platter** `(16, SA.top + 8, 44, 44)` using `_UIBarMetrics.platterHeight`
   and `sideMargin`. Guard: `OpenUIKitRuntime.systemFontCut == .iOS`.
3. **Toolbar platters** `y = H − max(16, SA.bottom − 16) − 48`. Back is
   48×48 at x=16; trailing capsule 174×48. Guard: same iOS cut. Catalyst
   paints no chrome.
4. **LPLinkView** height 53, cornerRadius 10, title/host/image frames from
   the table, plain fill RGB (233, 233, 235). Guard: paint always (no
   Catalyst golden uses `LPLinkView`); compact blue fill only when
   `imageProvider != nil`.
5. **`canSendMail()` / `canSendText()`** return false.

## Before / after

| | before | after |
|---|---|---|
| modules | none; 16+12+6 apps cannot `import` | three SPM products, corpus API |
| Safari chrome | — | SE dismiss `(16,8,44,44)`, back y=603, capsule 174×48; iPhone 16 dismiss y=67, back y=786 |
| Mail | — | `canSendMail()==false` (measured); form paint unobserved |
| LPLinkView | — | 53×W, r=10, title/host frames match `link.layout.json` |
| conformance apps | 8 | 9 (`Present`) |
| Catalyst | 124/124 | 124/124 (no fixture scenes added; iOS chrome is cut-guarded) |
| iOS suite | 112/113 (`corner_radius`) | 112/113 |
| unit tests | — | `PresentableFrameworksTests` 9/9; `ConformanceRegistryTests` 8/8 |

## OPEN

- Address field on `SFSafariViewController` when a page actually loads.
- `.close` / `.cancel` dismiss glyphs (only `.done` = checkmark was captured).
- iOS 26 glass mix on the remote safari platters (geometry uses
  `_UIBarMetrics.platterFill`).
- Mail Cancel/Send pixels (`canSendMail` false; present hung).
- `LPLinkView` host-label grey RGB (dump has no `textColor`; `.secondaryLabel`).
- `NSItemProvider` image/icon bitmaps (async on Darwin; absent on Linux).
- `LPMetadataProvider.shouldFetchSubresources` Darwin default (stored false).
- `preferredBarTintColor` / `ActivityButton` / Reading List persistence /
  content-blocker enablement / `SFAuthenticationSession` start (fail closed;
  not in the paint table).

## Files

- `Sources/SafariServices/SafariServices.swift`
- `Sources/MessageUI/MessageUI.swift`
- `Sources/LinkPresentation/LinkPresentation.swift`
- `Sources/ConformanceApps/Present/`
- `Sources/ConformanceApps/Registry.swift` (regenerated, 9 apps)
- `Tests/OpenUIKitTests/PresentableFrameworksTests.swift`
- `Package.swift` products + targets
