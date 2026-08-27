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


ok = True
print(f"patching {CF}")
ok &= apply(INTERNAL, OLD_INTERNAL, NEW_INTERNAL, "CFInternal.h  (CF_IS_OBJC + 3)")
ok &= apply(RUNTIME,  OLD_RUNTIME,  NEW_RUNTIME,  "CFRuntime.c   (CFTYPE_* + 2)")
sys.exit(0 if ok else 1)
