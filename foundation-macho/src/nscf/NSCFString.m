/* __NSCFString — the class CF stamps on every CFString it creates.
 *
 * See docs/NSCF_DESIGN.md for the constraint this obeys: IVAR-LESS, and `self`
 * IS the CFStringRef. Every method here is a forward to the corresponding
 * CFString function, which is the whole point — the object is a CF struct and
 * this class is the isa that makes it answerable to Objective-C.
 *
 * WHY THIS CLASS IS THE ONE THAT TESTS THE ARCHITECTURE, rather than just
 * implementing it: CFString has 46 dispatch sites, more than any other type,
 * and it is where libswiftCore's String bridging bottoms out. The claim behind
 * #51 is that the two consumers meet at the CLASS-CLUSTER PRIMITIVES. Here that
 * claim is checkable rather than asserted, and it holds:
 *
 *   -characterAtIndex:  is a cluster primitive AND appears in CF's own harvest
 *                       (CFString.c:2135). Both consumers, one method.
 *   -length             is a cluster primitive and does NOT appear in the
 *                       harvest — for a KNOWN reason, not a mysterious one.
 *                       The 151 selectors were harvested from clang's
 *                       "instance method not found" warnings, which fire only
 *                       for messages to TYPED pointers. CF sends -length
 *                       through CFTYPE_OBJC_FUNCDISPATCH0, which casts to `id`,
 *                       and clang permits any method on `id` silently. So the
 *                       harvest is a LOWER BOUND with a documented bias, and
 *                       -length's absence from it is evidence about the
 *                       instrument rather than about CF.
 *
 * That is why the method set below is the union of two sources rather than a
 * copy of either.
 */

#import <objc/NSObject.h>
#import "../../include/NSCFType.h"   /* the shared lifetime base */
#include <stdint.h>

#import "../../include/CFFoundationTypes.h"
#import "CFTypesMirror.h"

/* CoreFoundation's own declarations. This file does not link today — CF itself
 * does not link yet — and that is deliberate: an undefined symbol at the link
 * line is a loud failure, whereas a hand-rolled reimplementation of
 * CFStringGetLength would be a silent second source of truth. */
/* CFBase.h's types, mirrored rather than included: this file is compiled
 * standalone today (CF's headers are staged only for the census), and a
 * duplicate typedef of an identical type is legal C. They must match CFBase.h
 * exactly, and CFBase.h declares CFIndex TWICE — `signed long long` under
 * __LLP64__ and `signed long` otherwise. Same width, different type identity,
 * which is the sort of difference that survives a size check and fails an
 * overload or a CFIndex* mismatch.
 *
 * VERIFIED for our target rather than reasoned from the ladder: compiling
 * `_Static_assert(__builtin_types_compatible_p(CFIndex, long))` against CF's
 * real CFBase.h with our flags exits 0. So `long` is right here. */

typedef const struct __CFString *CFStringRef;
extern CFIndex        CFStringGetLength(CFStringRef);
extern UniChar        CFStringGetCharacterAtIndex(CFStringRef, CFIndex);
extern void           CFStringGetCharacters(CFStringRef, CFRange, UniChar *);
extern const UniChar *CFStringGetCharactersPtr(CFStringRef);

#define CFSELF ((CFStringRef)(self))

@interface __NSCFString : __NSCFType
@end

@implementation __NSCFString

/* --- the class-cluster primitives ------------------------------------------
 * Everything NSString derives, it derives from these two. */

- (NSUInteger)length {
    return (NSUInteger)CFStringGetLength(CFSELF);
}

- (unichar)characterAtIndex:(NSUInteger)index {
    return (unichar)CFStringGetCharacterAtIndex(CFSELF, (CFIndex)index);
}

/* --- what CoreFoundation itself sends, from the harvest ---------------------
 * Each cites the call site that proves CF needs it. */

/* CFString.c:2167 */
- (void)getCharacters:(unichar *)buffer range:(NSRange)range {
    CFRange r = { (CFIndex)range.location, (CFIndex)range.length };
    CFStringGetCharacters(CFSELF, r, (UniChar *)buffer);
}

/* CFString.c:2265. Returns NULL when the backing store is not contiguous
 * UTF-16, which is a legitimate answer rather than a failure: CF's callers
 * test it and fall back to -getCharacters:range:. Returning a fabricated
 * pointer to satisfy the signature would turn a fast-path miss into a crash. */
- (const unichar *)_fastCharacterContents {
    return (const unichar *)CFStringGetCharactersPtr(CFSELF);
}

/* --- deliberately NOT implemented -------------------------------------------
 * The harvest also shows CF sending, to NSString:
 *
 *   -_encodingCantBeStoredInEightBitCFString     CFString.c:1271
 *   -_fastestEncodingInCFStringEncoding          CFString.c:4967
 *   -_smallestEncodingInCFStringEncoding         CFString.c:4952
 *   -getLineStart:end:contentsEnd:forRange:      CFString.c:4764
 *   -getParagraphStart:end:contentsEnd:forRange: CFString.c:4769
 *
 * The three encoding methods answer questions about a FOREIGN NSString's
 * internal storage — CF asks them of objects it did not create, to decide how
 * to copy them. For an __NSCFString the answer is a property of the CF object
 * and CF can read it directly, so implementing them here would be answering on
 * behalf of the wrong object.
 *
 * The two line/paragraph methods have direct CF equivalents
 * (CFStringGetLineBounds / CFStringGetParagraphBounds) and are omitted only
 * because their NSRange-out-parameter signatures were reconciled from
 * CF_OBJC_CALLV casts and carry the "PUBLIC, UNREVIEWED" marker in
 * CFDerivedMethods.h. Writing them against an unreviewed signature is how a
 * wrong out-parameter width gets baked in; they wait for the same adjudication
 * the other 52 got.
 *
 * -hash and -isEqual: are absent for the reason given in NSCFConstantString.m:
 * the hash must agree with CFStringHashCString, which libswiftCore resolves by
 * dlsym, and two hash functions that disagree lose dictionary keys.
 */

@end

Class __NSCFStringClass(void) { return [__NSCFString class]; }
