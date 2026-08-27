/* freeprobe.c -- DIAGNOSTIC ONLY. Tests one hypothesis:
 *
 *   machorun's malloc_size() answers Darwin's "is this pointer mine?" contract
 *   with `if (mr_addr_in_image(p)) return 0; return glibc_malloc_usable_size(p)`.
 *   That covers pointers inside MAPPED GUEST IMAGES and nothing else. glibc's
 *   malloc_usable_size does no validation -- it reads the word before the
 *   pointer -- so for any OTHER non-glibc pointer it returns a plausible
 *   non-zero number, objc4's try_free believes it owns the block, and frees it.
 *
 * So: count free() calls, and report the ones whose chunk header word is
 * implausible, plus whether the pointer is in an image. If the last thing
 * before "free(): invalid size" is an in-image or wild pointer, the hypothesis
 * holds.
 */
#include <stddef.h>
#include <stdint.h>
extern long write(int, const void *, unsigned long);
extern void glibc_free_real(void *) __asm__("_glibc_free");
extern int mr_addr_in_image(const void *p);

static void hex(unsigned long long v, char *o) {
    static const char d[] = "0123456789abcdef";
    for (int i = 15; i >= 0; i--) { o[i] = d[v & 0xf]; v >>= 4; }
}
static void say(const char *tag, const void *p, unsigned long long hdr, int inimg) {
    char b[96]; int n = 0;
    while (*tag) b[n++] = *tag++;
    b[n++] = ' '; b[n++] = 'p'; b[n++] = '='; hex((unsigned long long)(uintptr_t)p, b + n); n += 16;
    b[n++] = ' '; b[n++] = 'h'; b[n++] = '='; hex(hdr, b + n); n += 16;
    b[n++] = ' '; b[n++] = 'i'; b[n++] = 'm'; b[n++] = 'g'; b[n++] = '=';
    b[n++] = (char)('0' + (inimg ? 1 : 0));
    b[n++] = '\n';
    write(2, b, (unsigned long)n);
}

void free(void *p);
void free(void *p)
{
    if (p) {
        unsigned long long hdr = ((unsigned long long *)p)[-1];
        int inimg = mr_addr_in_image(p);
        /* glibc chunk size lives in hdr with the low 3 bits as flags. A size
         * that is zero, absurdly large, or not 16-byte aligned is not a chunk
         * this allocator produced. */
        unsigned long long sz = hdr & ~0x7ULL;
        if (inimg || sz == 0 || sz > (1ULL << 32) || (sz & 0xf))
            say("freeprobe SUSPECT", p, hdr, inimg);
    }
    glibc_free_real(p);
}
