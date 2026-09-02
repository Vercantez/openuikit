// T19 — the CFString operations the preferences/bundle path performs on
// CONSTANT strings, driven directly so they are reachable while wall 1 (#80,
// CFLock_t's errorcheck mutex) still blocks T16 and T18.
//
// WHY THIS EXISTS. Selector discovery for __NSCFConstantString was
// execution-driven through T18, and T18 now stops inside
// CFBundleGetInfoDictionary on the MUTEX, not on a selector. Both discovery
// vehicles converge on wall 1. This one does not: every call below operates on
// a CFSTR and takes no CF lock, so it keeps naming selectors while #80 is
// someone else's task.
//
// The operations are not "the CFString API". They are the ones the preferences
// and bundle paths were measured to perform on constant strings:
//
//   CFPreferences.c:135        CFStringHasPrefix on the host-UUID literal
//   CFKnownLocations.c:38      CFURLCreateWithFileSystemPath(CFSTR("/Library/Preferences"))
//   CFPreferences.c            CFDictionary lookups keyed by CFSTR  -> CFHash/CFEqual
//   CFString.c:2236            CFStringGetCStringPtr -> -_fastCStringContents:
//   CFStringFindWithOptionsAndLocale, reached from CFURLCreateWithFileSystemPath
//
// EACH CHECK ASSERTS A VALUE, not merely survival. `_fastCStringContents:` was
// added to this class in the same change; "T18 got further" shows it does not
// crash and says NOTHING about whether it returns the right bytes. A selector
// that returns a wrong pointer would also "get further", right up until
// something reads through it.
//
// Golden for every expected value:
//   ~/swift-macho-linux/full/oracle-userdefaults/darwin-conststring-2026-08-28.txt

#import <objc/objc.h>
#include <stdint.h>
#include <string.h>

extern long write(int, const void *, unsigned long);
extern int  snprintf(char *, unsigned long, const char *, ...);

typedef const void *CFTypeRef;
typedef const struct __CFString *CFStringRef;
typedef const struct __CFAllocator *CFAllocatorRef;
typedef const struct __CFURL *CFURLRef;
typedef const struct __CFDictionary *CFDictionaryRef;
typedef signed long CFIndex;
typedef unsigned char Boolean;
typedef unsigned long CFTypeID;
typedef unsigned long CFHashCode;
typedef uint32_t CFStringEncoding;
typedef unsigned short UniChar;
typedef struct { CFIndex location, length; } CFRange;

extern CFStringRef CFStringCreateWithCString(CFAllocatorRef, const char *, CFStringEncoding);
extern const char *CFStringGetCStringPtr(CFStringRef, CFStringEncoding);
extern Boolean CFStringGetCString(CFStringRef, char *, CFIndex, CFStringEncoding);
extern const UniChar *CFStringGetCharactersPtr(CFStringRef);
extern CFIndex CFStringGetLength(CFStringRef);
extern UniChar CFStringGetCharacterAtIndex(CFStringRef, CFIndex);
extern Boolean CFStringHasPrefix(CFStringRef, CFStringRef);
extern Boolean CFStringHasSuffix(CFStringRef, CFStringRef);
extern CFIndex CFStringCompare(CFStringRef, CFStringRef, unsigned long);
extern Boolean CFStringFindWithOptions(CFStringRef, CFStringRef, CFRange, unsigned long, CFRange *);
extern CFHashCode CFHash(CFTypeRef);
extern Boolean CFEqual(CFTypeRef, CFTypeRef);
extern CFTypeID CFGetTypeID(CFTypeRef);
extern CFTypeID CFStringGetTypeID(void);
extern void CFRelease(CFTypeRef);
extern CFURLRef CFURLCreateWithFileSystemPath(CFAllocatorRef, CFStringRef, CFIndex, Boolean);
extern CFStringRef CFURLCopyFileSystemPath(CFURLRef, CFIndex);

/* CF's own definition. The builtin is what stamps
 * ___CFConstantStringClassReference into __DATA,__cfstring -- i.e. what makes
 * the literal an instance of __NSCFConstantString in the first place. Declared
 * here rather than pulled from the SDK's CoreFoundation, which is Apple's and
 * not the CF under test. Needs -fconstant-cfstrings. */
#define CFSTR(s) ((CFStringRef)__builtin___CFStringMakeConstantString("" s ""))

#define UTF8 0x08000100
#define ASCII 0x0600
#define POSIX 0

static int fails = 0, passes = 0;
static void say(const char *s){unsigned long n=0;while(s[n])n++;(void)!write(2,s,n);}
static void step(const char *s){ say("  .. "); say(s); say("\n"); }
static void ok(const char *s){ say("  OK   "); say(s); say("\n"); passes++; }
static void bad(const char *s){ say("  FAIL "); say(s); say("\n"); fails++; }
static void badf(const char *fmt, const char *a){ char b[512]; snprintf(b,sizeof b,fmt,a); bad(b); }

int main(int argc, char **argv) {
    char buf[512];

    /* NEGATIVE CONTROL, in its own process because it ends in abort().
     *
     * -_getCString:maxLength:encoding: refuses non-byte-compatible encodings
     * LOUDLY rather than returning NO, because CF reads NO as "did not fit".
     * That refusal is only evidence if it is known to fire -- the same reason
     * docs/cf-census/target-os-mac-sweep.md added t12_stub_control.m rather
     * than inferring an untaken branch from an absence of output.
     *
     *     t19 refuse   -> must print UNIMPLEMENTED and abort (exit 134)
     */
    if (argc > 1 && strcmp(argv[1], "refuse") == 0) {
        say("T19 refuse: asking for UTF-16 (0x0100), which we do not transcode.\n"
            "Expected: a loud UNIMPLEMENTED naming the encoding, then SIGABRT.\n");
        char b[64];
        Boolean r = CFStringGetCString(CFSTR("hello"), b, sizeof b, 0x0100);
        say("*** REACHED THE LINE AFTER THE REFUSAL -- the loud path did NOT\n"
            "*** fire, so every 'it refuses' claim about this method is unproven.\n");
        return r ? 3 : 4;
    }

    say("\n=== T19: CFString dispatch on CONSTANT strings ===\n");
    say("Every constant string takes the ObjC branch of every typeID-free\n"
        "dispatch, because its isa can never equal CFString's slot.\n\n");

    CFStringRef k = CFSTR("hello");

    // ---------------------------------------------------- the new selector
    step("CFStringGetCStringPtr -> -_fastCStringContents: (the selector T18 named)");
    const char *p = CFStringGetCStringPtr(k, UTF8);
    if (!p) bad("CFStringGetCStringPtr returned NULL; Darwin returns \"hello\"");
    else if (strcmp(p, "hello") != 0) badf("wrong bytes back: '%s'", p);
    else {
        ok("returned the literal's bytes");
        // The measured Darwin property that decided the implementation.
        if (p[CFStringGetLength(k)] == 0) ok("bytes are NUL-terminated at [length]");
        else bad("bytes are NOT NUL-terminated -- :YES must then return NULL");
    }

    step("CFStringGetCharactersPtr -> -_fastCharacterContents (must be NULL: 8-bit)");
    if (CFStringGetCharactersPtr(k) == 0) ok("NULL, matching Darwin for a constant string");
    else bad("returned a UniChar buffer; a constant string has none");

    // ------------------------------------------- the primitives, re-asserted
    step("length / characterAtIndex:");
    if (CFStringGetLength(k) == 5) ok("length == 5"); else bad("wrong length");
    if (CFStringGetCharacterAtIndex(k, 1) == 'e') ok("characterAtIndex:1 == 'e'");
    else bad("wrong character");

    // ------------------------------------- the three typeID-free dispatches
    step("CFGetTypeID -> -_cfTypeID");
    if (CFGetTypeID(k) == CFStringGetTypeID()) ok("CFGetTypeID == CFStringGetTypeID()");
    else bad("constant string reports the wrong type ID");

    step("CFHash -> -hash, and it must AGREE with a dynamic string of equal content");
    CFStringRef dyn = CFStringCreateWithCString(0, "hello", UTF8);
    if (!dyn) { bad("could not create the dynamic control"); }
    else {
        CFHashCode hc = CFHash(k), hd = CFHash(dyn);
        if (hc == hd) ok("CFHash(constant) == CFHash(dynamic) for equal content");
        else bad("hashes disagree -- a dictionary would lose keys across the two");

        step("CFEqual -> -isEqual: across two DIFFERENT representations");
        // selector-reentry.md records that t9's lookup never actually hashed,
        // because CFSTR twice yields ONE pointer and the compare short-circuits
        // on identity. This pair CANNOT short-circuit: different classes,
        // different storage, equal content. That is the case that was
        // impossible before -hash/-isEqual: existed on this class.
        if (CFEqual(k, dyn)) ok("CFEqual(constant, dynamic) is true");
        else bad("CFEqual says two equal strings differ");
        if (CFEqual(dyn, k)) ok("CFEqual is symmetric across the two");
        else bad("CFEqual is asymmetric -- one direction dispatches, the other does not");
        CFRelease(dyn);
    }

    step("identity: CFSTR(\"x\") twice is ONE pointer (why t9 never hashed)");
    if (CFSTR("x") == CFSTR("x")) ok("same pointer, as on Darwin");
    else bad("distinct pointers -- unexpected, and t9's comment would then hold");

    // ------------------------------------------------ operations on literals
    step("CFStringHasPrefix (CFPreferences.c:135 does this on a literal)");
    if (CFStringHasPrefix(CFSTR("00000000-0000-1000-8000-abc"), CFSTR("00000000-0000-1000-8000-")))
        ok("prefix of a constant by a constant");
    else bad("CFStringHasPrefix wrong on two constants");
    if (!CFStringHasPrefix(k, CFSTR("world"))) ok("negative control: not a prefix");
    else bad("CFStringHasPrefix said yes to a non-prefix");

    step("CFStringCompare on two constants");
    if (CFStringCompare(CFSTR("a"), CFSTR("b"), 0) < 0) ok("\"a\" < \"b\"");
    else bad("CFStringCompare ordering wrong");
    if (CFStringCompare(k, CFSTR("hello"), 0) == 0) ok("equal constants compare equal");
    else bad("equal constants do not compare equal");

    step("CFStringFindWithOptions (reached from CFURLCreateWithFileSystemPath)");
    CFRange r;
    if (CFStringFindWithOptions(CFSTR("a/b/c.plist"), CFSTR("/"),
                                (CFRange){0, 11}, 0, &r) && r.location == 1)
        ok("found \"/\" at index 1");
    else bad("CFStringFindWithOptions did not find the separator");

    step("CFStringGetCString into a caller buffer");
    if (CFStringGetCString(k, buf, sizeof buf, UTF8) && strcmp(buf, "hello") == 0)
        ok("copied \"hello\" out");
    else bad("CFStringGetCString did not produce the contents");

    // ------------------------------------------------ the URL path from #78
    step("CFURLCreateWithFileSystemPath(CFSTR(\"/Library/Preferences\")) "
         "-- CFKnownLocations.c:38, the literal that names our storage dir");
    CFURLRef u = CFURLCreateWithFileSystemPath(0, CFSTR("/Library/Preferences"), POSIX, 1);
    if (!u) bad("CFURLCreateWithFileSystemPath returned NULL");
    else {
        ok("created a CFURL from a constant string");
        CFStringRef back = CFURLCopyFileSystemPath(u, POSIX);
        if (back && CFStringGetCString(back, buf, sizeof buf, UTF8)
                 && strcmp(buf, "/Library/Preferences") == 0)
            ok("round-tripped the path back out");
        else badf("path came back as '%s'", back ? buf : "(null)");
        if (back) CFRelease(back);
        CFRelease(u);
    }

    char m[128];
    snprintf(m, sizeof m, "\nT19: pass %d  fail %d\n", passes, fails);
    say(m);
    if (fails == 0) say("T19 PASS\n");
    return fails == 0 ? 0 : 1;
}
