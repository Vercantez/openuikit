# `xcodeplan`: pinned Focus Xcode graph frontend

## Reusable project inventory

[`project_inventory.py`](project_inventory.py) is the reusable discovery layer
for projects that are not yet individually pinned. It accepts a shared scheme
or an explicit native target/configuration and emits canonical JSON without
invoking Xcode:

```sh
python3 full/xcodeplan/project_inventory.py \
  path/to/App.xcodeproj --scheme App --output /tmp/app-inventory.json
```

The inventory preserves classic `PBXBuildFile` order, resolves groups,
localized variant groups, and Core Data `XCVersionGroup` wrappers, records
target/project build settings, evaluates only
the documented product-name subset, and enumerates package products, local
package roots/manifests, target
dependencies, phases, sources, headers, and resources. It also supports the
simple `PBXFileSystemSynchronizedRootGroup` shape emitted by current Xcode
templates: filesystem membership is bytewise sorted, target-specific
`membershipExceptions` are applied, and opaque inputs remain single graph
items. Core ML (`.mlmodel`, `.mlkitmodel`, `.mlpackage`) and Core Data
(`.xcdatamodel`, `.xcdatamodeld`, `.xcmappingmodel`) inputs enter the
source/compiler bucket; resource wrappers such as `.xcassets`,
`.imagecatalog`, `.xcstickers`, and `.icon` enter the resource bucket.
Recognized `explicitFileTypes` are mapped by exact semantic allowlists rather
than by broad `sourcecode.*`/`audio.*`/`image.*`/`text.*`/`video.*` or
`file.*`/`folder.*`/`wrapper.*` prefixes. Empty, unknown, or file/directory
mismatched explicit types are rejected. Unknown inferred extensions and dotted
directories remain one `unclassified` input instead of being flattened into
apparently ordinary files.
An `XCVersionGroup` stays one ordered compiler input while its exact child
references, selected `currentVersion`, modern `contents` versus legacy
`elements`/`layout` storage, and optional `.xccurrentversion` plist/hash are
frozen. The PBX and plist current versions must agree. Missing, repeated,
escaping, aliased, symlinked, or unlisted model versions fail closed.
Version groups are accepted only in a sources phase, matching Xcode's model
compiler boundary.
The same Focus and synchronized-project inputs produce byte-identical output on
macOS and arm64 Linux.

This slice accepts runnable application targets and verifies that their product
reference is an `.app`/`wrapper.application` rooted in `BUILT_PRODUCTS_DIR`.
One product-identity pipeline runs for both `--scheme` and `--target`: it
validates project-level inheritance, target-level `PRODUCT_NAME`, supported
`$(inherited)`/`$(TARGET_NAME)`/project-name expansion, the PBX target's
presentation names, and the product reference. A scheme's runnable
`BuildableName` must equal the effective configured product exactly; a safe but
contradictory `PRODUCT_NAME` cannot hide behind the product-reference basename.
At least one selected project or target configuration must provide
`PRODUCT_NAME`. Native Xcode derives an empty stem when it is absent, so PBX
target names, `productName`, product-reference paths, and coordinated scheme
aliases are never used as invented defaults.
The reference itself may legitimately differ because one PBX product reference
can serve several named configurations (Focus's Focus/Klar products are the
live example). The JSON therefore records `effective_product_name`,
`buildable_name`, and `product_name_origin` explicitly instead of asking a
downstream consumer to infer the configured artifact from presentation data.
The proof also audits Xcode's adjacent native settings in both the selected
project and target configurations. Explicit `WRAPPER_EXTENSION`,
`WRAPPER_PREFIX`, `WRAPPER_SUFFIX`, `WRAPPER_NAME`, `FULL_PRODUCT_NAME`,
executable-name pieces (including `EXECUTABLE_VARIANT_SUFFIX`),
`MACH_O_TYPE`, `SKIP_INSTALL`, product type, and derived target/project names
are accepted only as literal values exactly consistent with that one identity.
Conditional variants are rejected, including Xcode's whitespace-normalized
spellings such as `PRODUCT_NAME [sdk=…]`; noncanonical direct aliases such as a
quoted `"PRODUCT_NAME "` are rejected too because native Xcode right-trims that
key. Direct wrapper/executable/signing/output path overrides, destination-derived
`SHALLOW_BUNDLE` inputs (including platform-suffixed variants), and ambiguous
`PACKAGE_TYPE` settings are not modeled and therefore fail closed. A present
bundle identifier must use a nonempty variable-free ASCII identifier grammar. This
matters because Xcode permits `FULL_PRODUCT_NAME` to disagree with
`WRAPPER_NAME`, splitting its native build graph even when both spellings look
individually safe.

Build artifact components use a deliberately narrow grammar: they start with a
Unicode letter or number, are NFC-normalized, and then contain only Unicode
letters/marks/numbers, spaces, dots, underscores, hyphens, or plus signs. This
keeps real names such as `Firefox Focus` and `Café Notes` while excluding path,
option, glob, quote, and shell-operator spellings. Every present project and
target `PRODUCT_NAME` is validated even when overridden, so unsafe values are
never silently emitted for later reuse. Selected project and target base
`.xcconfig` files are evaluated before their corresponding PBX `buildSettings`
layer. Required quoted includes run at their textual position; `=`, `+=`, and
`?=` assignments, comments, quoting, continuation, `$(inherited)`, same-setting
references, and recursively resolvable build-setting variables are modeled.
Each root and included file must be a regular, non-symlink source-root input and
is recorded in deterministic evaluation order with its SHA-256. Includes are
canonicalized to the unique tracked spelling (including the case-only spelling
drift found in Simplenote), while missing/ambiguous inputs, cycles, escapes,
optional or unknown directives, malformed assignments, and destination-
conditional settings fail closed. Variables that depend on an unmodeled
platform default remain visibly unresolved and cannot pass the literal product-
identity validators.

Safety checks pin a real, non-symlink source-root directory and reject `.`/`..`
scheme identities, explicit scheme paths without the `.xcscheme` extension,
DTD/entity declarations after XML encoding detection, repository escapes
(including lexical scheme traversal), plus project/scheme/input symlinks beneath that root
(including descendants hidden inside directory resources), duplicate
`PBXBuildFile` identities target-wide, duplicate semantic input paths within
each build role, mismatched scheme/build-action/product identities, repeated
synchronized groups, and unsupported filesystem nodes. Linking and embedding
one framework remain separate roles and require distinct `PBXBuildFile`
objects. Input identity is compared by normalized Unicode casefold spelling and,
for materialized source-root objects, device/inode identity. Case-only,
normalization-only, and hard-link aliases therefore cannot compile or package
one filesystem object twice, regardless of the host filesystem's behavior.
Synchronized paths whose membership cannot be inferred from an
extension are reported explicitly under `unclassified` and make
`unsupported_features` non-empty rather than disappearing from the graph.
Shell phases record an empty `files` array; nonempty shell-phase
`PBXBuildFile` inputs are resolved and rejected rather than escaping the
target-global identity checks.
Explicit empty scheme, target, and configuration selectors are errors; they
never downgrade to an unselected/default mode. Likewise, a present-empty PBX
presentation field is invalid rather than being treated as absent.
Every path rooted at `BUILT_PRODUCTS_DIR` or `SDKROOT` must also be a canonical
relative POSIX path. Absolute paths, parent/current-directory components,
repeated separators, backslash/drive spellings, unresolved variables, and
control or Unicode format characters are rejected. This check covers the
selected application product as well as framework and copy-phase inputs, so a
successful inventory never asks a downstream join to recover containment from
an unsafe external-tree spelling.
For ordinary file references using `<group>`, Xcode's parent components are
resolved against the containing PBX group before repository containment is
checked. This admits real layouts such as `Resources/../Images.xcassets`
without ever admitting a path above the source root. A localized variant
group's own `path` similarly rebases its physical children while its `name`
remains the logical build input.
Classic build-phase references whose final path is not materialized are kept in
the graph, listed under `missing_inputs`, and also make
`unsupported_features` non-empty. The frontend does not guess whether a shell
phase will generate them.
Native target dependencies remain explicit graph edges. Aggregate target
dependencies are also frozen with their configuration list, ordered build
phases, and nested dependency references, but are reported as provider gaps
because the frontend does not execute their shell phases.

This initial source-root model accepts absent/empty values for both project
directory fields and the legacy `.` spelling for `PBXProject.projectDirPath`.
Nonempty `projectRoot` and other `projectDirPath` values are rejected rather
than scanning the project-parent directory while Xcode silently rebases
`SRCROOT`; safely honoring nontrivial rebasing is a future inventory slice.

This reusable slice deliberately rejects synchronized
`explicitFolders`, build-phase membership exception sets, custom build rules,
and target exception metadata such as per-file compiler flags, platform
filters, and header visibility. Destination-conditional `.xcconfig` selection,
shell execution, resource compilation, local-package
source expansion, target transitivity, compilation, linking, signing, and
launching remain downstream stages. Thus a successful inventory means “the
selected graph was understood within this boundary,” not “the app is
buildable.” Non-application native targets require a later product-identity
mapping before this generic frontend will accept them.

`xcodeplan.py` turns one specifically attested Xcode scheme/target into stable
JSON that Linux-side build work can consume. It is a parser, not a filename
census: the tool parses the shared scheme XML and the OpenStep
`project.pbxproj`, follows PBX object identifiers, resolves group-relative and
variant-group file references, and preserves Xcode's build-phase and build-file
ordering.

It uses only the Python 3.10+ standard library and the `git` command. The
repository's `harness/Dockerfile` installs the distribution's `python3`
package alongside the cross-compilation tools needed by the guest drivers.

The accepted subject is focus-ios commit
`a2832521c1daa0c23419c73705ae043ed60c9791`, scheme `Focus`, launch
configuration `FocusDebug`, target `Blockzilla`. The project, scheme, local
package manifest, and workspace `Package.resolved` are individually SHA-256
pinned. The expected `focus-ios/` Git worktree prefix is attested and Git runs
with ambient `GIT_*` overrides and user/system configuration disabled. Tracked
worktree changes are rejected. Untracked or ignored files outside the consumed
graph are irrelevant, but they cannot satisfy a graph input or appear anywhere
beneath a consumed directory resource.

Run it from this repository with:

```sh
python3 full/xcodeplan/xcodeplan.py \
  scratch/ladder-corpus/focus-ios/focus-ios \
  --output /tmp/focus-plan.json
cmp full/xcodeplan/focus-plan.json /tmp/focus-plan.json
```

Success means the generated bytes exactly equal the checked
[`focus-plan.json`](focus-plan.json) attestation (SHA-256
`7d7fa64265cf926de3caf37c3227ff57649492713a8360abe2e6f968183f0568`).
Any pin, parse, reference, variable, graph, or canonical-byte mismatch exits 2
and writes no plan to stdout.

## Accepted graph

The parser requires all of these facts simultaneously:

- exactly eight ordered build phases: Copy Wordmark, Swiftlint, Glean, Nimbus,
  Sources, Frameworks, Resources, Embed App Extensions;
- four known `/bin/sh` phases, with hashed script bodies, an explicit shell
  variable allowlist, and fully resolved input/output paths;
- 132 ordered source build-file references: 131 Swift references and one
  localized `Intents.intentdefinition` reference;
- 10 framework products, 26 resource references, and four embedded extension
  products copied from `BUILT_PRODUCTS_DIR` with `RemoveHeadersOnCopy`;
- direct dependencies `ContentBlocker`, `ShareExtension`,
  `FocusIntentExtension`, and `WidgetsExtension`;
- package products `SnapKit`, `Fuzi`, `Sentry`, `Glean`, `UIHelpers`,
  `DesignSystem`, `Onboarding`, `FocusAppServices`, `AppShortcuts`, and
  `Licenses`.

The attested workspace lock resolves SnapKit 5.7.0 at
`e74fe2a978d1216c3602b129447c7301573cc2d8`. The current Focus census and module
proofs now use that same locked revision rather than the earlier diagnostic
checkout of upstream `main`. `xcodeplan` still records only the dependency
identity; each runnable build/proof must fetch and validate the locked source
subject separately.

Every PBX build-file, file, product, configuration, target, group, variant,
and dependency identifier used by that graph must resolve. Non-generated source
and resource paths and declared shell inputs must match their pinned Git blobs,
types, and executable modes. Consumed directories are recursively matched to
the pinned Git tree, so untracked, ignored, missing, or byte-modified descendants
cannot alter their build contents. Duplicate shell outputs are rejected.
`Metrics.swift` and `AppNimbus.swift` are accepted
as absent only because earlier, ordered shell phases declare those exact output
paths. Unknown phase classes, reordered phases, build rules, proxy-only target
dependencies, unexpected source trees, repository-escaping paths, unapproved
copy settings, unknown shell variables, shell command substitution, and
unresolved Xcode variables all fail closed.

## Complete portable application inputs and bundle resources

`application_build_plan.py` turns a successful project inventory into the
immutable input boundary for an application build. It reads every ordered
Swift source, every resource descendant, and the selected Info.plist from the
untouched source tree; classifies the supported `.intentdefinition` compiler
input separately from Swift sources; generates the single-scene entry point;
and writes all outputs into a brand-new directory outside that source tree.
Other non-Swift compiler types still refuse. Source and physical compiler-input
lists are emitted separately as NUL-delimited paths, so whitespace in an Xcode
group never becomes shell syntax. `prepared-inputs.json` hashes both manifests.
`--verify` rehashes the complete source/compiler-input/resource boundary before
and after compilation:

```sh
python3 full/xcodeplan/application_build_plan.py app-inventory.json \
  --source-root /read/only/AppProject --output-dir /new/build-plan
python3 full/xcodeplan/application_build_plan.py \
  /new/build-plan/application-build-plan.json \
  --source-root /read/only/AppProject --verify
```

When the target selects local Swift-package products, the application plan
also embeds the fail-closed graph documented in
[`docs/LOCAL_SWIFT_PACKAGE_GRAPH.md`](../../docs/LOCAL_SWIFT_PACKAGE_GRAPH.md).
It publishes separately hashed `local-package-graph.json` and
`local-package-targets.nul` inputs and reconstructs every manifest, pin, edge,
and source hash during normal verification. A frozen graph with unresolved
remote source remains valid provenance but is explicitly not buildable.

Application build-plan format 2 publishes `compiler_inputs` in source-phase
order. Each `open-intentdefinition` record contains its virtual
`logical_path`, one physical `primary_path`, and ordered
`input_files[{path,sha256,size}]`. A direct file is a one-file record. A
localized PBX variant group must resolve to exactly one first
`*.intentdefinition`, followed only by same-stem `*.strings` files under
distinct immediate `*.lproj` siblings; every byte and the declared order are
attested. Unsupported extensions, reordered/multiple definitions, malformed
localization topology, aliases, symlinks, and post-plan mutation fail closed.
`compiler-inputs.nul` flattens those physical input files in record order while
`app-sources.nul` remains Swift-only.

The plan records each resource's bundle destination. Current
filesystem-synchronised applications preserve the hierarchy beneath their
top-level `Resources` directory; localised `.lproj` descendants remain
localised; traditional entries default to their basename. Case-folded
destination collisions and unsafe paths refuse instead of overwriting one
resource with another.

`materialize_application_bundle.py` consumes that frozen plan and creates a
relocatable `<Product>.app/Contents/{MacOS,Frameworks,Resources}` skeleton.
It copies the unchanged Info.plist and complete application resource graph,
then installs the complete attested OpenUIKit data/font resource tree beneath
`Contents/Resources/OpenUIKit`. Every copied byte is re-read and recorded in a
canonical materialisation manifest. Source or platform symlinks, a reused
output, a missing semantic-colour/font input, and an application collision
with the reserved platform resource directory all refuse. The executable host
binds `OpenUIKitRuntime` to these bundle-relative resources before the first
window tick, removing checkout/build-container paths from the runtime contract.

`core_guest_package.py` validates the other half of the boundary: one
relocatable, Linux-built ARM64 platform package. Its canonical manifest names
the SDK, target modules, headers, Mach-O dylibs, link objects, UIKit resources,
and machorun guest root; publishes compiler/linker arguments relative to the
package root; and pins every module, dylib, Preview object, resource, and font
by size and SHA-256. Absolute host paths, output/module/plugin flags owned by
the application driver, missing framework families, symlinked libraries or
resources, and a partial Preview tuple all refuse. The validator also rehashes
every published attestation, recursively rebuilds the SDK's exact
`core-tree-v1` ledger without following links, and rejects dangling, absolute,
or SDK-escaping symlink targets before accepting the reusable package.

`build_portable_application_guest.sh` composes those boundaries into the
complete application build:

```sh
full/xcodeplan/build_portable_application_guest.sh \
  --inventory /pins/App.project-inventory.json \
  --source-root /read/only/AppProject \
  --platform-package /artifacts/open-uikit-core \
  --container-image sha256:138303d276d49b9b3b6aa9ee277dfb30b876e24557f80c07fd5d52044ef2d9d7 \
  --remote-package-materializations /pins/exact-materializations.json \
  --remote-package-cache /read/only/content-addressed-cache \
  --preview-plugin /artifacts/OpenUIKitPreviewMacros-tool \
  --preview-evidence-source-list /pins/App.preview-sources.nul \
  --output-root /new/App-linux-build
```

The host requires an absent output root and an exact lowercase SHA-256 Docker
image content ID, validates that the image is Linux/ARM64, validates and hashes
the platform and optional macro plugin, freezes all application inputs, and
creates the bundle resource skeleton. The image identity and platform are
recorded in `host-inputs.tsv`; mutable image tags are refused. Exact remote
package inputs are revalidated on both sides of a read-only cache mount as
described in [`../../docs/REMOTE_SWIFT_PACKAGE_MATERIALIZATION.md`](../../docs/REMOTE_SWIFT_PACKAGE_MATERIALIZATION.md).
That container then compiles every reachable local or remote package target as
its own topologically ordered Swift module and object set. Those objects enter the
executable link exactly once. It then compiles every NUL-delimited unchanged
application Swift source together with only the generated entry point and
platform host loop in one ordinary multi-source module invocation. An exact
output-file map assigns one ARM64 Mach-O object to every source; the driver
rejects missing, extra, reordered, symlinked, non-ARM64, or reused outputs,
hashes the exhaustive mapping/object ledger, measures real cross-file symbol
edges, and links every object exactly once in deterministic source order. WMO,
explicit batch scheduling, production macro dumping, and caller-owned output
maps are refused because they would change this measured compiler contract.
When the package
declares DeveloperToolsSupport, it loads the exact host macro executable,
links the package's framework closure, copies
its dylibs into `Contents/Frameworks`, recursively proves the Mach-O runtime
closure, and cold-launches the packaged executable under machorun. Success
requires one active UIWindow and three paced production loop turns. Source,
support, plugin, and package brackets are rechecked after execution; partial
outputs remain visibly unusable and can never be passed as a fresh output.
Preview-enabled packages also publish the exact bounded macro diagnostic
arguments and require a NUL-delimited `--preview-evidence-source-list`. That
list must be a normalized, target-ordered, nonempty proper subset of the frozen
application sources, contain a literal `#Preview`, and type-check successfully
as the application module. Only this caller-supplied dependency-closed subset
receives `-dump-macro-expansions`; dumping the full application module is
forbidden. The driver captures the bounded proof as
`app-macro-expansions.stderr`, records its exact source/argument hashes, and
rejects `Internal Error:`, unlocated fatal/error diagnostics, or ordinary
source errors even when swiftc returns zero. Production compilation has a
separate `application-compile.stderr` and never receives the dump flags. The
driver also attests that the target-side
DeveloperToolsSupport object appears exactly once in the executable link. It
also matches UIKit's sole measured DTS import to the object's definition and
exports only that exact Preview initializer from the application executable;
post-link symbol counts must be one in Preview mode and zero otherwise. A
post-link symbol audit additionally proves that none of the measured
application-internal references remain undefined. The compile mode, exact
output-map count, zero WMO/dump/disable-batch counts, object count, and evidence
hashes are recorded in `application-compile-audit.tsv`.

Compiler-input providers have one deliberate insertion boundary. After the
application plan is frozen and verified, but before the final output-file map
is created, `compiler_input_providers.py` populates a brand-new output-owned
`derived-sources/` root. Its first production provider consumes the planner's
exact `open-intentdefinition` records and invokes the independent open
`.intentdefinition` compiler. The provider publishes an ordered NUL manifest
and canonical attestation binding the provider/tool identity, exact tool hash,
every frozen model/localization input hash, and every regular non-symlink
generated Swift path/hash/size. It verifies that complete contract immediately
after generation and again after cold launch.

The driver order is always unchanged application sources, then attested
derived sources, then the generated scene/bootstrap host sources. Output-map,
ARM64 object, cross-file, deterministic link, and final hash audits apply to
the combined list. A target with no compiler inputs still publishes an
explicit empty provider attestation; unsupported non-Swift inputs fail closed
instead of being silently dropped or copied into application source.

## Tests

The self-contained fixture covers all eight phase classes plus localized file,
generated-source, dependency, package-product, and copy-product resolution:

```sh
python3 -m unittest discover -s full/xcodeplan/tests -v
```

The same command also exercises a two-target Xcode 16-style synchronized
fixture, including target-specific exclusions, explicit file types, classic
compatibility, scheme identity, canonical output, and symlink/escape controls.

The live pinned checkout/canonical integration test is opt-in so the unit suite
does not require a 3rd-party checkout:

```sh
FOCUS_IOS_CHECKOUT="$PWD/scratch/ladder-corpus/focus-ios/focus-ios" \
  python3 -m unittest discover -s full/xcodeplan/tests -v
```

## Boundary

This does not run Xcode, interpret arbitrary projects, execute shell phases,
compile proprietary asset catalogs or intent definitions, select destination-
conditional `.xcconfig` assignments, execute arbitrary `Package.swift`, or
materialize remote Swift packages. It derives only the documented ordinary
local-library SwiftPM graph, not a general Swift compiler/linker graph. Source-form
`.xcassets` directories are preserved for OpenUIKit's measured reader. Shell bodies remain opaque, pinned
inputs represented by a digest plus their validated variable surface; parsing
shell semantics would be a separate frontend. The tool also selects only the
scheme's runnable `Blockzilla` target, not its test action or transitive target
builds. Those limits are why this frontend is named `xcodeplan`, not
`xcodebuild`.

## Application entry-point planning

`scene_bootstrap.py` consumes a materialized application inventory and emits a
new build input outside the application's source tree. It recognizes two
production entry shapes and rejects every other top-level `@main` declaration.

The UIKit shape is the ordinary one-`UIWindowScene` Xcode template: exactly one
`@main UIApplicationDelegate`, one Info.plist-selected
`UIWindowSceneDelegate`, no storyboard/custom scene class/multiple-scene
configuration, and no missing or unsupported inventory entries. Delegate
declarations must be visible across files, directly inherit `UIResponder`, and
declare no initializer; otherwise the tool rejects the inventory before
writing output. This deliberately narrow rule proves both generated
zero-argument constructions instead of hoping the compiler finds them later.

The generated `static main()` first asks `PortableUIKitApplicationHost` to
validate and bind the resources packaged beside the executable. This happens
before even constructing the unchanged app delegate: OpenUIKit's process-wide
font and color tables are lazy and may otherwise be initialized permanently
from an obsolete working-directory path during an initializer or
`viewDidLoad`. The host repeats the same idempotent preparation at its run-loop
boundary. It then launches the unchanged app delegate, asks it for the scene
configuration, connects the unchanged scene delegate, transitions that scene
active, and enters the real monotonic, sleeping `UIKitRunLoop`; the proof
runner sets `OPENUIKIT_HOST_TURNS` only to bound that same loop for automation.

The SwiftUI shape is one top-level `@main struct` directly conforming to `App`
or `SwiftUI.App`. Its physical Info.plist remains a frozen bundle input, but it
does not need a UIKit scene manifest or scene delegate: `App` already inherits
its default main from the production `libSwiftUI.dylib`, and each `WindowGroup`
creates its real OpenUIKit scene/window/hosting-controller graph. The planner
therefore emits a deterministic comment-only `GeneratedSceneBootstrap.swift`
and records `entry_point: swiftui-app-default-main`; it never emits an
extension or competing `static main()`. Verification reparses the frozen
sources, reclassifies the entry point, checks branch-specific provenance, and
reconstructs the generated bytes before accepting a build plan.

The current executable proof is intentionally smaller than the Reminder app:
it compiles exactly the two unchanged delegate files out of the inventory's 22
Swift files, plus generated/build-support inputs. The support declarations
stand in for Reminder's model and first controller so `SceneDelegate`'s real
`willConnect` body can construct its real navigation/window graph. They are not
application-source edits and are not a claim that the other 20 files compile.

From the host, with the pinned Reminder inventory and source tree available:

```sh
UIKIT_CHECKOUT=/path/to/uikit \
MACHORUN_CHECKOUT=/path/to/machorun \
  full/xcodeplan/build_and_run_reminder_scene_guest.sh \
    /path/to/Reminder.project-inventory.json /path/to/Reminder/source-root
```

The script regenerates the exclusive bootstrap, records input hashes and the
2/22 boundary, runs the existing `full/scripts/build_full.sh` substrate, emits
a Linux-produced arm64 Mach-O, and executes it under `machorun`. The composed
path targets macOS 15 and links the exact pinned FoundationEssentials,
swift-collections, local `os`, and C-shim object closure used by literal UIKit;
the upstream compile-input digest is part of the full-build subject. A
successful bounded proof records markers for unchanged `willConnect`, one
active window, and the requested number of clocked host-loop turns under
`build/full/scene-guest/`.
