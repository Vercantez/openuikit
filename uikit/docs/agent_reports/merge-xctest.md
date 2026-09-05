# Merge `origin/agent/linux-xctest` onto main (split Package.swift)

MERGE TASK, no new rendering rules. Main (`25d903e9`) already splits
`Package.swift` into typed sub-arrays (`coreProducts`/`frameworkProducts`,
`coreTargets`/`frameworkTargets`/`conformanceTargets`/`testTargets` +
`platformCombineTargets`) so Swift 6.2 type-checks. `origin/agent/linux-xctest`
(`59ac2cc4`) adds the Linux-only C target `CLinuxXCTestSupport` (10 ms
non-main dispatch timer pumping corelibs XCTest's CFRunLoop) and links it
into the three test targets, on a base whose manifest was still one
`targets:` literal. A keep-both of that literal onto the split arrays
does not type-check.

This merge keeps **every main target, product, dependency, exclude list,
swiftSettings and platform condition** and **adds the branch's Linux-only
C target the same way**: `#if os(Linux)` `linuxXCTestSupportTargets` joined
at `Package.targets`, and the three test targets' dependency lists
(`openUIKitTestDeps` / `openUIKitCTestDeps` / `swiftUITestLinuxDeps`) empty
on Darwin.

## File resolutions

| file | how it was resolved |
|---|---|
| `uikit/Package.swift` | Not keep-both. Main's split arrays kept. Linux-only `.target(name: "CLinuxXCTestSupport")` is its own `[Target]` sub-array (empty on Darwin). `OpenUIKitTests` / `OpenUIKitCTests` / Linux `SwiftUITests` depend on it via the dep arrays; Darwin deps are byte-identical to main. Join is `coreTargets + frameworkTargets + conformanceTargets + testTargets + platformCombineTargets + linuxXCTestSupportTargets`. |
| `uikit/docs/REAL_APP_TEST.md` | Both sides' rows. linux-xctest pump row kept; main's present-axes / merge-silent / silent-frameworks / … rows kept. This merge's row newest. |
| `uikit/scoreboard/latest.*` / pin files | Untouched (main). |
| `Sources/CLinuxXCTestSupport/*`, `LinuxXCTestPumpTests.swift`, `docs/PORTABILITY.md`, `docs/agent_reports/linux-xctest.md`, `scripts/linux_realapp_verify.sh`, `scripts/linux_selector_verify.sh` | Auto-merged from the branch (no conflict). |
| `Sources/ImageIO/ImageIODestination.swift`, `Sources/CoreImage/CIFilter.swift` | Main's silent-frameworks targets did not compile under `swift build --build-tests` on Linux 6.2.4 (linux-xctest branched before they landed; `openrender` does not link them). MEASURED uikit-linux: `CGFloat(truncating: NSNumber)` — no exact matches; `override setValue/value(forKey:)` — method does not override any superclass method (corelibs NSObject has no KVC, same gap as `UIVisualEffect`). Portable `CGFloat(number.doubleValue)` and `#if canImport(ObjectiveC) override`. Darwin ImageIO/CoreImage tests 9/9. |

`swift package describe --type json` vs main's pre-merge graph: **macOS
same 43 targets / 20 products / 7 test targets** (no `CLinuxXCTestSupport`);
OpenUIKitTests sources grow by `LinuxXCTestPumpTests.swift` (`#if os(Linux)`,
absent from the Darwin test list). **Linux 44 targets**, the extra one is
`CLinuxXCTestSupport` at `Sources/CLinuxXCTestSupport`.

No files outside `uikit/`. No pin files. No `Package.resolved`.

## Proof (this merge)

Mac (`SIM_DEVICE_SUFFIX=-merge-xctest`):

- `time swift package describe > /dev/null`: **0.56 s** (bar <20 s)
- `swift build --build-tests`: Build complete
- Darwin test list: **1485** names, **0** `LinuxXCTestPumpTests` (7 test
  targets unchanged vs main)
- `swift test --filter GlyphInkTableTests --filter CoreAnimationCompatibilityTests --filter ConformanceRegistryTests --filter GeometryTests --filter ColorTests --filter ABITests --filter SelectorNameTests --filter LinuxXCTestPumpTests`: **101 tests, 0 failures**
- `swift test --filter 'ImageIOTests|CoreImageTests'`: **9 tests, 0 failures**
- Catalyst **124/124** (`/tmp/gate-merge-xctest`)
- real-app unchanged vs this main: **99.137 / 98.535 / 98.548 / 99.469 / 98.639 / 98.133 / 97.516 / 99.511 / 82.170 / 99.760 / 99.689 / 85.393**

`docker exec -w /work-merge-xctest uikit-linux` (`swift:6.2-noble` 6.2.4;
tree tarred excluding `.build` / `Package.resolved`):

- `swift package describe`: **0.708 s**; 44 targets; `CLinuxXCTestSupport` present
- `swift build --build-tests`: Build complete
- `LinuxXCTestPumpTests.testPumpConstructorInstalled`: installed=1
- ink list ×10, `timeout 60`: **10/10**, 90 tests, 0 failures, **0.463–0.503 s**, 0 stalls
- selector list ×10, `timeout 60`: **10/10**, 35 tests, 0 failures, **0.104–0.541 s**, 0 stalls
- `swift build -c release --product openrender`: **Build of product 'openrender' complete! (201.92s)**

`bash scripts/linux_realapp_verify.sh /tmp/linux_realapp-merge-xctest`
from the Mac host: **rc=0**. Selector 35 tests 0.123 s, ink 90 tests
0.532 s, first try; Hello **505** opaque px; miss
`I|system-regular|17|light|F0.0|81`; headless **12/12** + live **10/10**
byte-identical vs Mac.

No new rendering rules. Catalyst paths stay behind the existing iOS cut.
The linux-xctest measurement (ink 3/5 hung → 20/20 after the pump) is
unchanged; this merge only re-expresses the manifest on the split arrays
and makes main's ImageIO/CoreImage compile in the Linux test bundle those
verify scripts now build.
