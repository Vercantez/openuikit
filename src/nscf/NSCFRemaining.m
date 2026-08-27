/* The last five: __NSCFBag, __NSCFLocale, __NSCFAttributedString,
 * __NSCFCalendar, NSURL.
 *
 * Same constraint as the rest (docs/NSCF_DESIGN.md): IVAR-LESS, `self` IS the
 * CF object.
 *
 * __NSCFBag IS THE INTERESTING ONE, AND IT HAS NO METHODS AT ALL.
 *
 * The harvest contains ZERO selectors for NSBag -- CF never messages one. That
 * is not an omission: CFBag's three dispatch sites (CFBag.c:250, 258, 266) are
 * `if (CF_IS_OBJC(...)) return 0;` style GUARDS that bail out, not
 * CF_OBJC_FUNCDISPATCHV calls that send. CF asks "is this foreign?" and, if so,
 * declines to touch it.
 *
 * So this class's entire job is to EXIST, so that __CFISAForTypeID returns
 * something for _kCFRuntimeIDCFBag and the predicate answers correctly for CF's
 * own bags. A class with no methods looks like an oversight and is the precise
 * requirement; writing plausible -count/-member: on it would be inventing an
 * interface CF has never asked for, and would be indistinguishable from the
 * real thing until something called it.
 */

#import <objc/NSObject.h>
#import "../../include/NSCFType.h"   /* the shared lifetime base */
#include <stdint.h>

#import "../../include/CFFoundationTypes.h"
#import "CFTypesMirror.h"

typedef const struct __CFBag             *CFBagRef;
typedef const struct __CFLocale          *CFLocaleRef;
typedef const struct __CFAttributedString *CFAttributedStringRef;
typedef const struct __CFCalendar        *CFCalendarRef;
typedef const struct __CFURL             *CFURLRef;
typedef const struct __CFString          *CFStringRef;
typedef const struct __CFDictionary      *CFDictionaryRef;
typedef const struct __CFDate            *CFDateRef;
typedef const void                       *CFTypeRef;

extern CFTypeRef   CFLocaleGetValue(CFLocaleRef, CFStringRef);
extern CFStringRef CFLocaleGetIdentifier(CFLocaleRef);
extern CFStringRef CFLocaleCopyDisplayNameForPropertyValue(CFLocaleRef, CFStringRef, CFStringRef);

extern CFStringRef CFAttributedStringGetString(CFAttributedStringRef);

extern CFIndex     CFCalendarGetFirstWeekday(CFCalendarRef);
extern CFIndex     CFCalendarGetMinimumDaysInFirstWeek(CFCalendarRef);
extern CFStringRef CFCalendarGetIdentifier(CFCalendarRef);

extern CFStringRef CFURLGetString(CFURLRef);
extern CFURLRef    CFURLGetBaseURL(CFURLRef);
extern CFStringRef CFURLCopyScheme(CFURLRef);
extern CFStringRef CFURLCopyHostName(CFURLRef);
extern CFStringRef CFURLCopyUserName(CFURLRef);
extern CFStringRef CFURLCopyPassword(CFURLRef);
extern CFStringRef CFURLCopyQueryString(CFURLRef, CFStringRef);
extern CFStringRef CFURLCopyFragment(CFURLRef, CFStringRef);

/* -------------------------------------------------------------------- bag -- */

@interface __NSCFBag : __NSCFType
@end

@implementation __NSCFBag
/* Deliberately empty -- see the file header. CF guards on this type but never
 * messages it, so a method here would answer a question nobody asks. */
@end

/* ----------------------------------------------------------------- locale -- */

@interface __NSCFLocale : __NSCFType
@end

@implementation __NSCFLocale

/* public; measured equivalent */
- (CFTypeRef)objectForKey:(id)key {
    return CFLocaleGetValue((CFLocaleRef)self, (CFStringRef)key);
}

/* no public reference; SPI */
- (CFStringRef)localeIdentifier {
    return CFLocaleGetIdentifier((CFLocaleRef)self);
}

/* CFLocale.c:959. +1 -- the ownership note in NSCFError.m applies. */
- (CFStringRef)_copyDisplayNameForKey:(id)key value:(id)value {
    return CFLocaleCopyDisplayNameForPropertyValue((CFLocaleRef)self,
                                                   (CFStringRef)key,
                                                   (CFStringRef)value);
}

/* CFLocale.c:163 and :168 are a GETTER AND SETTER PAIR for a cached flag CF
 * keeps about a locale -- "does this locale need special case handling". They
 * are NOT implemented, and this is the one place in the surface where the right
 * answer is a stored bit rather than a forward: CF is asking us to remember
 * something on its behalf, and an ivar-less class has nowhere to put it. The
 * CF object has the storage; there is no CFLocale function exposing it.
 *
 * Answering the getter with a constant would be worse than not answering:
 * `false` makes CF redo work forever, `true` makes it skip work it needs. So
 * both are left out until the pair can be backed by the CF object's own bit,
 * which needs a CF-side accessor that does not exist yet. */

@end

/* ------------------------------------------------------ attributed string -- */

@interface __NSCFAttributedString : __NSCFType
@end

@implementation __NSCFAttributedString

/* public; measured equivalent -- and the ONLY one of the five harvested
 * selectors that is implementable today. */
- (CFStringRef)string {
    return CFAttributedStringGetString((CFAttributedStringRef)self);
}

/* The other four -- -attributesAtIndex:effectiveRange:,
 * -attribute:atIndex:effectiveRange:, and their longestEffectiveRange:inRange:
 * variants -- are all marked "not in split", meaning they appeared in NEITHER
 * half of the adjudication, so their signatures have no established provenance.
 * Every one takes an `NSRange *` OUT-PARAMETER, which is the exact case the
 * NSString line/paragraph refusal was about: a wrong out-parameter width is
 * written through a pointer and corrupts the caller's stack rather than failing
 * to compile. Two independent reasons to wait, not one. */

@end

/* --------------------------------------------------------------- calendar -- */

@interface __NSCFCalendar : __NSCFType
@end

@implementation __NSCFCalendar

/* reconciled from (CFIndex) -- both were adjudicated for signedness during the
 * silent-set closure, which is why the cast is explicit. */
- (NSUInteger)firstWeekday {
    return (NSUInteger)CFCalendarGetFirstWeekday((CFCalendarRef)self);
}

- (NSUInteger)minimumDaysInFirstWeek {
    return (NSUInteger)CFCalendarGetMinimumDaysInFirstWeek((CFCalendarRef)self);
}

- (CFStringRef)calendarIdentifier {
    return CFCalendarGetIdentifier((CFCalendarRef)self);
}

/* The four _composeAbsoluteTime:/_decomposeAbsoluteTime:/_addComponents:/
 * _diffComponents: selectors are "not in split" AND take
 * `const unsigned char *` -- which is not really a byte pointer, it is a
 * va_list-style component descriptor CF packs itself. Reconstructing that
 * encoding from a call site would be guessing at a private protocol, and
 * getting it wrong would misread every date computation rather than fail.
 * Left out. */

@end

/* -------------------------------------------------------------------- URL -- */

/* NOT __NSCFURL: the registration table says NSURL, because that is what was
 * OBSERVED on macOS -- CFURLCreateWithString returns an object whose class is
 * NSURL, not __NSCFURL. The __NSCF prefix is a convention, not a rule, and
 * following it here would have been tidier and wrong. */
@interface NSURL : __NSCFType
@end

@implementation NSURL

/* no public reference; SPI */
- (CFStringRef)relativeString { return CFURLGetString((CFURLRef)self); }
- (CFURLRef)baseURL           { return CFURLGetBaseURL((CFURLRef)self); }

/* CFURL.c:1673 -- CF asking a foreign NSURL for its underlying CFURL. For one
 * of ours the answer is self, which is the whole point of the bridge. */
- (CFURLRef)_cfurl { return (CFURLRef)self; }

/* PUBLIC, UNREVIEWED, and taken: each returns a CFStringRef and takes nothing,
 * so there is no out-parameter whose width could be wrong -- the same test that
 * admitted NSError's localized* trio and refused NSAttributedString's four.
 * All are +1; see the ownership note in NSCFError.m. */
- (CFStringRef)scheme   { return CFURLCopyScheme((CFURLRef)self); }
- (CFStringRef)host     { return CFURLCopyHostName((CFURLRef)self); }
- (CFStringRef)user     { return CFURLCopyUserName((CFURLRef)self); }
- (CFStringRef)password { return CFURLCopyPassword((CFURLRef)self); }
- (CFStringRef)query    { return CFURLCopyQueryString((CFURLRef)self, NULL); }
- (CFStringRef)fragment { return CFURLCopyFragment((CFURLRef)self, NULL); }

@end

Class __NSCFBagClass(void)              { return [__NSCFBag class]; }
Class __NSCFLocaleClass(void)           { return [__NSCFLocale class]; }
Class __NSCFAttributedStringClass(void) { return [__NSCFAttributedString class]; }
Class __NSCFCalendarClass(void)         { return [__NSCFCalendar class]; }
Class __NSURLClass(void)                { return [NSURL class]; }
