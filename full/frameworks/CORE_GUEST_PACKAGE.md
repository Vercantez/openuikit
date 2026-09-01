# Cold core guest package

`build_core_guest_package.sh` is the reusable platform half of the untouched
application pipeline. It rebuilds the production ARM64 Mach-O substrate from
cold inputs and publishes one relocatable package. The Xcode-project planner
and app executor consume that package; they do not reproduce framework build
logic.

This is production code, not a mock SDK. The package contains the target
modules and dylibs for FoundationEssentials, OpenCoreGraphics, OpenUIKit,
OpenCombine, Dispatch, Combine, Symbols, SwiftUI, the app-facing Foundation facade, final
Foundation-visible UIKit, CoreImage, QuartzCore, Intents, IntentsUI, WebKit,
LocalAuthentication, SafariServices, Network, StoreKit, AudioToolbox,
CoreHaptics, PassKit, CoreGraphics, ImageIO, LinkPresentation, MessageUI,
MobileCoreServices, Security, CryptoKit, CommonCrypto, AppIntents, OSLog,
UniformTypeIdentifiers, SwiftData, UserNotifications, QuickLook, and its
`_QuickLook_SwiftUI` cross-import overlay, CoreMedia, AVFoundation, AVKit,
Charts, CoreTransferable, Photos, PhotosUI, and the `_PhotosUI_SwiftUI`
cross-import overlay, Accelerate, Compression, CoreText, AdServices,
NaturalLanguage, AuthenticationServices, the
`_AuthenticationServices_SwiftUI` cross-import overlay, and FoundationModels
with its native host compiler plugin for `@Generable` and `@Guide`.
NaturalLanguage is backed by a deterministic Unicode-script and Latin-language
classifier. The app-facing `zlib` Clang module is backed by a separate
`libz.dylib`. IOKit is a package-owned Swift overlay over a package-owned
`IOKit.framework` C module and dylib, with its complete 53-symbol Apple Swift
runtime contract supplied by a separate `libswiftIOKit.dylib`. Together these
are fifty-eight reusable ARM64 Mach-O platform binaries (fifty-four Swift framework
dylibs, IOKit, `libswiftIOKit`, ICU, and zlib), including real
`libDispatch.dylib`, `libSymbols.dylib`, and `libSwiftUI.dylib`,
`libCoreImage.dylib`, and
`libQuartzCore.dylib` boundaries; they are not application-side source
overlays. The package also contains C module headers, CQuartz, the SDK, the attested machorun
guest-root closure, OpenUIKit's complete resource tree, and the two pinned
DejaVu fonts used by the proven Linux path.

## Container entry point

Run the builder inside the pinned Linux/aarch64 image:

```sh
bash full/frameworks/build_core_guest_package.sh \
  --output-root /w/build/core-package-NEW \
  --expected-support-commit 40_LOWERCASE_HEX \
  --expected-support-tree 40_LOWERCASE_HEX \
  --uikit-checkout /uikit \
  --expected-uikit-commit 40_LOWERCASE_HEX \
  --expected-uikit-tree 40_LOWERCASE_HEX
```

`--output-root` must be a nonexistent direct child of `/w/build`. Exact support
and UIKit commit/tree values are required inputs, not provenance inferred after
the fact. Both source checkouts are bracketed for commit/tree and cleanliness;
the support commit must also descend from the accepted Foundation substrate.

The Foundation facade source list is mandatory and defaults to
`full/foundation/foundation_guest_sources.txt`. Its thirty-three LF-terminated lines
are validated for exact order, identity, regular-file topology, and content
hash before and after the build. A different path can be supplied with
`--foundation-sources-manifest`, but it must satisfy that same exact contract.

The semantic build order is deliberate:

1. Rebuild FoundationEssentials, OpenCoreGraphics, and OpenUIKit with the
   Foundation umbrella hidden.
2. Exercise the literal early UIKit/identity production gate; this is not the
   final app-facing UIKit module.
3. Build the portable Dispatch module, OpenCombine, Combine, and the
   first-party Symbols value model while Foundation is hidden.
4. Compile the ordered app-facing Foundation facade, the package-owned IOKit
   Swift overlay, and then SwiftUI against that facade so SwiftUI publicly
   re-exports its overlays and portable Dispatch identity while consuming
   Symbols.
5. Compile final UIKit after Foundation exists, then prove cross-import
   Notification, NotificationCenter, and OperationQueue identity.
6. Compile the CoreImage Swift overlay over its explicit Clang
   `CIFilterBuiltins` child module and the identity-preserving QuartzCore
   facade. Render a deterministic gradient and pass an exact UIKit-owned
   layer through QuartzCore in the package probe.
7. Compile the reusable Intents and IntentsUI modules, backed by real shortcut,
   donation, resolution, and host-driven controller state.
8. Compile production WebKit from its five-source attested manifest after both
   Foundation and UIKit exist.
9. Compile and link thirty-five app-facing first-party modules as independent ARM64
   Mach-O dylibs. Host-service boundaries fail closed, while portable metadata,
   image decoding, graphics, and composition state work locally. Every install
   ID/dependency/self-load contract is audited.
10. Build and audit the fail-closed IOKit C framework and complete
   `libswiftIOKit` runtime boundaries, then link all fifty-eight reusable
   platform binaries: the fifty-six library-directory dylibs (fifty-four Swift
   frameworks, ICU, and zlib) plus IOKit and `libswiftIOKit`. Run the package's
   Mach-O closure/resource/font and framework-behavior probe through the
   packaged machorun root.
11. Run a real asynchronous Mach-O gate covering async main, TaskGroup,
    detached jobs, global/main queues, continuations, and delayed work, then
    run the full loopback URLSession async/continuation/TaskGroup gate.
12. Compile the native Apple Foundation URL/cache and byte-count formatter
    oracles unchanged against the project-owned module, run each in a new Linux
    guest process, and require their 43- and 86-line outputs to match the
    checked-in Apple transcripts byte-for-byte.

The portable `Dispatch.swiftmodule` is built with the package compiler and
shadows the version-incompatible Apple SDK binary module for unchanged
`import Dispatch` and reexports. Its ARM64 Mach-O `libDispatch.dylib` uses a
fixed-width `/usr/lib/libOpenDispatch.dylib` runtime bridge into a uniquely
named ELF helper. Keeping the host imports in that runtime image is what makes
machorun's audited `_glibc_` boundary available without exposing host symbols
to ordinary app framework images. The helper schedules
with real Linux libdispatch `dispatch_async_f`, `dispatch_after_f`, and
`dispatch_main`; it never invokes guest callbacks synchronously. The guest
main queue is an identity token only, while global queue pointers must have
been minted by the helper. The package pins and hashes the exact Linux
`libdispatch.so` and `libBlocksRuntime.so` closure and records libdispatch's
`GLIBC_2.38` requirement instead of relying on ambient host libraries.
The same queue identity conforms directly to OpenCombine's `Scheduler`, with
monotonic time/stride arithmetic, immediate and delayed work, cancellable
repeating schedules, and real `receive(on:)` delivery. The direct Mach-O gate
executes each route rather than accepting a compile-only conformance.

CoreImage's tracked ordinary Clang module map owns an explicit
`CoreImage.CIFilterBuiltins` child module; the Swift overlay is built with
`-import-underlying-module`. This is required for unchanged dotted imports—a
pure Swift module cannot model that import spelling. The relocatable compile
contract carries both the module-map and header search arguments, and all
three underlying-module files are package artifacts. QuartzCore publishes
curated aliases to OpenUIKit's canonical Core Animation types, so importing
UIKit and QuartzCore does not create a second `CALayer` identity.

`libWebKit.dylib` has install ID `@rpath/libWebKit.dylib` and required direct
loads of the packaged `libUIKit.dylib` and `libFoundation.dylib`, each exactly
once. The builder rejects any load of Apple's `WebKit.framework`. Its runtime
probe preserves web-view configuration and data-store identity, honors
navigation policy, and observes a typed engine-unavailable provisional failure
with zero commits, finishes, history entries, JavaScript results, network
responses, or rendering claims. State-only obscured insets, under-page color,
asynchronous media-suspension completion, and KVO initial/prior/old/new
transitions for URL, loading, and background color remain observable even
without a rendering engine. Exact sources, native Xcode 26.1 evidence,
install/load audit, and pre/post source brackets are packaged under
`attestation/` alongside the seven-framework provenance and load audits.

`libImageIO.dylib` owns static and incremental image-source state over the
package's OpenCoreGraphics image identity. Incremental PNG input progresses
from invalid data through recognized-but-incomplete headers to a complete,
decodable image only after final bytes arrive; premature image requests fail
closed. The same source model publishes composited animated GIF frames and
their delays rather than flattening every source to one frame. The package
probe also consumes Darwin `remquo` and `nan` through the real CoreGraphics
math boundary, preventing constant-folded placeholders from satisfying it.

`libUniformTypeIdentifiers.dylib` owns the canonical `UTType` and
`UTTagClass` value identities. Its registry covers the system item, content,
text, source, document, image, audiovisual, archive, executable, bundle,
certificate, and 3D families used by the corpus. Tag lookup is
case-insensitive, conformance and `supertypes` traverse the complete type
graph, unknown identifiers fail closed, and custom exported/imported types
retain their declared conformance without pretending to be OS-registered.

`libOSLog.dylib` reexports the package's single `os.Logger` identity and adds
process-local signpost IDs and event/begin/end signpost APIs. Logger and
signpost diagnostics are visible on standard error; the platform explicitly
reports that Apple's unified-log persistence service is unavailable. A
standalone ARM64 Mach-O gate links only `-lOSLog`, rejects direct
Foundation/FoundationEssentials loads, and executes both surfaces through the
packaged Linux runtime. The pinned `ld64.lld-18` represents that framework
reexport with one ordinary FoundationEssentials load and one
`LC_REEXPORT_DYLIB` command for the same install name. The package audits the
two command kinds independently and still requires exactly one reexport.

`libSwiftData.dylib` is a volatile persistence engine with a real native
`SwiftDataMacros` attached-macro plugin. It implements model identity,
schema-checked contexts, insert/delete/save/rollback, Foundation Predicate
evaluation, sorting, limits, live Query reads, and SwiftUI environment/model
container integration. The default SwiftUI convenience modifier uses a
process-lifetime in-memory container and emits one diagnostic instead of
crashing an unchanged app at launch. Explicit durable configurations still
throw; disk stores, CloudKit, migrations, and undo are not claimed. A separate
ARM64 Mach-O gate expands `@Model` and `#Predicate`, executes compound fetches
and mutations, and rejects accidental linkage to Apple's SwiftData framework.

`libUserNotifications.dylib` supplies the Apple-shaped notification content,
request, settings, category, center, and async delegate surface. It fails closed
when no host authorization is provided and offers an explicitly authorized,
process-local volatile delivery queue for portable hosts; it does not claim an
operating-system notification daemon, push transport, or durable scheduling.

`libQuickLook.dylib` implements preview items, indexed controller/data-source
state, AR metadata, and a local OpenUIKit presenter that renders PNG/JPEG files
with a truthful metadata fallback. `lib_QuickLook_SwiftUI.dylib` is discovered
through packaged Swift cross-import metadata and supplies both Apple
`quickLookPreview` overloads with selection synchronization. Proprietary preview
generators and editing fail closed; hosts can replace presentation through the
attested SPI without changing application source.

`libCoreTransferable.dylib` supplies the data and file transfer-representation
model used by unchanged package sources. Its result builder composes multiple
representations, asynchronous export/import closures execute normally, and an
unconfigured direction throws a typed error instead of pretending a service is
available. `libPhotos.dylib` provides authorization, filtered/sorted/limited
asset fetches, image-data/orientation delivery, and thumbnails over an explicit
host-installed volatile library. Authorization defaults to denied and no
durable system photo library is claimed. Both frameworks have standalone Mach-O
runtime gates and pinned untouched IceCubes consumer hashes.

`libPhotosUI.dylib` owns composable image/video filters and picker
configuration. Its `_PhotosUI_SwiftUI` cross-import overlay owns picker items,
typed async and completion-handler transfer loading, and single/multiple
selection modifiers with bounded binding updates. With no host picker service,
presentation fails closed and clears the presentation binding. A host can
install a picker boundary, deliver volatile typed items, and drive selection or
dismissal without changing application source.

`libAccelerate.dylib` exposes the imported C `vImage` buffer, pixel-count,
flag, error, and ARGB8888 box-convolution surface used by unchanged Nuke. Its
portable implementation validates row-byte, region, kernel, and flag contracts,
supports edge extension, and is byte-for-byte differential-tested against an
Apple-produced convolution transcript. The Clang module map and header are
published as part of the app compile contract rather than hidden in the build.

`libCompression.dylib` supplies Apple's `Algorithm`, `InputFilter`, and
`OutputFilter` streaming shapes over an explicit Darwin-to-ELF bridge. Brotli
compression and decompression use the pinned Linux Brotli runtime through the
private Darwin-root `libOpenCompression.dylib` and attested
`libOpenCompressionHost.so`; the app-rpath framework has no direct ELF imports.
That route is deliberate: machorun grants host lookup only to implementation
images staged in its Darwin root, never to an app-local dylib. Output limits are
hard, malformed streams fail closed, and the package gate decodes an exact
payload produced by Apple's Compression framework before round-tripping native
data. The bridge, host helper, and complete SONAME closure are package artifacts
and the helper is included in every cold-run preload set.

`libCoreText.dylib` provides process-scoped font registration with Apple's
CoreText error domain and observed error codes. It validates font files,
accepts the same font bytes at distinct URLs, rejects repeat registration at a
single URL with the Apple-observed already-registered error, and publishes the
URL registration API used by unchanged RevenueCat Paywalls. A native Apple
oracle freezes the registration, duplicate-copy, invalid-file, and missing-file
transcript used by the ARM64 Mach-O package gate.

`libAdServices.dylib` publishes Apple's throwing
`AAAttribution.attributionToken()` shape, observed error domain, and the three
public error codes. Linux has no Apple Ads attribution daemon or App Store
identity, so it deterministically throws `platformNotSupported`; it never
fabricates a token. The module's interface oracle is compiled against Apple's
framework and then replayed byte-for-byte against the portable Mach-O dylib.

The packaged `zlib` Clang module preserves the 112-byte ARM64 `z_stream` ABI,
Apple's field offsets, constants, and the `inflateInit2_`/`inflate`/`inflateEnd`
surface used by unchanged RevenueCat RCContainer gzip decoding. `libz.dylib`
reexports a private Darwin-root `libOpenZlib.dylib`; only that runtime-classified
bridge owns the four `_glibc_` imports into attested `libOpenZlibHost.so`, which
in turn pins Linux `libz.so.1.3`. The app-facing facade therefore cannot acquire
machorun's host fallback accidentally. Valid gzip bytes decode through real
zlib; malformed input fails closed. Native and Mach-O oracles must both match
the frozen Apple transcript exactly.

`IOKit.framework` supplies an Apple-shaped raw C boundary: six exported
functions, four-byte Mach/IO ABI types, iteration flags, and the unsupported
return code are frozen against Xcode 26.1 build 17B55. A package-owned
`IOKit.swiftmodule` then projects that boundary into the portable Foundation
representation used by unchanged clients (`String`, `CFDictionary`, and
`CFAllocator`) without publishing duplicate C/CF identities. The 52 public
`kIOReturn` getters resolve to an open `libswiftIOKit.dylib` whose exact 53
exports match the sanitized SDK TBD; that runtime has zero undefined imports
and zero external loads. The native Apple imported-interface transcript is
retained as source evidence, while a distinct compile-time-typed portable
transcript prevents falsely claiming that the two Foundation representations
have identical reflected Swift spellings.

Linux has no Apple I/O Registry, so BSD matching and property lookups return
nil, iterators are cleared, and service acquisition and release report
`kIOReturnUnsupported`; no device identity is fabricated. The C binary has
install name `/System/Library/Frameworks/IOKit.framework/Versions/A/IOKit`, no
undefined imports, and no host or `_glibc_` route. Compile and link contracts
carry exactly one `-F frameworks` pair; the link contract carries exactly one
`-framework IOKit` pair and one `-lswiftIOKit`. Module metadata, compile and
runtime framework copies, header, module map, and Swift runtime are all
exhaustively artifact-attested.

`full/adservices/tests/test_revenuecat_frontier_guest.sh` additionally hashes
and compiles the exact untouched RevenueCat 5.86.0 attribution, RCContainer,
and `MacDevice.swift` sources from commit
`57043e7e0173c48d64e171944ac76a34d2467fa1`, links them to the published
AdServices, Compression, zlib, and IOKit binaries, and cold-runs all three
executables on Linux through the packaged loader and host-helper closure.

`libNaturalLanguage.dylib` publishes all measured `NLLanguage` constants and a
stateful `NLLanguageRecognizer`. Recognition is local and deterministic: it
combines Unicode-script classification with conservative lexical profiles,
preserves Apple's replacement/empty-input/reset semantics, honors language
constraints and hints, and assigns conservative confidence to ambiguous text
so callers can apply their own threshold. It does not claim Apple's proprietary
on-device model. Native-oracle,
literal StatusKit/WishKit consumers, and direct Mach-O runtime gates cover the
surface.

`libAuthenticationServices.dylib` and its packaged Swift cross-import overlay
provide the modern `WebAuthenticationSession` environment value and async
authentication call used by unchanged applications. A startup-only host
boundary receives browser-start/cancel events and may complete a request only
with a callback URL whose scheme matches the request. Missing hosts,
concurrent sessions, mismatched callbacks, cancellation, and stale completion
all fail with typed AuthenticationServices errors; the platform never invents
successful credentials. The overlay's direct base/SwiftUI loads and the
consumer's three framework loads are audited exactly once.

The pinned swift-foundation revision has an upstream-corrected final-class
Predicate key-path bug. The builder verifies exact source and patch hashes,
applies the backport only to a derived build copy, and leaves the pinned
checkout untouched.

The current production OpenUIKit source-set contract is 105 Swift files. The
increase from 102 is the canonical Focus launch-core tranche's independent
feedback-generator, table-diffable-data-source, and property-animator files;
the cold builder refuses either a missing file or an unexpected extra source.

The production Symbols source-set contract is one Swift file. It owns immutable
effect/configuration values, the exact marker-protocol families used for
overload selection, and composable effect options. It is emitted as the literal
`Symbols` module and `libSymbols.dylib`; the builder rejects any load of Apple's
Symbols framework.

The production SwiftUI source-set contract is eleven Swift files. The seventh
is the settings runtime used by Focus's untouched internal-settings screens:
sections, toggles, text fields, pickers, disabled propagation, and retained
change/publisher effects. It is compiled into the same real
`libSwiftUI.dylib`; it is not an application-side overlay. The eighth owns the
modern application lifecycle: `App`'s default main, `Scene`/`SceneBuilder`,
real `WindowGroup` hosting, and `UIApplicationDelegateAdaptor`. The package
probe constructs that app/scene surface from the dylib. The ninth lowers both
indefinite and value-triggered symbol-effect overloads into concrete OpenUIKit
opacity/transform render nodes while preserving effect identity. The package
probe exercises the Symbols values, protocol constraints, SwiftUI lowering,
and the exact `libSwiftUI` to `libSymbols` load edge, while OpenUIKit's host
tests cover the concrete application, scene, window, and hosting-controller
launch path.

FoundationEssentials' dylib includes both the upstream cshim `uuid.o` and the
project compatibility `uuid_compat.o`; the latter must not be dropped merely
because a small dead-stripped probe happens not to reference it. It also owns
a real Darwin `removefile` state and operation implementation: physical,
depth-first recursive deletion; no symlink traversal; keep-parent and
cross-mount policy; confirm/error/status callbacks; cancellation; and an
explicit `ENOTSUP` refusal for secure-erasure modes. A native semantic fixture
and an exact seven-symbol Mach-O export audit are mandatory build gates.
The compatibility object no longer shadows machorun's real Darwin group and
extended-attribute adapters. The build pins and runs the canonical Mach-O
group fixture against the same result as a native build (including the
32-byte `group` layout, errno-return convention, and not-found contract), and
runs the full xattr name/flag/errno/list-repacking fixture from `/tmp`. It then
requires FoundationEssentials' `_r` group and xattr imports to bind to the
staged real libSystem implementation exactly once. The same shadow audit
uncovered and removed obsolete `quotactl` and `uname` traps; their pinned
Mach-O fixtures now grade Darwin's `ENOTSUP` quota contract and the translated
1,280-byte `utsname` layout before either import is allowed into the package.
The group comparison records the one intentional native difference rather
than hiding it: Darwin reuses one static record across non-reentrant name/GID
lookups, while glibc uses distinct records; only that line is normalized before
the otherwise byte-exact native comparison, and the Mach-O fixture must match
the unmodified Darwin golden.

FileManager enumeration now uses machorun's genuine Darwin-to-glibc `fts`
translation instead of package-local abort stubs. The package pins the exact
Apple-built arm64 fixture, source, stdout, empty stderr, zero exit status, and
Mach-O metadata summary. A cold run must reproduce all 43 oracle rows covering
the 72-byte stream and 112-byte entry layouts, physical/logical/no-stat walks,
name-only children, symlink and dangling-link behavior, `SKIP`, `FOLLOW`, and
`AGAIN`, repeated child generations, parent/level/path invariants, comparator
callbacks, and stream-device projection. All five `fts` entry points must be
defined exactly once by the staged real libSystem, while FoundationEssentials'
four actual imports must bind to that image exactly once.

FoundationEssentials' filesystem enumeration also consumes machorun's genuine
Darwin `statfs` and `fstatfs` projection. The bounded Apple differential covers
the 2,168-byte ABI, exact path/file-descriptor identity across root and nested
mounts, translated mount flags, and Darwin errno behavior. The cold marker is:

```text
OPEN_FOUNDATION_STATFS_OK abi=2168 path-fd=exact mounts=root,nested flags=translated errno=darwin oracle=apple-bounded
```

Provenance key
`FoundationEssentials-statfs` pins `libSystem-source`, `fixture`, `golden`,
`stderr`, `exit`, `apple-source`, and `apple-summary`, while the package retains
`statfs-apple.txt`, `statfs-apple-summary.txt`, and `statfs-macho.log` as the
independently checkable attestations.

FileManager copying now follows the same ownership rule: the package-local
`copyfile` and `fcopyfile` traps are gone, and both imports bind exactly once to
machorun's real Darwin copy engine. The pinned Apple-built arm64 fixture proves
state allocation, private filename ownership and the documented NULL-source
route, callback/context pointer ABI, regular-file contents, owner/mode/time and
xattr metadata, exclusive/no-follow behavior, symlink identity, empty-directory
creation, descriptor copying, byte progress, and the documented best-effort
`CLONE` fallback. Its stdout, empty stderr, zero exit status, source, binary and
Mach-O summary are independently hashed, cold-run, and artifact-attested.
Unsupported recursive, forced-clone, AppleDouble and quarantined
`RUN_IN_PLACE` cases remain fail-closed in libSystem rather than being reported
as successful Linux copies.

The app-facing Foundation facade deliberately keeps linker auto-linking
disabled. Its manual closure therefore names exactly
`libswift_StringProcessing` (used by `DateFormatter` and the bounded string
search/regex compatibility surface) and
`libswiftSynchronization` (used by `UserDefaults`), `libswiftDarwin`
(used by the descriptor-backed `FileHandle` for Darwin's `open` and `errno`
overlays), and `libswift_Concurrency` (used by the asynchronous URLSession
surface), plus `libswift_errno` (the concrete owner of Darwin's lazy `errno`
getter). The builder requires all five SDK TBD inputs and staged runtime
dylibs, verifies their install names, and requires one load command for each in
`libFoundation.dylib`. It links the full direct closure before the final
FoundationInternationalization reexport, then audits that
`ObjectIdentifier.Hashable` binds to `libswiftCore` and Darwin `errno` binds to
`libswift_errno`, rather than accidentally binding either through the
reexported library's ordinal. The facade object has no direct RegexParser symbol; that
dylib remains StringProcessing's transitive runtime dependency rather than a
guessed direct link.

The thirty-three-source facade's names-only undefined-symbol inventory is also a
packaged attestation. With the pinned Swift compiler it contains exactly 19
`17_StringProcessing` records, two `15Synchronization` records, and zero
`12_RegexParser` records, plus exactly two `6Darwin` records. The build refuses
drift in any count before linking; this is why RegexParser is absent from the
direct link list even though the runtime closure still reaches it through
StringProcessing, while Darwin is deliberately present for the measured
`FileHandle` calls.

The same facade contains a real asynchronous `URLSession` route. A narrow
fixed-width C ABI crosses from the Darwin-ABI Mach-O bridge to a Linux libcurl
helper loaded by machorun. The helper enables peer and host TLS verification,
uses the pinned container CA bundle, disables host redirects so cookie and
POST-to-GET redirect semantics stay guest-owned, enforces hard request and
response byte limits, and makes cancellation/destroy ownership explicit. The
package records exact Mach-O imports, ELF exports, libcurl features, CA hash,
and direct/transitive SONAMEs under `attestation/`.

The same facade restores two Apple-only Foundation overlay surfaces omitted by
swift-foundation's non-framework configuration: the public `NSRange`
arithmetic functions and markdown `InlinePresentationIntent` attributed-string
key. The package's Foundation-only runtime probe checks range boundary,
intersection, union, raw-value, attribute-name, write, and read-back behavior;
these are framework APIs, not application source rewrites.

It also restores Foundation's genuine Objective-C name-conversion boundary
(`NSClassFromString`, `NSStringFromClass`, `NSSelectorFromString`, and
`NSStringFromSelector`) by querying the staged objc4 runtime, plus CGFloat's
distinct `NSNumber` bridge. The cold Foundation-only probe registers a real
Objective-C class, resolves it by name, round-trips a selector, and boxes and
unboxes CGFloat; it has no special-case knowledge of any application or
framework class name.

Because the guest's distinct CGFloat metadata is canonically owned by
OpenCoreGraphics, `libFoundation.dylib` declares exactly one direct
`@rpath/libOpenCoreGraphics.dylib` load. The builder verifies that edge after
linking instead of relying on UIKit's transitive graphics dependency.

SwiftUI is compiled after the app-facing Foundation facade so its public
Foundation re-export includes Foundation's overlays and its portable Dispatch
re-export, matching the surface seen by a source file that imports only
SwiftUI. `libSwiftUI.dylib` therefore names both `libFoundation.dylib` and the
underlying `libFoundationEssentials.dylib` as direct dependencies; the builder
audits each edge rather than depending on link order or an application shim.

The SwiftUI facade also keeps linker auto-linking disabled. Its object directly
uses MainActor metadata and executor functions from `libswift_Concurrency`, so
the builder names exactly that one manual SwiftUI runtime link. It requires the
SDK TBD and staged dylib, verifies the dylib install name, and requires exactly
one `/usr/lib/swift/libswift_Concurrency.dylib` load in `libSwiftUI.dylib`.
Swift 6.2 also emits the OS-or-variant-version availability thunk for the
MainActor-isolated graph-host lifetime. The staged Apple `libswiftCore` TBD
advertises that symbol while its dylib does not define it, so SwiftUI links the
same exact `swiftcorepatch.o` compatibility thunk already used by
FoundationEssentials and OpenUIKit. The package test scopes that object to the
SwiftUI dylib link and refuses its deletion.

The packaged replay separately pins the current machorun `libswiftCore.dylib`,
physically copies it into the staged root, verifies the required availability
symbol against both the SDK TBD and runtime export inventory, and attests the
source and staged hashes. The full-runtime stager refuses a stale base-root
copy instead of silently overriding this canonical runtime identity.

The Intents and IntentsUI source lists are exact, tracked package inputs. Their
paths, manifests, and content hashes are bracketed before and after every cold
build and published in `attestation/intents-sources.tsv`. Intents names its
Synchronization runtime dependency explicitly; IntentsUI links the production
UIKit and Intents dylibs. The guest probe donates and deletes a real
interaction, installs and reads back a stable voice shortcut, and constructs a
host-driven IntentsUI controller before the package is published.

## Output contract

The package is self-contained under these directories:

```text
sdk/                 copied compile sysroot
modules/             target Swift modules
lib/                 reusable ARM64 Mach-O dylibs
frameworks/          compile-time C frameworks (currently IOKit.framework)
include/             C module maps and headers
objects/             optional executable-layer objects
resources/OpenUIKit/ exact runtime JSON/resources plus fonts/
guest-root/          machorun plus its attested runtime closure
host-tools/          attested compiler plugins and native closure
probe/               independently runnable package probe
attestation/         provenance, exhaustive inventories, hashes, runtime log
```

`attestation/core-package.json` is authoritative. Its stable consumer schema
has:

- `classification: "open-uikit-core-guest-package"` and `format_version: 1`;
- `target.triple: "arm64-apple-macos15.0"`;
- exactly the `sdk`, `modules`, `libraries`, `frameworks`, `includes`,
  `objects`, `resources`, `guest_root`, and `host_tools` path keys;
- package-root-relative `swift_compile_arguments` and
  `executable_link_arguments` arrays;
- SHA-256 and byte size for every declared product, every library, and every
  file below `frameworks`, `resources/OpenUIKit`, and `host-tools`;
- exact tree/provenance manifests and logical OpenUIKit resource/font paths;
- a nullable bounded `preview` record.

The argument arrays are evaluated with the package root as the current working
directory. No absolute build path is permitted. The parallel `.rsp` files are
NUL-delimited UTF-8 for diagnostics only; consumers use the JSON arrays. Verify
any moved package with:

The published app compile contract keeps Swift's normal implicit
StringProcessing import enabled. Platform framework compilation suppresses it
internally to audit dependencies, but exporting that internal hygiene flag
would break unchanged sources such as StatusKit's ordinary `Regex(...)` use.

```sh
python3 -B full/xcodeplan/core_guest_package.py PACKAGE --emit-summary
python3 -B full/frameworks/core_package_manifest.py verify \
  --package-root PACKAGE
```

The source SDK currently contains exactly nine dangling Swift overlay aliases
whose Apple framework binaries are absent from the sanitized SDK: CloudKit,
CreateML, IdentityLookup, Network, PencilKit, ShazamKit, SoundAnalysis,
SoundAnalysis_Private, and Virtualization. The project-built `Network` module and
dylib are supplied independently of that stale Apple overlay alias. The aliases'
paths and raw `readlink`
payloads (including the two byte-significant SoundAnalysis `../../..//System`
targets) are pinned in
`full/frameworks/sdk_dangling_symlink_exclusions.tsv`. The builder first
attests that exact dangling set in the immutable source SDK, copies the SDK,
and removes only those nine verified links from the fresh staged package.
Source pre/post dangling attestations must match, while the normalized source
inventory and packaged `attestation/sdk-tree.tsv` must be byte-identical. Any
missing, additional, retargeted, non-symlink, absolute, or escaping entry
refuses; the general inventory rules remain strict.

The public package validator rehashes every manifest and independently rebuilds
the packaged SDK's `core-tree-v1` ledger. It rejects dangling, absolute,
escaping, or unsupported SDK nodes and refuses any byte drift from
`manifests.sdk_tree`, so relocation or later cache corruption cannot bypass the
creation-time checks.

OpenUIKit's source `Resources` tree is copied byte-for-byte to
`resources/OpenUIKit`, with symlinks forbidden and empty directories attested.
The pinned container fonts are then added at
`resources/OpenUIKit/fonts/DejaVuSans.ttf` and
`DejaVuSans-Bold.ttf`. The app materializer copies this directory to
`<App>.app/Contents/Resources/OpenUIKit`; generated host code sets
`OpenUIKitRuntime.resourceRoot` and `fontPaths` to those bundle locations.

## Packaged compiler plugins

`compiler_plugins` in `attestation/core-package.json` is the structured
transport contract for production library plugins. Each entry records the
external macro module, package-relative native ELF path and hash, sorted macro
registrations, allowed consumer scopes (`app`, `framework`, and `package`),
whether serialized compiler jobs are required, and the complete attested host
Swift/SwiftSyntax closure. The matching `-load-plugin-library` pair must occur
exactly once in the relocatable compile response. Both manifest validators
rebuild and check this relationship, and mutation tests reject omitted closure
members, narrowed/expanded scopes, bad hashes, and missing load pairs.

The initial set is `ObservationMacros`, `FoundationMacros`, and
`SwiftDataMacros`. The same rooted compile contract reaches Swift-package
targets, framework targets, and the application compile; it is not a
SwiftData-specific driver side channel.

## Optional Preview seam

Preview support is strictly all-or-none:

```sh
  --developer-tools-support-module DeveloperToolsSupport.swiftmodule \
  --developer-tools-support-object developertoolsupport.o \
  --preview-macro-plugin OpenUIKitPreviewMacros-tool
```

The builder validates the exact basenames, regular-file topology, plugin
executable bit, native ELF64/AArch64 identity, Swift 6.2.4 toolchain, and all
three hashes. It also records and enforces SwiftSyntax revision
`4799286537280063c85a32f09884cfbca301b1a1`. The host plugin is never
target-linked or copied into the
package. Its package response file contains the literal relocatable token
`${PREVIEW_PLUGIN}#OpenUIKitPreviewMacros` followed by exactly `-j1`; the
actual external plugin path is used only while building or when explicitly
passed to manifest verification. Every compiler invocation that loads this
SwiftSyntax executable plugin is serialized the same way. This preserves the
ordinary driver mode while preventing Swift 6.2.4 from concurrently tearing
down framed plugin channels; inherited or additional driver-job flags remain
outside the contract.

The pinned SwiftSyntax revision predates upstream commit
`f537808000a69e5acfa0b42c5de1ae5793e2c0c5`, which recognizes a zero-length
framed message as plugin termination. Without that check, teardown can pass an
empty payload to the JSON decoder and emit the observed `Internal Error:`,
`Corrupted JSON`, and `unexpected end of file` diagnostics despite a successful
compiler exit. The one-job contract is the tested workaround while this exact
SwiftSyntax revision stays pinned.

The target DTS module is added to UIKit/app compile visibility. Its object is
kept separate under `objects/` and named only by
`preview.developer_tools_support_object`. It is intentionally absent from
generic `executable_link_arguments`: the app driver appends it exactly once.
The core runtime probe likewise links it exactly once, leaves its UIKit imports
dynamic, evaluates a retained Preview body, and proves UIKit carries no DTS
dylib dependency. In Preview mode, the builder also requires UIKit's one
measured DTS import and the object's matching definition, then exports only
that exact Preview initializer from the probe executable so flat lookup can
resolve it. The post-link audit requires exactly one such export; non-Preview
packages require zero DTS imports and exports. Broad executable export and a
DTS dylib are deliberately outside this seam. The JSON also publishes the
exact compiler evidence flags:

```json
["-Xfrontend", "-dump-macro-expansions"]
```

The app driver captures that compiler stream as
`attestation/app-macro-expansions.stderr`. Successful object emission alone is
not a macro-expansion proof.

## Fresh host replay

`run_core_guest_package_docker.sh` is the production host-side cold wrapper.
It requires an exact lowercase SHA-256 Linux/ARM64 container image ID, exact
support, UIKit, and machorun commit/tree pins, an exact SHA-256 for machorun's
ignored prebuilt loader, a new output path, and a staged-input root containing:

```text
sysroot_fe4/  mrroot/  mrroot_fe/  swift-foundation/
swift-collections/  opencombine-core-durable-20260828-r2/
```

Example shape (the output must not exist):

```sh
bash full/frameworks/run_core_guest_package_docker.sh \
  --container-image sha256:138303d276d49b9b3b6aa9ee277dfb30b876e24557f80c07fd5d52044ef2d9d7 \
  --support-checkout /path/to/clean/support \
  --expected-support-commit 40_HEX \
  --expected-support-tree 40_HEX \
  --staged-input-root /path/to/canonical/support/scratch \
  --uikit-checkout /path/to/clean/uikit \
  --expected-uikit-commit 40_HEX \
  --expected-uikit-tree 40_HEX \
  --machorun-checkout /path/to/clean/machorun \
  --expected-machorun-commit 40_HEX \
  --expected-machorun-tree 40_HEX \
  --expected-machorun-loader-sha256 64_HEX \
  --output-root /path/to/new/core-package
```

Mutable image tags and defaults are refused; the exact image ID and verified
Linux/ARM64 platform are recorded in host evidence. The wrapper creates fresh
`--no-local --no-hardlinks` clones for support, UIKit, and machorun. It then
byte-copies the ignored machorun loader and `darwin/usr` runtime closure, every
prepared staged-input tree, and the optional Preview trio. The copier opens a
new destination file for every regular file, proves that it shares no source
inode, preserves directories, modes, and symlink targets, and rejects sockets,
FIFOs, and device nodes. Ignored build outputs from the three source checkouts
are therefore never inherited; only machorun's explicitly required ignored
runtime inputs enter the replay.

Docker receives exactly one host bind, the fresh replay root at `/replay:rw`.
The bind must be writable because `/replay/w/build` carries the validated
package back to the host. This is not claimed to make copied inputs
kernel-read-only. Instead, before Docker starts the wrapper records a canonical
JSON-lines manifest of every input entry—relative path, file type, permission
mode, regular-file size and SHA-256, or symlink target. It records the same
manifest after the container and host validators finish and refuses publication
unless the files are byte-identical. Only the four explicitly enumerated fresh
write targets below and their descendants are excluded. Git optional locks and
Python bytecode writes are disabled so source metadata cannot drift silently.

The container itself runs with `--network none` and `--read-only`. `/tmp` is its
only tmpfs mount; `HOME`, `TMPDIR`, and `XDG_CACHE_HOME` point into it. Build,
both module caches, and the working machorun root are new empty directories in
the one physical replay bind. In particular, there are no tmpfs or bind mounts
nested below `/replay`: Docker Desktop was measured dropping such nested
mounts during a long build, after the guest-root umbrellas had been linked.
That produced transient missing libraries and erased the failed root before it
could be diagnosed. A fresh physical directory is equally cold, remains
host-visible throughout the run, and is removed with the replay on success.
No dependency fetch or prior compiler cache can affect a replay.

The complete persistent write-target census for the composed core call graph
is deliberately small:

| Target | Writers | Fresh storage |
| --- | --- | --- |
| `/replay/w/build` | Core staging plus all `build_full.sh` products; every Foundation helper receives its `OUT` below this root | Empty directory in the one host bind; excluded as `w/build` |
| `/replay/w/scratch/mrroot_full` | `build_full.sh` guest-root and umbrella staging | Empty directory in the one host bind; excluded as `w/scratch/mrroot_full` |
| `/replay/w/scratch/modcache_full` | Ordinary `build_full.sh` Swift compiles | Empty directory in the one host bind; excluded as `w/scratch/modcache_full` |
| `/replay/w/scratch/modcache_fe4` | `build_collections.sh`, `build_os_module.sh`, and `build_fe.sh` FoundationEssentials compiles | Empty directory in the one host bind; excluded as `w/scratch/modcache_fe4` |

`build_cshims.sh` writes only to its caller-supplied build output. The SDK,
base guest roots, Foundation and Collections checkouts, OpenCombine, UIKit,
machorun, and support clone are all covered by the pre/post content manifest.
Any unexpected write anywhere outside the four fresh paths quarantines the run.
No other persistent path in `build_core_guest_package.sh` → `build_full.sh` →
the four Foundation helper scripts is a permitted write target.

The evidence directory records the exact image ID/platform, commit and tree for
support, UIKit, machorun, Foundation, Collections, and OpenCombine, the pinned
machorun-loader hash, a hash for every physical-copy report, both full input
manifests, Docker output, and host-validator output. A post-container durability
gate also hashes the host-visible staged loader, manifest, renamed real
libraries, libSystem/libc++ umbrellas, and linked libquartz before host
validation. Both package validators run before the manifest comparison.
Publication is a same-filesystem atomic
rename into the still-nonexistent output path. On success the large physical
replay tree is deleted and only the package plus compact evidence remain. On
any failure, the complete run and any partially published package are renamed
with `.INVALID-DO-NOT-USE`; a later invocation never reuses either one.

Neither script edits UIKit, application, vendored, machorun, or upstream
Foundation/OpenCombine sources. A package is not complete unless its runtime
probe, closure attestation, JSON verifier, canonical consumer validator, and
`PACKAGE_COMPLETE` marker all agree.

## Static tests

```sh
python3 -B full/frameworks/test_core_guest_package.py
python3 -B full/dispatch/tests/test_dispatch_boundary.py
python3 -B full/frameworks/test_physical_replay.py
bash -n full/frameworks/build_core_guest_package.sh
bash -n full/frameworks/run_core_guest_package_docker.sh
bash -n full/scripts/build_full.sh
bash full/frameworks/test_single_bind_guest_root_docker.sh \
  --container-image sha256:64_LOWERCASE_HEX
```

The tests exercise exact Foundation and WebKit ordering, all added
first-party framework products, WebKit deletion/mutation/load refusal,
path/symlink refusal, relocation to a path containing spaces, Preview
placeholder/external-plugin behavior, DTS ownership, resource/library tamper
detection, and the early/final UIKit ordering hooks.

The final focused Docker smoke is intentionally separate from the static suite.
It uses the same one-bind/read-only-root/no-network layout, links minimal ARM64
Mach-O libSystem, libc++, and libquartz products around 48 independent compiler
invocations, then verifies those files again on the host after the container
has exited. It refuses mutable image tags and cleans its physical replay on
success while quarantining the complete fixture on failure.
