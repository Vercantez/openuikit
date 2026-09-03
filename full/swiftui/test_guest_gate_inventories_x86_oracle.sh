#!/usr/bin/env bash
# ld64.lld proof that x86_64-macos attributes re-exported Darwin overlay
# symbols to libswiftDarwin, not to DarwinFoundation1 or libswift_errno.
#
# Apple ld (MacOSX26.1 SDK, x86_64-apple-macos14.0) on
#   import Darwin; POSIXErrorCode(rawValue: EAGAIN) + errno
# records only:
#   /usr/lib/libSystem.B.dylib
#   /usr/lib/swift/libswiftDarwin.dylib
# and dyld_info -fixups attributes POSIXErrorCode.init / .rawValue and
# Darwin.errno.getter to libswiftDarwin. Apple's Darwin tbd re-exports
# _DarwinFoundation1/2/3 (POSIXErrorCode lives in the DarwinFoundation1 tbd);
# libswift_errno.tbd re-exports DarwinFoundation1 with
# $ld$previous$/usr/lib/swift/libswiftDarwin.dylib$$1$10.14.4$15.0$$.
#
# This script reproduces that record with hand-written tbds (no flattened
# Darwin export list) so guest_gate_inventories.py's x86_64 drop of
# libswift_errno — rather than a DarwinFoundation1 substitution — is tied to
# linker behaviour. gen_swift_tbd.sh flattening is a separate concern: with
# Apple's tbds the same LC_LOAD_DYLIB record is produced through re-export
# attribution, so flattening is invisible to the inventory.
set -euo pipefail

W=${W:-$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)}

command -v ld64.lld-18 >/dev/null 2>&1 \
    || { echo "guest_gate_x86_oracle: ld64.lld-18 is missing" >&2; exit 2; }
command -v clang >/dev/null 2>&1 \
    || { echo "guest_gate_x86_oracle: clang is missing" >&2; exit 2; }
command -v llvm-objdump-18 >/dev/null 2>&1 \
    || { echo "guest_gate_x86_oracle: llvm-objdump-18 is missing" >&2; exit 2; }

WORKDIR=$(mktemp -d "${TMPDIR:-/tmp}/guest-gate-x86-oracle.XXXXXX")
trap 'rm -rf "$WORKDIR"' EXIT
SYS=$WORKDIR/sysroot
mkdir -p "$SYS/usr/lib/swift"

# Darwin re-exports DarwinFoundation1 and does not itself export POSIXErrorCode.
cat > "$SYS/usr/lib/swift/libswiftDarwin.tbd" <<'EOF'
--- !tapi-tbd
tbd-version:     4
targets:         [ x86_64-macos ]
install-name:    '/usr/lib/swift/libswiftDarwin.dylib'
current-version: 1
compatibility-version: 1
reexported-libraries:
  - targets:   [ x86_64-macos ]
    libraries: [ '/usr/lib/swift/libswift_DarwinFoundation1.dylib' ]
...
EOF

cat > "$SYS/usr/lib/swift/libswift_DarwinFoundation1.tbd" <<'EOF'
--- !tapi-tbd
tbd-version:     4
targets:         [ x86_64-macos ]
install-name:    '/usr/lib/swift/libswift_DarwinFoundation1.dylib'
current-version: 1
compatibility-version: 1
exports:
  - targets:   [ x86_64-macos ]
    symbols:   [ '_$s6Darwin14POSIXErrorCodeOMn' ]
...
EOF

# errno re-exports DarwinFoundation1 with only the FORCE_LOAD export, so a
# mistaken -lswift_errno would still LC_LOAD errno without owning POSIXErrorCode.
cat > "$SYS/usr/lib/swift/libswift_errno.tbd" <<'EOF'
--- !tapi-tbd
tbd-version:     4
targets:         [ x86_64-macos ]
install-name:    '/usr/lib/swift/libswift_errno.dylib'
current-version: 1
compatibility-version: 1
reexported-libraries:
  - targets:   [ x86_64-macos ]
    libraries: [ '/usr/lib/swift/libswift_DarwinFoundation1.dylib' ]
exports:
  - targets:   [ x86_64-macos ]
    symbols:   [ '$ld$force_load$' ]
...
EOF

cat > "$SYS/usr/lib/libSystem.tbd" <<'EOF'
--- !tapi-tbd
tbd-version:     4
targets:         [ x86_64-macos ]
install-name:    '/usr/lib/libSystem.B.dylib'
current-version: 1
compatibility-version: 1
exports:
  - targets:   [ x86_64-macos ]
    symbols:   [ 'dyld_stub_binder' ]
...
EOF

cat > "$WORKDIR/probe.s" <<'EOF'
    .text
    .globl _probe
_probe:
    movq _$s6Darwin14POSIXErrorCodeOMn@GOTPCREL(%rip), %rax
    movl (%rax), %eax
    ret
EOF

clang -c -target x86_64-apple-macos14.0 -o "$WORKDIR/probe.o" "$WORKDIR/probe.s"
ld64.lld-18 -arch x86_64 -platform_version macos 14.0 14.0 \
    -syslibroot "$SYS" -L/usr/lib -L/usr/lib/swift \
    -dylib -install_name @rpath/libprobe.dylib \
    -o "$WORKDIR/libprobe.dylib" "$WORKDIR/probe.o" \
    -lswiftDarwin -lSystem

HEADERS=$WORKDIR/private-headers.txt
llvm-objdump-18 --macho --private-headers "$WORKDIR/libprobe.dylib" > "$HEADERS"

grep -Fq 'name /usr/lib/swift/libswiftDarwin.dylib' "$HEADERS" \
    || { echo "guest_gate_x86_oracle: missing LC_LOAD_DYLIB libswiftDarwin" >&2; cat "$HEADERS" >&2; exit 2; }
grep -Fq 'name /usr/lib/libSystem.B.dylib' "$HEADERS" \
    || { echo "guest_gate_x86_oracle: missing LC_LOAD_DYLIB libSystem.B" >&2; cat "$HEADERS" >&2; exit 2; }
if grep -Fq 'libswift_DarwinFoundation1.dylib' "$HEADERS"; then
    echo "guest_gate_x86_oracle: LC_LOAD recorded DarwinFoundation1 (expected Darwin only)" >&2
    cat "$HEADERS" >&2
    exit 2
fi
if grep -Fq 'libswift_errno.dylib' "$HEADERS"; then
    echo "guest_gate_x86_oracle: LC_LOAD recorded libswift_errno (expected Darwin only)" >&2
    cat "$HEADERS" >&2
    exit 2
fi

llvm-objdump-18 --macho --bind "$WORKDIR/libprobe.dylib" \
    | grep -Eq 'libswiftDarwin[[:space:]]+_\$.*POSIXErrorCode' \
    || { echo "guest_gate_x86_oracle: POSIXErrorCode bind not attributed to libswiftDarwin" >&2
         llvm-objdump-18 --macho --bind "$WORKDIR/libprobe.dylib" >&2
         exit 2; }

echo "GUEST_GATE_X86_ORACLE_OK loads=libswiftDarwin,libSystem.B bind=libswiftDarwin"
