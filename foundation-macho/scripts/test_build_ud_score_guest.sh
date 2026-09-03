#!/usr/bin/env bash
# Teeth for scripts/build_ud_score_guest.sh:
#   * no-arg / arm64 compile argv is unchanged (W=/work R=/repo, macos15,
#     four -I paths, $R/scripts/link_ud_guest.sh) and two dumps are identical
#   * x86 argv has the committed -l set, -nostdlib, clang-18, one rope
#   * objects + libCFTest sha + link argv → bin/ud_score_guest.inputs; reuse
#     only on match
#
#   bash foundation-macho/scripts/test_build_ud_score_guest.sh
set -euo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
FM=$(cd "$HERE/.." && pwd)
ROOT=$(cd "$FM/.." && pwd)
S=$HERE/build_ud_score_guest.sh
pass=0
fail=0

ok() { echo "PASS: $*"; pass=$((pass + 1)); }
die_test() { echo "FAIL: $*" >&2; fail=$((fail + 1)); }

expect_grep() {
    local needle=$1 hay=$2 label=$3
    if printf '%s\n' "$hay" | grep -q -- "$needle"; then
        ok "$label"
    else
        die_test "$label (missing: $needle)"
    fi
}

expect_not_grep() {
    local needle=$1 hay=$2 label=$3
    if printf '%s\n' "$hay" | grep -q -- "$needle"; then
        die_test "$label (forbidden: $needle)"
    else
        ok "$label"
    fi
}

echo "== bash -n"
if bash -n "$S"; then
    ok "bash -n build_ud_score_guest.sh"
else
    die_test "bash -n build_ud_score_guest.sh"
fi

echo "== arm64 no-arg argv is byte-identical across dumps (W=/work R=/repo)"
dump_arm() {
    env -u W -u R -u SDK -u OUT -u GEN -u MODULE_CACHE -u SWIFTC_EXTRA -u RUNNER -u LINK \
        TRIPLE=arm64-apple-macos13.0 COMPILE_TRIPLE=arm64-apple-macos15.0 \
        bash "$S" --print-argv
}
arm1=$(dump_arm)
arm2=$(dump_arm)
echo "$arm1"
if [ "$arm1" = "$arm2" ]; then
    ok "two no-arg arm64 --print-argv dumps are byte-identical"
else
    die_test "arm64 dumps drifted"
fi
expect_grep 'UD_SCORE_W=/work' "$arm1" "no-arg W defaults to /work"
expect_grep 'UD_SCORE_R=/repo' "$arm1" "no-arg R defaults to /repo"
expect_grep 'UD_SCORE_ARCH=arm64' "$arm1" "TRIPLE=arm64-apple-macos13.0 → ARCH=arm64"
expect_grep 'UD_SCORE_COMPILE_TRIPLE=arm64-apple-macos15.0' "$arm1" \
    "arm64 compiles at macos15"
expect_grep 'UD_SCORE_TRIPLE=arm64-apple-macos13.0' "$arm1" "arm64 links at macos13"
expect_grep 'UD_SCORE_SDK=/work/fe/sysroot' "$arm1" "no-arg SDK is /work/fe/sysroot"
expect_grep 'UD_SCORE_OUT=/work/bin/ud_score_guest' "$arm1" "no-arg OUT is /work/bin/ud_score_guest"
expect_grep 'UD_SCORE_GEN=/work/oracle/GuestGolden.swift' "$arm1" \
    "no-arg GEN is /work/oracle/GuestGolden.swift"
expect_grep 'UD_SCORE_MODULE_CACHE=/work/fe/modcache' "$arm1" \
    "no-arg module cache is /work/fe/modcache"
expect_grep 'bash /repo/scripts/link_ud_guest.sh' "$arm1" \
    "no-arg links via \$R/scripts/link_ud_guest.sh"
expect_grep 'UD_SCORE_CC=clang-18' "$arm1" "prefers clang-18"
expect_grep 'UD_SCORE_NOSTDLIB=-nostdlib' "$arm1" "Linux-hosted Darwin link is -nostdlib"
expect_grep 'UD_SCORE_LINK_LIBS=-lswiftCore -lswiftDarwin -lswift_StringProcessing -lswiftSynchronization -lswift_errno -lobjc -lSystem libCFTest.dylib libswiftcompat.dylib' \
    "$arm1" "committed -l set (tbd-first overlays + libSystem + ours)"
expect_grep '-target arm64-apple-macos15.0' "$arm1" "compile -target is arm64 macos15"
expect_grep '-I /work/fe/module -I /work/fe -I /work/fe/collections -I /work/fe/os' \
    "$arm1" "canonical four -I paths"
expect_grep '-I /repo/include/CFPreferencesMinimal' "$arm1" \
    "CFPreferencesMinimal -I is under /repo"
expect_grep '-module-cache-path /work/fe/modcache' "$arm1" \
    "canonical module-cache-path"
expect_grep '-o /work/fe/score_runner.o' "$arm1" "score runner lands at /work/fe/score_runner.o"
expect_not_grep 'x86_64' "$arm1" "arm64 dump does not carry x86_64"
expect_not_grep '-runtime-compatibility-version' "$arm1" \
    "no-arg compile does not append x86 SWIFTC_EXTRA"

echo "== x86 --print-argv retargets W/R/ARCH without rewriting the -l set"
X86W=$(mktemp -d /tmp/ud-score-print-x86.XXXXXX)
x86=$(
    W="$X86W" R="$FM" SDK="$X86W/fe/sysroot" OUT="$X86W/bin/ud_score_guest" \
        TRIPLE=x86_64-apple-macos13.0 COMPILE_TRIPLE=x86_64-apple-macos15.0 \
        bash "$S" --print-argv
)
echo "$x86"
expect_grep "UD_SCORE_W=$X86W" "$x86" "x86 dump names the passed W"
expect_grep "UD_SCORE_R=$FM" "$x86" "x86 dump names foundation-macho as R"
expect_grep 'UD_SCORE_ARCH=x86_64' "$x86" "x86 ARCH from TRIPLE"
expect_grep '-target x86_64-apple-macos15.0' "$x86" "x86 compiles at macos15"
expect_grep 'UD_SCORE_LINK_LIBS=-lswiftCore -lswiftDarwin -lswift_StringProcessing -lswiftSynchronization -lswift_errno -lobjc -lSystem libCFTest.dylib libswiftcompat.dylib' \
    "$x86" "x86 keeps the committed -l set"
expect_grep 'UD_SCORE_NOSTDLIB=-nostdlib' "$x86" "x86 is still -nostdlib"
expect_grep "bash $FM/scripts/link_ud_guest.sh" "$x86" \
    "x86 still links through link_ud_guest.sh"
rm -rf "$X86W"

echo "== dummy x86 link: expected -l set, one rope, stamp reuse"
W=$(mktemp -d /tmp/ud-score-guest.XXXXXX)
cleanup() { rm -rf "$W"; }
trap cleanup EXIT

mkdir -p "$W/fe/module" "$W/fe/collections" "$W/fe/os" "$W/fe/cshims" \
    "$W/fe/sysroot/usr/lib/swift" "$W/lib" "$W/bin"
SDK=$W/fe/sysroot
TRIPLE=x86_64-apple-macos13.0

cc_obj() {
    local dest=$1 src=$2
    echo "$src" | clang-18 -target "$TRIPLE" -c -o "$dest" -x c -
}

cc_obj "$W/fe/score_runner.o" 'int main(void){return 0;}'
cc_obj "$W/fe/UserDefaultsGuest.o" 'int ud_guest_port=1;'
cc_obj "$W/fe/module/FoundationEssentials.o" 'int fe_essentials=1;'
cc_obj "$W/fe/collections/OrderedCollections.o" 'int fe_ordered=1;'
cc_obj "$W/fe/collections/InternalCollectionsUtilities.o" 'int fe_icu=1;'
cc_obj "$W/fe/collections/_RopeModule.o" 'int rope_dup=1;'
cp -a "$W/fe/collections/_RopeModule.o" "$W/fe/_RopeModule.o"
cc_obj "$W/fe/os/os.o" 'int fe_os=1;'
cc_obj "$W/fe/cshims/platform_shims.o" 'int fe_plat=1;'
cc_obj "$W/fe/cshims/string_shims.o" 'int fe_str=1;'
cc_obj "$W/fe/cshims/uuid.o" 'int fe_uuid=1;'
cc_obj "$W/fe/fm_unimplemented.o" 'int fe_fm=1;'

emit_tbd() {
    local dest=$1 install=$2
    mkdir -p "$(dirname "$dest")"
    cat >"$dest" <<EOF
--- !tapi-tbd
tbd-version:     4
targets:         [ x86_64-macos ]
install-name:    '$install'
current-version: 1
compatibility-version: 1
exports:
  - targets:   [ x86_64-macos ]
    symbols:   [
                  '_dummy_tbd',
               ]
...
EOF
}

emit_tbd "$SDK/usr/lib/libSystem.B.tbd" "/usr/lib/libSystem.B.dylib"
ln -sfn libSystem.B.tbd "$SDK/usr/lib/libSystem.tbd"
emit_tbd "$SDK/usr/lib/libobjc.A.tbd" "/usr/lib/libobjc.A.dylib"
ln -sfn libobjc.A.tbd "$SDK/usr/lib/libobjc.tbd"
for n in libswiftCore libswiftDarwin libswift_StringProcessing \
    libswiftSynchronization libswift_errno; do
    emit_tbd "$SDK/usr/lib/swift/$n.tbd" "/usr/lib/swift/$n.dylib"
done

echo 'int cftest=1;' | clang-18 -target "$TRIPLE" -c -o "$W/cftest.o" -x c -
clang-18 -target "$TRIPLE" -isysroot "$SDK" -fuse-ld=lld -B /usr/lib/llvm-18/bin \
    -nostdlib -dynamiclib -install_name /usr/lib/libCFTest.dylib \
    "$W/cftest.o" -o "$W/lib/libCFTest.dylib"
cp -a "$W/lib/libCFTest.dylib" "$W/lib/libswiftcompat.dylib"

log=$W/build_ud_score_guest.log
set +e
W="$W" R="$FM" SDK="$SDK" OUT="$W/bin/ud_score_guest" \
    TRIPLE=$TRIPLE COMPILE_TRIPLE=x86_64-apple-macos15.0 \
    SKIP_SWIFTC=1 LLD_BIN=/usr/lib/llvm-18/bin \
    bash "$S" >"$log" 2>&1
st=$?
set -e
echo "$log:"
cat "$log"

if [ "$st" -eq 0 ] && [ -f "$W/bin/ud_score_guest" ] \
    && llvm-otool-18 -hv "$W/bin/ud_score_guest" | grep -Eq 'MH_MAGIC_64[[:space:]]+X86_64'
then
    ok "dummy ud_score_guest is MH_MAGIC_64 X86_64"
else
    die_test "dummy score link exit $st (want 0 + X86_64 Mach-O). log=$(tr '\n' ' ' < "$log")"
fi
if grep -q 'UD_SCORE_STATUS=cold-built' "$log"; then
    ok "first dummy build is cold-built"
else
    die_test "first dummy build missing UD_SCORE_STATUS=cold-built"
fi
if [ -f "$W/bin/ud_score_guest.inputs" ]; then
    ok "wrote bin/ud_score_guest.inputs"
else
    die_test "missing bin/ud_score_guest.inputs"
fi

stamp=$(cat "$W/bin/ud_score_guest.inputs")
echo "$stamp"
expect_grep 'recipe=ud_score_guest.1' "$stamp" "stamp names recipe ud_score_guest.1"
expect_grep 'obj:fe/score_runner.o=' "$stamp" "stamp records score_runner.o"
expect_grep 'obj:fe/collections/_RopeModule.o=' "$stamp" \
    "stamp records collections/_RopeModule.o"
expect_not_grep 'obj:fe/_RopeModule.o=' "$stamp" \
    "stamp does not record the flat rope duplicate"
expect_grep 'libCFTest=' "$stamp" "stamp records libCFTest sha"
expect_grep '-lswiftCore' "$stamp" "stamp link argv has -lswiftCore"
expect_grep '-lswiftDarwin' "$stamp" "stamp link argv has -lswiftDarwin"
expect_grep '-lswift_StringProcessing' "$stamp" "stamp link argv has -lswift_StringProcessing"
expect_grep '-lswiftSynchronization' "$stamp" "stamp link argv has -lswiftSynchronization"
expect_grep '-lswift_errno' "$stamp" "stamp link argv has -lswift_errno"
expect_grep '-lobjc' "$stamp" "stamp link argv has -lobjc"
expect_grep '-lSystem' "$stamp" "stamp link argv has -lSystem"
expect_grep '-nostdlib' "$stamp" "stamp link argv has -nostdlib"
expect_grep 'clang-18' "$stamp" "stamp link argv names clang-18"

rope_n=$(printf '%s\n' "$stamp" | grep '^link_argv=' | grep -o '_RopeModule\.o' | wc -l | tr -d ' ')
if [ "$rope_n" -eq 1 ]; then
    ok "stamp link argv names one _RopeModule.o"
else
    die_test "stamp rope count=$rope_n (want 1)"
fi

before=$(stat -c '%Y' "$W/bin/ud_score_guest")
log2=$W/reuse.log
set +e
W="$W" R="$FM" SDK="$SDK" OUT="$W/bin/ud_score_guest" \
    TRIPLE=$TRIPLE COMPILE_TRIPLE=x86_64-apple-macos15.0 \
    SKIP_SWIFTC=1 LLD_BIN=/usr/lib/llvm-18/bin \
    bash "$S" >"$log2" 2>&1
st2=$?
set -e
echo "$log2:"
cat "$log2"
after=$(stat -c '%Y' "$W/bin/ud_score_guest")
if [ "$st2" -eq 0 ] && grep -q 'UD_SCORE_STATUS=satisfied' "$log2" \
    && grep -q 'reuse' "$log2" && [ "$before" = "$after" ]
then
    ok "matching inputs reuse the binary (satisfied, mtime unchanged)"
else
    die_test "reuse got exit $st2 mtime $before→$after log=$(tr '\n' ' ' < "$log2")"
fi

echo 'int cftest=2;' | clang-18 -target "$TRIPLE" -c -o "$W/cftest.o" -x c -
clang-18 -target "$TRIPLE" -isysroot "$SDK" -fuse-ld=lld -B /usr/lib/llvm-18/bin \
    -nostdlib -dynamiclib -install_name /usr/lib/libCFTest.dylib \
    "$W/cftest.o" -o "$W/lib/libCFTest.dylib"
log3=$W/relink.log
set +e
W="$W" R="$FM" SDK="$SDK" OUT="$W/bin/ud_score_guest" \
    TRIPLE=$TRIPLE COMPILE_TRIPLE=x86_64-apple-macos15.0 \
    SKIP_SWIFTC=1 LLD_BIN=/usr/lib/llvm-18/bin \
    bash "$S" >"$log3" 2>&1
st3=$?
set -e
echo "$log3:"
cat "$log3"
if [ "$st3" -eq 0 ] && grep -q 'UD_SCORE_STATUS=cold-built' "$log3" \
    && grep -q '==> linking' "$log3"
then
    ok "libCFTest sha mismatch rebuilds (cold-built)"
else
    die_test "libCFTest mismatch got exit $st3 log=$(tr '\n' ' ' < "$log3")"
fi

echo "test_build_ud_score_guest: pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
