/* CFFoundationInterfaces.h — the Foundation METHOD surface CoreFoundation messages.
 *
 * Step 2 of #51, and the first increment of it. `@class` forward declarations
 * are NOT sufficient: an unknown method's return type defaults to `id`, and
 * clang then guesses the message-send ABI. Measured, that produces 78 warnings
 * and 8 HARD ERRORS wherever CF casts the result to a non-pointer —
 * "pointer cannot be cast to type 'CFTimeInterval' (aka 'double')",
 * "used type 'CFRange' where arithmetic or pointer type is required".
 *
 * Those errors are the same defect as the warnings, surfacing where C refuses to
 * look away. A wrong signature here is the posix_spawnattr_t hazard moved from C
 * to Objective-C: the message compiles, the selector matches, objc_msgSend
 * dispatches, and the argument or return register is wrong.
 *
 * HOW EACH SIGNATURE IS ESTABLISHED — the surface splits 86 public / 65 private
 * (docs/cf-census/cf-objc-public-private.txt), and the halves have different
 * sources of truth:
 *
 *   PUBLIC   documented API. Written clean-room here, then VERIFIED against
 *            Apple's headers with scripts/verify_sigs.py. Apple's headers are a
 *            reference to check against, never a source to copy — this
 *            project's clean-room standard, stated in
 *            ~/swiftcore-macho/sdk/foundation/Foundation.h.
 *
 *   PRIVATE  no header exists. But CoreFoundation is the CALLER, and its call
 *            sites carry the types: CF_OBJC_FUNCDISPATCHV takes the return type
 *            as a macro argument and casts every parameter. So each private
 *            signature below cites the call site it was read from, which is a
 *            stronger source than a header would be — it is the code that has
 *            to agree.
 *
 * Incremental by design. This covers the four files that the type header alone
 * could not unblock; the set grows as the harvest loop runs (docs/CF_TRIAGE.md
 * §24). Every addition cites its evidence.
 */
#ifndef _CF_FOUNDATION_INTERFACES_H
#define _CF_FOUNDATION_INTERFACES_H

#if defined(__OBJC__)

#include <objc/NSObject.h>
#include "CFFoundationTypes.h"

/* SELF-CONTAINED ON PURPOSE. An earlier version of this header assumed CF's own
 * headers would already be included by the time it was reached, and said so in
 * a comment instead of checking. It is FORCE-included (-include), so it lands
 * before everything, and CFRange / CFTimeInterval / CFStreamError did not exist
 * yet: all 86 files failed with "expected a type". That was the fourth total
 * census wipeout tonight caused by a header assumption I asserted rather than
 * verified -- the others being a duplicate mach_port_context_t typedef, a
 * duplicate div_t, and an include path that shadowed the sysroot.
 *
 * So: include what is needed, do not assume ordering. */
#include "CFBase.h"     /* CFRange, CFTimeInterval, CFIndex */
#include "CFStream.h"   /* CFStreamError */

/* ---- NSDate --------------------------------------------------------------
 * PUBLIC. Verified against Apple's NSDate.h:
 *   @property (readonly) NSTimeInterval timeIntervalSinceReferenceDate;
 *   - (NSTimeInterval)timeIntervalSinceDate:(NSDate *)anotherDate;
 * NSTimeInterval and CFTimeInterval are both double, which is why CF's
 * CF_OBJC_FUNCDISPATCHV(..., CFTimeInterval, ...) cast is well-formed once the
 * real return type is known — and ill-formed when it defaults to id.
 * Call sites: CFDate.c:199, CFDate.c:205. */
@interface NSDate : NSObject
- (double)timeIntervalSinceReferenceDate;
- (double)timeIntervalSinceDate:(NSDate *)anotherDate;
@end

/* ---- NSCalendar ----------------------------------------------------------
 * PRIVATE SPI — absent from Apple's public headers. Signatures read directly
 * from CF's call sites, which spell out every type:
 *   CFCalendar.c:1071  CF_OBJC_FUNCDISPATCHV(..., CFRange, (NSCalendar *)calendar,
 *                        _minimumRangeOfUnit:(NSCalendarUnit)unit)
 *   CFCalendar.c:1124  ... _maximumRangeOfUnit:(NSCalendarUnit)unit
 *   CFCalendar.c:2996  ... _rangeOfUnit:(NSCalendarUnit)smallerUnit
 *                            inUnit:(NSCalendarUnit)biggerUnit forAT:at
 * `at` is a CFAbsoluteTime in the enclosing function; CFAbsoluteTime is
 * CFTimeInterval is double. */
@interface NSCalendar : NSObject
- (CFRange)_minimumRangeOfUnit:(NSCalendarUnit)unit;
- (CFRange)_maximumRangeOfUnit:(NSCalendarUnit)unit;
- (CFRange)_rangeOfUnit:(NSCalendarUnit)smallerUnit
                 inUnit:(NSCalendarUnit)biggerUnit
                  forAT:(double)at;
@end

/* ---- NSInputStream / NSOutputStream --------------------------------------
 * PRIVATE SPI. CFStream.c:899 and :904 both request a CFStreamError BY VALUE:
 *   CF_OBJC_FUNCDISPATCHV(..., CFStreamError, (NSInputStream *)stream, _cfStreamError)
 * CFStreamError is a struct, so this is a struct-return message — precisely the
 * case where guessing `id` produces the wrong ABI rather than a wrong value,
 * because struct returns use a different objc_msgSend variant. */
@interface NSInputStream : NSObject
- (CFStreamError)_cfStreamError;
@end

@interface NSOutputStream : NSObject
- (CFStreamError)_cfStreamError;
@end

/* ---- NSString ------------------------------------------------------------
 * PUBLIC. Verified against Apple's NSString.h:109,
 *   @property (readonly) NSUInteger length;
 * Call site CFString.c:1211 assigns the result to a CFIndex, which is why the
 * id default produced "incompatible pointer to integer conversion". */
@interface NSString : NSObject
- (NSUInteger)length;
/* The second cluster primitive. Declared for the same reason as -length: an
 * undeclared selector returns id, and t9_bridge.m casting that to a UniChar
 * produced "cast to smaller integer type from 'id'" -- a warning that IS the
 * defect, not a lint about it. Spelling matches src/nscf/NSCFString.m:73
 * exactly, because a declaration that disagrees with its implementation is
 * worse than none: it silences the warning and keeps the mismatch. */
- (unichar)characterAtIndex:(NSUInteger)index;
@end

/* ---- NSTimeZone ----------------------------------------------------------
 * PRIVATE, both of them -- no header exists, and none is needed, because CF is
 * the caller and its call sites carry the whole signature. Read from
 * CFTimeZone.c rather than invented:
 *
 *   1596  CFTimeInterval CFTimeZoneGetDaylightSavingTimeOffset(
 *                            CFTimeZoneRef tz, CFAbsoluteTime at)
 *   1597    CF_OBJC_FUNCDISPATCHV(..., CFTimeInterval, (NSTimeZone *)tz,
 *                                 _daylightSavingTimeOffsetForAbsoluteTime:at)
 *
 * The macro's second argument IS the return type and `at` IS the parameter, so
 * both are established by the code that has to agree with them -- a stronger
 * source than a header would be.
 *
 * CFTimeInterval and CFAbsoluteTime are both double; they are spelled as the CF
 * types to keep the correspondence with the call site visible.
 *
 * The other three NSTimeZone dispatch sites (name, data, localizedName:locale:)
 * return pointer types, so the id default is already right for them, and
 * declaring them would add risk without removing any. */
@interface NSTimeZone : NSObject
- (CFTimeInterval)_daylightSavingTimeOffsetForAbsoluteTime:(CFAbsoluteTime)at;
- (CFTimeInterval)_nextDaylightSavingTimeTransitionAfterAbsoluteTime:(CFAbsoluteTime)at;
@end

/* ---- NSTimer -------------------------------------------------------------
 * PRIVATE. Read from CFRunLoop.c:4599,
 *   CF_OBJC_FUNCDISPATCHV(CFRunLoopTimerGetTypeID(), CFAbsoluteTime,
 *                         (NSTimer *)rlt, _cffireTime)
 * The underscore-prefixed name is Foundation's own bridge accessor -- it exists
 * so CFRunLoopTimerGetNextFireDate can ask an NSTimer for its fire date, and it
 * appears in no public header. The call site is the specification.
 *
 * -timeInterval is the PUBLIC one, verified against Apple's NSTimer.h,
 *   @property (readonly) NSTimeInterval timeInterval;
 * reached from CFRunLoop.c:4679 with the same CFTimeInterval return type.
 * NSTimeInterval and CFTimeInterval are both double. */
@interface NSTimer : NSObject
- (CFAbsoluteTime)_cffireTime;
- (CFTimeInterval)timeInterval;
@end

/* ---- the collection primitives ------------------------------------------
 * Declared for the same reason as -length, and the reason is sharper here:
 * -count returns NSUInteger, and without a declaration the compiler assumes id
 * and a caster gets "cast to smaller integer type from 'id'" -- or, on a
 * 64-bit return, no warning at all and a pointer read as a count.
 *
 * Spellings match src/nscf/NSCFCollections.m exactly (lines 70, 74, 96, 101,
 * 142): -objectForKey: returns `const void *` rather than id there, because CF
 * hands the raw value straight back. A declaration that disagrees with its
 * implementation silences the warning and keeps the mismatch, which is worse
 * than having neither. */
@interface NSArray : NSObject
- (NSUInteger)count;
- (id)objectAtIndex:(NSUInteger)index;
@end

@interface NSDictionary : NSObject
- (NSUInteger)count;
- (const void *)objectForKey:(id)key;
@end

@interface NSSet : NSObject
- (NSUInteger)count;
- (const void *)member:(id)object;
@end

#endif /* __OBJC__ */
#endif /* _CF_FOUNDATION_INTERFACES_H */
