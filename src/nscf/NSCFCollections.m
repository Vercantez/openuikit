/* __NSCFArray, __NSCFDictionary, __NSCFSet — the three collection bridges.
 *
 * Same constraint as the rest (docs/NSCF_DESIGN.md): IVAR-LESS, and `self` IS
 * the CF object. These three are where that stops being a design note and
 * becomes a RUNTIME contract, because libswiftCore's
 * swift_stdlib_connectNSBaseClasses re-parents __SwiftNativeNSArrayBase,
 * __SwiftNativeNSDictionaryBase and __SwiftNativeNSSetBase onto the cluster
 * heads with class_setSuperclass. Changing a superclass under a class that
 * has ivars moves where those ivars live; the contract only holds for
 * ivar-less clusters.
 *
 * THE HARVEST BIAS SHOWS UP AGAIN, IDENTICALLY, AND THAT IS THE POINT.
 * CF's harvested selector list gives NSArray only -count and
 * -getObjects:range:. -objectAtIndex: is ABSENT — exactly as -length was
 * absent for NSString, and for the same reason: the 151 came from clang
 * "instance method not found" warnings, which fire only for messages to TYPED
 * pointers, and CF sends both through casts to `id`. Two independent types
 * showing the same omission of the same KIND of selector is what turns "the
 * harvest is a lower bound with a documented bias" from a caveat into a
 * measured property.
 *
 * So each method set below is again the union of two sources: the class-cluster
 * primitives, and what CF's harvest proves CF sends. Where they overlap —
 * -count on all three, -member: on NSSet, -objectForKey: on NSDictionary — that
 * IS the shared-primitive claim behind #51, holding on its fourth, fifth and
 * sixth type.
 */

#import <objc/NSObject.h>
#include <stdint.h>

#import "../../include/CFFoundationTypes.h"
#import "CFTypesMirror.h"

/* CFBase.h's types, mirrored — see NSCFString.m for why, and for the
 * verification that CFIndex is `long` for our target rather than `long long`. */

typedef const struct __CFArray      *CFArrayRef;
typedef const struct __CFDictionary *CFDictionaryRef;
typedef const struct __CFSet        *CFSetRef;

extern CFIndex     CFArrayGetCount(CFArrayRef);
extern const void *CFArrayGetValueAtIndex(CFArrayRef, CFIndex);
extern void        CFArrayGetValues(CFArrayRef, CFRange, const void **);

extern CFIndex     CFDictionaryGetCount(CFDictionaryRef);
extern const void *CFDictionaryGetValue(CFDictionaryRef, const void *);
extern Boolean     CFDictionaryGetValueIfPresent(CFDictionaryRef, const void *, const void **);
extern Boolean     CFDictionaryContainsKey(CFDictionaryRef, const void *);
extern void        CFDictionaryGetKeysAndValues(CFDictionaryRef, const void **, const void **);
extern void        CFDictionaryApplyFunction(CFDictionaryRef,
                       void (*)(const void *, const void *, void *), void *);

extern CFIndex     CFSetGetCount(CFSetRef);
extern const void *CFSetGetValue(CFSetRef, const void *);
extern Boolean     CFSetGetValueIfPresent(CFSetRef, const void *, const void **);
extern Boolean     CFSetContainsValue(CFSetRef, const void *);
extern void        CFSetGetValues(CFSetRef, const void **);
extern void        CFSetApplyFunction(CFSetRef, void (*)(const void *, void *), void *);

/* ------------------------------------------------------------------ array -- */

@interface __NSCFArray : NSObject
@end

@implementation __NSCFArray

/* Cluster primitives. -objectAtIndex: is here despite its absence from the
 * harvest, for the reason in the file header. */
- (NSUInteger)count {
    return (NSUInteger)CFArrayGetCount((CFArrayRef)self);
}

- (id)objectAtIndex:(NSUInteger)index {
    return (id)CFArrayGetValueAtIndex((CFArrayRef)self, (CFIndex)index);
}

/* Harvested; carries the PUBLIC, UNREVIEWED marker in CFDerivedMethods.h, but
 * unlike NSString's line/paragraph pair the signature here is unambiguous —
 * an id* out-buffer and an NSRange, both of which CF's own CFArrayGetValues
 * takes directly, so there is no out-parameter width to get wrong. */
- (void)getObjects:(id *)objects range:(NSRange)range {
    CFRange r = { (CFIndex)range.location, (CFIndex)range.length };
    CFArrayGetValues((CFArrayRef)self, r, (const void **)objects);
}

@end

/* ------------------------------------------------------------- dictionary -- */

@interface __NSCFDictionary : NSObject
@end

@implementation __NSCFDictionary

- (NSUInteger)count {
    return (NSUInteger)CFDictionaryGetCount((CFDictionaryRef)self);
}

/* public; measured equivalent */
- (const void *)objectForKey:(id)key {
    return CFDictionaryGetValue((CFDictionaryRef)self, (const void *)key);
}

/* CFDictionary.c:244. The double-underscore name is CF's own private spelling,
 * not an invention — CF calls exactly this on foreign dictionaries. */
- (Boolean)__getValue:(id *)value forKey:(id)key {
    return CFDictionaryGetValueIfPresent((CFDictionaryRef)self,
                                         (const void *)key,
                                         (const void **)value);
}

/* CFDictionary.c:229. Returns char rather than BOOL in the harvest; kept as
 * declared, since CF reads the result as a C truth value either way and
 * widening it here would be a silent signature change on a private call. */
- (char)containsKey:(id)key {
    return (char)CFDictionaryContainsKey((CFDictionaryRef)self, (const void *)key);
}

/* CFDictionary.c:286 */
- (void)getObjects:(id *)objects andKeys:(id *)keys {
    CFDictionaryGetKeysAndValues((CFDictionaryRef)self,
                                 (const void **)keys,
                                 (const void **)objects);
}

/* CFDictionary.c:295 */
- (void)__apply:(void (*)(const void *, const void *, void *))applier
        context:(void *)context {
    CFDictionaryApplyFunction((CFDictionaryRef)self, applier, context);
}

@end

/* -------------------------------------------------------------------- set -- */

@interface __NSCFSet : NSObject
@end

@implementation __NSCFSet

- (NSUInteger)count {
    return (NSUInteger)CFSetGetCount((CFSetRef)self);
}

/* The cluster primitive, and public; measured equivalent in the harvest. */
- (const void *)member:(id)object {
    return CFSetGetValue((CFSetRef)self, (const void *)object);
}

/* CFSet.c:226 */
- (Boolean)__getValue:(id *)value forObj:(id)object {
    return CFSetGetValueIfPresent((CFSetRef)self,
                                  (const void *)object,
                                  (const void **)value);
}

- (BOOL)containsObject:(id)object {
    return CFSetContainsValue((CFSetRef)self, (const void *)object) ? YES : NO;
}

/* CFSet.c:241 */
- (void)getObjects:(id *)objects {
    CFSetGetValues((CFSetRef)self, (const void **)objects);
}

/* CFSet.c:249 */
- (void)__applyValues:(void (*)(const void *, void *))applier
              context:(void *)context {
    CFSetApplyFunction((CFSetRef)self, applier, context);
}

@end

/* --- deliberately NOT implemented -------------------------------------------
 * -countForKey: / -countForObject: appear in the harvest for NSDictionary and
 * NSSet. CFDictionary and CFSet are not bags — a key is present once or not at
 * all — so the honest answer is (containsKey ? 1 : 0), and writing that here
 * would encode a bag semantic CF does not have. CFBag is a separate type with
 * its own typeID and its own bridge class. Left out rather than answered
 * plausibly.
 *
 * NSMutableArray's seven mutators are absent because __NSCFArray covers the
 * IMMUTABLE typeID. CFArray's mutable variant shares _kCFRuntimeIDCFArray, so
 * the mutators belong on this class too — but they need CFArrayCreateMutable's
 * storage semantics settled first, and adding a mutator that silently no-ops on
 * an immutable CFArray is worse than not having it.
 *
 * -hash and -isEqual: are absent for the reason given in NSCFConstantString.m.
 */

Class __NSCFArrayClass(void)      { return [__NSCFArray class]; }
Class __NSCFDictionaryClass(void) { return [__NSCFDictionary class]; }
Class __NSCFSetClass(void)        { return [__NSCFSet class]; }
