# `index.json` — the format OpenUIKit consumes, and the resolution rule

**This is a handover document.** `~/uikit` is read-only for agents, so
`UIImage(named:)` / `UIColor(named:)` reading this index is somebody else's
commit, through the gated oracle-suite process. What is specified here is
everything that side needs: the file layout, every field, the resolution
algorithm as a numbered procedure, and the cases where the right answer is to
**refuse** rather than return something.

Produced by:

    xcassets_tool.py index <app-dir-or-.xcassets> --out <dir>

    <dir>/index.json
    <dir>/Resources/<first-2-of-sha256>/<sha256><ext>

Payloads are **content-addressed**, so identical files across catalogs are
stored once, and "the name is the hash of the contents" is checkable by anyone
at any time (`roundtrip.py` does exactly that, in both directions).

---

## Top level

```jsonc
{
  "format": "openuikit-xcassets-index",
  "version": 1,
  "app": "NetNewsWire",
  "catalogs": ["iOS/Resources/Assets.xcassets", ...],   // relative to the app
  "resources_dir": "Resources",
  "assets":         { "<name>": <Asset> },   // resolvable
  "unresolved":     { "<name>": <Unresolved> },
  "collisions":     { "<name>": [ {"contents": "...", "record": <Asset>} ] },
  "folder_orphans": [ <Payload> ],
  "stats":          { ... }                  // denominators, for gates
}
```

### `assets` — everything a lookup may return

```jsonc
"accountCloudKit": {
  "type": "imageset",                     // imageset | colorset | appiconset | dataset | symbolset
  "properties": { "preserves-vector-representation": true,
                  "template-rendering-intent": "template" },
  "variants": [ <Variant> ],
  "orphan_files": [ <Payload> ]           // present only if the directory had unnamed files
}
```

### `Variant` — image-like (`imageset`, `appiconset`, `dataset`, `symbolset`)

| field | | |
|---|---|---|
| `payload` | `<Payload>` | the file |
| `idiom` | `universal` \| `iphone` \| `ipad` \| `watch` \| `tv` \| `mac` \| `car` \| `vision` \| `ios-marketing` \| `watch-marketing` | |
| `appearance` | `any` \| `light` \| `dark` \| `tinted` | **`any` is not `light`.** An entry with no `appearances` key is `any`; 11 entries in 3 apps say `light` explicitly |
| `scale` | `1` \| `2` \| `3` \| **`null`** | `null` means the entry declares no scale — **4,758 image entries in the corpus, 43% of all of them.** It matches any requested scale |
| `screen_width`, `language_direction`, `height_class` | string or `null` | rare: 100 / 14 / 2 uses |
| `resizing` | object or `null` | `{mode, center, cap_insets, insets_spelling}`; **both `cap-insets` and `capInsets` occur in the wild** and are normalised here |
| `size`, `role`, `subtype`, `platform` | appiconset only | |

### `Variant` — `colorset`

| field | | |
|---|---|---|
| `idiom`, `appearance` | as above | |
| `native` | `[r,g,b,a]`, or `[white,a]` for `gray-gamma-22` | components in the file's **own** colour space, decoded to 0..1 |
| `color_space` | `srgb` \| `display-p3` \| `extended-srgb` \| `gray-gamma-22` | |
| `srgb` | `[r,g,b,a]` | **derived convenience, see the warning below** |
| `conversion` | string | how `srgb` was obtained |
| `encodings` | `{"red":"hex", "alpha":"float", ...}` | which of the four encodings each component used |
| `reference` | string, and `srgb` is `null` | a **system** colour (`systemBackgroundColor`, `labelColor`); 14 variants in 5 apps |

> **`native` is authoritative; `srgb` is a convenience.** Measured against
> `actool`: it stores `display-p3` components **unconverted**, under
> `Colorspace: "p3"`. So `native` is what Apple's compiler agrees with (510
> colorsets, checked), and the `srgb` field is this tool's own P3→sRGB and
> gray-gamma-22→sRGB conversion, which the oracle **cannot** corroborate. A
> consumer that has a colour-managed pipeline should use `native` +
> `color_space`; one that does not should use `srgb` and know that it is a
> conversion someone chose.

### `Payload`

```jsonc
{ "sha256": "…", "bytes": 12345, "ext": ".pdf",
  "filename": "icloud-dark.pdf",              // the ORIGINAL basename
  "file": "ab/abcdef….pdf" }                  // under resources_dir
```

### `unresolved` — asks must REFUSE, not guess

```jsonc
"App Icon & Top Shelf Image": {
  "type": ".brandassets",
  "reason": "asset type outside the covered set",
  "nested_asset_dirs": {".imageset": 2, ".imagestack": 2},
  "files": [ <Payload> ]
}
```

`reason` is one of:

* `asset type outside the covered set` — `.sticker`, `.imagestack`,
  `.brandassets`, `.complicationset`, `.launchimage`, … (15 roots, 97 nested)
* `asset directory nested inside another asset directory` — 3 in the corpus,
  all firefox-ios `.imageset`-inside-`.imageset`

**A lookup that lands here must raise, naming the type.** The bytes are kept so
nothing is lost; the resolution is not offered because it was never verified.

### `collisions` — both definitions, no winner picked

624 asset names in the corpus are defined by more than one catalog in the same
app (`AppIcon` most of all). Which one wins at runtime depends on bundle search
order, which the index cannot know. **Both records are kept in full.** A
consumer should apply its own bundle order and, if it has none, refuse.

---

## The resolution algorithm

Given a name and a trait environment `(scale, appearance, idiom)`:

1. **Name.** If in `assets`, continue. If in `unresolved`, **refuse**, naming
   `reason`. If in `collisions` and not `assets`, that cannot happen — a
   collision always has a winner in `assets`; consult `collisions` only if you
   need the other definitions.

2. **Idiom.** Take variants whose `idiom` equals the requested one. If none,
   take `universal`. If still none, **no match**. An idiom that is neither the
   requested one nor `universal` is never a candidate.

3. **Appearance.** Take variants whose `appearance` equals the requested one.
   If none, take `any`. **`light` and `dark` never substitute for each other**
   — falling back from `dark` to `light` is a wrong render, not a near miss.

4. **Scale.** Exact match wins. Otherwise the **largest scale below** the
   request, then the **smallest above**, then any variant with `scale: null`. A
   `null`-scale variant is ranked last so an explicit match always beats it.

   > **CORRECTED 2026-08-28 BY MEASUREMENT (#82).** This step used to say
   > *smallest above, then largest below*, reasoning that downscaling a larger
   > asset beats upscaling a smaller one. That argument is plausible and it is
   > **not what UIKit does**. An asset carrying only 1x and 3x, asked at 2x on
   > both an iPhone and an iPad, gets the **1x** payload from
   > `UIImage(named:)`; the old rule returned 3x. Four rows, one rule, and
   > `EXPECTED_RESOLUTION.md` named it in advance as the likeliest divergence
   > in the run.
   >
   > Scope of the evidence, which is narrower than the rule: the only
   > observable fall-**up** case is `{1x,3x}` asked at 2x, because no 1x
   > simulator device exists and a 3x ask against `{1x,2x}` falls down either
   > way. "Largest below" is confirmed in both directions that could be
   > observed; "smallest above" is now the last resort rather than the first
   > choice, and remains unobserved.

5. Return the first remaining variant.

`xcassets_tool.py resolve` implements exactly this and prints its trace:

```
$ xcassets_tool.py resolve index.json accountCloudKit --scale 2 --appearance dark
   idiom=universal -> 2 (exact 0, universal 2)
   appearance=dark -> 1 (exact 1, any 1)
   scale=2 -> scaleless
   { "payload": { "filename": "icloud-dark.pdf", ... }, "scale": null, ... }
```

### What the oracle says about this — UPDATED, #82 closed the gap

`actool` + `assetutil` establish that the reader's **variant table** matches
Apple's — every `(name, scale, idiom, appearance, filename)` tuple (#79).

**Steps 1–4 are now measured too (#82).** `UIImage(named:in:compatibleWith:)`
was run against a compiled fixture in three simulator devices (2x phone, 3x
phone, 2x pad) and the returned image identified against every candidate
payload: **234 of 234 image rows and 90 of 90 colour rows choose what UIKit
chooses.** The correction in step 4 above is what that run bought.

Two limits remain, and they are limits of the vehicle rather than of the
result:

* **1x is unreachable** — no 1x simulator device exists — so a 1x request has
  never been observed.
* **`scale: null` variants** were exercised at 2x and 3x only.

---

## Worked example — `accountCloudKit` from NetNewsWire

Source (`iOS/Resources/Assets.xcassets/accountCloudKit.imageset/Contents.json`):

```json
{ "images": [
    { "idiom": "universal", "filename": "icloud-any.pdf" },
    { "idiom": "universal", "filename": "icloud-dark.pdf",
      "appearances": [ { "appearance": "luminosity", "value": "dark" } ] } ],
  "info": { "author": "xcode", "version": 1 },
  "properties": { "preserves-vector-representation": true,
                  "template-rendering-intent": "template" } }
```

Index:

```jsonc
"accountCloudKit": {
  "type": "imageset",
  "properties": { "preserves-vector-representation": true,
                  "template-rendering-intent": "template" },
  "variants": [
    { "idiom": "universal", "appearance": "any",  "scale": null,
      "payload": { "filename": "icloud-any.pdf",  "file": "…/….pdf", … } },
    { "idiom": "universal", "appearance": "dark", "scale": null,
      "payload": { "filename": "icloud-dark.pdf", "file": "…/….pdf", … } } ]
}
```

Note **`scale: null` on both** — the source declares no scale, which is the
common case, not the exception. `actool` compiling this catalog emits
renditions at 1x, 2x and 3x from each PDF; the source form has one entry each,
and the reader is right not to invent the other two.

Lookups:

| request | result |
|---|---|
| `(2, light, phone)` | `icloud-any.pdf` — no `iphone` idiom, so `universal`; no `light`, so `any`; scaleless |
| `(2, dark, phone)` | `icloud-dark.pdf` — exact appearance |
| `(3, dark, pad)` | `icloud-dark.pdf` — scale is irrelevant for a scaleless variant |

---

## Checklist for the OpenUIKit side

- [ ] `UIImage(named:)` → steps 1–5; **raise** on `unresolved`.
- [ ] `UIColor(named:)` → same steps; **raise** on a `reference` variant,
      because the system palette is not in the catalog and `actool` resolving
      it is not something this index can reproduce. Which field to use is now
      measured against `UIColor`, and it depends on the space:
      - `srgb` / `extended-srgb` → **`native`** (UIKit reports it unchanged)
      - `display-p3` → **`srgb`**. `UIColor.getRed:green:blue:alpha:` converts
        out of P3 while `cgColor.colorSpace` still reports DisplayP3, and it
        agrees with this index's conversion to **~3e-5** on every P3 colour in
        the corpus. #79 said no oracle could corroborate that conversion; one
        can, and it does.
      - `gray-gamma-22` → **`native`**, replicating `white` into R, G and B.
        UIKit does **not** gamma-convert: for `white = 0.9` it reports
        `0.9, 0.9, 0.9`, while this index's `srgb` conversion gives
        `0.902873`. Neither is wrong — one is a colour-managed conversion, the
        other is component reporting — but a consumer that wants to **match
        UIKit** must use `native` here.
- [ ] `template-rendering-intent: "template"` (2,452 uses in 16 apps) means the
      image is a tinting mask — carry it through to `UIImage.renderingMode`.
- [ ] `resizing` (11 uses in 3 apps) is `UIImage.resizableImage(withCapInsets:)`.
- [ ] Vector payloads are `.pdf` (and `.svg` for symbolsets). If the consumer
      cannot rasterise PDF, that is a **named gap**, not a fallback to nothing.
- [ ] Bundle order for `collisions` is the consumer's to decide, and to state.
      **Measured (#82), for the one case the index cannot answer from source:**
      when two catalogs defining the same name are compiled together, `actool`
      emits **one** rendition — the one from the catalog listed **first** on its
      command line — and `UIImage(named:)` returns that one. So the winner is
      decided at *build* time by catalog order, not at runtime by bundle
      search. A consumer reproducing Xcode's behaviour should apply its own
      catalog order and take the first definition.
- [ ] **`.unspecified` is not a state to plan for.** Asked with
      `userInterfaceIdiom = .unspecified`, UIKit substitutes the **device's**
      idiom rather than falling back to `universal` — measured on 36 rows. A
      real app's trait collection always carries phone, pad or mac, so step 2
      never sees `.unspecified`; a consumer that synthesises trait collections
      should fill in the device idiom rather than leaving it unset.
