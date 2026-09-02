/*
 * compat/mach-o/ldsyms.h -- objc4-linux.
 * _mh_dylib_header is the link-editor-synthesised header of the containing
 * dylib. objc-os.h uses it as `libobjc_header`, i.e. "which image am I?".
 * On ELF we publish our own record for libobjc.so, filled in by
 * objc4linux_register_self() at library-constructor time.
 */
#ifndef _OBJC4LINUX_MACHO_LDSYMS_H
#define _OBJC4LINUX_MACHO_LDSYMS_H
#include <mach-o/loader.h>
#ifdef __cplusplus
extern "C" {
#endif
extern struct mach_header_64 _mh_dylib_header;
#ifdef __cplusplus
}
#endif
#endif
