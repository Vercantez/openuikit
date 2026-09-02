#!/bin/bash
# check_shim_shadowing.sh -- prove that libswiftcompat.dylib does not shadow
# libc++abi's C++ type_info vtables, by throwing a real exception through them.
#
# WHY THIS EXISTS RATHER THAN JUST THE BUILD-TIME ASSERTION.
#
# scripts/build_compat.sh already refuses to emit a shim whose exports overlap
# machorun's userland. That is a symbol-level check, and symbol-level checks are
# how this defect hid for a week: the Swift gate (machorun scripts/swift_gate.sh)
# passes with the shadowing shim AND without it, in both of its link orders,
# because instantiating Swift classes never dispatches through a type_info
# vtable. Only a C++ throw does.
#
# So this runs machorun's own 30_throw fixture -- the one whose interesting case
# is "catch a Derived as a Base &", which needs libc++abi's hierarchy walk
# through __si_class_type_info's vtable rather than a pointer compare -- and it
# links libswiftcompat FIRST, ahead of libc++abi.
#
# THAT LINK ORDER IS THE WHOLE EXPERIMENT. With the vtables defined in the shim,
# ld64 resolves them to libswiftcompat and emits a TWO-LEVEL bind naming it, so
# the guest does not merely risk the wrong definition by load order -- it is
# wired to the wrong one deterministically. The shim's were
# `const void *[8] = {0,...}`, which clang places in (__DATA,__common):
# ZEROFILL, no contents in the file. Measured result, 2026-08-27:
#
#     shim WITH the vtables:  SIGSEGV, pc 0x0, no output at all
#     shim WITHOUT them:      exit 0, all six cases ok, matches macOS
#
# BOTH SIDES RUN EVERY TIME. A check that only asserts the good case cannot
# tell "the bug is fixed" from "the fixture stopped reaching the code", and this
# fixture reaches it only through a linker decision that is easy to lose.
#
# Usage: scripts/check_shim_shadowing.sh [path/to/libswiftcompat.dylib]
# Default is artifacts/libswiftcompat.dylib.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MACHORUN="${MACHORUN:-$HOME/machorun}"
IMAGE="${MACHORUN_SWIFT_IMAGE:-machorun-swift:6.2.4}"
SHIM="${1:-$REPO/artifacts/libswiftcompat.dylib}"

[ -f "$SHIM" ] || { echo "no shim at $SHIM -- build it with scripts/build_compat_docker.sh" >&2; exit 2; }
for p in "$MACHORUN/tests/src/30_throw.cpp" "$MACHORUN/tests/expected/30_throw.stdout" \
         "$MACHORUN/build/machorun"; do
  [ -e "$p" ] || { echo "missing input: $p" >&2; exit 2; }
done

STAGE=$(mktemp -d); trap 'rm -rf "$STAGE"; docker rm -f "$C" >/dev/null 2>&1 || true' EXIT
cp "$SHIM" "$STAGE/real.dylib"

C=shimshadow-$$
docker rm -f "$C" >/dev/null 2>&1 || true
docker run -d --name "$C" --platform linux/arm64 \
  -v "$MACHORUN":/work:ro -v "$REPO":/src:ro -v "$STAGE":/stage:ro \
  "$IMAGE" sleep infinity >/dev/null

docker exec "$C" bash -euo pipefail -c '
  rm -rf /b/sdk; mkdir -p /b/sdk/usr
  cp -a /work/sdk/usr/include /b/sdk/usr/include
  cp -a /work/sdk/usr/lib     /b/sdk/usr/lib
  mkdir -p /b/sdk/usr/include/c++
  cp -a /work/build/sdk/MacOSX.sdk/usr/include/c++/v1 /b/sdk/usr/include/c++/v1
  cp /stage/real.dylib /b/real.dylib

  # The MUTANT: the real shim plus the four vtables exactly as they were before
  # the 2026-08-27 deletion. Linked directly rather than through
  # build_compat.sh, which now refuses to produce this on purpose.
  cat > /b/mutant.c <<"EOF"
#define V(sym,name) __attribute__((visibility("default"))) const void *sym[8] __asm__(name) = {0,0,0,0,0,0,0,0}
V(v_class,    "__ZTVN10__cxxabiv117__class_type_infoE");
V(v_si,       "__ZTVN10__cxxabiv120__si_class_type_infoE");
V(v_pointer,  "__ZTVN10__cxxabiv119__pointer_type_infoE");
V(v_function, "__ZTVN10__cxxabiv120__function_type_infoE");
EOF
  clang -target arm64-apple-macos13.0 -isysroot /b/sdk -O1 -fPIC -c /b/mutant.c -o /b/mutant.o

  # THE MUTANT GETS ITS OWN INSTALL NAME, and that detail is load-bearing.
  # It was first written as -install_name /usr/lib/libswiftcompat.dylib, which
  # looks right and is wrong: machorun resolves a two-level bind by install
  # name, so the guest loaded whatever was STAGED at that path and the mutant
  # file on disk was never in the process at all. That made the control an
  # assertion about machorun'"'"'s staged tree rather than about this file -- it
  # passed only while the staged shim still carried the vtables, and went inert
  # the moment the fix was staged. Caught by this script'"'"'s own INERT check.
  clang -target arm64-apple-macos13.0 -isysroot /b/sdk -fuse-ld=lld -B /usr/lib/llvm-18/bin \
    -dynamiclib -install_name @rpath/libshadowmutant.dylib -nostdlib -L/b/sdk/usr/lib \
    /b/mutant.o -lSystem -Wl,-undefined,dynamic_lookup -o /b/libshadowmutant.dylib

  # Refuse to grade if the mutant is not actually zerofill: if a future clang
  # emits it into __const with real contents, the negative control is testing
  # nothing and a silent pass would be worse than no check.
  /usr/lib/llvm-18/bin/llvm-nm -m /b/libshadowmutant.dylib \
    | grep -q "__DATA,__common.*__ZTVN10__cxxabiv117__class_type_infoE" \
    || { echo "REFUSING TO GRADE: mutant vtable is not zerofill; the control is inert." >&2; exit 3; }

  clang++ -target arm64-apple-macos13.0 -isysroot /b/sdk -std=c++17 -O1 \
    -c /work/tests/src/30_throw.cpp -o /b/30_throw.o
'

status=0
for variant in real mutant; do
  case $variant in
    real)   dylib=/b/real.dylib;             extra="" ;;
    # -rpath so the mutant is found by its own @rpath install name and is
    # genuinely the image in the process, rather than deferring to whatever
    # /usr/lib/libswiftcompat.dylib happens to be staged.
    mutant) dylib=/b/libshadowmutant.dylib;  extra="-Wl,-rpath,/b" ;;
  esac
  docker exec "$C" bash -euo pipefail -c "
    clang++ -target arm64-apple-macos13.0 -isysroot /b/sdk -fuse-ld=lld -B /usr/lib/llvm-18/bin \
      -nostdlib -L/b/sdk/usr/lib /b/30_throw.o \
      $dylib -lc++ -lc++abi -lSystem $extra -o /b/throw.$variant
  "
  # Which image does the binary name for the vtable? This is what makes the
  # experiment an experiment; if the mutant stopped winning the link, the
  # SIGSEGV below would be absent for a reason that is not a fix.
  from=$(docker exec "$C" /usr/lib/llvm-18/bin/llvm-nm -m "/b/throw.$variant" \
         | awk '/__ZTVN10__cxxabiv120__si_class_type_infoE/ {print $NF}' | tr -d '()' | head -1)
  rc=0
  # 2>/dev/null on the exec suppresses bash's own "Segmentation fault" job
  # message; the guest's stderr is captured to /b/$variant.err either way, and
  # the mutant is EXPECTED to die here.
  out=$(docker exec "$C" bash -c "
        cd /work && LC_ALL=C LANG=C TZ=UTC timeout -k 2 60 /work/build/machorun /b/throw.$variant \
          > /b/$variant.out 2>/b/$variant.err; echo \$?" 2>/dev/null) || true
  rc=$out
  same=no
  docker exec "$C" cmp -s "/b/$variant.out" /work/tests/expected/30_throw.stdout && same=yes

  if [ "$variant" = real ]; then
    if [ "$rc" = 0 ] && [ "$same" = yes ]; then
      printf '  real shim     PASS   exit 0, matches macOS baseline (vtable from %s)\n' "$from"
    else
      printf '  real shim     FAIL   exit %s, matches=%s (vtable from %s)\n' "$rc" "$same" "$from"
      docker exec "$C" head -3 "/b/$variant.err" | sed 's/^/        /'
      status=1
    fi
  else
    if [ "$from" != libshadowmutant ]; then
      printf '  mutant        INERT  vtable bound from %s, not the shim -- control proves nothing\n' "$from"
      status=1
    elif [ "$rc" = 139 ] || [ "$rc" = 134 ]; then
      printf '  mutant        DIED   exit %s as required (vtable from %s) -- the check has teeth\n' "$rc" "$from"
    else
      printf '  mutant        NO-OP  exit %s, matches=%s -- the shadowing shim did NOT fail;\n' "$rc" "$same"
      printf '                       this check can no longer detect the defect it was written for\n'
      status=1
    fi
  fi
done
exit $status
