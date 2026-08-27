#ifndef MR_HOSTCLOCK_H
#define MR_HOSTCLOCK_H
/* Monotonic seconds since an arbitrary epoch. Never jumps. */
double mr_monotonic_seconds(void);
/* Sleep for `s` seconds, restarting on EINTR. */
void mr_sleep_seconds(double s);
#endif
