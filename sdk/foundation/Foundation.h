/* Foundation.h — clean-room minimal umbrella.
 *
 * Apple's Foundation.framework headers are Xcode-only and not open source, so
 * this is written from the *measured* surface the Swift 6.2.4 standard library
 * actually reaches: 19 distinct NS identifiers (see docs/BUILD_LOG.md), almost
 * all of them used as opaque `id` or looked up at runtime via
 * objc_lookUpClass(). Nothing here is copied from Apple headers; the
 * declarations are reconstructed from the uses in stdlib/public/{runtime,stubs}
 * and from documented Foundation API.
 *
 * This is a *compile-time* header only. libswiftCore links no Foundation:
 * stdlib/public/core/CMakeLists.txt leaves swift_core_framework_depends empty
 * on Darwin, and every NS class the runtime needs is resolved with
 * objc_lookUpClass at run time.
 */
#ifndef _SWIFTCORE_MACHO_FOUNDATION_H
#define _SWIFTCORE_MACHO_FOUNDATION_H

#include <objc/objc.h>
#include <objc/runtime.h>
#include <objc/message.h>
#include <objc/NSObject.h>
#include <objc/NSObjCRuntime.h>
#include <CoreFoundation/CoreFoundation.h>

#if defined(__OBJC__)

typedef struct _NSZone NSZone;

typedef struct _NSRange { NSUInteger location; NSUInteger length; } NSRange;

typedef NSUInteger NSStringEncoding;
enum {
  NSASCIIStringEncoding     = 1,
  NSUTF8StringEncoding      = 4,
  NSUnicodeStringEncoding   = 10,
  NSUTF16StringEncoding     = NSUnicodeStringEncoding,
  NSUTF32StringEncoding     = 0x8c000100,
};

typedef unsigned short unichar;

@protocol NSCopying
- (id)copyWithZone:(nullable NSZone *)zone;
@end

@protocol NSMutableCopying
- (id)mutableCopyWithZone:(nullable NSZone *)zone;
@end

@protocol NSCoding
- (void)encodeWithCoder:(id)coder;
- (nullable instancetype)initWithCoder:(id)coder;
@end

typedef struct {
  unsigned long state;
  id __unsafe_unretained _Nullable * _Nullable itemsPtr;
  unsigned long * _Nullable mutationsPtr;
  unsigned long extra[5];
} NSFastEnumerationState;

@protocol NSFastEnumeration
- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(id __unsafe_unretained _Nullable [_Nonnull])buffer
                                    count:(NSUInteger)len;
@end

@class NSString, NSArray, NSDictionary, NSError, NSData, NSNumber, NSValue;

@interface NSString : NSObject <NSCopying, NSCoding>
@property (readonly) NSUInteger length;
- (unichar)characterAtIndex:(NSUInteger)index;
- (instancetype)initWithBytes:(const void *)bytes
                       length:(NSUInteger)len
                     encoding:(NSStringEncoding)encoding;
+ (instancetype)stringWithUTF8String:(const char *)nullTerminatedCString;
@property (readonly) const char *UTF8String;
- (BOOL)isEqualToString:(NSString *)aString;
/* SwiftNativeNSXXXBaseARC.m hashes non-ASCII strings by their NFD form. */
@property (readonly) NSString *decomposedStringWithCanonicalMapping;
@property (readonly) NSString *precomposedStringWithCanonicalMapping;
@end

@interface NSArray : NSObject <NSCopying, NSMutableCopying, NSFastEnumeration>
@property (readonly) NSUInteger count;
- (id)objectAtIndex:(NSUInteger)index;
@end

@interface NSDictionary : NSObject <NSCopying, NSMutableCopying, NSFastEnumeration>
@property (readonly) NSUInteger count;
- (nullable id)objectForKey:(id)aKey;
+ (instancetype)dictionary;
@end

@interface NSMutableDictionary : NSDictionary
- (void)setObject:(id)anObject forKey:(id <NSCopying>)aKey;
@end

@interface NSNull : NSObject <NSCopying, NSCoding>
+ (NSNull *)null;
@end

@interface NSError : NSObject <NSCopying, NSCoding>
@property (readonly) NSString *domain;
@property (readonly) NSInteger code;
@property (readonly) NSDictionary *userInfo;
- (instancetype)initWithDomain:(NSString *)domain
                          code:(NSInteger)code
                      userInfo:(nullable NSDictionary *)dict;
@end

@interface NSBundle : NSObject
+ (NSBundle *)mainBundle;
+ (nullable instancetype)bundleWithPath:(NSString *)path;
- (nullable NSDictionary *)infoDictionary;
- (nullable id)objectForInfoDictionaryKey:(NSString *)key;
@end

@interface NSCoder : NSObject
@end

@interface NSProxy <NSObject>
{ Class isa; }
+ (id)alloc;
- (void)forwardInvocation:(id)invocation;
@end

@interface NSObject (NSFoundationAdditions)
- (NSString *)description;
- (nullable NSString *)debugDescription;
@end

#endif /* __OBJC__ */
#endif /* _SWIFTCORE_MACHO_FOUNDATION_H */
