# CoreMedia SDK depth, second pass (`agent/fw-coremedia2`)

Base: `origin/agent/fw-coremedia` (first pass, refused for coverage honesty).
Scope: `full/coremedia/` plus this report. No uikit sources, no `reference/`
or `tests/acceptance/` edits, no pin files authored here.

## What was refused

`coverage.tsv` marked **1657** identifiers `implemented`, but **850** of
**1642** non-enum implemented rows cited one test
(`tests/agent/CMFormatDescriptionTests.swift#testCMFormatDescriptionCreateEqualExtensions`)
— a bulk relabel of format-description extensions, error codes, overlay
members, and unrelated C functions as "focused runtime assertion". Other
catch-alls: `testCMSampleBufferCreateAndTiming` 246, `testCMMetadataIdentifierBasics`
106, `testCMTimebaseRateAndAnchor` 95, `testCMBlockBufferCreateCopyFill` 94.

Invented success is worse than a marked gap. `implemented` evidence must be a
focused test of that identifier's behaviour. Enum/option-set members may share
one table-driven raw-value test; kCM* CFString payloads may share a family
table. The merge path refuses any single test cited by more than 150 non-enum
rows or more than 40% of them.

## Coverage before / after

| | implemented | declared | deferred | nondeferred |
|---|---:|---:|---:|---:|
| main (seed) | 126 | 140 | 2108 | 266 |
| first pass (refused) | 1657 | 73 | 644 | 1730 |
| this pass | **437** | **1289** | 648 | 1726 |

Public surface is still 3504 precise IDs. The large-partitioned floor is 150
nondeferred; 1726 remains well above it. not-applicable stays 1130.

Every row whose only evidence was a bulk citation is `declared` again with
`source:full/coremedia/<file>.swift#Symbol` (or `deferred` when no product
source names the identifier — three `CMSampleDataReference` Swift overlay
IDs). `testCMTimeDocumentedArithmetic` (nested re-entry of other tests plus
TimeCode APIs it never called) is deleted.

### Evidence distribution (top 5 tests by row count)

1. `testCMFormatDescriptionExtensionKeyStrings` — 46 (documented suffix
   payloads of `kCMFormatDescriptionExtension_*`)
2. `testCMSampleAttachmentKeyStrings` — 34
3. `testCMFormatDescriptionColorMatrixKeyStrings` — 29
4. `testCMFormatDescriptionOverlayKeys` / `testCMSampleBufferCreateAndTiming` — 26
5. `testCMBlockBufferCreateCopyFill` — 24

57 distinct cited tests. 437 implemented rows. Non-enum implemented: 422.
Largest non-enum citation is `testCMFormatDescriptionExtensionKeyStrings` at
**46 / 422 = 10.9%**. No test exceeds 150 non-enum rows or 40%.

First-pass top 5 (for the refusal): `testCMFormatDescriptionCreateEqualExtensions`
850, `testCMSampleBufferCreateAndTiming` 246, `testCMMetadataIdentifierBasics`
106, `testCMTimebaseRateAndAnchor` 95, `testCMBlockBufferCreateCopyFill` 94.

## Behaviour this pass actually tests

Cited Apple documentation, not a comparison-score search.

1. **CMTime arithmetic** (`CMTime.h`). `CMTimeMake` / `MakeWithEpoch` /
   `MakeWithSeconds` / `GetSeconds`. Add/subtract of 1/2 + 1/3 = 5/6.
   Multiply / `MultiplyByRatio` / `MultiplyByFloat64`. Compare, min, max,
   absolute value. ConvertScale 1/2 → timescale 1 for every rounding method:
   half-away-from-zero = ±1, toward-zero = 0, away-from-zero = ±1,
   toward-+∞ = (1, 0), toward-−∞ = (0, −1). Default == half-away-from-zero
   (raw value 1). QuickTime is the labeled toward-+∞ stand-in
   (`oracle-questions.tsv`). Dictionary keys `value` / `timescale` / `epoch`
   / `flags`. Swift Comparable is `CMTimeCompare`'s sign.
2. **CMTimeRange / CMTimeMapping** (`CMTimeRange.h`). Make, fromTimeToTime,
   end exclusive of contains, union/intersection, equality, dictionary
   `start`/`duration`, mapping `source`/`target`.
3. **CMBlockBuffer / CMSampleBuffer**. Create empty / memory-block, copy/fill/
   replace/access-bytes, create-ready + timing info, attachments propagate
   vs not, invalidate exactly-once, not-ready/make-ready.
4. **CMFormatDescription**. Create/equal, video dimensions 1920×1080, media
   type/subtype FourCC (`vide`/`avc1`), muxed MPEG-2 transport. Audio ASBD
   bridging stays behind `canImport(CoreAudioTypes)` — isolated host does
   not claim it.
5. **CMClock / CMTimebase**. Host clock timescale 1_000_000_000 (CMSync.h
   "nanoseconds"). Rate/anchor interpolation; timers return
   `kCMTimebaseError_TimerIntervalTooShort` (−12751).
6. **kCM* CFString payloads** as family tables (suffix of the identifier;
   CoreVideo color aliases `ITU_R_709_2` / `IEC_sRGB` / `Apple Log`).
   Pointer identity vs Apple interned constants is unobserved.

`coremedia_guest_sources.txt` is unchanged (14 sorted product sources).

## Open (oracle-questions.tsv)

QuickTime rounding halfway policy, invalid/indefinite compare order, add
across epochs, CFString pointer identity, process-local CFTypeIDs, AuxiliaryPicture
FourCC, invalidate-callback queue, AccessDataBytes interior pointer, audio
format-description defaults. No parameter search against comparison scores.

## Gate

Darwin `swiftc -warnings-as-errors` of `libCoreMedia.dylib` plus 57 cited
tests printed `COREMEDIA_AGENT_RUNTIME_OK`. Isolated Linux
`swift:6.2-noble` `tests/acceptance/test_host.sh` printed
`COREMEDIA_AGENT_RUNTIME_OK` and `FRAMEWORK_FANOUT_HOST_OK` (host runner
`import Glibc`; macOS cannot run that file as-is). Linux
`swift:6.2-noble` `swift build -c release --product openrender` completed.
Lineage accepts generator digest `e44f6bde…` against checked-in `e56ee6e7…`.
No uikit pixel rule; Catalyst / iOS suite / real-app screens were not
re-rendered.
