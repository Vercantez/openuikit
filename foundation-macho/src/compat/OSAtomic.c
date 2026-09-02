/* OSAtomic.c — Darwin's OSAtomic primitives, for real.
 *
 * CoreFoundation reaches five of these (measured at the link line). Unlike
 * everything in scripts/cf_shims.sh, this is an IMPLEMENTATION, not a
 * measurement stub: each function below does what Darwin's does, via the
 * compiler's __atomic builtins.
 *
 * Semantics that are easy to get wrong and are asserted by CF's use:
 *   - OSAtomicIncrement32 / OSAtomicDecrement32 / OSAtomicAdd64 return the
 *     NEW value, not the old one. Darwin's do; __atomic_add_fetch does too,
 *     which is why these use _add_fetch rather than _fetch_add.
 *   - The plain (non-Barrier) forms are documented as NOT being full barriers,
 *     but Apple's arm64 implementations are sequentially consistent in practice
 *     and callers have come to rely on it. __ATOMIC_SEQ_CST is therefore the
 *     conservative and compatible choice; a weaker order would be a silent
 *     behavioural difference rather than a visible failure.
 *   - OSAtomicCompareAndSwapPtrBarrier returns true on success.
 *
 * These belong in machorun's libSystem eventually — they are Darwin platform
 * API, not Foundation. They live here for now because the sysroot/libSystem
 * work is owned elsewhere and this unblocks the CF link independently.
 */

#include <stdbool.h>
#include <stdint.h>

int32_t OSAtomicIncrement32(volatile int32_t *value) {
    return __atomic_add_fetch(value, 1, __ATOMIC_SEQ_CST);
}

int32_t OSAtomicDecrement32(volatile int32_t *value) {
    return __atomic_sub_fetch(value, 1, __ATOMIC_SEQ_CST);
}

int64_t OSAtomicAdd64(int64_t amount, volatile int64_t *value) {
    return __atomic_add_fetch(value, amount, __ATOMIC_SEQ_CST);
}

bool OSAtomicCompareAndSwapPtrBarrier(void *oldValue, void *newValue,
                                      void *volatile *theValue) {
    /* Strong CAS: no spurious failure, which is what Darwin promises and what
       CF's retain/release paths assume. __atomic_compare_exchange_n updates
       `expected` on failure, so pass a local rather than the caller's value. */
    void *expected = oldValue;
    return __atomic_compare_exchange_n(theValue, &expected, newValue,
                                       false /* strong */,
                                       __ATOMIC_SEQ_CST, __ATOMIC_SEQ_CST);
}

void OSMemoryBarrier(void) {
    __atomic_thread_fence(__ATOMIC_SEQ_CST);
}
