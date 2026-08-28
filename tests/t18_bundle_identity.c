/* T18 -- the ruling asked what CFBundle actually reports under machorun,
 * because CFPreferences.c:439-442 resolves kCFPreferencesCurrentApplication
 * through CFBundleGetIdentifier(CFBundleGetMainBundle()) and SILENTLY falls
 * back to _CFProcessNameString(). That decides the plist FILENAME while every
 * in-process read still passes -- the silent-plausible shape. */
typedef const void *CFTypeRef; typedef const struct __CFString *CFStringRef;
typedef const struct __CFBundle *CFBundleRef; typedef signed long CFIndex;
typedef unsigned char Boolean; typedef unsigned long CFTypeID; typedef unsigned int CFStringEncoding;
extern CFBundleRef CFBundleGetMainBundle(void);
extern CFStringRef CFBundleGetIdentifier(CFBundleRef);
extern Boolean CFStringGetCString(CFStringRef, char *, CFIndex, CFStringEncoding);
extern CFTypeID CFGetTypeID(CFTypeRef); extern CFTypeID CFStringGetTypeID(void);
extern long write(int, const void *, unsigned long);
static void say(const char *s){unsigned long n=0;while(s[n])n++;(void)!write(2,s,n);}
int main(void){
  char b[512];
  say("  .. CFBundleGetMainBundle()\n");
  CFBundleRef mb = CFBundleGetMainBundle();
  if (!mb) { say("  RESULT: CFBundleGetMainBundle() == NULL\n"
                 "          -> CFPreferences would fall back to _CFProcessNameString()\n"); return 0; }
  say("  RESULT: CFBundleGetMainBundle() returned non-NULL\n");
  say("  .. CFBundleGetIdentifier()\n");
  CFStringRef id = CFBundleGetIdentifier(mb);
  if (!id) { say("  RESULT: CFBundleGetIdentifier() == NULL\n"
                 "          -> CFPreferences falls back to the PROCESS NAME, so the\n"
                 "             plist lands under the wrong filename and reads still pass\n"); return 0; }
  if (CFGetTypeID(id) != CFStringGetTypeID()) { say("  RESULT: identifier is not a CFString\n"); return 0; }
  if (CFStringGetCString(id, b, sizeof b, 0x08000100)) { say("  RESULT: bundle identifier = "); say(b); say("\n"); }
  else say("  RESULT: identifier present but not copyable\n");
  return 0;
}
