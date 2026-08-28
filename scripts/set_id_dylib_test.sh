#!/bin/bash
# set_id_dylib_test.sh -- grade scripts/set_id_dylib.pl on the two real inputs
# full/scripts/build_full.sh renames, using Apple's own tools as the reader.
#
# WHY NOT SIMPLY `cmp` AGAINST APPLE'S install_name_tool. That was the first
# design and it is WRONG, measured: Apple's install_name_tool does not perform
# the minimal edit. On machorun's ld64.lld-produced libSystem.B it also
# renormalises __LINKEDIT (vmsize 0xf240 -> 0x10000, filesize 62016 -> 61992,
# one linkedit blob 1648 -> 1624) -- and it is NOT IDEMPOTENT: running it a
# SECOND time with the SAME name changes the file again (193064 -> 193072
# bytes). A tool that does not agree with itself cannot be a byte oracle.
#
# It is still the right READER. So the grade is two-sided:
#   BOUND  -- our output differs from the input ONLY in the load-command region
#             we claim to touch: the 4-byte sizeofcmds and the bytes at/after
#             the LC_ID_DYLIB command. Everything from the first section's file
#             offset onward -- all of __TEXT's content and all of __LINKEDIT --
#             is byte-identical. That is the property mrroot_full's freshness
#             guard depends on (libSystem.real must still BE machorun's bytes).
#   READ   -- Apple's otool parses the result and reports the new install name,
#             the same LC_REEXPORT_DYLIB list, the same export set, and an
#             `otool -l` that differs from Apple's own transform of the same
#             input ONLY in the __LINKEDIT renormalisation above.
# A hand-written Mach-O writer checked only by reading back its own output
# agrees with itself by construction; the failure mode is a plausible file some
# other consumer rejects. Apple's parser is that other consumer.
#
# macOS ONLY, by construction (exit 64 off Darwin, as scripts/run_macos.sh does).
set -uo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
MACHORUN=${MACHORUN:-$HOME/machorun}
PATCH="$ROOT/scripts/set_id_dylib.pl"

if [ "$(uname -s)" != Darwin ]; then
    echo "set_id_dylib_test: needs macOS -- Apple's otool/install_name_tool are the oracle" >&2
    exit 64
fi
command -v xcrun >/dev/null || { echo "set_id_dylib_test: no xcrun" >&2; exit 64; }

TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
fail=0; n=0
note() { printf '      %s\n' "$*"; }

# Print, for a Mach-O: "<id_cmd_file_offset> <first_section_fileoff>".
bounds() {
perl - "$1" <<'PL'
use strict; use warnings;
my $d = do { local $/; open my $f, '<:raw', $ARGV[0] or die; <$f> };
my ($ncmds, $soc) = unpack('LL', substr($d, 16, 8));
my ($off, $id, $first) = (32, undef, undef);
for (1 .. $ncmds) {
    my ($cmd, $cs) = unpack('LL', substr($d, $off, 8));
    $id = $off if $cmd == 0x0D;
    if ($cmd == 0x19) {
        my $ns = unpack('L', substr($d, $off + 64, 4)); my $so = $off + 72;
        for (1 .. $ns) { my $o = unpack('L', substr($d, $so + 48, 4));
                         $first = $o if $o && (!defined $first || $o < $first); $so += 80; }
    }
    $off += $cs;
}
print "$id $first\n";
PL
}

grade() {
    local src=$1 newname=$2 label=$3
    n=$((n+1))
    if [ ! -f "$src" ]; then
        echo "  $label: MISSING INPUT $src -- cannot grade" >&2; fail=$((fail+1)); return; fi
    local sub=0
    cp "$src" "$TMP/ours"; cp "$src" "$TMP/apple"
    local ourmsg
    ourmsg=$(perl "$PATCH" "$TMP/ours" "$newname" 2>&1) || {
        echo "  $label: set_id_dylib.pl FAILED: $ourmsg" >&2; fail=$((fail+1)); return; }
    printf '  %s\n' "$label"
    note "$ourmsg"

    read -r idoff firstsec < <(bounds "$src")

    # --- BOUND ---------------------------------------------------------------
    # cmp -l numbers bytes from 1. Every differing byte must be either the
    # 4-byte sizeofcmds at file offset 20 (bytes 21..24) or at/after the
    # LC_ID_DYLIB command. Nothing at or past the first section may move.
    local stray
    stray=$(cmp -l "$src" "$TMP/ours" 2>/dev/null | awk -v id="$idoff" '
        { b = $1 - 1; if (b >= 20 && b <= 23) next; if (b >= id) next; print b }' | head -5)
    local pastsec
    pastsec=$(cmp -l "$src" "$TMP/ours" 2>/dev/null | awk -v s="$firstsec" '{ if ($1-1 >= s) print $1-1 }' | head -5)
    local ndiff
    ndiff=$(cmp -l "$src" "$TMP/ours" 2>/dev/null | wc -l | tr -d ' ')
    if [ -n "$stray" ]; then
        echo "  $label: BOUND VIOLATED -- bytes changed outside the LC_ID_DYLIB region: $stray" >&2; sub=1
    fi
    if [ -n "$pastsec" ]; then
        echo "  $label: BOUND VIOLATED -- content bytes changed at/after first section ($firstsec): $pastsec" >&2; sub=1
    fi
    # `wc -c <file`, not `stat`: GNU coreutils is first on PATH on this Mac, so
    # `stat -f %z` is read as "filesystem format" and fails. Same family as the
    # `date -r` trap in machorun's check_stale.sh -- pick the portable spelling.
    if [ "$(wc -c <"$src")" != "$(wc -c <"$TMP/ours")" ]; then
        echo "  $label: BOUND VIOLATED -- file length changed" >&2; sub=1
    fi
    note "bound ok: $ndiff byte(s) differ, all within sizeofcmds + LC_ID_DYLIB@$idoff; first section $firstsec untouched; length unchanged"

    # --- READ (Apple's parser) ----------------------------------------------
    local got; got=$(otool -D "$TMP/ours" | tail -1)
    if [ "$got" != "$newname" ]; then
        echo "  $label: otool -D reads '$got', expected '$newname'" >&2; sub=1
    else note "otool -D: $got"; fi

    local rx_before rx_after
    rx_before=$(otool -l "$src"       | grep -A2 LC_REEXPORT_DYLIB | grep '  *name ' | awk '{print $2}' | sort)
    rx_after=$( otool -l "$TMP/ours"  | grep -A2 LC_REEXPORT_DYLIB | grep '  *name ' | awk '{print $2}' | sort)
    if [ "$rx_before" != "$rx_after" ]; then
        echo "  $label: LC_REEXPORT_DYLIB list changed" >&2; sub=1
    else note "reexports preserved: $(echo "$rx_before" | tr '\n' ' ')[$(echo "$rx_before" | grep -c .)]"; fi

    local ex_before ex_after
    ex_before=$(nm -gU "$src"      2>/dev/null | awk '{print $NF}' | sort -u)
    ex_after=$( nm -gU "$TMP/ours" 2>/dev/null | awk '{print $NF}' | sort -u)
    if [ "$ex_before" != "$ex_after" ]; then
        echo "  $label: export set changed ($(echo "$ex_before"|grep -c .) -> $(echo "$ex_after"|grep -c .))" >&2; sub=1
    else note "export set preserved: $(echo "$ex_before" | grep -c .) symbols"; fi

    # --- READ vs APPLE'S OWN TRANSFORM --------------------------------------
    xcrun install_name_tool -id "$newname" "$TMP/apple" 2>/dev/null || {
        echo "  $label: apple install_name_tool failed on the same input" >&2; sub=1; }
    local lcdiff
    lcdiff=$(diff <(otool -l "$TMP/ours" | tail -n +2) <(otool -l "$TMP/apple" | tail -n +2) \
             | grep '^[<>]' | grep -vE '(vmsize|filesize|datasize)' )
    if [ -n "$lcdiff" ]; then
        echo "  $label: load commands differ from Apple's transform beyond __LINKEDIT sizing:" >&2
        echo "$lcdiff" | head -10 >&2; sub=1
    else
        note "vs Apple's transform: load commands agree except __LINKEDIT renormalisation ($(diff <(otool -l "$TMP/ours") <(otool -l "$TMP/apple") | grep -c '^[<>]') size fields)"
    fi

    [ "$sub" -eq 0 ] || fail=$((fail+1))
}

echo "set_id_dylib_test: grading $PATCH  (machorun: $MACHORUN)"
grade "$MACHORUN/darwin/usr/lib/libSystem.B.dylib" /usr/lib/libSystem.real.dylib "libSystem.B -- name field 32B, needs 30: FITS IN PLACE"
grade "$MACHORUN/darwin/usr/lib/libc++.1.dylib"    /usr/lib/libc++.real.dylib    "libc++.1 -- name field 24B, needs 27: COMMAND MUST GROW"

# --- teeth: the refusals must actually fire ---------------------------------
# A refusal that has never been observed to fire is a comment.
echo "set_id_dylib_test: teeth (each refusal exercised on a real file)"
teeth() {
    local label=$1 file=$2 name=$3 pristine=${4:-}
    n=$((n+1))
    if perl "$PATCH" "$file" "$name" >"$TMP/msg" 2>&1; then
        echo "  $label: DID NOT REFUSE" >&2; fail=$((fail+1)); return; fi
    printf '  %-26s refused: %s\n' "$label" "$(head -1 "$TMP/msg")"
    if [ -n "$pristine" ] && ! cmp -s "$file" "$pristine"; then
        echo "  $label: REFUSED BUT MODIFIED THE FILE" >&2; fail=$((fail+1)); fi
}
cp "$MACHORUN/darwin/usr/lib/libc++.1.dylib" "$TMP/toolong"
teeth "over-long name" "$TMP/toolong" "/usr/lib/$(printf 'x%.0s' $(seq 1 200)).dylib" "$MACHORUN/darwin/usr/lib/libc++.1.dylib"

printf 'not a mach-o at all, not even close\n' >"$TMP/notmacho"
teeth "non-Mach-O" "$TMP/notmacho" /usr/lib/x.dylib

# The padding-is-zero guard: dirty the byte right after the load commands of a
# file that would otherwise grow cleanly, and require a refusal rather than a
# silent overwrite of somebody else's data.
cp "$MACHORUN/darwin/usr/lib/libc++.1.dylib" "$TMP/dirtypad"
perl -e 'open my $f, "+<:raw", $ARGV[0] or die $!; my $d = do { local $/; <$f> };
         my $eol = 32 + unpack("L", substr($d,20,4)); substr($d,$eol,1) = "\xAA";
         seek($f,0,0); print $f $d; close $f;' "$TMP/dirtypad"
cp "$TMP/dirtypad" "$TMP/dirtypad.orig"
teeth "dirty header padding" "$TMP/dirtypad" /usr/lib/libc++.real.dylib "$TMP/dirtypad.orig"

echo
if [ "$fail" -eq 0 ]; then
    echo "set_id_dylib_test: ok -- $n check(s): 2 renames graded (bound + Apple's reader), 3 refusals fired"
    exit 0
fi
echo "set_id_dylib_test: FAILED -- $fail of $n check(s)" >&2
exit 1
