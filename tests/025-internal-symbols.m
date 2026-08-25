// 025-internal-symbols -- the export surface, not a behaviour.
//
// This is the test that keeps the project honest about its motivating claim.
// The reason to port Apple's objc4 rather than use libobjc2 is that Swift's
// runtime calls a set of private <objc/objc-internal.h> entry points that only
// objc4 has, and that are not weak-linked. Enumerating them by dlsym gives a
// checklist that is meaningful on both platforms and does not depend on any of
// them behaving correctly yet.
//
// objc_readClassPair is deliberately probed rather than called: calling it
// needs a statically-built objc_class + class_ro_t whose layout is private, so
// constructing one in a portable test source would encode the layout of one
// particular objc4 vintage into the corpus.
#include "testsupport.h"
#include <dlfcn.h>

static const char *const kSymbols[] = {
    // Class construction -- the Swift-critical ones.
    "objc_readClassPair",
    "objc_allocateClassPair",
    "objc_registerClassPair",
    "objc_duplicateClass",
    "objc_disposeClassPair",
    "objc_constructInstance",
    "objc_destructInstance",
    "objc_initializeClassPair",

    // Dispatch.
    "objc_msgSend",
    "objc_msgSendSuper",
    "objc_msgSendSuper2",
    "_objc_msgForward",
    "method_invoke",

    // ARC.
    "objc_retain",
    "objc_release",
    "objc_autorelease",
    "objc_retainAutorelease",
    "objc_retainAutoreleaseReturnValue",
    "objc_retainAutoreleasedReturnValue",
    "objc_autoreleaseReturnValue",
    "objc_unsafeClaimAutoreleasedReturnValue",
    "objc_storeStrong",
    "objc_retainBlock",
    "objc_autoreleasePoolPush",
    "objc_autoreleasePoolPop",
    "objc_alloc",
    "objc_allocWithZone",
    "objc_alloc_init",
    "objc_opt_new",
    "objc_opt_self",
    "objc_opt_class",
    "objc_opt_isKindOfClass",
    "objc_opt_respondsToSelector",

    // Weak.
    "objc_initWeak",
    "objc_initWeakOrNil",
    "objc_destroyWeak",
    "objc_copyWeak",
    "objc_moveWeak",
    "objc_storeWeak",
    "objc_storeWeakOrNil",
    "objc_loadWeak",
    "objc_loadWeakRetained",

    // Root-class helpers a non-NSObject root class needs.
    "_objc_rootRetain",
    "_objc_rootRelease",
    "_objc_rootAutorelease",
    "_objc_rootRetainCount",
    "_objc_rootTryRetain",
    "_objc_rootIsDeallocating",
    "_objc_rootAlloc",
    "_objc_rootAllocWithZone",
    "_objc_rootDealloc",
    "_objc_rootInit",
    "_objc_rootZone",
    "_objc_rootHash",

    // Associated objects, sync, exceptions.
    "objc_setAssociatedObject",
    "objc_getAssociatedObject",
    "objc_removeAssociatedObjects",
    "objc_sync_enter",
    "objc_sync_exit",
    "objc_exception_throw",
    "objc_exception_rethrow",
    "objc_begin_catch",
    "objc_end_catch",
    "objc_terminate",

    // Blocks-as-IMPs.
    "imp_implementationWithBlock",
    "imp_getBlock",
    "imp_removeBlock",

    // Debug/data symbols the Swift runtime and lldb read directly.
    "objc_debug_isa_class_mask",
    "objc_debug_isa_magic_mask",
    "objc_debug_isa_magic_value",
    "objc_debug_taggedpointer_mask",
    "_objc_empty_cache",

    // Image/section discovery -- the part this port replaces wholesale.
    "objc_getClassList",
    "objc_copyClassList",
    "objc_copyClassNamesForImage",
    "objc_copyImageNames",
    "class_getImageName",
};

int main(void) {
    unsigned present = 0, absent = 0;
    for (unsigned i = 0; i < sizeof(kSymbols)/sizeof(kSymbols[0]); i++) {
        void *p = dlsym(RTLD_DEFAULT, kSymbols[i]);
        say("sym.%s=%s", kSymbols[i], p ? "present" : "ABSENT");
        if (p) present++; else absent++;
    }
    say("symbols.total=%u", present + absent);
    say("symbols.absent=%u", absent);
    return 0;
}
