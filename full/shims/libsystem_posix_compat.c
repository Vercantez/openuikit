/* libsystem_posix_compat.c -- libSystem umbrella additions reached only by
 * guests built for an iOS triple (docs/agent_reports/ios-target-route.md).
 *
 * Linked into the full/ libSystem umbrella next to syspatch/mathpatch/concpatch;
 * machorun itself is pinned (scripts/vendor_pins.sh), so the umbrella is where
 * a guest-facing libSystem symbol can be added on an agent branch.
 *
 * posix_madvise. swift-foundation-icu compiled for arm64-apple-ios26.0-simulator
 * maps its data and advises it; the macOS-triple build never referenced the
 * symbol, and machorun stopped at load with "undefined symbol
 * '_posix_madvise'" (wanted by lib_FoundationICU.dylib). MEASURED on macOS 26
 * and the iOS 26.1 simulator, identical transcripts
 * (full/iostarget/posix_madvise.c, full/iostarget/posix_madvise.expected):
 *
 *   advice 0..4 (NORMAL, RANDOM, SEQUENTIAL, WILLNEED, DONTNEED) -> 0;
 *   an invalid advice -> -1 with errno EINVAL. Darwin does NOT follow POSIX's
 *     "return the error number" here; glibc does;
 *   an unaligned address -> 0 (Linux's madvise EINVALs it);
 *   DONTNEED keeps the page's contents.
 *
 * Built on machorun's Darwin madvise, which already translates errno and the
 * advice numbering. DONTNEED is answered here and never forwarded: machorun's
 * madvise maps it to Linux MADV_DONTNEED, which zero-fills a private page --
 * the opposite of the measured contents-kept behaviour (glibc's own
 * posix_madvise ignores DONTNEED for the same reason). The start is widened
 * down to a 4 KiB boundary, the smallest Linux page on either guest arch.
 */
#include <errno.h>
#include <stddef.h>
#include <stdint.h>
#include <sys/mman.h>

int posix_madvise(void *addr, size_t len, int advice)
{
    if (advice < POSIX_MADV_NORMAL || advice > POSIX_MADV_DONTNEED) {
        errno = EINVAL;
        return -1;
    }
    if (advice == POSIX_MADV_DONTNEED)
        return 0;
    uintptr_t a = (uintptr_t)addr;
    uintptr_t start = a & ~(uintptr_t)4095;
    return madvise((void *)start, len + (size_t)(a - start), advice);
}
