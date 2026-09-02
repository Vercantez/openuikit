// T20 -- WHERE does CF think preferences go, and WHY?
//
// #86 finding 1: the plist landed in /Library/Preferences (the ANY-USER
// domain) instead of $HOME/Library/Preferences. Setting CFFIXED_USER_HOME did
// not move it, which already killed the obvious explanation once -- so this
// asks CF for each intermediate value rather than inferring the mechanism from
// the final path.
//
// The chain, from CFPreferences.c:170 and CFKnownLocations.c:23:
//
//   _preferencesCreateDirectoryForUserHostSafetyLevel(user, host, level)
//     routes by POINTER IDENTITY on kCFPreferencesAnyUser / kCFPreferencesCurrentUser
//     -> _CFKnownLocationCreatePreferencesURLForUser(user, name)
//          UserAny     -> "/Library/Preferences"
//          UserCurrent -> CFCopyHomeDirectoryURLForUser(NULL) + "/Library/Preferences"
//
// So there are exactly three places it can go wrong, and this prints all
// three: the pointer identity of the constants, what the home lookup returns,
// and what the known-location call produces for each user kind. A probe that
// printed only the last one could not tell a bad home from a bad route.

#import <objc/objc.h>
#include <string.h>

extern long write(int, const void *, unsigned long);
extern int snprintf(char *, unsigned long, const char *, ...);
extern char *getenv(const char *);

typedef const void *CFTypeRef;
typedef const struct __CFString *CFStringRef;
typedef const struct __CFURL *CFURLRef;
typedef const struct __CFAllocator *CFAllocatorRef;
typedef signed long CFIndex;
typedef unsigned char Boolean;
typedef unsigned int CFStringEncoding;

extern Boolean CFStringGetCString(CFStringRef, char *, CFIndex, CFStringEncoding);
extern void CFRelease(CFTypeRef);
extern CFURLRef CFCopyHomeDirectoryURL(void);
extern CFURLRef CFCopyHomeDirectoryURLForUser(CFStringRef);
extern CFStringRef CFURLCopyFileSystemPath(CFURLRef, CFIndex);
extern CFStringRef CFURLGetString(CFURLRef);
extern CFURLRef CFURLCopyAbsoluteURL(CFURLRef);
extern CFURLRef _CFKnownLocationCreatePreferencesURLForUser(CFIndex user, CFStringRef username);
extern const CFStringRef kCFPreferencesCurrentUser;
extern const CFStringRef kCFPreferencesAnyUser;
extern const CFStringRef kCFPreferencesCurrentHost;
extern const CFStringRef kCFPreferencesAnyHost;

#define UTF8 0x08000100
#define POSIX 0
#define USER_ANY 0
#define USER_CURRENT 1
#define USER_BYNAME 2

static void say(const char *s){unsigned long n=0;while(s[n])n++;(void)!write(2,s,n);}
static void sayf(const char *f, const char *a){char b[1024];snprintf(b,sizeof b,f,a);say(b);}

/* RESOLVE BEFORE PRINTING. CFURLCopyFileSystemPath returns only the RELATIVE
 * portion of a relative URL, so a correctly-based URL prints as if it had no
 * base at all -- "Library/Preferences" rather than "/root/Library/Preferences".
 *
 * This is not hypothetical: the first version of this probe printed the
 * relative portion, and the matching Darwin probe did too. On Darwin that
 * nearly turned a display artifact into a conclusion about Apple's CF. Both
 * were fixed the same way, and the fix is the reason the finding survived
 * checking. */
static const char *urlpath(CFURLRef u, char *buf, int n) {
    if (!u) return "(NULL)";
    CFURLRef abs = CFURLCopyAbsoluteURL(u);
    CFStringRef p = CFURLCopyFileSystemPath(abs ? abs : u, POSIX);
    if (!p) { if (abs) CFRelease(abs); return "(no filesystem path)"; }
    if (!CFStringGetCString(p, buf, n, UTF8)) {
        CFRelease(p); if (abs) CFRelease(abs); return "(uncopyable)";
    }
    CFRelease(p);
    if (abs) CFRelease(abs);
    return buf;
}

int main(void) {
    char buf[1024];
    say("\n=== T20: where does CF put preferences, and why? ===\n\n");

    sayf("  $HOME (as the process sees it)        %s\n",
         getenv("HOME") ? getenv("HOME") : "(unset)");
    sayf("  $CFFIXED_USER_HOME                    %s\n",
         getenv("CFFIXED_USER_HOME") ? getenv("CFFIXED_USER_HOME") : "(unset)");

    say("\n--- STEP 1: the home lookup CFKnownLocations depends on\n");
    CFURLRef h1 = CFCopyHomeDirectoryURL();
    sayf("  CFCopyHomeDirectoryURL()              %s\n", urlpath(h1, buf, sizeof buf));
    CFURLRef h2 = CFCopyHomeDirectoryURLForUser(0);
    sayf("  CFCopyHomeDirectoryURLForUser(NULL)   %s\n", urlpath(h2, buf, sizeof buf));

    say("\n--- STEP 2: what the known-location call returns per user kind\n");
    CFURLRef any = _CFKnownLocationCreatePreferencesURLForUser(USER_ANY, 0);
    sayf("  UserAny                               %s\n", urlpath(any, buf, sizeof buf));
    CFURLRef cur = _CFKnownLocationCreatePreferencesURLForUser(USER_CURRENT, 0);
    sayf("  UserCurrent                           %s\n", urlpath(cur, buf, sizeof buf));

    say("\n--- STEP 3: the verdict\n");
    const char *a = urlpath(any, buf, sizeof buf);
    char b2[1024];
    const char *c = urlpath(cur, b2, sizeof b2);
    if (strcmp(a, c) == 0) {
        say("  UserCurrent and UserAny produce THE SAME PATH.\n"
            "  So the routing is fine and the HOME LOOKUP is what fails --\n"
            "  step 1 shows which of the two home calls is wrong.\n");
    } else {
        say("  UserCurrent and UserAny DIFFER, which is correct. If a write\n"
            "  still lands in the Any location, the fault is ABOVE this layer --\n"
            "  the pointer-identity test in\n"
            "  _preferencesCreateDirectoryForUserHostSafetyLevel (step 4).\n");
    }

    /* The pointer-identity test itself. CFPreferences.c:175 compares the
     * CFStringRef by ==, so two distinct-but-equal constants would silently
     * take the `else` branch (UserByName), not UserCurrent. Printing the
     * pointers is the only way to see that. */
    say("\n--- STEP 4: the constants are compared BY POINTER (CFPreferences.c:175)\n");
    snprintf(buf, sizeof buf,
             "  kCFPreferencesCurrentUser  %p\n"
             "  kCFPreferencesAnyUser      %p\n"
             "  kCFPreferencesCurrentHost  %p\n"
             "  kCFPreferencesAnyHost      %p\n",
             (void *)kCFPreferencesCurrentUser, (void *)kCFPreferencesAnyUser,
             (void *)kCFPreferencesCurrentHost, (void *)kCFPreferencesAnyHost);
    say(buf);
    say("  (all four must be distinct and non-NULL; a NULL or a collision here\n"
        "   routes every domain to the wrong place while every call succeeds)\n");

    if (h1) CFRelease(h1);
    if (h2) CFRelease(h2);
    if (any) CFRelease(any);
    if (cur) CFRelease(cur);
    say("\nT20 done -- this probe REPORTS, it does not pass or fail.\n");
    return 0;
}
