/* lockprobe.c -- DIAGNOSTIC. What is in the lock word at an unlock, and is the
 * ownership bail fatal-in-fact or fatal-by-policy?
 *
 * machorun stores the owner's thread token in the guest's four bytes and bails
 * from unlock if the word != the caller's token. On a SINGLE-THREADED guest --
 * measured: pthread_create is never called -- that token is constant, so a
 * mismatch means the WORD changed by some route other than lock/unlock.
 *
 * mr_bail and mr_thread_token are both HIDDEN, so this cannot reproduce the
 * check exactly. It does the next best thing: records every distinct value it
 * ever sees in a lock word at unlock, does the unlock unconditionally, and
 * reports the set at exit. If every value is one small integer, the tokens are
 * fine and the bail is about something else. If a wild value appears, the four
 * bytes were overwritten -- which is the corruption itself, caught at the one
 * place the runtime checks its own invariant.
 *
 * NOT A FIX: skipping the ownership check is exactly the silent-corruption
 * behaviour the real implementation refuses. This build is for reading only.
 */
#include <stdint.h>
extern long write(int, const void *, unsigned long);

#define NSEEN 16
static unsigned seen[NSEEN];
static int nseen;
static unsigned long ncalls;

static void hex(unsigned long long v, char *o, int digits)
{
    static const char d[] = "0123456789abcdef";
    for (int i = digits - 1; i >= 0; i--) { o[i] = d[v & 0xf]; v >>= 4; }
}

static void report(void)
{
    char b[256]; int n = 0;
    static const char h[] = "lockprobe: unlocks=0x";
    for (unsigned i = 0; i < sizeof(h) - 1; i++) b[n++] = h[i];
    hex(ncalls, b + n, 8); n += 8;
    static const char m[] = "  distinct owner values seen:";
    for (unsigned i = 0; i < sizeof(m) - 1; i++) b[n++] = m[i];
    for (int i = 0; i < nseen; i++) {
        b[n++] = ' '; b[n++] = '0'; b[n++] = 'x';
        hex(seen[i], b + n, 8); n += 8;
    }
    b[n++] = '\n';
    write(2, b, (unsigned long)n);
}

void os_unfair_lock_unlock(void *l);
void os_unfair_lock_unlock(void *l)
{
    unsigned *w = l;
    unsigned owner = __atomic_load_n(w, __ATOMIC_RELAXED);
    ncalls++;
    int known = 0;
    for (int i = 0; i < nseen; i++) if (seen[i] == owner) { known = 1; break; }
    if (!known && nseen < NSEEN) { seen[nseen++] = owner; if (nseen == 1 || owner > 0xffff) report(); }
    __atomic_store_n(w, 0u, __ATOMIC_RELEASE);
}

__attribute__((destructor)) static void lockprobe_fini(void) { report(); }
