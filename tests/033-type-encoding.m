// 033-type-encoding -- @encode strings.
// These are compiler output, not runtime output, but they are the format the
// runtime parses in method_copyArgumentType, property attributes and ivar
// types. If clang encodes differently on ELF, every one of those diverges, so
// pinning them here localises the blame.
#include "testsupport.h"

typedef struct Point { int x; int y; } Point;
typedef struct Nested { Point p; double d; char c; } Nested;
typedef union  Uni { int i; float f; } Uni;
typedef struct Bits { unsigned a : 3; unsigned b : 5; } Bits;
typedef struct Opaque *OpaqueRef;

@protocol T4LEncProto @end
@interface Enc : TestRoot @end
@implementation Enc @end

#define E(expr) say("enc." #expr "=%s", @encode(expr))

int main(void) {
    E(void);
    E(char); E(unsigned char); E(signed char);
    E(short); E(unsigned short);
    E(int); E(unsigned int);
    E(long); E(unsigned long);
    E(long long); E(unsigned long long);
    E(float); E(double); E(long double);
    E(_Bool); E(BOOL);
    E(char *); E(const char *); E(void *); E(const void *);
    E(int *); E(int **);
    E(id); E(Class); E(SEL);
    E(Enc *);
    E(id<T4LEncProto>);
    E(Point); E(Nested); E(Uni); E(Bits);
    E(OpaqueRef);
    E(int[4]); E(int[2][3]);
    E(Point[3]);
    E(void (*)(void));
    E(int (*)(int, double));
    E(const int);
    E(volatile int);

    say("sizeof.Point=%zu", sizeof(Point));
    say("sizeof.Nested=%zu", sizeof(Nested));
    say("sizeof.Bits=%zu", sizeof(Bits));
    say("sizeof.long=%zu", sizeof(long));
    say("sizeof.longdouble=%zu", sizeof(long double));
    say("sizeof.id=%zu", sizeof(id));
    say("sizeof.BOOL=%zu", sizeof(BOOL));

    // The runtime's own parse of a method type string must agree with @encode.
    Method m = class_getInstanceMethod(objc_getClass("TestRoot"), @selector(init));
    say("init.types=%s", SAFESTR(method_getTypeEncoding(m)));
    char *ret = method_copyReturnType(m);
    say("init.ret=%s", SAFESTR(ret));
    say("init.ret.matches.encode.id=%s", YN(strcmp(SAFESTR(ret), @encode(id)) == 0));
    free(ret);
    return 0;
}
