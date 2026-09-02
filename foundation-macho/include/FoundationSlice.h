/* FoundationSlice.h — the minimal Foundation slice.
 *
 * Declarations for the classes implemented by src/slice/NSSlice.m. This is a
 * SUPERSET of the compile-time-only umbrella in ~/swiftcore-macho/sdk/foundation,
 * and it replaces it in the staged SDK.
 *
 * THE LOAD-BEARING DESIGN CONSTRAINT — why these are class clusters:
 *
 *   libswiftCore's `swift_stdlib_connectNSBaseClasses()` calls
 *   `class_setSuperclass()` to re-parent its own `__SwiftNativeNS*Base` classes
 *   onto NSArray / NSMutableArray / NSDictionary / NSSet / NSString /
 *   NSEnumerator at run time (measured: otool -tV of that symbol). Re-parenting
 *   only preserves the subclass's ivar offsets if the NEW superclass has the
 *   same instance size as the old one (NSObject: isa only, 8 bytes).
 *
 *   So those six classes MUST declare no ivars. That is not a simplification
 *   for the slice — it is why Apple's Foundation makes them class clusters in
 *   the first place. All storage lives in the concrete __NSSlice* subclasses.
 *
 * Nothing here is copied from Apple headers; the declarations are reconstructed
 * from the selector census in docs/DECISION.md §2 and from documented API.
 */
#ifndef _FOUNDATION_SLICE_H
#define _FOUNDATION_SLICE_H

#include <objc/objc.h>
#include <objc/runtime.h>
#include <objc/message.h>
#include <objc/NSObject.h>
#include <objc/NSObjCRuntime.h>

#if defined(__OBJC__)

typedef struct _NSZone NSZone;
typedef unsigned short unichar;
typedef struct _NSRange { NSUInteger location; NSUInteger length; } NSRange;
typedef NSUInteger NSStringEncoding;
typedef unsigned long CFTypeID;
/* Same spelling CoreFoundation uses, so sources that include the real CF
   headers on macOS and this one on Linux compile unchanged. Redundant but
   identical typedefs are legal in C11. */
typedef const void *CFTypeRef;

enum {
  NSASCIIStringEncoding   = 1,
  NSUTF8StringEncoding    = 4,
  NSUnicodeStringEncoding = 10,
  NSUTF16StringEncoding   = NSUnicodeStringEncoding,
};

static inline NSRange NSMakeRange(NSUInteger loc, NSUInteger len) {
  NSRange r; r.location = loc; r.length = len; return r;
}

@protocol NSCopying
- (id)copyWithZone:(NSZone *)zone;
@end
@protocol NSMutableCopying
- (id)mutableCopyWithZone:(NSZone *)zone;
@end

typedef struct {
  unsigned long state;
  id __unsafe_unretained *itemsPtr;
  unsigned long *mutationsPtr;
  unsigned long extra[5];
} NSFastEnumerationState;

@protocol NSFastEnumeration
- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(id __unsafe_unretained [])buffer
                                    count:(NSUInteger)len;
@end

@class NSString, NSArray, NSDictionary, NSSet, NSNumber, NSEnumerator;

/* ---- NSString ------------------------------------------------------------ */
/* NO IVARS. See the header comment.
 *
 * NS_SWIFT_BRIDGED(String) is not decoration: it is what tells ClangImporter
 * that NSString is the ObjC counterpart of the Swift value type String, so
 * `- (BOOL)isEqualToString:(NSString *)` imports as `isEqual(to: String)`
 * exactly as it does on macOS. Without it every bridged parameter in every
 * Foundation signature differs from Apple's, and source written against real
 * Foundation stops compiling. Measured against the macOS oracle.
 *
 * The argument MUST be the fully-qualified Swift name, "Swift.String".
 * Measured: with the bare "String", ClangImporter silently ignores the
 * attribute and the parameter stays NSString — no diagnostic, the signature is
 * just quietly wrong. Apple spells it the same way, in
 * Foundation.framework/Headers/Foundation.apinotes as `SwiftBridge:
 * Swift.String`, rather than in the header at all. */
#if __has_attribute(swift_bridge)
#  define NS_SWIFT_BRIDGED(T) __attribute__((swift_bridge(T)))
#else
#  define NS_SWIFT_BRIDGED(T)
#endif

NS_SWIFT_BRIDGED("Swift.String")
@interface NSString : NSObject <NSCopying, NSFastEnumeration>
@property (readonly) NSUInteger length;
- (unichar)characterAtIndex:(NSUInteger)index;
- (void)getCharacters:(unichar *)buffer range:(NSRange)range;
- (instancetype)initWithBytes:(const void *)bytes
                       length:(NSUInteger)len
                     encoding:(NSStringEncoding)encoding;
- (instancetype)initWithCharacters:(const unichar *)chars length:(NSUInteger)len;
+ (instancetype)stringWithUTF8String:(const char *)cstr;
+ (instancetype)stringWithCharacters:(const unichar *)chars length:(NSUInteger)len;
@property (readonly) const char *UTF8String;
- (BOOL)isEqualToString:(NSString *)other;
- (NSUInteger)lengthOfBytesUsingEncoding:(NSStringEncoding)enc;
- (BOOL)getCString:(char *)buf maxLength:(NSUInteger)max encoding:(NSStringEncoding)enc;
- (const char *)cStringUsingEncoding:(NSStringEncoding)enc;
@end

/* ---- NSArray ------------------------------------------------------------- */
@interface NSArray : NSObject <NSCopying, NSMutableCopying, NSFastEnumeration>
@property (readonly) NSUInteger count;
- (id)objectAtIndex:(NSUInteger)index;
- (id)objectAtIndexedSubscript:(NSUInteger)index;
- (instancetype)initWithObjects:(const id [])objects count:(NSUInteger)count;
- (void)getObjects:(id __unsafe_unretained [])objects range:(NSRange)range;
- (NSEnumerator *)objectEnumerator;
+ (instancetype)arrayWithObjects:(const id [])objects count:(NSUInteger)count;
@end

@interface NSMutableArray : NSArray
- (void)addObject:(id)obj;
- (void)insertObject:(id)obj atIndex:(NSUInteger)index;
- (void)removeObjectAtIndex:(NSUInteger)index;
- (void)removeLastObject;
- (void)removeAllObjects;
- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(id)obj;
- (void)setObject:(id)obj atIndexedSubscript:(NSUInteger)index;
- (void)exchangeObjectAtIndex:(NSUInteger)a withObjectAtIndex:(NSUInteger)b;
+ (instancetype)array;
@end

/* ---- NSDictionary / NSSet / NSEnumerator --------------------------------- */
/* Present mainly so connectNSBaseClasses finds all six classes; the slice
   implements enough to construct and read them. */
@interface NSDictionary : NSObject <NSCopying, NSFastEnumeration>
@property (readonly) NSUInteger count;
- (id)objectForKey:(id)key;
- (NSEnumerator *)keyEnumerator;
- (instancetype)initWithObjects:(const id [])objects
                       forKeys:(const id <NSCopying> [])keys
                         count:(NSUInteger)count;
+ (instancetype)dictionary;
@end

@interface NSSet : NSObject <NSCopying, NSFastEnumeration>
@property (readonly) NSUInteger count;
- (id)member:(id)object;
- (NSEnumerator *)objectEnumerator;
- (instancetype)initWithObjects:(const id [])objects count:(NSUInteger)count;
@end

@interface NSEnumerator : NSObject
- (id)nextObject;
@end

/* ---- NSNumber ------------------------------------------------------------ */
@interface NSNumber : NSObject <NSCopying>
+ (NSNumber *)numberWithInteger:(NSInteger)value;
+ (NSNumber *)numberWithInt:(int)value;
+ (NSNumber *)numberWithLongLong:(long long)value;
+ (NSNumber *)numberWithDouble:(double)value;
+ (NSNumber *)numberWithBool:(BOOL)value;
@property (readonly) NSInteger integerValue;
@property (readonly) int intValue;
@property (readonly) double doubleValue;
@property (readonly) float floatValue;
@property (readonly) long long longLongValue;
@property (readonly) unsigned long long unsignedLongLongValue;
@property (readonly) const char *objCType;
@end

/* ---- unambiguous entry points for the Swift overlay ---------------------- */
/* ClangImporter renames ObjC factory methods and array-typed parameters in ways
 * that are awkward to predict from the Swift side. Plain C functions and one
 * explicitly-named initialiser import 1:1, so the overlay binds to these
 * instead of guessing. */
@interface NSArray (SliceSwiftEntry)
- (instancetype)initWithObjectPointer:(const id *)objects count:(NSUInteger)count;
@end

#if defined(__cplusplus)
extern "C" {
#endif
NSNumber *SliceMakeNumberLongLong(long long value);
NSString *SliceMakeStringUTF8(const char *cstr);
#if defined(__cplusplus)
}
#endif

/* ---- the CoreFoundation surface libswiftCore resolves by dlsym ------------ */
/* Measured: the once-initialiser behind _swift_stdlib_isNSString does
   dlsym(RTLD_DEFAULT, ...) for exactly these four. See docs/DECISION.md §3. */
#if defined(__cplusplus)
extern "C" {
#endif
CFTypeID   CFGetTypeID(const void *cf);
CFTypeID   CFStringGetTypeID(void);
NSUInteger CFStringHashNSString(const void *str);
NSUInteger CFStringHashCString(const unsigned char *bytes, NSInteger len);
#if defined(__cplusplus)
}
#endif

#endif /* __OBJC__ */
#endif /* _FOUNDATION_SLICE_H */
