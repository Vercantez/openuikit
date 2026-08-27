/* #51 item (3): the three-case CF_IS_OBJC test.
 *
 * CF_IS_OBJC decides, for every CF call that can receive either a CF object or
 * a Foundation object, WHICH ONE IT HAS. It is one comparison:
 *
 *   CFInternal.h:967-970
 *     if (!obj) return false;
 *     return ((uintptr_t)((CFRuntimeBase *)obj)->_cfisa) != __CFISAForTypeID(typeID);
 *
 * and __CFISAForTypeID reads __CFRuntimeObjCClassTable[typeID], the slot
 * _CFRuntimeBridgeClasses fills. _CFRuntimeCreateInstance initialises a new
 * instance's _cfisa FROM THAT SAME SLOT (CFRuntime.c:550), which is the fact
 * the whole design rests on and the reason the cases below come out as they do.
 *
 * WHAT EACH CASE IS FOR:
 *
 *   1  native, registered type      must be FALSE. CF must treat its own
 *                                   object as a CF object.
 *   2  foreign Objective-C object   must be TRUE. CF must message it instead.
 *   3  native, _cfisa == 0          must be TRUE -- AND THAT IS THE BUG.
 *                                   This is the state of an instance created
 *                                   BEFORE its type was registered. It is a
 *                                   CF object being reported as foreign, which
 *                                   means CF would send it a message. The test
 *                                   asserts the misbehaviour because the
 *                                   misbehaviour is real; what prevents it is
 *                                   registration happening at the TOP of
 *                                   __CFInitialize, before any instance exists.
 *   4  native, UNREGISTERED type    must be FALSE. This one exists because I
 *                                   got it wrong: §35 claimed unregistered
 *                                   types would "invert" once anything
 *                                   registered. They do not. An unregistered
 *                                   type has slot 0 and its instances get
 *                                   _cfisa 0, so 0 != 0 is false and the type
 *                                   is self-consistent. The hazard is TEMPORAL
 *                                   (case 3), not partial. Case 4 is the
 *                                   retraction, kept as an executable claim so
 *                                   it cannot quietly drift back.
 */
#import <objc/NSObject.h>
#import <objc/runtime.h>
#include <stdio.h>
#include <stdint.h>

typedef unsigned long   CFTypeID;
typedef long            CFIndex;
typedef unsigned char   Boolean;
typedef const void     *CFTypeRef;
typedef const struct __CFAllocator *CFAllocatorRef;

extern Boolean   _CFIsObjC(CFTypeID typeID, void *obj);
extern CFTypeRef _CFRuntimeCreateInstance(CFAllocatorRef, CFTypeID, CFIndex, unsigned char *);
extern void      __CFInitialize(void);

/* CFRuntime_Internal.h */
#define kTypeCFString     7UL    /* BRIDGED   -> __NSCFString      */
#define kTypeCFBinaryHeap 23UL   /* NOT_BRIDGED, adjudicated in docs/cf-registration.tsv */

/* CFRuntimeBase: isa at +0. Measured from a real CFSTR, see NSCFConstantString.m. */
struct RuntimeBaseHead { uintptr_t isa; uintptr_t cfinfoa; };

static int failures = 0;
static void check(const char *name, int got, int want, const char *why)
{
    if (got == want) {
        printf("  ok   %-34s %s\n", name, why);
    } else {
        printf("  FAIL %-34s got %d want %d -- %s\n", name, got, want, why);
        failures++;
    }
}

int main(void)
{
    __CFInitialize();

    /* ---- 1. native instance of a REGISTERED type -> not ObjC --------------- */
    CFTypeRef native = _CFRuntimeCreateInstance(NULL, kTypeCFString, 0, NULL);
    if (!native) { printf("FAIL could not create a native CFString instance\n"); return 1; }
    check("native/registered", _CFIsObjC(kTypeCFString, (void *)native), 0,
          "CF's own object must not be messaged");

    /* Registration actually happened -- otherwise case 1 passes for the wrong
     * reason (0 != 0 is also false). This is the control that separates
     * "registered and matching" from "nothing registered at all". */
    uintptr_t isa = ((struct RuntimeBaseHead *)native)->isa;
    check("registration really happened", isa != 0, 1,
          "_cfisa is non-zero, so the slot held a class at creation time");
    if (isa) {
        printf("       _cfisa -> %s\n", class_getName((Class)isa));
    }

    /* ---- 2. a genuine Objective-C object -> is ObjC ------------------------ */
    id foreign = [[NSObject alloc] init];
    check("foreign ObjC object", _CFIsObjC(kTypeCFString, (void *)foreign), 1,
          "a real ObjC isa differs from the slot, so CF must message it");

    /* ---- 3. THE TEMPORAL HAZARD ------------------------------------------- */
    /* An instance created before its type was registered keeps _cfisa == 0
     * while the slot later holds a class. Reproduced by clearing _cfisa, which
     * is exactly the state such an instance would be in. */
    CFTypeRef stale = _CFRuntimeCreateInstance(NULL, kTypeCFString, 0, NULL);
    ((struct RuntimeBaseHead *)stale)->isa = 0;
    check("native created pre-registration", _CFIsObjC(kTypeCFString, (void *)stale), 1,
          "MISREPORTED as foreign -- this is why registration precedes instances");

    /* ---- 4. unregistered type is self-consistent (the retraction) ---------- */
    CFTypeRef unreg = _CFRuntimeCreateInstance(NULL, kTypeCFBinaryHeap, 0, NULL);
    if (!unreg) { printf("FAIL could not create a CFBinaryHeap instance\n"); return 1; }
    check("native/unregistered", _CFIsObjC(kTypeCFBinaryHeap, (void *)unreg), 0,
          "slot 0 and _cfisa 0 agree -- no inversion, contra the retracted claim");
    check("unregistered slot is empty", ((struct RuntimeBaseHead *)unreg)->isa == 0, 1,
          "and it is empty for the reason claimed, not by accident");

    /* ---- NULL, which the macro special-cases before touching memory -------- */
    check("NULL", _CFIsObjC(kTypeCFString, NULL), 0,
          "guarded at CFInternal.h:968 before any dereference");

    printf(failures ? "\nT8 FAIL (%d)\n" : "\nT8 PASS\n", failures);
    return failures != 0;
}
