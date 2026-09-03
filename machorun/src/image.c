/* image.c -- open, slice, parse and register one Mach-O image.
 *
 * Parsing happens over a read-only whole-file mapping (im->raw) so that every
 * file offset in the load commands can be followed directly, including the
 * __LINKEDIT blobs. Execution happens over the segment mappings created by
 * map.c. The two views are deliberately separate: the parse view is bounds
 * checked, the execution view is not (it is the guest's own memory).
 */
#define _GNU_SOURCE
#include "machorun.h"

#include <fcntl.h>
#include <limits.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <unistd.h>

/* ------------------------------------------------------------- accessors */

const void *mr_file_at(const mr_image *im, uint64_t off, uint64_t len, const char *what)
{
    uint64_t base = im->slice_off;
    if (off > im->raw_len || len > im->raw_len - off ||
        base > im->raw_len || off > im->raw_len - base ||
        base + off + len > im->raw_len)
        mr_die("%s: %s at file offset %llu+%llu is outside the file (%zu bytes)",
               im->path, what, (unsigned long long)off, (unsigned long long)len, im->raw_len);
    return im->raw + base + off;
}

const mr_segment *mr_image_segment(const mr_image *im, const char *name)
{
    for (int i = 0; i < im->nsegs; i++)
        if (strcmp(im->segs[i].name, name) == 0) return &im->segs[i];
    return NULL;
}

const struct section_64 *mr_image_section(const mr_image *im, const char *seg, const char *sect)
{
    for (int i = 0; i < im->nsegs; i++) {
        const mr_segment *s = &im->segs[i];
        if (seg && strncmp(s->name, seg, 16) != 0) continue;
        for (uint32_t j = 0; j < s->nsects; j++)
            if (strncmp(s->sects[j].sectname, sect, 16) == 0) return &s->sects[j];
    }
    return NULL;
}

/* Is this address inside a mapped guest image (any segment of any image)?
 *
 * Exists for one caller with a sharp requirement: Darwin's malloc_size(p)
 * returns 0 for a pointer no malloc zone owns, and objc4 leans on that --
 * `try_free(p)` in objc-runtime-new.h is `if (p && malloc_size(p)) free(p)`,
 * which is how it tells a class_ro_t the compiler put in __DATA_CONST from one
 * it allocated itself. glibc's malloc_usable_size does no such validation: it
 * reads the word before the pointer and returns whatever is there. So machorun
 * has to answer "is this image data?" itself. See darwin/src/libsystem.c. */
int mr_addr_in_image(const void *p)
{
    uint64_t a = (uint64_t)(uintptr_t)p;
    for (int i = 0; i < MR.nimages; i++) {
        const mr_image *im = MR.images[i];
        if (a >= im->span_lo && a < im->span_hi) return 1;
    }
    return 0;
}

/* Answers dlopen(RTLD_NOLOAD) for libSystem, which cannot see MR.images itself.
 * Deliberately the same matcher mr_image_find_loaded uses -- install name OR
 * resolved path -- so "is it loaded" and "which image is it" can never
 * disagree. Exported #internal in darwin/loader-exports.txt: it is a seam
 * between the loader and our own dylibs, not guest API. */
int mr_image_is_loaded(const char *key)
{
    return key && mr_image_find_loaded(key) != NULL;
}

mr_image *mr_image_find_loaded(const char *key)
{
    for (int i = 0; i < MR.nimages; i++) {
        mr_image *im = MR.images[i];
        if (im->install_name && strcmp(im->install_name, key) == 0) return im;
        if (strcmp(im->path, key) == 0) return im;
    }
    return NULL;
}

/* ---------------------------------------------------------- path search */

/* Expand one @-prefixed or plain path against a loader image. Returns a
 * malloc'd candidate path, or NULL if the prefix does not apply. */
static char *expand_at(const char *p, const mr_image *loader)
{
    if (strncmp(p, "@executable_path/", 17) == 0)
        return mr_join(MR.exec_dir, p + 17);
    if (strncmp(p, "@loader_path/", 13) == 0)
        return mr_join(loader ? loader->dir : MR.exec_dir, p + 13);
    if (strcmp(p, "@executable_path") == 0) return mr_xstrdup(MR.exec_dir);
    if (strcmp(p, "@loader_path") == 0)
        return mr_xstrdup(loader ? loader->dir : MR.exec_dir);
    return NULL;
}

#define MAX_TRIED 32

static char *resolve_dylib_path(const char *want, mr_image *loader,
                                char **tried, int *ntried, int *is_runtime)
{
    char *cand;
    *is_runtime = 0;

    if (strncmp(want, "@rpath/", 7) == 0) {
        const char *tail = want + 7;
        /* LC_RPATHs of the loading image first, then of the main executable. */
        for (int pass = 0; pass < 2; pass++) {
            mr_image *src = pass == 0 ? loader : MR.main_image;
            if (!src || (pass == 1 && src == loader)) continue;
            for (int i = 0; i < src->nrpaths; i++) {
                char *rp = expand_at(src->rpaths[i], src);
                char *base = rp ? rp : mr_xstrdup(src->rpaths[i]);
                cand = mr_join(base, tail);
                free(base);
                if (mr_file_exists(cand)) return cand;
                if (*ntried < MAX_TRIED) tried[(*ntried)++] = cand; else free(cand);
            }
        }
        return NULL;
    }

    if ((cand = expand_at(want, loader)) != NULL) {
        if (mr_file_exists(cand)) return cand;
        if (*ntried < MAX_TRIED) tried[(*ntried)++] = cand; else free(cand);
        return NULL;
    }

    if (want[0] == '/') {
        /* A Darwin absolute path. The prefix map is the project's core
         * mechanism: /usr/lib/libSystem.B.dylib is not a file on Linux, and
         * measured, not a file on macOS either -- it lives in the dyld shared
         * cache. So there is nothing to fall back to; it is our tree or an
         * error naming the path. */
        *is_runtime = 1;
        if (MR.darwin_root) {
            cand = mr_join(MR.darwin_root, want);
            if (mr_file_exists(cand)) return cand;
            if (*ntried < MAX_TRIED) tried[(*ntried)++] = cand; else free(cand);
        }
        *is_runtime = 0;
        if (mr_file_exists(want)) return mr_xstrdup(want);
        if (*ntried < MAX_TRIED) tried[(*ntried)++] = mr_xstrdup(want);
        return NULL;
    }

    /* Relative: against the loader's directory, then the cwd. */
    cand = mr_join(loader ? loader->dir : MR.exec_dir, want);
    if (mr_file_exists(cand)) return cand;
    if (*ntried < MAX_TRIED) tried[(*ntried)++] = cand; else free(cand);
    if (mr_file_exists(want)) return mr_xstrdup(want);
    return NULL;
}

/* ------------------------------------------------------------- fat slice */

static uint32_t be32(uint32_t v) { return __builtin_bswap32(v); }
static uint64_t be64(uint64_t v) { return __builtin_bswap64(v); }

static uint64_t select_slice(mr_image *im)
{
    const uint32_t *magicp = (const uint32_t *)im->raw;
    uint32_t magic;
    if (im->raw_len < 4) mr_die("%s: file is too small to be a Mach-O", im->path);
    magic = *magicp;

    if (magic == MH_MAGIC_64) return 0;
    if (magic == MH_CIGAM_64)
        mr_die("%s: big-endian Mach-O (magic cffaedfe); only little-endian 64-bit is supported", im->path);
    if (magic == MH_MAGIC_32 || magic == 0xcefaedfeu)
        mr_die("%s: 32-bit Mach-O; only 64-bit is supported", im->path);

    if (magic == FAT_CIGAM || magic == FAT_CIGAM_64 || magic == FAT_MAGIC || magic == FAT_MAGIC_64) {
        /* fat headers are always big-endian on disk. FAT_CIGAM is what a
         * little-endian host sees for a big-endian FAT_MAGIC. */
        int is64 = (magic == FAT_CIGAM_64 || magic == FAT_MAGIC_64);
        const struct fat_header *fh = (const struct fat_header *)im->raw;
        uint32_t n = be32(fh->nfat_arch);
        const uint8_t *p = im->raw + sizeof(*fh);
        if (n > 64) mr_die("%s: implausible fat_header.nfat_arch = %u", im->path, n);
        for (uint32_t i = 0; i < n; i++) {
            uint32_t ct, cs;
            uint64_t off, size;
            if (is64) {
                const struct fat_arch_64 *a = (const struct fat_arch_64 *)p;
                ct = be32(a->cputype); cs = be32(a->cpusubtype);
                off = be64(a->offset); size = be64(a->size);
                p += sizeof(*a);
            } else {
                const struct fat_arch *a = (const struct fat_arch *)p;
                ct = be32(a->cputype); cs = be32(a->cpusubtype);
                off = be32(a->offset); size = be32(a->size);
                p += sizeof(*a);
            }
            if (ct != MR_HOST_CPU_TYPE) continue;
            if (ct == CPU_TYPE_ARM64 && (cs & ~CPU_SUBTYPE_MASK) == CPU_SUBTYPE_ARM64E) continue;
            if (off + size > im->raw_len)
                mr_die("%s: fat slice %u runs past the end of the file", im->path, i);
            mr_log("%s: fat binary, taking %s slice at file offset 0x%llx",
                   im->path, MR_HOST_CPU_NAME, (unsigned long long)off);
            return off;
        }
        mr_die("%s: fat binary with %u slices but no %s (CPU type 0x%x) slice",
               im->path, n, MR_HOST_CPU_NAME, MR_HOST_CPU_TYPE);
    }
    mr_die("%s: not a Mach-O -- magic is 0x%08x", im->path, magic);
}

/* ------------------------------------------------------------ parse pass */

static void parse_load_commands(mr_image *im)
{
    const struct mach_header_64 *mh = im->mh;
    const uint8_t *lc = (const uint8_t *)mr_file_at(im, sizeof(*mh), mh->sizeofcmds, "load commands");
    const uint8_t *end = lc + mh->sizeofcmds;
    int have_text = 0;

    for (uint32_t i = 0; i < mh->ncmds; i++) {
        const struct load_command *c = (const struct load_command *)lc;
        if (lc + sizeof(*c) > end || c->cmdsize < sizeof(*c) || lc + c->cmdsize > end)
            mr_die("%s: load command %u is malformed (cmdsize %u)", im->path, i,
                   lc + sizeof(*c) <= end ? c->cmdsize : 0);

        switch (c->cmd) {
        case LC_SEGMENT_64: {
            const struct segment_command_64 *s = (const void *)c;
            mr_segment *g;
            if (im->nsegs >= MR_MAX_SEGMENTS)
                mr_die("%s: more than %d segments", im->path, MR_MAX_SEGMENTS);
            g = &im->segs[im->nsegs++];
            memcpy(g->name, s->segname, 16);
            g->name[16] = 0;
            g->vmaddr = s->vmaddr; g->vmsize = s->vmsize;
            g->fileoff = s->fileoff; g->filesize = s->filesize;
            g->maxprot = s->maxprot; g->initprot = s->initprot;
            g->flags = s->flags; g->nsects = s->nsects;
            g->sects = (const struct section_64 *)(s + 1);
            if (c->cmdsize < sizeof(*s) + (uint64_t)s->nsects * sizeof(struct section_64))
                mr_die("%s: segment %s claims %u sections but cmdsize is %u",
                       im->path, g->name, s->nsects, c->cmdsize);
            if (strcmp(g->name, "__TEXT") == 0) { im->preferred_base = g->vmaddr; have_text = 1; }
            break;
        }
        case LC_ID_DYLIB: {
            const struct dylib_command *d = (const void *)c;
            im->install_name = mr_xstrdup((const char *)c + d->name_offset);
            break;
        }
        case LC_LOAD_DYLIB:
        case LC_LOAD_WEAK_DYLIB:
        case LC_REEXPORT_DYLIB:
        case LC_LOAD_UPWARD_DYLIB:
        case LC_LAZY_LOAD_DYLIB: {
            const struct dylib_command *d = (const void *)c;
            if (im->ndeps >= MR_MAX_DEPS)
                mr_die("%s: more than %d dependent dylibs", im->path, MR_MAX_DEPS);
            im->deps[im->ndeps].path = mr_xstrdup((const char *)c + d->name_offset);
            im->deps[im->ndeps].weak = (c->cmd == LC_LOAD_WEAK_DYLIB);
            im->deps[im->ndeps].reexport = (c->cmd == LC_REEXPORT_DYLIB);
            im->ndeps++;
            if (c->cmd == LC_REEXPORT_DYLIB)
                mr_log("%s: LC_REEXPORT_DYLIB %s (re-export chasing is not implemented; "
                       "flat lookup will still find it)", im->path, (const char *)c + d->name_offset);
            break;
        }
        case LC_RPATH: {
            const struct rpath_command *r = (const void *)c;
            if (im->nrpaths >= MR_MAX_RPATHS)
                mr_die("%s: more than %d LC_RPATHs", im->path, MR_MAX_RPATHS);
            im->rpaths[im->nrpaths++] = mr_xstrdup((const char *)c + r->path_offset);
            break;
        }
        case LC_MAIN: {
            const struct entry_point_command *e = (const void *)c;
            im->has_entry = 1;
            im->entryoff = e->entryoff;
            im->stacksize = e->stacksize;
            break;
        }
        case LC_UNIXTHREAD: {
            /* arm64: flavor 6, state is x[29], fp, lr, sp, pc, cpsr; pc at uint64 index 32.
             * x86_64: flavor 4, state is rax..gs (21 uint64s); rip at index 16. */
            const uint32_t *w = (const uint32_t *)(c + 1);
            uint32_t flavor = w[0], count = w[1];
            const uint64_t *st = (const uint64_t *)(w + 2);
            if (flavor == ARM_THREAD_STATE64) {
                if (count < 34)
                    mr_die("%s: ARM_THREAD_STATE64 count %u is too small", im->path, count);
                im->has_unixthread = 1;
                im->unixthread_pc = st[32];   /* x0..x28, fp, lr, sp, pc */
            } else if (flavor == x86_THREAD_STATE64) {
                /* count is uint32s (42) or uint64s (21); either is enough for rip. */
                if (count < 21)
                    mr_die("%s: x86_THREAD_STATE64 count %u is too small", im->path, count);
                im->has_unixthread = 1;
                im->unixthread_pc = st[16];   /* rax..r15, rip */
            } else {
                mr_unimplemented("LC_UNIXTHREAD flavor",
                                 "%s: thread state flavor %u, only ARM_THREAD_STATE64 (6) "
                                 "and x86_THREAD_STATE64 (4) are handled",
                                 im->path, flavor);
            }
            break;
        }
        case LC_DYLD_CHAINED_FIXUPS: {
            const struct linkedit_data_command *l = (const void *)c;
            im->chained_off = l->dataoff; im->chained_size = l->datasize;
            break;
        }
        case LC_DYLD_EXPORTS_TRIE: {
            const struct linkedit_data_command *l = (const void *)c;
            im->trie_off = l->dataoff; im->trie_size = l->datasize;
            break;
        }
        case LC_DYLD_INFO:
        case LC_DYLD_INFO_ONLY:
            im->dyld_info = (const void *)c;
            if (!im->trie_off) {
                im->trie_off = im->dyld_info->export_off;
                im->trie_size = im->dyld_info->export_size;
            }
            break;
        case LC_SYMTAB:
            im->symtab = (const void *)c;
            break;
        default:
            break;    /* LC_UUID, LC_BUILD_VERSION, LC_CODE_SIGNATURE, ... */
        }
        lc += c->cmdsize;
    }

    if (!have_text) mr_die("%s: no __TEXT segment", im->path);
}

/* --------------------------------------------------------------- loading */

mr_image *mr_image_load(const char *want, mr_image *loader, int weak, int is_main)
{
    char *tried[MAX_TRIED];
    int   ntried = 0, is_runtime = 0;
    char *path;
    mr_image *im;
    int fd;
    struct stat st;
    void *raw;

    if (is_main) {
        path = mr_file_exists(want) ? mr_xstrdup(want) : NULL;
        if (!path) mr_die("cannot open %s: no such file", want);
    } else {
        mr_image *dup = mr_image_find_loaded(want);
        if (dup) return dup;
        path = resolve_dylib_path(want, loader, tried, &ntried, &is_runtime);
        if (!path) {
            if (weak) {
                mr_log("weak dylib %s not found; its binds will resolve to NULL", want);
                return NULL;
            }
            /* BEFORE the report, and it is not cosmetic: _exit does not flush,
             * and the guest shares this stdout. Without it a fixture that
             * printed eleven passing lines and then hit this looks like a
             * fixture that printed nothing -- measured, on loader_path's first
             * Linux run. mr_die does the same for the same reason; these two
             * bare _exit sites had been missed. */
            fflush(stdout);
            fprintf(stderr, "machorun: cannot find dylib '%s'\n", want);
            fprintf(stderr, "  required by: %s\n", loader ? loader->path : "(main)");
            for (int i = 0; i < ntried; i++)
                fprintf(stderr, "  tried: %s\n", tried[i]);
            if (want[0] == '/')
                fprintf(stderr,
                        "  Darwin absolute paths are redirected into our own tree at %s.\n"
                        "  Nothing else can satisfy them: %s is not a file on Linux, and\n"
                        "  (measured) not a file on macOS either -- it lives in the dyld\n"
                        "  shared cache. Build or add that dylib under darwin/.\n",
                        MR.darwin_root ? MR.darwin_root : "(no darwin root found)", want);
            _exit(72);
        }
    }

    if ((im = mr_image_find_loaded(path)) != NULL) { free(path); return im; }

    im = mr_xmalloc(sizeof(*im));
    im->path = path;
    im->dir = mr_dirname(path);
    im->is_main = is_main;
    im->is_runtime = is_runtime;

    fd = open(path, O_RDONLY | O_CLOEXEC);
    if (fd < 0) mr_die("cannot open %s: %m", path);
    im->fd = fd;
    if (fstat(fd, &st) != 0) mr_die("cannot stat %s: %m", path);
    im->raw_len = (size_t)st.st_size;
    im->dev = st.st_dev;
    im->ino = st.st_ino;

    /* DYLD'S SECOND DEDUPE TEST: the path resolved to a FILE THAT IS ALREADY
     * LOADED. The string test above (mr_image_find_loaded) catches a request
     * naming a loaded install name or path; it cannot catch a SYMLINK, whose
     * resolved path is a string nobody has seen. dyld loads such an image ONCE
     * -- measured, docs/DUP_IMAGES.md variant 4 -- and without this machorun
     * loaded it twice. Two copies of a dylib is two copies of its statics, its
     * constructors, and, when the dylib is CoreFoundation, its ObjC classes.
     *
     * WHAT THIS MUST NOT DO, and the asymmetry IS the design: two DISTINCT
     * FILES that happen to share an LC_ID_DYLIB stay TWO images. dyld keeps
     * them separate (variant 3, and that is the CoreFoundation case this
     * project actually hit), so a dedupe keyed on the install name would
     * collapse them -- looking like a better result while diverging from
     * Darwin. (st_dev, st_ino) draws the line where dyld draws it: the same
     * FILE, never merely the same NAME.
     *
     * Placed after the fstat because it needs one, and before the mmap so a
     * duplicate is never mapped at all. */
    for (int i = 0; i < MR.nimages; i++) {
        mr_image *other = MR.images[i];
        if (other->dev != st.st_dev || other->ino != st.st_ino) continue;
        mr_log("%s is the same file as %s (dev %llu ino %llu); aliasing it "
               "rather than loading a second copy", path, other->path,
               (unsigned long long)st.st_dev, (unsigned long long)st.st_ino);
        close(fd);
        free(im->dir);
        free(im);
        free(path);
        return other;
    }

    raw = mmap(NULL, im->raw_len, PROT_READ, MAP_PRIVATE, fd, 0);
    if (raw == MAP_FAILED) mr_die("cannot map %s for parsing: %m", path);
    im->raw = raw;

    im->slice_off = select_slice(im);
    im->mh = (const struct mach_header_64 *)mr_file_at(im, 0, sizeof(struct mach_header_64), "mach header");

    if (im->mh->cputype != MR_HOST_CPU_TYPE)
        mr_die("%s: cputype 0x%x is not this host's %s (CPU type 0x%x). "
               "machorun does not emulate; rebuild the guest for %s.",
               path, im->mh->cputype, MR_HOST_CPU_NAME, MR_HOST_CPU_TYPE, MR_HOST_CPU_NAME);
    if ((im->mh->cpusubtype & ~CPU_SUBTYPE_MASK) == CPU_SUBTYPE_ARM64E)
        mr_unimplemented("arm64e",
                         "%s: cpusubtype 2 means pointer authentication and chained pointer "
                         "format 1 (DYLD_CHAINED_PTR_ARM64E), whose signing keys are "
                         "process-scoped on Darwin. Out of scope; build for arm64.", path);
    im->filetype = im->mh->filetype;
    im->mh_flags = im->mh->flags;

    parse_load_commands(im);

    /* Registered before dependencies so a cycle terminates. */
    mr_image_append(im);
    if (is_main) MR.main_image = im;

    mr_map_image(im);
    mr_exports_parse(im);
    close(fd);
    im->fd = -1;

    mr_log("loaded %s at 0x%llx (slide 0x%llx, %d segments, %d deps, %zu exports)",
           im->path, (unsigned long long)im->load_base, (unsigned long long)im->slide,
           im->nsegs, im->ndeps, im->nexports);

    for (int i = 0; i < im->ndeps; i++)
        im->deps[i].img = mr_image_load(im->deps[i].path, im, im->deps[i].weak, 0);

    return im;
}

/* ===================================================================== *
 * dlopen, for GUEST Mach-O images.
 *
 * This is the startup sequence in src/main.c, performed on demand for one
 * image instead of for the whole graph, and it must be the SAME sequence or a
 * dlopen'd image differs from a linked one in ways nobody would predict:
 *
 *     load (pulls in its own dependencies, deduped against MR.images)
 *     fixups, NEWEST FIRST -- a bind in the new image can name a symbol in an
 *       image it dragged in, so everything must be mapped before anything is
 *       bound, exactly as at startup
 *     protect read-only segments, set up TLV
 *     objc map_images for the new images ONLY
 *     initialisers, which deliver load_images (+load) per image
 *
 * THE HANDLE IS THE mr_image *. It is already the token objc4 receives as
 * `sectionLocationMetadata`, it is stable for the life of the process because
 * images are never unmapped, and it makes dlsym a lookup in one export trie
 * rather than a search. dlopen(NULL) means "the main program" on Darwin, which
 * is MR.main_image.
 *
 * "THE LOADING IMAGE" FOR A dlopen IS THE IMAGE THAT CALLED IT, AND THAT IS
 * WHAT caller_ra IS FOR. It decides three things, not one:
 *
 *     @loader_path/    the caller's directory
 *     @rpath/          the caller's LC_RPATHs are searched first, the main
 *                      executable's second -- and each of those LC_RPATHs may
 *                      itself begin @loader_path, so the caller decides twice
 *     a relative path  tried against the caller's directory before the cwd
 *
 * All three used to be answered with MR.main_image, which is right only while
 * the caller IS the main executable. A plugin that dlopens its own sibling by
 * @loader_path is the ordinary case on Darwin -- it is how a framework loads
 * its helpers -- and answering from the main executable does not fail loudly:
 * it looks in the WRONG DIRECTORY, so it either returns NULL for a library
 * that is present, or finds a different file of the same name and returns a
 * handle to it. tests/bin/loader_path stages exactly that: the same string,
 * "@loader_path/libloader_path_leaf.dylib", dlopen'd from two images that sit
 * in different directories, and the two answers must be different files.
 *
 * @executable_path DOES NOT MOVE. It means the main executable in every image,
 * which is the whole difference between the two spellings, so the fixture
 * checks that this change did not sweep it along.
 *
 * caller_ra comes from libSystem's dlopen, where __builtin_return_address(0)
 * is the guest's own return address -- the same one-line trick that answers
 * dlsym's RTLD_NEXT/RTLD_SELF, because it is the same missing notion.
 * ===================================================================== */
void mr_objc_note_new_images(int from);

void *mr_dlopen(const char *path, int mode, const void *caller_ra)
{
    int before = MR.nimages;
    mr_image *im, *caller;

    char *tried[MAX_TRIED], *resolved;
    int ntried = 0, is_runtime = 0;

    if (!path) return MR.main_image;          /* Darwin: a handle for the program */

    /* NULL is the loader calling itself and means the main executable. A
     * non-NULL address in no image cannot be a guest frame, and silently
     * falling back to the main image there would reintroduce exactly the wrong
     * answer this argument exists to remove -- so say it instead. */
    caller = caller_ra ? mr_image_containing(caller_ra) : MR.main_image;
    if (!caller)
        mr_die("dlopen(\"%s\"): called from 0x%llx, which is not in any Mach-O image. "
               "@loader_path and @rpath resolve against the CALLING image, so there is "
               "no honest answer from here. A loader or glibc frame means libSystem's "
               "dlopen was reached other than by a guest call.",
               path, (unsigned long long)(uintptr_t)caller_ra);

    /* RESOLVE BEFORE ASKING WHETHER IT IS LOADED. The caller's spelling is
     * almost never the table's: a guest says "./libfoo.dylib" and the image
     * table holds the resolved filesystem path, or an @rpath install name.
     * Comparing raw strings makes RTLD_NOLOAD answer "not loaded" about an
     * image that IS -- MEASURED, not feared: the first version of this
     * returned NULL from the fixture's second RTLD_NOLOAD where real dyld
     * returns the handle, and only that check caught it. dyld canonicalises
     * for the same reason.
     *
     * The raw check stays as well, because an install name ("/usr/lib/
     * libSystem.B.dylib") is a legitimate spelling that resolution would
     * redirect into darwin/ rather than match. */
    im = mr_image_find_loaded(path);
    if (!im) {
        resolved = resolve_dylib_path(path, caller, tried, &ntried, &is_runtime);
        /* NOT FOUND IS AN ANSWER HERE, NOT AN ERROR, AND THAT IS THE ONE PLACE
         * dlopen PARTS COMPANY WITH A LOAD COMMAND. An LC_LOAD_DYLIB that
         * cannot be resolved is fatal: the program was linked against it and
         * cannot run. A dlopen that cannot be resolved returns NULL, and
         * asking is a normal thing to do -- "is this optional framework
         * present?" is how CoreFoundation decides which branch to take, and it
         * asks about libraries it fully expects to be absent.
         *
         * mr_image_load prints its tried-list and _exit(72)s, which is right
         * for its own callers and wrong for this one. FOUND BY tests/bin/
         * loader_path, whose last case dlopens a library that is deliberately
         * in neither directory: on Linux the whole fixture died at exit 72
         * with no stdout, having already passed the eleven checks before it.
         * The `dlopen` fixture never reached this because every path it names
         * exists, and RTLD_NOLOAD returns below before getting here. */
        if (!resolved) {
            mr_log("dlopen: %s not found (%d path(s) tried); returning NULL", path, ntried);
            for (int i = 0; i < ntried; i++) free(tried[i]);
            return NULL;
        }
        im = mr_image_find_loaded(resolved);
        free(resolved);
    }
    for (int i = 0; i < ntried; i++) free(tried[i]);
    if (im) return im;                        /* already in, including RTLD_NOLOAD */
    if (mode & MR_RTLD_NOLOAD) return NULL;   /* the honest "not loaded" */

    im = mr_image_load(path, caller, 0, 0);
    if (!im) return NULL;

    for (int k = MR.nimages - 1; k >= before; k--) mr_fixups_apply(MR.images[k]);
    for (int k = before; k < MR.nimages; k++) mr_protect_readonly_segments(MR.images[k]);
    for (int k = before; k < MR.nimages; k++) mr_tlv_setup(MR.images[k]);

    mr_objc_note_new_images(before);
    mr_run_initialisers(im);

    mr_log("dlopen: %s at 0x%llx (%d new image(s))",
           im->path, (unsigned long long)im->load_base, MR.nimages - before);
    return im;
}

/* dlsym on a real handle: one image's export trie, following its re-exports
 * the same way a two-level bind does. */
void *mr_dlsym_handle(void *handle, const char *name);
void *mr_dlsym_handle(void *handle, const char *name)
{
    mr_image *im = handle;
    uint64_t addr = 0;

    if (!im || !name) return NULL;
    for (int i = 0; i < MR.nimages; i++)
        if (MR.images[i] == im)
            return mr_exports_lookup(im, name, &addr) ? (void *)(uintptr_t)addr : NULL;

    mr_die("dlsym: handle %p is not an image machorun loaded. A machorun dlopen "
           "handle is the mr_image pointer; anything else is a handle from a "
           "different dynamic linker.", handle);
}

/* ===================================================================== *
 * dladdr, for GUEST Mach-O images.
 *
 * "Which image and symbol is this address in" is a question the loader has
 * always been able to answer -- src/crash.c has answered it for every guest
 * fault since the backtrace landed -- and forwarding it to glibc would answer
 * about the LOADER's ELF world, which is a different program with different
 * addresses. So this is a Dl_info shape around machinery that exists.
 *
 * IT READS THE SYMBOL TABLE, NOT THE EXPORT TRIE, and that difference is the
 * whole reason it is worth doing properly. MEASURED on macOS: dladdr on a
 * static, non-exported function returns its name. The export trie has no such
 * symbol -- it carries only what the image vends -- so a trie-based dladdr
 * would return dli_sname = NULL for exactly the addresses a backtrace or a
 * crash report cares about most. LC_SYMTAB has them.
 *
 * WHAT MACOS ACTUALLY RETURNS, measured rather than assumed, because three of
 * these four are easy to get backwards:
 *
 *     dli_sname     WITHOUT the leading underscore ("printf", not "_printf")
 *     dli_saddr     the symbol's live address, exactly
 *     dli_fbase     the mach header, i.e. the image's load base
 *     return value  1 on success; 0 for a stack address and for NULL -- NOT
 *                   -1, and not errno. dlerror() is not set either.
 *
 * A defined symbol whose address we cannot name still returns 1 with
 * dli_sname and dli_saddr NULL, which is what Darwin's man page specifies and
 * what a stripped image produces.
 * ===================================================================== */
#define MR_N_STAB 0xe0
#define MR_N_TYPE 0x0e
#define MR_N_SECT 0x0e

int mr_dladdr(const void *addr, mr_dl_info *out)
{
    uint64_t a = (uint64_t)(uintptr_t)addr;
    mr_image *im = NULL;
    const struct nlist_64 *syms;
    const char *strs;
    uint64_t best_val = 0;
    const char *best_name = NULL;

    if (!out) return 0;
    out->dli_fname = NULL; out->dli_fbase = NULL;
    out->dli_sname = NULL; out->dli_saddr = NULL;

    im = mr_image_containing(addr);
    if (!im) return 0;                       /* a stack address, glibc, the loader */

    /* Darwin reports the path the image was loaded by. For a dylib that is its
     * install name (/usr/lib/libfoo.dylib), not the file we opened underneath
     * darwin/ -- a guest comparing this against its own load commands would
     * otherwise never match. */
    out->dli_fname = im->install_name ? im->install_name : im->path;
    out->dli_fbase = (void *)(uintptr_t)im->load_base;

    if (!im->symtab || !im->symtab->nsyms) return 1;   /* stripped: no name to give */

    syms = mr_file_at(im, im->symtab->symoff,
                      (uint64_t)im->symtab->nsyms * sizeof(*syms), "LC_SYMTAB symbols");
    strs = mr_file_at(im, im->symtab->stroff, im->symtab->strsize, "LC_SYMTAB strings");
    if (!syms || !strs) return 1;

    /* Greatest defined symbol at or below the address. N_STAB entries are
     * debug records with a reused n_value and must be skipped, or a stabs
     * image answers with a source file name. */
    for (uint32_t k = 0; k < im->symtab->nsyms; k++) {
        uint64_t live;
        if (syms[k].n_type & MR_N_STAB) continue;
        if ((syms[k].n_type & MR_N_TYPE) != MR_N_SECT) continue;   /* not defined here */
        if (syms[k].n_strx >= im->symtab->strsize) continue;
        live = syms[k].n_value + (uint64_t)im->slide;
        if (live > a || live < best_val) continue;
        best_val = live;
        best_name = strs + syms[k].n_strx;
    }

    if (best_name && best_name[0]) {
        /* Darwin strips the Mach-O underscore. Measured: "printf", not
         * "_printf". */
        out->dli_sname = best_name[0] == '_' ? best_name + 1 : best_name;
        out->dli_saddr = (void *)(uintptr_t)best_val;
    }
    return 1;
}

/* THE ONE PLACE THAT ANSWERS "WHICH IMAGE IS THIS ADDRESS IN".
 *
 * There were four copies of this loop -- crash.c's image_of, objc_notify.c's
 * image_containing, this one, and an inline scan in mr_dladdr -- and all four
 * agreed, which is the condition under which duplication is cheapest to remove
 * and most likely to be left alone. The predicate is a half-open interval, and
 * a copy that drifted to `<= span_hi` would put an address one byte past an
 * image inside it: a wrong image name in a backtrace, a wrong answer from
 * dladdr, and a dlsym scope starting one image too early. None of those looks
 * like a bug at the call site.
 *
 * It also IS "the calling image" -- the notion whose absence kept dlsym's
 * RTLD_NEXT / RTLD_SELF / RTLD_MAIN_ONLY unimplemented and dlopen's
 * @loader_path approximate. Four questions that look unrelated in a symbol
 * census are this one function plus a return address. Callable from a signal
 * handler: it takes no lock and allocates nothing, which crash.c depends on. */
/* THE _dyld_* IMAGE-INTROSPECTION FAMILY, which libSystem cannot answer.
 *
 * CoreFoundation walks the loaded images to find bundles and to map addresses
 * back to binaries. On Darwin that is dyld's own table; here the loader IS
 * dyld, so MR.images is the table and libSystem has no view of it -- the same
 * reason _NSGetExecutablePath and dladdr had to come from this side.
 *
 * INDEX 0 IS THE MAIN EXECUTABLE, which is a contract rather than an accident:
 * mr_image_load registers an image BEFORE its dependencies (so a dependency
 * cycle terminates), and the main image is loaded first, so it lands at 0
 * exactly as dyld promises. tests/bin/dyld_images asserts it rather than
 * leaving it to the comment.
 *
 * Out-of-range indices return NULL/0 rather than aborting, because that is
 * what dyld does and because the standard idiom is to walk until the header
 * comes back NULL -- aborting would turn every correct caller into a crash. */
uint32_t mr_dyld_image_count(void)
{
    return (uint32_t)MR.nimages;
}

const void *mr_dyld_image_header(uint32_t i)
{
    if (i >= (uint32_t)MR.nimages) return NULL;
    return (const void *)(uintptr_t)MR.images[i]->load_base;
}

const char *mr_dyld_image_name(uint32_t i)
{
    if (i >= (uint32_t)MR.nimages) return NULL;
    return MR.images[i]->path;
}

intptr_t mr_dyld_image_slide(uint32_t i)
{
    if (i >= (uint32_t)MR.nimages) return 0;
    return (intptr_t)MR.images[i]->slide;
}

mr_image *mr_image_containing(const void *addr)
{
    uint64_t a = (uint64_t)(uintptr_t)addr;
    for (int i = 0; i < MR.nimages; i++)
        if (a >= MR.images[i]->span_lo && a < MR.images[i]->span_hi) return MR.images[i];
    return NULL;
}

/* dlsym's scoped handles. `which` is the Darwin pseudo-handle as an integer:
 * -1 RTLD_NEXT, -3 RTLD_SELF, -5 RTLD_MAIN_ONLY.
 *
 * NEXT and SELF differ by one image: SELF searches the caller's image and
 * everything after it in load order, NEXT starts after the caller. "After" is
 * load order, which is what dyld means by it too. */
void *mr_dlsym_scoped(const void *caller_ra, int which, const char *name)
{
    mr_image *caller = mr_image_containing(caller_ra);
    uint64_t addr = 0;
    int start;

    if (which == -5) {                                    /* RTLD_MAIN_ONLY */
        return MR.main_image && mr_exports_lookup(MR.main_image, name, &addr)
                 ? (void *)(uintptr_t)addr : NULL;
    }
    if (!caller)
        mr_die("dlsym: RTLD_NEXT/RTLD_SELF from 0x%llx, which is not in any Mach-O image. "
               "The caller must be guest code; a loader or glibc frame means libSystem's "
               "dlsym was reached other than by a guest call.",
               (unsigned long long)(uintptr_t)caller_ra);

    for (start = 0; start < MR.nimages; start++)
        if (MR.images[start] == caller) break;
    if (which == -1) start++;                             /* RTLD_NEXT skips the caller */

    for (int i = start; i < MR.nimages; i++)
        if (mr_exports_lookup(MR.images[i], name, &addr)) return (void *)(uintptr_t)addr;
    return NULL;
}
