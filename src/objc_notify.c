/* objc_notify.c -- the dyld side of the Objective-C runtime interface.
 *
 * This is not a shim invented for machorun. It is dyld's OWN protocol, the one
 * Apple's objc4 already expects, implemented here because machorun IS dyld for
 * these images:
 *
 *   1. Someone calls _objc_init().  On macOS that is libSystem's initializer,
 *      not a constructor in libobjc -- libobjc.A.dylib has no __mod_init_func
 *      and no __TEXT,__init_offsets (verified with otool on the dylib we
 *      build). We call it at the same point: after our own darwin/ dylibs are
 *      initialised, before any guest initialiser.
 *
 *   2. _objc_init() calls _dyld_objc_register_callbacks(&v4), handing us four
 *      function pointers: mapped, init, unmapped, patches.
 *
 *   3. We must then call `mapped` for every already-loaded image carrying
 *      Objective-C metadata -- SYNCHRONOUSLY, inside the registration call,
 *      which is what dyld does. `mapped` is objc4's map_images(): it reads
 *      __objc_classlist and friends and realizes classes.
 *
 *   4. Before each image's own initialisers run we call `init` for that image.
 *      That is objc4's load_images(), which dispatches +load. The ordering
 *      matters: a +load must be able to message a class from any image that
 *      has already been mapped, and must run before the C++/C constructors of
 *      its own image.
 *
 * objc4 never parses the Mach-O itself for these sections; it asks
 * _dyld_lookup_section_info(). So that one function is the whole
 * image-discovery seam, and it is where the Mach-O bet pays off: the answer is
 * a straight walk of the load commands we already parsed.
 *
 * Contrast with ~/objc4-linux, which had to REPLACE this: it enumerates images
 * with dl_iterate_phdr(3), reads on-disk ELF section headers, and manufactures
 * a fake `struct mach_header_64` for objc4 to cast back to. Here there is
 * nothing to fake -- the images really are Mach-O.
 */
#define _GNU_SOURCE
#include "machorun.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* ------------------------------------------------------------------ types
 * Mirrors of the declarations in vendor/objc4-priv/mach-o/dyld_priv.h. The two
 * must agree; they are checked against each other only by the link, so keep
 * them adjacent in review. */

enum dyld_section_kind {
    K_class_list = 0, K_non_lazy_class_list, K_class_refs, K_super_refs,
    K_protocol_list, K_protocol_refs, K_sel_refs, K_msg_refs,
    K_category_list, K_category_list2, K_non_lazy_category_list,
    K_stub_list, K_objc_fork_ok, K_raw_isa, K_image_info,
    K_COUNT
};

/* The Mach-O section name for each kind. dyld hardcodes exactly this table;
 * so do we. A kind with no name here has no section and reports empty. */
static const char *const kind_sectname[K_COUNT] = {
    [K_class_list]             = "__objc_classlist",
    [K_non_lazy_class_list]    = "__objc_nlclslist",
    [K_class_refs]             = "__objc_classrefs",
    [K_super_refs]             = "__objc_superrefs",
    [K_protocol_list]          = "__objc_protolist",
    [K_protocol_refs]          = "__objc_protorefs",
    [K_sel_refs]               = "__objc_selrefs",
    [K_msg_refs]               = "__objc_msgrefs",
    [K_category_list]          = "__objc_catlist",
    [K_category_list2]         = "__objc_catlist2",
    [K_non_lazy_category_list] = "__objc_nlcatlist",
    [K_stub_list]              = "__objc_stublist",
    [K_objc_fork_ok]           = "__objc_fork_ok",
    [K_raw_isa]                = "__objc_rawisa",
    [K_image_info]             = "__objc_imageinfo",
};

struct section_info_result { void *buffer; size_t bufferSize; };

/* Opaque to objc4: it only hands the pointer back to us. We use the mr_image. */
struct _dyld_section_location_info_s;

struct objc_mapped_info {
    const void *mh;
    const char *path;
    struct _dyld_section_location_info_s *sectionLocationMetadata;
    uint32_t    dyldObjCRefsOptimized : 1;
    uint32_t    dyldCategoriesOptimized : 1;
};

typedef void (*notify_mapped2)(unsigned count, const struct objc_mapped_info infos[],
                               void *makeImageMutable);
typedef void (*notify_init2)(const struct objc_mapped_info *info);
typedef void (*notify_unmapped)(const char *path, const void *mh);
typedef void (*notify_patch_class)(const void *omh, void *ocls, const void *pmh, const void *pcls);

struct objc_callbacks_v4 {
    uintptr_t          version;
    notify_mapped2     mapped;
    notify_init2       init;
    notify_unmapped    unmapped;
    notify_patch_class patches;
};

/* ------------------------------------------------------------------ state */
static struct objc_callbacks_v4 CB;
static int CB_registered;

/* An image "has ObjC" iff it has __objc_imageinfo, which is exactly the test
 * dyld uses to decide whether to include it in the mapped batch. */
static int image_has_objc(const mr_image *im)
{
    return mr_image_section(im, NULL, "__objc_imageinfo") != NULL;
}

/* ------------------------------------------------- _dyld_lookup_section_info */
/* Find `sectname` in any segment. objc4's own foreach_data_segment()
 * (runtime/objc-file.h) scans every segment whose name starts with "__DATA" or
 * "__AUTH"; we scan all of them, which is a superset, so there is no section
 * objc4 can see that we cannot. */
struct section_info_result
_dyld_lookup_section_info(const void *mh,
                          struct _dyld_section_location_info_s *info,
                          enum dyld_section_kind kind)
{
    struct section_info_result r = { NULL, 0 };
    const mr_image *im = (const mr_image *)info;

    if (!im || (unsigned)kind >= K_COUNT) return r;
    if ((uint64_t)(uintptr_t)mh != im->load_base)
        mr_die("_dyld_lookup_section_info: header 0x%llx does not match the image "
               "record for %s (base 0x%llx). objc4 passes back the pointer we gave it, "
               "so this means our mapped_info was built wrong.",
               (unsigned long long)(uintptr_t)mh, im->path,
               (unsigned long long)im->load_base);

    const char *want = kind_sectname[kind];
    if (!want) return r;

    const struct section_64 *sec = mr_image_section(im, NULL, want);
    if (!sec) return r;

    r.buffer     = (void *)(uintptr_t)(sec->addr + (uint64_t)im->slide);
    r.bufferSize = (size_t)sec->size;
    return r;
}

/* --------------------------------------------------- makeImageMutable block
 *
 * `mapped` takes a third argument: a BLOCK that objc4 calls as
 * makeImageMutable(imageIndex) when it needs to write into an image whose
 * __DATA_CONST we have already made read-only. objc4 does that while patching
 * class references and Swift metadata.
 *
 * Passing NULL here is what a first draft does, and it is a SIGSEGV at
 * `ldr x8, [x21, #0x10]` inside _read_images -- offset 0x10 of a block is its
 * `invoke` pointer. So this is a real block, hand-built to the Blocks ABI
 * because the loader is plain C: {isa, flags, reserved, invoke, descriptor}.
 * objc4 only ever invokes it, never copies or releases it, so BLOCK_IS_GLOBAL
 * with a null isa is sufficient and a copy would be a bug we want to see.
 */
#define BLOCK_IS_GLOBAL (1 << 28)

struct mr_block_descriptor { unsigned long reserved, size; };
struct mr_block {
    void *isa;
    int   flags;
    int   reserved;
    void (*invoke)(void *blk, uint32_t index);
    const struct mr_block_descriptor *descriptor;
};

/* The batch we last handed to `mapped`, so an index can be turned back into an
 * image. dyld indexes by position in the infos[] array. */
static mr_image **batch;
static size_t     batch_capacity;
static unsigned  batch_n;

static void mark_image_mutable(void *blk, uint32_t index)
{
    (void)blk;
    if (index >= batch_n)
        mr_die("makeImageMutable(%u): only %u images were in the mapped batch",
               index, batch_n);

    mr_image *im = batch[index];
    for (int i = 0; i < im->nsegs; i++) {
        const mr_segment *s = &im->segs[i];
        if (!(s->flags & SG_READ_ONLY) || s->vmsize == 0) continue;
        uint64_t addr = s->vmaddr + (uint64_t)im->slide;
        if (mr_mprotect_rw((void *)(uintptr_t)addr, s->vmsize) != 0)
            mr_die("%s: makeImageMutable could not restore write access to %s",
                   im->path, s->name);
        mr_log("  %s: %s back to rw- (objc asked to patch it)", im->path, s->name);
    }
    /* Deliberately NOT re-protected afterwards. dyld keeps such an image
     * mutable for the rest of the process too -- the point of the callback is
     * that objc4 owns those pages from here on. */
}

static const struct mr_block_descriptor mutable_desc = { 0, sizeof(struct mr_block) };
static struct mr_block make_mutable_block = {
    NULL, BLOCK_IS_GLOBAL, 0, mark_image_mutable, &mutable_desc
};

/* ------------------------------------------------ registration and dispatch */
/* `from` is the index to start at: 0 for the startup batch, and MR.nimages as
 * it stood before a dlopen for the images that call brought in. Delivering the
 * whole table again on a dlopen would hand objc4 classes it has already
 * realized, and objc4 asserts on that rather than ignoring it.
 *
 * batch[] is rebuilt per call because makeImageMutable indexes into THIS
 * delivery's infos[], not into MR.images. */
static void deliver_mapped_from(int from)
{
    struct objc_mapped_info *infos;
    size_t available;
    size_t infos_capacity = 0;
    unsigned n = 0;

    if (from < 0 || from > MR.nimages)
        mr_die("objc mapped-batch start %d is outside the %d-image table",
               from, MR.nimages);
    available = (size_t)(MR.nimages - from);
    infos = mr_grow_array(NULL, &infos_capacity, available,
                          sizeof(*infos), "Objective-C mapped-image metadata");
    batch = mr_grow_array(batch, &batch_capacity, available,
                          sizeof(*batch), "Objective-C mapped-image batch");

    for (int i = from; i < MR.nimages; i++) {
        mr_image *im = MR.images[i];
        if (!image_has_objc(im)) continue;
        if (im->objc_mapped) continue;
        infos[n].mh   = (const void *)(uintptr_t)im->load_base;
        infos[n].path = im->install_name ? im->install_name : im->path;
        infos[n].sectionLocationMetadata = (struct _dyld_section_location_info_s *)im;
        infos[n].dyldObjCRefsOptimized   = 0;   /* no shared cache: nothing was */
        infos[n].dyldCategoriesOptimized = 0;   /* pre-attached by the builder  */
        im->objc_mapped = 1;
        batch[n] = im;
        n++;
    }
    batch_n = n;

    mr_log("objc: delivering map_images for %u image(s)", n);
    if (n && CB.mapped) CB.mapped(n, infos, &make_mutable_block);
    free(infos);
}

static void deliver_mapped(void) { deliver_mapped_from(0); }

/* The dlopen half: tell objc4 about images that arrived after startup, then let
 * mr_run_initialisers deliver load_images (+load) for each. */
void mr_objc_note_new_images(int from) { if (CB_registered) deliver_mapped_from(from); }

void _dyld_objc_register_callbacks(const void *callbacks);
void _dyld_objc_register_callbacks(const void *callbacks)
{
    const struct objc_callbacks_v4 *v = callbacks;

    if (!v) mr_die("_dyld_objc_register_callbacks(NULL)");
    if (v->version != 4)
        mr_unimplemented("objc-callbacks-version",
                         "libobjc registered _dyld_objc_callbacks version %llu; machorun "
                         "implements version 4 only. The struct layout differs per version, "
                         "so guessing would corrupt the function pointers.",
                         (unsigned long long)v->version);
    if (CB_registered)
        mr_die("_dyld_objc_register_callbacks called twice");

    CB = *v;
    CB_registered = 1;
    mr_log("objc: callbacks registered (v4) mapped=%p init=%p",
           (void *)CB.mapped, (void *)CB.init);

    /* dyld delivers the existing images synchronously from inside the
     * registration call, before returning to _objc_init. objc4 relies on that:
     * by the time _objc_init returns, every class in every loaded image is
     * realized. */
    deliver_mapped();
}

/* Called by mr_run_initialisers immediately before an image's own
 * initialisers. This is load_images(): +load runs here. */
void mr_objc_note_image(mr_image *im)
{
    if (!image_has_objc(im)) return;

    if (!CB_registered)
        mr_unimplemented("objc-callbacks",
                         "%s carries __objc_imageinfo, but no libobjc has registered "
                         "dyld callbacks. Either darwin/usr/lib/libobjc.A.dylib is "
                         "missing, or it did not call _dyld_objc_register_callbacks from "
                         "_objc_init. Classes would never be registered and objc_msgSend "
                         "would fault.", im->path);

    if (!im->objc_mapped)
        mr_die("%s: load_images before map_images -- the image was not in the mapped "
               "batch. That is a machorun ordering bug, not an objc4 one.", im->path);
    if (im->objc_inited) return;
    im->objc_inited = 1;

    struct objc_mapped_info info;
    info.mh   = (const void *)(uintptr_t)im->load_base;
    info.path = im->install_name ? im->install_name : im->path;
    info.sectionLocationMetadata = (struct _dyld_section_location_info_s *)im;
    info.dyldObjCRefsOptimized = 0;
    info.dyldCategoriesOptimized = 0;

    mr_log("objc: load_images for %s", im->path);
    if (CB.init) CB.init(&info);
}

/* _objc_init: on macOS libSystem's initializer calls this. We do it at the
 * same point. Returns 0 if there is no libobjc loaded, which is the normal
 * case for every non-ObjC fixture. */
int mr_objc_run_objc_init(void)
{
    for (int i = 0; i < MR.nimages; i++) {
        mr_image *im = MR.images[i];
        if (!im->install_name) continue;
        if (strcmp(im->install_name, "/usr/lib/libobjc.A.dylib") != 0) continue;

        uint64_t addr = 0;
        if (!mr_exports_lookup(im, "__objc_init", &addr))
            mr_die("%s does not export _objc_init. machorun calls it where Darwin's "
                   "libSystem initializer does, because libobjc.A.dylib carries no "
                   "initialiser section of its own.", im->path);
        mr_log("objc: calling _objc_init at 0x%llx", (unsigned long long)addr);
        ((void (*)(void))(uintptr_t)addr)();
        return 1;
    }
    return 0;
}

/* ------------------------------------------------------- image identity SPI */
const void *_dyld_get_prog_image_header(void);
const void *_dyld_get_prog_image_header(void)
{
    return MR.main_image ? (const void *)(uintptr_t)MR.main_image->load_base : NULL;
}

#define image_containing(a) mr_image_containing(a)

const void *dyld_image_header_containing_address(const void *addr);
const void *dyld_image_header_containing_address(const void *addr)
{
    mr_image *im = image_containing(addr);
    return im ? (const void *)(uintptr_t)im->load_base : NULL;
}

const char *dyld_image_path_containing_address(const void *addr);
const char *dyld_image_path_containing_address(const void *addr)
{
    mr_image *im = image_containing(addr);
    if (!im) return NULL;
    return im->install_name ? im->install_name : im->path;
}

const void *_dyld_get_dlopen_image_header(void *handle);
const void *_dyld_get_dlopen_image_header(void *handle)
{
    /* A machorun dlopen handle IS the mr_image *, so this is a field read.
     * objc4 calls it from its dlopen path to find the header of what was just
     * loaded. */
    if (handle && mr_addr_in_image(handle) == 0) {
        for (int i = 0; i < MR.nimages; i++)
            if (MR.images[i] == (mr_image *)handle)
                return (const void *)(uintptr_t)MR.images[i]->load_base;
    }
    mr_unimplemented("dlopen",
                     "_dyld_get_dlopen_image_header(%p): machorun has no dlopen yet, so "
                     "there is no handle this could describe. See docs/UNIMPLEMENTED.md.",
                     handle);
}

int _dyld_get_image_uuid(const void *mh, unsigned char uuid[16]);
int _dyld_get_image_uuid(const void *mh, unsigned char uuid[16])
{
    mr_image *im = image_containing(mh);
    if (!im) return 0;
    const struct load_command *lc = (const struct load_command *)(im->mh + 1);
    for (uint32_t i = 0; i < im->mh->ncmds; i++) {
        if (lc->cmd == LC_UUID) {
            memcpy(uuid, (const unsigned char *)lc + 8, 16);
            return 1;
        }
        lc = (const struct load_command *)((const char *)lc + lc->cmdsize);
    }
    return 0;
}

int _dyld_is_memory_immutable(const void *addr, size_t length);
int _dyld_is_memory_immutable(const void *addr, size_t length)
{
    /* "Will this memory never change and never be unmapped?" objc4 uses it to
     * decide whether it may keep a pointer to a caller's string instead of
     * copying. Answering NO is always safe -- it costs a copy. Answering yes
     * wrongly is a use-after-free, so we do not try to be clever until there
     * is a fixture that measures the difference. */
    (void)addr; (void)length;
    return 0;
}

/* getsegmentdata(3) -- <mach-o/getsect.h>. objc4 uses it in _headerForAddress. */
uint8_t *getsegmentdata(const void *mh, const char *segname, unsigned long *size);
uint8_t *getsegmentdata(const void *mh, const char *segname, unsigned long *size)
{
    mr_image *im = image_containing(mh);
    if (!im) { if (size) *size = 0; return NULL; }
    const mr_segment *s = mr_image_segment(im, segname);
    if (!s) { if (size) *size = 0; return NULL; }
    if (size) *size = (unsigned long)s->vmsize;
    return (uint8_t *)(uintptr_t)(s->vmaddr + (uint64_t)im->slide);
}

/* ------------------------------------------------------------ SDK gating */
/* objc4 consults these only for bug-compatibility with programs linked against
 * old Apple SDKs. Everything machorun runs was built against a modern one, so
 * "at least" is always true and the modern branch is always taken. */
typedef struct { uint32_t platform; uint32_t version; } dyld_build_version_t;

const dyld_build_version_t dyld_platform_version_macOS_10_11   = { 1, 0x000A0B00 };
const dyld_build_version_t dyld_platform_version_macOS_10_12   = { 1, 0x000A0C00 };
const dyld_build_version_t dyld_platform_version_macOS_10_13   = { 1, 0x000A0D00 };
const dyld_build_version_t dyld_platform_version_iOS_10_0      = { 2, 0x000A0000 };
const dyld_build_version_t dyld_platform_version_tvOS_10_0     = { 3, 0x000A0000 };
const dyld_build_version_t dyld_platform_version_watchOS_3_0   = { 4, 0x00030000 };
const dyld_build_version_t dyld_platform_version_bridgeOS_2_0  = { 5, 0x00020000 };
const dyld_build_version_t dyld_fall_2018_os_versions          = { 0xffffffff, 0x07E20961 };
const dyld_build_version_t dyld_fall_2020_os_versions          = { 0xffffffff, 0x07E40961 };

/* "Was the program built against an SDK at least this new?"
 *
 * IT ANSWERS YES UNCONDITIONALLY, AND THAT IS THE CORRECT ANSWER FOR EVERY
 * BINARY THIS PROJECT CAN BUILD -- not a convenient one. Measured rather than
 * assumed, because an unconditional yes is exactly the shape that has bitten
 * this project twice (libswiftcompat's pthread_main_np returning 1 made every
 * thread the main thread; the CF_IS_OBJC predicate was right by accident):
 *
 *   every fixture carries sdk 26.1 in LC_BUILD_VERSION -- the SDK, not the
 *     deployment target, which is macos11/12;
 *   the newest constant any caller asks about is macOS 10.13 (2017), and the
 *     newest wildcard date is dyld_fall_2020_os_versions (2020-09).
 *
 * 26.1 is newer than all of them, so an exact implementation returns 1 for
 * every query we can generate. THERE IS NO FIXTURE THAT COULD TELL THE TWO
 * APART, which is why this is documented rather than reimplemented: a change
 * nobody can test is a change made on speculation.
 *
 * WHEN IT BECOMES WRONG, so the next person has a condition rather than a
 * feeling: the moment machorun runs a guest built against an OLD SDK -- an
 * app shipped years ago, which is precisely the kind of binary the project
 * exists to run. Then objc4 and libswiftCore take modern-behaviour branches
 * the binary was not written for, silently.
 *
 * The exact implementation needs the program's LC_BUILD_VERSION (which
 * src/image.c currently skips) and, for the 0xffffffff wildcard-platform
 * constants, dyld's own table mapping each platform's version to a release
 * DATE. The same-platform comparison is unambiguous; the date mapping is the
 * part that must be copied rather than guessed. */
int dyld_program_sdk_at_least(dyld_build_version_t v);
int dyld_program_sdk_at_least(dyld_build_version_t v) { (void)v; return 1; }

uint32_t dyld_get_active_platform(void);
uint32_t dyld_get_active_platform(void) { return 1; }   /* PLATFORM_MACOS */

int dyld_shared_cache_some_image_overridden(void);
int dyld_shared_cache_some_image_overridden(void) { return 0; }

/* ------------------------------------------------- shared cache: not here */
/* SUPPORT_PREOPT is 0 in our libobjc (patches-macho/0002), so none of these is
 * reachable. They exist because the symbols are still referenced, and each one
 * aborts rather than returning a plausible answer. */
#define NO_SHARED_CACHE(name)                                                 \
    mr_unimplemented("shared-cache",                                          \
                     name "() was called, but machorun has no dyld shared cache " \
                     "and libobjc is built with SUPPORT_PREOPT 0. Reaching this " \
                     "means the build config and the runtime disagree.")

int _dyld_get_shared_cache_range(size_t *length, const void **address);
int _dyld_get_shared_cache_range(size_t *length, const void **address)
{ (void)length; (void)address; return 0; }   /* "there is no shared cache" */

const char *_dyld_get_objc_selector(const char *n);
const char *_dyld_get_objc_selector(const char *n) { (void)n; return NULL; }

uint32_t _dyld_objc_class_count(void);
uint32_t _dyld_objc_class_count(void) { return 0; }

void _dyld_for_each_objc_class(const char *n, void *cb);
void _dyld_for_each_objc_class(const char *n, void *cb)
{ (void)n; (void)cb; NO_SHARED_CACHE("_dyld_for_each_objc_class"); }

void _dyld_for_each_objc_protocol(const char *n, void *cb);
void _dyld_for_each_objc_protocol(const char *n, void *cb)
{ (void)n; (void)cb; NO_SHARED_CACHE("_dyld_for_each_objc_protocol"); }

void _dyld_for_objc_header_opt_ro(void *cb);
void _dyld_for_objc_header_opt_ro(void *cb) { (void)cb; }

void _dyld_for_objc_header_opt_rw(void *cb);
void _dyld_for_objc_header_opt_rw(void *cb) { (void)cb; }
