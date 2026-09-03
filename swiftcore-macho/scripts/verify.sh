#!/bin/bash
# Verify the artifact is what we claim: Darwin Mach-O of SWIFTCORE_DARWIN_ARCH
# (not the other slice, not ELF), exporting the Swift runtime surface, and
# record exactly which imports the self-hosted SDK does not currently satisfy.
set -uo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck disable=SC1091
. "$SCRIPT_DIR/guest_arch.inc"
W=${W:-$HOME/work}
LIB=${LIB:-$W/build/lib/swift/${SWIFTCORE_STDLIB_DIR}/libswiftCore.dylib}
NM=${NM:-/usr/lib/llvm-18/bin/llvm-nm}
OTOOL=${OTOOL:-/usr/lib/llvm-18/bin/llvm-otool}
RE=${RE:-/usr/lib/llvm-18/bin/llvm-readobj}

echo "=== 1. file type ==="
file "$LIB"

echo
echo "=== 2. Mach-O header (arch, filetype, platform) ==="
"$OTOOL" -hv "$LIB" 2>/dev/null | tail -5
"$RE" --macho-version-min "$LIB" 2>/dev/null | head -8

echo
echo "=== 3. install name + dependencies ==="
"$OTOOL" -D "$LIB" 2>/dev/null
"$OTOOL" -L "$LIB" 2>/dev/null | head -12

echo
echo "=== 4. hostile: the other Darwin slice must not be in this file ==="
hdr=$("$OTOOL" -hv "$LIB" 2>/dev/null)
case "$SWIFTCORE_DARWIN_ARCH" in
  x86_64)
    echo "$hdr" | grep -Eq 'MH_MAGIC_64[[:space:]]+X86_64' \
      && echo "  OK      cputype X86_64" \
      || { echo "  FAIL    expected X86_64"; exit 1; }
    echo "$hdr" | grep -q ARM64 \
      && { echo "  FAIL    ARM64 token present in an x86_64 artifact"; exit 1; } \
      || echo "  OK      no ARM64 slice"
    ;;
  arm64)
    echo "$hdr" | grep -Eq 'MH_MAGIC_64[[:space:]]+ARM64' \
      && echo "  OK      cputype ARM64" \
      || { echo "  FAIL    expected ARM64"; exit 1; }
    echo "$hdr" | grep -q X86_64 \
      && { echo "  FAIL    X86_64 token present in an arm64 artifact"; exit 1; } \
      || echo "  OK      no X86_64 slice"
    ;;
esac

echo
echo "=== 5. exported swift runtime entry points (spot checks) ==="
EXPORTS=$("$NM" --defined-only --extern-only "$LIB" 2>/dev/null | awk '{print $NF}')
echo "$EXPORTS" | wc -l | sed 's/^/total exported symbols: /'
for s in _swift_retain _swift_release _swift_allocObject _swift_deallocObject \
         _swift_getTypeByMangledName _swift_conformsToProtocol \
         _swift_dynamicCast _swift_once _swift_getGenericMetadata \
         _swift_errorRetain _swift_bridgeObjectRetain \
         '_OBJC_CLASS_$__TtCs12_SwiftObject' '_OBJC_METACLASS_$__TtCs12_SwiftObject'; do
  if echo "$EXPORTS" | grep -qxF "$s"; then echo "  OK      $s"; else echo "  MISSING $s"; fi
done

echo
echo "=== 6. counts by family ==="
for p in _swift_ '_$s' _OBJC_CLASS; do
  printf '  %-12s %s\n' "$p" "$(echo "$EXPORTS" | grep -cF "$p")"
done

echo
echo "=== 7. undefined imports NOT exported by our SDK's .tbd files ==="
SDKSYMS=$(mktemp)
grep -ohE "'_[A-Za-z0-9_$.]+'" "$W"/sdk/MacOSX.sdk/usr/lib/*.tbd 2>/dev/null | tr -d "'" | sort -u > "$SDKSYMS"
echo "  symbols our .tbd files export: $(wc -l < "$SDKSYMS")"
UND=$("$NM" --undefined-only "$LIB" 2>/dev/null | awk '{print $NF}' | sort -u)
echo "  undefined imports in libswiftCore: $(echo "$UND" | wc -l)"
MISS=$(comm -23 <(echo "$UND") "$SDKSYMS")
echo "  of those, not in any .tbd: $(echo "$MISS" | grep -c .)"
echo
echo "  --- grouped ---"
echo "$MISS" | grep -c '^__Z\|^___cxa\|^__ZN\|^__ZSt' | sed 's/^/  C++ ABI \/ libc++ mangled: /'
echo "$MISS" | grep -cE '^_OBJC_CLASS_\$_NS|^_NS' | sed 's/^/  Foundation NS classes:     /'
echo "$MISS" | grep -vE '^__Z|^___cxa|^_OBJC_CLASS_\$_NS|^_NS' | grep -c . | sed 's/^/  plain C symbols:           /'
echo
echo "  --- plain C symbols missing (these are the real libSystem gap) ---"
echo "$MISS" | grep -vE '^__Z|^___cxa|^_OBJC_CLASS_\$_NS|^_NS' | head -60
rm -f "$SDKSYMS"
