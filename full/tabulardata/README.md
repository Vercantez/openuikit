# TabularData (Linux starting point)

This directory is a clean-room Linux port of Apple's public `TabularData`
module, seeded from the iPhoneOS 26.1 SDK graphs. It produces module
`TabularData` and `libTabularData.dylib`.

The isolated host gate (`bash tests/acceptance/test_host.sh`) compiles
against the **toolchain** Foundation. It is not an integrated Linux/EC2
guest-Foundation result. A future EC2 run must build guest Foundation
first, build this module with those `-I/-L` paths, and execute
`tests/agent/TabularDataDependencyIdentity.swift`.

Environment marker used by this campaign:

`CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean`

## What is real

- Value types: `Column`, `ColumnSlice`, `DiscontiguousColumnSlice`,
  `AnyColumn` / `AnyColumnSlice`, `FilledColumn`, `DataFrame` /
  `DataFrame.Row` / `Rows` / `Slice`, `RowGrouping`, summaries, CSV/JSON
  options, and the public error enums.
- CSV read/write (header, quoting, typed columns, NA/boolean encodings,
  ISO-8601 dates, base64 `.data`) and JSON array-of-objects plus
  column-dictionary tables.
- Column arithmetic (`+ - * /` and in-place forms), comparisons that
  produce `[Bool]` masks, grouping, joins (inner/left/right/full),
  random/stratified splits, explode/combine/transform, and `summary()`.
- Collection overlays that Linux Swift actually offers:
  `BidirectionalCollection` plus `MutableCollection` /
  `RandomAccessCollection` where the Apple graph lists them.

## Fail-closed boundaries

- **SFrame:** `DataFrame(contentsOfSFrameDirectory:)` always throws
  `SFrameReadingError.unsupportedArchive`. There is no Turi Create decoder
  on this host.
- **Combine:** `Column.encoded(using:)`, `decoded(using:)`,
  `DataFrame.encodeColumn` / `decode(inColumn:using:)`, and
  `AnyColumn` TopLevelEncoder/Decoder methods are **deferred**. Isolated
  Linux Foundation has no `TopLevelEncoder` / `TopLevelDecoder`.
- **Combine publishers:** `publisher` on collection types is deferred
  (no Combine overlay).
- **FormatStyle collection formatting:** `formatted(_:)` whose
  `FormatInput` is the collection itself is deferred. `FilledColumn`
  of `String` still uses the stdlib `formatted()` / `joined()` overlays
  that Linux provides.
- Invalid JSON bytes become `JSONReadingError.unsupportedStructure`
  rather than a successful table.

## Depth pass 2026-09

Exact public IDs: **1768**. Nondeferred floor for `medium-full` is 884.

- After this seed: implemented **1658** / declared **52** / deferred **58**
  (TopLevelEncoder/Decoder, Combine `publisher`, collection `formatted(_:)`,
  `compare(_:_:)` when `Element: SortComparator`, deprecated `index(of:)`,
  and RangeSet `removingSubranges` / `moveSubranges` that the host runner
  must not hang on).
- Top-5 implemented evidence distribution (1658 rows):
  1. `TabularDataColumnTests.swift#testColumnInitAndAppend` — 74
  2. `TabularDataGroupTests.swift#testGroupedCountsAndAggregates` — 68
  3. `TabularDataColumnTests.swift#testDiscontiguousColumnSliceBehavior` — 63
  4. `TabularDataColumnTests.swift#testColumnSliceBehavior` — 62
  5. `TabularDataCollectionTests.swift#testColumnSliceCollectionInherited` — 62
- Enum/option-set members share table-driven tests
  (`testCSVTypeCases`, `testJSONTypeCases`, error-case tests). No other
  single test exceeds 40% of the remaining implemented rows (largest remaining
  citation is about 4.8%).
- Gate: `bash full/tabulardata/tests/acceptance/test_host.sh`.

Still not claimed: Apple-identical CSV quoting of every Unicode edge
case, Combine encoder round trips, Turi Create SFrame bytes, or
Hasher mixing that matches Darwin `Column` / `DataFrame` hash values.

See `oracle-questions.tsv`.
