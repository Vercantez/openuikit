# Route (a): Focus selector wall

Measured 2026-09-07 on branch `agent/route-a-selector-wall`, starting at
`12bb634cdc3c7ea5fa4f044d5d2a42dedc25127e`. This is a compiler/dispatch probe;
no rendering rule or upstream Focus source was changed. The dated 2026-09-16
ladder artifacts are frozen inputs, not captures made during this run.

## Census and denominator

The reproducible [census](route-a-selector-census.md) and its
[per-occurrence JSON](route-a-selector-census.json) enumerate paths, line
numbers, code, per-file counts and NSObject ancestry. Comments and strings
are excluded; conditional compilation branches are included.

| Scope | Swift files | `#selector` | `@objc` | `@objcMembers` | selector `perform` calls | direct / indirect NSObject subclasses |
|---|---:|---:|---:|---:|---:|---:|
| `Sources/Blockzilla` | 131 | 74 | 82 | 0 | 4 | 3 / 59 |
| `Sources/BlockzillaPackage` | 51 | 3 | 3 | 0 | 0 | 0 / 7 |
| SnapKit | 37 | 0 | 0 | 0 | 0 | 0 / 1 |
| Fuzi | 8 | 0 | 0 | 0 | 0 | 0 / 0 |

NSObject ancestry above is the iOS SDK inheritance chain, **not** a claim
that native Linux OpenUIKit has the same NSObject superclass graph. The
census lists the local Focus service adapters separately. Resolved
OpenCombine/SwiftSyntax packages and general framework ports are outside
this vendored-app denominator.

Blockzilla has 129 upstream files plus two launch/generated files. The
frozen 227-file whole-repository Focus census includes targets/tests absent
from that slice. Its 77 selectors agree with Blockzilla + BlockzillaPackage;
its 86 lexical `@objc` hits include the URLBar block comment, yielding 85
code attributes. Its one `@objcMembers` is in non-vendored
`ScreenshotTests/SnapshotHelper.swift`. `deps-census-2026-09-16.json` scans
30 dependency repositories; the 20-app counts are in the ladder census.
The wall audit measures public type declarations, not selector compilability.

The four dynamic calls, all still unsupported by this adapter, are:

* `AutocompleteCustomUrlViewController.swift:178`: delayed `updateEmptyStateView`.
* `KeyboardType.swift:24`: runtime `identifier` lookup.
* `WebCacheUtils.swift:64,66`: `optionalSharedHistory` and `removeAllItems`.

## Compiler options and runtime boundary

Experiments use the operator's `uikit-linux` container, Swift 6.2.4,
`aarch64-unknown-linux-gnu`, exclusively under `/work-route-a`. The uikit
and objc4-linux trees were copied with tar; `/src` and `/work` were untouched.
Exact commands, exit statuses, diagnostics and emitted-code excerpts are
carried in the [55-command option matrix](route-a-objc-options.json) and
[option analysis](route-a-objc-options.md).

| Candidate | Measured result | Conclusion for Focus |
|---|---|---|
| Stock compiler | `Objective-C interoperability is disabled`; `'#selector' can only be used with the Objective-C runtime` | Original selector-bearing files cannot compile |
| `-enable-experimental-feature ObjCInterop` | Same diagnostics | This flag alone does not enable the compiler path |
| `-Xfrontend -enable-objc-interop` (also both flags) | `import the 'ObjectiveC' module to use '#selector'`; downstream object/link tests expose runtime symbols | Parsing/typechecking flags do not supply the required runtime ABI |
| Swift `Selector` / `NSObject` shim modules | Can pass typecheck/object emission with the frontend flag; stock runtime linkage and selector representation remain wrong | A module named ObjectiveC is insufficient |
| Explicit route-(a) source lowering | Measured names plus existing `SelectorDispatching` / `ActionTable`; separate generated copies | Selected for the Focus execution proof |

The freshly built objc4-linux runtime independently fires a C Objective-C
action (`OBJC4_TARGET_ACTION_FIRED`). That establishes the C runtime control,
not stock Swift/ObjC interoperability. The SwiftObject class/metaclass
symbols requested by interop-enabled native Swift classes are absent from
stock `libswiftCore`. The name:String Selector shim also has an observed
ABI mismatch: emitted IR stores an 8-byte ObjC selector pointer but returns
a 16-byte String-shaped value.

Importing the actual objc4 `NSObject.h` as `ObjCRoot.NSObject` and using a
pointer-shaped Selector gets an isolated Swift subclass through compilation
and linking. Instantiating it crashes with SIGSEGV (`-11`) in the tested
runtime configuration before action delivery; allocation without selectors
crashes at the same stage. This is a measured boundary, not proof of the
crash's root cause or impossibility under every runtime configuration.

## Bounded source lowering

`Tools/ingest/route_a_selectors.py rewrite --route-a` resolves same-file,
explicitly `@objc`, synchronous Void instance methods with zero or one
simply typed parameter. It creates `Selector.named(...)` expressions and a
dispatch witness **inside the original class**, so private methods remain
private and real app method bodies run. Source output must be a separate
file; no output is written when any selector/attribute is unresolved.

The Apple Swift selector-name oracle measures zero-argument, underscore,
explicit-ObjC-name, and the actual Focus named-label spellings. In particular
`toggle(sender:)` is `toggleWithSender:` and `toggleSwitched(_:)` is
`toggleSwitched:`. An unqualified universal With+label rule would be wrong:
`f(with:)` exports as `fWith:`. Inferred labels are restricted to the
measured `sender`, `notification`, `gestureRecognizer`, `enabled` and
`clipboardString` set; an explicit ObjC name can supply another label.

Across the 77 selectors / 85 attributes in Blockzilla + BlockzillaPackage,
the conservative adapter identifies **75/77 selector expressions and 81/85
attributes**. Its refusal to emit partial files reduces deliverable source
coverage to **67/77 selectors and 74/85 attributes in 29 selector-bearing
files**. Therefore **10 selectors and 11 attributes remain un-emittable**.
This is source-emission coverage, not 67 compiled or executed call sites.
The [complete coverage JSON](route-a-selector-rewrite-coverage.json) carries
each input SHA-256 and each unsupported-site reason.

The blocked files are WebViewController (`@objc` array property),
AutocompleteCustomUrlViewController (extension-scoped selector reference),
AutocompleteTextField (non-Void action), Combine+UIControl (generic class),
and InsetButton (`@objc` declaration in an extension; no selector).
Inherited/protocol exposure, KVC, dynamic `perform`, and Foundation
timer/notification selector delivery are not implemented. Generated app
inheritance/conformance still requires compiler validation across files.
The original route-(b) source stays intact and the full route-(a) Focus app
has **not** been built or launched.

The supplied ladder §9 actually lists Focus as **NEAR on both routes**, not
FAR as the task description says. These are frozen ordinal-policy scores;
this run supplies a compiler measurement without silently rescoring them.

## Focus compile and execution proof

`Tools/ingest/route_a_focus_probe.py` compiles the complete pinned
`SwitchTableViewCell.swift` and `ThemeTableViewToggleCell.swift`, first
original and then lowered. It uses the real PaddedSwitch, ToggleItem and
SystemThemeDelegate sources, production OpenUIKit/UIKit and the actual
OpenCombine-backed Combine product. Only Settings storage, colors and a
localized label are fixture dependencies; no fixture implements an action.

The probe dispatches `.valueChanged` three times per cell. The theme cell
must call its delegate with `[true, false, true]`; the other cell's private
`toggle(sender:)` must publish that sequence through Combine. Unresolved
selectors fail the probe. Source SHA-256 values are checked after the run.

The [execution record](route-a-focus-probe.json) includes exact original
diagnostics, every build/rewrite/run command and the five unchanged source
hashes. Original sources produce two selector errors, two disabled-interop
errors and a cascading lazy-property type error. Both generated files compile
with **zero errors**, then print:

```text
ThemeTableViewToggleCell: valueChanged -> private toggleSwitched(_:) -> delegate = [true, false, true]
SwitchTableViewCell: valueChanged -> private toggle(sender:) -> Combine = [true, false, true]
ROUTE_A_SELECTOR_PASS cells=2 deliveries=6 unresolved=0
```

Before/after: **0/2 → 2/2 complete Focus cell files compile**; action execution
was unavailable before and is now **6/6 deliveries, zero unresolved**.
The generated executable uses stock native Linux Swift, without ObjC flags
or the experimental runtime/shim modules.

To reproduce after copying `uikit/` into the reserved scratch tree:

```sh
docker exec uikit-linux bash -c 'cd /work-route-a/uikit && swift build -c release --product openrender && swift build -c release --target UIKit && python3 Tools/ingest/route_a_focus_probe.py --out /work-route-a/focus-probe'
python3 -m unittest discover -s Tools/ingest -p 'test_route_a_*.py'
```

The copied manifest is restored after both compilation paths. Python census
and rewriter tests: **18/18**. Native Linux release `openrender` and `UIKit`
builds are green (620.08 s / 5.44 s); generated-cell build 4.56 s. Native Mac
release `openrender` builds (933.69 s). No production app/library/rendering
source, scene, golden, package manifest or pin changes are part of this branch.

## Regression verification

Fresh private-device iOS suite, Catalyst, real-app screens, nearby Swift
selector tests and the CHECK_ONLY operator gate are in progress. Final
measurements will be appended before the branch is pushed.
