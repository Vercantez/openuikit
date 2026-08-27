/* hostclock.c -- a monotonic wall clock and a sleep, for the run loop.
 *
 * OpenUIKit deliberately owns no clock: UIWindow.tick(timestamp:) takes the
 * time from its host, which is what keeps scripted captures deterministic
 * (openhost feeds it SDL_GetTicks; openrender sets it by hand). A run loop is
 * just the host that feeds it REAL time, so the only new primitives needed are
 * "what time is it" and "sleep until".
 *
 * CLOCK_MONOTONIC, not wall time: the frame clock must not jump when the
 * system clock is adjusted, and UIKit's animation timings are durations rather
 * than dates. Darwin's CLOCK_MONOTONIC is 6, and machorun's libSystem forwards
 * clock_gettime to glibc, whose CLOCK_MONOTONIC is 1 -- so the constant is
 * NOT portable across the boundary and is passed as the value the guest's
 * libSystem expects.
 */
#include "hostclock.h"
#include <time.h>

double mr_monotonic_seconds(void)
{
    struct timespec ts;
    if (clock_gettime(CLOCK_MONOTONIC, &ts) != 0) return 0.0;
    return (double)ts.tv_sec + (double)ts.tv_nsec * 1e-9;
}

void mr_sleep_seconds(double s)
{
    if (s <= 0) return;
    struct timespec req;
    req.tv_sec = (long)s;
    req.tv_nsec = (long)((s - (double)req.tv_sec) * 1e9);
    if (req.tv_nsec < 0) req.tv_nsec = 0;
    if (req.tv_nsec > 999999999) req.tv_nsec = 999999999;
    /* Restart on EINTR: a short sleep that returns early would silently make
     * the loop run fast, which is exactly the failure the frame-pacing test
     * exists to catch. */
    while (nanosleep(&req, &req) != 0) { }
}
