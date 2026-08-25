/*
 * compat/mach-o/dyld_priv.h  --  objc4-linux
 *
 * The dyld SPI objc4 talks to, declared with Apple's exact signatures so that
 * the ~45 call sites in objc-os.h / objc-opt.mm / objc-runtime-new.mm compile
 * verbatim. The IMPLEMENTATIONS are ours and live in
 * compat/src/objc4linux-dyld.cpp -- backed by dl_iterate_phdr(3), dladdr(3)
 * and on-disk ELF section headers.
 *
 * Anything that only exists because of the dyld shared cache is declared here
 * but implemented as a loud abort; SUPPORT_PREOPT is 0 on Linux so those
 * declarations should never be reached. See docs/UNIMPLEMENTED.md.
 */
#ifndef _OBJC4LINUX_DYLD_PRIV_H
#define _OBJC4LINUX_DYLD_PRIV_H

#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>
#include <mach-o/loader.h>

/* Avoid a libuuid dependency for one 16-byte array. */
#ifndef _UUID_T
#define _UUID_T
typedef unsigned char uuid_t[16];
#endif

#ifdef __cplusplus
extern "C" {
#endif

/* ---- section location lookup -------------------------------------------
 * On Darwin dyld precomputes, per image, where each Objective-C section is,
 * and objc4 funnels every request through _dyld_lookup_section_info(). That
 * one function is the whole image-discovery seam (PORT_MAP 3.3). We keep the
 * interface and populate the table from ELF section headers instead.
 */

enum _dyld_section_location_kind {
    _dyld_section_location_data_class_list = 0,
    _dyld_section_location_data_non_lazy_class_list,
    _dyld_section_location_data_class_refs,
    _dyld_section_location_data_super_refs,
    _dyld_section_location_data_protocol_list,
    _dyld_section_location_data_protocol_refs,
    _dyld_section_location_data_sel_refs,
    _dyld_section_location_data_msg_refs,
    _dyld_section_location_data_category_list,
    _dyld_section_location_data_category_list2,
    _dyld_section_location_data_non_lazy_category_list,
    _dyld_section_location_data_stub_list,
    _dyld_section_location_data_objc_fork_ok,
    _dyld_section_location_data_raw_isa,
    _dyld_section_location_objc_image_info,

    _dyld_section_location_count,
};

/* Opaque to objc4: it only ever passes the pointer back to us. Ours is a
 * (start,size) table indexed by the enum above. */
struct _dyld_section_location_info_s;
/* NOTE: not a pointer-to-const. objc4 writes `const
 * _dyld_section_location_info_t` in several places, which must mean a const
 * *pointer*; making the pointee const here breaks every one of those calls. */
typedef struct _dyld_section_location_info_s *_dyld_section_location_info_t;

struct _dyld_section_info_result {
    void   *buffer;
    size_t  bufferSize;
};

struct _dyld_section_info_result
_dyld_lookup_section_info(const struct mach_header *mh,
                          _dyld_section_location_info_t info,
                          enum _dyld_section_location_kind kind);

/* ---- image registration callbacks -------------------------------------- */

struct _dyld_objc_notify_mapped_info {
    const struct mach_header    *mh;
    const char                  *path;
    _dyld_section_location_info_t sectionLocationMetadata;
    uint32_t                     dyldObjCRefsOptimized : 1;
    uint32_t                     dyldCategoriesOptimized : 1;
};

#if __BLOCKS__
typedef void (^_dyld_objc_mark_image_mutable)(uint32_t objcImageIndex);
#else
typedef void (*_dyld_objc_mark_image_mutable)(uint32_t objcImageIndex);
#endif

typedef void (*_dyld_objc_notify_mapped2)(unsigned count,
                                          const struct _dyld_objc_notify_mapped_info infos[],
                                          _dyld_objc_mark_image_mutable makeImageMutable);
typedef void (*_dyld_objc_notify_init2)(const struct _dyld_objc_notify_mapped_info *info);
typedef void (*_dyld_objc_notify_unmapped)(const char *path, const struct mach_header *mh);
typedef void (*_dyld_objc_notify_patch_class)(const struct mach_header *originalMH, void *originalClass,
                                              const struct mach_header *patchMH, const void *patchClass);

struct _dyld_objc_callbacks { uintptr_t version; };

struct _dyld_objc_callbacks_v4 {
    uintptr_t                      version;
    _dyld_objc_notify_mapped2      mapped;
    _dyld_objc_notify_init2        init;
    _dyld_objc_notify_unmapped     unmapped;
    _dyld_objc_notify_patch_class  patches;
};

void _dyld_objc_register_callbacks(const struct _dyld_objc_callbacks *callbacks);

/* ---- image identity ---------------------------------------------------- */

const struct mach_header *_dyld_get_prog_image_header(void);
const struct mach_header *dyld_image_header_containing_address(const void *addr);
const char               *dyld_image_path_containing_address(const void *addr);
const struct mach_header *_dyld_get_dlopen_image_header(void *handle);
bool                      _dyld_get_image_uuid(const struct mach_header *mh, uuid_t uuid);
bool                      _dyld_is_memory_immutable(const void *addr, size_t length);

/* ---- SDK version gating ------------------------------------------------
 * objc4 uses these purely for bug-compatibility with old Apple SDKs. There is
 * no legacy Linux ObjC ABI to be compatible with, so our implementation always
 * takes the modern branch. dyld_build_version_t values are inert.
 */
typedef struct { uint32_t platform; uint32_t version; } dyld_build_version_t;

extern const dyld_build_version_t dyld_platform_version_macOS_10_11;
extern const dyld_build_version_t dyld_platform_version_macOS_10_13;
extern const dyld_build_version_t dyld_fall_2018_os_versions;
extern const dyld_build_version_t dyld_fall_2020_os_versions;

bool     dyld_program_sdk_at_least(dyld_build_version_t version);
uint32_t dyld_get_active_platform(void);

/* ---- shared cache: does not exist on Linux -----------------------------
 * Declared so SUPPORT_PREOPT-guarded code still parses. Every definition
 * aborts via objc4linux_unimplemented().
 */
bool dyld_shared_cache_some_image_overridden(void);
bool _dyld_get_shared_cache_range(size_t *length, const void **address);
const char *_dyld_get_objc_selector(const char *selName);
void _dyld_for_each_objc_class(const char *className,
                               void (^callback)(void *classPtr, bool isLoaded, bool *stop));
void _dyld_for_each_objc_protocol(const char *protocolName,
                                  void (^callback)(void *protoPtr, bool isLoaded, bool *stop));
void _dyld_for_objc_header_opt_ro(void (^callback)(const void *hdrOptRO));
void _dyld_for_objc_header_opt_rw(void (^callback)(void *hdrOptRW));
uint32_t _dyld_objc_class_count(void);

#ifdef __cplusplus
}
#endif

#endif
