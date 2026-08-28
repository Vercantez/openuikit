# Pre-registered expectations for the asset-catalog spot oracle

Committed **before `spot_oracle.py` is run over the corpus**, so the ordering is
checkable in `git log` rather than asserted here — the same discipline
`full/oracle-json/EXPECTED.md` used, and for the same reason: a pre-registered
expectation list is trusted precisely because nobody re-derives it, which makes
it exactly as dangerous as any other unchecked number.

---

## What the oracle is, and what it is not

`xcassets_tool.py` reads **source-form** `.xcassets`. The oracle is Apple's own
asset-catalog compiler:

    actool --compile <dir> --platform iphoneos --target-device iphone
           --target-device ipad --minimum-deployment-target 15.0 <catalog>
    assetutil --info <dir>/Assets.car

`assetutil` dumps every rendition `actool` produced with its `Name`, `Scale`,
`Idiom`, `Appearance`, **`RenditionName` (the source file basename)** and, for
colours, the resolved `Color components`. That is a genuine independent
implementation — closed-source, written by the vendor of the format — and it is
what makes this a differential test rather than a self-test.

**This is a stronger provenance than the JSON oracle had.** There, macOS's
`JSONDecoder` turned out to be the same swift-foundation source the port
compiles. Here nothing is shared: `actool` is not derived from this reader and
this reader is not derived from `actool`.

**`.car` remains out of scope as an INPUT.** It is used here only as an oracle's
output. The tool must never need it.

---

## P1 — the comparison is on tuples, not on files

For each catalog, compare the sets

    ORACLE:  {(Name, Scale, Idiom, Appearance, RenditionName)}   from assetutil
    TOOL:    {(name, scale, idiom, appearance, filename)}        from index.json

Scale is an integer; a tool variant with `scale: null` is compared against
whatever scale `actool` assigned it, because a scaleless entry is precisely the
case where the two might disagree.

**Not compared: pixel data, SHA1 digests, compression, colour model.** `actool`
recompresses and may re-encode; the reader copies bytes. Comparing them would
measure image codecs, not asset resolution.

## P2 — idioms outside the compiled device set are EXPECTED to be absent

`actool` compiles for the platform and devices it is told about. `watch`,
`tv`, `car`, `vision`, `watch-marketing` and `mac` renditions will not appear in
an `iphoneos` / iphone+ipad `.car`. **Rows the tool has with those idioms are
excluded from the comparison and counted separately**, never treated as
oracle-missing.

`ios-marketing` is also excluded: the 1024×1024 App Store icon is consumed by
the packaging step, not emitted as a rendition.

## P3 — appiconsets are compared by NAME ONLY

`actool` only emits app-icon renditions when told `--app-icon <name>`, and it
rewrites their names and roles when it does. Comparing 146 appiconsets'
variants would measure our knowledge of `actool`'s icon pipeline, not the
reader. **Their names must appear; their variants are not compared.** 1,218
image entries are in this class.

## P4 — symbolsets are excluded, by our own scope statement

27 symbolsets in 9 apps, all `.svg`, all `record-not-resolve`. The reader does
not claim to resolve them, so scoring them would be scoring a claim nobody
made.

## P5 — colours: NATIVE components, not the sRGB conversion

Measured on a synthetic probe catalog written for this purpose (`probe/`, not
corpus data): `actool` stores `display-p3` components **unchanged** under
`Colorspace: "p3"`. It does **not** convert to sRGB.

So the oracle checks the reader's **decoded native components** against
`Color components`, to 1e-6. The `srgb` field the index also carries — the
P3→sRGB and gray-gamma-22→sRGB conversions in `to_srgb()` — is a **convenience
for the consumer that `assetutil` cannot check**, and it is labelled as such
rather than reported as validated.

### P5a — the component encoding rule, and an honest note on its ordering

`xcassets_tool.py`'s `component_value()` states the rule in its own source and
calls it pre-registered: a value containing `.` is a float in 0..1, a value
starting with `0x` is hex/255, anything else is an integer/255. That rule was
written into the tool **before** any oracle was run, from the corpus census
alone.

It was then **confirmed on the synthetic probe before the corpus run**, not
blindly predicted through it, and saying so is the point: `{"red":"1",
"green":"123","blue":"199","alpha":"1.000"}` — NetNewsWire's shape, with an
integer triple beside a float alpha — compiles to
`[0.00392156…, 0.48235…, 0.78039…]`, i.e. `1/255`, `123/255`, `199/255`. The
corpus run therefore tests **whether the confirmed rule holds across 510
colorsets**, which is a weaker claim than a blind prediction and a real one.

## P6 — three `.imageset` directories nested inside another `.imageset`

firefox-ios ships `globeLarge.imageset/privateModeLarge.imageset` and two more
under `lightningFillLarge.imageset`. They look like an editor accident. The
reader records them as anomalies and resolves neither.

**No prediction is registered for what `actool` does with them**, because there
is no honest basis for one. The oracle run is the way to find out, and the
answer is recorded as a finding either way — including "actool ignores them",
which would confirm the reader's choice, and "actool exposes them as
top-level assets", which would make the reader wrong and is the reason the
question is being asked.

## P7 — catalogs `actool` refuses

Some catalogs are tvOS- or watchOS-only, or reference files that are not there.
`actool` will fail on them. **Every refusal is counted and named**, and those
catalogs are excluded from the agreement denominator rather than scored as
mismatches. A run in which `actool` refuses most of the corpus and the
remainder agrees perfectly is not a passing run, so the count of compiled
catalogs is printed beside every other number.

## P8 — the prediction

On the compared set — `.imageset`, `.colorset` and `.dataset`, universal /
iphone / ipad idioms, in catalogs `actool` compiles — **the tool and `actool`
agree on every tuple**. Divergences are findings about the reader, not about
`actool`, unless a specific `actool` behaviour is named.

---

## Teeth, to be demonstrated rather than described

1. **A corrupted `Contents.json` must refuse naming the file** — not fall back,
   not skip.
2. **An unknown key must refuse** — the whole point of the census-derived
   tables.
3. **A planted wrong variant must fail the spot oracle** — swap two files'
   `filename` fields in one imageset and the oracle must report exactly that
   asset. Without this, a comparison that trivially passes proves nothing about
   the comparison.
