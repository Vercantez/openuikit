/* machorun.h -- loader-internal interfaces.
 *
 * One process, two object formats: our ELF (glibc + this loader) and the guest
 * Mach-O images. See docs/PLAN.md part I.
 */
#ifndef MACHORUN_H
#define MACHORUN_H

#include <stdint.h>
#include <stddef.h>
#include "macho.h"

#define MR_MAX_SEGMENTS 16
#define MR_MAX_DEPS     64
#define MR_MAX_RPATHS   16
#define MR_MAX_IMAGES   64

/* Two page sizes live in this program and conflating them is the easiest bug
 * in the project (PLAN §I.4). The Mach-O one is a property of the fixup
 * tables; the host one is what mmap/mprotect require. Distinct types so the
 * compiler notices. */
typedef struct { uint32_t v; } macho_page_size_t;
typedef struct { uint64_t v; } host_page_size_t;

typedef struct mr_segment {
    char     name[17];
    uint64_t vmaddr, vmsize, fileoff, filesize;
    uint32_t maxprot, initprot, flags, nsects;
    const struct section_64 *sects;   /* into the parse mapping */
} mr_segment;

typedef struct mr_export {
    const char *name;      /* owned by the trie blob (parse mapping) or strdup */
    uint64_t    offset;    /* image-relative; absolute value for ABSOLUTE kind */
    uint32_t    flags;
} mr_export;

typedef struct mr_image mr_image;

typedef struct mr_dep {
    char     *path;        /* the LC_LOAD_DYLIB string, verbatim */
    mr_image *img;         /* NULL for a missing weak dylib */
    int       weak;
    int       reexport;
} mr_dep;

struct mr_image {
    char *path;            /* resolved filesystem path we actually opened */
    char *install_name;    /* LC_ID_DYLIB, or NULL for executables */
    char *dir;             /* dirname(path), for @loader_path */

    int fd;                /* open only between mr_image_load and mr_map_image */
    const uint8_t *raw;    /* whole-file parse mapping (PROT_READ) */
    size_t         raw_len;
    uint64_t       slice_off;   /* fat slice base within the file, else 0 */
    const struct mach_header_64 *mh;   /* == raw + slice_off */

    uint32_t filetype, mh_flags;

    mr_segment segs[MR_MAX_SEGMENTS];
    int        nsegs;

    uint64_t preferred_base;   /* __TEXT.vmaddr */
    uint64_t load_base;        /* where the mach header actually landed */
    int64_t  slide;
    uint64_t span_lo, span_hi; /* reserved VA range, absolute */

    /* linkedit blobs, file offsets within the slice */
    uint32_t chained_off, chained_size;
    uint32_t trie_off, trie_size;
    const struct dyld_info_command *dyld_info;
    const struct symtab_command    *symtab;

    mr_dep deps[MR_MAX_DEPS];
    int    ndeps;
    char  *rpaths[MR_MAX_RPATHS];
    int    nrpaths;

    mr_export *exports;
    size_t     nexports;

    int      has_entry;        /* LC_MAIN seen */
    uint64_t entryoff, stacksize;
    int      has_unixthread;
    uint64_t unixthread_pc;

    /* TLV */
    const struct section_64 *sec_thread_vars, *sec_thread_data, *sec_thread_bss;
    uint32_t tlv_key;          /* pthread_key_t, valid when tlv_registered */
    int      tlv_registered;

    int is_runtime;      /* came out of our darwin/ tree: host dlsym allowed */
    int is_main;
    int fixed_up;
    int init_state;      /* 0 none, 1 running, 2 done */

    /* ObjC image-notification state (src/objc_notify.c). Both are set by us,
     * never by libobjc, and exist to make the map-before-load ordering a
     * checkable invariant rather than an assumption. */
    int objc_mapped;     /* included in a _dyld_objc_notify mapped batch */
    int objc_inited;     /* the init (load_images / +load) callback has run */
};

/* ---------------------------------------------------------------- state */
typedef struct mr_state {
    mr_image *images[MR_MAX_IMAGES];
    int       nimages;
    mr_image *main_image;
    char     *exec_dir;
    char     *darwin_root;      /* $MACHORUN_ROOT/darwin, or the first that exists */
    host_page_size_t page;
    int       verbose;
    int       argc;
    char    **argv;
    char    **envp;
    char    **apple;
} mr_state;

extern mr_state MR;

/* ----------------------------------------------------------------- util */
void  mr_die(const char *fmt, ...) __attribute__((noreturn, format(printf, 1, 2)));
void  mr_unimplemented(const char *what, const char *fmt, ...)
        __attribute__((noreturn, format(printf, 2, 3)));
void  mr_log(const char *fmt, ...) __attribute__((format(printf, 1, 2)));
void *mr_xmalloc(size_t n);
char *mr_xstrdup(const char *s);
char *mr_join(const char *a, const char *b);
char *mr_dirname(const char *path);
int   mr_file_exists(const char *path);

static inline uint64_t mr_round_up(uint64_t v, uint64_t a) { return (v + a - 1) & ~(a - 1); }
static inline uint64_t mr_round_dn(uint64_t v, uint64_t a) { return v & ~(a - 1); }

/* uleb/sleb over a bounded buffer; both advance *p and die on overrun. */
uint64_t mr_uleb(const uint8_t **p, const uint8_t *end);
int64_t  mr_sleb(const uint8_t **p, const uint8_t *end);

/* --------------------------------------------------------------- images */
mr_image *mr_image_load(const char *path, mr_image *loader, int weak, int is_main);
mr_image *mr_image_find_loaded(const char *install_name);
int       mr_image_is_loaded(const char *install_name_or_path);
int       mr_addr_in_image(const void *p);
const mr_segment *mr_image_segment(const mr_image *im, const char *name);
const struct section_64 *mr_image_section(const mr_image *im, const char *seg, const char *sect);
/* file offset (within the slice) -> parse-mapping pointer, bounds checked */
const void *mr_file_at(const mr_image *im, uint64_t off, uint64_t len, const char *what);
void mr_map_image(mr_image *im);
void mr_protect_readonly_segments(mr_image *im);
int  mr_mprotect_rw(void *addr, uint64_t size);
void mr_reserve_pagezero(void);
void mr_constrain_heap(void);
int  mr_addr_in_glibc_heap(const void *p);

/* libswiftCore has the 47-bit isa mask compiled into it, so anything that can
 * end up in an isa -- a mapped image, and the heap the runtimes allocate class
 * objects from -- has to live below this. See the placement note in src/map.c. */
#define MR_ISA_LIMIT 0x800000000000ull

/* The size mr_constrain_heap() probes with to prove that LARGE allocations are
 * constrained too. It has to sit above glibc's 32 MiB mmap threshold, because
 * everything below it was never in question -- that is the whole reason the
 * original probe could not see the bug it was guarding against. */
#define MR_HEAP_PROBE_LARGE (33ull * 1024 * 1024)

/* --------------------------------------------------------------- fixups */
void mr_fixups_apply(mr_image *im);
void mr_fixups_chained(mr_image *im);
void mr_fixups_classic(mr_image *im);

/* --------------------------------------------------------------- export */
void     mr_exports_parse(mr_image *im);
int      mr_exports_lookup(const mr_image *im, const char *name, uint64_t *addr_out);
uint64_t mr_resolve_symbol(mr_image *from, int lib_ordinal, const char *name,
                           int weak_import, int *found);
void     mr_resolve_report(mr_image *from, const mr_image *in, const char *name);

/* ------------------------------------------------------------ tlv, init */
void mr_tlv_setup(mr_image *im);
void mr_run_initialisers(mr_image *im);
void mr_objc_note_image(mr_image *im);      /* -> load_images / +load */
int  mr_objc_run_objc_init(void);           /* -> _objc_init; 0 if no libobjc */
void mr_install_crash_reporter(void);

/* dlopen over guest images. The handle is the mr_image *; see src/image.c.
 * RTLD_NOLOAD is Darwin's 0x10 (sdk/usr/include/dlfcn.h) and is duplicated here
 * rather than included, because the loader is an ELF and does not read the
 * Darwin SDK headers. Pinned in sdk/tests/glibc_abi_probe.c. */
#define MR_RTLD_NOLOAD 0x10
void *mr_dlopen(const char *path, int mode);
void *mr_dlsym_handle(void *handle, const char *name);

#endif /* MACHORUN_H */
