# Guest Objective-C Foundation, sqlite3, and ObjC/C targets: status 2026-09-23

Branch `agent/guest-objc-foundation`. Each increment passed
`local_guest_verify.sh`: all probes OK, `REAL-APP SCREEN VERIFIED ON LINUX` and
`GUEST HOST INTERACTION VERIFIED ON LINUX`. Each also passed `full/iostarget/ios_guest.sh`
(`IOS_TARGET_GUEST_VERIFIED`). `render_full` is byte-identical to main (sha256
`63e5749f…`, both built at the same path). The first increment also passed
`CHECK_ONLY` `agent_merge.sh`.

## The wall

The Mach-O guest had objc4 but no Objective-C Foundation. Its only Foundation
is a Swift facade, `full/foundation` + `full/appshim` compiled as module
`Foundation`. There was no `sqlite3` (neither header nor library), and the app
pipeline compiled Swift only. That blocked every Objective-C-heavy app. For
NetNewsWire the blockers were FMDB (RSDatabaseObjC), which opens SQLite at
launch, plus `project_inventory.py`, which refused the xcconfig files.

## Survey, and the design (one Foundation)

- `foundation-macho/` does have Objective-C NS* classes: the NSSlice class
  clusters and the toll-free `__NSCF*` classes over a corelibs CoreFoundation
  built in ObjC mode. That work is proven against macOS in its own harness.
  The guest app build does not use any of it. `build_full.sh` stages
  loud-abort `Foundation`/`CoreFoundation` framework stubs and links the Swift
  facade (`foundation_guest.o`) into every executable.
- The facade's NSString, NSArray, NSDictionary, NSNumber, NSData, NSError,
  NSNull, NSValue and NSLock are Swift classes (NSObject subclasses with
  runtime names like `_TtC10Foundation8NSString`). Their Swift storage is a
  `String`, a `Mutex<[Any]>`, an enum. The facade's
  `String/Array/Dictionary/Data: _ObjectiveCBridgeable` conformances point at
  those classes.
- Adding a second, Objective-C NSString would mean two classes named NSString
  and two bridging paths. libswiftCore's `swift_stdlib_connectNSBaseClasses`
  looks NSString/NSArray/… up by name and reparents onto them, which requires
  ivar-less cluster heads (foundation-macho DECISION §1.2). The facade classes
  are not cluster heads.

**Decision: the Swift facade stays the only Foundation, and Objective-C gets a
view of it.** The facade's objects cannot be changed without changing
`render_full`, so everything new is additive and linked only where Objective-C
is present.

1. **Headers** (`full/objcfoundation/include/Foundation`) declare each facade
   class as `OF_SWIFT_CLASS("<runtime name>", "<module>")`:
   - `objc_runtime_name` makes Objective-C code reference the facade's class
     object itself.
   - `external_source_symbol(language="Swift", defined_in=…)` makes Swift's
     ClangImporter resolve the declaration back to the Swift class when an
     Objective-C module is imported.
   - `swift_bridge` (Swift.String, Swift.Array, Swift.Dictionary, Swift.Set,
     FoundationEssentials.Data/Date) keeps the facade's conformances as the
     bridging path.

   Members are compiled for Objective-C only (`#if !defined(__swift__)`), so
   Swift sees the Swift API and nothing is declared twice. The signatures
   follow the iOS 26.1 SDK for the surface implemented. One recorded
   deviation: `NSNumber : NSObject`, not NSValue, because that is the runtime
   class.
2. **FoundationObjCBridge** (`bridge/*.swift`) gives the facade classes the
   SDK's selectors as `@objc` extension members (categories). It also adds the
   classes the facade lacks, as Swift classes: NSMutableString (a facade
   NSString edited in place, so String bridging stays correct), NSSet,
   NSMutableSet, NSEnumerator, NSDate, NSLocale, NSTimeZone, NSDateFormatter
   and NSAssertionHandler. It adds `Set`, `Date` and `AnyHashable` bridging,
   and NSString's AnyHashable representation.
3. **`src/OFFoundation.m`** holds what Swift cannot declare: the `%@`
   formatter and every variadic method, the NSRange selectors, class
   factories, NSLog, the `NSString *const` constants, `-[NSObject description]`
   (objc4 leaves it to CF), and the constant-string rewrite below.
4. **Constant strings.** clang emits each `@"…"` as a 32-byte `__cfstring`
   record whose isa is `___CFConstantStringClassReference`. The facade
   NSString instance is also 32 bytes, with its String at +8 and its UTF-8 at
   +24. The offsets are read from the ivar list and checked at run time.
   Before `main`, every record in every loaded image is rewritten in place
   into a `__NSCFConstantString` (a facade subclass with no ivars), which
   makes it immortal. Immortality was measured to be load-bearing: clang's ARC
   optimizer drops the retain of a value it sees is a constant but keeps the
   release of a reload (`id keys[] = {@"ky"}`), so a counted constant gets
   freed from `__DATA`.

Two measured compiler facts shape how Swift consumes the headers. Both are in
`OBJC_SWIFT_FLAGS`:
- a Swift module that imports an Objective-C module needs
  `-import-module FoundationObjCBridge`. Without it, swift-frontend 6.2.4
  crashes in IRGen lowering any method that returns a bridge class (NSDate);
- an untyped `NSDictionary *` imports as `[AnyHashable: Any]`, and without
  AnyHashable's Objective-C counterpart IRGen crashes the same way (FMDB's
  `-rs_insertRowWithDictionary:…`).

## Proof: same sources, iOS 26.1 simulator vs guest

`uikit/Tools/oracle2/guestobjcfoundation/run.sh` builds `scenario/*.m`,
NetNewsWire's unmodified RSDatabaseObjC and `main.swift` for the simulator
and records `transcript-ios26.1.txt`. RSDatabaseObjC comes from the pinned
corpus at `3b378e72` and is checked against
`full/objcfoundation/rsdatabaseobjc.sha256`. The guest probe
`GuestObjCFoundationProbe` compiles the same files and must print the
identical 100 lines:

```
GUEST_OBJC_FOUNDATION_OK 79 lines identical to the iOS 26.1 run (ObjC strings, numbers, collections, errors, data, dates; Swift<->ObjC bridging)
GUEST_FMDB_OK 21 lines identical: NetNewsWire's unmodified RSDatabaseObjC on an in-memory SQLite database, from Objective-C and from Swift
```

What those lines cover:
- **Formatting and descriptions:** %d/%ld/%lld/%x/%f/%e/%g/%s/%c/%C/%@ with
  flags and widths; the collection description layouts; NSNumber printing;
  NSData, NSDate and NSError descriptions.
- **Strings:** mutation, categories, and the numeric parsers.
- **Collections:** fast enumeration and blocks.
- **Swift ↔ ObjC:** `NSError**` imported as `throws`; String, `[String: Any]`,
  `[NSNumber]`, Data, `Set<String>` and Date crossing in both directions;
  Swift closures passed as ObjC blocks.
- **FMDB:** `executeStatements`, transactions, bindings of every value kind,
  `resultDictionary`, the RS categories, and error reporting, called from
  Objective-C and from Swift in NetNewsWire's call shapes.

## sqlite3

**Choice: SQLite 3.51.0's public-domain amalgamation, built as
`/usr/lib/libsqlite3.dylib`.** It is pinned by URL and SHA-256
(`full/sqlite/build_sqlite_guest.sh`), and 3.51.0 is the version the iOS 26.1
SDK's `sqlite3.h` declares. The alternative was the precedent of
`full/coredata`'s `dlopen("libsqlite3.so.0")`, which was rejected:
- That pattern belongs to the Linux-native (ELF) CoreData module.
- FMDB links `sqlite3_*` at build time, which a Mach-O dylib satisfies with
  two-level binding. A host ELF would need a bridge per function and would run
  whatever SQLite the container ships.
- The guest's other C dependencies already work this way: libxml2 and
  libquartz are built from pinned source as Mach-O.

Compile options come from a measurement. `uikit/Tools/oracle2/guestsqliteoptions`
records the simulator's `sqlite3_compileoption_get` rows and the pragma
defaults. `full/sqlite/apple_compile_options.tsv` classifies every row as
reproduced, derived, or omitted with a reason. The omitted rows are Apple's
closed CCCRYPT codec, `MUTEX_UNFAIR`, `LOCKING_STYLE`, `SQLLOG`,
`SETLK_TIMEOUT` and `UPDATE_DELETE_LIMIT`, which the amalgamation cannot do.
`GuestSQLiteProbe` runs the same C program under machorun and prints
`GUEST_SQLITE_OK`: version and threading mode, 23 pragma defaults, and 38
prepare/bind/step/FTS4/JSON/math/WAL/error lines are all identical to iOS.
The module map is Apple's (`module SQLite3`).

Getting SQLite to run needed machorun work, each piece with a rung recorded on
macOS:
- POSIX record locks: `F_GETLK/F_SETLK/F_SETLKW` are rotated between the two
  systems, `l_type` is rotated, and `struct flock` is 24 bytes on one side
  against 32 on the other;
- `F_FULLFSYNC`, `fchown`, `strspn` and `dispatch_once`
  (rungs `fcntl_locks`, `file_attrs`, `dispatch_once_block`).

`fchmod`/`utimes` are deliberately not exported. `fm_unimplemented.c` defines
private copies of both, and exporting them from libSystem reordered
`render_full`'s LINKEDIT (measured: same code, different symbol order). SQLite
gets them from `full/sqlite/compat` instead.

## Pipeline

- **`project_inventory.py`** now handles:
  - `#include?`: evaluated when present, recorded as skipped when absent, and
    refused when it names an existing file outside the checkout;
  - a trailing `;` in a value;
  - destination-conditional assignments, which are recorded but not applied;
  - a literal `PRODUCT_MODULE_NAME`: Xcode renames only the module;
  - package products in copy-files phases.

  Each behaviour was measured with `xcodebuild -showBuildSettings` on Xcode
  26.1 and has a test. NetNewsWire-iOS Debug now inventories end to end, and
  its effective `OTHER_SWIFT_FLAGS` equal xcodebuild's.
- **`build_full.sh`** builds the ObjC Foundation into `$OUT/objcfoundation`,
  never into APPINC or `APPMODS_CINC`, and offers:
  - `compile_app_objc` and `compile_app_c`: ARC, modules, the guest
    Foundation, SQLite3;
  - `OBJC_SWIFT_FLAGS`, for Swift modules that import Objective-C modules;
  - `OBJC_FOUNDATION_LINK_OBJECTS`;
  - `check_runtime_names.py`, which refuses a header whose runtime name no
    object defines. It has tests.

  It also attests an in-repo `machorun/` by its committed tree, as it already
  did for `uikit/`. The machorun pin is the operator's to advance after merge.

## Walls and limits (named, not papered over)

- **`@try/@catch` / NSException raising.** machorun has no compact-unwind
  support. NetNewsWireObjC's SFSafariViewController category uses `@try`.
  guest-swift-modules owns an NSException class, but it will not make
  `@try` work.
- **Methods taking `NSRange`**, when app Objective-C methods are imported into
  Swift: the facade's NSRange is a Swift struct that a Clang declaration
  cannot name.
- **Not implemented:**
  - `-[NSMutableData mutableBytes]` and a settable `length`;
  - string encodings other than UTF-8 and ASCII (these return nil);
  - NSDateFormatter beyond fixed Gregorian patterns with GMT-offset zones;
  - positional format arguments (`%1$@`), which abort with a message;
  - `NSClassFromString(@"NSString")`: runtime names are the Swift mangled
    ones, which keeps libswiftCore's by-name lookups away from classes that
    carry ivars.
- **Descriptions:** strings inside collection descriptions are quoted by an
  identifier-like rule, which is measured for simple words only. NSData longer
  than 24 bytes follows Apple's documented layout, not a measurement.
- **Constant strings in images loaded by `dlopen` after startup** are not
  rewritten.
- **A difference in the facade's Swift `NSError.description`.** It spells the
  user info `{Key = value;}` while iOS prints `{Key=value}`. The Objective-C
  `-description` follows the measurement. The Swift one is the facade's to
  fix, and fixing it changes `render_full`.
- **Not yet reached:**
  - NetNewsWire's Swift RSDatabase modules are not compiled for the guest;
  - Minizip/zlib;
  - a SafariServices Clang module in the guest.

## Using it (for the NNW guest and later Simplenote/eidolon)

In a `*.probe.sh` or `build_full.sh` section:

```bash
compile_app_objc "$OUT/x/FMDatabase.o" "$RSDB/FMDatabase.m" -I "$RSDB/include" -I "$RSDB"
"${SWIFTC[@]}" … "${OBJC_SWIFT_FLAGS[@]}" -Xcc -fmodule-map-file=<objc module map> …
link_app_executable "$OUT/App" … "${OBJC_FOUNDATION_LINK_OBJECTS[@]}" "$ROOTDIR/darwin/usr/lib/libsqlite3.dylib"
```

`uikit/Tools/guestprobes/GuestObjCFoundationProbe.probe.sh` is the worked
example.
