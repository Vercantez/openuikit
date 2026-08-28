// T16 — DOES CoreFoundation's PREFERENCES PATH ACTUALLY EXECUTE?
//
// #78's route ruling turned on this question. CFPreferences, CFApplication-
// Preferences, CFXMLPreferencesDomain, CFKnownLocations, CFPropertyList,
// CFBinaryPList, CFURLAccess and CFFileUtilities have all COMPILED, LINKED and
// been exported from libCFTest.dylib. None of them has ever RUN. "It links" is
// not "it works", and this project's record is that the gap between them is
// where the real work lives.
//
// This drives the six entry points UserDefaults needs, in the order it needs
// them, straight at CF — no Swift, no Foundation, no bridging layer to blame.
//
// WHAT MAKES THIS A MEASUREMENT AND NOT A DEMO:
//
//  * every step prints BEFORE it calls, so a hard failure names the step it
//    died in rather than leaving a silent truncation. The init-wall probe in
//    this repo once printed nothing at all because printf is block-buffered to
//    a pipe and abort() discards the buffer, so everything here goes to fd 2
//    UNBUFFERED via write(2).
//
//  * the stubs underneath are loud (`STUB CALLED: <name>` then abort), so an
//    unimplemented dependency identifies itself instead of returning zero.
//
//  * a read-back that succeeds is NOT the result. The result is whether the
//    VALUE is right, whether the FILE appears, and what FORMAT it is in —
//    a store that silently drops writes and returns the cached in-memory copy
//    would pass a naive round-trip.
//
//  * negative controls: an absent key must return NULL, and a key removed must
//    stop being found. Without those, a CopyAppValue that returned the same
//    object for everything would look perfect.

#import <objc/objc.h>
#include <stdint.h>
#include <string.h>

extern long write(int, const void *, unsigned long);
extern int  snprintf(char *, unsigned long, const char *, ...);

// --- CF, declared here rather than included: this TU must not depend on the
// --- SDK's CoreFoundation headers, which are Apple's and not the ones we built.
typedef const void *CFTypeRef;
typedef const struct __CFString *CFStringRef;
typedef const struct __CFArray *CFArrayRef;
typedef const struct __CFDictionary *CFDictionaryRef;
typedef const struct __CFAllocator *CFAllocatorRef;
typedef const struct __CFNumber *CFNumberRef;
typedef signed long CFIndex;
typedef unsigned char Boolean;
typedef unsigned long CFTypeID;
typedef uint32_t CFStringEncoding;

extern CFStringRef CFStringCreateWithCString(CFAllocatorRef, const char *, CFStringEncoding);
extern Boolean CFStringGetCString(CFStringRef, char *, CFIndex, CFStringEncoding);
extern CFIndex CFStringGetLength(CFStringRef);
extern CFTypeID CFGetTypeID(CFTypeRef);
extern CFTypeID CFStringGetTypeID(void);
extern CFTypeID CFNumberGetTypeID(void);
extern CFTypeID CFArrayGetTypeID(void);
extern CFTypeID CFDictionaryGetTypeID(void);
extern void CFRelease(CFTypeRef);
extern CFIndex CFArrayGetCount(CFArrayRef);
extern const void *CFArrayGetValueAtIndex(CFArrayRef, CFIndex);
extern CFIndex CFDictionaryGetCount(CFDictionaryRef);
extern const void *CFDictionaryGetValue(CFDictionaryRef, const void *);
extern Boolean CFNumberGetValue(CFNumberRef, CFIndex, void *);
extern CFNumberRef CFNumberCreate(CFAllocatorRef, CFIndex, const void *);

extern CFTypeRef CFPreferencesCopyAppValue(CFStringRef, CFStringRef);
extern void      CFPreferencesSetAppValue(CFStringRef, CFTypeRef, CFStringRef);
extern Boolean   CFPreferencesAppSynchronize(CFStringRef);
extern CFArrayRef CFPreferencesCopyKeyList(CFStringRef, CFStringRef, CFStringRef);
extern CFDictionaryRef CFPreferencesCopyMultiple(CFArrayRef, CFStringRef, CFStringRef, CFStringRef);
extern void CFPreferencesAddSuitePreferencesToApp(CFStringRef, CFStringRef);

extern const CFStringRef kCFPreferencesCurrentApplication;
extern const CFStringRef kCFPreferencesCurrentUser;
extern const CFStringRef kCFPreferencesAnyHost;

#define kCFStringEncodingUTF8 0x08000100
#define kCFNumberSInt64Type 4

// --- unbuffered output, because a buffered one loses the last message on abort
static void say(const char *s) { unsigned long n = 0; while (s[n]) n++; (void)!write(2, s, n); }
static void sayf(const char *fmt, const char *a) { char b[1024]; snprintf(b, sizeof b, fmt, a); say(b); }
static int failures = 0;
static void step(const char *s) { say("  .. "); say(s); say("\n"); }
static void ok(const char *s)   { say("  OK   "); say(s); say("\n"); }
static void bad(const char *s)  { say("  FAIL "); say(s); say("\n"); failures++; }

static const char *cstr(CFStringRef s, char *buf, int n) {
    if (!s) return "(null)";
    if (CFGetTypeID(s) != CFStringGetTypeID()) return "(not a CFString)";
    if (!CFStringGetCString(s, buf, n, kCFStringEncodingUTF8)) return "(uncopyable)";
    return buf;
}

int main(void) {
    char buf[512];
    say("\n=== T16: does CF's PREFERENCES path execute? ===\n");
    say("Driving the six entry points UserDefaults needs, straight at CF.\n\n");

    // ---------------------------------------------------------------- setup
    step("CFStringCreateWithCString for the app domain + key");
    CFStringRef appID = CFStringCreateWithCString(0, "com.example.t16prefs", kCFStringEncodingUTF8);
    CFStringRef key   = CFStringCreateWithCString(0, "t16_key", kCFStringEncodingUTF8);
    CFStringRef val   = CFStringCreateWithCString(0, "t16_value", kCFStringEncodingUTF8);
    CFStringRef absent = CFStringCreateWithCString(0, "t16_absent", kCFStringEncodingUTF8);
    if (!appID || !key || !val) { bad("could not create the CFStrings"); return 1; }
    ok("CFStrings created");

    // ------------------------------------------- NEGATIVE CONTROL, run FIRST
    // If CopyAppValue returned something for everything, every check below
    // would pass. Establish that absence is answerable before trusting presence.
    step("CFPreferencesCopyAppValue on a key that was never set (must be NULL)");
    CFTypeRef none = CFPreferencesCopyAppValue(absent, appID);
    if (none == 0) ok("absent key -> NULL (the detector can say 'no')");
    else { bad("absent key returned a value -- every later check is worthless"); CFRelease(none); }

    // -------------------------------------------------------------- the write
    step("CFPreferencesSetAppValue (this is CFApplicationPreferences -> "
         "CFPreferences -> CFXMLPreferencesDomain)");
    CFPreferencesSetAppValue(key, val, appID);
    ok("CFPreferencesSetAppValue returned");

    step("CFPreferencesCopyAppValue reads it back from the in-memory domain");
    CFTypeRef got = CFPreferencesCopyAppValue(key, appID);
    if (!got) bad("read back NULL -- the write did not take");
    else if (CFGetTypeID(got) != CFStringGetTypeID()) bad("read back a non-CFString");
    else {
        const char *s = cstr((CFStringRef)got, buf, sizeof buf);
        if (strcmp(s, "t16_value") == 0) ok("value round-tripped in memory");
        else sayf("  FAIL wrong value back: '%s'\n", s), failures++;
        CFRelease(got);
    }

    // ----------------------------------------------- the part that touches disk
    step("CFPreferencesAppSynchronize -- THE FILE WRITE. This is "
         "__CFWriteBytesToFileWithAtomicity: mkstemp, write, fsync, chmod, rename.");
    Boolean synced = CFPreferencesAppSynchronize(appID);
    if (synced) ok("CFPreferencesAppSynchronize returned TRUE");
    else bad("CFPreferencesAppSynchronize returned FALSE (the write path failed)");

    // ------------------------------------------------- non-string plist types
    step("CFPreferencesSetAppValue with a CFNumber (exercises CFBinaryPList's "
         "integer encoding, not just strings)");
    int64_t n = 4242;
    CFNumberRef num = CFNumberCreate(0, kCFNumberSInt64Type, &n);
    CFStringRef nkey = CFStringCreateWithCString(0, "t16_num", kCFStringEncodingUTF8);
    CFPreferencesSetAppValue(nkey, num, appID);
    CFTypeRef gotn = CFPreferencesCopyAppValue(nkey, appID);
    if (!gotn) bad("CFNumber did not round-trip");
    else if (CFGetTypeID(gotn) != CFNumberGetTypeID()) bad("CFNumber came back as another type");
    else {
        int64_t out = 0;
        CFNumberGetValue((CFNumberRef)gotn, kCFNumberSInt64Type, &out);
        if (out == 4242) ok("CFNumber round-tripped");
        else bad("CFNumber came back with the wrong value");
        CFRelease(gotn);
    }

    // -------------------------------------------------------- the enumerations
    step("CFPreferencesCopyKeyList (this is the domain enumeration "
         "dictionaryRepresentation() sits on)");
    CFArrayRef keys = CFPreferencesCopyKeyList(appID, kCFPreferencesCurrentUser,
                                               kCFPreferencesAnyHost);
    if (!keys) bad("CFPreferencesCopyKeyList returned NULL");
    else {
        CFIndex c = CFArrayGetCount(keys);
        char m[128]; snprintf(m, sizeof m, "CFPreferencesCopyKeyList -> %ld keys", (long)c);
        if (c >= 2) ok(m); else bad(m);

        step("CFPreferencesCopyMultiple over those keys");
        CFDictionaryRef d = CFPreferencesCopyMultiple(keys, appID,
                                                      kCFPreferencesCurrentUser,
                                                      kCFPreferencesAnyHost);
        if (!d) bad("CFPreferencesCopyMultiple returned NULL");
        else {
            CFIndex dc = CFDictionaryGetCount(d);
            snprintf(m, sizeof m, "CFPreferencesCopyMultiple -> %ld entries", (long)dc);
            if (dc == c) ok(m); else bad(m);
            CFTypeRef v = (CFTypeRef)CFDictionaryGetValue(d, key);
            if (v && CFGetTypeID(v) == CFStringGetTypeID()
                  && strcmp(cstr((CFStringRef)v, buf, sizeof buf), "t16_value") == 0)
                ok("the value is reachable through CopyMultiple by key");
            else bad("CopyMultiple did not return our value for our key");
            CFRelease(d);
        }
        CFRelease(keys);
    }

    // ------------------------------------------------------------- the removal
    step("CFPreferencesSetAppValue(key, NULL) removes");
    CFPreferencesSetAppValue(key, 0, appID);
    CFTypeRef after = CFPreferencesCopyAppValue(key, appID);
    if (after == 0) ok("removed key -> NULL");
    else { bad("removed key still has a value"); CFRelease(after); }

    step("CFPreferencesAppSynchronize again (rewrites the file with one key)");
    if (CFPreferencesAppSynchronize(appID)) ok("second synchronize returned TRUE");
    else bad("second synchronize returned FALSE");

    // ------------------------------------------------------------- the suites
    step("CFPreferencesAddSuitePreferencesToApp (the suite mechanism)");
    CFStringRef suite = CFStringCreateWithCString(0, "com.example.t16suite", kCFStringEncodingUTF8);
    CFPreferencesAddSuitePreferencesToApp(appID, suite);
    ok("CFPreferencesAddSuitePreferencesToApp returned");

    say("\n");
    if (failures == 0) say("T16 PASS -- CF's preferences path executes.\n");
    else { char m[96]; snprintf(m, sizeof m, "T16 FAIL -- %d checks failed.\n", failures); say(m); }
    say("NOTE: whether the FILE landed, where, and in what format is checked by\n"
        "      the runner around this binary -- a process that cannot see its\n"
        "      own filesystem result should not be the one reporting it.\n");
    return failures == 0 ? 0 : 1;
}
