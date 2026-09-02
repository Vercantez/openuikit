/* CFFoundationTypes.h — the Foundation TYPE surface CoreFoundation needs.
 *
 * Step 1 of #51. CF's Objective-C dispatch call sites do not only name
 * Foundation classes; they name Foundation TYPES — NSRange, NSMakeRange,
 * unichar, NSCalendarUnit, NSStringCompareOptions, NSTimeZoneNameStyle. While
 * the dispatch macros were stubbed to no-ops those were dead text. Live, they
 * must resolve, and 13 files cannot compile without them.
 *
 * This is the compile-time contract that inverts the layering: CF sits BELOW
 * Foundation at link time but must see Foundation's declarations at compile
 * time. That is Apple's arrangement too, because CF and Foundation are
 * co-developed. See docs/CF_TRIAGE.md §24.
 *
 * SCOPE: types only. The method declarations are a separate and larger job —
 * @class forward declarations are NOT sufficient there, because an unknown
 * method's return type defaults to `id` and clang then guesses the message-send
 * ABI. Measured: that produces 78 warnings, and 8 HARD ERRORS wherever CF casts
 * the result to a non-pointer ("pointer cannot be cast to type 'CFTimeInterval'
 * (aka 'double')", "used type 'CFStreamError' where arithmetic or pointer type
 * is required"). Those errors are the same defect as the warnings, surfacing
 * where C will not silently allow it.
 *
 * Nothing here is copied from Apple headers; each declaration is reconstructed
 * from the use sites in swift-corelibs-foundation and from documented API.
 */
#ifndef _CF_FOUNDATION_TYPES_H
#define _CF_FOUNDATION_TYPES_H

#include <stdint.h>
#include <stddef.h>

/* NSInteger/NSUInteger are already provided by objc/NSObjCRuntime.h in our
 * sysroot, so they are deliberately NOT redeclared here. Declaring something
 * the sysroot already has has now bitten this project twice — mach_port_context_t
 * took the CF census from 74 passing to zero, and a div_t shim broke all 19
 * libcxxabi files. Check the header that DEFINES a symbol, not the one named
 * after it: Darwin splits its declarations across <_stdlib.h>, <sys/_types/...>
 * and friends, so the obvious header is often the wrong one to grep. */
#include <objc/NSObjCRuntime.h>

typedef unsigned short unichar;

/* NSTimeInterval. Reconciling a signature to Foundation's SPELLING requires
 * Foundation's TYPEDEF -- rewriting `- (CFTimeInterval)timeInterval` to
 * `- (NSTimeInterval)timeInterval` introduced a type name that did not exist
 * and took the census to zero. Same width as CFTimeInterval (both double);
 * the point of the rename is the contract, not the layout. */
typedef double NSTimeInterval;

/* NSStreamStatus. MEASURED as a real difference from CFStreamStatus: CF's is
 * signed, Foundation's unsigned. Same width, so the message send is unchanged;
 * the rename is the contract, and like NSTimeInterval it must EXIST before a
 * signature can be reconciled to it. */
typedef NSUInteger NSStreamStatus;

/* ---- NSRange ------------------------------------------------------------- */
/* 19 call sites reach NSMakeRange, 4 more name NSRange directly. */
typedef struct _NSRange {
    NSUInteger location;
    NSUInteger length;
} NSRange;

typedef NSRange *NSRangePointer;

static inline NSRange NSMakeRange(NSUInteger loc, NSUInteger len) {
    NSRange r;
    r.location = loc;
    r.length = len;
    return r;
}

static inline NSUInteger NSMaxRange(NSRange r)          { return r.location + r.length; }
static inline BOOL NSLocationInRange(NSUInteger l, NSRange r) {
    return (l >= r.location) && (l - r.location < r.length);
}
static inline BOOL NSEqualRanges(NSRange a, NSRange b)  {
    return a.location == b.location && a.length == b.length;
}

/* ---- option / style enumerations ----------------------------------------- */
/* Values match the documented Foundation constants. CF passes these straight
 * through to methods it messages, so the numeric values are ABI, not cosmetic. */

typedef NSUInteger NSStringCompareOptions;
enum {
    NSCaseInsensitiveSearch      = 1,
    NSLiteralSearch              = 2,
    NSBackwardsSearch            = 4,
    NSAnchoredSearch             = 8,
    NSNumericSearch              = 64,
    NSDiacriticInsensitiveSearch = 128,
    NSWidthInsensitiveSearch     = 256,
    NSForcedOrderingSearch       = 512,
    NSRegularExpressionSearch    = 1024,
};

typedef NSUInteger NSCalendarUnit;
enum {
    NSCalendarUnitEra               = (1UL << 1),
    NSCalendarUnitYear              = (1UL << 2),
    NSCalendarUnitMonth             = (1UL << 3),
    NSCalendarUnitDay               = (1UL << 4),
    NSCalendarUnitHour              = (1UL << 5),
    NSCalendarUnitMinute            = (1UL << 6),
    NSCalendarUnitSecond            = (1UL << 7),
    NSCalendarUnitWeekday           = (1UL << 9),
    NSCalendarUnitWeekdayOrdinal    = (1UL << 10),
    NSCalendarUnitQuarter           = (1UL << 11),
    NSCalendarUnitWeekOfMonth       = (1UL << 12),
    NSCalendarUnitWeekOfYear        = (1UL << 13),
    NSCalendarUnitYearForWeekOfYear = (1UL << 14),
    NSCalendarUnitNanosecond        = (1UL << 15),
    NSCalendarUnitCalendar          = (1UL << 20),
    NSCalendarUnitTimeZone          = (1UL << 21),
};

typedef NSUInteger NSTimeZoneNameStyle;
enum {
    NSTimeZoneNameStyleStandard,
    NSTimeZoneNameStyleShortStandard,
    NSTimeZoneNameStyleDaylightSaving,
    NSTimeZoneNameStyleShortDaylightSaving,
    NSTimeZoneNameStyleGeneric,
    NSTimeZoneNameStyleShortGeneric,
};

#endif /* _CF_FOUNDATION_TYPES_H */
