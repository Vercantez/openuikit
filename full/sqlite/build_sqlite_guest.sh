#!/usr/bin/env bash
# The guest's /usr/lib/libsqlite3.dylib: SQLite's public-domain amalgamation,
# pinned to the version the iOS 26.1 SDK declares (sqlite3.h SQLITE_VERSION
# "3.51.0") and built as a Darwin Mach-O dylib with the compile options the iOS
# 26.1 simulator's libsqlite3 reports (apple_compile_options.tsv, measured by
# uikit/Tools/oracle2/guestsqliteoptions). Apps link it the way they link
# Apple's (-lsqlite3, install name /usr/lib/libsqlite3.dylib) and include
# <sqlite3.h> or `import SQLite3`.
#
# Why a Mach-O build and not full/coredata's dlopen("libsqlite3.so.0"): that
# pattern belongs to the Linux-native (ELF) CoreData module and loads a host
# library at run time. FMDB and every other C/ObjC client link sqlite3_* at
# build time with two-level binding, which a Mach-O dylib satisfies directly;
# a host ELF would need a bridge per function (like full/dispatch's) and would
# run whatever SQLite the container happens to ship.
#
#   W SYS OUT TARGET ARCH ROOTDIR MINOS LINK_PLATFORM LINK_SDK_VERSION must be set
#   (build_full.sh passes them). Writes:
#     $ROOTDIR/darwin/usr/lib/libsqlite3.dylib
#     $OUT/sqlite/include/{sqlite3.h,sqlite3ext.h,module.modulemap}
set -euo pipefail
: "${W:?}" "${SYS:?}" "${OUT:?}" "${TARGET:?}" "${ARCH:?}" "${ROOTDIR:?}"
: "${MINOS:?}" "${LINK_PLATFORM:?}" "${LINK_SDK_VERSION:?}"
VERSION=3510000
SHA256=1caf7116f2910600d04473ad69d37ec538fa62fa36adccd37b5e0e43647c98be
URL=https://www.sqlite.org/2025/sqlite-amalgamation-$VERSION.zip
S=$OUT/sqlite
mkdir -p "$S"
archive=$S/sqlite-amalgamation-$VERSION.zip
if [ ! -f "$archive" ]; then
    curl -fL --retry 3 "$URL" -o "$archive.part"
    mv "$archive.part" "$archive"
fi
echo "$SHA256  $archive" | sha256sum -c - >/dev/null || {
    echo "build_sqlite_guest: $archive does not match the pinned SHA-256" >&2
    exit 2
}
rm -rf "$S/src"
mkdir -p "$S/src"
python3 - "$archive" "$S/src" <<'PY'
import sys, zipfile
with zipfile.ZipFile(sys.argv[1]) as z:
    for name in ("sqlite3.c", "sqlite3.h", "sqlite3ext.h"):
        data = z.read(f"sqlite-amalgamation-3510000/{name}")
        open(f"{sys.argv[2]}/{name}", "wb").write(data)
PY
grep -Fq '#define SQLITE_VERSION        "3.51.0"' "$S/src/sqlite3.h" || {
    echo "build_sqlite_guest: amalgamation is not SQLite 3.51.0" >&2
    exit 2
}

# Two guest-build defines that sqlite3_compileoption_get() does not report:
#   SQLITE_OS_UNIX=1            the unix VFS (as on iOS)
#   SQLITE_WITHOUT_ZONEMALLOC   mem1.c's __APPLE__ path allocates from a private
#                               malloc zone (malloc_create_zone, sysctlbyname),
#                               which machorun's libSystem does not provide;
#                               this keeps SYSTEM_MALLOC with sqlite's own size
#                               header instead. Allocation strategy only.
# and two renames: fchmod/utimes -> compat/sqlite_guest_compat.c (why there).
mapfile -t OPTION_FLAGS < <(python3 -B "$W/full/sqlite/sqlite_options.py" flags)
[ "${#OPTION_FLAGS[@]}" -gt 40 ] || { echo "build_sqlite_guest: no compile options" >&2; exit 2; }
clang-18 -target "$TARGET" -isysroot "$SYS" -O2 -fPIC -g0 \
    -idirafter "$W/full/sqlite/compat" \
    -DSQLITE_OS_UNIX=1 -DSQLITE_WITHOUT_ZONEMALLOC=1 "${OPTION_FLAGS[@]}" \
    -Dfchmod=openuikit_sqlite_fchmod -Dutimes=openuikit_sqlite_utimes \
    -Wno-unused-command-line-argument \
    -c "$S/src/sqlite3.c" -o "$S/sqlite3.o"
clang-18 -target "$TARGET" -isysroot "$SYS" -O2 -fPIC -g0 -Wall -Werror \
    -c "$W/full/sqlite/compat/sqlite_guest_compat.c" -o "$S/sqlite_guest_compat.o"
ld64.lld-18 -dylib -arch "$ARCH" -platform_version "$LINK_PLATFORM" "$MINOS" "$LINK_SDK_VERSION" \
    -syslibroot "$SYS" -install_name /usr/lib/libsqlite3.dylib \
    -o "$ROOTDIR/darwin/usr/lib/libsqlite3.dylib" "$S/sqlite3.o" "$S/sqlite_guest_compat.o" -lSystem
exports=$(llvm-nm-18 --extern-only --defined-only "$ROOTDIR/darwin/usr/lib/libsqlite3.dylib" | grep -c ' _sqlite3_')
[ "$exports" -gt 200 ] || { echo "build_sqlite_guest: only $exports sqlite3_ exports" >&2; exit 2; }
undefined=$(llvm-nm-18 --undefined-only "$ROOTDIR/darwin/usr/lib/libsqlite3.dylib" | awk '{print $NF}' | sort -u | tr '\n' ' ')

mkdir -p "$S/include"
cp "$S/src/sqlite3.h" "$S/src/sqlite3ext.h" "$S/include/"
# The iOS 26.1 SDK's usr/include/SQLite3.modulemap, same shape, so Swift's
# `import SQLite3` resolves the same way (no link directive there either).
cat > "$S/include/module.modulemap" <<'EOF'
module SQLite3 [system] {
  header "sqlite3.h"
  export *

  explicit module Ext {
    header "sqlite3ext.h"
    export *
  }
}
EOF
echo "   -> libsqlite3.dylib (SQLite 3.51.0, ${#OPTION_FLAGS[@]} compile options, $exports sqlite3_ exports)"
echo "      imports: $undefined"
