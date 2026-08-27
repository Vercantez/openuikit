/* __NSCFError, __NSCFCharacterSet, __NSCFTimeZone — three more bridges.
 *
 * Same constraint as the rest (docs/NSCF_DESIGN.md): IVAR-LESS, and `self` IS
 * the CF object. Method sets derived from CF's own harvest, each citing the
 * evidence for why CF needs it.
 *
 * A NOTE ON WHAT THE HARVEST'S MARKERS MEAN HERE, because these three use all
 * four of them and the differences change what is safe to write:
 *
 *   "public; measured equivalent"  the selector has a documented Foundation
 *                                  equivalent whose signature was CHECKED on
 *                                  macOS. Safe to implement as declared.
 *   "PUBLIC, UNREVIEWED"           public, but the signature came out of a
 *                                  CF_OBJC_CALLV cast and nobody adjudicated
 *                                  it. Safe only where there is no
 *                                  out-parameter whose width could be wrong.
 *   "no public reference; SPI"     private, so the signature is CF's own and
 *                                  there is nothing to reconcile against.
 *   "CFFile.c:NNNN"                private with the call site named.
 *
 * NSError's three localized* selectors carry UNREVIEWED and are implemented
 * anyway: each returns a CFStringRef and takes nothing, so there is no
 * out-parameter to get wrong -- the same test applied to NSArray's
 * -getObjects:range: and refused for NSString's line/paragraph pair.
 */

#import <objc/NSObject.h>
#import "../../include/NSCFType.h"   /* the shared lifetime base */
#include <stdint.h>

#import "../../include/CFFoundationTypes.h"
#import "CFTypesMirror.h"

typedef const struct __CFError        *CFErrorRef;
typedef const struct __CFCharacterSet *CFCharacterSetRef;
typedef const struct __CFTimeZone     *CFTimeZoneRef;
typedef const struct __CFString       *CFStringRef;
typedef const struct __CFDictionary   *CFDictionaryRef;
typedef const struct __CFData         *CFDataRef;
typedef uint32_t                       UTF32Char;

extern CFStringRef     CFErrorGetDomain(CFErrorRef);
extern CFIndex         CFErrorGetCode(CFErrorRef);
extern CFDictionaryRef CFErrorCopyUserInfo(CFErrorRef);
extern CFStringRef     CFErrorCopyDescription(CFErrorRef);
extern CFStringRef     CFErrorCopyFailureReason(CFErrorRef);
extern CFStringRef     CFErrorCopyRecoverySuggestion(CFErrorRef);

extern Boolean           CFCharacterSetIsLongCharacterMember(CFCharacterSetRef, UTF32Char);
extern Boolean           CFCharacterSetHasMemberInPlane(CFCharacterSetRef, CFIndex);
extern CFCharacterSetRef CFCharacterSetCreateInvertedSet(void *, CFCharacterSetRef);
extern CFDataRef         CFCharacterSetCreateBitmapRepresentation(void *, CFCharacterSetRef);

extern CFStringRef CFTimeZoneGetName(CFTimeZoneRef);
extern CFDataRef   CFTimeZoneGetData(CFTimeZoneRef);

/* ------------------------------------------------------------------ error -- */

@interface __NSCFError : __NSCFType
@end

@implementation __NSCFError

/* public; measured equivalent */
- (CFStringRef)domain { return CFErrorGetDomain((CFErrorRef)self); }
- (CFIndex)code       { return CFErrorGetCode((CFErrorRef)self); }

/* public; measured equivalent. NOTE the ownership mismatch: -userInfo is a
 * NON-copying accessor by Foundation convention, and CFErrorCopyUserInfo
 * returns +1. Returning it directly leaks one reference per call. Left
 * autorelease-less rather than papering over it -- see the note at the bottom
 * of this file, because the same mismatch recurs on every Copy-backed
 * accessor here and needs one answer, not four. */
- (CFDictionaryRef)userInfo { return CFErrorCopyUserInfo((CFErrorRef)self); }

/* PUBLIC, UNREVIEWED -- taken because each returns a CFStringRef and takes
 * nothing, so there is no out-parameter whose width could be wrong. Same
 * ownership caveat as -userInfo. */
- (CFStringRef)localizedDescription {
    return CFErrorCopyDescription((CFErrorRef)self);
}
- (CFStringRef)localizedFailureReason {
    return CFErrorCopyFailureReason((CFErrorRef)self);
}
- (CFStringRef)localizedRecoverySuggestion {
    return CFErrorCopyRecoverySuggestion((CFErrorRef)self);
}

@end

/* ---------------------------------------------------------- character set -- */

@interface __NSCFCharacterSet : __NSCFType
@end

@implementation __NSCFCharacterSet

/* public; measured equivalent */
- (Boolean)longCharacterIsMember:(UTF32Char)c {
    return CFCharacterSetIsLongCharacterMember((CFCharacterSetRef)self, c);
}

/* public; measured equivalent. The harvest types the plane as uint8_t while CF
 * takes CFIndex -- kept as the harvest declares it, since that is what CF's
 * call site passes, and widened at the boundary rather than changing the
 * selector's signature. */
- (Boolean)hasMemberInPlane:(uint8_t)plane {
    return CFCharacterSetHasMemberInPlane((CFCharacterSetRef)self, (CFIndex)plane);
}

/* no public reference; SPI. +1 result, same ownership question as NSError's. */
- (CFCharacterSetRef)invertedSet {
    return CFCharacterSetCreateInvertedSet(NULL, (CFCharacterSetRef)self);
}

/* CFCharacterSet.c:2100. The name says _retained_, so here the +1 IS the
 * contract and CF releases it -- this one is unambiguous where the others are
 * not, which is a good argument for CF's naming convention. */
- (CFDataRef)_retainedBitmapRepresentation {
    return CFCharacterSetCreateBitmapRepresentation(NULL, (CFCharacterSetRef)self);
}

@end

/* -------------------------------------------------------------- time zone -- */

@interface __NSCFTimeZone : __NSCFType
@end

@implementation __NSCFTimeZone

/* public; measured equivalent. Both are Get-not-Copy, so no ownership question
 * arises -- which is why these two are the only accessors in this file that
 * are simply correct. */
- (CFStringRef)name { return CFTimeZoneGetName((CFTimeZoneRef)self); }
- (CFDataRef)data   { return CFTimeZoneGetData((CFTimeZoneRef)self); }

/* -localizedName:locale: is in the harvest and is NOT implemented: it is marked
 * "not in split", meaning it appeared in neither the public nor the private
 * half of the adjudication, so its signature has no established provenance.
 * Writing it would be inventing an interface rather than implementing one. */

@end

/* --- THE OWNERSHIP MISMATCH, STATED ONCE ------------------------------------
 *
 * Four accessors above return the result of a CF *Copy* function through a
 * selector whose Foundation convention is non-owning: -userInfo,
 * -localizedDescription, -localizedFailureReason, -localizedRecoverySuggestion,
 * and -invertedSet. Each therefore leaks one reference per call as written.
 *
 * This is NOT fixed here, deliberately, and the reason is the same one that
 * kept -hash out of __NSCFString: the correct fix is to autorelease, and there
 * is no autorelease pool in this stack yet. A hand-rolled CFRelease before
 * return would be worse than the leak -- it would hand back a freed object,
 * turning a bounded leak into a use-after-free.
 *
 * So this is recorded as a known, bounded defect with a named fix rather than
 * silently wrong code. It is also the first thing in this surface that CANNOT
 * be settled by looking at CF: the answer lives in Foundation's memory
 * conventions, which is our side of the boundary. -- see docs/NSCF_DESIGN.md
 */

Class __NSCFErrorClass(void)        { return [__NSCFError class]; }
Class __NSCFCharacterSetClass(void) { return [__NSCFCharacterSet class]; }
Class __NSCFTimeZoneClass(void)     { return [__NSCFTimeZone class]; }
