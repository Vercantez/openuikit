// The Objective-C/C half of the guest's Objective-C Foundation: what Swift
// cannot declare. Variadic methods and the %@ formatter, the NSRange-taking
// selectors, class-factory methods, NSLog, the NSString* constants, the
// constant-string fix-up, and -[NSObject description].
//
// Everything here forwards to the Swift classes and @objc members of
// FoundationObjCBridge (../bridge) and the facade (full/foundation).
// Compiled with ARC.

#import <Foundation/Foundation.h>
#include <objc/message.h>
#include <mach-o/dyld.h>
#include <mach-o/getsect.h>
#include <pthread.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/time.h>
#include <time.h>
#include <unistd.h>

// Swift entry points (../bridge).
extern NSString *OFStringFromUTF8(const char *bytes, long length) NS_RETURNS_RETAINED;
extern char *OFCopyDescriptionUTF8(id _Nullable object);
extern long OFFixConstantStrings(void *records, long count, const void *marker);
extern NSNumber *OFMakeBooleanNumber(BOOL value) NS_RETURNS_RETAINED;

// Selectors the Swift half implements under guest-private names.
@interface NSString (OFBridgePrivate)
- (instancetype)_of_initWithUTF8Bytes:(const char *)bytes length:(NSInteger)length;
- (NSString *)_of_substringWithLocation:(NSUInteger)location length:(NSUInteger)length;
- (void)_of_getCharacters:(unichar *)buffer location:(NSUInteger)location length:(NSUInteger)length;
- (NSUInteger)_of_rangeOfString:(NSString *)target options:(NSStringCompareOptions)options
                       location:(NSUInteger)location length:(NSUInteger)length outLength:(NSUInteger *)outLength;
- (NSString *)_of_stringByReplacingOccurrencesOfString:(NSString *)target withString:(NSString *)replacement
                                               options:(NSStringCompareOptions)options location:(NSUInteger)location length:(NSUInteger)length;
- (NSString *)_of_stringByReplacingCharactersInLocation:(NSUInteger)location length:(NSUInteger)length withString:(NSString *)replacement;
@end

@interface NSMutableString (OFBridgePrivate)
- (void)_of_replaceCharactersInLocation:(NSUInteger)location length:(NSUInteger)length withString:(NSString *)replacement;
- (void)_of_deleteCharactersInLocation:(NSUInteger)location length:(NSUInteger)length;
- (NSUInteger)_of_replaceOccurrencesOfString:(NSString *)target withString:(NSString *)replacement
                                     options:(NSStringCompareOptions)options location:(NSUInteger)location length:(NSUInteger)length;
@end

@interface NSArray (OFBridgePrivate)
- (NSArray *)_of_subarrayWithLocation:(NSUInteger)location length:(NSUInteger)length;
@end

@interface NSData (OFBridgePrivate)
- (void)_of_getBytes:(void *)buffer location:(NSUInteger)location length:(NSUInteger)length;
- (NSData *)_of_subdataWithLocation:(NSUInteger)location length:(NSUInteger)length;
@end

#pragma mark - Constants

NSString *const NSCocoaErrorDomain = @"NSCocoaErrorDomain";
NSString *const NSPOSIXErrorDomain = @"NSPOSIXErrorDomain";
NSString *const NSOSStatusErrorDomain = @"NSOSStatusErrorDomain";
NSString *const NSUnderlyingErrorKey = @"NSUnderlyingError";
NSString *const NSLocalizedDescriptionKey = @"NSLocalizedDescription";
NSString *const NSLocalizedFailureReasonErrorKey = @"NSLocalizedFailureReason";
NSString *const NSLocalizedRecoverySuggestionErrorKey = @"NSLocalizedRecoverySuggestion";
NSString *const NSFilePathErrorKey = @"NSFilePath";
NSString *const NSInternalInconsistencyException = @"NSInternalInconsistencyException";
NSString *const NSInvalidArgumentException = @"NSInvalidArgumentException";
NSString *const NSRangeException = @"NSRangeException";

#pragma mark - Constant strings

// clang lays each @"..." / CFSTR literal down as a 32-byte __cfstring record
// whose isa is this symbol's address. No class lives here: before main, every
// such record in every loaded image is rewritten into a facade NSString
// (FoundationObjCBridge._OFConstantString, OFFixConstantStrings). Images
// dlopen'ed later are not rewritten (a documented limit).
__attribute__((visibility("default"))) uintptr_t __CFConstantStringClassReference[4];

// Constant strings are immortal, as the SDK's are: retain/release are no-ops.
// This is load-bearing, not a nicety -- clang's ARC optimizer drops the retain
// of a value it can see is a constant literal but keeps the matching release
// of a reload (measured: `id keys[] = {@"ky"}` retains nothing and releases
// once), so a counted constant is freed from __DATA.
// void * signatures: under ARC an id return would itself be retained.
static void *of_constant_retain(void *self, SEL _cmd) { return self; }
static void of_constant_release(void *self, SEL _cmd) {}
static void *of_constant_autorelease(void *self, SEL _cmd) { return self; }
static NSUInteger of_constant_retainCount(void *self, SEL _cmd) { return NSUIntegerMax; }
static BOOL of_constant_tryRetain(void *self, SEL _cmd) { return YES; }
static BOOL of_constant_isDeallocating(void *self, SEL _cmd) { return NO; }

static void of_make_immortal(Class cls) {
    class_addMethod(cls, sel_registerName("retain"), (IMP)of_constant_retain, "@@:");
    class_addMethod(cls, sel_registerName("release"), (IMP)of_constant_release, "v@:");
    class_addMethod(cls, sel_registerName("autorelease"), (IMP)of_constant_autorelease, "@@:");
    class_addMethod(cls, sel_registerName("retainCount"), (IMP)of_constant_retainCount, "Q@:");
    class_addMethod(cls, sel_registerName("_tryRetain"), (IMP)of_constant_tryRetain, "c@:");
    class_addMethod(cls, sel_registerName("_isDeallocating"), (IMP)of_constant_isDeallocating, "c@:");
}

__attribute__((constructor(101))) static void of_foundation_load(void) {
    Class constant = objc_getClass("__NSCFConstantString");
    if (!constant) {
        fprintf(stderr, "FoundationObjCBridge: class __NSCFConstantString is missing\n");
        abort();
    }
    of_make_immortal(constant);
    uint32_t count = _dyld_image_count();
    for (uint32_t i = 0; i < count; i++) {
        const struct mach_header_64 *header = (const struct mach_header_64 *)_dyld_get_image_header(i);
        static const char *const segments[] = {"__DATA", "__DATA_CONST", "__DATA_DIRTY"};
        for (unsigned s = 0; s < sizeof segments / sizeof segments[0]; s++) {
            unsigned long size = 0;
            uint8_t *records = getsectiondata(header, segments[s], "__cfstring", &size);
            if (records && size >= 32) OFFixConstantStrings(records, (long)(size / 32), __CFConstantStringClassReference);
        }
    }
}

#pragma mark - The %@ formatter

typedef struct {
    char *bytes;
    size_t length;
    size_t capacity;
} OFBuffer;

static void of_append(OFBuffer *b, const char *text, size_t n) {
    if (b->length + n + 1 > b->capacity) {
        size_t capacity = b->capacity ? b->capacity : 128;
        while (b->length + n + 1 > capacity) capacity *= 2;
        b->bytes = realloc(b->bytes, capacity);
        b->capacity = capacity;
    }
    memcpy(b->bytes + b->length, text, n);
    b->length += n;
    b->bytes[b->length] = 0;
}

static void of_append_utf16(OFBuffer *b, const unichar *units, size_t count) {
    for (size_t i = 0; i < count; i++) {
        uint32_t c = units[i];
        if (c >= 0xd800 && c < 0xdc00 && i + 1 < count && units[i + 1] >= 0xdc00 && units[i + 1] < 0xe000) {
            c = 0x10000 + ((c - 0xd800) << 10) + (units[i + 1] - 0xdc00);
            i++;
        }
        char out[4];
        size_t n;
        if (c < 0x80) { out[0] = (char)c; n = 1; }
        else if (c < 0x800) { out[0] = (char)(0xc0 | (c >> 6)); out[1] = (char)(0x80 | (c & 0x3f)); n = 2; }
        else if (c < 0x10000) {
            out[0] = (char)(0xe0 | (c >> 12)); out[1] = (char)(0x80 | ((c >> 6) & 0x3f)); out[2] = (char)(0x80 | (c & 0x3f)); n = 3;
        } else {
            out[0] = (char)(0xf0 | (c >> 18)); out[1] = (char)(0x80 | ((c >> 12) & 0x3f));
            out[2] = (char)(0x80 | ((c >> 6) & 0x3f)); out[3] = (char)(0x80 | (c & 0x3f)); n = 4;
        }
        of_append(b, out, n);
    }
}

// snprintf with 0, 1 or 2 '*' arguments already taken from the va_list.
#define OF_FORMAT(VALUE) do { \
        char tmp[512]; \
        int n; \
        if (stars == 2) n = snprintf(tmp, sizeof tmp, spec, star[0], star[1], VALUE); \
        else if (stars == 1) n = snprintf(tmp, sizeof tmp, spec, star[0], VALUE); \
        else n = snprintf(tmp, sizeof tmp, spec, VALUE); \
        if (n >= (int)sizeof tmp) { \
            char *big = malloc((size_t)n + 1); \
            if (stars == 2) snprintf(big, (size_t)n + 1, spec, star[0], star[1], VALUE); \
            else if (stars == 1) snprintf(big, (size_t)n + 1, spec, star[0], VALUE); \
            else snprintf(big, (size_t)n + 1, spec, VALUE); \
            of_append(&out, big, (size_t)n); \
            free(big); \
        } else if (n > 0) { \
            of_append(&out, tmp, (size_t)n); \
        } \
    } while (0)

static void of_unsupported(const char *what, const char *format) {
    fprintf(stderr, "FoundationObjCBridge: %s in format \"%s\" is not implemented in the guest\n", what, format);
    abort();
}

NSString *OFStringWithFormatV(NSString *format, va_list ap) {
    const char *f = format.UTF8String;
    if (!f) return @"";
    OFBuffer out = {0};
    of_append(&out, "", 0);
    for (const char *p = f; *p; ) {
        if (*p != '%') {
            const char *next = strchr(p, '%');
            size_t n = next ? (size_t)(next - p) : strlen(p);
            of_append(&out, p, n);
            p += n;
            continue;
        }
        const char *start = p++;
        if (*p == '%') { of_append(&out, "%", 1); p++; continue; }
        int star[2];
        int stars = 0;
        const char *q = p;
        while (*q >= '0' && *q <= '9') q++;
        if (*q == '$') of_unsupported("a positional argument (%n$)", f);
        while (*p && strchr("-+ #0'", *p)) p++;
        if (*p == '*') { star[stars++] = va_arg(ap, int); p++; } else { while (*p >= '0' && *p <= '9') p++; }
        if (*p == '.') {
            p++;
            if (*p == '*') { star[stars++] = va_arg(ap, int); p++; } else { while (*p >= '0' && *p <= '9') p++; }
        }
        enum { L_NONE, L_HH, L_H, L_L, L_LL, L_Z, L_T, L_J, L_LD } len = L_NONE;
        if (p[0] == 'h' && p[1] == 'h') { len = L_HH; p += 2; }
        else if (*p == 'h') { len = L_H; p++; }
        else if (p[0] == 'l' && p[1] == 'l') { len = L_LL; p += 2; }
        else if (*p == 'l') { len = L_L; p++; }
        else if (*p == 'q') { len = L_LL; p++; }
        else if (*p == 'z') { len = L_Z; p++; }
        else if (*p == 't') { len = L_T; p++; }
        else if (*p == 'j') { len = L_J; p++; }
        else if (*p == 'L') { len = L_LD; p++; }
        char conversion = *p;
        if (!conversion) break;
        p++;
        // The spec as snprintf wants it: flags/width/precision kept, length
        // normalised ('q' -> "ll"), conversion last.
        char spec[64];
        size_t prefix = (size_t)(p - start - 1);
        if (prefix > sizeof spec - 8) of_unsupported("an overlong conversion", f);
        char body[64];
        size_t bn = 0;
        for (const char *c = start; c < start + prefix; c++) {
            if (*c == 'q') { body[bn++] = 'l'; body[bn++] = 'l'; }
            else body[bn++] = *c;
        }
        body[bn] = 0;
        switch (conversion) {
        case '@': {
            id object = va_arg(ap, id);
            char *text = OFCopyDescriptionUTF8(object);
            // Width/precision apply to the description as to a C string.
            snprintf(spec, sizeof spec, "%ss", body);
            OF_FORMAT(text);
            free(text);
            break;
        }
        case 'd': case 'i':
            snprintf(spec, sizeof spec, "%s%c", body, conversion);
            switch (len) {
            case L_LL: OF_FORMAT(va_arg(ap, long long)); break;
            case L_L: case L_Z: case L_T: case L_J: OF_FORMAT(va_arg(ap, long)); break;
            default: OF_FORMAT(va_arg(ap, int)); break;
            }
            break;
        case 'o': case 'u': case 'x': case 'X':
            snprintf(spec, sizeof spec, "%s%c", body, conversion);
            switch (len) {
            case L_LL: OF_FORMAT(va_arg(ap, unsigned long long)); break;
            case L_L: case L_Z: case L_T: case L_J: OF_FORMAT(va_arg(ap, unsigned long)); break;
            default: OF_FORMAT(va_arg(ap, unsigned int)); break;
            }
            break;
        case 'e': case 'E': case 'f': case 'F': case 'g': case 'G': case 'a': case 'A':
            snprintf(spec, sizeof spec, "%s%c", body, conversion);
            if (len == L_LD) OF_FORMAT(va_arg(ap, long double));
            else OF_FORMAT(va_arg(ap, double));
            break;
        case 'c':
            snprintf(spec, sizeof spec, "%s%c", body, conversion);
            OF_FORMAT(va_arg(ap, int));
            break;
        case 'C': {
            unichar c = (unichar)va_arg(ap, int);
            of_append_utf16(&out, &c, 1);
            break;
        }
        case 's': {
            const char *text = va_arg(ap, const char *);
            snprintf(spec, sizeof spec, "%s%c", body, conversion);
            OF_FORMAT(text ? text : "(null)");
            break;
        }
        case 'S': {
            const unichar *units = va_arg(ap, const unichar *);
            if (!units) { of_append(&out, "(null)", 6); break; }
            size_t n = 0;
            while (units[n]) n++;
            of_append_utf16(&out, units, n);
            break;
        }
        case 'p':
            snprintf(spec, sizeof spec, "%s%c", body, conversion);
            OF_FORMAT(va_arg(ap, void *));
            break;
        case 'n':
            (void)va_arg(ap, void *);
            break;
        default: {
            char what[40];
            snprintf(what, sizeof what, "the conversion %%%c", conversion);
            of_unsupported(what, f);
        }
        }
    }
    NSString *result = OFStringFromUTF8(out.bytes, (long)out.length);
    free(out.bytes);
    return result;
}

#pragma mark - NSString

@implementation NSString (OFFoundationObjC)
+ (instancetype)string { return [[self alloc] init]; }
+ (instancetype)stringWithString:(NSString *)string { return [[self alloc] initWithString:string]; }
+ (instancetype)stringWithCharacters:(const unichar *)characters length:(NSUInteger)length {
    return [[self alloc] initWithCharacters:characters length:length];
}
+ (instancetype)stringWithUTF8String:(const char *)bytes { return [[self alloc] initWithUTF8String:bytes]; }
+ (instancetype)stringWithCString:(const char *)bytes encoding:(NSStringEncoding)encoding {
    return [[self alloc] initWithCString:bytes encoding:encoding];
}
+ (instancetype)stringWithFormat:(NSString *)format, ... {
    va_list ap;
    va_start(ap, format);
    NSString *formatted = OFStringWithFormatV(format, ap);
    va_end(ap);
    return [[self alloc] initWithString:formatted];
}
- (instancetype)initWithFormat:(NSString *)format, ... {
    va_list ap;
    va_start(ap, format);
    NSString *formatted = OFStringWithFormatV(format, ap);
    va_end(ap);
    return [self initWithString:formatted];
}
- (instancetype)initWithFormat:(NSString *)format arguments:(va_list)arguments {
    va_list copy;
    va_copy(copy, arguments);
    NSString *formatted = OFStringWithFormatV(format, copy);
    va_end(copy);
    return [self initWithString:formatted];
}
- (NSString *)stringByAppendingFormat:(NSString *)format, ... {
    va_list ap;
    va_start(ap, format);
    NSString *formatted = OFStringWithFormatV(format, ap);
    va_end(ap);
    return [self stringByAppendingString:formatted];
}
- (NSString *)substringWithRange:(NSRange)range {
    return [self _of_substringWithLocation:range.location length:range.length];
}
- (void)getCharacters:(unichar *)buffer range:(NSRange)range {
    [self _of_getCharacters:buffer location:range.location length:range.length];
}
- (NSRange)rangeOfString:(NSString *)target options:(NSStringCompareOptions)options range:(NSRange)range {
    NSUInteger length = 0;
    NSUInteger location = [self _of_rangeOfString:target options:options location:range.location length:range.length outLength:&length];
    return NSMakeRange(location, length);
}
- (NSRange)rangeOfString:(NSString *)target options:(NSStringCompareOptions)options {
    return [self rangeOfString:target options:options range:NSMakeRange(0, self.length)];
}
- (NSRange)rangeOfString:(NSString *)target { return [self rangeOfString:target options:0]; }
- (NSString *)stringByReplacingOccurrencesOfString:(NSString *)target withString:(NSString *)replacement
                                          options:(NSStringCompareOptions)options range:(NSRange)range {
    return [self _of_stringByReplacingOccurrencesOfString:target withString:replacement options:options
                                                 location:range.location length:range.length];
}
- (NSString *)stringByReplacingCharactersInRange:(NSRange)range withString:(NSString *)replacement {
    return [self _of_stringByReplacingCharactersInLocation:range.location length:range.length withString:replacement];
}
@end

@implementation NSMutableString (OFFoundationObjC)
+ (NSMutableString *)stringWithCapacity:(NSUInteger)capacity { return [[self alloc] initWithCapacity:capacity]; }
- (void)appendFormat:(NSString *)format, ... {
    va_list ap;
    va_start(ap, format);
    NSString *formatted = OFStringWithFormatV(format, ap);
    va_end(ap);
    [self appendString:formatted];
}
- (void)replaceCharactersInRange:(NSRange)range withString:(NSString *)replacement {
    [self _of_replaceCharactersInLocation:range.location length:range.length withString:replacement];
}
- (void)deleteCharactersInRange:(NSRange)range {
    [self _of_deleteCharactersInLocation:range.location length:range.length];
}
- (NSUInteger)replaceOccurrencesOfString:(NSString *)target withString:(NSString *)replacement
                                 options:(NSStringCompareOptions)options range:(NSRange)range {
    return [self _of_replaceOccurrencesOfString:target withString:replacement options:options
                                       location:range.location length:range.length];
}
@end

#pragma mark - Collections

static NSUInteger of_collect(id first, va_list ap, __unsafe_unretained id **out) {
    NSUInteger count = 0, capacity = 8;
    __unsafe_unretained id *objects = (__unsafe_unretained id *)calloc(capacity, sizeof(id));
    for (id object = first; object; object = va_arg(ap, id)) {
        if (count == capacity) {
            capacity *= 2;
            objects = (__unsafe_unretained id *)realloc(objects, capacity * sizeof(id));
        }
        objects[count++] = object;
    }
    *out = objects;
    return count;
}

@implementation NSArray (OFFoundationObjC)
+ (instancetype)array { return [[self alloc] init]; }
+ (instancetype)arrayWithObject:(id)object { return [[self alloc] initWithObjects:&object count:1]; }
+ (instancetype)arrayWithObjects:(const id [])objects count:(NSUInteger)count {
    return [[self alloc] initWithObjects:objects count:count];
}
+ (instancetype)arrayWithObjects:(id)first, ... {
    va_list ap;
    va_start(ap, first);
    __unsafe_unretained id *objects;
    NSUInteger count = of_collect(first, ap, &objects);
    va_end(ap);
    NSArray *array = [[self alloc] initWithObjects:objects count:count];
    free(objects);
    return array;
}
- (instancetype)initWithObjects:(id)first, ... {
    va_list ap;
    va_start(ap, first);
    __unsafe_unretained id *objects;
    NSUInteger count = of_collect(first, ap, &objects);
    va_end(ap);
    self = [self initWithObjects:objects count:count];
    free(objects);
    return self;
}
+ (instancetype)arrayWithArray:(NSArray *)array { return [[self alloc] initWithArray:array]; }
- (NSArray *)subarrayWithRange:(NSRange)range { return [self _of_subarrayWithLocation:range.location length:range.length]; }
@end

@implementation NSMutableArray (OFFoundationObjC)
+ (instancetype)arrayWithCapacity:(NSUInteger)capacity { return [[self alloc] initWithCapacity:capacity]; }
@end

@implementation NSDictionary (OFFoundationObjC)
+ (instancetype)dictionary { return [[self alloc] init]; }
+ (instancetype)dictionaryWithObject:(id)object forKey:(id)key {
    return [[self alloc] initWithObjects:&object forKeys:&key count:1];
}
+ (instancetype)dictionaryWithObjects:(const id [])objects forKeys:(const id [])keys count:(NSUInteger)count {
    return [[self alloc] initWithObjects:objects forKeys:keys count:count];
}
+ (instancetype)dictionaryWithObjectsAndKeys:(id)first, ... {
    va_list ap;
    va_start(ap, first);
    __unsafe_unretained id *items;
    NSUInteger count = of_collect(first, ap, &items);
    va_end(ap);
    NSUInteger pairs = count / 2;
    __unsafe_unretained id *objects = (__unsafe_unretained id *)calloc(pairs ? pairs : 1, sizeof(id));
    __unsafe_unretained id *keys = (__unsafe_unretained id *)calloc(pairs ? pairs : 1, sizeof(id));
    for (NSUInteger i = 0; i < pairs; i++) { objects[i] = items[2 * i]; keys[i] = items[2 * i + 1]; }
    NSDictionary *dictionary = [[self alloc] initWithObjects:objects forKeys:keys count:pairs];
    free(items); free(objects); free(keys);
    return dictionary;
}
+ (instancetype)dictionaryWithDictionary:(NSDictionary *)other { return [[self alloc] initWithDictionary:other]; }
+ (instancetype)dictionaryWithObjects:(NSArray *)objects forKeys:(NSArray *)keys {
    NSUInteger count = objects.count;
    __unsafe_unretained id *os = (__unsafe_unretained id *)calloc(count ? count : 1, sizeof(id));
    __unsafe_unretained id *ks = (__unsafe_unretained id *)calloc(count ? count : 1, sizeof(id));
    NSMutableArray *hold = [NSMutableArray arrayWithCapacity:count * 2];
    for (NSUInteger i = 0; i < count; i++) {
        id o = objects[i], k = keys[i];
        [hold addObject:o];
        [hold addObject:k];
        os[i] = o;
        ks[i] = k;
    }
    NSDictionary *dictionary = [[self alloc] initWithObjects:os forKeys:ks count:count];
    free(os); free(ks);
    return dictionary;
}
@end

@implementation NSMutableDictionary (OFFoundationObjC)
+ (instancetype)dictionaryWithCapacity:(NSUInteger)capacity { return [[self alloc] initWithCapacity:capacity]; }
@end

@implementation NSSet (OFFoundationObjC)
+ (instancetype)set { return [[self alloc] init]; }
+ (instancetype)setWithObject:(id)object { return [[self alloc] initWithArray:@[object]]; }
+ (instancetype)setWithObjects:(id)first, ... {
    va_list ap;
    va_start(ap, first);
    __unsafe_unretained id *objects;
    NSUInteger count = of_collect(first, ap, &objects);
    va_end(ap);
    NSSet *set = [[self alloc] initWithArray:[NSArray arrayWithObjects:objects count:count]];
    free(objects);
    return set;
}
+ (instancetype)setWithArray:(NSArray *)array { return [[self alloc] initWithArray:array]; }
+ (instancetype)setWithSet:(NSSet *)set { return [[self alloc] initWithArray:set.allObjects]; }
@end

@implementation NSMutableSet (OFFoundationObjC)
+ (instancetype)setWithCapacity:(NSUInteger)capacity { return [[self alloc] initWithCapacity:capacity]; }
@end

#pragma mark - NSNumber, NSData

@implementation NSNumber (OFFoundationObjC)
+ (NSNumber *)numberWithChar:(char)v { return [[self alloc] initWithChar:v]; }
+ (NSNumber *)numberWithUnsignedChar:(unsigned char)v { return [[self alloc] initWithUnsignedChar:v]; }
+ (NSNumber *)numberWithShort:(short)v { return [[self alloc] initWithShort:v]; }
+ (NSNumber *)numberWithUnsignedShort:(unsigned short)v { return [[self alloc] initWithUnsignedShort:v]; }
+ (NSNumber *)numberWithInt:(int)v { return [[self alloc] initWithInt:v]; }
+ (NSNumber *)numberWithUnsignedInt:(unsigned int)v { return [[self alloc] initWithUnsignedInt:v]; }
+ (NSNumber *)numberWithLong:(long)v { return [[self alloc] initWithLong:v]; }
+ (NSNumber *)numberWithUnsignedLong:(unsigned long)v { return [[self alloc] initWithUnsignedLong:v]; }
+ (NSNumber *)numberWithLongLong:(long long)v { return [[self alloc] initWithLongLong:v]; }
+ (NSNumber *)numberWithUnsignedLongLong:(unsigned long long)v { return [[self alloc] initWithUnsignedLongLong:v]; }
+ (NSNumber *)numberWithFloat:(float)v { return [[self alloc] initWithFloat:v]; }
+ (NSNumber *)numberWithDouble:(double)v { return [[self alloc] initWithDouble:v]; }
// @YES / @NO (clang 18 sends +numberWithBool:) are two shared objects, as in
// the SDK; they are never released.
+ (NSNumber *)numberWithBool:(BOOL)v {
    static NSNumber *yes, *no;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        yes = OFMakeBooleanNumber(YES);
        no = OFMakeBooleanNumber(NO);
    });
    return v ? yes : no;
}
+ (NSNumber *)numberWithInteger:(NSInteger)v { return [[self alloc] initWithInteger:v]; }
+ (NSNumber *)numberWithUnsignedInteger:(NSUInteger)v { return [[self alloc] initWithUnsignedInteger:v]; }
@end

@implementation NSData (OFFoundationObjC)
+ (instancetype)data { return [[self alloc] init]; }
+ (instancetype)dataWithBytes:(const void *)bytes length:(NSUInteger)length { return [[self alloc] initWithBytes:bytes length:length]; }
+ (instancetype)dataWithBytesNoCopy:(void *)bytes length:(NSUInteger)length {
    return [[self alloc] initWithBytesNoCopy:bytes length:length freeWhenDone:YES];
}
+ (instancetype)dataWithBytesNoCopy:(void *)bytes length:(NSUInteger)length freeWhenDone:(BOOL)b {
    return [[self alloc] initWithBytesNoCopy:bytes length:length freeWhenDone:b];
}
+ (instancetype)dataWithData:(NSData *)data { return [[self alloc] initWithData:data]; }
- (void)getBytes:(void *)buffer range:(NSRange)range { [self _of_getBytes:buffer location:range.location length:range.length]; }
- (NSData *)subdataWithRange:(NSRange)range { return [self _of_subdataWithLocation:range.location length:range.length]; }
@end

@implementation NSMutableData (OFFoundationObjC)
+ (instancetype)dataWithCapacity:(NSUInteger)capacity { return [[self alloc] initWithCapacity:capacity]; }
@end

#pragma mark - NSObject, NSAssertionHandler

// objc4 leaves these to CoreFoundation ("Replaced by CF"): the SDK prints
// "<ClassName: 0x...>" for an object and the name for a class.
@implementation NSObject (OFFoundationDescription)
- (NSString *)description {
    return [NSString stringWithFormat:@"<%s: %p>", class_getName(object_getClass(self)), (__bridge void *)self];
}
+ (NSString *)description { return NSStringFromClass(self); }
@end

static void of_assertion_failure(NSString *where, NSString *file, NSInteger line, NSString *reason) {
    fprintf(stderr, "*** Assertion failure in %s, %s:%ld\n", where.UTF8String, file.UTF8String, (long)line);
    fprintf(stderr, "*** Terminating app due to uncaught exception 'NSInternalInconsistencyException', reason: '%s'\n",
            reason.UTF8String);
    abort();
}

@implementation NSAssertionHandler (OFFoundationObjC)
- (void)handleFailureInMethod:(SEL)selector object:(id)object file:(NSString *)fileName
                   lineNumber:(NSInteger)line description:(NSString *)format, ... {
    va_list ap;
    va_start(ap, format);
    NSString *reason = format ? OFStringWithFormatV(format, ap) : @"";
    va_end(ap);
    BOOL isClass = object_isClass(object);
    NSString *where = [NSString stringWithFormat:@"%c[%s %s]", isClass ? '+' : '-',
                       class_getName(isClass ? (Class)object : object_getClass(object)), sel_getName(selector)];
    of_assertion_failure(where, fileName, line, reason);
}
- (void)handleFailureInFunction:(NSString *)functionName file:(NSString *)fileName
                     lineNumber:(NSInteger)line description:(NSString *)format, ... {
    va_list ap;
    va_start(ap, format);
    NSString *reason = format ? OFStringWithFormatV(format, ap) : @"";
    va_end(ap);
    of_assertion_failure(functionName, fileName, line, reason);
}
@end

#pragma mark - Typed message sends for the Swift half

// Swift cannot bind one symbol to several objc_msgSend signatures, so each
// shape it needs is a C function here.
NSInteger OFSendCompare(id receiver, SEL selector, id other) {
    return ((NSInteger (*)(id, SEL, id))objc_msgSend)(receiver, selector, other);
}
void OFSendVoid(id receiver, SEL selector) { ((void (*)(id, SEL))objc_msgSend)(receiver, selector); }
void OFSendVoidWith(id receiver, SEL selector, id argument) {
    ((void (*)(id, SEL, id))objc_msgSend)(receiver, selector, argument);
}
// +0, as a getter returns it; the caller takes it unretained.
__unsafe_unretained id OFSendObject(id receiver, SEL selector) {
    return ((__unsafe_unretained id (*)(id, SEL))objc_msgSend)(receiver, selector);
}

#pragma mark - Runtime helpers and NSLog

NSString *NSStringFromSelector(SEL selector) {
    return selector ? [NSString stringWithUTF8String:sel_getName(selector)] : (NSString *)nil;
}
SEL NSSelectorFromString(NSString *name) { return name ? sel_registerName(name.UTF8String) : (SEL)0; }
NSString *NSStringFromClass(Class cls) {
    return cls ? [NSString stringWithUTF8String:class_getName(cls)] : (NSString *)nil;
}
Class NSClassFromString(NSString *name) { return name ? objc_getClass(name.UTF8String) : Nil; }
NSString *NSStringFromProtocol(Protocol *proto) { return [NSString stringWithUTF8String:protocol_getName(proto)]; }
Protocol *NSProtocolFromString(NSString *name) { return objc_getProtocol(name.UTF8String); }
NSString *NSStringFromRange(NSRange range) {
    return [NSString stringWithFormat:@"{%lu, %lu}", (unsigned long)range.location, (unsigned long)range.length];
}
NSRange NSRangeFromString(NSString *text) {
    unsigned long location = 0, length = 0;
    const char *s = text.UTF8String;
    while (s && *s && (*s < '0' || *s > '9')) s++;
    if (s && *s) location = strtoul(s, (char **)&s, 10);
    while (s && *s && (*s < '0' || *s > '9')) s++;
    if (s && *s) length = strtoul(s, NULL, 10);
    return NSMakeRange(location, length);
}

NSString *NSFileTypeForHFSTypeCode(OSType code) {
    char text[7] = {'\'', (char)(code >> 24), (char)(code >> 16), (char)(code >> 8), (char)code, '\'', 0};
    return [NSString stringWithUTF8String:text];
}

OSType NSHFSTypeCodeFromFileType(NSString *type) {
    const char *s = type.UTF8String;
    if (!s || strlen(s) != 6 || s[0] != '\'' || s[5] != '\'') return 0;
    return ((OSType)(unsigned char)s[1] << 24) | ((OSType)(unsigned char)s[2] << 16) |
           ((OSType)(unsigned char)s[3] << 8) | (OSType)(unsigned char)s[4];
}

// "2026-09-23 12:34:56.789012+0000 name[pid:tid] message", to stderr.
void NSLogv(NSString *format, va_list args) {
    NSString *message = OFStringWithFormatV(format, args);
    struct timeval now;
    gettimeofday(&now, NULL);
    struct tm local;
    time_t seconds = now.tv_sec;
    localtime_r(&seconds, &local);
    char stamp[64];
    strftime(stamp, sizeof stamp, "%Y-%m-%d %H:%M:%S", &local);
    char zone[16];
    strftime(zone, sizeof zone, "%z", &local);
    uint64_t thread = 0;
    pthread_threadid_np(NULL, &thread);
    fprintf(stderr, "%s.%06ld%s %s[%d:%llx] %s\n", stamp, (long)now.tv_usec, zone, getprogname(), getpid(),
            (unsigned long long)thread, message.UTF8String);
}

void NSLog(NSString *format, ...) {
    va_list ap;
    va_start(ap, format);
    NSLogv(format, ap);
    va_end(ap);
}
