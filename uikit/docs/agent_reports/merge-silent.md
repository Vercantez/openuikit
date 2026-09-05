# Merge `origin/agent/silent-frameworks` onto main (Package.swift type-check)

MERGE TASK, no new rules. Main (`e97fa7fb`) already carries Combine/os
products and SafariServices / MessageUI / LinkPresentation plus the Present
app. `origin/agent/silent-frameworks` (`f94fd58d`) adds fail-closed StoreKit,
portable ImageIO / CoreImage, `NSUbiquitousKeyValueStore`, and the HTTPCookie
Apple golden (16/16) under `full/foundation/`.

A keep-both of `uikit/Package.swift` made one `Package(products:targets:)`
literal that Swift 6.2 cannot type-check:

`Package.swift:137: error: the compiler is unable to type-check this
expression in reasonable time`

That hit macOS and Linux `swift:6.2-noble` (corelibs is where the timeout
first bit). This merge keeps **every main target, product, dependency,
exclude list, swiftSettings and platform condition** and **adds the
branch's StoreKit / ImageIO / CoreImage targets the same way**, split into
named, explicitly typed arrays so the manifest type-checks in seconds.

## File resolutions

| file | how it was resolved |
|---|---|
| `uikit/Package.swift` | Not keep-both. Split `products` into `coreProducts` + `frameworkProducts` (`[Product]`) and `targets` into `coreTargets` + `frameworkTargets` + `conformanceTargets` + `testTargets` + `platformCombineTargets` (`[Target]`), joined with `+`. Restored `CoreImageTests` `swiftSettings` (the keep-both had dropped the closing of that `.testTarget`). Darwin module names stay `OpenUIKitImageIO` / `OpenUIKitCoreImage` / `OpenUIKitStoreKit`; Linux keeps the literal Apple names. |
| `uikit/docs/REAL_APP_TEST.md` | Both sides' rows. Silent-frameworks StoreKit/ImageIO/CoreImage/HTTPCookie row kept; main's presentable + Combine/os rows kept. This merge's type-check row newest. |
| `uikit/scoreboard/latest.*` / `open.txt` | From main. The keep-both merge had retained silent-frameworks' older board (`ee1844f5`); restored `origin/main`. |
| `full/foundation/URLSession.swift` + HTTPCookie golden / oracle / pytest / host script | Auto-merged from the branch (no conflict). |
| StoreKit / ImageIO / CoreImage sources + tests, `NSUbiquitousKeyValueStore`, `docs/agent_reports/silent-frameworks.md` | Added as-is from the branch. |

`swift package describe --type json` vs main's pre-merge graph: same
targets / products / dependencies, plus the branch's
`OpenUIKitStoreKit` / `OpenUIKitImageIO` / `OpenUIKitCoreImage` and
`StoreKitTests` / `ImageIOTests` / `CoreImageTests`. Shared-target
settings and dependency lists match; OpenUIKit / OpenUIKitTests source
lists grow by `NSUbiquitousKeyValueStore.swift` and
`UbiquitousKeyValueStoreTests.swift`.

No files outside `uikit/` except `full/foundation/` for the cookie golden.
No pin files. No `Package.resolved`.

## Proof (this merge)

Mac (`SIM_DEVICE_SUFFIX=-merge-silent`):

- `time swift package describe > /dev/null`: **0.52 s** (bar <20 s)
- `swift build --build-tests`: Build complete
- `swift test --filter 'StoreKit|Ubiquitous|Cookie|CoreImage|ImageIO|ConformanceRegistry'`: **28 tests, 0 failures** (ConformanceRegistry 8 including Present directory scan; StoreKit 7; ImageIO 4 + Apple oracle 2; CoreImage 3; UbiquitousKeyValueStore 3)
- `python3 -m pytest full/foundation/tests/test_foundation_formatters.py -q`: **1 passed** (HTTPCookie family 16 rows, sha256 `8d4c1d5f0afae89aeca967d54bea17d3e9d4245b028c5b5bd2b1f1d66ee4ea07`). `pytest -k cookie` collects nothing — the pin is a `subTest(name="HTTPCookie")` of `test_each_family_is_pinned_to_the_apple_golden`, not a test name containing "cookie"
- Catalyst **124/124** (`/tmp/gate-merge-silent`)
- real-app unchanged vs this main: **99.137 / 98.535 / 98.548 / 99.469 / 98.639 / 98.133 / 97.516 / 99.511 / 82.170 / 99.760 / 99.689 / 85.393**

`docker run --rm -v "$PWD":/src:ro swift:6.2-noble` (tree copied to `/work`):

- `time swift package describe >/dev/null`: **0.805 s**
- `swift build -c release --product openrender`: **Build of product 'openrender' complete! (198.71s)**

No new rendering rules. Catalyst paths stay behind the existing iOS cut.
The silent-frameworks measurements (HTTPCookie 16/16, ImageIO PNG identical
RGBA8 / JPEG maxDelta=2, CIGaussianBlur pad 3×inputRadius) are unchanged.
