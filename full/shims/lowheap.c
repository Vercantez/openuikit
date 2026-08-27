/* lowheap.c -- MEASUREMENT ONLY: serve the guest's C heap from below 2^47.
 *
 * NOT A PRODUCT, and not part of the default build. It is compiled into a
 * SECOND libSystem umbrella (libSystem.B.lowheap.dylib) that the runner swaps
 * in only when asked, so the scoreboard's headline numbers always come from
 * the unmodified stack.
 *
 * WHAT IT MEASURES. In the full 108-scene suite, 51 of the 59 failures die at
 * libswiftCore+0x2dce0 (_swift_initClassMetadataImpl) on a fault address of
 * the form 0x2aaa_xxxx_xxxx -- which is a glibc brk-heap pointer
 * 0xaaaa_xxxx_xxxx with bit 47 cleared by Apple's 47-bit isa mask. machorun's
 * fix/map-below-isa-mask arena places IMAGES below 2^47 but cannot move the C
 * heap, and class metadata instantiated at runtime is malloc'd.
 *
 * The roadmap question is whether those 51 are ONE bug or many. Moving the
 * heap below 2^47 answers it directly and cheaply: if they all render, the
 * remaining work is a guest malloc arena and nothing else.
 *
 * WHY A BUMP ALLOCATOR IS HONEST HERE. This process renders one scene and
 * exits. free() is a no-op, realloc always copies forward: no fragmentation,
 * no reuse, no thread contention to get wrong. That is adequate for a one-shot
 * process and unacceptable for anything longer-lived -- which is exactly why
 * it is a separate dylib and not the default. A real fix is a proper allocator
 * over a low arena, and it belongs in machorun's libSystem, not here.
 */

#include <stddef.h>
#include <stdlib.h>
#include <string.h>

extern long write(int, const void *, unsigned long);
extern void *mmap(void *, unsigned long, int, int, int, long);

/* 64 GiB. The loader's own image arena starts at 8 GiB and probes upward in
 * 2 MiB steps for at most 16 GiB (machorun src/map.c), so 64 GiB is clear of
 * it, clear of a 4 GiB executable at 0x100000000, and far below 2^47. */
#define BASE   0x1000000000ull
#define SIZE   (2048ull << 20)      /* 2 GiB */
#define ALIGN  16

static unsigned char *cur, *end;

__attribute__((noreturn)) static void die(const char *m, unsigned long n)
{
    write(2, m, n);
    abort();
}

static void init(void)
{
    /* DARWIN mmap flags, not Linux ones: machorun's libSystem translates
     * MAP_ANON 0x1000 -> 0x20 and passes MAP_PRIVATE/MAP_FIXED through, but it
     * masks everything else off, so MAP_FIXED_NOREPLACE is not available here.
     * The address is therefore a HINT and the result is CHECKED -- taking
     * MAP_FIXED instead would silently clobber whatever happened to be there.
     * PROT_READ|PROT_WRITE = 3, MAP_PRIVATE|MAP_ANON = 0x1002. */
    void *p = mmap((void *)BASE, SIZE, 3, 0x02 | 0x1000, -1, 0);
    unsigned long long a = (unsigned long long)p;
    if (p == (void *)-1 || a == 0 || a + SIZE > 0x800000000000ull) {
        static const char m[] = "lowheap: no arena below 2^47 (hint refused); "
                                "the measurement cannot run\n";
        die(m, sizeof(m) - 1);
    }
    cur = (unsigned char *)p;
    end = cur + SIZE;
}

/* 16-byte header holds the size, so malloc_size and realloc are exact rather
 * than estimates -- the Swift runtime asks for both. */
static void *bump(size_t n, size_t align)
{
    if (!cur) init();
    if (align < ALIGN) align = ALIGN;
    unsigned char *p = cur + ALIGN;
    size_t mis = (size_t)(unsigned long)p & (align - 1);
    if (mis) p += align - mis;
    if (p + n > end) {
        static const char m[] = "lowheap: arena exhausted (raise SIZE in lowheap.c)\n";
        die(m, sizeof(m) - 1);
    }
    ((size_t *)p)[-1] = n;
    cur = p + n;
    return p;
}

void *malloc(size_t n)              { return bump(n ? n : 1, ALIGN); }
void *calloc(size_t c, size_t n)    { size_t t = c * n; return bump(t ? t : 1, ALIGN); }
                                    /* fresh anonymous pages are already zero */
void  free(void *p)                 { (void)p; }
void *valloc(size_t n)              { return bump(n ? n : 1, 16384); }
size_t malloc_size(const void *p)   { return p ? ((const size_t *)p)[-1] : 0; }
size_t malloc_good_size(size_t n)   { return n; }

void *realloc(void *p, size_t n)
{
    if (!p) return bump(n ? n : 1, ALIGN);
    size_t old = ((size_t *)p)[-1];
    if (n <= old) return p;
    void *q = bump(n, ALIGN);
    memcpy(q, p, old);
    return q;
}

int posix_memalign(void **out, size_t align, size_t n)
{
    if (!out) return 22;                       /* EINVAL */
    *out = bump(n ? n : 1, align);
    return 0;
}
