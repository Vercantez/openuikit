/* CFPreferencesMinimal.h -- the exact CoreFoundation surface UserDefaults uses,
 * declared here so the guest build does NOT import Apple's CoreFoundation
 * Swift overlay.
 *
 * WHY NOT `import CoreFoundation`. Measured 2026-08-28 while composing the two
 * halves of Foundation: the FE sysroot already carries Apple's
 * CoreFoundation.swiftmodule, so `import CoreFoundation` resolves to APPLE'S
 * overlay -- built for arm64e-apple-macos26.1, with `-module-link-name
 * swiftCoreFoundation` -- and then fails building its Objective-C module
 * because the toolchain's own CoreFoundation.h wants headers that sysroot does
 * not have.
 *
 * The header chase is the wrong fix. Satisfying it would bind the guest to
 * APPLE'S CoreFoundation overlay while it LINKS OURS: a Swift module and a
 * dylib that only agree by coincidence of name. That is the shadowing family
 * again, one level up -- two CoreFoundations, every symbol resolving, and the
 * wrong one deciding what the compiler believes.
 *
 * So the port names its dependency instead. The whole surface is SIX functions
 * and FOUR constants, measured from swift-corelibs-foundation's UserDefaults
 * (its only CF references), plus the CF types they need. Declaring them makes
 * the dependency visible in one file rather than implied by an import, and it
 * is the same discipline tests/t16_cfprefs.m already follows.
 *
 * THE TYPES ARE OPAQUE ON PURPOSE. Swift sees FMCFStringRef and friends as
 * OpaquePointer-shaped; nothing here dereferences them, and the port passes
 * them straight back to CF. Giving them real layouts would be inventing an ABI
 * we do not own.
 */

/* THE TYPE NAMES ARE FM-PREFIXED, AND THAT IS NOT COSMETIC.
 *
 * Measured 2026-08-28: naming a typedef `CFStringRef` here made Swift's
 * importer report "'CFStringRef' has been renamed to 'CFString' -- obsoleted
 * in Swift 3", in a header that never imports Apple's CoreFoundation. Apple's
 * API NOTES rename CF types BY NAME, so any header reusing those names
 * inherits the rename. That is the fifth-artifact-class hazard: the headers
 * are right, the module is right, and an apinotes file nobody listed decides
 * what Swift sees.
 *
 * Distinct names sidestep it, and they carry the design: every use site now
 * says FMCFStringRef, which cannot be mistaken for Apple's CoreFoundation in
 * a build that deliberately does not import it.
 */
#ifndef FM_CF_PREFERENCES_MINIMAL_H
#define FM_CF_PREFERENCES_MINIMAL_H

#include <stdint.h>

typedef const void *FMCFTypeRef;
typedef const struct __CFString *FMCFStringRef;
typedef const struct __CFArray *FMCFArrayRef;
typedef const struct __CFDictionary *FMCFDictionaryRef;
typedef const struct __CFAllocator *FMCFAllocatorRef;
typedef signed long FMCFIndex;
typedef unsigned long FMCFTypeID;
typedef unsigned long FMCFHashCode;
typedef unsigned char CFBoolean_t;      /* CF's Boolean; one byte, not Swift Bool */
typedef uint32_t FMCFStringEncoding;

/* Lifetime and identity -- the port retains nothing, but CF's Copy functions
 * return +1 and the caller must release. */
extern void      CFRelease(FMCFTypeRef cf);
extern FMCFTypeRef CFRetain(FMCFTypeRef cf);
extern FMCFTypeID  CFGetTypeID(FMCFTypeRef cf);
extern FMCFTypeID  CFStringGetTypeID(void);
extern FMCFTypeID  CFNumberGetTypeID(void);
extern FMCFTypeID  CFBooleanGetTypeID(void);
extern FMCFTypeID  CFArrayGetTypeID(void);
extern FMCFTypeID  CFDictionaryGetTypeID(void);
extern FMCFTypeID  CFDataGetTypeID(void);
extern FMCFTypeID  CFDateGetTypeID(void);

/* Strings, for keys and values. */
extern FMCFStringRef CFStringCreateWithBytes(FMCFAllocatorRef alloc,
                                           const uint8_t *bytes, FMCFIndex len,
                                           FMCFStringEncoding enc,
                                           CFBoolean_t isExternalRepresentation);
extern FMCFIndex      CFStringGetLength(FMCFStringRef s);
extern CFBoolean_t  CFStringGetCString(FMCFStringRef s, char *buf, FMCFIndex size,
                                       FMCFStringEncoding enc);

/* Numbers and booleans, for the value types the bridge marshals. CFBoolean is
 * a DISTINCT type from CFNumber in CF, and conflating them is the NSNumber
 * folding hazard at the C level: a CFNumber holding 1 and kCFBooleanTrue are
 * different objects with different type IDs, and a plist round-trip that loses
 * the difference turns `true` into `1`. */
typedef const struct __CFBoolean *FMCFBooleanRef;
typedef const struct __CFNumber  *FMCFNumberRef;
extern const FMCFBooleanRef kCFBooleanTrue;
extern const FMCFBooleanRef kCFBooleanFalse;
extern CFBoolean_t CFBooleanGetValue(FMCFBooleanRef b);
extern FMCFNumberRef CFNumberCreate(FMCFAllocatorRef alloc, FMCFIndex theType, const void *valuePtr);
extern CFBoolean_t CFNumberGetValue(FMCFNumberRef n, FMCFIndex theType, void *valuePtr);
extern CFBoolean_t CFNumberIsFloatType(FMCFNumberRef n);
/* CFNumberType values, from CFNumber.h. Named rather than spelled as bare
 * integers at the call sites, because a wrong one silently reinterprets the
 * bytes rather than failing. */
#define kCFNumberSInt64Type 4
#define kCFNumberFloat64Type 6

/* THE SIX. swift-corelibs-foundation's UserDefaults.swift references exactly
 * these and nothing else from CF (measured: its only CFPreferences* call
 * sites). CopyKeyList is the seventh and is ours, not upstream's -- upstream
 * calls CFPreferencesCopyMultiple with a NULL key list, which returns the
 * whole domain; we pass an explicit list so the enumeration is visible. */
extern FMCFTypeRef       CFPreferencesCopyAppValue(FMCFStringRef key, FMCFStringRef appID);
extern void            CFPreferencesSetAppValue(FMCFStringRef key, FMCFTypeRef value,
                                                FMCFStringRef appID);
extern CFBoolean_t     CFPreferencesAppSynchronize(FMCFStringRef appID);
extern void            CFPreferencesAddSuitePreferencesToApp(FMCFStringRef appID,
                                                             FMCFStringRef suite);
extern void            CFPreferencesRemoveSuitePreferencesFromApp(FMCFStringRef appID,
                                                                  FMCFStringRef suite);
extern FMCFArrayRef      CFPreferencesCopyKeyList(FMCFStringRef appID, FMCFStringRef user,
                                                FMCFStringRef host);
extern FMCFDictionaryRef CFPreferencesCopyMultiple(FMCFArrayRef keys, FMCFStringRef appID,
                                                 FMCFStringRef user, FMCFStringRef host);

/* THE FOUR CONSTANTS. Compared BY POINTER inside CF
 * (CFPreferences.c:175 routes on `userName == kCFPreferencesAnyUser`), so
 * these must be the real symbols and never copies. */
extern const FMCFStringRef kCFPreferencesCurrentApplication;
extern const FMCFStringRef kCFPreferencesCurrentUser;
extern const FMCFStringRef kCFPreferencesAnyUser;
extern const FMCFStringRef kCFPreferencesCurrentHost;
extern const FMCFStringRef kCFPreferencesAnyHost;

#define kCFStringEncodingUTF8 0x08000100

#endif /* FM_CF_PREFERENCES_MINIMAL_H */
