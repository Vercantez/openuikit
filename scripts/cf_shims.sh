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

# Round 4: the remaining sysroot gaps, found once the ICU headers were real.
# Same status as everything above -- DECLARATION ONLY. dirent.h in particular is
# reached by CFTimeZone, CFLocale and ICU, so the real fix is one header in
# machorun's sysroot, not three shims in three projects.

mkdir -p "$X/sys"

cat > "$X/dirent.h" <<'EOF'
#ifndef _CFSHIM_DIRENT_H
#define _CFSHIM_DIRENT_H
#include <stdint.h>
#include <sys/types.h>
struct dirent {
    uint64_t d_ino; uint64_t d_seekoff; uint16_t d_reclen;
    uint16_t d_namlen; uint8_t d_type; char d_name[1024];
};
#define d_fileno d_ino
#define DT_UNKNOWN 0
#define DT_DIR 4
#define DT_REG 8
#define DT_LNK 10
#define DT_WHT 14
/* extern "C" because ICU reaches these from C++ and without it they take C++
   mangling; the link then fails on __Z7opendirPKc, which reads like a missing
   function rather than a missing linkage specifier. */
#ifdef __cplusplus
extern "C" {
#endif
typedef struct __dirstream DIR;
DIR *opendir(const char *);
struct dirent *readdir(DIR *);
int readdir_r(DIR *, struct dirent *, struct dirent **);
int closedir(DIR *);
void rewinddir(DIR *);
#ifdef __cplusplus
}
#endif
#endif
EOF

cat > "$X/sys/socket.h" <<'EOF'
#ifndef _CFSHIM_SYS_SOCKET_H
#define _CFSHIM_SYS_SOCKET_H
#include <sys/types.h>
#include <stdint.h>
typedef uint8_t  sa_family_t;
typedef uint32_t socklen_t;
struct sockaddr { uint8_t sa_len; sa_family_t sa_family; char sa_data[14]; };
struct iovec;
#define AF_UNSPEC 0
#define AF_UNIX   1
#define AF_INET   2
#define AF_INET6 30
#define SOCK_STREAM 1
#define SOCK_DGRAM  2
#define SHUT_RDWR   2
int socket(int, int, int);
int connect(int, const struct sockaddr *, socklen_t);
int bind(int, const struct sockaddr *, socklen_t);
int listen(int, int);
int accept(int, struct sockaddr *, socklen_t *);
int getsockname(int, struct sockaddr *, socklen_t *);
int getpeername(int, struct sockaddr *, socklen_t *);
int getsockopt(int, int, int, void *, socklen_t *);
int setsockopt(int, int, int, const void *, socklen_t);
int shutdown(int, int);
ssize_t send(int, const void *, size_t, int);
ssize_t recv(int, void *, size_t, int);
#endif
EOF

cat > "$X/sys/mount.h" <<'EOF'
#ifndef _CFSHIM_SYS_MOUNT_H
#define _CFSHIM_SYS_MOUNT_H
#include <stdint.h>
#define MFSTYPENAMELEN 16
#define MAXPATHLEN 1024
struct statfs {
    uint32_t f_bsize; int32_t f_iosize; uint64_t f_blocks; uint64_t f_bfree;
    uint64_t f_bavail; uint64_t f_files; uint64_t f_ffree; int32_t f_fsid[2];
    uint32_t f_owner; uint32_t f_type; uint32_t f_flags; uint32_t f_fssubtype;
    char f_fstypename[MFSTYPENAMELEN];
    char f_mntonname[MAXPATHLEN];
    char f_mntfromname[MAXPATHLEN];
    uint32_t f_reserved[8];
};
#define MNT_RDONLY 0x00000001
int statfs(const char *, struct statfs *);
int fstatfs(int, struct statfs *);
int getmntinfo(struct statfs **, int);
#endif
EOF

cat > "$X/pwd.h" <<'EOF'
#ifndef _CFSHIM_PWD_H
#define _CFSHIM_PWD_H
#include <sys/types.h>
struct passwd {
    char *pw_name; char *pw_passwd; uid_t pw_uid; gid_t pw_gid;
    __darwin_time_t pw_change; char *pw_class; char *pw_gecos;
    char *pw_dir; char *pw_shell; __darwin_time_t pw_expire;
};
struct passwd *getpwnam(const char *);
struct passwd *getpwuid(uid_t);
int getpwuid_r(uid_t, struct passwd *, char *, size_t, struct passwd **);
int getpwnam_r(const char *, struct passwd *, char *, size_t, struct passwd **);
#endif
EOF

# Apple System Log. Deprecated on Darwin and diagnostic-only here, so the
# macros expand to nothing rather than to calls.
cat > "$X/asl.h" <<'EOF'
#ifndef _CFSHIM_ASL_H
#define _CFSHIM_ASL_H
typedef void *aslclient;
typedef void *aslmsg;
#define ASL_LEVEL_EMERG 0
#define ASL_LEVEL_ERR   3
#define ASL_LEVEL_WARNING 4
#define ASL_LEVEL_NOTICE  5
#define ASL_LEVEL_INFO    6
#define ASL_LEVEL_DEBUG   7
#define asl_log(...)      do { } while (0)
#define asl_vlog(...)     do { } while (0)
#endif
EOF

# <libc.h> is a Darwin umbrella over unistd/stdlib/string.
cat > "$X/libc.h" <<'EOF'
#ifndef _CFSHIM_LIBC_H
#define _CFSHIM_LIBC_H
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#endif
EOF

# machorun's sysroot crt_externs.h is a WRAPPER: it ends in
# `#include_next <crt_externs.h>` and expects a real one further down the search
# path. Landing here on -idirafter is exactly where include_next looks, so this
# completes the chain rather than shadowing it.
cat > "$X/crt_externs.h" <<'EOF'
#ifndef _CFSHIM_CRT_EXTERNS_H
#define _CFSHIM_CRT_EXTERNS_H
#ifdef __cplusplus
extern "C" {
#endif
int    *_NSGetArgc(void);
char ***_NSGetArgv(void);
char ***_NSGetEnviron(void);
char  **_NSGetProgname(void);
#ifdef __cplusplus
}
#endif
#endif
EOF

# CFBundle and CFLocale walk directory trees with fts(3).
cat > "$X/fts.h" <<'EOF'
#ifndef _CFSHIM_FTS_H
#define _CFSHIM_FTS_H
#include <sys/types.h>
typedef struct _ftsent {
    struct _ftsent *fts_link; char *fts_accpath; char *fts_path;
    unsigned short fts_pathlen; unsigned short fts_namelen;
    unsigned short fts_info; char *fts_name;
} FTSENT;
typedef struct { void *opaque; } FTS;
#define FTS_D      1
#define FTS_DP     6
#define FTS_F      8
#define FTS_SL    12
#define FTS_NOSTAT 0x0010
#define FTS_PHYSICAL 0x0010
#define FTS_XDEV   0x0040
FTS   *fts_open(char *const *, int, int (*)(const FTSENT **, const FTSENT **));
FTSENT *fts_read(FTS *);
int     fts_close(FTS *);
#endif
EOF

# CFTimeZone reads the zoneinfo database; same header ICU's putil.cpp wants.
cat > "$X/tzfile.h" <<'EOF'
#ifndef _CFSHIM_TZFILE_H
#define _CFSHIM_TZFILE_H
#ifndef TZDIR
#define TZDIR "/usr/share/zoneinfo"
#endif
#ifndef TZDEFAULT
#define TZDEFAULT "/etc/localtime"
#endif
#endif
EOF

# CFString uses MAX(); Darwin declares it in <sys/param.h>.
cat > "$X/sys/param.h" <<'EOF'
#ifndef _CFSHIM_SYS_PARAM_H
#define _CFSHIM_SYS_PARAM_H
#include <sys/types.h>
#ifndef MAX
#define MAX(a,b) (((a)>(b))?(a):(b))
#endif
#ifndef MIN
#define MIN(a,b) (((a)<(b))?(a):(b))
#endif
#ifndef MAXPATHLEN
#define MAXPATHLEN 1024
#endif
#ifndef NBBY
#define NBBY 8
#endif
#endif
EOF

# The Mach port and VM entry points CFRunLoop and CFUtilities call. Declaring
# them is honest -- they are real Darwin APIs and the implementations are
# libSystem's job, not ours. NOTE these are the nine symbols the RunLoop fork
# is meant to make unnecessary; they are declared here so the census can measure
# CFRunLoop at all, NOT because we intend to implement them.
cat > "$X/mach/mach_port_extra.h" <<'EOF'
#ifndef _CFSHIM_MACH_PORT_EXTRA_H
#define _CFSHIM_MACH_PORT_EXTRA_H
#include <mach/mach.h>
/* mach_port_context_t and mach_port_options_t ALREADY EXIST in the sysroot's
   mach headers. Redeclaring them is a typedef-redefinition error that takes
   the whole census from 74 passing to ZERO -- measured. Declare only the
   functions. */
/* THE NINE ARE GONE, and this is the RunLoop fork paying out exactly as the
   note above predicted. mach_port_construct/destruct/type/insert_member/
   extract_member and mk_timer_create/destroy/arm/cancel were referenced by ONE
   file, CFRunLoop.c, and only from its Mach branch. patch_cf_runloop.py now
   selects the eventfd/epoll branch, which defines its own static mk_timer_*
   over timerfd -- so these declarations stopped being scaffolding and became a
   COLLISION: 20 "static declaration follows non-static declaration" errors,
   our own shim preventing the real implementation from compiling.

   Checked for all ten before removing any, not just the four that erupted:
   nine belong to CFRunLoop.c alone. mach_vm_region is CFUtilities.c's, and
   stays.

   AND ONE OF THE NINE CAME BACK. The first cut removed all nine on the
   strength of "which FILE references it", which is the wrong test: the right
   question is which REACHABLE BRANCH does. Measured properly, by grepping the
   PREPROCESSED output, five are eliminated outright and four survive -- but the
   four surviving mk_timer_* occurrences are the epoll branch's own static
   DEFINITIONS, which is exactly why our declarations collided with them. Only
   mach_port_type survives as a genuine CALL, from a Darwin block that has no
   Linux alternative and which patch_cf_runloop.py therefore leaves alone. So
   eight go and this one stays.

   AND NOW ALL NINE DO GO. mach_port_type's last caller was a version-1 source's
   RECV-right preflight -- a MACH-ONLY DIAGNOSTIC that CFLogs once and changes
   nothing, and on the epoll layer a version-1 source's "port" is an eventfd, so
   the question it asks cannot arise. patch_cf_runloop.py gates it, and
   CFRunLoop.o now has ZERO Mach IPC imports where it had nine. Only
   mach_absolute_time remains, which is Mach TIME and exported by libSystem.

   Verified at the OBJECT level, and the first attempt was wrong in an
   instructive way: a preprocessor check reported mach_port_type "reachable" in
   all 86 files, which is nonsense -- it was matching THIS DECLARATION, which
   CFShimCarbon.h force-includes everywhere. `llvm-nm -u` over the built objects
   reports none. WHEN THE THING YOU GREP FOR IS SOMETHING YOU YOURSELF
   INSERTED, THE PREPROCESSOR CANNOT TELL YOU WHETHER ANYONE CALLS IT. */
kern_return_t mach_vm_region(vm_map_t, mach_vm_address_t *, mach_vm_size_t *,
                             vm_region_flavor_t, vm_region_info_t,
                             mach_msg_type_number_t *, mach_port_t *);
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

/* MAX/MIN. CFString.c uses MAX() at :3380 and :6826 but never includes
 * <sys/param.h>; on Darwin it arrives transitively through a header chain our
 * sysroot does not reproduce. Force-included rather than added to
 * sys/param.h, because the problem is not that the header is missing -- it is
 * that CFString does not include it. */
#ifndef MAX
#define MAX(a,b) (((a)>(b))?(a):(b))
#endif
#ifndef MIN
#define MIN(a,b) (((a)<(b))?(a):(b))
#endif

/* RECONSTRUCTION 4 -- _CFThreadSetName.
 * Declared only in ForSwiftFoundationOnly.h, like the _CFThread* types, but
 * CFStream calls it regardless. Same layering bug, same fix. */
int _CFThreadSetName(pthread_t, const char *);

/* _NSGetMachExecuteHeader is Darwin's accessor for the main executable's
 * Mach-O header; CFBundle_Binary and CFBundle_Grok use it to find the running
 * image. Real Darwin API, declared here because our sysroot omits it. */
struct mach_header;
const struct mach_header *_NSGetMachExecuteHeader(void);

/* The Mach declarations CFRunLoop/CFUtilities need. See sys/mach_port_extra.h
 * for why these are declared but must NOT be implemented by us. */
#include <mach/mach_port_extra.h>

#endif
EOF

echo "shims written to $X:"
find "$X" -type f -name '*.h' | sed "s|$X/|  |" | sort
