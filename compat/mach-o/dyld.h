/* compat/mach-o/dyld.h -- objc4-linux. Public dyld API surface objc4 names. */
#ifndef _OBJC4LINUX_MACHO_DYLD_H
#define _OBJC4LINUX_MACHO_DYLD_H
#include <mach-o/loader.h>
#include <stdint.h>
#ifdef __cplusplus
extern "C" {
#endif
uint32_t                  _dyld_image_count(void);
const struct mach_header *_dyld_get_image_header(uint32_t image_index);
intptr_t                  _dyld_get_image_vmaddr_slide(uint32_t image_index);
const char               *_dyld_get_image_name(uint32_t image_index);
void _dyld_register_func_for_add_image(void (*func)(const struct mach_header *mh, intptr_t vmaddr_slide));
void _dyld_register_func_for_remove_image(void (*func)(const struct mach_header *mh, intptr_t vmaddr_slide));
#ifdef __cplusplus
}
#endif
#endif
