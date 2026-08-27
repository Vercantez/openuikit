/* Does the bridge survive MUTATION and REFERENCE COUNTING?
 *
 * t9 proved reads work: strings, constant strings, arrays and dictionaries,
 * through CF and through objc_msgSend. Everything it touched was IMMUTABLE and
 * nothing it did could leak. This asks the two questions t9 could not:
 *
 *   1. do mutable collections work through the bridge
 *   2. is retain/release coherent across the boundary
 *
 * and MEASURES the ownership defect named in src/nscf/NSCFError.m rather than
 * restating it: five accessors return a +1 object through a selector whose
 * Foundation convention is non-owning, with no autorelease pool to absorb it.
 * That was a note when nothing executed. It is reachable code now.
 *
 * FICTION IN SCOPE: none. Nothing here touches bundles or forks, so neither
 * remaining probe stub is on any path.
 */
#import <objc/NSObject.h>
#import <objc/runtime.h>
#import "CFFoundationTypes.h"
#import "CFFoundationInterfaces.h"
#include <stdio.h>
#include <string.h>

#include <CFBase.h>
#include <CFString.h>
#include <CFArray.h>
#include <CFDictionary.h>
#include <CFError.h>

extern void __CFInitialize(void);

static int fails = 0;
static void ok(const char *name, int cond, const char *why)
{
    printf(cond ? "  ok   %-34s %s\n" : "  FAIL %-34s %s\n", name, why);
    fflush(stdout);
    if (!cond) fails++;
}

int main(void)
{
    __CFInitialize();
    CFStringRef s = CFStringCreateWithCString(NULL, "v", kCFStringEncodingUTF8);

    /* ---- 1. mutable array: mutate through CF, read through the bridge ------ */
    CFMutableArrayRef ma = CFArrayCreateMutable(NULL, 0, &kCFTypeArrayCallBacks);
    ok("CFMutableArray created", ma != NULL, "non-NULL");
    if (ma) {
        Class c = object_getClass((id)ma);
        printf("     isa -> %s\n", c ? class_getName(c) : "(null)"); fflush(stdout);
        /* The mutable and immutable variants share one typeID, so they share one
         * registration slot and therefore one class. Whether that is right is
         * the question -- Foundation has __NSCFArray for both. */
        ok("mutable array isa is __NSCFArray",
           c && !strcmp(class_getName(c), "__NSCFArray"),
           "mutable and immutable share a typeID, so they share a class");

        CFArrayAppendValue(ma, s);
        CFArrayAppendValue(ma, s);
        ok("CFArrayGetCount after append == 2", CFArrayGetCount(ma) == 2,
           "CF sees its own mutation");
        ok("[array count] sees the mutation", (NSUInteger)[(id)ma count] == 2,
           "and so does the bridge -- a stale count here would mean the bridge "
           "cached something");
    }

    /* ---- 2. mutable dictionary -------------------------------------------- */
    CFMutableDictionaryRef md = CFDictionaryCreateMutable(NULL, 0,
        &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    ok("CFMutableDictionary created", md != NULL, "non-NULL");
    if (md) {
        Class c = object_getClass((id)md);
        printf("     isa -> %s\n", c ? class_getName(c) : "(null)"); fflush(stdout);
        ok("mutable dict isa is __NSCFDictionary",
           c && !strcmp(class_getName(c), "__NSCFDictionary"),
           "the isa fix covers the mutable path too -- it goes through the same "
           "_CFRuntimeSetInstanceTypeIDAndIsa");
        CFDictionarySetValue(md, CFSTR("k"), s);
        ok("CFDictionaryGetCount == 1", CFDictionaryGetCount(md) == 1, "CF sees it");
        ok("[dict count] sees the mutation", (NSUInteger)[(id)md count] == 1,
           "and the bridge agrees");
        ok("[dict objectForKey:] after mutation",
           (const void *)[(id)md objectForKey:(id)CFSTR("k")] == (const void *)s,
           "keyed read of a value inserted through CF");
    }

    /* ---- 3. retain/release coherence across the boundary ------------------- */
    /* CFRetain and -retain must be the same operation on the same counter. If
     * they are not, an object retained by ObjC and released by CF is freed
     * early -- the kind of bug that shows up far from its cause. */
    CFStringRef r = CFStringCreateWithCString(NULL, "rc", kCFStringEncodingUTF8);
    CFIndex rc0 = CFGetRetainCount(r);
    printf("     retain count at birth: %ld\n", (long)rc0); fflush(stdout);

    CFRetain(r);
    CFIndex rc1 = CFGetRetainCount(r);
    ok("CFRetain increments", rc1 == rc0 + 1, "CF side");

    [(id)r retain];
    CFIndex rc2 = CFGetRetainCount(r);
    ok("-retain increments the SAME counter", rc2 == rc1 + 1,
       "ObjC retain must not maintain a separate count");

    [(id)r release];
    ok("-release decrements it", CFGetRetainCount(r) == rc1, "symmetric");
    CFRelease(r);
    ok("CFRelease decrements it", CFGetRetainCount(r) == rc0, "back to birth");

    /* ---- 4. THE OWNERSHIP DEFECT, MEASURED --------------------------------- */
    /* -userInfo is non-owning by Foundation convention; CFErrorCopyUserInfo
     * returns +1. src/nscf/NSCFError.m returns it directly, so every call adds
     * a reference nothing will ever drop. Measured rather than asserted: call
     * it repeatedly and watch the count climb. */
    CFErrorRef err = CFErrorCreate(NULL, CFSTR("dom"), 1, NULL);
    ok("CFError created", err != NULL, "non-NULL");
    if (err) {
        CFDictionaryRef u1 = (CFDictionaryRef)[(id)err userInfo];
        if (u1) {
            CFIndex before = CFGetRetainCount(u1);
            for (int i = 0; i < 5; i++) (void)[(id)err userInfo];
            CFIndex after = CFGetRetainCount(u1);
            printf("     userInfo retain count: %ld -> %ld over 5 calls\n",
                   (long)before, (long)after); fflush(stdout);
            /* THE ASSERTION IS THAT IT LEAKS, because it does. Pinning the
             * defect makes the eventual fix observable: when an autorelease
             * pool or a CFAutorelease lands, this flips and the test says so
             * loudly instead of passing quietly in both worlds. */
            ok("-userInfo LEAKS +1 per call (known defect)", after == before + 5,
               "5 calls, 5 unbalanced references -- pinned so the fix is visible");
        } else {
            ok("-userInfo returned non-NULL", 0, "expected a userInfo dictionary");
        }
    }

    printf(fails ? "\nT10 FAIL (%d)\n" : "\nT10 PASS\n", fails);
    return fails != 0;
}
