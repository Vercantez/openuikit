/*
 * compat/mach-o/getsect.h -- objc4-linux.
 *
 * getsectiondata()/getsegmentdata() walk Mach-O load commands. ELF has no
 * mapped section table at runtime (only program headers), so there is no
 * direct equivalent; objc4-linux reads section headers from the file at
 * registration time and answers from a cached table instead
 * (compat/src/objc4linux-elfsections.cpp). These declarations exist so that
 * headers naming them parse; the definitions abort loudly.
 */
#ifndef _OBJC4LINUX_MACHO_GETSECT_H
#define _OBJC4LINUX_MACHO_GETSECT_H
#include <mach-o/loader.h>
#include <stdint.h>
#ifdef __cplusplus
extern "C" {
#endif
uint8_t *getsectiondata(const struct mach_header_64 *mhp, const char *segname,
                        const char *sectname, unsigned long *size);
uint8_t *getsegmentdata(const struct mach_header_64 *mhp, const char *segname,
                        unsigned long *size);
const struct section_64 *getsectbynamefromheader_64(const struct mach_header_64 *mhp,
                        const char *segname, const char *sectname);
#ifdef __cplusplus
}
#endif
#endif
