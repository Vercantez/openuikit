#!/bin/bash
# dup_install_name_probe.sh -- what does dyld ACTUALLY do when one dylib is
# reachable at two paths? Run on macOS; it builds four variants and prints what
# real dyld does with each.
#
#   tests/src/dup_install_name_probe.sh
#
# WHY THIS EXISTS. Task #90 was filed to make machorun "dedupe loaded images by
# LC_ID_DYLIB the way dyld does", after our CoreFoundation appeared twice in one
# guest process. The premise was never measured against dyld. This probe
# measures it, and the answer is that DYLD DOES NOT DO THAT -- see
# docs/DUP_IMAGES.md for the table and what it means.
#
# Each variant prints two things that cannot both be faked: whether a static
# inside the dylib has ONE address seen from both call paths, and how many
# entries of that name are in the _dyld_* image table. A constructor logs each
# time it runs, so "loaded twice" is visible even before main.
set -euo pipefail
[ "$(uname -s)" = "Darwin" ] || { echo "macOS only -- dyld is the oracle here" >&2; exit 1; }

W=$(mktemp -d); trap 'rm -rf "$W"' EXIT
cd "$W"

cat > lib.c <<'EOF'
#include <stdio.h>
static int token;
int *dup_token(void) { return &token; }
__attribute__((constructor)) static void ctor(void) {
    fprintf(stderr, "    [ctor ran, token@%p]\n", (void *)&token);
}
EOF
cat > mid.c <<'EOF'
extern int *dup_token(void);
int *mid_token(void) { return dup_token(); }
EOF
cat > main_dep.c <<'EOF'
#include <stdio.h>
#include <string.h>
#include <mach-o/dyld.h>
extern int *dup_token(void);
extern int *mid_token(void);
int main(void) {
    int *a = dup_token(), *b = mid_token();
    printf("    one image: %s\n", a == b ? "YES" : "NO");
    int n = 0;
    for (uint32_t i = 0; i < _dyld_image_count(); i++)
        if (strstr(_dyld_get_image_name(i), "libdup.dylib")) n++;
    printf("    images named libdup.dylib = %d\n", n);
    return 0;
}
EOF
cat > main_dlopen.c <<'EOF'
#include <stdio.h>
#include <string.h>
#include <dlfcn.h>
#include <mach-o/dyld.h>
extern int *dup_token(void);
int main(void) {
    int *a = dup_token();
    void *h = dlopen("./other/libdup.dylib", RTLD_NOW);
    if (!h) { printf("    dlopen failed: %s\n", dlerror()); return 1; }
    int *(*f)(void) = (int *(*)(void))dlsym(h, "dup_token");
    int *b = f ? f() : NULL;
    printf("    one image: %s\n", a == b ? "YES" : "NO");
    int n = 0;
    for (uint32_t i = 0; i < _dyld_image_count(); i++)
        if (strstr(_dyld_get_image_name(i), "libdup.dylib")) n++;
    printf("    images named libdup.dylib = %d\n", n);
    return 0;
}
EOF

mk() { # $1 dir  $2 copy|symlink  $3 same|different (dep string)
    local d=$1 kind=$2 dep=$3
    mkdir -p "$d/other"
    clang -dynamiclib -o "$d/libdup.dylib" lib.c -install_name @rpath/libdup.dylib
    if [ "$kind" = copy ]; then cp "$d/libdup.dylib" "$d/other/libdup.dylib"
    else ln -sf ../libdup.dylib "$d/other/libdup.dylib"; fi
    clang -dynamiclib -o "$d/libmid.dylib" mid.c "$d/libdup.dylib" \
        -install_name @rpath/libmid.dylib -Wl,-rpath,@loader_path
    # A dependency records the dylib's INSTALL NAME, so producing a DIFFERENT
    # dep string for the same file needs an explicit rewrite. That difference is
    # the whole variable this probe is built around.
    [ "$dep" = different ] && install_name_tool -change \
        @rpath/libdup.dylib @rpath/other/libdup.dylib "$d/libmid.dylib"
    clang -o "$d/probe" main_dep.c "$d/libdup.dylib" "$d/libmid.dylib" \
        -Wl,-rpath,@executable_path -Wl,-rpath,@executable_path/other
}

echo "== 1. dlopen of a DISTINCT REAL PATH (two files, same install name)"
mkdir -p v1/other
clang -dynamiclib -o v1/libdup.dylib lib.c -install_name @rpath/libdup.dylib
cp v1/libdup.dylib v1/other/libdup.dylib
clang -o v1/probe main_dlopen.c v1/libdup.dylib -Wl,-rpath,@executable_path
( cd v1 && ./probe )

echo "== 2. dependency, SAME dep string, two real files"
mk v2 copy same && ( cd v2 && ./probe )

echo "== 3. dependency, DIFFERENT dep strings, two real files  <- the CF case"
mk v3 copy different && ( cd v3 && ./probe )

echo "== 4. dependency, DIFFERENT dep strings, SYMLINK to one file"
mk v4 symlink different && ( cd v4 && ./probe )
