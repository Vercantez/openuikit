/*
 * compat/src/objc4linux-elf.cpp  --  objc4-linux
 *
 * ELF image discovery: the Linux replacement for everything dyld does for
 * objc4 on Darwin.
 *
 * =====================================================================
 * WHAT DYLD DOES AND WHAT WE DO INSTEAD
 * =====================================================================
 *
 * On Darwin, dyld knows where every Objective-C section of every image is,
 * because it computed that at shared-cache build time or at mmap time. It
 * hands objc4 a `_dyld_section_location_info_t` per image and objc4 asks it
 * questions through exactly one function, `_dyld_lookup_section_info()`.
 * That single function is the whole image-discovery seam (docs/PORT_MAP.md
 * 3.3), and this file is the Linux side of it.
 *
 * The mechanism:
 *
 *   1. `dl_iterate_phdr(3)` enumerates every loaded object with its load bias
 *      (`dlpi_addr`), its path (`dlpi_name`) and its program headers.
 *
 *   2. Program headers do NOT name sections -- ELF section headers are not
 *      loaded into memory at all. So for each image we open its file and read
 *      the on-disk section header table, matching section NAMES.
 *
 *   3. Runtime address of a section = `dlpi_addr + sh_addr`. That is exact
 *      for PIE/DSO images: sh_addr is the link-time vaddr and dlpi_addr is
 *      the bias the loader applied to the whole image.
 *
 * MEASURED, not assumed -- `clang -fobjc-runtime=macosx-10.15` on ELF
 * aarch64 emits these section names (readelf -S on a .o AND on the linked
 * executable; the names survive linking unchanged and land in a PT_LOAD
 * segment):
 *
 *     objc_classlist   objc_nlclslist   objc_catlist    objc_nlcatlist
 *     objc_protolist   objc_protorefs   objc_selrefs    objc_classrefs
 *     objc_superrefs   objc_imageinfo
 *
 * They are the Mach-O names with the leading "__" stripped, which is what
 * makes them valid C identifiers. `swiftc -Xfrontend -enable-objc-interop`
 * emits the SAME names (measured: objc_classlist, objc_imageinfo), so one
 * discovery path serves both compilers -- which is the entire point of the
 * project.
 *
 * objc_msgrefs is absent on aarch64 because SUPPORT_FIXUP is 0 there; it is
 * still in the table below so x86-64 needs no change here.
 *
 * =====================================================================
 * LIMITS -- see docs/UNIMPLEMENTED.md
 * =====================================================================
 *
 *   * Images `dlopen`ed after startup are NOT discovered. The scan runs once,
 *     from libobjc's constructor. objc4linux_scan_images() is written to be
 *     re-runnable (already-registered images are skipped) so wiring this up
 *     is a matter of finding a hook, not of restructuring.
 *
 *   * An image whose file cannot be opened (deleted, or a synthetic object
 *     like linux-vdso.so.1) is skipped. Those have no Objective-C metadata.
 */

#include <errno.h>
#include <fcntl.h>
#include <limits.h>
#include <link.h>
#include <elf.h>
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <malloc.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <unistd.h>
#include <dlfcn.h>

#include <objc4linux/unimplemented.h>
#include <mach-o/loader.h>
#include <mach-o/dyld_priv.h>

/* _objc_init lives in libobjc itself; we are linked into it. */
extern "C" void _objc_init(void);
extern "C" void objc4linux_scan_images(void);

/* ------------------------------------------------------------------ *
 * The per-image section table. This is what
 * `_dyld_section_location_info_t` points at.
 * ------------------------------------------------------------------ */

struct SectionRange {
    const uint8_t *start;
    size_t         size;
};

struct _dyld_section_location_info_s {
    SectionRange s[_dyld_section_location_count];
};

/* A loaded PT_LOAD range, used for address -> image queries. */
struct LoadRange {
    uintptr_t lo, hi;
    bool      writable;
};

/*
 * Our per-image record.
 *
 * `hdr` MUST be the first member: objc4 holds `const struct mach_header *`
 * as its opaque image identity (compat/mach-o/loader.h explains why we keep
 * the Darwin spelling), and we recover the ElfImage by casting back.
 */
struct ElfImage {
    struct mach_header_64          hdr;
    _dyld_section_location_info_s  sections;
    uintptr_t                      base;       /* dlpi_addr */
    char                          *path;
    LoadRange                      loads[16];
    unsigned                       nloads;
    bool                           hasObjC;
    ElfImage                      *next;
};

static_assert(offsetof(ElfImage, hdr) == 0,
              "objc4 casts our image record to `struct mach_header *`");

/* ------------------------------------------------------------------ *
 * Registry
 * ------------------------------------------------------------------ */

static pthread_mutex_t gRegistryLock = PTHREAD_MUTEX_INITIALIZER;
static ElfImage       *gImages       = nullptr;   /* newest first */
static ElfImage       *gMainImage    = nullptr;

static ElfImage *imageForBase(uintptr_t base, const char *path)
{
    for (ElfImage *i = gImages; i; i = i->next) {
        if (i->base == base && (!path || !i->path || strcmp(i->path, path) == 0))
            return i;
    }
    return nullptr;
}

static ElfImage *imageContainingAddress(const void *addr)
{
    uintptr_t a = (uintptr_t)addr;
    for (ElfImage *i = gImages; i; i = i->next) {
        for (unsigned n = 0; n < i->nloads; n++) {
            if (a >= i->loads[n].lo && a < i->loads[n].hi) return i;
        }
    }
    return nullptr;
}

/* ------------------------------------------------------------------ *
 * Section name -> _dyld_section_location_kind
 *
 * The names are MEASURED from clang/swiftc output (see the header comment),
 * not transliterated from Mach-O. The "__" -prefixed spellings are accepted
 * too so that an object built by a toolchain that keeps the Mach-O names
 * still resolves.
 * ------------------------------------------------------------------ */

struct SectionNameMap {
    const char *name;
    enum _dyld_section_location_kind kind;
};

static const SectionNameMap kSectionNames[] = {
    { "objc_classlist",   _dyld_section_location_data_class_list },
    { "objc_nlclslist",   _dyld_section_location_data_non_lazy_class_list },
    { "objc_classrefs",   _dyld_section_location_data_class_refs },
    { "objc_superrefs",   _dyld_section_location_data_super_refs },
    { "objc_protolist",   _dyld_section_location_data_protocol_list },
    { "objc_protorefs",   _dyld_section_location_data_protocol_refs },
    { "objc_selrefs",     _dyld_section_location_data_sel_refs },
    { "objc_msgrefs",     _dyld_section_location_data_msg_refs },
    { "objc_catlist",     _dyld_section_location_data_category_list },
    { "objc_catlist2",    _dyld_section_location_data_category_list2 },
    { "objc_nlcatlist",   _dyld_section_location_data_non_lazy_category_list },
    { "objc_stublist",    _dyld_section_location_data_stub_list },
    { "objc_fork_ok",     _dyld_section_location_data_objc_fork_ok },
    { "objc_rawisa",      _dyld_section_location_data_raw_isa },
    { "objc_imageinfo",   _dyld_section_location_objc_image_info },
};

static bool sectionKindForName(const char *name,
                               enum _dyld_section_location_kind *out)
{
    if (name[0] == '_' && name[1] == '_') name += 2;
    if (strncmp(name, "objc_", 5) != 0) return false;
    for (auto &e : kSectionNames) {
        if (strcmp(name, e.name) == 0) { *out = e.kind; return true; }
    }
    return false;
}

/* ------------------------------------------------------------------ *
 * On-disk section header scan
 * ------------------------------------------------------------------ */

#if __SIZEOF_POINTER__ == 8
typedef Elf64_Ehdr ElfEhdr;
typedef Elf64_Shdr ElfShdr;
#else
typedef Elf32_Ehdr ElfEhdr;
typedef Elf32_Shdr ElfShdr;
#endif

/*
 * Parse `path`'s section header table and fill in `img->sections`.
 * Returns true if the file was read; `img->hasObjC` says whether anything
 * Objective-C was found.
 */
static bool scanSectionHeaders(ElfImage *img, const char *path)
{
    int fd = open(path, O_RDONLY | O_CLOEXEC);
    if (fd < 0) return false;

    struct stat st;
    if (fstat(fd, &st) != 0 || (size_t)st.st_size < sizeof(ElfEhdr)) {
        close(fd);
        return false;
    }
    size_t fileSize = (size_t)st.st_size;

    void *map = mmap(nullptr, fileSize, PROT_READ, MAP_PRIVATE, fd, 0);
    close(fd);
    if (map == MAP_FAILED) return false;

    const uint8_t *file = (const uint8_t *)map;
    const ElfEhdr *eh = (const ElfEhdr *)file;

    if (memcmp(eh->e_ident, ELFMAG, SELFMAG) != 0) goto done;
    if (eh->e_shoff == 0 || eh->e_shentsize < sizeof(ElfShdr)) goto done;

    {
        /* Section count and .shstrtab index have "extended" encodings when
         * either exceeds 16 bits; both live in section header 0. */
        const ElfShdr *sh0 = (const ElfShdr *)(file + eh->e_shoff);
        if (eh->e_shoff + eh->e_shentsize > fileSize) goto done;

        size_t shnum = eh->e_shnum ? eh->e_shnum : (size_t)sh0->sh_size;
        size_t shstrndx = eh->e_shstrndx;
        if (shstrndx == SHN_XINDEX) shstrndx = sh0->sh_link;

        if (shnum == 0 || shstrndx >= shnum) goto done;
        if (eh->e_shoff + shnum * (size_t)eh->e_shentsize > fileSize) goto done;

        auto shdr = [&](size_t i) -> const ElfShdr * {
            return (const ElfShdr *)(file + eh->e_shoff + i * (size_t)eh->e_shentsize);
        };

        const ElfShdr *strsh = shdr(shstrndx);
        if (strsh->sh_offset + strsh->sh_size > fileSize) goto done;
        const char *shstr = (const char *)(file + strsh->sh_offset);
        size_t shstrSize = (size_t)strsh->sh_size;

        for (size_t i = 1; i < shnum; i++) {
            const ElfShdr *sh = shdr(i);
            if (sh->sh_name >= shstrSize) continue;
            /* Not mapped at runtime => nothing for us to point at. */
            if (!(sh->sh_flags & SHF_ALLOC) || sh->sh_addr == 0) continue;

            enum _dyld_section_location_kind kind;
            if (!sectionKindForName(shstr + sh->sh_name, &kind)) continue;

            img->sections.s[kind].start =
                (const uint8_t *)(img->base + (uintptr_t)sh->sh_addr);
            img->sections.s[kind].size = (size_t)sh->sh_size;
            img->hasObjC = true;
        }
    }

done:
    munmap(map, fileSize);
    return true;
}

/* ------------------------------------------------------------------ *
 * dl_iterate_phdr scan
 * ------------------------------------------------------------------ */

struct ScanContext {
    ElfImage **found;      /* top-down order, as dl_iterate_phdr reports */
    unsigned   count;
    unsigned   cap;
};

static char *mainExecutablePath(void)
{
    char buf[PATH_MAX];
    ssize_t n = readlink("/proc/self/exe", buf, sizeof(buf) - 1);
    if (n <= 0) return nullptr;
    buf[n] = '\0';
    return strdup(buf);
}

static int scanCallback(struct dl_phdr_info *info, size_t size, void *data)
{
    (void)size;
    ScanContext *ctx = (ScanContext *)data;

    bool isMain = (info->dlpi_name == nullptr || info->dlpi_name[0] == '\0');

    /* Already known? The scan is re-runnable by design. */
    if (imageForBase((uintptr_t)info->dlpi_addr,
                     isMain ? nullptr : info->dlpi_name))
        return 0;

    char *path = isMain ? mainExecutablePath() : strdup(info->dlpi_name);
    if (!path) return 0;

    ElfImage *img = (ElfImage *)calloc(1, sizeof(ElfImage));
    if (!img) { free(path); return 0; }

    img->hdr.magic    = OBJC4LINUX_IMAGE_MAGIC;
    img->hdr.filetype = isMain ? MH_EXECUTE : MH_DYLIB;
    img->base         = (uintptr_t)info->dlpi_addr;
    img->path         = path;

    for (int i = 0; i < info->dlpi_phnum; i++) {
        const ElfW(Phdr) *ph = &info->dlpi_phdr[i];
        if (ph->p_type != PT_LOAD) continue;
        if (img->nloads >= sizeof(img->loads) / sizeof(img->loads[0])) break;
        LoadRange &r = img->loads[img->nloads++];
        r.lo = (uintptr_t)info->dlpi_addr + (uintptr_t)ph->p_vaddr;
        r.hi = r.lo + (uintptr_t)ph->p_memsz;
        r.writable = (ph->p_flags & PF_W) != 0;
    }

    scanSectionHeaders(img, path);

    img->next = gImages;
    gImages = img;
    if (isMain) gMainImage = img;

    if (img->hasObjC) {
        if (ctx->count < ctx->cap) ctx->found[ctx->count++] = img;
        else ctx->count++;   /* overflow; caller retries with a bigger array */
    }
    return 0;
}

/*
 * Enumerate loaded images and return the newly-registered ones that carry
 * Objective-C metadata, in BOTTOM-UP order (dependencies before dependents),
 * which is the order dyld hands to map_images: infos[0] is the lowest-level
 * library, infos[n-1] the main executable.
 *
 * dl_iterate_phdr reports the opposite order (main executable first, then
 * objects in load order), so the result is reversed.
 *
 * Caller must hold gRegistryLock. Returns a malloc'd array; caller frees.
 */
static ElfImage **collectNewObjCImages(unsigned *outCount)
{
    unsigned cap = 32;
    for (;;) {
        ElfImage **arr = (ElfImage **)calloc(cap, sizeof(ElfImage *));
        if (!arr) { *outCount = 0; return nullptr; }
        ScanContext ctx = { arr, 0, cap };
        dl_iterate_phdr(scanCallback, &ctx);
        if (ctx.count <= cap) {
            /* reverse: top-down -> bottom-up */
            for (unsigned i = 0, j = ctx.count ? ctx.count - 1 : 0; i < j; i++, j--) {
                ElfImage *t = arr[i]; arr[i] = arr[j]; arr[j] = t;
            }
            *outCount = ctx.count;
            return arr;
        }
        /* Overflowed. Everything is registered now, so a second pass would
         * find nothing new -- grow and rebuild from the registry instead. */
        free(arr);
        cap = ctx.count + 8;
        unsigned n = 0;
        arr = (ElfImage **)calloc(cap, sizeof(ElfImage *));
        if (!arr) { *outCount = 0; return nullptr; }
        for (ElfImage *i = gImages; i && n < cap; i = i->next)
            if (i->hasObjC) arr[n++] = i;
        /* gImages is newest-first == reverse of registration == bottom-up
         * only by accident; sort deterministically by re-reversing. */
        for (unsigned i = 0, j = n ? n - 1 : 0; i < j; i++, j--) {
            ElfImage *t = arr[i]; arr[i] = arr[j]; arr[j] = t;
        }
        *outCount = n;
        return arr;
    }
}

/* ------------------------------------------------------------------ *
 * The dyld notification surface
 * ------------------------------------------------------------------ */

static struct _dyld_objc_callbacks_v4 gCallbacks;
static bool gHaveCallbacks = false;

extern "C"
void _dyld_objc_register_callbacks(const struct _dyld_objc_callbacks *callbacks)
{
    if (!callbacks || callbacks->version != 4) {
        objc4linux_unimplemented("_dyld_objc_register_callbacks: only the v4 "
                                 "callback block is implemented");
    }
    gCallbacks = *(const struct _dyld_objc_callbacks_v4 *)callbacks;
    gHaveCallbacks = true;

    /*
     * Deliberately does NOT scan here.
     *
     * dyld's contract is that _dyld_objc_notify_register RETURNS, and only
     * then does dyld deliver map/init callbacks. objc4 depends on that: the
     * very next statement in _objc_init() is
     *
     *     didCallDyldNotifyRegister = true;
     *
     * and loadAllCategoriesIfNeeded() -- the function that performs the
     * initial category attach for every image present at launch -- is a
     * no-op while that flag is false. Scanning from inside this call left
     * every category in the program unattached, silently: no +load, no
     * category methods, and `unrecognized selector` at the first use.
     *
     * So the scan is driven by the constructor, after _objc_init() returns.
     */
}

/*
 * Register every not-yet-known image and drive map_images/load_images over
 * the ones with Objective-C metadata. Safe to call repeatedly.
 */
extern "C" void objc4linux_scan_images(void)
{
    pthread_mutex_lock(&gRegistryLock);
    unsigned count = 0;
    ElfImage **imgs = collectNewObjCImages(&count);
    pthread_mutex_unlock(&gRegistryLock);

    if (!imgs) return;
    if (count == 0 || !gHaveCallbacks) { free(imgs); return; }

    struct _dyld_objc_notify_mapped_info *infos =
        (struct _dyld_objc_notify_mapped_info *)
        calloc(count, sizeof(struct _dyld_objc_notify_mapped_info));
    if (!infos) { free(imgs); return; }

    for (unsigned i = 0; i < count; i++) {
        infos[i].mh   = (const struct mach_header *)&imgs[i]->hdr;
        infos[i].path = imgs[i]->path;
        infos[i].sectionLocationMetadata = &imgs[i]->sections;
        /* Nothing here was preoptimized by a shared cache, and there is no
         * TPRO: header_info's tproEnabled() reads this bitfield word. */
        infos[i].dyldObjCRefsOptimized   = 0;
        infos[i].dyldCategoriesOptimized = 0;
    }

    /* dyld hands objc4 a block it can call to make a read-only image's
     * selrefs writable. Our sections are already in a writable PT_LOAD
     * segment (measured: objc_selrefs lands in the RW LOAD), so this is a
     * genuine no-op rather than a stub. */
    _dyld_objc_mark_image_mutable makeMutable = ^(uint32_t) { };

    if (gCallbacks.mapped) gCallbacks.mapped(count, infos, makeMutable);

    /* On Darwin, load_images is called per image just before that image's
     * initializers run. We are running from libobjc's own constructor, i.e.
     * before every other image's initializers, so calling it for the whole
     * batch here preserves the ordering guarantee (+load before any other
     * image's initializers) and the relative order among images. */
    if (gCallbacks.init) {
        for (unsigned i = 0; i < count; i++) gCallbacks.init(&infos[i]);
    }

    free(infos);
    free(imgs);
}

/* ------------------------------------------------------------------ *
 * _dyld_lookup_section_info -- THE seam.
 * ------------------------------------------------------------------ */

extern "C"
struct _dyld_section_info_result
_dyld_lookup_section_info(const struct mach_header *mh,
                          _dyld_section_location_info_t info,
                          enum _dyld_section_location_kind kind)
{
    struct _dyld_section_info_result result = { nullptr, 0 };

    if (!info) {
        /* objc4 calls with a NULL info in one place (objc-os.mm's
         * _objc_getObjcImageInfo path for an image it has not registered).
         * Fall back to the image record itself. */
        if (!mh) return result;
        const ElfImage *img = (const ElfImage *)mh;
        if (img->hdr.magic != OBJC4LINUX_IMAGE_MAGIC) return result;
        info = (_dyld_section_location_info_t)&img->sections;
    }

    if ((unsigned)kind >= (unsigned)_dyld_section_location_count) return result;

    const SectionRange &r = info->s[kind];
    if (!r.start || r.size == 0) return result;

    result.buffer     = (void *)r.start;
    result.bufferSize = r.size;
    return result;
}

/* ------------------------------------------------------------------ *
 * Image identity
 * ------------------------------------------------------------------ */

extern "C"
const struct mach_header *_dyld_get_prog_image_header(void)
{
    return gMainImage ? (const struct mach_header *)&gMainImage->hdr : nullptr;
}

extern "C"
const struct mach_header *dyld_image_header_containing_address(const void *addr)
{
    pthread_mutex_lock(&gRegistryLock);
    ElfImage *img = imageContainingAddress(addr);
    pthread_mutex_unlock(&gRegistryLock);
    return img ? (const struct mach_header *)&img->hdr : nullptr;
}

/*
 * objc4 calls this with our own image record (header_info::fname()) as well
 * as with real code/data addresses, so both must work.
 */
extern "C"
const char *dyld_image_path_containing_address(const void *addr)
{
    if (!addr) return nullptr;

    pthread_mutex_lock(&gRegistryLock);
    for (ElfImage *i = gImages; i; i = i->next) {
        if (addr == (const void *)&i->hdr) {
            const char *p = i->path;
            pthread_mutex_unlock(&gRegistryLock);
            return p;
        }
    }
    ElfImage *img = imageContainingAddress(addr);
    const char *p = img ? img->path : nullptr;
    pthread_mutex_unlock(&gRegistryLock);
    if (p) return p;

    Dl_info dli;
    if (dladdr(addr, &dli) && dli.dli_fname) return dli.dli_fname;
    return nullptr;
}

extern "C"
const struct mach_header *_dyld_get_dlopen_image_header(void *handle)
{
    /* dlinfo(RTLD_DI_LINKMAP) gives the link_map, whose l_addr is the load
     * bias -- the same key our registry is indexed by. */
    struct link_map *lm = nullptr;
    if (!handle || dlinfo(handle, RTLD_DI_LINKMAP, &lm) != 0 || !lm)
        return nullptr;

    pthread_mutex_lock(&gRegistryLock);
    ElfImage *img = imageForBase((uintptr_t)lm->l_addr, nullptr);
    pthread_mutex_unlock(&gRegistryLock);
    return img ? (const struct mach_header *)&img->hdr : nullptr;
}

/*
 * True if [addr, addr+length) lies entirely in a non-writable PT_LOAD of a
 * registered image. objc4 uses this for strdupIfMutable(): a string in a
 * read-only segment can be referenced instead of copied.
 */
extern "C"
bool _dyld_is_memory_immutable(const void *addr, size_t length)
{
    uintptr_t lo = (uintptr_t)addr;
    uintptr_t hi = lo + length;

    pthread_mutex_lock(&gRegistryLock);
    bool result = false;
    for (ElfImage *i = gImages; i; i = i->next) {
        for (unsigned n = 0; n < i->nloads; n++) {
            const LoadRange &r = i->loads[n];
            if (!r.writable && lo >= r.lo && hi <= r.hi) { result = true; break; }
        }
        if (result) break;
    }
    pthread_mutex_unlock(&gRegistryLock);
    return result;
}

extern "C"
bool _dyld_get_image_uuid(const struct mach_header *, uuid_t)
{
    /* The ELF analogue is PT_NOTE/NT_GNU_BUILD_ID. Only used for
     * duplicate-class diagnostics; not wired up. */
    return false;
}

/* ------------------------------------------------------------------ *
 * Segment queries.
 *
 * objc4's _headerForAddress() walks Mach-O __DATA* segments looking for the
 * image that owns a class. On ELF there are no segment names, so the patched
 * objc-os.mm asks us instead.
 * ------------------------------------------------------------------ */

extern "C"
bool objc4linux_image_contains_address(const struct mach_header *mh,
                                       const void *addr)
{
    if (!mh) return false;
    const ElfImage *img = (const ElfImage *)mh;
    if (img->hdr.magic != OBJC4LINUX_IMAGE_MAGIC) return false;

    uintptr_t a = (uintptr_t)addr;
    for (unsigned n = 0; n < img->nloads; n++) {
        if (a >= img->loads[n].lo && a < img->loads[n].hi) return true;
    }
    return false;
}

/* ------------------------------------------------------------------ *
 * malloc_size
 *
 * Darwin's malloc_size() returns 0 for a pointer malloc does not own, and
 * objc4 relies on that in try_free() to distinguish heap-allocated metadata
 * from metadata that is constant data inside a compiled image. glibc's
 * malloc_usable_size() has no such contract -- it decodes the chunk header at
 * ptr-16 unconditionally. See the long note in compat/malloc/malloc.h.
 *
 * The ELF image registry answers the real question directly: an address
 * inside any loaded image's PT_LOAD ranges is not a malloc block.
 * ------------------------------------------------------------------ */

extern "C"
size_t malloc_size(const void *ptr)
{
    if (!ptr) return 0;

    pthread_mutex_lock(&gRegistryLock);
    bool inImage = imageContainingAddress(ptr) != nullptr;
    pthread_mutex_unlock(&gRegistryLock);
    if (inImage) return 0;

    return malloc_usable_size((void *)ptr);
}

/* ------------------------------------------------------------------ *
 * Entry point.
 *
 * ORDERING (docs/PORT_PLAN.md "Riskiest unknown"):
 *
 * On Darwin, libSystem calls _objc_init() before ANY library initializer
 * runs, and objc4 then runs its own C++ static constructors by hand
 * (static_init()) because it is executing earlier than its own .init_array.
 *
 * Linux gives us no such privileged position, but it gives us two useful
 * facts, both measured rather than assumed:
 *
 *   1. `readelf -x .init_array libobjc.so` shows exactly TWO entries, both
 *      from the toolchain (frame_dummy from crtbegin, init_have_lse_atomics
 *      from compiler-rt). objc4 contributes ZERO static constructors -- its
 *      release-build discipline forbids them, which is what makes Darwin's
 *      static_init() safe to reduce to a no-op here (patch 0006).
 *
 *   2. A constructor with a priority is emitted into `.init_array.NNNNN`,
 *      which the linker script places BEFORE plain `.init_array`. So
 *      priority 101 makes this the first thing that runs in libobjc.
 *
 * And glibc runs an object's initializers only after all of its
 * dependencies', so every image that links -lobjc initializes after us.
 * That reproduces Darwin's "+load before any initializer" guarantee for the
 * normal case. It does NOT reproduce it for an image that uses Objective-C
 * without linking libobjc, nor for anything dlopen'ed later.
 * ------------------------------------------------------------------ */

__attribute__((constructor(101)))
static void objc4linux_elf_init(void)
{
    _objc_init();          // registers our callbacks, sets up the runtime
    objc4linux_scan_images();   // stands in for dyld delivering them
}
