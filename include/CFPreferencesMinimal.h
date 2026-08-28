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
 * THE TYPES ARE OPAQUE ON PURPOSE. Swift sees CFStringRef and friends as
 * OpaquePointer-shaped; nothing here dereferences them, and the port passes
 * them straight back to CF. Giving them real layouts would be inventing an ABI
 * we do not own.
 */

#ifndef FM_CF_PREFERENCES_MINIMAL_H
#define FM_CF_PREFERENCES_MINIMAL_H

#include <stdint.h>

typedef const void *CFTypeRef;
typedef const struct __CFString *CFStringRef;
typedef const struct __CFArray *CFArrayRef;
typedef const struct __CFDictionary *CFDictionaryRef;
typedef const struct __CFAllocator *CFAllocatorRef;
typedef signed long CFIndex;
typedef unsigned long CFTypeID;
typedef unsigned long CFHashCode;
typedef unsigned char CFBoolean_t;      /* CF's Boolean; one byte, not Swift Bool */
typedef uint32_t CFStringEncoding;

/* Lifetime and identity -- the port retains nothing, but CF's Copy functions
 * return +1 and the caller must release. */
extern void      CFRelease(CFTypeRef cf);
extern CFTypeRef CFRetain(CFTypeRef cf);
extern CFTypeID  CFGetTypeID(CFTypeRef cf);
extern CFTypeID  CFStringGetTypeID(void);
extern CFTypeID  CFNumberGetTypeID(void);
extern CFTypeID  CFBooleanGetTypeID(void);
extern CFTypeID  CFArrayGetTypeID(void);
extern CFTypeID  CFDictionaryGetTypeID(void);
extern CFTypeID  CFDataGetTypeID(void);
extern CFTypeID  CFDateGetTypeID(void);

/* Strings, for keys and values. */
extern CFStringRef CFStringCreateWithBytes(CFAllocatorRef alloc,
                                           const uint8_t *bytes, CFIndex len,
                                           CFStringEncoding enc,
                                           CFBoolean_t isExternalRepresentation);
extern CFIndex      CFStringGetLength(CFStringRef s);
extern CFBoolean_t  CFStringGetCString(CFStringRef s, char *buf, CFIndex size,
                                       CFStringEncoding enc);

/* THE SIX. swift-corelibs-foundation's UserDefaults.swift references exactly
 * these and nothing else from CF (measured: its only CFPreferences* call
 * sites). CopyKeyList is the seventh and is ours, not upstream's -- upstream
 * calls CFPreferencesCopyMultiple with a NULL key list, which returns the
 * whole domain; we pass an explicit list so the enumeration is visible. */
extern CFTypeRef       CFPreferencesCopyAppValue(CFStringRef key, CFStringRef appID);
extern void            CFPreferencesSetAppValue(CFStringRef key, CFTypeRef value,
                                                CFStringRef appID);
extern CFBoolean_t     CFPreferencesAppSynchronize(CFStringRef appID);
extern void            CFPreferencesAddSuitePreferencesToApp(CFStringRef appID,
                                                             CFStringRef suite);
extern void            CFPreferencesRemoveSuitePreferencesFromApp(CFStringRef appID,
                                                                  CFStringRef suite);
extern CFArrayRef      CFPreferencesCopyKeyList(CFStringRef appID, CFStringRef user,
                                                CFStringRef host);
extern CFDictionaryRef CFPreferencesCopyMultiple(CFArrayRef keys, CFStringRef appID,
                                                 CFStringRef user, CFStringRef host);

/* THE FOUR CONSTANTS. Compared BY POINTER inside CF
 * (CFPreferences.c:175 routes on `userName == kCFPreferencesAnyUser`), so
 * these must be the real symbols and never copies. */
extern const CFStringRef kCFPreferencesCurrentApplication;
extern const CFStringRef kCFPreferencesCurrentUser;
extern const CFStringRef kCFPreferencesAnyUser;
extern const CFStringRef kCFPreferencesCurrentHost;
extern const CFStringRef kCFPreferencesAnyHost;

#define kCFStringEncodingUTF8 0x08000100

#endif /* FM_CF_PREFERENCES_MINIMAL_H */
