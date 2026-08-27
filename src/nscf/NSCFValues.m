/* __NSCFNumber, __NSCFBoolean, __NSCFData, __NSCFDate — the value-type bridges.
 *
 * Same constraint as the rest (docs/NSCF_DESIGN.md): IVAR-LESS, and `self` IS
 * the CF object.
 *
 * TWO OF THESE ARE ATTESTED IN COREFOUNDATION'S OWN SOURCE, which no other
 * class in this surface is. CFNumber.c initialises its static objects with
 *
 *     INIT_CFRUNTIME_BASE_WITH_CLASS(__NSCFBoolean, _kCFRuntimeIDCFBoolean)
 *     INIT_CFRUNTIME_BASE_WITH_CLASS(__NSCFNumber,  _kCFRuntimeIDCFNumber)
 *
 * so these two names are corelibs' own, not our convention applied to a gap.
 * (The macro expands to NULL in our configuration -- measured, CF_TRIAGE §36 --
 * which is why those statics are consistent with the empty class table today.
 * The NAMES are still evidence.)
 *
 * THE HARVEST BIAS, A THIRD TIME. NSData's harvested selectors are -bytes and
 * -getBytes:range:. -length is ABSENT, exactly as it was for NSString and as
 * -objectAtIndex: was for NSArray. Three independent types, three omissions of
 * the same KIND of selector -- the ones CF sends through a cast to `id`, which
 * clang permits silently so no "method not found" warning is ever emitted. At
 * three instances this is no longer a caveat about the instrument; it is a
 * characterised property of it, and the union-of-two-sources method is the only
 * correct way to read the list.
 */

#import <objc/NSObject.h>
#include <stdint.h>

#import "../../include/CFFoundationTypes.h"
#import "CFTypesMirror.h"

/* CFBase.h's types, mirrored — see NSCFString.m for why, and for the check that
 * CFIndex is `long` for our target rather than `long long`. */

typedef const struct __CFNumber  *CFNumberRef;
typedef const struct __CFBoolean *CFBooleanRef;
typedef const struct __CFData    *CFDataRef;
typedef const struct __CFDate    *CFDateRef;

extern Boolean           CFNumberGetValue(CFNumberRef, CFNumberType, void *);
extern CFNumberType      CFNumberGetType(CFNumberRef);
extern CFComparisonResult CFNumberCompare(CFNumberRef, CFNumberRef, void *);
extern Boolean           CFBooleanGetValue(CFBooleanRef);
extern const uint8_t    *CFDataGetBytePtr(CFDataRef);
extern CFIndex           CFDataGetLength(CFDataRef);
extern void              CFDataGetBytes(CFDataRef, CFRange, uint8_t *);
extern CFAbsoluteTime    CFDateGetAbsoluteTime(CFDateRef);
extern CFComparisonResult CFDateCompare(CFDateRef, CFDateRef, void *);

/* ----------------------------------------------------------------- number -- */

@interface __NSCFNumber : NSObject
@end

@implementation __NSCFNumber

/* CFNumber.c:1195 -- CF asks a foreign NSNumber which CFNumberType it would
 * prefer, to pick a conversion. For one of ours the answer is the CF object's
 * own, so this forwards rather than deciding. */
- (CFNumberType)_cfNumberType {
    return CFNumberGetType((CFNumberRef)self);
}

/* CFNumber.c:1215 */
- (Boolean)_getValue:(void *)value forType:(CFNumberType)type {
    return CFNumberGetValue((CFNumberRef)self, type, value);
}

/* public; measured equivalent */
- (CFComparisonResult)compare:(id)other {
    return CFNumberCompare((CFNumberRef)self, (CFNumberRef)other, NULL);
}

/* CFNumber.c:1226. Not a typo for -compare:: CF calls this when IT is the
 * foreign object and self is the receiver, so the operands are the other way
 * round. Implementing it as compare: with the arguments swapped is the whole
 * content of the method, and getting the direction wrong would invert every
 * ordering silently. */
- (CFComparisonResult)_reverseCompare:(id)other {
    return CFNumberCompare((CFNumberRef)other, (CFNumberRef)self, NULL);
}

@end

/* ---------------------------------------------------------------- boolean -- */

@interface __NSCFBoolean : NSObject
@end

@implementation __NSCFBoolean

/* public; measured equivalent. Declared as returning Boolean in the harvest
 * rather than BOOL, and kept that way -- CF reads it as a C truth value. */
- (Boolean)boolValue {
    return CFBooleanGetValue((CFBooleanRef)self);
}

/* kCFBooleanTrue and kCFBooleanFalse are statics in __DATA that are never
 * deallocated, so refcounting them is a no-op. Same reasoning as
 * __NSCFConstantString: a release path that reached free() would be freeing a
 * section rather than a heap block. */
- (instancetype)retain { return self; }
- (oneway void)release { }
- (instancetype)autorelease { return self; }
- (NSUInteger)retainCount { return (NSUInteger)-1; }

@end

/* ------------------------------------------------------------------- data -- */

@interface __NSCFData : NSObject
@end

@implementation __NSCFData

/* The cluster primitives. -length is here despite being absent from the
 * harvest, for the reason in the file header. */
- (NSUInteger)length {
    return (NSUInteger)CFDataGetLength((CFDataRef)self);
}

/* "no public reference; SPI" in the harvest -- CF calls it on foreign data to
 * get at contiguous bytes. For one of ours CFDataGetBytePtr always succeeds,
 * unlike CFStringGetCharactersPtr which legitimately returns NULL. */
- (const uint8_t *)bytes {
    return CFDataGetBytePtr((CFDataRef)self);
}

/* PUBLIC, UNREVIEWED in CFDerivedMethods.h, but taken anyway: unlike NSString's
 * line/paragraph pair there is no out-parameter whose width could be wrong --
 * a void* buffer and an NSRange, both of which CFDataGetBytes takes directly. */
- (void)getBytes:(void *)buffer range:(NSRange)range {
    CFRange r = { (CFIndex)range.location, (CFIndex)range.length };
    CFDataGetBytes((CFDataRef)self, r, (uint8_t *)buffer);
}

@end

/* ------------------------------------------------------------------- date -- */

@interface __NSCFDate : NSObject
@end

@implementation __NSCFDate

/* public; measured equivalent. The only selector the harvest shows for NSDate,
 * and CF reaches -timeIntervalSinceReferenceDate through the id path, so it is
 * here for the same reason -length is. */
- (CFComparisonResult)compare:(id)other {
    return CFDateCompare((CFDateRef)self, (CFDateRef)other, NULL);
}

- (double)timeIntervalSinceReferenceDate {
    return (double)CFDateGetAbsoluteTime((CFDateRef)self);
}

@end

Class __NSCFNumberClass(void)  { return [__NSCFNumber class]; }
Class __NSCFBooleanClass(void) { return [__NSCFBoolean class]; }
Class __NSCFDataClass(void)    { return [__NSCFData class]; }
Class __NSCFDateClass(void)    { return [__NSCFDate class]; }
