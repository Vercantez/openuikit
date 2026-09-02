#!/bin/bash
# Build swift-foundation-icu as a Darwin Mach-O arm64 static library, on Linux.
#
#   scripts/build_icu.sh [icu-source-dir] [outdir]
#
# Source: apple/swift-foundation-icu 0.0.9 — the tree swift-corelibs-foundation
# FetchContents. Not a substitute, not a hand-roll.
#
# Two facts about this package that are worth knowing before reading the flags,
# because both are the opposite of the usual shorthand:
#
#  * U_DISABLE_RENAMING=1. Symbols are plain `ucal_open`, `udat_format`, ...
#    The `_foundation_unicode/` prefix is an INCLUDE-PATH convention, not a
#    symbol rename. There is no rename step to reproduce.
#
#  * The ICU data is VENDORED, as icuSources/common/icu_packaged_main_data.*.inc.h
#    (~20 MB of C arrays) selected by USE_PACKAGE_DATA=1, with stubdata/
#    excluded. There is no external .dat to fetch and no data-building
#    bootstrap — which is the difference between a hard ICU port and an easy one.
#
# Scale, measured: 469 .cpp files, ~338K lines. 456 of them compile against
# machorun's staged Darwin sysroot with no intervention at all. The handful that
# do not are listed in the shim section below.
set -euo pipefail
ICU=${1:-/priv/icu}
OUT=${2:-/root/work/icu}
SDK=${SDK:-$HOME/work/sdk/MacOSX.sdk}
JOBS=${JOBS:-$(nproc)}
TRIPLE=arm64-apple-macos13.0
I=$ICU/icuSources
SHIM=$OUT/shim

mkdir -p "$OUT/obj" "$OUT/log" "$SHIM/os"

# ---------------------------------------------------------------------- shims
# Three headers machorun's sysroot does not carry that ICU reaches. All three
# are declaration-only; ICU uses a small, specific part of each.

# aaplbfct.cpp — Apple's break-factory. Uses glob() to find dictionary files.
cat > "$SHIM/glob.h" <<'EOF'
#ifndef _ICUSHIM_GLOB_H
#define _ICUSHIM_GLOB_H
#include <stddef.h>
typedef struct { size_t gl_pathc; char **gl_pathv; size_t gl_offs; } glob_t;
#define GLOB_NOSORT 0x20
int  glob(const char *, int, int (*)(const char *, int), glob_t *);
void globfree(glob_t *);
#endif
EOF

# putil.cpp — nl_langinfo(CODESET) to guess the default charset.
cat > "$SHIM/langinfo.h" <<'EOF'
#ifndef _ICUSHIM_LANGINFO_H
#define _ICUSHIM_LANGINFO_H
typedef int nl_item;
#define CODESET 14
char *nl_langinfo(nl_item);
#endif
EOF

# coll/rematch/smpdtfmt/uniset/usearch — Apple's os_log diagnostics. The macros
# must expand to nothing rather than to calls: this is diagnostic-only code and
# we do not want a link dependency on os_log for it.
cat > "$SHIM/os/log.h" <<'EOF'
#ifndef _ICUSHIM_OS_LOG_H
#define _ICUSHIM_OS_LOG_H
typedef void *os_log_t;
#define OS_LOG_DEFAULT ((os_log_t)0)
#define os_log(...)          do { } while (0)
#define os_log_error(...)    do { } while (0)
#define os_log_info(...)     do { } while (0)
#define os_log_debug(...)    do { } while (0)
#define os_log_fault(...)    do { } while (0)
#define os_log_create(a,b)   ((os_log_t)0)
#define os_log_type_enabled(a,b) (0)
#endif
EOF

# putil.cpp — the platform layer. Reads TZDIR to locate the zoneinfo database.
cat > "$SHIM/tzfile.h" <<'EOF'
#ifndef _ICUSHIM_TZFILE_H
#define _ICUSHIM_TZFILE_H
#ifndef TZDIR
#define TZDIR "/usr/share/zoneinfo"
#endif
#ifndef TZDEFAULT
#define TZDEFAULT "/etc/localtime"
#endif
#endif
EOF

# aaplbfct.cpp — Apple's break-dictionary lookup walks the Library directories.
cat > "$SHIM/NSSystemDirectories.h" <<'EOF'
#ifndef _ICUSHIM_NSSYSTEMDIRECTORIES_H
#define _ICUSHIM_NSSYSTEMDIRECTORIES_H
#include <stdint.h>
typedef enum { NSLibraryDirectory = 5 } NSSearchPathDirectory;
typedef enum {
  NSUserDomainMask = 1, NSLocalDomainMask = 2, NSNetworkDomainMask = 4
} NSSearchPathDomainMask;
typedef unsigned int NSSearchPathEnumerationState;
NSSearchPathEnumerationState NSStartSearchPathEnumeration(NSSearchPathDirectory,
                                                          NSSearchPathDomainMask);
NSSearchPathEnumerationState NSGetNextSearchPathEnumeration(NSSearchPathEnumerationState,
                                                            char *);
#endif
EOF

# lstmbe.cpp — the LSTM break engine, which needs expf().
#
# machorun's sysroot math.h declares NO single-precision variants AT ALL: expf,
# sinf, cosf, powf, sqrtf, ... are all absent (measured). libc++'s <cmath> pulls
# them in with `using ::atan2f _LIBCPP_USING_IF_EXISTS`, so their absence is
# SILENT until something references one, and then the error surfaces inside
# libc++'s <complex> rather than at the use site -- which is why this reads as
# "reference to unresolved using declaration" and not "expf is missing".
#
# Force-included so it lands before <cmath> does its using-declarations. ICU
# reaches only expf, but the whole set is declared because the gap is the whole
# set. The real fix belongs in machorun's math.h.
cat > "$SHIM/icu_floatmath.h" <<'EOF'
#ifndef _ICUSHIM_FLOATMATH_H
#define _ICUSHIM_FLOATMATH_H
#ifdef __cplusplus
extern "C" {
#endif
float expf(float);   float logf(float);    float log2f(float);  float log10f(float);
float powf(float, float);                   float sqrtf(float);  float cbrtf(float);
float sinf(float);   float cosf(float);    float tanf(float);
float asinf(float);  float acosf(float);   float atanf(float);  float atan2f(float, float);
float sinhf(float);  float coshf(float);   float tanhf(float);
float fabsf(float);  float floorf(float);  float ceilf(float);  float roundf(float);
float truncf(float); float fmodf(float, float);                  float hypotf(float, float);
float nearbyintf(float); float rintf(float); float exp2f(float);
#ifdef __cplusplus
}
#endif
#endif
EOF

# putil.cpp again — walks the zoneinfo tree to identify the local timezone.
#
# machorun's sysroot carries no dirent.h at all. This is the SAME gap that
# blocks CFTimeZone and CFLocale in the CoreFoundation census, so the real fix
# is one header in machorun's sysroot, not three shims in three projects. Scoped
# here so the ICU build stands alone until that lands.
#
# Layout matches Darwin's 64-bit-inode struct dirent. d_fileno is Darwin's
# legacy alias for d_ino and is declared because CF reaches it even though ICU
# does not.
cat > "$SHIM/dirent.h" <<'EOF'
#ifndef _ICUSHIM_DIRENT_H
#define _ICUSHIM_DIRENT_H
#include <stdint.h>
#include <sys/types.h>
#define __DARWIN_MAXPATHLEN 1024
struct dirent {
    uint64_t d_ino;
    uint64_t d_seekoff;
    uint16_t d_reclen;
    uint16_t d_namlen;
    uint8_t  d_type;
    char     d_name[__DARWIN_MAXPATHLEN];
};
#define d_fileno d_ino
#define DT_UNKNOWN 0
#define DT_DIR     4
#define DT_REG     8
#define DT_LNK    10
/* extern "C" is LOAD-BEARING here. ICU is C++, so without it these get C++
 * mangling and the link fails with undefined `__Z7opendirPKc` -- which reads
 * like a missing function rather than a missing linkage specifier. Measured:
 * that is exactly how it presented. The real Darwin dirent.h is C-only and
 * never has to think about this; a hand-written shim does. */
#ifdef __cplusplus
extern "C" {
#endif
typedef struct __dirstream DIR;
DIR           *opendir(const char *);
struct dirent *readdir(DIR *);
int            readdir_r(DIR *, struct dirent *, struct dirent **);
int            closedir(DIR *);
void           rewinddir(DIR *);
#ifdef __cplusplus
}
#endif
#endif
EOF

# ---------------------------------------------------------------------- flags
# U_TIMEZONE_PACKAGE must reach the compiler as a STRING literal. Passing it
# through a nested shell drops the quotes and udata.cpp then fails with
# "use of undeclared identifier 'icutz44l'" — which reads like a missing symbol
# rather than a quoting bug, so it is spelled out here in an array.
CXXFLAGS=(
  # NOT -fno-rtti / -fno-exceptions. ICU uses dynamic_cast and typeid
  # throughout its calendar, collation and timezone code (measured: 22 files
  # fail without RTTI), and upstream's CMakeLists sets neither. Adding them
  # looks like a harmless size optimisation and is not.
  -target "$TRIPLE" -isysroot "$SDK" -std=c++14 -Os
  -I"$I/common" -I"$I/i18n" -I"$I/include" -idirafter "$SHIM"
  -include "$SHIM/icu_floatmath.h"
  -DU_ATTRIBUTE_DEPRECATED=
  -DU_SHOW_CPLUSPLUS_API=1 -DU_SHOW_INTERNAL_API=1
  -DU_TIMEZONE_PACKAGE=\"icutz44l\"
  -DSTD_INSPIRED -DMAC_OS_X_VERSION_MIN_REQUIRED=101500
  -DU_HAVE_STRTOD_L=1 -DU_HAVE_XLOCALE_H=1 -DU_HAVE_STRING_VIEW=1
  -DU_DISABLE_RENAMING=1
  -DU_COMBINED_IMPLEMENTATION -DU_COMMON_IMPLEMENTATION
  -DU_I18N_IMPLEMENTATION -DU_IO_IMPLEMENTATION
  -DICU_DATA_DIR=\"/usr/share/icu\" -DUSE_PACKAGE_DATA=1 -DAPPLE_ICU_CHANGES=1
  -Wno-deprecated-declarations -Wno-vla-cxx-extension -Wno-unused-function
)

find "$I/common" "$I/i18n" "$I/io" -name '*.cpp' | sort > "$OUT/sources.txt"
echo "sources: $(wc -l < "$OUT/sources.txt")   jobs: $JOBS"

printf '%s\n' "${CXXFLAGS[@]}" > "$OUT/cxxflags.txt"

compile_one() {
  src=$1; OUT=$2
  b=$(basename "$src" .cpp)
  mapfile -t F < "$OUT/cxxflags.txt"
  clang++ "${F[@]}" -c "$src" -o "$OUT/obj/$b.o" 2>"$OUT/log/$b.err"
}
export -f compile_one

echo "==> compiling"
xargs -a "$OUT/sources.txt" -P "$JOBS" -I{} bash -c 'compile_one "$@"' _ {} "$OUT" || true

ok=$(ls "$OUT/obj"/*.o 2>/dev/null | wc -l)
tot=$(wc -l < "$OUT/sources.txt")
echo "compiled: $ok / $tot"

if [ "$ok" -ne "$tot" ]; then
  echo "=== failures ==="
  while read -r src; do
    b=$(basename "$src" .cpp)
    [ -f "$OUT/obj/$b.o" ] || printf '  %-22s %s\n' "$b" \
      "$(grep -m1 -E 'error:' "$OUT/log/$b.err" | sed 's/.*error: //' | cut -c1-60)"
  done < "$OUT/sources.txt"
fi

echo "==> archiving libicucore.a"
llvm-ar-18 rcs "$OUT/libicucore.a" "$OUT/obj"/*.o
ls -la "$OUT/libicucore.a"
echo "exported ICU entry points: $(llvm-nm-18 --defined-only --extern-only "$OUT/libicucore.a" 2>/dev/null | grep -cE ' _(u|ucal|udat|unum|uloc|ucol|ucnv|uregex|utrans)_')"
