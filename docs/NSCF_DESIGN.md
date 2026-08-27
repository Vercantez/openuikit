# The `__NSCF*` classes: what they are, and how they differ from the slice

The proven slice (`src/slice/NSSlice.m`, byte-identical to macOS — see DECISION.md)
established the class-cluster shape: an abstract `NSString`/`NSArray`/… plus a
concrete `__NSSlice*` subclass holding the storage. #51's 19 bridged classes
reuse that shape and **invert one thing about it**, which is load-bearing enough
to state before writing any of them.

## The constraint: `__NSCF*` classes are IVAR-LESS, and `self` is a CF object

`__NSSliceString` owns its storage:

```objc
@interface __NSSliceString : NSString {
  unichar   *_chars;
  NSUInteger _len;
}
```

`__NSCFString` must own none. The reason is in how its instances come to exist:
they are not `+alloc`'d. `_CFRuntimeCreateInstance` allocates a CF struct and
stamps the registered class into its first word (`CFRuntime.c:550`,
`memory->_cfisa = __CFISAForTypeID(typeID)`). **The class is an isa and nothing
else.** So in any `__NSCFString` method, `self` *is* a `CFStringRef`, and every
method forwards to the corresponding `CFString*` function.

Three consequences follow, and each is a way to get this wrong:

1. **An ivar would alias CF's own fields.** ObjC lays ivars out after the
   superclass's instance size, i.e. immediately after `isa` for a direct
   `NSObject` subclass. CF has already put `_cfinfoa` and the type's own payload
   there. An ivar is not "extra space CF doesn't know about" — it is a second
   name for bytes CF is already using. Nothing diagnoses this; it reads and
   writes plausible-looking garbage.

2. **`swift_stdlib_connectNSBaseClasses` requires it.** libswiftCore re-parents
   `__SwiftNativeNSStringBase` and its five siblings onto our classes with
   `class_setSuperclass`. Changing a superclass under a class that has ivars
   changes where those ivars live; the runtime contract only holds for
   ivar-less class clusters. This is why the six classes libswiftCore looks up
   by name are all abstract cluster heads.

3. **The abstract class holds the primitives, the concrete class holds nothing.**
   Everything a subclass must override is a primitive (`length`,
   `characterAtIndex:`, `count`, `objectAtIndex:`, `member:`); everything else is
   derived and lives on the abstract class. That is also where the two consumers
   meet: the 22 selectors shared between CF's 151 and libswiftCore's 124 are
   almost exactly the cluster primitives, so a correct primitive set serves both.
   It does NOT mean they want the same surface — the union is 253.

## `__NSCFConstantString` is not optional, and CF's placeholder must be deleted

Measured (CF_TRIAGE §36): with `-fconstant-cfstrings` the compiler stamps every
`CFSTR` literal's isa with `___CFConstantStringClassReference`, and
`CFRuntime.c` **defines that symbol as a zeroed `int[24]`**. So `CF_IS_OBJC` is
already true for every constant string and CF would message a zeroed array.
On macOS the same address is a real class:

```
CFSTR isa == &__CFConstantStringClassReference -> __NSCFConstantString
provided by CoreFoundation      [s length] == 5
```

Two things are therefore required, and the second is the easy half to forget:

* our Foundation must define `___CFConstantStringClassReference` as a real
  ObjC class implementing the NSString primitives over `struct __CFConstStr`;
* **CF's zeroed definition must be DELETED, not shadowed.** Two definitions in
  two dylibs would bind CF's own constant strings to the placeholder and
  Foundation's to the class — constant strings split in half, silently, with
  every symbol resolving.

`__NSCFConstantString` is also the one bridged class whose instances are
immutable, never deallocated, and laid out by the compiler rather than by
`_CFRuntimeCreateInstance` — so it is the only one whose storage shape we do not
choose. That makes it the one worth MEASURING rather than reading off a header.

### The layout, measured on macOS

Dumping the raw words of `CFSTR("hello world")` on macOS 26 arm64:

```
class = __NSCFConstantString, CFStringGetLength = 11
  word[0] @+ 0 = 0x00000001fb3026f8   isa (== &__CFConstantStringClassReference)
  word[1] @+ 8 = 0x00000000000007c8   _cfinfoa
  word[2] @+16 = 0x0000000104f2c734   pointer to the bytes
  word[3] @+24 = 0x000000000000000b   length (11)
```

So: `{ isa, _cfinfoa, uint8_t *_ptr, uint32_t _length }` — a **two-word**
`CFRuntimeBase`, with the payload starting at +16.

**My first probe assumed a three-word base** (isa, `_swift_rc`, `_cfinfoa`),
put `_ptr` at +24, and segfaulted dereferencing the length as a pointer. The
three-word form is real but is the `DEPLOYMENT_RUNTIME_SWIFT` variant —
`_CF_CONST_STR_CONTENTS` in CFInternal.h — and we build with that off, so we get
the two-word `CF_CONST_STRING` form, which is also what macOS uses. Reading the
header would have shown both and not said which; the memory dump said which.

Two details worth keeping: `0x7c8` matches `CF_CONST_STRING`'s literal
`0x000007c8U` exactly, confirming the file's own macro is the one in effect; and
the length lives in its own word, so a class reading `_length` as declared
(`uint32_t`) is correct on a little-endian target and would be silently wrong on
a big-endian one — noted rather than guarded, since we are arm64-only.

## Registration is downstream of all of this

`scripts/check_registration.py` refuses until every one of the 19 exists,
because a partially populated `__CFRuntimeObjCClassTable` is worse than an empty
one for the temporal reason in CF_TRIAGE §36: an instance created before its
type registers keeps `_cfisa = 0` while the slot later holds a class. So
registration goes in `__CFInitialize`, before any instance exists, and the
checker enforces that as `MISPLACED`.

## Order of work

The refusal list is the work order. Starting points chosen for leverage:

1. `__NSCFConstantString` — the live armed bug, self-contained, and its
   verification is available today (a `CFSTR` literal must answer `length`).
2. `__NSCFString` — 46 dispatch sites, the most of any type, and the class
   libswiftCore's `String` bridging bottoms out on.
3. `__NSCFArray` / `__NSCFDictionary` / `__NSCFSet` — the cluster primitives
   that `swift_stdlib_connectNSBaseClasses` re-parents onto.

The remaining 14 are mechanical once the pattern is established, and each is
one CF function per selector.


## Where these classes live, and what actually flips `canImport(Foundation)`

The #54 trap says a nearly-empty Foundation is worse than none, because its
existence flips OpenUIKit's 33 `canImport(Foundation)` guards onto a path it
cannot satisfy. So: do the 19 classes flip them?

**No — and the reason is not the one I was about to give.** I was going to argue
that the classes are safe because they are an ObjC dylib while `canImport` is a
Swift-module question, so only `build_overlay.sh`'s `-module-name Foundation`
could flip the guards. That reasoning is wrong. Measured:

```
A: no Foundation.swiftmodule on the search path  -> FOUNDATION_VISIBLE
B: a Foundation.swiftmodule on the search path   -> FOUNDATION_VISIBLE
control: canImport(NoSuchModuleXYZ)              -> takes the #else
```

`canImport(Foundation)` is **already true** for anything compiled against our
staged SDK, with no `-I` at all. It is satisfied by a CLANG module:

```
$SDK/System/Library/Frameworks/Foundation.framework/Modules/module.modulemap
```

which `scripts/stage_sdk.sh` puts there. The control matters: a module name that
certainly does not exist takes the `#else`, so the probe discriminates and
"visible" is a real answer rather than a stuck one.

**Consequences for where the classes live:**

* Adding all 19 `__NSCF*` classes to the ObjC dylib changes nothing about the
  guards. They were already flipped, by the SDK, before any of this work.
* The lever is therefore **which SDK a target compiles against**, not which
  `-I` it gets. An app-only *include path* is the wrong knob; an app-only
  *sysroot*, or an SDK without the Foundation framework directory, is the right
  one.
* Which means the risk #54 identified is real but already realised, and is not
  something this task can newly cause. Anything compiling OpenUIKit's
  freestanding branch against this SDK is relying on those guards being false
  when they measure true — worth checking on the OpenUIKit side, because it is
  the sort of thing that works until a guarded branch is actually reached.

So the 19 classes go in the ObjC half (`src/nscf/`, built into the same dylib as
the slice) and the question that needs answering is not about them.
