#!/bin/bash
# Verify the artifact is what we claim: Darwin Mach-O, arm64 (not arm64e, not
# ELF), exporting the Swift runtime surface, and record exactly which imports
# the self-hosted SDK does not currently satisfy.
set -uo pipefail
W=${W:-$HOME/work}
LIB=${LIB:-$W/build/lib/swift/macosx/arm64/libswiftCore.dylib}
NM=${NM:-/usr/lib/llvm-18/bin/llvm-nm}
OTOOL=${OTOOL:-/usr/lib/llvm-18/bin/llvm-otool}
RE=${RE:-/usr/lib/llvm-18/bin/llvm-readobj}

echo "=== 1. file type ==="
file "$LIB"

echo
echo "=== 2. Mach-O header (arch, filetype, platform) ==="
"$OTOOL" -h "$LIB" 2>/dev/null | tail -3
"$RE" --macho-version-min "$LIB" 2>/dev/null | head -8

echo
echo "=== 3. install name + dependencies ==="
"$OTOOL" -L "$LIB" 2>/dev/null | head -12

echo
echo "=== 4. exported swift runtime entry points (spot checks) ==="
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
echo "=== 5. counts by family ==="
for p in _swift_ '_$s' _OBJC_CLASS; do
  printf '  %-12s %s\n' "$p" "$(echo "$EXPORTS" | grep -cF "$p")"
done

echo
echo "=== 6. undefined imports NOT exported by our SDK's .tbd files ==="
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
