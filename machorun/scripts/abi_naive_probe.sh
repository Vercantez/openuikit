#!/bin/bash
# Show what BREAKS if our Darwin userland forwards to glibc naively.
#
# Every translation in darwin/src/ costs code, and code that is not load-bearing
# should be deleted. This script disables one translation at a time, rebuilds
# libSystem, runs the fixture that covers it, and prints how the output moves
# away from the macOS baseline. If a variant here ever comes out "identical",
# that translation is dead weight and should go.
#
#   scripts/abi_naive_probe.sh            all five variants
#   scripts/abi_naive_probe.sh errno      just one
#
# Runs the builds inside the test-bed container; safe to run from macOS.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE="${MACHORUN_IMAGE:-machorun-testbed:24.04}"
WANT="${1:-all}"

command -v docker >/dev/null 2>&1 || { echo "abi_naive_probe: needs docker" >&2; exit 64; }

docker run --rm -i --platform linux/arm64 -v "$ROOT:/work" -w /work "$IMAGE" \
    bash -s "$WANT" <<'INNER'
set -u
WANT="$1"
CF="-target arm64-apple-macos11 -nostdinc -std=gnu11 -fno-stack-protector -fno-builtin -fPIC -O1 -w"

# build_variant <name> <python-patch-file> <fixture>
build_variant() {
    local name="$1" patch="$2" fixture="$3" d="/tmp/naive-$1"
    rm -rf "$d"; mkdir -p "$d/src" "$d/obj" "$d/darwin/usr/lib"
    cp /work/darwin/src/*.c /work/darwin/src/*.h "$d/src/"
    python3 "$patch" "$d/src" || { echo "  patch failed"; return 1; }
    for f in libsystem posix mach ctype; do
        clang $CF -c "$d/src/$f.c" -o "$d/obj/$f.o" || { echo "  compile failed: $f"; return 1; }
    done
    ld64.lld -dylib -arch arm64 -platform_version macos 11.0 11.0 \
        -install_name /usr/lib/libSystem.B.dylib -undefined dynamic_lookup \
        -o "$d/darwin/usr/lib/libSystem.B.dylib" "$d/obj"/*.o || return 1
    cp /work/darwin/usr/lib/libc++.1.dylib "$d/darwin/usr/lib/"

    echo "=== $name -- running $fixture"
    ( cd /work/tests/bin && MACHORUN_ROOT="$d" timeout 20 /work/build/machorun "./$fixture" \
        > /tmp/out.$name 2> /tmp/err.$name )
    local rc=$?
    echo "    exit: $rc (macOS: $(cat /work/tests/expected/$fixture.exit))"
    if diff -q "/work/tests/expected/$fixture.stdout" "/tmp/out.$name" >/dev/null 2>&1; then
        echo "    stdout: IDENTICAL to macOS -- this translation is not load-bearing!"
    else
        echo "    stdout diverges from macOS:"
        diff -a "/work/tests/expected/$fixture.stdout" "/tmp/out.$name" | head -12 | sed 's/^/      /'
    fi
    [ -s "/tmp/err.$name" ] && { echo "    stderr:"; head -4 "/tmp/err.$name" | sed 's/^/      /'; }
    echo
}

mk_patch() { cat > "/tmp/patch-$1.py"; }

# 1. The variadic ABI: hand our Darwin va_list straight to glibc's vprintf.
mk_patch varargs <<'PY'
import sys
p = sys.argv[1] + "/libsystem.c"
s = open(p).read()
old = "    n = file_format(__stdoutp ? __stdoutp : glibc_stdout, fmt, ap);\n    va_end(ap);\n    return n;\n}\n\nEXPORT int fprintf"
new = "    n = glibc_vprintf(fmt, ap);\n    va_end(ap);\n    return n;\n}\n\nEXPORT int fprintf"
assert old in s
s = s.replace("extern int glibc_snprintf_d",
              "extern int glibc_vprintf(const char *, va_list) __asm__(\"_glibc_vprintf\");\nextern int glibc_snprintf_d", 1)
open(p, "w").write(s.replace(old, new, 1))
PY

# 2. errno: return glibc's errno location, and drop the in/out brackets.
mk_patch errno <<'PY'
import sys, glob
p = sys.argv[1] + "/posix.c"
s = open(p).read()
s = s.replace("EXPORT int *__error(void) { return mr_errno_slot(); }",
              "EXPORT int *__error(void) { return glibc___errno_location(); }")
open(p, "w").write(s)
h = sys.argv[1] + "/dsys.h"
d = open(h).read()
d = d.replace("#define MR_ERRNO_CALL(expr)  ({ mr_errno_in(); __typeof__(expr) _r = (expr); mr_errno_out(); _r; })",
              "#define MR_ERRNO_CALL(expr)  (expr)")
open(h, "w").write(d)
PY

# 3. open() flags: pass the guest's Darwin flag word through unchanged.
mk_patch flags <<'PY'
import sys
p = sys.argv[1] + "/posix.c"
s = open(p).read()
i = s.index("static int linux_open_flags(int d)")
j = s.index("EXPORT int open(const char *path")
open(p, "w").write(s[:i] + "static int linux_open_flags(int d) { return d; }\n\n" + s[j:])
PY

# 4. struct stat: copy the bytes across instead of translating the layout.
mk_patch stat <<'PY'
import sys
p = sys.argv[1] + "/posix.c"
s = open(p).read()
i = s.index("static void stat_l2d(const struct linux_stat *l, struct darwin_stat *d)")
j = s.index("EXPORT int stat(const char *path")
body = ("static void stat_l2d(const struct linux_stat *l, struct darwin_stat *d)\n"
        "{ glibc_memcpy(d, l, sizeof *l); }\n\n")
open(p, "w").write(s[:i] + body + s[j:])
PY

# 5. The rune table: keep the symbol, empty the data. Nothing here calls a
#    function -- the guest INLINED the lookup into its own instructions -- so
#    this shows who really owns _DefaultRuneLocale.
mk_patch rune <<'RUNEPATCH'
import sys
p = sys.argv[1] + "/ctype.c"
s = open(p).read()
for name in ("MR_RUNETYPE_INIT", "MR_MAPLOWER_INIT", "MR_MAPUPPER_INIT"):
    s = s.replace("{ %s }" % name, "{ 0 }")
open(p, "w").write(s)
RUNEPATCH

run() { case "$WANT" in all|"$1") return 0;; *) return 1;; esac; }

echo
echo "machorun: what a naive Darwin userland does"
echo "--------------------------------------------------------------------"
run varargs && build_variant varargs /tmp/patch-varargs.py printf
run errno   && build_variant errno   /tmp/patch-errno.py   errno
run flags   && build_variant flags   /tmp/patch-flags.py   errno
run stat    && build_variant stat    /tmp/patch-stat.py    errno
run rune    && build_variant rune    /tmp/patch-rune.py    utility
INNER
