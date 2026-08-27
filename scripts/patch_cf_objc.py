#!/usr/bin/env python3
"""Restore CoreFoundation's Objective-C toll-free-bridging dispatch.

    scripts/patch_cf_objc.py <path-to-Sources/CoreFoundation>

Apple stripped CF's ObjC dispatch when open-sourcing it, but stripped only the
MACROS -- 294 call sites across 19 files are intact and waiting (docs/
CF_TRIAGE.md §4). This restores the six macros those call sites need.

WHAT MAKES THIS POSSIBLE, and it is not obvious:

  * The call sites use Objective-C MESSAGE SYNTAX -- `CF_OBJC_CALLV((NSString *)
    str, length)` splices into `[str length]`. So CF must be compiled as
    Objective-C (`-x objective-c`), not C. Measured: it does, 76/82 vs 77/82 as
    C, so ObjC compilation costs essentially nothing.

  * CoreFoundation_Prefix.h:87 has a designed `#if INCLUDE_OBJC` switch. Without
    -DINCLUDE_OBJC=1 it FAKES the runtime types -- `typedef char * id;`,
    `typedef char * Class;` -- which collide with the real <objc/objc.h> the
    moment you compile as ObjC. The switch is the supported hook; use it.

WHAT THIS DOES *NOT* DO, and must be understood before trusting the result:

  `_SetCFRuntimeObjcClass()` exists in CFInternal.h:916 but is CALLED FROM
  NOWHERE -- corelibs has no `_CFRuntimeBridgeClasses`, so
  __CFRuntimeObjCClassTable is never populated and __CFISAForTypeID() returns 0
  for every type. Native CF instances therefore get `_cfisa = 0` (CFRuntime.c:550).

  That means CF_IS_OBJC currently works by ACCIDENT: a native CF object has isa
  0, a real ObjC object has a real isa, so `isa != __CFISAForTypeID(typeID)`
  gives the right answer for both. It will KEEP giving the right answer only
  until something registers a class, at which point every unregistered type
  starts reporting its own instances as foreign ObjC objects and CF will message
  structs. Registration is a prerequisite for correctness, not an optimisation,
  and it is deliberately left undone here rather than half-done.
"""
import sys, os, re

CF = sys.argv[1] if len(sys.argv) > 1 else "Sources/CoreFoundation"

INTERNAL = os.path.join(CF, "internalInclude", "CFInternal.h")
RUNTIME  = os.path.join(CF, "CFRuntime.c")

OLD_INTERNAL = """#define CF_OBJC_FUNCDISPATCHV(typeID, obj, ...) do { } while (0)
#define CF_OBJC_RETAINED_FUNCDISPATCHV(typeID, obj, ...) do { } while (0)
#define CF_OBJC_CALLV(obj, ...) (0)
#define CF_IS_OBJC(typeID, obj) (0)"""

NEW_INTERNAL = """/* RESTORED -- see foundation-macho scripts/patch_cf_objc.py.
 * Apple stripped these four to no-ops when open-sourcing CF; the 294 call sites
 * that use them are still here. Requires -x objective-c and -DINCLUDE_OBJC=1. */
#if defined(__OBJC__)
#include <objc/message.h>
#include <objc/runtime.h>

/* An object is "ObjC" to CF when its isa is NOT the class CF registered for
 * this type -- i.e. it is a foreign NSString/NSArray/... rather than a CF
 * instance, so CF must message it instead of reading its struct.
 * NOTE: __CFISAForTypeID returns 0 until something calls _SetCFRuntimeObjcClass,
 * which nothing in corelibs does. See the module docstring. */
CF_INLINE Boolean _CFIsObjCDispatch(CFTypeID typeID, const void *obj) {
    if (!obj) return false;
    return ((uintptr_t)((CFRuntimeBase *)obj)->_cfisa) != __CFISAForTypeID(typeID);
}
#define CF_IS_OBJC(typeID, obj) _CFIsObjCDispatch((typeID), (const void *)(obj))

/* The call sites splice Objective-C message syntax through these, e.g.
 *   CF_OBJC_CALLV((NSString *)str, length)                 -> [str length]
 *   CF_OBJC_FUNCDISPATCHV(id, Boolean, (NSNumber *)n, boolValue)
 * so __VA_ARGS__ lands inside the brackets and must not be parenthesised. */
#define CF_OBJC_CALLV(obj, ...) [obj __VA_ARGS__]

#define CF_OBJC_FUNCDISPATCHV(typeID, rettype, obj, ...) \\
    do { if (CF_IS_OBJC(typeID, obj)) return (rettype)[obj __VA_ARGS__]; } while (0)

/* _RETAINED_ differs only in that the call site owns the result; CF's callers
 * already expect a +1 object here, so the message is the same. */
#define CF_OBJC_RETAINED_FUNCDISPATCHV(typeID, rettype, obj, ...) \\
    do { if (CF_IS_OBJC(typeID, obj)) return (rettype)[obj __VA_ARGS__]; } while (0)
#else
#define CF_OBJC_FUNCDISPATCHV(typeID, obj, ...) do { } while (0)
#define CF_OBJC_RETAINED_FUNCDISPATCHV(typeID, obj, ...) do { } while (0)
#define CF_OBJC_CALLV(obj, ...) (0)
#define CF_IS_OBJC(typeID, obj) (0)
#endif"""

OLD_RUNTIME = """#define CFTYPE_IS_OBJC(obj) (false)
#define CFTYPE_OBJC_FUNCDISPATCH0(rettype, obj, sel) do {} while (0)
#define CFTYPE_OBJC_FUNCDISPATCH1(rettype, obj, sel, a1) do {} while (0)"""

NEW_RUNTIME = """/* RESTORED -- see foundation-macho scripts/patch_cf_objc.py.
 * CFGetTypeID/CFHash/CFEqual dispatch through these. CFGetTypeID sending
 * -_cfTypeID is what makes _swift_stdlib_isNSString work: the Swift stdlib
 * implements it as CFGetTypeID(obj) == CFStringGetTypeID(). */
#if defined(__OBJC__)
/* No typeID here, so this asks "is this a CF instance at all". A CF instance
 * carries a registered isa; anything else is foreign. Same registration caveat
 * as CF_IS_OBJC. */
CF_INLINE Boolean _CFTypeIsObjC(const void *obj) {
    if (!obj) return false;
    uintptr_t isa = (uintptr_t)((CFRuntimeBase *)obj)->_cfisa;
    return isa != 0 && isa != __CFISAForTypeID(__CFGenericTypeID_inline(obj));
}
#define CFTYPE_IS_OBJC(obj) _CFTypeIsObjC((const void *)(obj))
#define CFTYPE_OBJC_FUNCDISPATCH0(rettype, obj, sel) \\
    do { if (CFTYPE_IS_OBJC(obj)) return (rettype)[(id)obj sel]; } while (0)
#define CFTYPE_OBJC_FUNCDISPATCH1(rettype, obj, sel, a1) \\
    do { if (CFTYPE_IS_OBJC(obj)) return (rettype)[(id)obj sel (a1)]; } while (0)
#else
#define CFTYPE_IS_OBJC(obj) (false)
#define CFTYPE_OBJC_FUNCDISPATCH0(rettype, obj, sel) do {} while (0)
#define CFTYPE_OBJC_FUNCDISPATCH1(rettype, obj, sel, a1) do {} while (0)
#endif"""


def apply(path, old, new, label):
    """Apply exactly once, and decide 'already applied' by the WHOLE replacement.

    TWO BUGS LIVED HERE, and the second was worse than the first.

    Originally this tested `new.split("\n")[0] in src` -- the first LINE of the
    replacement. False green whenever a patch keeps its first line unchanged,
    which the SetInstanceTypeIDAndIsa patch does: its replacement opens with
    `_CFRuntimeSetInstanceTypeID(cf, newTypeID);`, already in the file. The
    script printed "already patched", changed nothing, and only reading
    CFRuntime.c afterwards showed the #if still in place.

    The obvious fix -- `old not in src and new in src` -- is WRONG and I shipped
    it for one run. Several replacements legitimately CONTAIN their own anchor:
    NEW_INIT keeps `void __CFInitialize(void) {` and inserts before the body, so
    `old in src` stays true forever and the patch re-applies on every run. That
    put the whole 19-call registration block into CFRuntime.c TWICE.

    The correct test is the simplest one: THE WHOLE REPLACEMENT IS PRESENT.
    It is exact, it does not care whether the anchor survives, and a partially
    applied tree fails the `count(old) == 1` assertion below rather than being
    silently patched again.
    """
    src = open(path).read()
    if new in src:
        print(f"  {label}: already patched")
        return True
    if old not in src:
        print(f"  {label}: PATTERN NOT FOUND — corelibs may have changed", file=sys.stderr)
        return False
    open(path, "w").write(src.replace(old, new, 1))
    print(f"  {label}: patched")
    return True


# ---------------------------------------------------------------- registration
#
# _SetCFRuntimeObjcClass() exists at CFInternal.h:916 and is CALLED FROM NOWHERE:
# corelibs has no _CFRuntimeBridgeClasses, so __CFRuntimeObjCClassTable is never
# populated and __CFISAForTypeID() returns 0 for every type.
#
# That is why CF_IS_OBJC is currently RIGHT BY ACCIDENT. A native CF instance
# gets `_cfisa = __CFISAForTypeID(typeID)` = 0 (CFRuntime.c:550); a real ObjC
# object has a real isa; so `isa != __CFISAForTypeID(typeID)` happens to answer
# correctly for both. It inverts the moment anything registers a class: every
# UNREGISTERED type would then see its own instances as foreign and CF would
# start messaging structs.
#
# So registration is all-or-nothing per type, and it is a CORRECTNESS
# prerequisite rather than an optimisation.

OLD_INIT = "void __CFInitialize(void) {"

NEW_INIT = """CF_PRIVATE void _CFRuntimeBridgeClasses(CFTypeID typeID, const char *classname);

/* RESTORED -- see foundation-macho scripts/patch_cf_objc.py.
 * Binds a CF type to the Objective-C class whose instances CF hands out, so
 * __CFISAForTypeID() stops returning 0 and CF_IS_OBJC becomes right on purpose
 * rather than by accident. Looked up by NAME at run time, exactly as
 * libswiftCore's swift_stdlib_connectNSBaseClasses does -- CF must not link
 * against Foundation. */
CF_PRIVATE void _CFRuntimeBridgeClasses(CFTypeID typeID, const char *classname) {
#if defined(__OBJC__)
    Class cls = objc_lookUpClass(classname);
    if (!cls) {
        /* HALT rather than skip. Skipping looks safe and is the single worst
         * outcome: a PARTIALLY populated table. Registration is all-or-nothing
         * because CF_IS_OBJC compares an instance's _cfisa against this table,
         * and any type left at 0 while its neighbours hold classes is a type
         * whose own instances may be read as foreign.
         *
         * A missing class here means our Foundation is not loaded, which is a
         * deployment error rather than a condition to tolerate: CF is being
         * asked to bridge to something that is not there. Failing at
         * initialisation names the problem; continuing defers it to whichever
         * unrelated call first messages a struct. */
        CFLog(kCFLogLevelError,
              CFSTR("_CFRuntimeBridgeClasses: class %s not found -- Foundation "
                    "is not loaded. Refusing to leave a partially populated "
                    "bridge table."), classname);
        HALT;
    }
    _SetCFRuntimeObjcClass((uintptr_t)cls, typeID);
#endif
}

void __CFInitialize(void) {
    /* REGISTRATION, FIRST THING. Placement is not a style choice.
     *
     * __CFInitialize creates four instances of BRIDGED types further down --
     * three CFStrings and the __CFArgStuff CFArray, at CFRuntime.c:1335-1350 --
     * and _CFRuntimeCreateInstance stamps each one's _cfisa FROM THIS TABLE.
     * Registering after them would leave those four holding 0 while the table
     * holds classes, so CF_IS_OBJC would read them as foreign and message a
     * struct. __CFArgStuff is long-lived, so that landmine would persist for
     * the life of the process.
     *
     * This is safe here because Objective-C registers classes at IMAGE LOAD,
     * not from constructors -- measured, with a probe dylib whose constructor
     * successfully looked up a class defined in a different dylib. So our
     * Foundation's classes are findable by the time CF's constructor runs,
     * provided Foundation is a load-time dependency. If it is not, the lookup
     * fails and _CFRuntimeBridgeClasses halts rather than half-registering.
     *
     * All 19 together: the bridged set is exactly the types CF dispatches on,
     * and scripts/check_registration.py refuses if this list and that set
     * disagree in either direction. */
    _CFRuntimeBridgeClasses(_kCFRuntimeIDCFString, "__NSCFString");
    _CFRuntimeBridgeClasses(_kCFRuntimeIDCFArray, "__NSCFArray");
    _CFRuntimeBridgeClasses(_kCFRuntimeIDCFDictionary, "__NSCFDictionary");
    _CFRuntimeBridgeClasses(_kCFRuntimeIDCFSet, "__NSCFSet");
    _CFRuntimeBridgeClasses(_kCFRuntimeIDCFBag, "__NSCFBag");
    _CFRuntimeBridgeClasses(_kCFRuntimeIDCFData, "__NSCFData");
    _CFRuntimeBridgeClasses(_kCFRuntimeIDCFNumber, "__NSCFNumber");
    _CFRuntimeBridgeClasses(_kCFRuntimeIDCFBoolean, "__NSCFBoolean");
    _CFRuntimeBridgeClasses(_kCFRuntimeIDCFDate, "__NSCFDate");
    _CFRuntimeBridgeClasses(_kCFRuntimeIDCFTimeZone, "__NSCFTimeZone");
    _CFRuntimeBridgeClasses(_kCFRuntimeIDCFCalendar, "__NSCFCalendar");
    _CFRuntimeBridgeClasses(_kCFRuntimeIDCFLocale, "__NSCFLocale");
    _CFRuntimeBridgeClasses(_kCFRuntimeIDCFError, "__NSCFError");
    _CFRuntimeBridgeClasses(_kCFRuntimeIDCFURL, "NSURL");
    _CFRuntimeBridgeClasses(_kCFRuntimeIDCFCharacterSet, "__NSCFCharacterSet");
    _CFRuntimeBridgeClasses(_kCFRuntimeIDCFAttributedString, "__NSCFAttributedString");
    _CFRuntimeBridgeClasses(_kCFRuntimeIDCFReadStream, "__NSCFInputStream");
    _CFRuntimeBridgeClasses(_kCFRuntimeIDCFWriteStream, "__NSCFOutputStream");
    _CFRuntimeBridgeClasses(_kCFRuntimeIDCFRunLoopTimer, "__NSCFTimer");
"""

# --------------------------------------------------------- the constant string
#
# THE OTHER HALF OF src/nscf/NSCFConstantString.m. These two changes are only
# correct together, which is why they are one commit.
#
# With -fconstant-cfstrings the compiler stamps every CFSTR's isa with
# ___CFConstantStringClassReference. corelibs DEFINES that symbol here, as a
# zeroed int[24]. So CF_IS_OBJC is already true for every constant string in the
# process, and restoring CF's dispatch macros armed it: CF would send a message
# to a zeroed array as though it were a class.
#
# It has to be DELETED rather than shadowed. Leaving corelibs' definition while
# our Foundation also defines the symbol gives two definitions in two dylibs,
# and -- this is what makes it worth a patch rather than a link-order note --
# NOTHING COMPLAINS. Every symbol resolves. CF's own constant strings bind to
# the placeholder inside CF's image, everyone else's bind to the real class, and
# constant strings are split in half at runtime with no diagnostic anywhere.
# (The same shape as the signal.h shadowing in #47: the wrong definition wins
# because of where it sits, not because anything chose it.)
#
# __CFConstantStringClassReferencePtr is fixed in the same edit. corelibs sets
# it to NULL on this path, and _CFIsSwift compares an object's isa against it to
# recognise constant strings. NULL never matches, which was harmless only while
# the class reference was a zeroed array nothing could legitimately equal. Once
# the symbol denotes a real class, leaving the pointer NULL makes _CFIsSwift
# answer "not a constant string" for every constant string -- a defect that
# would have gone live precisely when the rest of this started working.

OLD_CONSTSTR = """#ifndef __CONSTANT_CFSTRINGS__
// Compiler uses this symbol name; must match compiler built-in decl, so we use 'int'
#if TARGET_RT_64_BIT
int __CFConstantStringClassReference[24] = {0};
#else
int __CFConstantStringClassReference[12] = {0};
#endif
#endif

#if TARGET_RT_64_BIT
int __CFConstantStringClassReference[24] = {0};
#else
int __CFConstantStringClassReference[12] = {0};
#endif

void *__CFConstantStringClassReferencePtr = NULL;"""

NEW_CONSTSTR = """/* PLACEHOLDER DELETED -- our Foundation defines this symbol for real.
 *
 * corelibs defined __CFConstantStringClassReference here as a zeroed int[24].
 * Every CFSTR in the process points its isa at that symbol, so with CF's ObjC
 * dispatch macros restored, CF would message a zeroed array as a class.
 *
 * src/nscf/NSCFConstantString.m aliases the symbol to the __NSCFConstantString
 * class object. Deleting this definition is what makes that alias the ONLY one:
 * with both present every symbol still resolves, CF's own constant strings bind
 * to the placeholder in CF's image and everyone else's to the real class, and
 * the split is completely silent. */
extern int __CFConstantStringClassReference[];

/* Was NULL. _CFIsSwift compares an isa against this pointer to recognise a
 * constant string; NULL never matched, which was invisible while the reference
 * was a zeroed array and becomes a live wrong answer once it is a real class. */
void *__CFConstantStringClassReferencePtr = &__CFConstantStringClassReference;"""

# ------------------------------------------------ corelibs' own Darwin stand-ins
#
# Two unguarded lines where corelibs declares a stand-in for something real
# Darwin provides. Correct for a Linux/Swift build, wrong for ours, and both
# surface only once CF is compiled as OBJECTIVE-C -- which is how it is actually
# built here and is not how the census was measuring it.
#
# This is the shadowing theme from the other side. Three of our OWN shims
# collide with the sysroot the same way (sys/uio.h's struct iovec and
# arpa/inet.h's htonl, both fixed in cf_shims.sh); these two are corelibs
# shadowing Darwin rather than us shadowing machorun. The rule generalises:
# A STAND-IN IS A CLAIM THAT THE REAL THING IS ABSENT, so it has to be guarded
# on that claim rather than stated unconditionally.

OLD_URLSTR = "typedef struct __NSString__ *NSString;"
NEW_URLSTR = """/* GUARDED: our Foundation supplies a real @interface NSString, and this
 * opaque typedef collides with it -- "redefinition of 'NSString' as a different
 * kind of symbol". corelibs needs the stand-in only where no Objective-C
 * NSString exists. */
#if !defined(__OBJC__)
typedef struct __NSString__ *NSString;
#endif"""

OLD_OSREL = "extern void os_release(void *object);"
NEW_OSREL = """/* GUARDED: <os/object.h> is in our SDK and, in an Objective-C TU, defines
 * os_release as a MACRO -- `#define os_release(object) [object release]`
 * (os/object.h:324). This forward declaration then expands mid-line and fails
 * with "expected expression". corelibs declares it because a Linux build has no
 * os/object.h at all. */
#if !defined(__OBJC__)
extern void os_release(void *object);
#endif"""

ok = True
print(f"patching {CF}")
ok &= apply(os.path.join(CF, "CFURLAccess.c"), OLD_URLSTR, NEW_URLSTR,
            "CFURLAccess.c (NSString stand-in)")
ok &= apply(os.path.join(CF, "CFRunLoop.c"), OLD_OSREL, NEW_OSREL,
            "CFRunLoop.c   (os_release stand-in)")
ok &= apply(INTERNAL, OLD_INTERNAL, NEW_INTERNAL, "CFInternal.h  (CF_IS_OBJC + 3)")
ok &= apply(RUNTIME,  OLD_RUNTIME,  NEW_RUNTIME,  "CFRuntime.c   (CFTYPE_* + 2)")
ok &= apply(RUNTIME,  OLD_CONSTSTR, NEW_CONSTSTR, "CFRuntime.c   (constant-string placeholder)")
ok &= apply(RUNTIME,  OLD_INIT,     NEW_INIT,     "CFRuntime.c   (_CFRuntimeBridgeClasses)")
# ------------------------------------------- the isa half of "TypeIDAndIsa"
#
# CFRuntime.c:621. The function is called _CFRuntimeSetInstanceTypeIDAndIsa and
# it sets the type id unconditionally and the isa ONLY under
# DEPLOYMENT_RUNTIME_SWIFT. We build with DEPLOYMENT_RUNTIME_SWIFT=0, so it does
# exactly half of what its name says.
#
# WHAT THAT COSTS: CFDictionary, CFSet and CFBag are all CFBasicHash instances,
# allocated with CFBasicHashGetTypeID() -- typeID 3 -- and then retyped to 18,
# 20 or 21 by this function. Each calls it five times. The retype moves the
# type id and leaves _cfisa holding slot 3's value, which is 0 because
# CFBasicHash is correctly NOT_BRIDGED.
#
# So every collection ends up with type id 18 and isa 0, and CF_IS_OBJC(18, obj)
# compares 0 against the __NSCFDictionary registration filled in slot 18, finds
# them different, concludes the object is FOREIGN, and sends it -count. The isa
# is 0. objc_msgSend reads the class at offset 0x10 and the process dies.
#
# MEASURED AGAINST macOS BEFORE CHANGING ANYTHING, because the fix rests on a
# claim about what real CF does:
#
#     CFDictionaryCreate  isa = __NSDictionaryI          CFGetTypeID 18
#     CFSetCreate         isa = __NSCFSet
#     CFArrayCreate       isa = __NSSingleObjectArrayI
#     [d count] via ObjC  = 1
#
# The isa is ALWAYS SET on macOS and messaging works. Note the classes are not
# uniformly __NSCF*: Apple returns size- and mutability-specialised classes
# (__NSDictionaryI, __NSSingleObjectArrayI). That is their optimised Foundation,
# not a contradiction -- the invariant that matters is that isa is never 0 and
# always agrees with what CF dispatches on. Ours has no specialised classes, so
# the registered __NSCF* class is the right target for us.
#
# The guard becomes unconditional. When newTypeID is unregistered,
# __CFISAForTypeID returns 0 and this writes 0 over 0 -- which is the
# self-consistent case t8 case 4 pins, so the unregistered path is unaffected.
OLD_ISA = """    _CFRuntimeSetInstanceTypeID(cf, newTypeID);
#if DEPLOYMENT_RUNTIME_SWIFT
    if (_CFTypeGetClass(cf) != __CFISAForTypeID(newTypeID)) {
        ((CFSwiftRef)cf)->isa = (uintptr_t)__CFISAForTypeID(newTypeID);
    }
#endif"""

NEW_ISA = """    _CFRuntimeSetInstanceTypeID(cf, newTypeID);
    /* THE ISA HALF, no longer Swift-only. Upstream guards this with
     * DEPLOYMENT_RUNTIME_SWIFT because Swift is the only runtime it bridges to;
     * we bridge to Objective-C, and without this every CFDictionary, CFSet and
     * CFBag carries the type id of its collection and the isa of the
     * CFBasicHash it was allocated as -- which is 0. CF_IS_OBJC then reads
     * 0 != __NSCFDictionary, calls its own object foreign, and messages a null
     * class. Verified on macOS that real CF always sets the isa here.
     *
     * Writes through CFRuntimeBase rather than upstream's CFSwiftRef: that
     * type is only declared under DEPLOYMENT_RUNTIME_SWIFT, so the original
     * line does not compile once the #if comes off. Same field, same offset --
     * _cfisa IS the isa -- reached through the type that exists in our
     * configuration. */
    if (_CFTypeGetClass(cf) != __CFISAForTypeID(newTypeID)) {
        ((CFRuntimeBase *)cf)->_cfisa = (uintptr_t)__CFISAForTypeID(newTypeID);
    }"""

ok &= apply(RUNTIME, OLD_ISA, NEW_ISA, "CFRuntime.c   (SetInstanceTypeIDAndIsa: the isa half)")

sys.exit(0 if ok else 1)
