# firefoxrowsprobe — UIToolbarDelegate / UIBarPosition and NSCollectionLayoutAnchor

Measures the two real BLOCKING UIKit rows of firefox-ios
(`full/ladder/gap-classes-2026-09-16.json`): `UIToolbarDelegate` (2 uses)
and `NSCollectionLayoutAnchor` (2 uses). `ios-26.1-iphone16.json` is the
unedited transcript from iPhone 16 / iOS 26.1 (3x, 393×852).

Run from `uikit/`:

```sh
SIM_DEVICE_SUFFIX=-firefox-blocking-rows scripts/firefox_rows_probe_sim.sh /tmp/ff
```

## Toolbar rows (`toolbar.*`, `barPosition.raw`, `navbar.pos`)

A 393×44 toolbar with `configureWithOpaqueBackground`, red background, blue
shadow and three items, added to a white root view at y 100.

| row | value |
| --- | --- |
| `UIBarPosition` raw any/bottom/top/topAttached | 0 / 1 / 2 / 3 |
| `barPosition` detached, no delegate | 1 (bottom) |
| `barPosition` detached, delegate answering `.top` | 1 — not asked yet |
| `position(for:)` calls after `delegate =` / detached read | 0 / 0 |
| calls after `addSubview` / `layoutIfNeeded` / second layout | 1 / 1 / 1 |
| `barPosition` in window for answer any / bottom / top / topAttached | 1 / 1 / 2 / 3 |
| delegate conforming without `position(for:)` | 0 calls, position 1 |
| bar object passed to the delegate | the `UIToolbar` itself |
| `UINavigationBar` default | 2 (top) |
| `sizeThatFits(393×0)` / `intrinsicContentSize` height | 48 / 48 (the port carries 54; not this row) |

Subview tree for every position: `UICoreHostingView<RootView>` with
`_UIInheritedView` platters at `[16, −2, 361, 48]`; no `_UIBarBackground`,
no shadow image view. `probe --hold <position>` keeps one bar on screen and
`simctl io screenshot` (render server) shows, for none/bottom/top/topAttached
alike, only the glass platters — at x 5 and x 196 every pixel between y 290
and 350 is white or the platter's grey. The red background and blue shadow
are not painted at all on iOS 26.1, so `barPosition` has no observable
pixel effect; the port stores the answer and paints nothing different.

## Anchor rows (`anchors.ltr.*`, `anchor.*`, `supp.defaults`)

A 300×600 collection; each section is one case: two items per row from
`horizontal(layoutSize: fractionalWidth(1) × absolute(100), subitem: <absolute 100×100 item>, count: 2)`
with 20 pt inter-item spacing, section insets 20/30/20/0, 40 pt between
sections. Item 0 of section s is `[30, 20 + 180 s, 125, 100]` (the count
overrides the item's absolute width). Badge size 20×20 unless noted.
`y` below is the item's minY.

| case | supplementary frame |
| --- | --- |
| `[.bottom]`, fractionalWidth(1) × 30 (firefox's title) | `[30, y+70, 125, 30]` |
| `[.top, .trailing]` | `[135, y, 20, 20]` — inside the corner |
| `[.top, .trailing]` fractionalOffset (0.5, −0.5) | `[145, y−10]` — fraction of the badge's 20 pt |
| `[.top, .trailing]` absoluteOffset (10, −10) | `[145, y−10]` |
| `[]`, `.all`, `[.leading, .trailing]` | `[82.667, y+40]` — centred; 82.5 snapped to thirds |
| `[.leading]` absoluteOffset (5, 5) | `[35, y+45]` |
| `[.bottom]` fractionalOffset (0, 0.5) | `[82.667, y+90]` |
| `[.top]` absoluteOffset (0, −7) | `[82.667, y−7]` |
| container `[.top, .trailing]`, item `[.bottom, .leading]` | `[155, y−20]` |
| … item `[.bottom, .leading]` absoluteOffset (3, 4) | `[158, y−16]` |
| … item `[]` fractionalOffset (0.5, 0.5) | `[155, y]` |
| item contentInsets 10, `[.top, .trailing]` | item `[40, y+10, 105, 80]`, badge `[125, y+10]` |
| `[.bottom, .trailing]`, fractionalWidth(0.5) × fractionalHeight(0.25) | `[92.667, y+75, 62.333, 25]` — 92.5 rounds up, maxX stays 155 |

Every supplementary: zIndex 1 (cells 0), index path (section, item),
`representedElementKind` "badge"; `layoutAttributesForElements(in: 0…200)`
returns badge+cell for items 0 and 1; contentSize 300×2660 — badges outside
the item do not grow the section.

Readback: `NSDirectionalRectEdge` top/leading/bottom/trailing/all =
1/2/4/8/15; `NSCollectionLayoutAnchor(edges:)` reads absolute with a zero
offset; `absoluteOffset:` / `fractionalOffset:` keep the point and flag;
`NSCollectionLayoutSupplementaryItem` zIndex 1, `itemAnchor` nil unless
given, `contentInsets` zero; `NSCollectionLayoutItem.supplementaryItems`
is 0 for a plain item and the array as given otherwise.

Thrown, and worth knowing: `NSCollectionLayoutGroup.horizontal(layoutSize:subitems: [item, item])`
where `item` carries a supplementary raises
`NSInternalInconsistencyException — Every supplementary must have a unique
elementKind: duplicates detected` from
`-[NSCollectionLayoutSection _checkForDuplicateSupplementaryItemKindsAndThrowIfFound]`.
The repeating `subitem:count:` form firefox uses is the legal one.

Not measured: RTL. The `anchors.rtl` rows (collection view with
`semanticContentAttribute = .forceRightToLeft`) are byte-identical to
`anchors.ltr`, items included — the forced attribute did not mirror this
layout at all on the oracle, so they say nothing about anchors under RTL.
The port mirrors `leading`/`trailing` and the x offset with its existing
`_layoutIsRTL` convention and labels that unmeasured.
