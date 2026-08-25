// 005-dispatch-types -- return values and arguments of every ABI shape.
// objc_msgSend is written in assembly per architecture and must be transparent
// to the calling convention: integer, float, small aggregate (register pair),
// large aggregate (indirect result), and stack-passed arguments.
#include "testsupport.h"

typedef struct { int a, b; }              SmallS;   // 8 bytes, one register
typedef struct { long a, b; }             PairS;    // 16 bytes, two registers
typedef struct { double a, b, c, d, e; }  BigS;     // 40 bytes, indirect
typedef struct { float x, y; }            FloatS;   // HFA

@interface Shapes : TestRoot
- (char)retChar;
- (short)retShort;
- (int)retInt;
- (long long)retLongLong;
- (unsigned long long)retULongLong;
- (float)retFloat;
- (double)retDouble;
- (const char *)retString;
- (void *)retNullPointer;
- (SmallS)retSmall;
- (PairS)retPair;
- (BigS)retBig;
- (FloatS)retFloatS;
- (void)retVoid;
- (int)sum9:(int)a :(int)b :(int)c :(int)d :(int)e :(int)f :(int)g :(int)h :(int)i;
- (double)mix:(int)i d:(double)d s:(SmallS)s ll:(long long)ll f:(float)f;
- (int)takeBig:(BigS)s;
@end

@implementation Shapes
- (char)retChar { return 'q'; }
- (short)retShort { return -1234; }
- (int)retInt { return 0x7f3f2f1f; }
- (long long)retLongLong { return -1234567890123LL; }
- (unsigned long long)retULongLong { return 18000000000000000000ULL; }
- (float)retFloat { return 1.5f; }
- (double)retDouble { return -2.25; }
- (const char *)retString { return "string-return"; }
- (void *)retNullPointer { return NULL; }
- (SmallS)retSmall { SmallS s = {7, 8}; return s; }
- (PairS)retPair { PairS s = {111, 222}; return s; }
- (BigS)retBig { BigS s = {1.0, 2.0, 3.0, 4.0, 5.0}; return s; }
- (FloatS)retFloatS { FloatS s = {0.5f, 0.25f}; return s; }
- (void)retVoid { }
- (int)sum9:(int)a :(int)b :(int)c :(int)d :(int)e :(int)f :(int)g :(int)h :(int)i {
    return a + b*2 + c*3 + d*4 + e*5 + f*6 + g*7 + h*8 + i*9;
}
- (double)mix:(int)i d:(double)d s:(SmallS)s ll:(long long)ll f:(float)f {
    return i + d + s.a + s.b + (double)ll + f;
}
- (int)takeBig:(BigS)s { return (int)(s.a + s.b + s.c + s.d + s.e); }
@end

int main(void) {
    Shapes *o = [Shapes new];

    say("char=%c", [o retChar]);
    say("short=%d", (int)[o retShort]);
    say("int=%d", [o retInt]);
    say("longlong=%lld", [o retLongLong]);
    say("ulonglong=%llu", [o retULongLong]);
    say("float=%.4f", (double)[o retFloat]);
    say("double=%.4f", [o retDouble]);
    say("string=%s", [o retString]);
    say("pointer=%s", NULLNESS([o retNullPointer]));
    [o retVoid];
    say("void=ok");

    SmallS s = [o retSmall];
    say("small=%d,%d", s.a, s.b);
    PairS p = [o retPair];
    say("pair=%ld,%ld", p.a, p.b);
    BigS bg = [o retBig];
    say("big=%.1f,%.1f,%.1f,%.1f,%.1f", bg.a, bg.b, bg.c, bg.d, bg.e);
    FloatS fs = [o retFloatS];
    say("floatstruct=%.4f,%.4f", (double)fs.x, (double)fs.y);

    say("sum9=%d", [o sum9:1 :2 :3 :4 :5 :6 :7 :8 :9]);

    SmallS arg = {3, 4};
    say("mix=%.4f", [o mix:1 d:0.5 s:arg ll:100 f:0.25f]);

    BigS bigArg = {10.0, 20.0, 30.0, 40.0, 50.0};
    say("takeBig=%d", [o takeBig:bigArg]);

    // Same calls again, now from a warm method cache.
    say("warm.int=%d", [o retInt]);
    say("warm.big.sum=%.1f", ({ BigS w = [o retBig]; w.a + w.b + w.c + w.d + w.e; }));

    objc_release(o);
    return 0;
}
