#!/usr/bin/env bash
# Unit teeth for scripts/x86/stamp.inc. Fake x86_64 Mach-O via a 32-byte header.
set -euo pipefail
ROOT=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
# shellcheck source=stamp.inc
. "$ROOT/scripts/x86/stamp.inc"

pass=0
fail=0
ok() { echo "PASS: $*"; pass=$((pass + 1)); }
die_test() { echo "FAIL: $*" >&2; fail=$((fail + 1)); }

WORK=$(mktemp -d /tmp/stamp-inc.XXXXXX)
cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT

# mach_header_64: MH_MAGIC_64, CPU_TYPE_X86_64, CPU_SUBTYPE_X86_64_ALL, MH_OBJECT
write_x86_macho() {
    python3 - "$1" <<'PY'
import pathlib, struct, sys
path = pathlib.Path(sys.argv[1])
path.write_bytes(struct.pack("<IiiIIII", 0xFEEDFACF, 0x01000007, 3, 1, 0, 0, 0))
PY
}

write_x86_macho "$WORK/prod.dylib"
printf 'src-a\n' > "$WORK/a.c"
printf 'src-b\n' > "$WORK/b.c"

key=$(stamp_key "$WORK/prod.dylib" "$WORK/a.c" "$WORK/b.c" argv-flag)
[ "${#key}" -eq 64 ] && ok "stamp_key is 64 hex" || die_test "stamp_key len ${#key}"

if stamp_reuse "$WORK/prod.dylib" "$key" 2>"$WORK/err"; then
    die_test "reuse without stamp file"
else
    ok "no-stamp does not reuse"
fi
stamp_rebuild_reason "$WORK/prod.dylib" "$key" 2>"$WORK/reason"
grep -qx 'rebuilt reason=no-stamp' "$WORK/reason" \
    && ok "rebuild reason=no-stamp" \
    || die_test "reason=$(cat "$WORK/reason")"

stamp_write "$WORK/prod.dylib" "$key"
if stamp_reuse "$WORK/prod.dylib" "$key" 2>"$WORK/err"; then
    grep -q 'reused=1 stamp=' "$WORK/err" && ok "matching stamp reuses" \
        || die_test "reuse stderr=$(cat "$WORK/err")"
else
    die_test "matching stamp should reuse"
fi

printf 'src-a-changed\n' > "$WORK/a.c"
key2=$(stamp_key "$WORK/prod.dylib" "$WORK/a.c" "$WORK/b.c" argv-flag)
[ "$key" != "$key2" ] && ok "content change flips key" || die_test "key unchanged after content edit"
if stamp_reuse "$WORK/prod.dylib" "$key2" 2>"$WORK/err"; then
    die_test "stale stamp reused"
else
    ok "stale stamp does not reuse"
fi
stamp_rebuild_reason "$WORK/prod.dylib" "$key2" 2>"$WORK/reason"
grep -q 'rebuilt reason=inputs ' "$WORK/reason" \
    && ok "rebuild reason=inputs old->new" \
    || die_test "reason=$(cat "$WORK/reason")"

# Existence alone is not enough: matching macho, wrong stamp.
write_x86_macho "$WORK/stale.dylib"
printf 'deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef\n' \
    > "$WORK/stale.dylib.inputs-sha256"
if stamp_reuse "$WORK/stale.dylib" "$key2" 2>/dev/null; then
    die_test "existence+macho reused with wrong stamp"
else
    ok "existence+macho without matching stamp does not reuse"
fi

# argv string is part of the key
k_flag=$(stamp_key "$WORK/prod.dylib" "$WORK/a.c" "$WORK/b.c" other-flag)
[ "$key2" != "$k_flag" ] && ok "argv string is in the key" || die_test "argv ignored"

# Wrong-arch Mach-O never reuses, even with a matching stamp file.
python3 - "$WORK/arm.dylib" <<'PY'
import pathlib, struct, sys
# MH_MAGIC_64, CPU_TYPE_ARM64, CPU_SUBTYPE_ARM64_ALL, MH_DYLIB
pathlib.Path(sys.argv[1]).write_bytes(struct.pack("<IiiIIII", 0xFEEDFACF, 0x0100000C, 0, 6, 0, 0, 0))
PY
stamp_write "$WORK/arm.dylib" "$key2"
if stamp_reuse "$WORK/arm.dylib" "$key2" 2>/dev/null; then
    die_test "wrong-arch Mach-O reused"
else
    ok "wrong-arch Mach-O does not reuse"
fi

echo "test_stamp: pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
