# TableViewIOSEditChromeTests: the two pre-existing failures (2026-09-09)

Branch `agent/tableview-editchrome-tests`. Reported by the
uicollectionviewcontroller agent as 2 failures reproducing on origin/main.

## What failed

`swift test --filter TableViewIOSEditChromeTests` on origin/main (6e6a0106):

```
TableViewTests.swift:1215: testGroupedDefaultRowStays53OnIOS :
  XCTAssertEqualWithAccuracy failed: ("52.0") is not equal to ("53.0") +/- ("0.001")
TableViewTests.swift:1216: testGroupedDefaultRowStays53OnIOS :
  XCTAssertEqualWithAccuracy failed: ("87.0") is not equal to ("53.0") +/- ("0.001")
Executed 8 tests, with 2 failures
```

Both assertions are in ONE test, `testGroupedDefaultRowStays53OnIOS`
(an `.insetGrouped` table, classic `.default` cells, SE 2x, iOS cut). The
edit-chrome test proper (`testEditModeInsetsAndControlsOnIOS`: content view
x 40 / width 292, delete control `[15, 18, 26, 26]`, reorder x 332 / 27)
was never failing.

## Which landing moved the behaviour

- The test was added in cbd603e5 (2026-09-05, "plain classic textLabel rows
  are 52 pt"). Its own doc comment already said "classic grouped is ALSO
  52" (rowprobe grouped_classic), and the commit message states the 53 was
  a deliberate compromise: "grouped stays 53 so tableview_grouped and Focus
  do not drop". So the test encoded a known-unmeasured value.
- 8540d66f (2026-09-07, agent/focus-fidelity-tables) moved the code to the
  oracle: `resolveRowHeight` returns `plainClassicRowHeight` (52) for every
  iOS-cut style, and `untitledGroupedFirstSectionTop = 35` puts an untitled
  first section's rows at y 35. That landing added FocusSettingsTableTests
  (which asserts `[0, 35, 353, 52]` at 3x) but did not touch this older
  test. `git log -S` for both the 52 path and the `[0, 35, 353, 52]`
  comment name only 8540d66f.

## Which side is right: the code

Oracle evidence, all iOS 26.1, from
[focus-fidelity-tables.md](focus-fidelity-tables.md) rule table:

| Rule | iPhone 16 3x golden + tableprobe | SE 2x tableprobe |
|---|---|---|
| Classic row, `estimatedRowHeight = automaticDimension`, insetGrouped | 52 (every style, with chevron / switch / none) | 52 |
| Untitled first section | rows at 35, `rectForHeader(0)` = `[35, 0]` | 35 |

The test runs on SE 2x, so the expected geometry is row 0 at 35 × 52 and
row 1 at 87, which is exactly what the port produces. The fixture scenes
(tableview_grouped / tableview_dark) still get 53 through a delegate
`heightForRowAt` in SceneBuilder, so nothing else moves.

## Change

`Tests/OpenUIKitTests/TableViewTests.swift`: the test is renamed
`testInsetGroupedClassicRowIs52AndStartsAt35OnIOS` and asserts minY 35
(both the literal and `UITableView.untitledGroupedFirstSectionTop`),
height 52, row 1 minY 87, with a comment citing the report and the
measured numbers. No source change.

## Proof

- `swift test --filter TableViewIOSEditChromeTests`: 8 tests, 0 failures
  (was 8 / 2 failures).
- `swift test --filter 'TableView|Cell|Separator'`: 78 tests, 0 failures.
- Merge check (`CHECK_ONLY=1 agent_merge.sh`): see the REAL_APP_TEST.md row.
