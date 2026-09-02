/*
 * vendor/objc4-priv/os/linker_set.h
 *
 * Darwin's linker sets: entries go into a named Mach-O section and ld64
 * synthesises `section$start$<seg>$<sect>` / `section$end$...` symbols for the
 * bounds. This is the MACH-O spelling -- unlike the ELF port's shim, which had
 * to use ELF's `__start_<name>` / `__stop_<name>` and rename the section to a
 * valid C identifier. Here the section keeps Apple's own name.
 *
 * objc4 has exactly one linker set, "__objc_dupclass" (objc-class.mm:918).
 * The bounds are weak: if no image contributed an entry the symbols resolve to
 * 0 and the loop body never runs, which is what an empty set does on Darwin.
 */
#ifndef _OBJC4_PRIV_OS_LINKER_SET_H
#define _OBJC4_PRIV_OS_LINKER_SET_H

__BEGIN_DECLS
extern void *__objc_dupclass_start __asm__("section$start$__DATA$__objc_dupclass")
        __attribute__((weak_import));
extern void *__objc_dupclass_end   __asm__("section$end$__DATA$__objc_dupclass")
        __attribute__((weak_import));
__END_DECLS

#define LINKER_SET_ENTRY(_set, _sym) \
    __attribute__((used, section("__DATA," _set))) \
    static const void *__linkerset_##_sym = &(_sym)

#define LINKER_SET_BEGIN(_set) ((void *)&__objc_dupclass_start)
#define LINKER_SET_LIMIT(_set) ((void *)&__objc_dupclass_end)

#define LINKER_SET_FOREACH(_pvar, _type, _set)                       \
    for ((_pvar) = (_type)LINKER_SET_BEGIN(_set);                    \
         (_pvar) != NULL && (_pvar) < (_type)LINKER_SET_LIMIT(_set); \
         (_pvar)++)

#endif
