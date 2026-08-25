/* compat/mach-o/nlist.h -- objc4-linux. Mach-O symbol table entries; only
 * named by code compiled out. */
#ifndef _OBJC4LINUX_MACHO_NLIST_H
#define _OBJC4LINUX_MACHO_NLIST_H
#include <stdint.h>
struct nlist_64 { union { uint32_t n_strx; } n_un; uint8_t n_type, n_sect;
                  uint16_t n_desc; uint64_t n_value; };
#endif
