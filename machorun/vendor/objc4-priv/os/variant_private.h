/* compat/os/variant_private.h -- objc4-linux.
 * Darwin distinguishes internal/customer OS builds. Linux does not; both
 * queries are false, i.e. we always behave like a customer build. */
#ifndef _OBJC4LINUX_OS_VARIANT_PRIVATE_H
#define _OBJC4LINUX_OS_VARIANT_PRIVATE_H
#include <stdbool.h>
static inline bool os_variant_has_internal_diagnostics(const char *subsystem __attribute__((unused))) { return false; }
static inline bool os_variant_allows_internal_security_policies(const char *subsystem __attribute__((unused))) { return false; }
static inline bool os_variant_is_darwinos(const char *subsystem __attribute__((unused))) { return false; }
#endif
