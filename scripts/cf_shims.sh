#!/bin/bash
# Headers the staged Darwin sysroot does not carry but CoreFoundation reaches.
#
#   scripts/cf_shims.sh [outdir]        # default $HOME/work/cfextra
#
# READ THIS BEFORE TRUSTING ANY PASS COUNT THAT DEPENDS ON IT.
#
# Most of this file is a MEASUREMENT INSTRUMENT, not an implementation. The
# declarations exist so the compiler gets past an #include and tells us what is
# behind it. Nothing here is linkable: every function declared below is
# undefined at link time, and that is deliberate -- a missing symbol at the link
# line is a loud failure, whereas a stub that returns 0 is a silent wrong
# answer. A file that compiles because of this script is "first blocker
# identified", NOT "ported".
#
# The exceptions are marked RECONSTRUCTION. Those are real definitions of things
# Apple genuinely omitted from the open-source tree, reasoned from evidence and
# recorded as reconstructions rather than quietly defined. They are correct as
# far as we can tell and are still worth re-checking against real Darwin
# behaviour before shipping.
set -euo pipefail
X=${1:-$HOME/work/cfextra}
mkdir -p "$X"/{sys,net,mach,mach-o,arpa,libkern}

# ---------------------------------------------------------------- declarations
# Round 1: the first #include failure in each of 11 files.

cat > "$X/sys/uio.h" <<'EOF'
#ifndef _CFSHIM_SYS_UIO_H
#define _CFSHIM_SYS_UIO_H
#include <sys/types.h>
struct iovec { void *iov_base; size_t iov_len; };
ssize_t writev(int, const struct iovec *, int);
ssize_t readv(int, const struct iovec *, int);
#endif
EOF

# CFPlatform.c:2291, in CF's generic POSIX branch. glibc has all of this.
cat > "$X/spawn.h" <<'EOF'
#ifndef _CFSHIM_SPAWN_H
#define _CFSHIM_SPAWN_H
#include <sys/types.h>
typedef void *posix_spawnattr_t;
typedef void *posix_spawn_file_actions_t;
int posix_spawn(pid_t *, const char *, const posix_spawn_file_actions_t *,
                const posix_spawnattr_t *, char *const [], char *const []);
int posix_spawn_file_actions_init(posix_spawn_file_actions_t *);
int posix_spawn_file_actions_destroy(posix_spawn_file_actions_t *);
int posix_spawn_file_actions_addclose(posix_spawn_file_actions_t *, int);
int posix_spawn_file_actions_adddup2(posix_spawn_file_actions_t *, int, int);
int posix_spawn_file_actions_addchdir(posix_spawn_file_actions_t *, const char *);
int posix_spawn_file_actions_addchdir_np(posix_spawn_file_actions_t *, const char *);
#endif
EOF

# uuid.c includes it and reaches no if_* API at all (measured). Vestigial.
cat > "$X/net/if.h" <<'EOF'
#ifndef _CFSHIM_NET_IF_H
#define _CFSHIM_NET_IF_H
#define IF_NAMESIZE 16
#endif
EOF

cat > "$X/sys/sysctl.h" <<'EOF'
#ifndef _CFSHIM_SYS_SYSCTL_H
#define _CFSHIM_SYS_SYSCTL_H
#include <sys/types.h>
#define CTL_KERN   1
#define CTL_VM     2
#define CTL_HW     6
#define KERN_PROC  14
#define KERN_MAXFILESPERPROC 29
#define HW_NCPU    3
#define HW_AVAILCPU 25
#define HW_MEMSIZE 24
int sysctl(int *, unsigned int, void *, size_t *, void *, size_t);
int sysctlbyname(const char *, void *, size_t *, void *, size_t);
#endif
EOF

# The NX byte-order enum already exists in our mach-o/fat.h -- redeclaring it
# is a redefinition error, which is how this shim failed the first time.
cat > "$X/mach-o/arch.h" <<'EOF'
#ifndef _CFSHIM_MACHO_ARCH_H
#define _CFSHIM_MACHO_ARCH_H
#include <mach/machine.h>
#include <mach-o/fat.h>
typedef struct { const char *name; cpu_type_t cputype; cpu_subtype_t cpusubtype;
                 int byteorder; const char *description; } NXArchInfo;
const NXArchInfo *NXGetLocalArchInfo(void);
struct fat_arch *NXFindBestFatArch(cpu_type_t, cpu_subtype_t, struct fat_arch *, unsigned long);
#endif
EOF

cat > "$X/mach/clock.h" <<'EOF'
#ifndef _CFSHIM_MACH_CLOCK_H
#define _CFSHIM_MACH_CLOCK_H
#include <mach/mach_types.h>
#include <mach/clock_types.h>
typedef mach_port_t clock_serv_t;
kern_return_t clock_get_time(clock_serv_t, mach_timespec_t *);
#endif
EOF

# CFXMLPreferencesDomain includes it and reaches no mach_*/host_* API. Vestigial.
cat > "$X/mach/mach_syscalls.h" <<'EOF'
#ifndef _CFSHIM_MACH_SYSCALLS_H
#define _CFSHIM_MACH_SYSCALLS_H
#endif
EOF

cat > "$X/mach/mach_vm.h" <<'EOF'
#ifndef _CFSHIM_MACH_VM_H
#define _CFSHIM_MACH_VM_H
#include <mach/mach.h>
#endif
EOF

cat > "$X/sysdir.h" <<'EOF'
#ifndef _CFSHIM_SYSDIR_H
#define _CFSHIM_SYSDIR_H
#include <stdint.h>
typedef unsigned int sysdir_search_path_enumeration_state;
typedef enum { SYSDIR_DIRECTORY_APPLICATION = 1 } sysdir_search_path_directory_t;
typedef enum { SYSDIR_DOMAIN_MASK_USER = 1 } sysdir_search_path_domain_mask_t;
sysdir_search_path_enumeration_state
sysdir_start_search_path_enumeration(sysdir_search_path_directory_t,
                                     sysdir_search_path_domain_mask_t);
sysdir_search_path_enumeration_state
sysdir_get_next_search_path_enumeration(sysdir_search_path_enumeration_state, char *);
#endif
EOF

# Round 2/3: the chain revealed once the round-1 includes stopped failing.

cat > "$X/sys/un.h" <<'EOF'
#ifndef _CFSHIM_SYS_UN_H
#define _CFSHIM_SYS_UN_H
#include <sys/socket.h>
struct sockaddr_un { unsigned char sun_len; sa_family_t sun_family; char sun_path[104]; };
#endif
EOF

cat > "$X/net/if_dl.h" <<'EOF'
#ifndef _CFSHIM_NET_IF_DL_H
#define _CFSHIM_NET_IF_DL_H
#include <sys/socket.h>
struct sockaddr_dl { unsigned char sdl_len, sdl_family, sdl_index, sdl_type,
                     sdl_nlen, sdl_alen, sdl_slen; char sdl_data[12]; };
#define LLADDR(s) ((char *)((s)->sdl_data + (s)->sdl_nlen))
#endif
EOF

cat > "$X/net/if_types.h" <<'EOF'
#ifndef _CFSHIM_NET_IF_TYPES_H
#define _CFSHIM_NET_IF_TYPES_H
#define IFT_ETHER 0x6
#endif
EOF

cat > "$X/arpa/inet.h" <<'EOF'
#ifndef _CFSHIM_ARPA_INET_H
#define _CFSHIM_ARPA_INET_H
#include <sys/socket.h>
#include <stdint.h>
uint32_t htonl(uint32_t); uint16_t htons(uint16_t);
uint32_t ntohl(uint32_t); uint16_t ntohs(uint16_t);
const char *inet_ntop(int, const void *, char *, socklen_t);
int inet_pton(int, const char *, void *);
#endif
EOF

cat > "$X/libproc.h" <<'EOF'
#ifndef _CFSHIM_LIBPROC_H
#define _CFSHIM_LIBPROC_H
#include <sys/types.h>
#include <stdint.h>
#define PROC_PIDPATHINFO_MAXSIZE 4096
int proc_pidpath(int, void *, uint32_t);
int proc_name(int, void *, uint32_t);
#endif
EOF

cat > "$X/vproc.h" <<'EOF'
#ifndef _CFSHIM_VPROC_H
#define _CFSHIM_VPROC_H
typedef void *vproc_t;
typedef void *vproc_err_t;
#endif
EOF

# --------------------------------------------------------------- RECONSTRUCTION
# CFBase.h:69 takes this branch when DEPLOYMENT_RUNTIME_SWIFT is off and wants
# Apple's libkern header. These are the documented Darwin fixed-width aliases.
cat > "$X/libkern/OSTypes.h" <<'EOF'
#ifndef _CFSHIM_LIBKERN_OSTYPES_H
#define _CFSHIM_LIBKERN_OSTYPES_H
#include <stdint.h>
typedef unsigned char      UInt8;   typedef signed char       SInt8;
typedef unsigned short     UInt16;  typedef signed short      SInt16;
typedef unsigned int       UInt32;  typedef signed int        SInt32;
typedef unsigned long long UInt64;  typedef signed long long  SInt64;
typedef unsigned char      Boolean;
#endif
EOF

# Force-included by scripts/cf_census.sh. Everything here is a RECONSTRUCTION.
cat > "$X/CFShimCarbon.h" <<'EOF'
#ifndef _CFSHIM_CARBON_H
#define _CFSHIM_CARBON_H

/* RECONSTRUCTION 1 -- AbsoluteTime.
 * A CarbonCore type CFRunLoop still names on Darwin. Documented layout. */
typedef struct { unsigned int hi, lo; } UnsignedWide;
typedef UnsignedWide AbsoluteTime;

/* RECONSTRUCTION 2 -- the _CFThread* types.
 * Defined ONLY in include/ForSwiftFoundationOnly.h:401-414, which is included
 * only when DEPLOYMENT_RUNTIME_SWIFT is on -- yet CF names these types in its
 * own internals regardless. A corelibs layering bug that is invisible in the
 * only mode Apple builds. Taken verbatim from that file's _POSIX_THREADS arm. */
#include <pthread.h>
typedef pthread_t      _CFThreadRef;
typedef pthread_attr_t _CFThreadAttributes;
typedef pthread_key_t  _CFThreadSpecificKey;

/* RECONSTRUCTION 3 -- __kCFAllocatorTypeID_CONST.
 * USED at CFRuntime.c:1720 and DEFINED NOWHERE in the open-source tree. It sits
 * in the #else of `#if DEPLOYMENT_RUNTIME_SWIFT` (CFRuntime.c:1542-1737), the
 * branch holding the real CF deallocation path -- which Apple never compiles
 * here because CFRelease in Swift mode just forwards to swift_release. So the
 * non-Swift path is not merely unbuilt, it is incomplete by omission.
 * Value is the CF allocator type ID, _kCFRuntimeIDCFAllocator == 2 in
 * internalInclude/CFRuntime_Internal.h:20. Re-verify against real CF if the
 * deallocation path ever misbehaves. */
#define __kCFAllocatorTypeID_CONST 2

#endif
EOF

echo "shims written to $X:"
find "$X" -type f -name '*.h' | sed "s|$X/|  |" | sort
