#ifndef OPEN_FOUNDATION_INTERNATIONALIZATION_OS_LOG_H
#define OPEN_FOUNDATION_INTERNATIONALIZATION_OS_LOG_H

/*
 * Apple ICU uses os_log only for exceptional diagnostics.  The Linux-hosted
 * Mach-O runtime has no os_log service, so preserve all ICU behavior while
 * making that diagnostic sink explicitly inert.
 */
typedef const void *os_log_t;
#define OS_LOG_DEFAULT ((os_log_t)0)

static inline void os_log(os_log_t log, const char *format, ...) {
    (void)log;
    (void)format;
}

#endif
