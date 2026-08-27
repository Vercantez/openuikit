/* __NSCFInputStream, __NSCFOutputStream, __NSCFTimer.
 *
 * Same constraint as the rest (docs/NSCF_DESIGN.md): IVAR-LESS, `self` IS the
 * CF object, every method a forward.
 *
 * The two streams are the most symmetric pair in the whole surface -- seven
 * selectors each, six of them the same shape -- which makes the ONE asymmetry
 * worth pointing at rather than smoothing over: -hasBytesAvailable maps to
 * CFReadStreamHasBytesAvailable, but -hasSpaceAvailable maps to
 * CFWriteStreamCanAcceptBytes. Not a naming accident to be normalised; they are
 * genuinely different questions, and a symmetric-looking wrapper that guessed
 * the name would fail to link rather than misbehave, which is the good outcome.
 *
 * TWO SIGNATURES HERE WERE RECONCILED RATHER THAN COPIED, and the reconciliation
 * is the reason to trust them: -streamStatus is declared NSStreamStatus where CF
 * returns CFStreamStatus, and -hasBytesAvailable is BOOL where CF returns
 * Boolean. Both were adjudicated by measuring the widths on macOS (CF_TRIAGE's
 * silent-set closure), not by picking whichever looked tidier. That is why the
 * casts below are explicit: each crosses a checked boundary rather than an
 * assumed one.
 */

#import <objc/NSObject.h>
#import "../../include/NSCFType.h"   /* the shared lifetime base */
#include <stdint.h>

#import "../../include/CFFoundationTypes.h"
#import "CFTypesMirror.h"

typedef const struct __CFReadStream  *CFReadStreamRef;
typedef const struct __CFWriteStream *CFWriteStreamRef;
typedef const struct __CFRunLoopTimer *CFRunLoopTimerRef;
typedef const struct __CFString      *CFStringRef;
typedef const struct __CFError       *CFErrorRef;
typedef const void                   *CFTypeRef;
typedef CFIndex                       CFStreamStatus;
typedef double                        CFTimeInterval;

extern CFIndex        CFReadStreamRead(CFReadStreamRef, uint8_t *, CFIndex);
extern Boolean        CFReadStreamHasBytesAvailable(CFReadStreamRef);
extern CFStreamStatus CFReadStreamGetStatus(CFReadStreamRef);
extern CFErrorRef     CFReadStreamCopyError(CFReadStreamRef);
extern void           CFReadStreamClose(CFReadStreamRef);
extern CFTypeRef      CFReadStreamCopyProperty(CFReadStreamRef, CFStringRef);
extern Boolean        CFReadStreamSetProperty(CFReadStreamRef, CFStringRef, CFTypeRef);

extern CFIndex        CFWriteStreamWrite(CFWriteStreamRef, const uint8_t *, CFIndex);
extern Boolean        CFWriteStreamCanAcceptBytes(CFWriteStreamRef);
extern CFStreamStatus CFWriteStreamGetStatus(CFWriteStreamRef);
extern CFErrorRef     CFWriteStreamCopyError(CFWriteStreamRef);
extern void           CFWriteStreamClose(CFWriteStreamRef);
extern CFTypeRef      CFWriteStreamCopyProperty(CFWriteStreamRef, CFStringRef);
extern Boolean        CFWriteStreamSetProperty(CFWriteStreamRef, CFStringRef, CFTypeRef);

extern Boolean        CFRunLoopTimerIsValid(CFRunLoopTimerRef);
extern CFAbsoluteTime CFRunLoopTimerGetNextFireDate(CFRunLoopTimerRef);
extern CFTimeInterval CFRunLoopTimerGetInterval(CFRunLoopTimerRef);
extern CFTimeInterval CFRunLoopTimerGetTolerance(CFRunLoopTimerRef);
extern void           CFRunLoopTimerInvalidate(CFRunLoopTimerRef);

/* ---------------------------------------------------------- input stream -- */

@interface __NSCFInputStream : __NSCFType
@end

@implementation __NSCFInputStream

/* public; measured equivalent */
- (CFIndex)read:(uint8_t *)buffer maxLength:(NSUInteger)len {
    return CFReadStreamRead((CFReadStreamRef)self, buffer, (CFIndex)len);
}

/* reconciled from (Boolean) -- the selector is BOOL, CF returns Boolean, and
 * the widths were measured rather than assumed equal. */
- (BOOL)hasBytesAvailable {
    return CFReadStreamHasBytesAvailable((CFReadStreamRef)self) ? YES : NO;
}

/* reconciled from (CFStreamStatus) */
- (NSStreamStatus)streamStatus {
    return (NSStreamStatus)CFReadStreamGetStatus((CFReadStreamRef)self);
}

/* no public reference; SPI. +1 result -- see the ownership note in
 * NSCFError.m, which applies unchanged here. */
- (CFErrorRef)streamError {
    return CFReadStreamCopyError((CFReadStreamRef)self);
}

/* CFStream.c:985 */
- (void)close { CFReadStreamClose((CFReadStreamRef)self); }

/* public; measured equivalent. Also +1. */
- (CFTypeRef)propertyForKey:(id)key {
    return CFReadStreamCopyProperty((CFReadStreamRef)self, (CFStringRef)key);
}

- (Boolean)setProperty:(id)value forKey:(id)key {
    return CFReadStreamSetProperty((CFReadStreamRef)self, (CFStringRef)key,
                                   (CFTypeRef)value);
}

@end

/* --------------------------------------------------------- output stream -- */

@interface __NSCFOutputStream : __NSCFType
@end

@implementation __NSCFOutputStream

- (CFIndex)write:(const uint8_t *)buffer maxLength:(NSUInteger)len {
    return CFWriteStreamWrite((CFWriteStreamRef)self, buffer, (CFIndex)len);
}

/* THE ONE ASYMMETRY: -hasSpaceAvailable is CFWriteStreamCanAcceptBytes, not
 * a "HasSpaceAvailable" that does not exist. Different question, different
 * name, and worth not normalising. */
- (BOOL)hasSpaceAvailable {
    return CFWriteStreamCanAcceptBytes((CFWriteStreamRef)self) ? YES : NO;
}

- (NSStreamStatus)streamStatus {
    return (NSStreamStatus)CFWriteStreamGetStatus((CFWriteStreamRef)self);
}

- (CFErrorRef)streamError {
    return CFWriteStreamCopyError((CFWriteStreamRef)self);
}

/* CFStream.c:990 */
- (void)close { CFWriteStreamClose((CFWriteStreamRef)self); }

- (CFTypeRef)propertyForKey:(id)key {
    return CFWriteStreamCopyProperty((CFWriteStreamRef)self, (CFStringRef)key);
}

- (Boolean)setProperty:(id)value forKey:(id)key {
    return CFWriteStreamSetProperty((CFWriteStreamRef)self, (CFStringRef)key,
                                    (CFTypeRef)value);
}

@end

/* ------------------------------------------------------------------ timer -- */

@interface __NSCFTimer : __NSCFType
@end

@implementation __NSCFTimer

/* CFRunLoop.c:4727 */
- (Boolean)isValid { return CFRunLoopTimerIsValid((CFRunLoopTimerRef)self); }

/* CFRunLoop.c:4577. The name is CF's: it asks for the timer's next fire date in
 * CF's absolute-time base, not Foundation's -fireDate. Kept as CF spells it
 * because CF is the only caller. */
- (CFAbsoluteTime)_cffireTime {
    return CFRunLoopTimerGetNextFireDate((CFRunLoopTimerRef)self);
}

/* reconciled from (CFTimeInterval) -- NSTimeInterval and CFTimeInterval are
 * both double, and that equality was MEASURED. Two names for the same width is
 * exactly the case where a mismatch would never surface. */
- (NSTimeInterval)timeInterval {
    return (NSTimeInterval)CFRunLoopTimerGetInterval((CFRunLoopTimerRef)self);
}

- (NSTimeInterval)tolerance {
    return (NSTimeInterval)CFRunLoopTimerGetTolerance((CFRunLoopTimerRef)self);
}

/* CFRunLoop.c:4676 */
- (void)invalidate { CFRunLoopTimerInvalidate((CFRunLoopTimerRef)self); }

@end

Class __NSCFInputStreamClass(void)  { return [__NSCFInputStream class]; }
Class __NSCFOutputStreamClass(void) { return [__NSCFOutputStream class]; }
Class __NSCFTimerClass(void)        { return [__NSCFTimer class]; }
