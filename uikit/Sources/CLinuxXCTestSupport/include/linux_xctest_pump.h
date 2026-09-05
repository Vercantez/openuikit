#ifndef LINUX_XCTEST_PUMP_H
#define LINUX_XCTEST_PUMP_H

#ifdef __cplusplus
extern "C" {
#endif

/* Install the Linux XCTest CFRunLoop / main-queue pump. Idempotent.
 * Returns 1 once installed. The constructor in pump.c also calls this
 * before main; Swift references linux_xctest_pump_installed so the
 * object file is not GC'd. */
int linux_xctest_pump_install(void);
int linux_xctest_pump_installed(void);

#ifdef __cplusplus
}
#endif

#endif
