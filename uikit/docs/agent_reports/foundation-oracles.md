# Guest Foundation formatter oracles

Carried-golden Apple differentials for the six Foundation families real apps
call most. Measured on this Mac against Apple Foundation, 2026-09-05.
No ICU: locale data is the table each golden proves (en/de/fr/ja).

Native Mac check: compile the oracle against Apple, compile the port file as
a module with `-D FOUNDATION_GUEST_SERVICES_HOST`, compile the same oracle
against that module, `cmp` the transcripts.

`bash full/foundation/tests/test_foundation_oracles_host.sh`

## Row counts (before → after)

| family | before | after | mismatches fixed |
|---|---|---|---|
| DateFormatter | 93 style/pattern rows in the services host gate only; no carried golden | **260** exact | Style patterns were hand-built (US `M/d/yy`, GB `dd/MM/yyyy`, FR `à`) and only en/fr names. Apple uses `y` not `yyyy`, NNBSP before `a`, de `dd.MM.yy` / `um`, ja `y/MM/dd` / `H時mm分ss秒`. Added de/fr/ja month, weekday, era, AM/PM and zone-name tables. Added `date(from:)` POSIX round trips (`2024-02-29 17:25:09` → `1709227509.0`). |
| JSONSerialization | 77 mixed structured-data rows, no trailing-comma golden | **41** exact | FoundationEssentials JSONDecoder rejects trailing commas. Apple accepts 16 RFC-invalid documents (`{"a":1,}`, `[1,]`, nested, whitespace). Strip a single comma before `]`/`}` when the previous non-space is not `{`/`[`/`,`. `{,}` / `[1,,]` stay 3840. Syntax errors were JSONDecoder 4864; wrap to `NSCocoaErrorDomain:3840` with `NSJSONSerializationErrorIndex`. |
| NSRegularExpression | 77 mixed structured-data rows | **62** exact | Existing `_StringProcessing` engine already matched the pattern table (anchors, classes, groups, quantifiers, lookahead, named groups, options, UTF-16 ranges, `$n` replacement). No engine change. |
| NumberFormatter | absent | **178** exact | New. Decimal/percent/currency/ordinal × en_US_POSIX/en_US/en_GB/de_DE/fr_FR/ja_JP. POSIX currency is `$`+U+00A0 with no grouping; ordinal still groups (`1,234th`). ja negative ordinal is `第−2` (U+2212 after 第). Rounding modes from Apple 1.25/1.15/−1.25 at 1 fraction digit. |
| ISO8601DateFormatter | absent | **33** exact | New. Option raw values (`withInternetDateTime=1907`, `withFractionalSeconds=2048`). Empty options → empty string. Week `2024-W09` / `2024W09`. Parse `Z` / `−06:00` / fractional seconds. |
| DateComponentsFormatter | absent | **46** exact | New. ZeroFormattingBehavior raw values (`default=1`, `pad=65536`, `dropAll=14`). Positional default `0:05:00` → `5:00` (drop leading hours, keep trailing `:00`). de `1 Stunde, 2 Minuten und 3 Sekunden`; fr NBSP before heure/secondes + `et`; ja full spaces, abbreviated glued. |

## Open questions

- Locales other than the six sampled identifiers fall back to English names / en_US style patterns.
- `JSONSerialization.data(withJSONObject:)` of a fragment without `.fragmentsAllowed` raises an ObjC exception on Apple; the port throws `NSError` 3840. Not in the golden (the oracle does not catch NSException).
- Japanese calendar / era years, `spellOut` number style, and `DateComponentsFormatter.UnitsStyle.spellOut` were not sampled.
- The Focus onboarding builder still pins 38 guest sources; this branch's manifest is 41. Operator bump: `build_focus_onboarding_guest.sh` and `EXPECTED_FOUNDATION_SOURCE_COUNT` in the core package builder.

## Verify

- `python3 full/foundation/tests/test_foundation_formatters.py` pins sha256 + row counts.
- `python3 full/foundation/tests/test_foundation_guest_services.py` manifest 41.
- `bash full/foundation/tests/test_foundation_oracles_host.sh` — all six exact.
- Existing `test_foundation_guest_services_host.sh` still `date_rows=93`.
- Linux `swift:6.2-noble`: the four new/rewritten formatter files compile as HOST modules; JSONSerialization HOST compiles with `import CoreFoundation`; `uikit` `openrender` release build green.
- No uikit render rule changed; Catalyst / iOS suite / real-app pixels stay the previous floors (112/113).
