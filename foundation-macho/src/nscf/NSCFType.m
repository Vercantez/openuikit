/* __NSCFType — the one place bridged lifetime is implemented.
 *
 * WHAT THIS FIXES: t10 measured two reference counts on one object. CFRetain
 * bumped CF's count in _cfinfoa; -retain fell through to NSObject's, which uses
 * the Objective-C runtime's own counter. Both were internally consistent and
 * the pair was wrong only where they met — an object retained through ObjC and
 * released through CF is freed with a live reference; the reverse leaks. A
 * use-after-free with no wrong-looking code anywhere near it.
 *
 * ONE SUPERCLASS RATHER THAN SEVENTEEN COPIES. The alternative was three
 * methods duplicated into every bridged class, which is seventeen chances to
 * diverge and seventeen places to fix when CF's contract changes. The classes
 * are already ivar-less and identically shaped — `self` IS the CF object — so
 * they have a common ancestor in everything but name.
 *
 * WHY INSERTING A SUPERCLASS IS SAFE HERE, AND THE EXPIRY CONDITION.
 * libswiftCore's _swift_stdlib_connectNSBaseClasses re-parents six classes at
 * runtime via class_setSuperclass: NSString, NSArray, NSMutableArray,
 * NSDictionary, NSSet, NSEnumerator. Inserting an ancestor under a class it
 * re-parents would be a collision. Measured (tests/t11_hierarchy.m), all 19
 * bridged classes are rooted DIRECTLY at NSObject and none is below any of the
 * six — they are SIBLINGS of those classes, not descendants.
 *
 * THAT IS A DIVERGENCE FROM FOUNDATION AND IT IS THE EXPIRY CONDITION. Real
 * __NSCFString IS a subclass of NSString. The moment anyone re-parents these to
 * match, the collision becomes live and t11_hierarchy.m must be re-run. It is
 * kept runnable for that reason rather than deleted after passing once.
 */
#import <objc/NSObject.h>
#import <objc/runtime.h>

#import "../../include/CFFoundationTypes.h"
#import "../../include/NSCFType.h"

/* CFIndex and CFHashCode are not in CFFoundationTypes.h -- it carries the
 * Foundation-facing types (NSRange, unichar, NSStreamStatus), not CF's own.
 * Mirrored here with the widths CFTypesMirror.h pins, rather than pulling CF's
 * headers into a file that only needs three scalars. */
typedef const void *CFTypeRef;
typedef long        CFIndex;
typedef unsigned long CFHashCode;
typedef unsigned char Boolean;
extern CFTypeRef CFRetain(CFTypeRef cf);
extern void      CFRelease(CFTypeRef cf);
extern CFIndex   CFGetRetainCount(CFTypeRef cf);
extern CFHashCode CFHash(CFTypeRef cf);
extern Boolean   CFEqual(CFTypeRef a, CFTypeRef b);

@implementation __NSCFType

/* THE POINT OF THE CLASS: one counter, CF's.
 *
 * These forward rather than reimplement, so there is no second notion of what
 * the count is. CFRetain returns the object, which is also -retain's contract,
 * so the return value is passed through rather than substituted with self —
 * they are the same pointer today and forwarding keeps them the same pointer if
 * CF ever starts returning something else. */
/* Cast through id, not instancetype: `instancetype` is a contextual RETURN
 * type and is not a valid cast operand -- "use of undeclared identifier
 * 'instancetype'". The declared return type still carries the covariance. */
- (instancetype)retain      { return (id)CFRetain((CFTypeRef)self); }
- (oneway void)release      { CFRelease((CFTypeRef)self); }
- (NSUInteger)retainCount   { return (NSUInteger)CFGetRetainCount((CFTypeRef)self); }

/* -autorelease is DELIBERATELY NOT IMPLEMENTED HERE, and inherits NSObject's.
 *
 * There is no autorelease pool in this runtime. Implementing it as a no-op
 * would silently convert every +1 returned through a non-owning selector into a
 * permanent leak with no record — which is exactly the defect t10 pins on
 * -userInfo, and making it quieter is the opposite of fixing it. Implementing
 * it as -release would be worse: an over-release that frees while the caller
 * still holds the pointer. Left to NSObject so the behaviour is at least the
 * runtime's own, and the leak stays measurable. */

/* -hash AND -isEqual: ARE DELIBERATELY ABSENT, and this is a measured
 * retraction rather than an omission.
 *
 * I added them forwarding to CFHash/CFEqual, reasoning that ObjC-side
 * collection membership should agree with CF's. The result was a HANG:
 * t10 stopped at CFDictionarySetValue and timed out at 90s, exit 124, with no
 * crash and no output -- the worst signature to debug, and it appeared in the
 * same edit that added them.
 *
 * The shape is a dispatch CYCLE. CF's hashing path can reach an object's -hash
 * for a bridged instance, and a -hash that calls CFHash closes the loop. The
 * lifetime methods do not have this problem because CFRetain/CFRelease on an
 * instance whose _cfisa matches its slot take CF's native path and never
 * re-dispatch -- which is exactly the invariant the isa fix restored.
 *
 * NEITHER WAS ASKED FOR. The ruling was retain/release/retainCount; I added two
 * more because they seemed obviously right. Speculative additions to a base
 * class inherited by twenty types is the wrong place to guess, and this one
 * cost a silent hang rather than a loud failure. If ObjC-side equality is
 * needed later it wants its own measurement, not a reflex.
 */

@end
