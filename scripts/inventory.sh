#!/usr/bin/env bash
#
# The deliverable report: compile every translation unit one at a time, print
# an honest PASS/FAIL inventory with the first error for each failure, then
# link libobjc.so and try to load it.
#
# Compiling one file at a time (rather than letting ninja stop at the first
# error) is the point: it makes the remaining work countable.
#
# Runs INSIDE the container. Invoke via: scripts/build_linux.sh inventory
set -uo pipefail

WORK=${WORK:-/work}
. "$WORK/scripts/flags.sh"

OUT=$WORK/build/inventory
rm -rf "$OUT"
mkdir -p "$OUT/obj" "$OUT/log"

bash "$WORK/scripts/gen-include-tree.sh"
mkdir -p "$GEN/asm"
python3 "$WORK/scripts/gen-elf-asm.py" "$SRC/runtime/arm64-asm.h" \
        "$GEN/asm/arm64-asm-elf.h"
python3 "$WORK/scripts/gen-elf-asm.py" "$SRC/runtime/Messengers.subproj/objc-msg-arm64.s" \
        "$GEN/asm/objc-msg-arm64-elf.s"
python3 "$WORK/scripts/gen-elf-asm.py" "$SRC/runtime/retain-release-helpers-arm64.s" \
        "$GEN/asm/retain-release-helpers-arm64-elf.s"

pass=0; fail=0
declare -a failed
declare -a objs

compile_one() {
    local f="$1" kind="$2"
    local base; base=$(basename "$f")
    local log="$OUT/log/$base.log"
    local flags cc=clang++
    case "$kind" in
        objcxx) flags="$OBJC4_OBJCXXFLAGS" ;;
        objc)   flags="$OBJC4_OBJCFLAGS";  cc=clang ;;
        cxx)    flags="$OBJC4_CXXFLAGS" ;;
        asm)    flags="$OBJC4_ASFLAGS -I$GEN/asm"; cc=clang ;;
    esac
    if $cc $flags -c "$f" -o "$OUT/obj/$base.o" > "$log" 2>&1; then
        printf '  PASS  %s\n' "$base"
        pass=$((pass+1)); objs+=("$OUT/obj/$base.o")
    else
        printf '  FAIL  %s\n' "$base"
        fail=$((fail+1)); failed+=("$base")
    fi
}

echo "=== runtime/*.mm  (Objective-C++, Apple runtime ABI) ==="
for f in "$SRC"/runtime/*.mm; do
    # dummy-library-mac-i386.c is a 10.x i386 dylib stub; nothing reaches it.
    case "$f" in *dummy-library-mac-i386*) continue ;; esac
    compile_one "$f" objcxx
done

echo "=== runtime/*.m ==="
for f in "$SRC"/runtime/*.m; do compile_one "$f" objc; done

echo "=== assembly (Mach-O -> ELF via scripts/gen-elf-asm.py) ==="
compile_one "$GEN/asm/objc-msg-arm64-elf.s" asm
compile_one "$GEN/asm/retain-release-helpers-arm64-elf.s" asm

echo "=== compat/ (our implementations of the Darwin surface) ==="
compile_one "$WORK/compat/src/objc4linux-compat.cpp" cxx

echo
echo "=== COMPILE: $pass ok, $fail failed ==="
if [ "$fail" -gt 0 ]; then
    for f in "${failed[@]}"; do
        echo "--- $f"
        grep -m3 -E '(error|fatal error):' "$OUT/log/$f.log" | sed 's/^/      /'
    done
    exit 0
fi

echo
echo "=== LINK ==="
if clang++ -shared -fPIC -o "$OUT/libobjc.so" "${objs[@]}" \
        -lpthread -ldl -lBlocksRuntime > "$OUT/log/link.log" 2>&1; then
    echo "  libobjc.so linked, $(stat -c%s "$OUT/libobjc.so") bytes"
    echo "  exported symbols: $(llvm-nm-18 --defined-only --dynamic "$OUT/libobjc.so" | wc -l)"
    echo "  unresolved (excluding libc / libstdc++ / libBlocksRuntime):"
    llvm-nm-18 -u --dynamic "$OUT/libobjc.so" \
        | grep -vE 'GLIBC|GCC_|CXXABI|GLIBCXX|^ *w |_ITM_|__gmon|_Block_|_NSConcrete' \
        | sed 's/^/    /'
    echo "  (empty above means everything resolved)"

    echo "=== LOAD ==="
    cat > "$OUT/load.c" <<'EOF'
#include <stdio.h>
#include <dlfcn.h>
int main(int argc, char **argv) {
    void *h = dlopen(argv[1], RTLD_NOW);
    if (!h) { printf("  dlopen FAILED: %s\n", dlerror()); return 1; }
    printf("  dlopen OK   objc_msgSend=%p  objc_readClassPair=%p\n",
           dlsym(h, "objc_msgSend"), dlsym(h, "objc_readClassPair"));
    return 0;
}
EOF
    clang "$OUT/load.c" -o "$OUT/load" -ldl && "$OUT/load" "$OUT/libobjc.so"
else
    echo "  LINK FAILED:"
    grep -E 'undefined|error' "$OUT/log/link.log" | head -20 | sed 's/^/    /'
fi
exit 0
