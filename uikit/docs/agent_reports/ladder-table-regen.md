# APP_LADDER §9.6 regenerated from a committed type list

Branch `agent/ladder-table-regen`, 2026-09-10. Based on
`origin/agent/netnewswire-ios-target` (`b34a9d02`) because `origin/main` did
not yet carry `full/ladder/target_scope.py`; `origin/main` was merged in
twice — first at `a7f94380` (`uikit/Sources` identical to `5b2a7364`), then
at `481c0f81` after the split-view and text-item landings moved main while
the first pass was waiting on the merge lock. Task: §9.6 ("Next rungs") was
stale prose — four of its "top blocking" rows named types that had already
landed — and the netnewswire report had found the root cause. Regenerate the
type list against the current head, re-run the census and classifier for
every route-(b) NEAR/MID app as bounded per-app runs, rewrite only the §9.6
rows from those outputs, and prove the pipeline reproduces.

Nothing outside `full/ladder/` and `uikit/docs/` was written. No pin file,
`Package.resolved`, `.app` bundle, app source or corpus clone was touched.
No build, simulator or pixel claim is made.

## The root cause, resolved

Three different OpenUIKit type lists were in play on 2026-09-16:

| list | names | where it lives | what was computed from it |
| --- | --- | --- | --- |
| `openuikit_types-2026-09-16.txt` | 411 | committed | the §9.6 prose rows (Signal 14/57, firefox 6/18, NetNewsWire 6/71, ios-oss 1/1, Telegram 26/78, WordPress 9/51) |
| 2026-09-07 regeneration | 427 | **never committed**; only `_meta.ours = 427` in `ladder-census-2026-09-16.json` records it | the committed 09-16 JSONs (`ladder-census`, `gap-classes`, `ladder-scores`) |
| `openuikit_types-2026-09-10.txt` | 435 | committed by the netnewswire branch, from `5b2a7364` | §9.8 |

So the committed `gap-classes-2026-09-16.json` already disagreed with the
§9.6 table on six of nine rows before this work started; the prose and the
JSON were never from the same list. The "generator not in the gates" shape:
the census recorded a count of its input and nothing compared that count to
the committed file.

Regeneration here: the `remeasure-2026-09-16.sh` generator (the regex
`^\s*(public|open)\s+(final\s+)?(class|struct|enum|protocol|typealias)\s+((UI|NS|CA)[A-Za-z0-9_]*)`
over `uikit/Sources/OpenUIKit/**/*.swift`), run twice:

| at main | names | vs the previous list |
| --- | --- | --- |
| `a7f94380` | 435 | byte-identical to the committed `openuikit_types-2026-09-10.txt` (`cmp` clean); +24 over the 411 list, none removed |
| `481c0f81` | 437 | +`UITextItem`, +`UIPopoverPresentationControllerSourceItem` (both `16068eff`, merged as `d8dca8ad`); committed as **`openuikit_types-2026-09-10b.txt`** |

The 24 names the 435 list adds over 411:
`NSCollectionLayoutAnchor NSKeyValueChangeKey UIAccessibilityNavigationStyle UIBarPosition UIBarPositioning UIBarPositioningDelegate UICollectionViewController UICollectionViewFlowLayoutInvalidationContext UICollectionViewLayoutInvalidationContext UICoordinateSpace UIEditMenuArrowDirection UIEditMenuConfiguration UIEditMenuInteraction UIEditMenuInteractionAnimating UIEditMenuInteractionDelegate UIInputView UIInputViewAudioFeedback UIInputViewStyle UIScrollEdgeElementContainerInteraction UISplitViewController UISplitViewControllerDelegate UISwipeGestureRecognizer UITextSpellCheckingType UIToolbarDelegate`

Every §9.6 row is from the 437 list; the census `_meta` records the list
filename and the source commit (`openuikit_source_commit = 481c0f81…`). The
435-list pass is reported below only where it differed (firefox-ios and
WordPress-iOS), because main moving underneath a measurement is exactly the
mechanism that produced the stale rows in the first place.

## The pipeline, per app

Read from the headers: `ladder_census.py` (per-app UIKit walk with
apicensus's SKIP_DIRS, model/SwiftUI/selector walk, language mix, repo build
shape; `--target-scope=FILE` restricts the per-file walks for apps named in
the file) → `classify_gaps.py` (judgement split of `uikit.missing` into
blocking / stub-able / unclassified after FREE/OOS; the §9.6 "blocking
types / uses" and "top ≤3" columns) → `score_ladder.py` (ordinal subscores
from the census plus `imports-full`, `nibdeps`, `dep-classes`; the
"route (b) / score" column). `dep_class.py` and `audit-2026-09-16.py` were
read for the column provenance and are not on this path (dep classes are an
input, unchanged).

Each app ran as its own foreground call from a one-symlink mini-corpus
(`<scratch>/mini/<app>/<app> → ~/openuikit/scratch/ladder-corpus/<app>`),
so `ladder_census.py`'s directory listing sees exactly one app. All nine
HEADs equal `corpus-pins-2026-09-16.tsv`, working trees clean.
simplenote-ios was censused from a clean detached `git clone --shared`
at its pin, as `uikit/scripts/blocking_types_census.sh` does, because the
shared checkout carries an ignored `BuildTools/.build/` that the repo-wide
`build` walk would otherwise count. NetNewsWire ran with
`--target-scope=full/ladder/target-scope-netnewswire-ios-2026-09-10.json`
(the committed iOS scope, 448 files, 429 Swift). Inputs otherwise:
`uikit_sdk_types-2026-09-16.txt` (737), `openuikit_types-2026-09-10b.txt`
(437), `uikit-union-2026-09-16.json`, `imports-full-2026-09-16.json`,
`nibdeps-2026-09-16.tsv`, `dep-classes-2026-09-16.json`. Longest single run:
Telegram-iOS, 16 s.

The nine per-app census JSONs were concatenated (per-app dicts unchanged,
`_meta` asserted equal across runs) into
`ladder-census-nextrungs-2026-09-10.json`, which fed one `classify_gaps.py`
and one `score_ladder.py` call. Control: for the eight whole-repo apps every
non-UIKit census field (`swiftui`, `model`, `imports`, `languages`, `build`,
`swift_lines`) and the UIKit `uses` / `distinct_types` totals equal
`ladder-census-2026-09-16.json`; only `implemented_types` / `missing_*`
move. NetNewsWire's scoped run equals the netnewswire branch's (0 / 0,
1,333 uses / 124 types / 429 files).

## Old → new, per app

Old = the §9.6 prose as committed (411 list). JSON-09-16 = the committed
`gap-classes-2026-09-16.json` (427 list), shown to make the pre-existing
disagreement visible. New = this regeneration (437 list); where the 435-list
pass differed it is in brackets.

| app | route (b) / score, old → new | blocking types / uses, old → JSON-09-16 → new | new top ≤3 BLOCKING | stale names in the old row (landing commit) |
| --- | --- | --- | --- | --- |
| focus-ios | NEAR / 2 → NEAR / 2 | 0/0 → 0/0 → **0/0** | none | — |
| eidolon | NEAR / 6 → NEAR / 6 | 0/0 → 0/0 → **0/0** | none | — |
| simplenote-ios | NEAR / 7 → NEAR / 7 | 0/0 → 0/0 → **0/0** (stub-able 3/6 unchanged) | none | — |
| Signal-iOS | MID / 10 → MID / 10 | 14/57 → 6/21 → **4/8** | `UITab` 3 · `UINavigationBarDelegate` 2 · `NSIndexPath` 2 (+ `UICornerConfiguration` 1) | `UICoordinateSpace` (`1244733d`), `UIScrollEdgeElementContainerInteraction` (`47ea334c`), `UICollectionViewLayoutInvalidationContext` (`c781adea`) |
| firefox-ios | MID / 10 → MID / 10 | 6/18 → 5/8 → **2/3** [435: 3/4] | `UIMenuBuilder` 2 · `UICommandAlternate` 1 | `UISwipeGestureRecognizer` (`a1c0c6b9`), `UIToolbarDelegate` and `NSCollectionLayoutAnchor` (`8427d5a0`); `UITextItem` 1 (`16068eff`, mid-run) |
| NetNewsWire | MID / 11 → **NEAR / 9** (iOS target scope) | 6/71 → 2/50 (whole repo) → **0/0** (scoped) | none | `UISplitViewController` (`ca711a5e`), `UICollectionViewController` (`c781adea`); `NSToolbarItem` 48 is Mac-target demand removed by the scope, not declared |
| ios-oss | MID / 11 → MID / 11 | 1/1 → 0/0 → **0/0** (stub-able 1/1) | none | `UICollectionViewController` (`c781adea`) |
| Telegram-iOS | MID / 12 → **MID / 11** | 26/78 → 19/56 → **19/56** | `NSTextLocation` 6 · `NSTextLayoutFragment` 6 · `NSIndexPath` 5 (tie with `NSTextLayoutManager` 5, instrument order kept) | `UIEditMenuInteraction` (`50c5ffcf`) |
| WordPress-iOS | MID / 13 → MID / 13 | 9/51 → 5/26 → **3/4** [435: 5/26] | `NSTextTab` 2 · `NSTextLayoutManager` 1 · `NSTextLocation` 1 | `UISplitViewController` (`ca711a5e`); `UITextItem` 12 and `UIPopoverPresentationControllerSourceItem` 10 (`16068eff`, mid-run) |

Landing commits are the first commit on `origin/main` whose diff to
`uikit/Sources/OpenUIKit` introduces a `public`/`open` declaration of the
name (`git log --reverse -G'(class|struct|enum|protocol|typealias) +NAME([^A-Za-z0-9_]|$)'`).
The eight from the old rows are dated 2026-09-07 or 2026-09-09, i.e. before
the §9.6 rows were written on 2026-09-09/10 — the rows were stale on the day
they were committed, not overtaken later. `16068eff` is dated 2026-09-10 and
landed between this branch's first pass and its merge check.

Score movements and their measured cause: NetNewsWire UIK 1 → 0 (no gap in
scope) and UI 2 → 1 (SwiftUI view-bearing share 31.7% → 22.4% once `Mac/`
and the guarded files leave the denominator), so 11 → 9 crosses the NEAR
line; §9.2's whole-repo 11 is left as is. Telegram-iOS 12 → 11 because the
genuine gap is 97 uses, below the UIK=2 threshold of 100 (it was already 97
under the 427 list, so the committed scores JSON already said 11; only the
prose said 12). No other subscore moves; firefox-ios (gap 27) and
WordPress-iOS (gap 22) stay UIK=1.

Twenty-app union, recomputed from `uikit-union-2026-09-16.json`'s demand
with `classify_gaps.klass` against each list: 411 → blocking 66 types / 487
uses, stub-able 40 / 143; 435 → 50 / 262, 39 / 138; **437 → blocking
48 / 230, stub-able 39 / 138**. Top blocking by app-reach under 437:
`NSIndexPath` 5 apps / 10 uses, `NSTextLocation` 3 / 8,
`NSTextLayoutManager` 3 / 7, `UIMenuBuilder` 3 / 6, `NSToolbarItem` 2 / 85,
`NSTextContentStorage` 2 / 9. The four names the old paragraph led with are
all declared, and so is `UITextItem` (3 / 21).

## What was rewritten, and what was not

- `full/ladder/APP_LADDER.md` §9.6: the nine table rows (same column set),
  a provenance sentence above the table, the "shared remaining reach"
  paragraph (recomputed), and a dated paragraph on the root cause and the
  run. Claims the numbers no longer support were deleted (the three
  "measure X" next-work items for Signal, the three for firefox, the
  split-view / text-item / popover items for WordPress, the "implement
  UICollectionViewController first" for ios-oss, "123 total missing uses
  include 45 stubbable" for Telegram); each such row carries
  "(was: …, landed …)".
- §9.8's last sentence: "every other row in §9.2–9.6 is still whole-repo"
  was no longer true once §9.6 carried the scoped row; reworded to §9.2–9.5.
- No other line in APP_LADDER.md is a direct sum of §9.6. §9.1's 09-07
  follow-up row (66/487 → 54/280) is a 20-app union from the 427 list and
  is left as its own dated record; §9.2 is the whole-repo 411-list score
  table and is left as is (see above for the two rows that would move).
- `uikit/docs/REAL_APP_TEST.md`: one dated row. The merge with main
  conflicted in this ledger (split-view and text-item rows landed); both
  sides kept.

## Reproducibility and tests

- Against the 437 list, firefox-ios and WordPress-iOS were each run twice
  from scratch; against the 435 list, firefox-ios and NetNewsWire. In all
  four cases the census JSON and the gap-classes JSON are byte-identical
  between runs (sha256 of every per-app run output and of the three
  committed combined files in `full/ladder/SHA256SUMS-nextrungs-2026-09-10.txt`).
- `python3 -m unittest full/ladder/test_target_scope.py` — 6 passed.
- `uikit/Tools/ingest/test_xcodeproj_to_package.py` — 23 passed, 24 skipped
  (unchanged; the parser is used by `target_scope.py`).
- There is no classifier unit test in `full/ladder/`; the classifier's
  check here is the control above (non-UIKit fields invariant, NetNewsWire
  scoped result equal to the netnewswire branch's).

## Limits

- Whole-repo for eight apps, scoped only for NetNewsWire, as before.
- The `_union` block inside `gap-classes-nextrungs-2026-09-10.json` is what
  the unchanged instrument emits: it reads `uikit-union-2026-09-16.json`'s
  `ours` flag, which was set by the 09-07 (427-list) run, so it does not
  reflect the 437 list. It was not used; the union figures above were
  recomputed from the list. Regenerating the union file itself is a 20-app
  run and was out of scope.
- The census `_meta` now carries the source commit and list filename; the
  older dated censuses do not, which is exactly how the 411/427 split went
  unnoticed. A gate that regenerates the list and compares bytes against
  the committed one is the fix the netnewswire report asked for and is
  still not in place. This branch hit the same hazard live: main advanced
  by two declared names between the first pass and the merge check, and
  only a second regeneration caught it.
- Declaration coverage is textual; no member, initializer, build or launch
  claim follows from a name leaving the blocking list.

Reproduce from the repo root (`<corpus>` = `~/openuikit/scratch/ladder-corpus`;
one app shown, the mini-corpus is a directory holding one symlink):

```sh
mkdir -p /tmp/mini/firefox-ios && ln -s <corpus>/firefox-ios /tmp/mini/firefox-ios/firefox-ios
python3 full/ladder/ladder_census.py /tmp/mini/firefox-ios \
    full/ladder/uikit_sdk_types-2026-09-16.txt full/ladder/openuikit_types-2026-09-10b.txt census.json
python3 full/ladder/classify_gaps.py census.json full/ladder/uikit-union-2026-09-16.json gaps.json
python3 full/ladder/score_ladder.py census.json full/ladder/imports-full-2026-09-16.json \
    full/ladder/nibdeps-2026-09-16.tsv full/ladder/dep-classes-2026-09-16.json scores.json
# NetNewsWire: add --target-scope=full/ladder/target-scope-netnewswire-ios-2026-09-10.json
```
