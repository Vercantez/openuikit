// 011-category-collision -- two categories in one translation unit define the
// same selector. objc4 has a defined-but-undocumented answer here (it attaches
// the category list back-to-front and prepends each method list), and any port
// that walks __objc_catlist in the other direction silently inverts it.
//
// This is deliberately a raw-order test: the answer is whatever the real
// runtime does, and the value of the test is that a divergence is loud.
#include "testsupport.h"

@interface Contested : TestRoot
- (int)who;
+ (int)classWho;
@end
@implementation Contested
- (int)who { return 0; }
+ (int)classWho { return 0; }
@end

@interface Contested (First)
- (int)who;
+ (int)classWho;
- (int)onlyFirst;
@end
@implementation Contested (First)
- (int)who { return 1; }
+ (int)classWho { return 11; }
- (int)onlyFirst { return 111; }
+ (void)load { event("First.load"); }
@end

@interface Contested (Second)
- (int)who;
+ (int)classWho;
- (int)onlySecond;
@end
@implementation Contested (Second)
- (int)who { return 2; }
+ (int)classWho { return 22; }
- (int)onlySecond { return 222; }
+ (void)load { event("Second.load"); }
@end

@interface Contested (Third)
- (int)who;
@end
@implementation Contested (Third)
- (int)who { return 3; }
+ (void)load { event("Third.load"); }
@end

int main(void) {
    Contested *c = [Contested new];

    say("instance.winner=%d", [c who]);
    say("class.winner=%d", [Contested classWho]);

    // Non-contested methods from every category are all present.
    say("onlyFirst=%d", ((int (*)(id, SEL))objc_msgSend)(c, sel_registerName("onlyFirst")));
    say("onlySecond=%d", ((int (*)(id, SEL))objc_msgSend)(c, sel_registerName("onlySecond")));

    // How many method-list entries exist for the contested selector? (One per
    // definition site: the class plus three categories.)
    unsigned n = 0;
    Method *ms = class_copyMethodList(objc_getClass("Contested"), &n);
    int count = 0;
    for (unsigned i = 0; i < n; i++)
        if (method_getName(ms[i]) == @selector(who)) count++;
    free(ms);
    say("who.entries=%d", count);

    // The winner reported by class_getInstanceMethod must agree with dispatch.
    Method m = class_getInstanceMethod(objc_getClass("Contested"), @selector(who));
    int viaMethod = ((int (*)(id, SEL))method_getImplementation(m))(c, @selector(who));
    say("getInstanceMethod.agrees.with.dispatch=%s", YN(viaMethod == [c who]));

    print_events("ev");
    objc_release(c);
    return 0;
}
