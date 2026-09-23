# test-debt: the unit tests run in the merge gate, and main's red tests are fixed

**Branch:** `agent/test-debt`, based on main bb773f63.

## Problem

`agent_merge.sh` built the test bundle (`swift build --build-tests`) but never ran it, so a failing unit test could reach main without anyone seeing it.

On main bb773f63, `swift test` (clean `.build`, all 2018 cases, default order) failed 11 tests in 8 classes. At this morning's base, 9cd38125, 10 of those were already failing, plus `ValueTypeTailTests`. Only one failure came from today's merges.

## Failure inventory

**How each row was measured:**
* "base" means the test fails at 9cd38125 when run in `bis/`, a `git archive` of the commit with an incremental build.
* The cause commit comes from bisecting today's `--first-parent` merges.
* For order-dependent failures, `leak.sh` halves the list of suites that run before the failing one until a single leaking suite is left.

| Test | Fails alone? | Cause | Class | Fix |
|---|---|---|---|---|
| `KeyboardChromeTests` ×4 (`testIOSFocusInstallsMeasuredPanelAndQKey`, `testHasTextUsesLowercaseAndShiftOff`, `testNumberPadOverlapIs233`, `testCatalystCutDoesNotShowKeyboard`) | yes | long-standing, before 9cd38125 | test bug (lifetime) | The test now keeps its window alive. |
| `TextFieldDelegateTests` ×2 (`testBeginAndEndCallbacksFire`, `testShouldEndEditingBlocksResign`) | yes | long-standing | test bug (lifetime) | Same fix. |
| `UISearchBarTests/testMeasuredFieldFrame` | yes | 2f008d44 (09-05, Dynamic Type) | real port regression | `UISearchBar.layoutSubviews`: on the Catalyst cut the field sits at y = (H − 44) / 2, as measured. |
| `FoundationCoexistenceTests/testRenderPathReadsNoWallClockLocaleOrRandomSource` | yes | 50c5ffcf (09-07, edit menu) | real port regression (determinism rule) | A nil `UIEditMenuConfiguration` identifier now comes from a process-wide serial spelled as a UUID, not from `UUID()`. |
| `IOSNavigationBarTransitionTests/testIOSInlineBarIsTransparentAndContentUnderlaps` | no | long-standing leak from `ApplicationShellCompatibilityTests` | real port bug (appearance proxy) | New bars copy the proxy's standard appearance only when the app set one. |
| `UIScrollEdgeEffectTests/testHardPlateUnderNavigationAndTabBarsMatchesTheMeasuredGeometry` | no | same leak | same | Same fix. |
| `ValueTypeTailTests/testShortcutDeliveryPrefersWindowSceneDelegate` | no (flaky) | long-standing leak: scenes left connected | test isolation | The test sets leftover scenes aside, and the two suites that leaked a scene now disconnect it. |
| `UIButtonConfigurationTests/testAttributedTitleFontAndColourWin` | yes | **b1a50a20, attrstring-unify (today)** | real regression | **Known failure** (see below). |
| `CollectionLayoutAnchorTests/testBadgesAreTiledPerItemAndDoNotGrowContent` (reported on c0dca164) | no (flaky; **crashes the run**) | the test arrived in fe74874f (nnw-batch-b); the underlying bug is older | real port bug (address-keyed side table) | The list configuration is now stored on the section or layout object, and the test no longer indexes an empty array. |
| `RasterizerTests/testFillPerformanceBudget` (reported under gate load) | no (flaky under load) | long-standing | environment (wall-clock budget) | The budget is now measured in thread CPU time (`CLOCK_THREAD_CPUTIME_ID`). |

### Causes

**Lifetime.** `UIApplication` holds its windows weakly, as UIKit does. `let (_, tf) = makeWindow()` releases the window whenever the optimizer decides to. The field then has no window and `becomeFirstResponder()` returns false. Adding a `print` was enough to flip the result.

`KeyboardChromeTests` then found the previous test's landscape keyboard window (`(0, 169, 667, 206)`).

Other tests use the same pattern and pass today because their windows happen to survive: `PresentationControllerTests`, `TableViewTests`, `FocusSettingsTableTests` and others (`grep 'let (_, '`). They are latent failures.

**Search bar.** The Catalyst oracle in the `UISearchBar.swift` header measured a 36 pt field at (H − 44) / 2 for H = 36/44/50/56/60/80. Commit 2f008d44 changed the code to centre the field's own height, which put the field 4 pt lower. The iOS cut is unchanged: its field is the 44 pt box, scaled by Dynamic Type.

**Edit-menu identifier.** The measured properties are kept: each identifier is distinct, its description has the UUID form, it is not a `UUID`, and it is not equal to its own description. `UIEditMenuInteractionTests` still pass.

**Appearance proxy.** A bar's synthesized default depends on the cut: opaque on Catalyst, default background on iOS. The proxy froze whichever default applied when it was first read, and every later bar copied it. UIKit's proxy only replays the setters the app called.

**Address-keyed side table.** `_ListConfigBox` and `_LayoutListBox` (`UICollectionViewListCell.swift`) stored the list configuration in a static `[ObjectIdentifier: …]` map and never removed entries.

A new section or layout allocated at a dead one's address inherited that configuration and was laid out as a list. The test then saw a content height of 2720 instead of 2660 and no badges, and `badges[0]` trapped (`Index out of range`), which ended the xctest process and hid every suite after it. This reproduced in 2 of 3 runs of the A–C suites.

With the configuration stored on the object, 4 of 4 runs pass. The two other address-keyed tables in the port (`_UIAccessibilityStorage`, `_UIStoryboardStates`) already check a weak owner, so they are safe.

**Scene leak.** `connectedScenes` is a `Set`, and shortcut delivery picks the first window scene it iterates. A scene left connected by an earlier suite could therefore win or lose depending on hash order, so the test failed only in some runs.

### Known failure left: `UIButtonConfigurationTests/testAttributedTitleFontAndColourWin`

The test was introduced in ios-oss-walls (c46cb926) and passes there and at 3f6ac938. It fails from b1a50a20 (attrstring-unify) on.

Since that merge, `NSAttributedString` is Foundation's own class on Apple toolchains. As a result, `AttributedString(NSAttributedString(...))` resolves to **Foundation's** `init(_:)`, which has exactly the same signature as the port's converter in `UIButtonConfiguration.swift`.

This was confirmed with a two-module `swiftc` experiment:
* Foundation's initializer wins whenever the client can see Foundation other than through the port. That includes Kickstarter's `import UIKit` through the shim, and XCTest.
* The port's converter wins only when Foundation reaches the client solely through the port's own `@_exported` re-export.

Foundation's attribute table comes from the real AppKit and UIKit scopes. That table drops the port's `UIFont` and `UIColor` values, so the Terms-of-Use button renders in the 17 pt default instead of the measured 20 pt bold systemRed.

**No port-side fix without new design:**
* The port's overload cannot be made to win.
* Foundation's table cannot be extended.
* The consumer cannot recover attributes that were already dropped.

**Owner:** attrstring-unify. The entry is listed in `scripts/known_test_failures.txt`.

## Gate stage: "unit tests"

**What it runs.** `unit_tests()` in `agent_merge.sh` is started with `bg unittests` next to the test-bundle build and waits for the bundle's `tests.rc`. It then runs `swift test --skip-build --scratch-path $TESTS_SCRATCH` on the merged tree:
* the whole suite, in one process, in default order;
* not `--parallel`, because 3 of the 8 red classes were state leaked from an earlier suite, and only the full-order run shows those;
* under a watchdog, `GATE_TEST_TIMEOUT`, default 1800 s. On timeout the process tree is killed.

The stage is joined just before the Linux build and exits 10 on failure. `GATE_SERIAL=1` runs it in place instead. `GATE_TEST_PARALLEL=1` adds `--parallel` and is part of the verdict key.

**How the result is graded.** `scripts/check_unit_tests.py <log> --rc <rc>` grades the log against `scripts/known_test_failures.txt`, which lists one `Class/test reason` per line. The gate refuses when:
* a test fails that is not in the list;
* a listed test now **passes**, so the list only shrinks;
* a listed test no longer runs, meaning the entry is stale;
* `swift test` exits non-zero with no failing case, i.e. a crash or timeout. The test that was running is named.

Agents can run the same check locally: `swift test 2>&1 | tee t.log; python3 scripts/check_unit_tests.py t.log --rc $?`.

**CHECK_ONLY and verdict reuse are unchanged.** The known-failures file is part of the merged tree, so it is already covered by the verdict key.

**Time.** On the CHECK_ONLY run of this branch (load average about 220):
* the test bundle was built at about +180 s;
* `swift test` took 277 s and finished at +459 s;
* the gate reached the join at +649 s, because the release build took 550 s under load.

So the stage added **0 s of wall time** in that run. The cost is CPU contention while it overlaps the release build and the replays. A serial `swift test` on a warm build takes 255–300 s at this load, so the stage only adds wall time on a gate that would otherwise finish in under about 470 s.

## Verification

* Full `swift test` on the branch: 2018 cases, 1 failure, the known one. `check_unit_tests.py` exits 0.
* `CHECK_ONLY=1 bash uikit/scripts/agent_merge.sh agent/test-debt`: passed in 649 s.
  * Catalyst 124/124.
  * Unit tests: 2042 cases, 1 known failure.
  * The verdict was stamped.
* `scripts/ops/local_guest_verify.sh <worktree>` and the re-run of the gate on the final head (after merging main c0dca164+ and the two fixes above) are reported in the handback.
