/* Does CoreFoundation WORK, or does it merely initialise?
 *
 * Everything up to now proves the BRIDGE IS WIRED: registration lands,
 * CF_IS_OBJC discriminates, __CFInitialize completes. None of it proves a
 * single CF object does anything. This is the first time any of that code
 * executes.
 *
 * WHICH RESULTS DEPEND ON FICTION: none of them. The two remaining probe
 * fictions are pthread_atfork (a no-op; only matters across fork(), which this
 * never does) and _NSGetExecutablePath (returns the LOADER's path, not the
 * guest's; only matters to bundle lookup). NOTHING BELOW TOUCHES BUNDLES OR
 * FORKS, deliberately -- a bundle-dependent result here would be measuring a
 * lie. If a case is ever added that resolves a resource path, it has to be
 * marked, because it will silently be reading machorun's own directory.
 *
 * Expect failures. The point is the SHAPE of what breaks.
 */
#import <objc/NSObject.h>
#import <objc/runtime.h>
/* The same method declarations CoreFoundation itself is built against. Without
 * them an undeclared selector's return type defaults to id, and casting id to
 * an integer is the exact defect CFFoundationInterfaces.h was written to stop
 * -- so the test that exercises the bridge must be built against the bridge's
 * own declarations, not against guesses. */
#import "CFFoundationTypes.h"
#import "CFFoundationInterfaces.h"
#include <stdio.h>
#include <string.h>

/* CoreFoundation's OWN headers, not hand-written externs.
 *
 * The first version of this file declared CFStringCreateWithCString,
 * CFArrayCreate and the callback structs by hand, and every one conflicted the
 * moment CF's real headers came into scope: kCFTypeArrayCallBacks is a
 * `const CFArrayCallBacks`, not a `const void *`, and CFArrayCreate takes a
 * TYPED callbacks pointer.
 *
 * Hand-declaring the API you are about to test is writing your own version of
 * the thing under test. Worse, it would have COMPILED had CF's headers stayed
 * out of scope -- passing a `const void *` where a struct pointer belongs, with
 * the mismatch invisible until the callbacks were dereferenced. Same defect
 * class as the id-return-type problem CFFoundationInterfaces.h exists to stop,
 * and the reason that header is included above rather than guessed at. */
#include <CFBase.h>
#include <CFString.h>
#include <CFArray.h>
#include <CFDictionary.h>

extern void __CFInitialize(void);

static int fails = 0;

/* EVERY LINE IS FLUSHED. Third time today that buffering has eaten the
 * evidence: a crash discards whatever printf has queued, so a test that dies
 * mid-way prints NOTHING and reads as "it never started" rather than "it got to
 * case 4". Here the output IS the measurement -- expected failures are the
 * deliverable -- so it has to survive the process dying.
 *
 * fflush rather than setvbuf: libSystem does not export setvbuf (measured at
 * the link), which is itself worth knowing. */
static void say(const char *fmt, const char *a, const char *b)
{ printf(fmt, a, b); fflush(stdout); }

static void ok(const char *name, int cond, const char *why)
{
    say(cond ? "  ok   %-32s %s\n" : "  FAIL %-32s %s\n", name, why);
    if (!cond) fails++;
}

int main(void)
{
    __CFInitialize();

    /* ---- 1. does a CF string come back, and what class is it? ------------- */
    CFStringRef s = CFStringCreateWithCString(NULL, "hello bridge", kCFStringEncodingUTF8);
    printf("CFStringCreateWithCString -> %p\n", (void *)s); fflush(stdout);
    ok("CFString created", s != NULL, "a non-NULL CFStringRef");
    if (!s) { printf("\nT9 FAIL (%d) -- nothing else can run\n", fails + 1); return 1; }

    Class cls = object_getClass((id)s);
    printf("     isa -> %s\n", cls ? class_getName(cls) : "(null)"); fflush(stdout);
    ok("isa is __NSCFString", cls && !strcmp(class_getName(cls), "__NSCFString"),
       "the registered bridge class, not a raw CF struct");

    ok("CFGetTypeID is CFString", CFGetTypeID(s) == CFStringGetTypeID(),
       "CF still recognises its own object through the bridge");

    /* ---- 2. CF's own accessors ------------------------------------------- */
    CFIndex len = CFStringGetLength(s);
    printf("     CFStringGetLength -> %ld\n", (long)len); fflush(stdout);
    ok("CFStringGetLength == 12", len == 12, "\"hello bridge\" is 12 characters");

    UniChar c0 = CFStringGetCharacterAtIndex(s, 0);
    ok("CFStringGetCharacterAtIndex", c0 == (UniChar)'h', "first character is 'h'");

    /* ---- 3. THE POINT OF THE WHOLE SURFACE: an ObjC message --------------- */
    /* This dispatches through objc_msgSend into __NSCFString's -length, which
     * forwards to CFStringGetLength. It is the 151-selector bridge executing
     * for the first time. */
    NSUInteger objcLen = (NSUInteger)[(id)s length];
    printf("     [str length] -> %lu\n", (unsigned long)objcLen); fflush(stdout);
    ok("-length through the bridge", objcLen == 12,
       "objc_msgSend -> __NSCFString -> CFStringGetLength");

    UniChar objcC = (UniChar)[(id)s characterAtIndex:0];
    ok("-characterAtIndex: through bridge", objcC == (UniChar)'h',
       "the second primitive, same path");

    /* ---- 4. a CFSTR literal, DEREFERENCED at runtime ---------------------- */
    /* Item (4) resolved this symbol at link. Nothing had ever read through one.
     * The __CFConstantStringClassReferencePtr NULL bug would have surfaced
     * exactly here -- at the moment everything else started working. */
    CFStringRef lit = CFSTR("literal");
    printf("CFSTR(\"literal\") -> %p\n", (void *)lit); fflush(stdout);
    ok("CFSTR is non-NULL", lit != NULL, "the compiler emitted it");
    if (lit) {
        Class lcls = object_getClass((id)lit);
        printf("     isa -> %s\n", lcls ? class_getName(lcls) : "(null)"); fflush(stdout);
        ok("CFSTR isa is __NSCFConstantString",
           lcls && !strcmp(class_getName(lcls), "__NSCFConstantString"),
           "the asm alias points at a real class object");
        ok("CFSTR length == 7", CFStringGetLength(lit) == 7, "\"literal\"");
        ok("CFSTR -length through bridge", (NSUInteger)[(id)lit length] == 7,
           "constant strings dispatch too");
    }

    /* ---- 5. collections --------------------------------------------------- */
    const void *vals[3] = { s, s, s };
    CFArrayRef arr = CFArrayCreate(NULL, vals, 3, &kCFTypeArrayCallBacks);
    printf("CFArrayCreate -> %p\n", (void *)arr); fflush(stdout);
    ok("CFArray created", arr != NULL, "a non-NULL CFArrayRef");
    if (arr) {
        ok("CFArrayGetCount == 3", CFArrayGetCount(arr) == 3, "three elements in");
        ok("CFArrayGetValueAtIndex", CFArrayGetValueAtIndex(arr, 1) == (const void *)s,
           "the same pointer comes back");
        Class acls = object_getClass((id)arr);
        printf("     isa -> %s\n", acls ? class_getName(acls) : "(null)"); fflush(stdout);
        ok("array isa is __NSCFArray", acls && !strcmp(class_getName(acls), "__NSCFArray"),
           "collections are bridged too");
    }

    const void *keys[2] = { CFSTR("a"), CFSTR("b") };
    const void *dvals[2] = { s, s };
    CFDictionaryRef dict = CFDictionaryCreate(NULL, keys, dvals, 2,
                                              &kCFTypeDictionaryKeyCallBacks,
                                              &kCFTypeDictionaryValueCallBacks);
    printf("CFDictionaryCreate -> %p\n", (void *)dict); fflush(stdout);
    ok("CFDictionary created", dict != NULL, "a non-NULL CFDictionaryRef");
    if (dict) {
        /* Print the isa BEFORE touching the dictionary. CFDictionaryGetCount
         * crashed inside objc_msgSend here, which can only mean CF_IS_OBJC came
         * back TRUE for an object CF itself created -- so the isa is the whole
         * question, and reading it must not go through CF. */
        Class dcls = object_getClass((id)dict);
        printf("     isa -> %s (raw %p)\n",
               dcls ? class_getName(dcls) : "(null)", (void *)dcls);
        fflush(stdout);
        printf("     CFGetTypeID(dict) = %lu   CFDictionaryGetTypeID() = %lu\n",
               (unsigned long)CFGetTypeID(dict), (unsigned long)CFDictionaryGetTypeID());
        fflush(stdout);
        ok("dict isa is __NSCFDictionary",
           dcls && !strcmp(class_getName(dcls), "__NSCFDictionary"),
           "if this is null or wrong, CF will message a non-class");
        ok("CFDictionaryGetCount == 2", CFDictionaryGetCount(dict) == 2, "two pairs in");
        /* Lookup exercises CFEqual and CFHash on constant strings -- the hash
         * path NSCFConstantString deliberately does NOT implement, so this is
         * the case most likely to fail, and informative either way. */
        const void *got = CFDictionaryGetValue(dict, CFSTR("a"));
        ok("CFDictionaryGetValue by CFSTR key", got == (const void *)s,
           "requires CFHash/CFEqual to agree across two distinct CFSTRs");
    }

    printf(fails ? "\nT9 FAIL (%d)\n" : "\nT9 PASS\n", fails);
    return fails != 0;
}
