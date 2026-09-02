/*
 * compat/mach/machine.h  --  objc4-linux
 *
 * Mach cputype/cpusubtype constants. objc4 reads them off the main
 * executable's header to detect an arm64e process (pointer authentication).
 * Our per-image record (compat/mach-o/loader.h) carries the same fields; we
 * fill in the host architecture and never arm64e, because __has_feature(
 * ptrauth_calls) is 0 on Linux -- MEASURED, see docs/PORT_MAP.md 1.2.
 */
#ifndef _OBJC4LINUX_MACH_MACHINE_H
#define _OBJC4LINUX_MACH_MACHINE_H

#define CPU_ARCH_ABI64          0x01000000
#define CPU_TYPE_ARM            12
#define CPU_TYPE_ARM64          (CPU_TYPE_ARM | CPU_ARCH_ABI64)
#define CPU_TYPE_X86            7
#define CPU_TYPE_X86_64         (CPU_TYPE_X86 | CPU_ARCH_ABI64)

#define CPU_SUBTYPE_MASK        0xff000000
#define CPU_SUBTYPE_ARM64_ALL   0
#define CPU_SUBTYPE_ARM64_V8    1
#define CPU_SUBTYPE_ARM64E      2

#endif
