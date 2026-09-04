#ifndef _SYS_IOCTL_H_
#define _SYS_IOCTL_H_
/*
 * SwiftOverlayShims (Linux LibcOverlayShims.h) includes <sys/ioctl.h>.
 * Staging apple-oss overlay-posix ioctl.h defines FIONBIO/FIONREAD and
 * CFSocket.c compiles; the CF census then reports CANNOT_CFOBJC_OBJECTS
 * extra=CFSocket (foundation-macho/docs/cf-census/cfobjc-fail.txt).
 * This stub satisfies the include without those Darwin ioctl requests.
 */
int ioctl(int, unsigned long, ...);
#endif
