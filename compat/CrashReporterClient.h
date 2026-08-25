/*
 * compat/CrashReporterClient.h  --  objc4-linux
 *
 * Darwin stashes a message in the crash report. Linux core dumps have no such
 * slot; we keep the string in a global in a section named `objc_crashinfo` so
 * gdb/lldb can `p (char*)__objc_crash_message`. systemd-coredump and abrt
 * cannot see it. Accepted loss, recorded in docs/UNIMPLEMENTED.md.
 */
#ifndef _OBJC4LINUX_CRASHREPORTERCLIENT_H
#define _OBJC4LINUX_CRASHREPORTERCLIENT_H

#ifdef __cplusplus
extern "C" {
#endif

extern const char *__objc_crash_message;
const char *CRSetCrashLogMessage(const char *msg);
const char *CRGetCrashLogMessage(void);

#ifdef __cplusplus
}
#endif

#define CRASH_REPORTER_CLIENT_HIDDEN
#define CRSetCrashLogMessage2(msg) ((void)(msg))

#endif
