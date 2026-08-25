/* compat/os/bsd.h -- objc4-linux. Boot-args parsing; not applicable. */
#ifndef _OBJC4LINUX_OS_BSD_H
#define _OBJC4LINUX_OS_BSD_H
#include <stdbool.h>
#include <stddef.h>
static inline bool os_parse_boot_arg_int(const char *a __attribute__((unused)), int64_t *v __attribute__((unused))) { return false; }
#endif
