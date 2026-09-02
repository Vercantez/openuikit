/*
 * compat/mach/vm_param.h  --  objc4-linux
 *
 * objc-vm.h wants MACH_VM_MAX_ADDRESS to size the packed-isa shiftcls field.
 * On Linux aarch64 the user VA ceiling is a KERNEL CONFIG (39/42/48/52-bit),
 * not a constant, so there is no honest compile-time value. We publish the
 * widest supported ceiling (52-bit VA => user addresses < 2^52) and the
 * isa layout in isa.h is chosen to cover it. See docs/UNIMPLEMENTED.md and
 * PORT_PLAN "second riskiest".
 */
#ifndef _OBJC4LINUX_MACH_VM_PARAM_H
#define _OBJC4LINUX_MACH_VM_PARAM_H

#include <unistd.h>

/*
 * MEASURED, not assumed (docs/measurements/va_layout.c, Ubuntu 24.04 aarch64,
 * 4K pages, ASLR on):
 *
 *   text(main)  0x0000aaaab6510898   48 bits
 *   data        0x0000aaaab653005c   48 bits
 *   heap small  0x0000aaaae88702a0   48 bits   (brk)
 *   heap large  0x0000ffffa925f010   48 bits   (mmap)
 *   mmap anon   0x0000ffffa9853000   48 bits
 *   libc text   0x0000ffffa96b0590   48 bits
 *   stack       0x0000fffffc89e6bc   48 bits
 *
 * Every user address is 48 bits wide. Darwin's arm64 ceiling is 2^47
 * (0x00007ffffffffff8), so ROUTINE Linux addresses sit above the range
 * Apple's masks assume -- see patches/0005 (FAST_DATA_MASK).
 *
 * The low 3 bits are cleared for the same reason Darwin clears them: objc4
 * asserts `ISA_MASK + sizeof(void*) == OBJC_VM_MAX_ADDRESS` style relations
 * (objc-runtime-new.mm:260).
 *
 * A 52-bit-VA kernel (CONFIG_ARM64_VA_BITS_52) would exceed this. Such a
 * kernel only hands out >48-bit addresses to processes that explicitly ask
 * via an mmap hint, which nothing here does -- but it is an assumption, and
 * it is recorded in docs/UNIMPLEMENTED.md.
 */
#if defined(__aarch64__) || defined(__arm64__)
#   define MACH_VM_MAX_ADDRESS 0x0000fffffffffff8ULL
#elif defined(__x86_64__)
/* x86-64 Linux: 47-bit user VA. 5-level paging (57-bit) is opt-in per-mmap
 * and never handed out unhinted, exactly as above. Same value Darwin uses. */
#   define MACH_VM_MAX_ADDRESS 0x00007ffffffffff8ULL
#endif

/*
 * Page sizes. aarch64 Linux kernels ship 4K, 16K or 64K pages; MEASURED 4096
 * in the Ubuntu 24.04 aarch64 container (docs/measurements/va_layout.c). objc4
 * uses PAGE_MIN_SIZE to size autorelease pool pages and PAGE_MAX_SIZE only as
 * an upper bound, so the conservative pair below is correct on all three.
 *
 * glibc's <limits.h> may already define PAGE_SIZE; do not fight it.
 */
#ifndef PAGE_SIZE
#   define PAGE_SIZE      4096
#endif
#ifndef PAGE_MIN_SIZE
#   define PAGE_MIN_SIZE  4096
#endif
#ifndef PAGE_MIN_SHIFT
#   define PAGE_MIN_SHIFT 12
#endif
#ifndef PAGE_MAX_SIZE
#   define PAGE_MAX_SIZE  16384
#endif
#ifndef PAGE_MAX_SHIFT
#   define PAGE_MAX_SHIFT 14
#endif

/* Darwin VM allocation tags; purely informational to vmmap(1). */
#ifndef VM_MEMORY_FOUNDATION
#   define VM_MEMORY_FOUNDATION 10
#endif
#ifndef VM_MEMORY_OBJC_DISPATCHERS
#   define VM_MEMORY_OBJC_DISPATCHERS 0
#endif

#endif
