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
    src = open(path).read()
    if new.split("\n")[0] in src:
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

ok = True
print(f"patching {CF}")
ok &= apply(INTERNAL, OLD_INTERNAL, NEW_INTERNAL, "CFInternal.h  (CF_IS_OBJC + 3)")
ok &= apply(RUNTIME,  OLD_RUNTIME,  NEW_RUNTIME,  "CFRuntime.c   (CFTYPE_* + 2)")
ok &= apply(RUNTIME,  OLD_CONSTSTR, NEW_CONSTSTR, "CFRuntime.c   (constant-string placeholder)")
ok &= apply(RUNTIME,  OLD_INIT,     NEW_INIT,     "CFRuntime.c   (_CFRuntimeBridgeClasses)")
sys.exit(0 if ok else 1)
