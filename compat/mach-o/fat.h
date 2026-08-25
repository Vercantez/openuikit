/* compat/mach-o/fat.h -- objc4-linux. Universal binaries do not exist here;
 * the only consumer is objc-runtime.mm's sliceRequiresGC(), which is compiled
 * out (SUPPORT_GC_COMPAT 0). */
#ifndef _OBJC4LINUX_MACHO_FAT_H
#define _OBJC4LINUX_MACHO_FAT_H
#include <stdint.h>
#define FAT_MAGIC 0xcafebabeu
#define FAT_CIGAM 0xbebafecau
struct fat_header { uint32_t magic; uint32_t nfat_arch; };
struct fat_arch   { int32_t cputype, cpusubtype; uint32_t offset, size, align; };
#endif
