/* 06_tls -- rung (f): thread-local storage, single-threaded.
 *
 * Darwin does NOT use ELF-style TLS relocations. Each _Thread_local variable
 * gets a "thread-local variable descriptor" in __DATA,__thread_vars
 * (section type S_THREAD_LOCAL_VARIABLES): a 3-word struct
 *   { void *(*thunk)(void *self); unsigned long key; unsigned long offset; }
 * The compiler loads the descriptor address, loads thunk from word 0, and
 * calls it with the descriptor in x0. The thunk (tlv_get_addr, in libdyld on
 * real Darwin) returns the address of this thread's copy.
 *
 * Initialised values live in __DATA,__thread_data (S_THREAD_LOCAL_REGULAR)
 * and zero-init ones in __DATA,__thread_bss (S_THREAD_LOCAL_ZEROFILL); the
 * descriptor's `offset` is a byte offset into that per-thread image.
 *
 * Loader must: recognise the three section types, register a TLV image,
 * provide _tlv_bootstrap / tlv_get_addr, and honour __thread_bss zeroing.
 * This is a distinct mechanism from anything ELF gives you for free.
 */
#include <stdio.h>

_Thread_local int tls_init = 7;
_Thread_local long tls_zero;
_Thread_local char tls_buf[16] = "tls";
static _Thread_local int tls_static = 100;

int main(void) {
    printf("tls_init=%d\n", tls_init);
    printf("tls_zero=%ld\n", tls_zero);
    printf("tls_buf=%s\n", tls_buf);
    printf("tls_static=%d\n", tls_static);

    tls_init += 1;
    tls_zero += 2;
    tls_static *= 2;
    tls_buf[0] = 'T';

    printf("after tls_init=%d tls_zero=%ld tls_static=%d tls_buf=%s\n",
           tls_init, tls_zero, tls_static, tls_buf);
    return 0;
}
