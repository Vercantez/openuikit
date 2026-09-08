# Route (a): compiler flags and shim measurements

Measured 2026-09-07 (America/Chicago) in the operator's `uikit-linux`
container: stock Swift 6.2.4, `aarch64-unknown-linux-gnu`, Ubuntu 24.04.4,
clang 18.1.3. The full commands, exit statuses, diagnostics, linker output,
and crash backtraces are in [route-a-objc-options.json](route-a-objc-options.json).
No operator `/src` or `/work` tree was changed. No packages were installed.
The experiments use `/work-route-a/objc-probes`; objc4 is rebuilt in a copy
under that directory, using its nine carried patches and the toolchain's
existing `Block.h` / `libBlocksRuntime.so`.

## Reproduction

From `uikit/`, copy the script into the already isolated container tree and run:

```sh
docker cp Tools/ingest/route_a_objc_probe.py uikit-linux:/work-route-a/uikit/Tools/ingest/route_a_objc_probe.py
docker exec uikit-linux python3 /work-route-a/uikit/Tools/ingest/route_a_objc_probe.py --out /work-route-a/objc-probes --objc-root /work-route-a/objc4-linux --build-runtime
swift Tools/ingest/route_a_selector_names.swift
```

The Python runner records failures as data; its own exit zero means the matrix
completed, not that the compiler/runtime options succeeded. The OpenUIKit
matrix runs when the copied package has its Linux release module built.
The JSON retains all compiler/linker diagnostics. For the large `nm` symbol
inventories only ObjC-related symbols are retained, with the full stdout SHA256
and original line count; this filtering does not apply to diagnostics.

## What the flags change

The isolated sample imports Foundation and declares an `NSObject` subclass
with `@objc func tapped()` and `#selector(tapped)`.

| Configuration | Typecheck result |
|---|---|
| Stock compiler flags | exit 1: `Objective-C interoperability is disabled`; `'#selector' can only be used with the Objective-C runtime` |
| `-enable-experimental-feature ObjCInterop` | exit 1: identical diagnostics |
| `-Xfrontend -enable-objc-interop` | exit 1: `import the 'ObjectiveC' module to use '#selector'` |
| Both flags | exit 1: same missing ObjectiveC module diagnostic |

The same four outcomes occur for an OpenUIKit `UIViewController` subclass
whose `UIButton.addTarget` argument is `#selector(tapped)`. Merely defining
local Swift types called `NSObject` and `Selector` does not satisfy the
compiler; under the frontend flag the diagnostic additionally requires
importing `Foundation` for `@objc`.

## What a shim does, and does not, provide

Compiling Swift modules named `Foundation` (an open `NSObject` class) and
`ObjectiveC` (a `Selector` struct), then importing both with the frontend flag,
allows this isolated selector sample to typecheck and emit an object. Keeping
stock Foundation and supplying only the ObjectiveC shim also typechecks and
emits an object. This is a measured syntax/compiler-name seam, not runtime
compatibility.

There are three distinct remaining failures:

1. Against the already built native OpenUIKit, a shim selector is a different
   type: `cannot convert value of type 'ObjectiveC.Selector' to expected
   argument type 'OpenUIKit.Selector'`.
2. A portable string-layout Selector is not the compiler's SEL representation.
   With `struct Selector { let name: String }`, emitted SIL is:

   ```sil
   %2 = string_literal objc_selector "tapped"
   %3 = struct $String (%2)
   %4 = struct $Selector (%3)
   ```

   The corresponding emitted IR stores one pointer into an allocation, then
   loads and returns `{ i64, ptr }` from it. It does not call the shim's String
   initializer. The second word is not initialized by that function. Thus
   successful object emission does not make the portable name-carrying layout
   a valid SEL ABI. Exact SIL and IR are retained in the JSON.
3. Stock Foundation + that shim + freshly built objc4 fail at link time:

   ```text
   undefined reference to 'OBJC_METACLASS_$__TtCs12_SwiftObject'
   undefined reference to '$s10Foundation8NSObjectCMm'
   ```

Even an interop-enabled plain Swift class with no selectors emits undefined
`OBJC_CLASS_$__TtCs12_SwiftObject` and
`OBJC_METACLASS_$__TtCs12_SwiftObject`. The shipped libswiftCore exports zero
ObjC class/metaclass symbols. Its object does contain `objc_classlist` and
`objc_imageinfo`; the object format is not the only wall.

## Actual objc4 headers and runtime

The rebuilt objc4 port passes the isolated C/ObjC control experiment:
`clang-18 -fobjc-runtime=macosx-10.15` builds a real `NSObject` subclass,
allocates it, and dispatches a registered selector through `objc_msgSend`.
The executable exits zero and prints `OBJC4_TARGET_ACTION_FIRED`. This run
checks that the runtime used for the Swift link experiments actually executes
Objective-C target/action. It does not re-run or claim the historical 44-test
runtime differential.

Importing objc4's actual `NSObject.h` through a separately named Clang module
`ObjCRoot` makes the boundary sharper: a Swift class inheriting
`ObjCRoot.NSObject` typechecks **and links** when unused. Unlike declaring a
Clang module named Foundation, this spelling unambiguously selects the
runtime's ObjC class instead of stock Swift Foundation's module.

For execution, a second ObjectiveC shim uses the pointer representation
actually present in the vendored `ObjectiveC.swift`:
`@frozen struct Selector { var ptr: OpaquePointer }`. A Swift sample contains
`#selector(Probe.tapped)`, allocates `Probe`, and passes the SEL to a small C
`objc_msgSend` wrapper. It compiles and links against the real objc4 runtime.
It crashes with signal 11 (Python return code `-11`) during `@objc Probe.init()`
before the `SWIFT_OBJC4_TARGET_ACTION_FIRED` marker. An allocation-only Swift
subclass sample crashes identically, with no selector dispatch involved.
The crash backtrace's first frame is symbolicated as
`pruneCallback(dl_phdr_info*, unsigned long, void*) + 1640 in libobjc.so`,
followed by `@objc Probe.init()` and `Probe.__allocating_init()`.
This measurement identifies the failing stage; it does not diagnose the root
cause from a nearest-symbol backtrace or assert that every possible runtime
configuration fails. No runtime symbols were fabricated to bypass linking.

Therefore the tested flag/shim combinations provide **zero working Focus
files against native OpenUIKit**. A complete runtime bridge is unproven;
source lowering to OpenUIKit's existing dispatch registry is the measured
option used by this branch.

## Darwin selector naming oracle

Apple Swift 6.2.1, `arm64-apple-macosx26.0`; actual `NSStringFromSelector`
results on an `NSObject` subclass. These cover every named first-label family
in the Focus audit, plus the measured `with` exception:

| Swift declaration shape | Actual ObjC selector |
|---|---|
| `plain()` | `plain` |
| `changed(_:)` | `changed:` |
| `toggle(sender:)` | `toggleWithSender:` |
| `didPressSearch(sender:)` | `didPressSearchWithSender:` |
| `keyboardWillShow(notification: Notification)` | `keyboardWillShowWithNotification:` |
| `mixed(sender:event:)` | `mixedWithSender:event:` |
| `@objc(chosenName:) explicit(_:)` | `chosenName:` |
| `tappedLearnMoreFooter(gestureRecognizer:)` | `tappedLearnMoreFooterWithGestureRecognizer:` |
| `didToggle(enabled: Bool)` | `didToggleWithEnabled:` |
| `paste(clipboardString: String)` | `pasteWithClipboardString:` |
| `pasteAndGo(clipboardString: String)` | `pasteAndGoWithClipboardString:` |
| `f(with:)` | `fWith:` |

The last case disproves a universal `name + With + CapitalizedFirstLabel`
rewrite. The lowering tool must fail closed for unmeasured naming forms or
carry additional oracle cases before accepting them.
