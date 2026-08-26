/* NSSlice.m — a minimal Foundation, as Darwin Mach-O arm64, on Linux.
 *
 * Purpose: prove that the Swift <-> ObjC bridging contract libswiftCore
 * expects can be satisfied by a Foundation WE control, on machorun, against
 * Apple's objc4. It is a scoping artefact, not a Foundation: storage is naive
 * (linear search, UTF-16 arrays), there is no CF toll-free layout, no
 * NSCoding, no thread safety.
 *
 * Manual retain/release, not ARC: the class-cluster + class_setSuperclass
 * dance is easier to reason about when every retain is written down.
 *
 * Three things here are load-bearing and none is obvious:
 *
 * 1. The six classes libswiftCore re-parents onto (NSString, NSArray,
 *    NSMutableArray, NSDictionary, NSSet, NSEnumerator) declare NO ivars.
 *    class_setSuperclass preserves the subclass's ivar offsets only if the new
 *    superclass is the same instance size as the old one (NSObject, 8 bytes).
 *    Give NSString a single ivar and Swift's __StringStorage silently reads its
 *    own fields at the wrong offsets.
 *
 * 2. -_cfTypeID is how the stdlib identifies bridged classes. Its
 *    _swift_stdlib_isNSString is CFGetTypeID(obj) == CFStringGetTypeID(), and
 *    our CFGetTypeID dispatches -_cfTypeID to the object. That is exactly the
 *    CFTYPE_OBJC_FUNCDISPATCH0 path corelibs stubs out to a no-op.
 *
 * 3. CFGetTypeID / CFStringGetTypeID / CFStringHashNSString /
 *    CFStringHashCString are resolved by libswiftCore with
 *    dlsym(RTLD_DEFAULT, ...), not by linking. They must be exported from a
 *    loaded image or the stdlib calls a NULL pointer.
 */

#include "FoundationSlice.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

/* CF type IDs, matching swift-corelibs-foundation's CFRuntime_Internal.h so a
 * later real CoreFoundation drops in without renumbering. */
enum {
  kSliceTypeIDString     = 7,
  kSliceTypeIDSet        = 17,
  kSliceTypeIDDictionary = 18,
  kSliceTypeIDArray      = 19,
  kSliceTypeIDNumber     = 22,
  kSliceTypeIDNotAType   = 0,
};

@interface NSObject (SliceCFBridging)
- (CFTypeID)_cfTypeID;
@end

@implementation NSObject (SliceCFBridging)
/* Default for anything that is not a bridged CF type. Apple's Foundation has
 * the same shape: the base answers "not a CF type" and the bridged classes
 * override. Without this, CFGetTypeID on a plain object is an unrecognised
 * selector rather than a clean 0. */
- (CFTypeID)_cfTypeID { return kSliceTypeIDNotAType; }
@end

/* ======================================================================== */
/* NSString                                                                 */
/* ======================================================================== */

@implementation NSString

+ (instancetype)stringWithUTF8String:(const char *)cstr {
  return [[[self alloc] initWithBytes:cstr
                               length:cstr ? strlen(cstr) : 0
                             encoding:NSUTF8StringEncoding] autorelease];
}

+ (instancetype)stringWithCharacters:(const unichar *)chars length:(NSUInteger)len {
  return [[[self alloc] initWithCharacters:chars length:len] autorelease];
}

/* The cluster: allocating the abstract class produces a concrete instance.
 *
 * BOTH +alloc and +allocWithZone: must be overridden. Swift's ClangImporter
 * does not emit +alloc for `NSArray(...)` — it emits objc_allocWithZone, and
 * objc4 only routes that to a custom +allocWithZone:. Overriding just +alloc
 * silently yields an instance of the ABSTRACT class, which then fails its own
 * primitive method with doesNotRecognizeSelector. Measured: that is exactly
 * how `-[NSArray initWithObjects:count:] unrecognized selector` presented. */
+ (id)alloc { return [self allocWithZone:NULL]; }
+ (id)allocWithZone:(NSZone *)zone {
  extern Class __SliceStringConcreteClass(void);
  if (self == [NSString class]) return [__SliceStringConcreteClass() allocWithZone:zone];
  return [super allocWithZone:zone];
}

- (CFTypeID)_cfTypeID { return kSliceTypeIDString; }
- (BOOL)isNSString__ { return YES; }

/* Tagged-pointer small-string fast path.
 *
 * When bridging a short ASCII String, the stdlib sends this to __StringStorage
 * — its own class, which connectNSBaseClasses has re-parented onto us, so the
 * message lands here by inheritance. Apple returns a real tagged-pointer
 * NSTaggedPointerString.
 *
 * Two things measured at the call site
 * (libswiftCore`String._bridgeToObjectiveCImpl+0xd8):
 *
 *     bl   objc_msgSend        ; newTaggedNSStringWithASCIIBytes_:length_:
 *     cbnz x0, <epilogue>      ; non-nil: returned AS THE BRIDGED OBJECT, as-is
 *     ...                      ; nil: _StringGuts.grow(16), then RECURSE
 *
 * 1. The result is not tag-checked. Whatever object we return becomes the
 *    bridged NSString, so an ordinary +1 __NSSliceString is a perfectly valid
 *    answer — we do not need real tagged pointers to be correct.
 *
 * 2. Returning nil is NOT safe here. It sends the stdlib down Apple's
 *    back-deployment path, which grows the small string and calls
 *    _bridgeToObjectiveCImpl again. Measured: that recursion does not
 *    terminate on our stack — `"hi" as NSString` died with SIGSEGV in
 *    swift_unknownObjectRetain on a guard page, while a >15-byte string (which
 *    never enters this path) bridged correctly. Long strings passing while
 *    short ones crashed is what localised it.
 *
 * The method must also EXIST: the stdlib does not check respondsToSelector:,
 * so an absent method is an unrecognised-selector abort.
 *
 * `new` prefix means the caller owns the result, so this returns +1 —
 * deliberately not autoreleased.
 */
+ (id)newTaggedNSStringWithASCIIBytes_:(const char *)bytes
                               length_:(NSUInteger)len {
  return [[NSString alloc] initWithBytes:bytes
                                  length:len
                                encoding:NSASCIIStringEncoding];
}
+ (id)newIndirectTaggedNSStringWithConstantNullTerminatedASCIIBytes_:(const char *)bytes
                                                             length_:(NSUInteger)len { return nil; }

/* Primitives — concrete subclasses override. */
- (NSUInteger)length { [self doesNotRecognizeSelector:_cmd]; return 0; }
- (unichar)characterAtIndex:(NSUInteger)i { [self doesNotRecognizeSelector:_cmd]; return 0; }

- (void)getCharacters:(unichar *)buffer range:(NSRange)range {
  for (NSUInteger i = 0; i < range.length; i++)
    buffer[i] = [self characterAtIndex:range.location + i];
}

- (instancetype)initWithBytes:(const void *)bytes
                       length:(NSUInteger)len
                     encoding:(NSStringEncoding)encoding {
  [self doesNotRecognizeSelector:_cmd];
  return nil;
}
- (instancetype)initWithCharacters:(const unichar *)chars length:(NSUInteger)len {
  [self doesNotRecognizeSelector:_cmd];
  return nil;
}

- (BOOL)isEqualToString:(NSString *)other {
  if (other == self) return YES;
  if (!other) return NO;
  NSUInteger n = [self length];
  if (n != [other length]) return NO;
  for (NSUInteger i = 0; i < n; i++)
    if ([self characterAtIndex:i] != [other characterAtIndex:i]) return NO;
  return YES;
}

- (BOOL)isEqual:(id)obj {
  if (obj == self) return YES;
  if (![obj isKindOfClass:[NSString class]]) return NO;
  return [self isEqualToString:(NSString *)obj];
}

- (NSUInteger)hash { return CFStringHashNSString((__bridge const void *)self); }

- (id)copyWithZone:(NSZone *)zone { return [self retain]; }

- (NSUInteger)lengthOfBytesUsingEncoding:(NSStringEncoding)enc {
  NSUInteger n = [self length];
  if (enc == NSUTF16StringEncoding) return n * 2;
  /* UTF-8 / ASCII */
  NSUInteger bytes = 0;
  for (NSUInteger i = 0; i < n; i++) {
    unichar c = [self characterAtIndex:i];
    if (enc == NSASCIIStringEncoding) { if (c > 127) return 0; bytes += 1; }
    else bytes += (c < 0x80) ? 1 : (c < 0x800) ? 2 : 3;
  }
  return bytes;
}

/* Naive UTF-8 encode; no surrogate-pair handling (the slice's test strings are BMP). */
- (BOOL)getCString:(char *)buf maxLength:(NSUInteger)max encoding:(NSStringEncoding)enc {
  NSUInteger n = [self length], o = 0;
  for (NSUInteger i = 0; i < n; i++) {
    unichar c = [self characterAtIndex:i];
    if (c < 0x80)        { if (o + 2 > max) return NO; buf[o++] = (char)c; }
    else if (c < 0x800)  { if (o + 3 > max) return NO;
                           buf[o++] = (char)(0xC0 | (c >> 6));
                           buf[o++] = (char)(0x80 | (c & 0x3F)); }
    else                 { if (o + 4 > max) return NO;
                           buf[o++] = (char)(0xE0 | (c >> 12));
                           buf[o++] = (char)(0x80 | ((c >> 6) & 0x3F));
                           buf[o++] = (char)(0x80 | (c & 0x3F)); }
  }
  if (o + 1 > max) return NO;
  buf[o] = '\0';
  return YES;
}

- (const char *)cStringUsingEncoding:(NSStringEncoding)enc {
  NSUInteger cap = [self length] * 3 + 1;
  char *buf = (char *)malloc(cap);
  if (![self getCString:buf maxLength:cap encoding:enc]) { free(buf); return NULL; }
  /* Leaked deliberately: matching Foundation's autoreleased-buffer lifetime
     needs an autorelease pool for raw memory, which the slice does not have. */
  return buf;
}

- (const char *)UTF8String { return [self cStringUsingEncoding:NSUTF8StringEncoding]; }

- (NSString *)description { return self; }

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(id __unsafe_unretained [])buffer
                                    count:(NSUInteger)len { return 0; }
@end

/* Concrete UTF-16 string. */
@interface __NSSliceString : NSString {
  unichar   *_chars;
  NSUInteger _len;
}
@end

Class __SliceStringConcreteClass(void) { return [__NSSliceString class]; }

@implementation __NSSliceString

- (instancetype)initWithCharacters:(const unichar *)chars length:(NSUInteger)len {
  self = [super init];
  if (!self) return nil;
  _len = len;
  _chars = (unichar *)malloc((len ? len : 1) * sizeof(unichar));
  if (chars && len) memcpy(_chars, chars, len * sizeof(unichar));
  return self;
}

/* Decode UTF-8 (and ASCII, and UTF-16) into the UTF-16 store. */
- (instancetype)initWithBytes:(const void *)bytes
                       length:(NSUInteger)len
                     encoding:(NSStringEncoding)encoding {
  if (encoding == NSUTF16StringEncoding)
    return [self initWithCharacters:(const unichar *)bytes length:len / 2];

  const unsigned char *b = (const unsigned char *)bytes;
  unichar *tmp = (unichar *)malloc((len ? len : 1) * sizeof(unichar));
  NSUInteger n = 0, i = 0;
  while (i < len) {
    unsigned char c = b[i];
    if (c < 0x80)              { tmp[n++] = c; i += 1; }
    else if ((c & 0xE0) == 0xC0 && i + 1 < len)
                               { tmp[n++] = (unichar)(((c & 0x1F) << 6) | (b[i+1] & 0x3F)); i += 2; }
    else if ((c & 0xF0) == 0xE0 && i + 2 < len)
                               { tmp[n++] = (unichar)(((c & 0x0F) << 12) | ((b[i+1] & 0x3F) << 6) | (b[i+2] & 0x3F)); i += 3; }
    else                       { tmp[n++] = 0xFFFD; i += 1; }
  }
  self = [self initWithCharacters:tmp length:n];
  free(tmp);
  return self;
}

- (NSUInteger)length { return _len; }
- (unichar)characterAtIndex:(NSUInteger)i {
  if (i >= _len) { fprintf(stderr, "NSString index %lu out of range %lu\n",
                           (unsigned long)i, (unsigned long)_len); abort(); }
  return _chars[i];
}
- (void)getCharacters:(unichar *)buffer range:(NSRange)range {
  memcpy(buffer, _chars + range.location, range.length * sizeof(unichar));
}
- (void)dealloc { free(_chars); [super dealloc]; }
@end

/* ======================================================================== */
/* NSArray / NSMutableArray                                                 */
/* ======================================================================== */

@implementation NSArray

+ (id)alloc { return [self allocWithZone:NULL]; }
+ (id)allocWithZone:(NSZone *)zone {
  extern Class __SliceArrayConcreteClass(void);
  if (self == [NSArray class]) return [__SliceArrayConcreteClass() allocWithZone:zone];
  return [super allocWithZone:zone];
}

+ (instancetype)arrayWithObjects:(const id [])objects count:(NSUInteger)count {
  return [[[self alloc] initWithObjects:objects count:count] autorelease];
}

- (CFTypeID)_cfTypeID { return kSliceTypeIDArray; }
- (BOOL)isNSArray__ { return YES; }

- (NSUInteger)count { [self doesNotRecognizeSelector:_cmd]; return 0; }
- (id)objectAtIndex:(NSUInteger)i { [self doesNotRecognizeSelector:_cmd]; return nil; }
- (instancetype)initWithObjects:(const id [])o count:(NSUInteger)c {
  [self doesNotRecognizeSelector:_cmd]; return nil;
}

- (id)objectAtIndexedSubscript:(NSUInteger)i { return [self objectAtIndex:i]; }

- (void)getObjects:(id __unsafe_unretained [])objects range:(NSRange)range {
  for (NSUInteger i = 0; i < range.length; i++)
    objects[i] = [self objectAtIndex:range.location + i];
}

- (id)copyWithZone:(NSZone *)zone { return [self retain]; }

- (id)mutableCopyWithZone:(NSZone *)zone {
  NSUInteger n = [self count];
  id *buf = (id *)malloc((n ? n : 1) * sizeof(id));
  [self getObjects:buf range:NSMakeRange(0, n)];
  id r = [[NSMutableArray alloc] initWithObjects:buf count:n];
  free(buf);
  return r;
}

- (BOOL)isEqual:(id)obj {
  if (obj == self) return YES;
  if (![obj isKindOfClass:[NSArray class]]) return NO;
  NSArray *o = (NSArray *)obj;
  NSUInteger n = [self count];
  if (n != [o count]) return NO;
  for (NSUInteger i = 0; i < n; i++)
    if (![[self objectAtIndex:i] isEqual:[o objectAtIndex:i]]) return NO;
  return YES;
}

- (NSEnumerator *)objectEnumerator {
  extern id __SliceMakeArrayEnumerator(NSArray *);
  return __SliceMakeArrayEnumerator(self);
}

/* Fast enumeration straight out of the backing store is not available on the
 * abstract class, so hand back one object per call via the state buffer. */
- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(id __unsafe_unretained [])buffer
                                    count:(NSUInteger)len {
  NSUInteger n = [self count];
  if (state->state >= n) return 0;
  NSUInteger produced = 0;
  state->itemsPtr = buffer;
  state->mutationsPtr = &state->extra[0];
  while (produced < len && state->state < n)
    buffer[produced++] = [self objectAtIndex:state->state++];
  return produced;
}
@end

@interface __NSSliceArray : NSArray {
@public
  id        *_objs;
  NSUInteger _count;
  NSUInteger _cap;
}
@end

Class __SliceArrayConcreteClass(void) { return [__NSSliceArray class]; }

@implementation __NSSliceArray
- (instancetype)initWithObjects:(const id [])objects count:(NSUInteger)count {
  self = [super init];
  if (!self) return nil;
  _cap = count ? count : 4;
  _objs = (id *)malloc(_cap * sizeof(id));
  _count = count;
  for (NSUInteger i = 0; i < count; i++) _objs[i] = [objects[i] retain];
  return self;
}
- (NSUInteger)count { return _count; }
- (id)objectAtIndex:(NSUInteger)i {
  if (i >= _count) { fprintf(stderr, "NSArray index %lu out of range %lu\n",
                             (unsigned long)i, (unsigned long)_count); abort(); }
  return _objs[i];
}
- (void)dealloc {
  for (NSUInteger i = 0; i < _count; i++) [_objs[i] release];
  free(_objs);
  [super dealloc];
}
@end

@implementation NSMutableArray
+ (id)alloc { return [self allocWithZone:NULL]; }
+ (id)allocWithZone:(NSZone *)zone {
  extern Class __SliceMutableArrayConcreteClass(void);
  if (self == [NSMutableArray class]) return [__SliceMutableArrayConcreteClass() allocWithZone:zone];
  return [super allocWithZone:zone];
}
+ (instancetype)array { return [[[self alloc] initWithObjects:NULL count:0] autorelease]; }
- (void)addObject:(id)obj { [self doesNotRecognizeSelector:_cmd]; }
- (void)insertObject:(id)obj atIndex:(NSUInteger)i { [self doesNotRecognizeSelector:_cmd]; }
- (void)removeObjectAtIndex:(NSUInteger)i { [self doesNotRecognizeSelector:_cmd]; }
- (void)removeLastObject { [self removeObjectAtIndex:[self count] - 1]; }
- (void)removeAllObjects { while ([self count]) [self removeLastObject]; }
- (void)replaceObjectAtIndex:(NSUInteger)i withObject:(id)obj {
  [self removeObjectAtIndex:i]; [self insertObject:obj atIndex:i];
}
- (void)setObject:(id)obj atIndexedSubscript:(NSUInteger)i {
  [self replaceObjectAtIndex:i withObject:obj];
}
- (void)exchangeObjectAtIndex:(NSUInteger)a withObjectAtIndex:(NSUInteger)b {
  id x = [[self objectAtIndex:a] retain];
  [self replaceObjectAtIndex:a withObject:[self objectAtIndex:b]];
  [self replaceObjectAtIndex:b withObject:x];
  [x release];
}
- (id)copyWithZone:(NSZone *)zone {
  NSUInteger n = [self count];
  id *buf = (id *)malloc((n ? n : 1) * sizeof(id));
  [self getObjects:buf range:NSMakeRange(0, n)];
  id r = [[NSArray alloc] initWithObjects:buf count:n];
  free(buf);
  return r;
}
@end

@interface __NSSliceMutableArray : NSMutableArray {
  id        *_objs;
  NSUInteger _count;
  NSUInteger _cap;
}
@end

Class __SliceMutableArrayConcreteClass(void) { return [__NSSliceMutableArray class]; }

@implementation __NSSliceMutableArray
- (instancetype)initWithObjects:(const id [])objects count:(NSUInteger)count {
  self = [super init];
  if (!self) return nil;
  _cap = count > 4 ? count : 4;
  _objs = (id *)malloc(_cap * sizeof(id));
  _count = count;
  for (NSUInteger i = 0; i < count; i++) _objs[i] = [objects[i] retain];
  return self;
}
- (NSUInteger)count { return _count; }
- (id)objectAtIndex:(NSUInteger)i {
  if (i >= _count) { fprintf(stderr, "NSMutableArray index %lu out of range %lu\n",
                             (unsigned long)i, (unsigned long)_count); abort(); }
  return _objs[i];
}
- (void)addObject:(id)obj { [self insertObject:obj atIndex:_count]; }
- (void)insertObject:(id)obj atIndex:(NSUInteger)i {
  if (_count == _cap) { _cap *= 2; _objs = (id *)realloc(_objs, _cap * sizeof(id)); }
  memmove(_objs + i + 1, _objs + i, (_count - i) * sizeof(id));
  _objs[i] = [obj retain];
  _count++;
}
- (void)removeObjectAtIndex:(NSUInteger)i {
  [_objs[i] release];
  memmove(_objs + i, _objs + i + 1, (_count - i - 1) * sizeof(id));
  _count--;
}
- (void)dealloc {
  for (NSUInteger i = 0; i < _count; i++) [_objs[i] release];
  free(_objs);
  [super dealloc];
}
@end

/* ======================================================================== */
/* NSEnumerator                                                             */
/* ======================================================================== */

@implementation NSEnumerator
- (id)nextObject { [self doesNotRecognizeSelector:_cmd]; return nil; }
@end

@interface __NSSliceArrayEnumerator : NSEnumerator {
  NSArray   *_a;
  NSUInteger _i;
}
@end

@implementation __NSSliceArrayEnumerator
- (instancetype)initWithArray:(NSArray *)a { self = [super init]; if (self) { _a = [a retain]; _i = 0; } return self; }
- (id)nextObject { return (_i < [_a count]) ? [_a objectAtIndex:_i++] : nil; }
- (void)dealloc { [_a release]; [super dealloc]; }
@end

id __SliceMakeArrayEnumerator(NSArray *a) {
  return [[[__NSSliceArrayEnumerator alloc] initWithArray:a] autorelease];
}

/* ======================================================================== */
/* NSDictionary / NSSet — linear-probe stubs, enough to construct and read   */
/* ======================================================================== */

@interface __NSSliceDictionary : NSDictionary {
  id        *_keys;
  id        *_vals;
  NSUInteger _count;
}
@end

@implementation NSDictionary
+ (id)alloc { return [self allocWithZone:NULL]; }
+ (id)allocWithZone:(NSZone *)zone {
  if (self == [NSDictionary class]) return [__NSSliceDictionary allocWithZone:zone];
  return [super allocWithZone:zone];
}
+ (instancetype)dictionary { return [[[self alloc] initWithObjects:NULL forKeys:NULL count:0] autorelease]; }
- (CFTypeID)_cfTypeID { return kSliceTypeIDDictionary; }
- (BOOL)isNSDictionary__ { return YES; }
- (NSUInteger)count { [self doesNotRecognizeSelector:_cmd]; return 0; }
- (id)objectForKey:(id)key { [self doesNotRecognizeSelector:_cmd]; return nil; }
- (instancetype)initWithObjects:(const id [])o forKeys:(const id <NSCopying> [])k count:(NSUInteger)c {
  [self doesNotRecognizeSelector:_cmd]; return nil;
}
- (id)copyWithZone:(NSZone *)zone { return [self retain]; }
- (NSEnumerator *)keyEnumerator { [self doesNotRecognizeSelector:_cmd]; return nil; }
- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(id __unsafe_unretained [])buffer
                                    count:(NSUInteger)len { return 0; }
@end

@implementation __NSSliceDictionary
- (instancetype)initWithObjects:(const id [])objects
                        forKeys:(const id <NSCopying> [])keys
                          count:(NSUInteger)count {
  self = [super init];
  if (!self) return nil;
  _count = count;
  _keys = (id *)malloc((count ? count : 1) * sizeof(id));
  _vals = (id *)malloc((count ? count : 1) * sizeof(id));
  for (NSUInteger i = 0; i < count; i++) {
    _keys[i] = [(id)keys[i] copyWithZone:NULL];
    _vals[i] = [objects[i] retain];
  }
  return self;
}
- (NSUInteger)count { return _count; }
- (id)objectForKey:(id)key {
  for (NSUInteger i = 0; i < _count; i++)
    if ([_keys[i] isEqual:key]) return _vals[i];
  return nil;
}
- (NSEnumerator *)keyEnumerator {
  NSArray *ka = [[NSArray alloc] initWithObjects:_keys count:_count];
  NSEnumerator *e = [ka objectEnumerator];
  [ka release];
  return e;
}
- (void)dealloc {
  for (NSUInteger i = 0; i < _count; i++) { [_keys[i] release]; [_vals[i] release]; }
  free(_keys); free(_vals);
  [super dealloc];
}
@end

@interface __NSSliceSet : NSSet { id *_objs; NSUInteger _count; }
@end

@implementation NSSet
+ (id)alloc { return [self allocWithZone:NULL]; }
+ (id)allocWithZone:(NSZone *)zone {
  if (self == [NSSet class]) return [__NSSliceSet allocWithZone:zone];
  return [super allocWithZone:zone];
}
- (CFTypeID)_cfTypeID { return kSliceTypeIDSet; }
- (BOOL)isNSSet__ { return YES; }
- (NSUInteger)count { [self doesNotRecognizeSelector:_cmd]; return 0; }
- (id)member:(id)object { [self doesNotRecognizeSelector:_cmd]; return nil; }
- (instancetype)initWithObjects:(const id [])o count:(NSUInteger)c {
  [self doesNotRecognizeSelector:_cmd]; return nil;
}
- (id)copyWithZone:(NSZone *)zone { return [self retain]; }
- (NSEnumerator *)objectEnumerator { [self doesNotRecognizeSelector:_cmd]; return nil; }
- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(id __unsafe_unretained [])buffer
                                    count:(NSUInteger)len { return 0; }
@end

@implementation __NSSliceSet
- (instancetype)initWithObjects:(const id [])objects count:(NSUInteger)count {
  self = [super init];
  if (!self) return nil;
  _objs = (id *)malloc((count ? count : 1) * sizeof(id));
  _count = 0;
  for (NSUInteger i = 0; i < count; i++)
    if (![self member:objects[i]]) _objs[_count++] = [objects[i] retain];
  return self;
}
- (NSUInteger)count { return _count; }
- (id)member:(id)object {
  for (NSUInteger i = 0; i < _count; i++)
    if ([_objs[i] isEqual:object]) return _objs[i];
  return nil;
}
- (NSEnumerator *)objectEnumerator {
  NSArray *a = [[NSArray alloc] initWithObjects:_objs count:_count];
  NSEnumerator *e = [a objectEnumerator];
  [a release];
  return e;
}
- (void)dealloc {
  for (NSUInteger i = 0; i < _count; i++) [_objs[i] release];
  free(_objs);
  [super dealloc];
}
@end

/* ======================================================================== */
/* NSNumber                                                                 */
/* ======================================================================== */

@interface __NSSliceNumber : NSNumber {
  double _d;
  long long _ll;
  char _type;   /* 'q' integer, 'd' double, 'B' bool */
}
@end

@implementation NSNumber
+ (id)alloc { return [self allocWithZone:NULL]; }
+ (id)allocWithZone:(NSZone *)zone {
  if (self == [NSNumber class]) return [__NSSliceNumber allocWithZone:zone];
  return [super allocWithZone:zone];
}
- (CFTypeID)_cfTypeID { return kSliceTypeIDNumber; }
- (BOOL)isNSNumber__ { return YES; }
- (id)copyWithZone:(NSZone *)zone { return [self retain]; }
+ (NSNumber *)numberWithInteger:(NSInteger)v { return [self numberWithLongLong:(long long)v]; }
+ (NSNumber *)numberWithInt:(int)v          { return [self numberWithLongLong:(long long)v]; }
+ (NSNumber *)numberWithLongLong:(long long)v {
  extern id __SliceMakeNumberLL(long long);
  return __SliceMakeNumberLL(v);
}
+ (NSNumber *)numberWithDouble:(double)v {
  extern id __SliceMakeNumberD(double);
  return __SliceMakeNumberD(v);
}
+ (NSNumber *)numberWithBool:(BOOL)v {
  extern id __SliceMakeNumberB(BOOL);
  return __SliceMakeNumberB(v);
}
- (NSInteger)integerValue { return (NSInteger)[self longLongValue]; }
- (int)intValue          { return (int)[self longLongValue]; }
- (float)floatValue      { return (float)[self doubleValue]; }
- (long long)longLongValue { [self doesNotRecognizeSelector:_cmd]; return 0; }
- (unsigned long long)unsignedLongLongValue { return (unsigned long long)[self longLongValue]; }
- (double)doubleValue    { [self doesNotRecognizeSelector:_cmd]; return 0; }
- (const char *)objCType { [self doesNotRecognizeSelector:_cmd]; return ""; }
@end

@implementation __NSSliceNumber
- (instancetype)initLL:(long long)v { self = [super init]; if (self) { _ll = v; _d = (double)v; _type = 'q'; } return self; }
- (instancetype)initD:(double)v     { self = [super init]; if (self) { _d = v; _ll = (long long)v; _type = 'd'; } return self; }
- (instancetype)initB:(BOOL)v       { self = [super init]; if (self) { _ll = v ? 1 : 0; _d = _ll; _type = 'B'; } return self; }
- (long long)longLongValue { return _ll; }
- (double)doubleValue      { return _d; }
- (const char *)objCType   { return _type == 'd' ? "d" : _type == 'B' ? "c" : "q"; }
- (BOOL)isEqual:(id)obj {
  if (![obj isKindOfClass:[NSNumber class]]) return NO;
  return [(NSNumber *)obj doubleValue] == _d;
}
- (NSUInteger)hash { return (NSUInteger)_ll; }
- (NSString *)description {
  char buf[64];
  if (_type == 'd') snprintf(buf, sizeof buf, "%g", _d);
  else snprintf(buf, sizeof buf, "%lld", _ll);
  return [NSString stringWithUTF8String:buf];
}
@end

id __SliceMakeNumberLL(long long v) { return [[[__NSSliceNumber alloc] initLL:v] autorelease]; }
id __SliceMakeNumberD(double v)     { return [[[__NSSliceNumber alloc] initD:v] autorelease]; }
id __SliceMakeNumberB(BOOL v)       { return [[[__NSSliceNumber alloc] initB:v] autorelease]; }

/* ======================================================================== */
/* Unambiguous entry points for the Swift overlay                           */
/* ======================================================================== */

@implementation NSArray (SliceSwiftEntry)
- (instancetype)initWithObjectPointer:(const id *)objects count:(NSUInteger)count {
  return [self initWithObjects:objects count:count];
}
@end

NSNumber *SliceMakeNumberLongLong(long long value) {
  return [NSNumber numberWithLongLong:value];
}

NSString *SliceMakeStringUTF8(const char *cstr) {
  return [NSString stringWithUTF8String:cstr];
}

/* ======================================================================== */
/* The CoreFoundation surface libswiftCore resolves by dlsym                */
/* ======================================================================== */

CFTypeID CFStringGetTypeID(void) { return kSliceTypeIDString; }

/* This is corelibs' CFTYPE_OBJC_FUNCDISPATCH0(CFTypeID, cf, _cfTypeID) — the
 * macro corelibs stubs to a no-op. Restoring it is the whole toll-free
 * bridging question in one line. */
CFTypeID CFGetTypeID(const void *cf) {
  if (!cf) return kSliceTypeIDNotAType;
  return [(id)cf _cfTypeID];
}

#define kSliceHashLimit 96

NSUInteger CFStringHashCString(const unsigned char *bytes, NSInteger len) {
  /* Apple's __CFStrHashEightBit, reproduced from swift-corelibs-foundation's
   * CFString.c (Apache 2.0). The exact algorithm matters: NSString.hash must
   * agree with whatever else hashes the same string. */
  NSUInteger result = (NSUInteger)len;
  if (len <= kSliceHashLimit) {
    for (NSInteger i = 0; i < len; i++) result = result * 257 + bytes[i];
  } else {
    for (NSInteger i = 0; i < 32; i++)          result = result * 257 + bytes[i];
    for (NSInteger i = (len >> 1) - 16; i < (len >> 1) + 16; i++) result = result * 257 + bytes[i];
    for (NSInteger i = len - 32; i < len; i++)  result = result * 257 + bytes[i];
  }
  return result + (result << (len & 31));
}

NSUInteger CFStringHashNSString(const void *str) {
  /* corelibs' DEPLOYMENT_RUNTIME_OBJC branch of CFStringHashNSString, with
   * CF_OBJC_CALLV expanded to a real objc_msgSend. */
  id s = (id)str;
  NSUInteger len = [s length];
  unichar buffer[kSliceHashLimit];
  NSUInteger bufLen;
  if (len <= kSliceHashLimit) {
    [s getCharacters:buffer range:NSMakeRange(0, len)];
    bufLen = len;
  } else {
    [s getCharacters:buffer            range:NSMakeRange(0, 32)];
    [s getCharacters:buffer + 32       range:NSMakeRange((len >> 1) - 16, 32)];
    [s getCharacters:buffer + 64       range:NSMakeRange(len - 32, 32)];
    bufLen = kSliceHashLimit;
  }
  NSUInteger result = len;
  if (len <= kSliceHashLimit) {
    for (NSUInteger i = 0; i < bufLen; i++) result = result * 257 + buffer[i];
  } else {
    for (NSUInteger i = 0; i < bufLen; i++) result = result * 257 + buffer[i];
  }
  return result + (result << (len & 31));
}
