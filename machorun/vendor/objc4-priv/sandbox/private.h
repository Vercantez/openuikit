/*
 * compat/sandbox/private.h  --  objc4-linux
 *
 * objc-errors.mm asks the sandbox whether it may write to the syslog socket
 * before doing so. Linux has no equivalent query (seccomp/LSM policy is not
 * introspectable this way), and we do not use syslog anyway -- _objc_inform
 * writes to stderr. sandbox_check() returning 0 means "not denied", which is
 * the branch that leads to our stderr path.
 */
#ifndef _OBJC4LINUX_SANDBOX_PRIVATE_H
#define _OBJC4LINUX_SANDBOX_PRIVATE_H
#define SANDBOX_FILTER_NONE   0
#define SANDBOX_FILTER_PATH   1
#define SANDBOX_CHECK_NO_REPORT (1 << 31)
static inline int sandbox_check(int pid __attribute__((unused)),
                                const char *op __attribute__((unused)),
                                int type, ...) { (void)type; return 0; }
#endif
