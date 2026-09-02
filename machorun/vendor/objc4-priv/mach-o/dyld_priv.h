/*
 * vendor/objc4-priv/mach-o/dyld_priv.h
 *
 * The dyld SPI objc4 talks to. Apple ships this only in the internal SDK.
 * Declared with Apple's exact signatures so that every call site in
 * objc-os.h / objc-os.mm / objc-opt.mm / objc-runtime-new.mm compiles verbatim.
 *
 * THIS IS THE SEAM. On Darwin, dyld drives objc4: it calls _objc_init, and
 * objc4 answers by handing dyld a table of callbacks through
 * _dyld_objc_register_callbacks(). dyld then calls `mapped` for each batch of
 * images and `init` before each image's initialisers run. machorun implements
 * exactly that protocol -- see src/objc_notify.c -- rather than inventing a
 * registration mechanism of its own, because this one is the mechanism objc4
 * already expects and it is image-format-agnostic only by accident: every
 * argument here is a Mach-O `struct mach_header *`.
 *
 * Derived from the declarations in ~/objc4-linux/compat/mach-o/dyld_priv.h,
 * which is the piece of that port that transfers to Mach-O unchanged.
 */
#ifndef _OBJC4_PRIV_MACH_O_DYLD_PRIV_H
#define _OBJC4_PRIV_MACH_O_DYLD_PRIV_H

#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>
#include <mach-o/loader.h>
#include <mach-o/dyld.h>
#include <uuid/uuid.h>
#include <Availability.h>

__BEGIN_DECLS

/* ---- section location lookup -------------------------------------------
 * dyld precomputes, per image, where each Objective-C section is, and objc4
 * funnels every request through _dyld_lookup_section_info(). That one
 * function is the whole image-discovery seam.
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

/* Opaque to objc4: it only ever passes the pointer back. Not a
 * pointer-to-const -- objc4 writes `const _dyld_section_location_info_t` in
 * several places, which must mean a const *pointer*. */
struct _dyld_section_location_info_s;
typedef struct _dyld_section_location_info_s *_dyld_section_location_info_t;

struct _dyld_section_info_result {
    void   *buffer;
    size_t  bufferSize;
};

extern struct _dyld_section_info_result
_dyld_lookup_section_info(const struct mach_header *mh,
                          _dyld_section_location_info_t info,
                          enum _dyld_section_location_kind kind);

/* ---- image registration callbacks -------------------------------------- */

struct _dyld_objc_notify_mapped_info {
    const struct mach_header     *mh;
    const char                   *path;
    _dyld_section_location_info_t  sectionLocationMetadata;
    uint32_t                      dyldObjCRefsOptimized : 1;
    uint32_t                      dyldCategoriesOptimized : 1;
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
typedef void (*_dyld_objc_notify_patch_class)(const struct mach_header *originalMH,
                                              void *originalClass,
                                              const struct mach_header *patchMH,
                                              const void *patchClass);

struct _dyld_objc_callbacks { uintptr_t version; };

struct _dyld_objc_callbacks_v4 {
    uintptr_t                     version;      /* == 4 */
    _dyld_objc_notify_mapped2     mapped;
    _dyld_objc_notify_init2       init;
    _dyld_objc_notify_unmapped    unmapped;
    _dyld_objc_notify_patch_class patches;
};

extern void _dyld_objc_register_callbacks(const struct _dyld_objc_callbacks *callbacks);

extern void _dyld_objc_mark_image_mutable_fn(uint32_t objcImageIndex);

/* ---- image identity ---------------------------------------------------- */

extern const struct mach_header *_dyld_get_prog_image_header(void);
extern const struct mach_header *dyld_image_header_containing_address(const void *addr);
extern const char               *dyld_image_path_containing_address(const void *addr);
extern const struct mach_header *_dyld_get_dlopen_image_header(void *handle);
extern bool  _dyld_get_image_uuid(const struct mach_header *mh, uuid_t uuid);
extern bool  _dyld_is_memory_immutable(const void *addr, size_t length);

/* ---- SDK version gating ------------------------------------------------
 * objc4 uses these only for bug-compatibility with programs built against old
 * Apple SDKs. Every guest machorun runs was built against a modern one.
 */
typedef struct { uint32_t platform; uint32_t version; } dyld_build_version_t;

extern const dyld_build_version_t dyld_platform_version_macOS_10_11;
extern const dyld_build_version_t dyld_platform_version_macOS_10_12;
extern const dyld_build_version_t dyld_platform_version_macOS_10_13;
extern const dyld_build_version_t dyld_platform_version_iOS_10_0;
extern const dyld_build_version_t dyld_platform_version_tvOS_10_0;
extern const dyld_build_version_t dyld_platform_version_watchOS_3_0;
extern const dyld_build_version_t dyld_platform_version_bridgeOS_2_0;
extern const dyld_build_version_t dyld_fall_2018_os_versions;
extern const dyld_build_version_t dyld_fall_2020_os_versions;

extern bool     dyld_program_sdk_at_least(dyld_build_version_t version);
extern uint32_t dyld_get_active_platform(void);

/* ---- shared cache: there is none under machorun ------------------------
 * Declared so the SUPPORT_PREOPT-guarded code parses. machorun's libobjc is
 * built with SUPPORT_PREOPT 0, so none of these is reached; each definition
 * in libSystem aborts loudly if one ever is.
 */
extern bool dyld_shared_cache_some_image_overridden(void);
extern bool _dyld_get_shared_cache_range(size_t *length, const void **address);
extern const char *_dyld_get_objc_selector(const char *selName);
extern void _dyld_for_each_objc_class(const char *className,
                                      void (^callback)(void *classPtr, bool isLoaded, bool *stop));
extern void _dyld_for_each_objc_protocol(const char *protocolName,
                                         void (^callback)(void *protoPtr, bool isLoaded, bool *stop));
extern void _dyld_for_objc_header_opt_ro(void (^callback)(const void *hdrOptRO));
extern void _dyld_for_objc_header_opt_rw(void (^callback)(void *hdrOptRW));
extern uint32_t _dyld_objc_class_count(void);

__END_DECLS

#endif
