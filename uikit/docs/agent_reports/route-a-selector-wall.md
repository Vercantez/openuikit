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
| Local Focus dependency adapters | 14 | 0 | 0 | 0 | 0 | 11 / 2 |

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

The [direct swiftc reproduction](route-a-focus-direct-swiftc.json), driven by
`Tools/ingest/route_a_focus_swiftc.py`, typechecks the complete original
ThemeTableViewToggleCell against the built native UIKit/OpenUIKit modules,
without modifying Package.swift. Default flags and the experimental-feature
flag each give exactly two errors: line 30 disabled `@objc`, and line 21
`#selector` requiring the ObjC runtime. The frontend interop flag instead
reports the UISwitch argument as not representable in Objective-C and asks
for the ObjectiveC module. The lowered file gives **2 → 0 errors**, exit zero
with empty diagnostic output. Exact argument arrays and source hashes are
carried in the record.

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

* Fresh private iOS 26.1 capture: **112/113**, sole `corner_radius` miss
  **99.411**, zero layout issues. All 113 scenes captured with the private
  `-route-a-selector-wall` simulator suffix.

* Catalyst: **124/124**, 178 rendered PNG hashes carried in the
  [regression record](route-a-selector-regressions.json).
* Real-app: **12/12 enforced floors hold**. Fifteen screens render, fourteen
  have existing goldens; the Focus browser golden is absent, so its score is
  unavailable. History/settings/dark/storage: **99.137 / 98.535 / 98.548 /
  99.740**; xs/xxxl/ax1: **98.720 / 98.334 / 97.549**; iPad
  settings/history/storage: **99.650 / 99.860 / 99.734**; Focus settings/home:
  **98.823 / 99.287**; Hackers feed/Ledger: **98.235 / 99.610**.
* Replaying after importing main leaves **178/178 Catalyst**, **113/113
  iOS** and **14/15 real-app** PNGs byte-identical to the earlier run. The
  one changed real-app image is Hackers, **94.662 → 98.235**, from the
  operator's upstream pill change; it is not a selector-adapter improvement.
* `swift test --filter 'Selector|ActionTable'`: **38/38**, zero failures.
* Python census/rewriter tests: **18/18**.
* Production `Sources`, `Package.swift`, fixtures and goldens are identical to
  the final merged main baseline `21a78014`; the generated adapter is opt-in and outside all production
  targets. No production-source stash is needed to establish unchanged
  renderer inputs.

The first CHECK_ONLY attempt found a concurrent fidelity-table insertion
conflict after the operator advanced main. Merge `f94894d2` imports main
`21a78014` and preserves both rows. The rerun is now checking that merged
production baseline. It is invoked from the repo root with the existing `ALLOW_PATHS` hook scoped
only to the brief-authorized ladder document:

```sh
export ALLOW_PATHS='^full/ladder/APP_LADDER[.]md$'
CHECK_ONLY=1 bash uikit/scripts/agent_merge.sh agent/route-a-selector-wall
```

The operator stopped that run; the final CHECK_ONLY result was not carried in this historical section. The resumed branch records its own proof below.


## Resumed 2026-09-07: one generic publisher blocker closed

Branch `agent/route-a-selector-wall3`, based on carried `46f92fe9`. This run
handles only the **Combine+UIControl generic-class blocker** above. Its publisher
is used at **10** Focus call sites: BrowserToolbar lines 106/115/124/138 and
URLBar lines 462/471/480/489/504/518. This makes one complete dependency usable;
it does not establish compilation or execution of those ten UI call sites.

The [measurement record](route-a-generic-control.json) carries input hashes,
commands, original diagnostics, oracle output, Linux output, and coverage.
Both platforms compile the **same complete upstream file**
`Sources/Blockzilla/Blockzilla/UIComponents/URLBar/Combine+UIControl.swift`
(SHA-256 `cc7ebea3216547a308dbbe0954eedd0d3f73530e00e467525ad9e28594d937fa`).
Only the Linux generated copy is lowered. There are no app dependency stubs,
substitute actions, mock publishers, ObjC flags, or production-library changes.

**Oracle:** private iPhone 16 `OpenUIKit-GenericControl-route-a-selector-wall3`,
iOS **26.1 (23B86)**, **3x**, Apple Swift **6.2.1**, Swift language mode 5.
The original file compiles and registers exactly **`eventHandler`**.
`Probe.swift` exercises three concrete subscriptions: Sink/UIControl,
Sink/UISwitch, and LimitedSubscriber/UIButton. Linux uses the actual
OpenCombine-backed `Combine` module and stock Swift **6.2.4**, native
`aarch64-unknown-linux-gnu`, in the operator container's `/work-route-a/uikit`
scratch copy. The copied package manifest is restored and the original
source hash is unchanged after execution.

| Measurement | iOS 26.1 original | Linux before | Linux lowered |
|---|---:|---:|---:|
| Complete publisher file compiles | yes | **no: 2 diagnostics** | **yes: 0 errors** |
| Sink/UIControl matching event deliveries | 3 | unavailable | 3 |
| Sink/UIControl wrong-event deliveries | 0 | unavailable | 0 |
| Sink/UIControl total after cancellation | 3 | unavailable | 3 |
| Sink/UISwitch values, including wrong event and cancellation | `[true, false]` | unavailable | `[true, false]` |
| LimitedSubscriber/UIButton deliveries after requesting one | 2 | unavailable | 2 |
| LimitedSubscriber/UIButton wrong-event deliveries | 0 | unavailable | 0 |
| LimitedSubscriber/UIButton total after cancellation | 2 | unavailable | 2 |
| Delivered input is the exact original control | **7/7** | unavailable | **7/7** |

All **10 JSON result fields match exactly**, including all seven identity
checks. The upstream `request(_:)` intentionally ignores demand; this run
preserves its measured behavior. The initial native introspection attempt
using `allTargets` trapped in Swift's Set-to-NSObject bridge. Querying
`actions(forTarget:forControlEvent:)` with the known generic subscription
measures the name without that harness failure; no upstream source was edited.

Exact original Linux errors (no other target errors):

```text
Combine+UIControl.swift:56:6: error: Objective-C interoperability is disabled
Combine+UIControl.swift:44:41: error: '#selector' can only be used with the Objective-C runtime
```

Before this change, the adapter independently refused the file with
`generic class requires separate dispatch evidence`. It now supports a bounded
**final generic class**, simple named parameters/constraints, simple inherited
type names, optional same-type requirements between generic parameters, and
**zero-argument synchronous Void actions**. The generated table and unapplied
method reference explicitly use `UIControlSubscription<SubscriberType, Control>`;
`SelectorDispatching` is inserted before the `where` clause. Non-final/nested
generic classes, parameter packs, generic superclass applications, other
requirements, parameterized actions, and references from outside the enclosing
specialization remain refused. This is opt-in route-(a) source generation;
route-(b) and original Focus sources remain unchanged.

Re-auditing the same 77 selectors / 85 attributes gives:

| Coverage | Before | After |
|---|---:|---:|
| Recognized selector candidates | 75/77 | **76/77** |
| Recognized attribute candidates | 81/85 | **82/85** |
| Selectors in emittable whole files | 67/77 | **68/77** |
| Attributes in emittable whole files | 74/85 | **75/85** |
| Emittable selector-bearing files | 29 | **30** |
| Selectors / attributes still in blocked files | 10 / 11 | **9 / 10** |

Remaining incomplete files are WebViewController (1 selector / 2 attributes),
AutocompleteCustomUrlViewController (2 / 2), AutocompleteTextField (6 / 5),
and InsetButton (0 / 1); exact rejected sites are in the record. All **4 dynamic
perform calls** remain outside this bridge. Whole-app route-(a) compilation,
KVC, inherited/protocol exposure, and timer/notification bridges remain open.
No other blocker was attempted in this resumed run.

Reproduction, from `uikit/`:

```sh
python3 Tools/ingest/route_a_generic_control_probe.py oracle --out /tmp/generic-oracle
# Copy this tree into uikit-linux:/work-route-a/uikit and oracle.json into /work-route-a/.
docker exec uikit-linux bash -c 'cd /work-route-a/uikit && python3 Tools/ingest/route_a_generic_control_probe.py linux --out /work-route-a/generic-proof --oracle /work-route-a/oracle.json'
python3 -m unittest discover -s Tools/ingest -p 'test_route_a_*.py'
```

Focused verification: **22/22 Python tests**, including the actual generic file
and fail-closed grammar boundaries. Linux's generated full-file build succeeds
in **2.67 s**, and execution prints
`ROUTE_A_GENERIC_CONTROL_PASS specializations=3 deliveries=7 oracle_fields=10`.
The original Linux build also rebuilt production UIKit/OpenUIKit successfully
before reporting the two expected errors in the unmodified app file. Re-running
the existing two-cell Linux proof also passes **6/6 deliveries, 0 unresolved**,
with both original source hashes preserved.

The branch3 CHECK_ONLY gate will be recorded here after completion. No pixel
rule, scene, golden, app source, package manifest, vendor pin, or file outside
`uikit/` was changed by this resumed step.
