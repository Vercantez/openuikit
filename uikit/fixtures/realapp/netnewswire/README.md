# NetNewsWire app bundle inputs for the guest

The Linux guest has no `ibtool`, `actool` or Xcode resource pipeline.
Eidolon's checked-in nibs set the pattern followed here:
- the files Xcode *compiles* are checked in;
- the files Xcode *copies* are staged from the pinned corpus at build time.

## `compiled/`

Copied byte for byte from Xcode 26.1's Debug-iphonesimulator product of
unmodified NetNewsWire (`scratch/ladder-corpus` PINS.txt:
3b378e72f877f86258b2d04e1601719f9d0036a7). It holds:
- the storyboards (`Base.lproj/*.storyboardc` and the four feature
  storyboards) and the three xibs;
- the English string tables compiled from `DefaultAccountNames.xcstrings`;
- the four keyboard-shortcut plists, which Xcode converts to binary;
- the two app icons actool renders;
- `Info.plist` as Xcode processed it, which carries the scene manifest;
- `PkgInfo`.

The iOS simulator route (route (b)) builds its bundle from the same Xcode
product.

## `resources.json`

The 40 resources Xcode copies verbatim, each mapped to its corpus path with
the SHA-256 both sides share. Examples are the themes, `DefaultFeeds.opml`,
the article template HTML/CSS/JS, the RTFs and `ContentRules.json`. A stager
copies each one and refuses a hash mismatch.

These are not in either list and are built separately:
- the SwiftPM resource bundle `ActivityLog_ActivityLog.bundle`
  (uikit/Tools/nnwguest);
- the asset catalog index. OpenUIKit reads the source `Assets.xcassets`
  through `full/xcassets/xcassets_tool.py`, not `Assets.car`.
