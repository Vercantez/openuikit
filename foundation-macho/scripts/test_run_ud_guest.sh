#!/usr/bin/env bash
# Teeth for run_ud_guest.sh / run_ud_persist.sh argv: loader sha256 on the
# == binary line, no preload without DISPATCH_HOST (the #87 path), and with
# the Reminder/Focus vars the host is LD_PRELOADed and the Darwin runtime is
# staged into a run-local overlay rather than the named root.
#
#   bash foundation-macho/scripts/test_run_ud_guest.sh
set -euo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
FM=$(cd "$HERE/.." && pwd)
ROOT=$(cd "$FM/.." && pwd)
GUEST=$HERE/run_ud_guest.sh
PERSIST=$HERE/run_ud_persist.sh
INC=$HERE/ud_dispatch_run.inc
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

echo "== bash -n"
for s in "$GUEST" "$PERSIST" "$INC"; do
    if bash -n "$s"; then
        ok "bash -n $(basename "$s")"
    else
        die_test "bash -n $(basename "$s")"
    fi
done

guest=$(cat "$GUEST")
persist=$(cat "$PERSIST")
inc=$(cat "$INC")
expect_grep 'ud_dispatch_run.inc' "$guest" "run_ud_guest.sh sources the shared dispatch helper"
expect_grep 'ud_dispatch_run.inc' "$persist" "run_ud_persist.sh sources the shared dispatch helper"
expect_grep 'ud_dispatch_loader_line' "$guest" "run_ud_guest.sh prints loader sha256 on == binary"
expect_grep 'ud_dispatch_loader_line' "$persist" "run_ud_persist.sh prints loader sha256 on == binary"
expect_grep 'ud_dispatch_prepare_root' "$guest" "run_ud_guest.sh prepares an optional runroot"
expect_grep 'ud_dispatch_prepare_root' "$persist" "run_ud_persist.sh prepares an optional runroot"
expect_grep 'ud_dispatch_run' "$guest" "run_ud_guest.sh execs through ud_dispatch_run"
expect_grep 'UD_MODE=persist-write ud_dispatch_run' "$persist" \
    "persist WRITE goes through ud_dispatch_run"
expect_grep 'UD_MODE=persist-read ud_dispatch_run' "$persist" \
    "persist READ goes through ud_dispatch_run"
expect_grep 'DISPATCH_HOST' "$inc" "helper reuses the Reminder/Focus DISPATCH_HOST name"
expect_grep 'OPENUI_DISPATCH_HOST' "$inc" "OPENUI_DISPATCH_HOST is accepted as an alias"
expect_grep 'LD_PRELOAD' "$inc" "helper LD_PRELOADs the host bridge"
expect_grep 'LD_LIBRARY_PATH' "$inc" "helper sets LD_LIBRARY_PATH to the host dir"
expect_grep 'darwin/usr/lib/libOpenDispatch.dylib' "$inc" \
    "Darwin runtime is staged at /usr/lib/libOpenDispatch.dylib"
expect_grep 'run-local overlay' "$inc" "helper clones a run-local overlay"
expect_grep 'BIND_SPECIAL_DYLIB_FLAT_LOOKUP' "$inc" \
    "helper documents libCFTest's flat dispatch binds"
expect_grep 'is_runtime' "$inc" "helper cites machorun is_runtime"
expect_grep 'sha256=' "$inc" "loader line includes sha256="
# Without the vars the exec must still be MACHORUN_ROOT=$ROOT "$MRUN" (via the
# helper's empty-preload branch). The #87 default MRUN must remain.
expect_grep 'MRUN:-/stage/machorun-bin' "$guest" \
    "run_ud_guest.sh default MRUN is still /stage/machorun-bin"
expect_grep 'MRUN:-/stage/machorun-bin' "$persist" \
    "run_ud_persist.sh default MRUN is still /stage/machorun-bin"

echo "== dummy root: no DISPATCH_HOST keeps the #87 argv"
W=$(mktemp -d /tmp/run-ud-guest.XXXXXX)
cleanup() { rm -rf "$W"; }
trap cleanup EXIT

mkdir -p "$W/root/darwin/System/Library/Frameworks/Foundation.framework" \
    "$W/root/darwin/System/Library/Frameworks/CoreFoundation.framework" \
    "$W/root/darwin/usr/lib" \
    "$W/bin"
echo placeholder > "$W/root/darwin/System/Library/Frameworks/Foundation.framework/Foundation"
echo placeholder > "$W/root/darwin/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation"
echo cftest > "$W/root/darwin/usr/lib/libCFTest.dylib"
echo 'int main(void){return 0;}' > "$W/bin/ud_guest"

cat > "$W/fake-mrun" <<'EOF'
#!/bin/bash
printf 'MRUN_ARGV %s\n' "$*"
printf 'MACHORUN_ROOT=%s\n' "${MACHORUN_ROOT:-}"
printf 'LD_PRELOAD=%s\n' "${LD_PRELOAD:-}"
printf 'LD_LIBRARY_PATH=%s\n' "${LD_LIBRARY_PATH:-}"
exit 0
EOF
chmod +x "$W/fake-mrun"
want_sha=$(sha256sum "$W/fake-mrun" | awk '{print $1}')

log=$W/no-dispatch.log
set +e
W="$W" BIN="$W/bin/ud_guest" MRUN="$W/fake-mrun" \
    bash "$GUEST" "$W/root" >"$log" 2>&1
st=$?
set -e
echo "$log:"
cat "$log"

if [ "$st" -eq 0 ]; then
    ok "no-DISPATCH_HOST runner exit 0"
else
    die_test "no-DISPATCH_HOST runner exit $st log=$(tr '\n' ' ' < "$log")"
fi
if grep -q "^== binary $W/bin/ud_guest  loader=$W/fake-mrun sha256=$want_sha" "$log"
then
    ok "== binary names loader path and sha256"
else
    die_test "== binary line missing loader sha256. got: $(grep '^== binary' "$log")"
fi
if grep -q "^MACHORUN_ROOT=$W/root$" "$log" \
    && grep -q '^LD_PRELOAD=$' "$log"
then
    ok "without DISPATCH_HOST, MACHORUN_ROOT is the named root and LD_PRELOAD is empty"
else
    die_test "no-dispatch argv drifted: $(grep -E 'MACHORUN_ROOT|LD_PRELOAD' "$log")"
fi
if grep -q '^== runroot ' "$log"; then
    die_test "no-DISPATCH_HOST still printed == runroot"
else
    ok "no-DISPATCH_HOST does not clone a runroot"
fi
if [ ! -e "$W/runroot" ]; then
    ok "named root was not cloned when DISPATCH_HOST is unset"
else
    die_test "runroot appeared without DISPATCH_HOST"
fi
if [ ! -e "$W/root/darwin/usr/lib/libOpenDispatch.dylib" ]; then
    ok "named root was not mutated without DISPATCH_HOST"
else
    die_test "libOpenDispatch.dylib appeared in the named root"
fi

echo "== DISPATCH_HOST + DISPATCH_DARWIN: preload, runroot, named root untouched"
mkdir -p "$W/host"
echo 'int host=1;' | clang-18 -shared -o "$W/host/libOpenDispatchHost.so" -x c - \
    || echo hostbridge > "$W/host/libOpenDispatchHost.so"
# Darwin runtime: a regular file is enough for the runner (it copies bytes).
echo darwin-facade > "$W/libOpenDispatch.dylib"

log=$W/with-dispatch.log
set +e
W="$W" BIN="$W/bin/ud_guest" MRUN="$W/fake-mrun" \
    DISPATCH_HOST="$W/host/libOpenDispatchHost.so" \
    DISPATCH_DARWIN="$W/libOpenDispatch.dylib" \
    bash "$GUEST" "$W/root" >"$log" 2>&1
st=$?
set -e
echo "$log:"
cat "$log"

if [ "$st" -eq 0 ]; then
    ok "DISPATCH_HOST runner exit 0"
else
    die_test "DISPATCH_HOST runner exit $st log=$(tr '\n' ' ' < "$log")"
fi
if grep -q "^== runroot $W/runroot$" "$log"; then
    ok "prints == runroot \$W/runroot"
else
    die_test "missing == runroot line: $(grep runroot "$log" || true)"
fi
if grep -q "LD_PRELOAD=$W/host/libOpenDispatchHost.so" "$log"; then
    ok "LD_PRELOAD contains the host bridge"
else
    die_test "LD_PRELOAD missing host bridge: $(grep LD_PRELOAD "$log")"
fi
if grep -q "LD_LIBRARY_PATH=$W/host" "$log"; then
    ok "LD_LIBRARY_PATH is the host dir"
else
    die_test "LD_LIBRARY_PATH drifted: $(grep LD_LIBRARY_PATH "$log")"
fi
if grep -q "^MACHORUN_ROOT=$W/runroot$" "$log"; then
    ok "MACHORUN_ROOT is the run-local overlay"
else
    die_test "MACHORUN_ROOT was not the overlay: $(grep MACHORUN_ROOT "$log")"
fi
if [ -f "$W/runroot/darwin/usr/lib/libOpenDispatch.dylib" ] \
    && cmp -s "$W/libOpenDispatch.dylib" \
        "$W/runroot/darwin/usr/lib/libOpenDispatch.dylib"
then
    ok "Darwin runtime staged at runroot/darwin/usr/lib/libOpenDispatch.dylib"
else
    die_test "Darwin runtime missing from runroot"
fi
if [ ! -e "$W/root/darwin/usr/lib/libOpenDispatch.dylib" ]; then
    ok "named root was not mutated (no libOpenDispatch.dylib in MRROOT)"
else
    die_test "DISPATCH_HOST path wrote into the named root"
fi
if grep -q "^== binary $W/bin/ud_guest  loader=$W/fake-mrun sha256=$want_sha" "$log"
then
    ok "DISPATCH_HOST path still prints loader sha256"
else
    die_test "DISPATCH_HOST == binary line drifted: $(grep '^== binary' "$log")"
fi

echo "== OPENUI_DISPATCH_HOST alias"
log=$W/alias.log
rm -rf "$W/runroot"
set +e
W="$W" BIN="$W/bin/ud_guest" MRUN="$W/fake-mrun" \
    OPENUI_DISPATCH_HOST="$W/host/libOpenDispatchHost.so" \
    DISPATCH_DARWIN="$W/libOpenDispatch.dylib" \
    bash "$GUEST" "$W/root" >"$log" 2>&1
st=$?
set -e
if [ "$st" -eq 0 ] && grep -q "LD_PRELOAD=$W/host/libOpenDispatchHost.so" "$log"
then
    ok "OPENUI_DISPATCH_HOST alias LD_PRELOADs the same bridge"
else
    die_test "OPENUI_DISPATCH_HOST alias failed: exit $st $(tr '\n' ' ' < "$log")"
fi

echo "== persist runner argv with DISPATCH_HOST (write phase only needs exec)"
# persist will fail later (no plist) unless we only check the first exec.
# Point PREFS at a writable temp and use a fake mrun that creates the plist
# on persist-write so the witness passes, then fails the read as a control.
mkdir -p "$W/prefs"
plist_path=$W/prefs/com.example.udguest.persist.plist
cat > "$W/fake-persist-mrun" <<EOS
#!/bin/bash
printf 'LD_PRELOAD=%s\n' "\${LD_PRELOAD:-}"
printf 'MACHORUN_ROOT=%s\n' "\${MACHORUN_ROOT:-}"
if [ "\${UD_MODE:-}" = persist-write ]; then
    mkdir -p "$W/prefs"
    python3 -c 'from pathlib import Path; Path("'"$plist_path"'").write_bytes(b"bplist00" + b"x" * 600 + b"9223372036854775807")'
    exit 0
fi
if [ -f "$plist_path" ]; then
    exit 0
fi
exit 1
EOS
chmod +x "$W/fake-persist-mrun"
log=$W/persist.log
set +e
W="$W" BIN="$W/bin/ud_guest" MRUN="$W/fake-persist-mrun" \
    PREFS="$W/prefs" \
    DISPATCH_HOST="$W/host/libOpenDispatchHost.so" \
    DISPATCH_DARWIN="$W/libOpenDispatch.dylib" \
    bash "$PERSIST" "$W/root" >"$log" 2>&1
st=$?
set -e
echo "$log:"
cat "$log"
if [ "$st" -eq 0 ] \
    && grep -q "LD_PRELOAD=$W/host/libOpenDispatchHost.so" "$log" \
    && grep -q "^== runroot $W/runroot$" "$log" \
    && grep -q "loader=$W/fake-persist-mrun sha256=" "$log"
then
    ok "run_ud_persist.sh LD_PRELOADs, prints runroot, prints loader sha256"
else
    die_test "persist dispatch argv failed: exit $st $(tr '\n' ' ' < "$log")"
fi

echo "test_run_ud_guest: pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
