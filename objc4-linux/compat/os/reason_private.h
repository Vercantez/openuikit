/* compat/os/reason_private.h -- objc4-linux.
 * abort_with_reason()/os_fault_with_payload() report a structured crash to
 * ReportCrash. Linux has no equivalent; we write the reason to stderr and
 * abort(). The reason code is preserved in the message so it stays greppable. */
#ifndef _OBJC4LINUX_OS_REASON_PRIVATE_H
#define _OBJC4LINUX_OS_REASON_PRIVATE_H
#include <stdint.h>
#ifdef __cplusplus
extern "C" {
#endif
__attribute__((noreturn))
void abort_with_reason(uint32_t reason_namespace, uint64_t reason_code,
                       const char *reason_string, uint64_t reason_flags);
void os_fault_with_payload(uint32_t reason_namespace, uint64_t reason_code,
                           void *payload, uint32_t payload_size,
                           const char *reason_string, uint64_t reason_flags);
#ifdef __cplusplus
}
#endif
#define OS_REASON_FLAG_NO_CRASH_REPORT      0x1
#define OS_REASON_FLAG_ONE_TIME_FAILURE     0x2
#define OS_REASON_FLAG_CONSISTENT_FAILURE   0x8
#endif
