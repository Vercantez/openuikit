// 006-load-order -- the raw, absolute order of +load within one image.
//
// This is the strictest +load test in the corpus and the one most likely to
// diverge first on Linux: on Darwin dyld hands objc4 a non-lazy class list and
// objc4 walks it superclass-first; on ELF the same list is a linker-ordered
// section. If this test fails but 007-load-invariants passes, the divergence is
// ordering-within-image and not a semantic break -- record it, do not "fix" it
// by weakening the test.
#include "testsupport.h"

@interface LoadA : TestRoot @end
@implementation LoadA + (void)load { event("LoadA.load"); } @end

@interface LoadB : LoadA @end
@implementation LoadB + (void)load { event("LoadB.load"); } @end

@interface LoadC : LoadB @end
@implementation LoadC + (void)load { event("LoadC.load"); } @end

// A class with no +load of its own must not inherit LoadA's for load purposes:
// +load is looked up on the class itself, never inherited.
@interface LoadSilent : LoadA @end
@implementation LoadSilent @end

@interface LoadA (Cat1) @end
@implementation LoadA (Cat1) + (void)load { event("LoadA(Cat1).load"); } @end

@interface LoadA (Cat2) @end
@implementation LoadA (Cat2) + (void)load { event("LoadA(Cat2).load"); } @end

@interface LoadIndependent : TestRoot @end
@implementation LoadIndependent + (void)load { event("LoadIndependent.load"); } @end

__attribute__((constructor))
static void c_constructor(void) { event("c-constructor"); }

int main(void) {
    event("main");
    print_events("ev");

    // +load is per-class, never inherited: LoadSilent has none of its own.
    say("silent.has.own.load=%s",
        YN(class_getClassMethod(objc_getClass("LoadSilent"), @selector(load)) !=
           class_getClassMethod(objc_getClass("LoadA"), @selector(load))));
    return 0;
}
