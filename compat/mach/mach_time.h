/* compat/mach/mach_time.h -- objc4-linux.
 * mach_absolute_time() is a monotonic tick counter; clock_gettime(
 * CLOCK_MONOTONIC) is the direct equivalent and already in nanoseconds, so
 * the timebase numer/denom are 1/1. */
#ifndef _OBJC4LINUX_MACH_TIME_H
#define _OBJC4LINUX_MACH_TIME_H
#include <stdint.h>
#include <time.h>
#ifdef __cplusplus
extern "C" {
#endif
struct mach_timebase_info { uint32_t numer; uint32_t denom; };
typedef struct mach_timebase_info *mach_timebase_info_t;
typedef struct mach_timebase_info  mach_timebase_info_data_t;
static inline int mach_timebase_info(mach_timebase_info_t info) {
    info->numer = 1; info->denom = 1; return 0;
}
static inline uint64_t mach_absolute_time(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (uint64_t)1000000000 * (uint64_t)ts.tv_sec + (uint64_t)ts.tv_nsec;
}
#define mach_continuous_time mach_absolute_time
#ifdef __cplusplus
}
#endif
#endif
