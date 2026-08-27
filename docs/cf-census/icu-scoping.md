# #48 scoping: is ICU a wall, and does porting from swift-foundation avoid it?

Scoping only, no porting. Two questions were asked; both have answers, and the
answer to the first is the opposite of the framing it arrived with.

## 1. Does upstream's in-tree ICU/CLDR derivation cover CF's 171 symbols?

**No. It covers essentially none of them, and porting the model layer from
swift-foundation would INCREASE the ICU requirement rather than remove it.**

Measured in a fresh clone of `swiftlang/swift-foundation`:

```
Package.swift:189-195   target "FoundationInternationalization" depends on
                        .product(name: "_FoundationICU",
                                 package: "swift-foundation-icu")
```

Upstream does not avoid ICU. It **vendors** it, as a separate package pulled
from `apple/swift-foundation-icu`. `FoundationInternationalization` is a Swift
wrapper *over* ICU, not a replacement *for* it.

The in-tree data target that the "carries CLDR data" claim refers to:

```
Sources/_FoundationInternationalizationData/   3 files, 88K
    ListFormatData.swift
    ListFormatLookup.swift
    CMakeLists.txt
```

**List formatting only.** Not calendars, not locales, not date or number
formats. The statement "swift-foundation carries ICU-derived logic and CLDR
data in-tree" is true and its natural reading is wrong by three orders of
magnitude — the same shape as "18 `.dateFormat` assignments" standing in for
date-formatting demand.

How much ICU each side actually uses, counted from source:

```
CoreFoundation                    171 ICU entry points
FoundationInternationalization    200 ICU entry points
  shared                          114
  CF only                          57
  swift-foundation only            86
  UNION                           257   <- what one ICU build must vend
```

The 57 CF-only symbols are not incidental: `uregex` (16, NSRegularExpression),
`ucnv` (13, charset conversion), `ucol` (5, collation), `utrans` (3,
transliteration). Those are surfaces swift-foundation does not use at all, so
adopting it would not retire them.

**So the model-layer port is still the right call for other reasons, but it must
not be justified by ICU avoidance.** It raises the ICU surface from 171 to 257.

## 2. What do six locales cost?

**The question does not apply to this package, which is good news.**

`swift-foundation-icu` ships its data **pre-packaged and vendored**, as
`icuSources/common/icu_packaged_main_data.*.inc.h` — roughly 20 MB of C arrays
selected by `USE_PACKAGE_DATA=1`, with `stubdata/` excluded. There is no
external `.dat` to fetch, no data-building bootstrap, and **no locale selection
at build time**. You take the blob.

Locale trimming against ICU's data filter remains possible as a *size*
optimisation later. It is not a prerequisite, it does not unblock anything, and
scoping it now would be work spent on a number nobody is blocked by.

That also means the six-locale finding (`en` 20, `de` 11, `es` 9, `en_US` 9,
`fr` 9, `ja` 8) tells us about *demand*, not about *cost*: the cost is fixed and
already paid by the vendored blob.

## 3. So what is actually left of the "link wall"?

Per `scripts/build_icu.sh`, which already carries the measurement:

```
469 .cpp sources, ~338K lines
456 compile against machorun's staged Darwin sysroot with NO intervention
 13 need the four declaration-only shims that script stages
     (glob.h, langinfo.h, os/log.h, tzfile.h)
```

**CAVEAT, stated because of how many stale numbers this project has produced
today: 456/469 is a RECORDED measurement from when that script was written. I
did not re-run it in this session.** Re-run before quoting it; the sysroot has
changed several times since, and every change so far has moved a number.

And per `docs/cf-census/icu-libc-gap.txt`, once #48's C++ runtime work
(libc++abi, the omitted libc++ sources, libunwind) is in, **every C++ symbol ICU
needs resolves** — all 31 of the original gap plus the 6 `_Unwind_*` behind
them. What remains is **20 libc symbols, none of them C++.**

## 4. The number that matters for planning

Remaining libSystem gaps across all three consumers, measured against today's
libSystem (13:07 UTC, machorun `559356b`):

```
CoreFoundation      81
ICU                 20
libdispatch          8
                   ---
UNION              108      (sum 109, so exactly ONE symbol is shared:
                             pthread_mach_thread_np)
```

They are **near-disjoint**, which is the opposite of the usual hope and worth
knowing: finishing one consumer's list does very little for the others.

**Conclusion: ICU is not a wall.** It compiles, its data is vendored, and its
C++ dependencies are solved. #48's remainder is 20 libSystem symbols — the same
lane as #60, not a port. The wall was the C++ runtime, and that has already
been climbed.
