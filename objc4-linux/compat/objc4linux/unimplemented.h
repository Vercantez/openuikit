/*
 * compat/objc4linux/unimplemented.h  --  objc4-linux
 *
 * Every hole in the port goes through here. There are NO silent stubs: a
 * feature we have not ported aborts with the file, line and function that
 * reached it, and has an entry in docs/UNIMPLEMENTED.md.
 */
#ifndef _OBJC4LINUX_UNIMPLEMENTED_H
#define _OBJC4LINUX_UNIMPLEMENTED_H

#ifdef __cplusplus
extern "C" {
#endif

__attribute__((noreturn, cold))
void objc4linux_unimplemented_(const char *file, int line, const char *func,
                               const char *what);

#define objc4linux_unimplemented(what) \
    objc4linux_unimplemented_(__FILE__, __LINE__, __func__, (what))

#ifdef __cplusplus
}
#endif

#endif
