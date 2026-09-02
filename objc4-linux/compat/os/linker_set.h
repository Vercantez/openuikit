/*
 * compat/os/linker_set.h  --  objc4-linux
 *
 * Darwin's linker sets place entries in a named Mach-O section and expose the
 * bounds via `section$start$__DATA$<set>` symbols. ELF has the same facility:
 * for a section whose name is a valid C identifier, both GNU ld and lld
 * synthesise `__start_<name>` / `__stop_<name>`.
 *
 * objc4 has exactly ONE linker set, "__objc_dupclass" (objc-class.mm:918), so
 * this header supports that one by name rather than pretending to be generic.
 * The bounds are weak: if no image contributed an entry the section does not
 * exist, the symbols resolve to 0, and the loop body never runs -- which is
 * the same observable behaviour as an empty set on Darwin.
 *
 * ELF section name: `objc_dupclass` (Darwin's `__objc_dupclass` minus the
 * leading underscores), matching the clang/swiftc ELF naming convention
 * measured in docs/PORT_MAP.md 3.2.
 */
#ifndef _OBJC4LINUX_OS_LINKER_SET_H
#define _OBJC4LINUX_OS_LINKER_SET_H

#ifdef __cplusplus
extern "C" {
#endif
extern void *__start_objc_dupclass[] __attribute__((weak));
extern void *__stop_objc_dupclass[]  __attribute__((weak));
#ifdef __cplusplus
}
#endif

#define LINKER_SET_ENTRY(_set, _sym) \
    __attribute__((used, section("objc_dupclass"))) static const void *__linkerset_##_sym = &(_sym)

#define LINKER_SET_BEGIN(_set) ((void *)__start_objc_dupclass)
#define LINKER_SET_LIMIT(_set) ((void *)__stop_objc_dupclass)

#define LINKER_SET_FOREACH(_pvar, _type, _set)                   \
    for ((_pvar) = (_type)LINKER_SET_BEGIN(_set);                \
         (_pvar) != NULL && (_pvar) < (_type)LINKER_SET_LIMIT(_set); \
         (_pvar)++)

#endif
