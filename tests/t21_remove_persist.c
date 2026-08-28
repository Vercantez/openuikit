/* T21 -- does a removed preference STAY removed across a process boundary?
 *
 * #86 finding 4 was "SetAppValue(key, NULL) does not remove". Fixing finding 3
 * (the absolute-path bug in CFKnownLocations that sent every write to the
 * ANY-USER domain) made T16's in-process remove start passing.
 *
 * THAT IS NOT ENOUGH TO CALL IT FIXED, and this file exists because of the
 * difference. An in-process remove can pass for two different reasons:
 *
 *   REMOVED   the key is gone from the domain and from the file
 *   SHADOWED  the key is gone from the domain CF consults FIRST, while a copy
 *             survives in a lower-priority domain -- or in a file that a fresh
 *             process will read back
 *
 * In one process the two are indistinguishable, because the removal sits in
 * the in-memory domain either way. Only a SECOND process, reading from disk
 * with no memory of the first, can tell them apart. That is the same reason
 * the UserDefaults host oracle proves persistence with a separate process
 * rather than a read-back.
 *
 * Three phases, three processes:
 *
 *   t21 write    set two keys, synchronize, exit
 *   t21 remove   remove ONE of them, synchronize, exit
 *   t21 check    fresh process: the removed key must be ABSENT and the other
 *                must still be PRESENT
 *
 * The surviving key is the control. Without it, a `check` phase that found
 * nothing -- because the file was lost, the domain name changed, or the write
 * never happened -- would report the removal as a success. "Absent" is only
 * evidence when something else is present.
 */

#include <string.h>

extern long write(int, const void *, unsigned long);
extern int snprintf(char *, unsigned long, const char *, ...);

typedef const void *CFTypeRef;
typedef const struct __CFString *CFStringRef;
typedef const struct __CFAllocator *CFAllocatorRef;
typedef signed long CFIndex;
typedef unsigned char Boolean;
typedef unsigned long CFTypeID;
typedef unsigned int CFStringEncoding;

extern CFStringRef CFStringCreateWithCString(CFAllocatorRef, const char *, CFStringEncoding);
extern Boolean CFStringGetCString(CFStringRef, char *, CFIndex, CFStringEncoding);
extern CFTypeID CFGetTypeID(CFTypeRef);
extern CFTypeID CFStringGetTypeID(void);
extern void CFRelease(CFTypeRef);
extern CFTypeRef CFPreferencesCopyAppValue(CFStringRef, CFStringRef);
extern void CFPreferencesSetAppValue(CFStringRef, CFTypeRef, CFStringRef);
extern Boolean CFPreferencesAppSynchronize(CFStringRef);

#define UTF8 0x08000100
#define APPID "com.example.t21remove"
#define K_GO   "t21_removed"     /* the one we delete   */
#define K_STAY "t21_survivor"    /* the control         */

static int fails = 0;
static void say(const char *s){unsigned long n=0;while(s[n])n++;(void)!write(2,s,n);}
static void ok(const char *s){ say("  OK   "); say(s); say("\n"); }
static void bad(const char *s){ say("  FAIL "); say(s); say("\n"); fails++; }

static CFStringRef S(const char *s) { return CFStringCreateWithCString(0, s, UTF8); }

int main(int argc, char **argv) {
    const char *phase = argc > 1 ? argv[1] : "check";
    CFStringRef app = S(APPID), kgo = S(K_GO), kstay = S(K_STAY);
    char buf[256];

    if (!strcmp(phase, "write")) {
        say("\nT21 write: setting both keys, then synchronising.\n");
        CFStringRef v1 = S("gone-soon"), v2 = S("still-here");
        CFPreferencesSetAppValue(kgo, v1, app);
        CFPreferencesSetAppValue(kstay, v2, app);
        if (CFPreferencesAppSynchronize(app)) ok("synchronize returned TRUE");
        else bad("synchronize returned FALSE");
        CFRelease(v1); CFRelease(v2);

    } else if (!strcmp(phase, "remove")) {
        say("\nT21 remove: a FRESH process removes one key and synchronises.\n");
        /* Read first, so the removal is known to act on something that was
         * actually loaded from disk rather than on an empty domain. */
        CFTypeRef pre = CFPreferencesCopyAppValue(kgo, app);
        if (pre) { ok("the key was present before removing it"); CFRelease(pre); }
        else bad("the key was already absent -- nothing was removed, and a "
                 "later 'absent' would prove nothing");
        CFPreferencesSetAppValue(kgo, 0, app);
        if (CFPreferencesAppSynchronize(app)) ok("synchronize returned TRUE");
        else bad("synchronize returned FALSE");

    } else {
        say("\nT21 check: a FRESH process, reading only from disk.\n");

        /* THE CONTROL FIRST. If the survivor is missing, the store is empty or
         * misaddressed and the removed key's absence means nothing. */
        CFTypeRef stay = CFPreferencesCopyAppValue(kstay, app);
        if (!stay) {
            bad("the SURVIVOR key is absent -- the domain is empty or was not "
                "found, so this run cannot distinguish removed from lost");
            say("\nT21 INCONCLUSIVE (not a pass and not a remove failure)\n");
            return 2;
        }
        if (CFGetTypeID(stay) == CFStringGetTypeID()
            && CFStringGetCString((CFStringRef)stay, buf, sizeof buf, UTF8)
            && !strcmp(buf, "still-here")) {
            ok("the survivor key read back from disk with the right value");
        } else {
            bad("the survivor key came back wrong");
        }
        CFRelease(stay);

        CFTypeRef gone = CFPreferencesCopyAppValue(kgo, app);
        if (gone) {
            bad("the REMOVED key is still readable in a fresh process -- it was "
                "SHADOWED in memory, not removed from the store");
            CFRelease(gone);
        } else {
            ok("the removed key is absent in a fresh process -- genuinely removed");
        }
    }

    CFRelease(app); CFRelease(kgo); CFRelease(kstay);
    snprintf(buf, sizeof buf, "\nT21 %s: %s\n", phase, fails ? "FAIL" : "PASS");
    say(buf);
    return fails ? 1 : 0;
}
