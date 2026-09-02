/*
 * compat/os/feature_private.h -- objc4-linux.
 *
 * Darwin's runtime feature flags come from objc4.plist via os_feature. Linux
 * has no such service. We read the same names from the environment
 * (OBJC_FEATURE_<name>=0/1) and otherwise take the shipped default, which is
 * the caller-supplied `default_value`.
 */
#ifndef _OBJC4LINUX_OS_FEATURE_PRIVATE_H
#define _OBJC4LINUX_OS_FEATURE_PRIVATE_H
#include <stdbool.h>
#ifdef __cplusplus
extern "C" {
#endif
bool objc4linux_feature_enabled(const char *subsystem, const char *feature, bool default_value);
#ifdef __cplusplus
}
#endif
#define os_feature_enabled_simple(subsystem, feature, default_value) \
    objc4linux_feature_enabled(#subsystem, #feature, (default_value))
#endif
