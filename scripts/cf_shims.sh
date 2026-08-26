#!/bin/bash
# Write DECLARATION-ONLY shims for the Darwin headers CF reaches that machorun's
# sysroot does not carry, then re-run the census.
#
# These are a MEASUREMENT INSTRUMENT, not an implementation. The point is to get
# past the first #include failure so the compiler reveals what is behind it.
# Nothing here is linkable; several are deliberately wrong-but-parseable.
set -euo pipefail
X=/home/ubuntu/work/cfextra
mkdir -p $X/sys $X/net $X/mach-o $X/mach

cat > $X/sys/uio.h <<'EOF'
#ifndef _CFSHIM_SYS_UIO_H
#define _CFSHIM_SYS_UIO_H
#include <sys/types.h>
struct iovec { void *iov_base; size_t iov_len; };
ssize_t writev(int, const struct iovec *, int);
ssize_t readv(int, const struct iovec *, int);
#endif
EOF

cat > $X/spawn.h <<'EOF'
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

# uuid.c includes it but reaches no if_* API (measured). Empty is enough.
cat > $X/net/if.h <<'EOF'
#ifndef _CFSHIM_NET_IF_H
#define _CFSHIM_NET_IF_H
#define IF_NAMESIZE 16
#endif
EOF

cat > $X/sys/sysctl.h <<'EOF'
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

cat > $X/mach-o/arch.h <<'EOF'
#ifndef _CFSHIM_MACHO_ARCH_H
#define _CFSHIM_MACHO_ARCH_H
#include <mach/machine.h>
#include <mach-o/fat.h>
typedef struct {
    const char     *name;
    cpu_type_t      cputype;
    cpu_subtype_t   cpusubtype;
    enum { NX_UnknownByteOrder, NX_LittleEndian, NX_BigEndian } byteorder;
    const char     *description;
} NXArchInfo;
const NXArchInfo *NXGetLocalArchInfo(void);
struct fat_arch *NXFindBestFatArch(cpu_type_t, cpu_subtype_t, struct fat_arch *, unsigned long);
#endif
EOF

cat > $X/mach/clock.h <<'EOF'
#ifndef _CFSHIM_MACH_CLOCK_H
#define _CFSHIM_MACH_CLOCK_H
#include <mach/mach_types.h>
#include <mach/clock_types.h>
typedef mach_port_t clock_serv_t;
kern_return_t clock_get_time(clock_serv_t, mach_timespec_t *);
#endif
EOF

cat > $X/mach/mach_syscalls.h <<'EOF'
#ifndef _CFSHIM_MACH_SYSCALLS_H
#define _CFSHIM_MACH_SYSCALLS_H
#endif
EOF

cat > $X/sysdir.h <<'EOF'
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

echo "shims written:"; find $X -type f | sed 's|.*/cfextra/|  |' | sort
