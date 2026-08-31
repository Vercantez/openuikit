#include "OpenFoundationInternationalizationABI.h"

#include <stddef.h>

extern int32_t host_realpath(
    uint32_t,
    const char *,
    char *,
    uint64_t
) __asm__("_glibc_openui_foundation_intl_v1_realpath");

/*
 * The pinned ICU asks Darwin libc to canonicalize /etc/localtime.  machorun's
 * reduced libSystem does not carry realpath, so keep that POSIX operation on
 * the Linux host behind a fixed-width, non-owning ABI.  ICU always supplies a
 * caller-owned PATH_MAX buffer; returning that same guest pointer preserves
 * Darwin realpath semantics without transferring a host pointer.
 */
__attribute__((visibility("default")))
char *realpath(const char *path, char *resolved_path)
{
    if (!path || !resolved_path) return NULL;
    if (host_realpath(
            OPENUI_FOUNDATION_INTL_ABI_VERSION,
            path,
            resolved_path,
            UINT64_C(1024)) != OPENUI_FOUNDATION_INTL_OK) {
        return NULL;
    }
    return resolved_path;
}
