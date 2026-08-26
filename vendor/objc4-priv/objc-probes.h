/*
 * compat/objc-probes.h  --  objc4-linux
 *
 * On Darwin this file is GENERATED from runtime/objc-probes.d by dtrace(1),
 * and objc-os.h includes it unconditionally. Linux has no dtrace, so every
 * probe compiles to nothing and every _ENABLED() test is false.
 *
 * This file was itself generated from objc-probes.d (see the generator in
 * this repo's git history) so the macro list stays complete if Apple adds a
 * probe. SystemTap SDT could supply real probes later; it is not worth it yet.
 */
#ifndef _OBJC4LINUX_OBJC_PROBES_H
#define _OBJC4LINUX_OBJC_PROBES_H

#define OBJC_RUNTIME_OBJC_EXCEPTION_THROW(a0)      do { (void)(a0); } while (0)
#define OBJC_RUNTIME_OBJC_EXCEPTION_THROW_ENABLED()  (0)
#define OBJC_RUNTIME_OBJC_EXCEPTION_RETHROW()        do {} while (0)
#define OBJC_RUNTIME_OBJC_EXCEPTION_RETHROW_ENABLED()  (0)
#define OBJC_RUNTIME_LOAD_IMAGE(a0, a1, a2, a3)    do { (void)(a0); (void)(a1); (void)(a2); (void)(a3); } while (0)
#define OBJC_RUNTIME_LOAD_IMAGE_ENABLED()            (0)
#define OBJC_RUNTIME_FIRST_TIME_START()             do {} while (0)
#define OBJC_RUNTIME_FIRST_TIME_START_ENABLED()     (0)
#define OBJC_RUNTIME_FIRST_TIME_END()               do {} while (0)
#define OBJC_RUNTIME_FIRST_TIME_END_ENABLED()       (0)
#define OBJC_RUNTIME_FIXUP_SELECTORS_START()        do {} while (0)
#define OBJC_RUNTIME_FIXUP_SELECTORS_START_ENABLED()  (0)
#define OBJC_RUNTIME_FIXUP_SELECTORS_END()          do {} while (0)
#define OBJC_RUNTIME_FIXUP_SELECTORS_END_ENABLED()  (0)
#define OBJC_RUNTIME_DISCOVER_CLASSES_START()       do {} while (0)
#define OBJC_RUNTIME_DISCOVER_CLASSES_START_ENABLED()  (0)
#define OBJC_RUNTIME_DISCOVER_CLASSES_END()         do {} while (0)
#define OBJC_RUNTIME_DISCOVER_CLASSES_END_ENABLED()  (0)
#define OBJC_RUNTIME_REMAP_CLASSES_START()          do {} while (0)
#define OBJC_RUNTIME_REMAP_CLASSES_START_ENABLED()  (0)
#define OBJC_RUNTIME_REMAP_CLASSES_END()            do {} while (0)
#define OBJC_RUNTIME_REMAP_CLASSES_END_ENABLED()    (0)
#define OBJC_RUNTIME_FIXUP_VTABLES_START()          do {} while (0)
#define OBJC_RUNTIME_FIXUP_VTABLES_START_ENABLED()  (0)
#define OBJC_RUNTIME_FIXUP_VTABLES_END()            do {} while (0)
#define OBJC_RUNTIME_FIXUP_VTABLES_END_ENABLED()    (0)
#define OBJC_RUNTIME_DISCOVER_PROTOCOLS_START()     do {} while (0)
#define OBJC_RUNTIME_DISCOVER_PROTOCOLS_START_ENABLED()  (0)
#define OBJC_RUNTIME_DISCOVER_PROTOCOLS_END()       do {} while (0)
#define OBJC_RUNTIME_DISCOVER_PROTOCOLS_END_ENABLED()  (0)
#define OBJC_RUNTIME_FIXUP_PROTOCOLS_START()        do {} while (0)
#define OBJC_RUNTIME_FIXUP_PROTOCOLS_START_ENABLED()  (0)
#define OBJC_RUNTIME_FIXUP_PROTOCOLS_END()          do {} while (0)
#define OBJC_RUNTIME_FIXUP_PROTOCOLS_END_ENABLED()  (0)
#define OBJC_RUNTIME_DISCOVER_CATEGORIES_START()    do {} while (0)
#define OBJC_RUNTIME_DISCOVER_CATEGORIES_START_ENABLED()  (0)
#define OBJC_RUNTIME_DISCOVER_CATEGORIES_END()      do {} while (0)
#define OBJC_RUNTIME_DISCOVER_CATEGORIES_END_ENABLED()  (0)
#define OBJC_RUNTIME_REALIZE_NON_LAZY_CLASSES_START()  do {} while (0)
#define OBJC_RUNTIME_REALIZE_NON_LAZY_CLASSES_START_ENABLED()  (0)
#define OBJC_RUNTIME_REALIZE_NON_LAZY_CLASSES_END()  do {} while (0)
#define OBJC_RUNTIME_REALIZE_NON_LAZY_CLASSES_END_ENABLED()  (0)
#define OBJC_RUNTIME_REALIZE_FUTURE_CLASSES_START()  do {} while (0)
#define OBJC_RUNTIME_REALIZE_FUTURE_CLASSES_START_ENABLED()  (0)
#define OBJC_RUNTIME_REALIZE_FUTURE_CLASSES_END()   do {} while (0)
#define OBJC_RUNTIME_REALIZE_FUTURE_CLASSES_END_ENABLED()  (0)
#define OBJC_RUNTIME_CACHE_MISS(a0, a1, a2)        do { (void)(a0); (void)(a1); (void)(a2); } while (0)
#define OBJC_RUNTIME_CACHE_MISS_ENABLED()            (0)
#define OBJC_RUNTIME_CACHE_FLUSH(a0)               do { (void)(a0); } while (0)
#define OBJC_RUNTIME_CACHE_FLUSH_ENABLED()           (0)
#define OBJC_RUNTIME_AUTORELEASE_POOL_PUSH(a0)    do { (void)(a0); } while (0)
#define OBJC_RUNTIME_AUTORELEASE_POOL_PUSH_ENABLED()  (0)
#define OBJC_RUNTIME_AUTORELEASE_POOL_POP(a0)     do { (void)(a0); } while (0)
#define OBJC_RUNTIME_AUTORELEASE_POOL_POP_ENABLED()  (0)
#define OBJC_RUNTIME_AUTORELEASE_POOL_GROW(a0)    do { (void)(a0); } while (0)
#define OBJC_RUNTIME_AUTORELEASE_POOL_GROW_ENABLED()  (0)

#endif
