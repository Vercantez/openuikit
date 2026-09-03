/* Expose CLOCK_REALTIME as clockid_t for FoundationEssentials.

   Clang modules compile Darwin headers with _POSIX_C_SOURCE and without
   _DARWIN_C_SOURCE, so Darwin time.h hides CLOCK_REALTIME. A textual
   `header "time.h"` then imports the token as Int, not clockid_t.
   FE (DispatchTime / CFExecutor) needs the Darwin clockid_t spelling.
   Do not put this in machorun/sdk; it is an x86 FE sysroot repair.
 */
#ifndef OPENUIKIT_FE_CLOCK_REALTIME_H
#define OPENUIKIT_FE_CLOCK_REALTIME_H

#include <time.h>

#ifdef CLOCK_REALTIME
#undef CLOCK_REALTIME
#endif

#ifdef __cplusplus
extern "C" {
#endif
static const clockid_t CLOCK_REALTIME = 0;
#ifdef __cplusplus
}
#endif

#endif
