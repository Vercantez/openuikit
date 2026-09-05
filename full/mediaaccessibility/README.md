# MediaAccessibility (Linux starting point)

This directory is a clean-room Linux starting point for Apple's public
`MediaAccessibility` module, seeded from the Xcode 26.1 iPhoneOS 26.1
symbol graph, API digester, TBD exports, and pinned `dotnet/macios`
bindings. It is not wired into the shared guest package.

Linux has no Accessibility Settings daemon, caption profile store,
IOSurface flashing-lights processor, Apple Music haptic tracks, or
ImageIO IPTC writer. Those paths fail closed. Caption appearance enums,
selected languages, display type, and profile IDs are a process-local
state machine.

## What is real

- `MACaptionAppearance*` enums with exact `CFIndex` raw values from pinned
  macios `MAEnums.cs` (`default`/`user` 0/1, `forcedOnly`/`automatic`/
  `alwaysOn` 0/1/2, `useValue`/`useContentIfAvailable` 0/1, font styles
  0…7, text edge styles 0…5). Failable `init(rawValue:)`, `==`/`!=`,
  `hashValue`, and `hash(into:)` are exercised.
- Process-local selected languages, display type, `isCustomized`, and
  profile IDs. `AddSelectedLanguage` rejects an empty tag, round-trips
  BCP-47 strings, and posts
  `kMACaptionAppearanceSettingsChangedNotification` on
  `NotificationCenter.default`.
- `ExecuteBlockForProfileID` temporarily makes the given profile active
  for the duration of the block, then restores the previous identifier.
- Color / opacity / character-size / text-edge / window-radius getters
  return the process-local defaults (white foreground, black background,
  opacities 1/0/0, size 1, edge `.undefined`, radius 0) and write
  `.useValue` into a non-nil behavior pointer.
- `MAFlashingLightsProcessor.OptionKey` is a `String` newtype with both
  `init(rawValue:)` and `init(_:)`.
- `MAMusicHaptics` is constructible. `MAMusicHapticsManager.shared` exists
  and `isActive` is `false`.

## Fail-closed boundaries

- `MADimFlashingLightsEnabled()` is `false`. No system setting is read.
- `canProcessSurface` is `false`. `processSurface` returns
  `Result(surfaceProcessed: false, intensityLevel: 0, mitigationLevel: 0)`
  and never claims to rewrite an `IOSurface`.
- `checkHapticTrackAvailabilityForMedia` invokes the optional completion
  synchronously with `false`. Status observers are stored and never fired.
- `MAImageCaptioningCopyCaption` / `SetCaption` return nil / `false` and
  write `MAImageCaptioningErrorDomain` (`unsupported` or `invalidURL`).
  `CopyMetadataTagPath` returns the process-local ImageIO path
  `{IPTC}:{Caption/Abstract}`.
- Isolated-host `CGColor`, `IOSurfaceRef`, and `CTFontDescriptor` are
  module-local stand-ins so the sealed Linux compile can type-check the
  public signatures. They are not CoreGraphics / CoreText ABI.
  `tests/agent/MediaAccessibilityDependencyIdentity.swift` imports the real
  `CoreFoundation` and `CoreGraphics` modules for the later EC2 build.

## Depth pass 2026-09

Implemented rows: **102**. Declared: **0**. Nondeferred: **102 / 102**.

Top-5 implemented evidence distribution:

| Citations | Evidence |
| ---: | --- |
| 13 | `MACaptionAppearanceEnumTests.swift#testCaptionAppearanceFontStyleRawValues` |
| 11 | `MACaptionAppearanceEnumTests.swift#testCaptionAppearanceTextEdgeStyleRawValues` |
| 8 | `MACaptionAppearanceEnumTests.swift#testCaptionAppearanceDisplayTypeRawValues` |
| 7 | `MACaptionAppearanceEnumTests.swift#testCaptionAppearanceBehaviorRawValues` |
| 7 | `MACaptionAppearanceEnumTests.swift#testCaptionAppearanceDomainRawValues` |

Those five are table-driven enum-member / raw-value tests. After that
family is excluded, no remaining test exceeds 9.1% of the remaining
implemented rows (largest: `testFlashingLightsProcessorResultFields` at 4).

The sealed host gate was run as `bash full/mediaaccessibility/tests/acceptance/test_host.sh`
and ended:

```
FRAMEWORK_FANOUT_DELIVERABLE_OK module=MediaAccessibility lane=leaf-full symbols=102
FRAMEWORK_FANOUT_REFERENCE_OK
MEDIAACCESSIBILITY_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=MediaAccessibility dylib=libMediaAccessibility.dylib
```

`swiftc --version` is Swift 6.2.4 targeting `x86_64-unknown-linux-gnu`.
`.cursor/verify-cloud-environment.sh` does not print
`CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean` on this
snapshot (`scratch/ladder-corpus/focus-ios` is missing). That campaign token
is the host-inventory stamp; the sealed framework gate prints the four lines
above.
