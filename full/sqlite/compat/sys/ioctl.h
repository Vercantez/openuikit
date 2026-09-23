/* The one declaration sqlite3.c takes from <sys/ioctl.h>, which the guest's
 * Darwin compile sysroot (sysroot_fe4) does not carry. Found with -idirafter,
 * so a sysroot that has the real header wins. sqlite3.c only issues ioctl()
 * for Linux F2FS atomic writes, which a Darwin build never compiles; the
 * pointer still sits in its syscall table, so the prototype must match
 * Darwin's: int ioctl(int, unsigned long, ...). */
#ifndef OPENUIKIT_SQLITE_COMPAT_SYS_IOCTL_H
#define OPENUIKIT_SQLITE_COMPAT_SYS_IOCTL_H
#ifdef __cplusplus
extern "C" {
#endif
int ioctl(int, unsigned long, ...);
#ifdef __cplusplus
}
#endif
#endif
