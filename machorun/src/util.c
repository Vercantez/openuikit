/* util.c -- diagnostics and small helpers.
 *
 * Two rules the whole loader obeys:
 *   - every failure names what was missing (mr_die),
 *   - every unimplemented path aborts loudly and says what to implement
 *     (mr_unimplemented). Nothing silently no-ops.
 */
#define _GNU_SOURCE
#include "machorun.h"

#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/stat.h>

mr_state MR;

void mr_die(const char *fmt, ...)
{
    va_list ap;
    fflush(stdout);
    fputs("machorun: ", stderr);
    va_start(ap, fmt);
    vfprintf(stderr, fmt, ap);
    va_end(ap);
    fputc('\n', stderr);
    fflush(stderr);
    _exit(70);
}

void mr_unimplemented(const char *what, const char *fmt, ...)
{
    va_list ap;
    fflush(stdout);
    fprintf(stderr, "machorun: UNIMPLEMENTED: %s\n  ", what);
    va_start(ap, fmt);
    vfprintf(stderr, fmt, ap);
    va_end(ap);
    fputs("\n  see docs/UNIMPLEMENTED.md\n", stderr);
    fflush(stderr);
    _exit(71);
}

void mr_log(const char *fmt, ...)
{
    va_list ap;
    if (!MR.verbose) return;
    fputs("machorun: ", stderr);
    va_start(ap, fmt);
    vfprintf(stderr, fmt, ap);
    va_end(ap);
    fputc('\n', stderr);
}

void *mr_xmalloc(size_t n)
{
    void *p = calloc(1, n ? n : 1);
    if (!p) mr_die("out of memory allocating %zu bytes", n);
    return p;
}

/* Grow a loader-owned vector geometrically.  Every caller keeps pointers to
 * the objects IN the vector rather than into this storage, so relocating the
 * vector itself is safe.  Arithmetic is checked before realloc: an impossible
 * request must be a named loader failure, never a wrapped allocation followed
 * by an out-of-bounds write. */
void *mr_grow_array(void *storage, size_t *capacity, size_t required,
                    size_t element_size, const char *what)
{
    size_t next, old_bytes, new_bytes;
    void *grown;

    if (!capacity || !what || element_size == 0)
        mr_die("invalid dynamic-array request for %s", what ? what : "(unnamed)");
    if (required <= *capacity) return storage;
    if (required > SIZE_MAX / element_size)
        mr_die("%s capacity overflow: %zu element(s) of %zu bytes",
               what, required, element_size);

    next = *capacity ? *capacity : 16;
    while (next < required) {
        if (next > SIZE_MAX / 2) { next = required; break; }
        next *= 2;
    }
    if (next > SIZE_MAX / element_size)
        mr_die("%s capacity overflow: %zu element(s) of %zu bytes",
               what, next, element_size);

    old_bytes = *capacity * element_size;
    new_bytes = next * element_size;
    grown = realloc(storage, new_bytes);
    if (!grown)
        mr_die("out of memory growing %s from %zu to %zu element(s)",
               what, *capacity, next);
    memset((unsigned char *)grown + old_bytes, 0, new_bytes - old_bytes);
    *capacity = next;
    return grown;
}

char *mr_xstrdup(const char *s)
{
    char *p = strdup(s ? s : "");
    if (!p) mr_die("out of memory");
    return p;
}

char *mr_join(const char *a, const char *b)
{
    size_t la = strlen(a), lb = strlen(b);
    int    sep = (la && a[la - 1] != '/' && b[0] != '/');
    char  *r = mr_xmalloc(la + lb + 2);
    memcpy(r, a, la);
    if (sep) r[la] = '/';
    memcpy(r + la + sep, b, lb + 1);
    return r;
}

char *mr_dirname(const char *path)
{
    const char *slash = strrchr(path, '/');
    char *r;
    if (!slash) return mr_xstrdup(".");
    if (slash == path) return mr_xstrdup("/");
    r = mr_xmalloc((size_t)(slash - path) + 1);
    memcpy(r, path, (size_t)(slash - path));
    return r;
}

int mr_file_exists(const char *path)
{
    struct stat st;
    return stat(path, &st) == 0 && (S_ISREG(st.st_mode) || S_ISLNK(st.st_mode));
}

int mr_image_is_cache_extract_without_fixups(const mr_image *im)
{
    int has_data = 0;
    if (!im) return 0;
    if (im->filetype != MH_DYLIB && im->filetype != MH_BUNDLE)
        return 0;
    if (im->chained_size)
        return 0;
    if (im->dyld_info &&
        (im->dyld_info->rebase_size || im->dyld_info->bind_size ||
         im->dyld_info->weak_bind_size || im->dyld_info->lazy_bind_size))
        return 0;
    for (int i = 0; i < im->nsegs; i++) {
        const mr_segment *s = &im->segs[i];
        if (s->filesize == 0) continue;
        if (strcmp(s->name, "__DATA") == 0 ||
            strcmp(s->name, "__DATA_CONST") == 0 ||
            strcmp(s->name, "__DATA_DIRTY") == 0 ||
            strcmp(s->name, "__AUTH_CONST") == 0)
            has_data = 1;
    }
    return has_data;
}

uint64_t mr_uleb(const uint8_t **p, const uint8_t *end)
{
    uint64_t r = 0;
    int      shift = 0;
    for (;;) {
        uint8_t b;
        if (*p >= end) mr_die("truncated ULEB128 in linkedit data");
        b = *(*p)++;
        if (shift < 64) r |= (uint64_t)(b & 0x7f) << shift;
        shift += 7;
        if (!(b & 0x80)) break;
        if (shift > 70) mr_die("malformed ULEB128 (more than 10 bytes)");
    }
    return r;
}

int64_t mr_sleb(const uint8_t **p, const uint8_t *end)
{
    int64_t r = 0;
    int     shift = 0;
    uint8_t b;
    do {
        if (*p >= end) mr_die("truncated SLEB128 in linkedit data");
        b = *(*p)++;
        r |= (int64_t)(b & 0x7f) << shift;
        shift += 7;
    } while (b & 0x80);
    if (shift < 64 && (b & 0x40)) r |= -((int64_t)1 << shift);
    return r;
}
