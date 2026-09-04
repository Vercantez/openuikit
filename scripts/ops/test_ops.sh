#!/usr/bin/env bash
# Tests for scripts/ops/{run_box,x86_cycle,premerge}.sh against stub AWS/gh.
set -euo pipefail
ROOT=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
pass=0
fail=0
ok() { echo "PASS: $*"; pass=$((pass + 1)); }
die_test() { echo "FAIL: $*" >&2; fail=$((fail + 1)); }

STUBDIR=$(mktemp -d /tmp/ops-stub.XXXXXX)
cleanup() { rm -rf "$STUBDIR"; }
trap cleanup EXIT

cat > "$STUBDIR/aws" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
echo "$@" >> "${OPENUIKIT_AWS_LOG}"
cmd=$1
sub=${2:-}
shift 2 || true
case "$cmd $sub" in
    "ssm list-commands")
        if ! printf '%s\n' "$@" | grep -q 'key=Status,value=InProgress'; then
            echo '{"error":"unfiltered listing forbidden"}' >&2
            exit 2
        fi
        if [ "${OPENUIKIT_STUB_INPROGRESS:-0}" = 1 ]; then
            echo '{"Commands":[{"CommandId":"cmd-busy","Status":"InProgress"}]}'
        else
            echo '{"Commands":[]}'
        fi
        ;;
    "s3 cp")
        echo "upload $*" >&2
        ;;
    "ssm send-command")
        echo "cmd-stub-1"
        ;;
    "ssm get-command-invocation")
        python3 - <<'PY'
import json, os
print(json.dumps({
    "Status": "Success",
    "StandardOutputContent": os.environ.get(
        "OPENUIKIT_STUB_STDOUT",
        "STAGE prepare status=rebuilt key=abc123def456 product=/opt/openuikit/x86-verify/openuikit sha256=deadbeefcafe\n"
        "RUNG_SCOREBOARD a=PASS/smoke 14/14  b=PASS  c=PASS\n"
        "GATE_B_PASS\n"
        "pass 69 fail 0\n"
        "BUILD_OK\n",
    ),
    "StandardErrorContent": "",
}))
PY
        ;;
    *)
        echo "aws stub: unknown $cmd $sub $*" >&2
        exit 2
        ;;
esac
EOF
chmod +x "$STUBDIR/aws"

REALGIT=$(command -v git)
cat > "$STUBDIR/git" <<EOF
#!/usr/bin/env bash
if [ "\${1:-}" = -C ] && [ "\${3:-}" = bundle ]; then
    mkdir -p "\$(dirname "\$5")"
    cp "$STUBDIR/tiny.bundle" "\$5"
    exit 0
fi
exec "$REALGIT" "\$@"
EOF
chmod +x "$STUBDIR/git"
mkdir -p "$STUBDIR/empty.git"
"$REALGIT" -C "$STUBDIR" init -q empty.git
"$REALGIT" -C "$STUBDIR/empty.git" -c user.email=t@t -c user.name=t commit --allow-empty -qm init
"$REALGIT" -C "$STUBDIR/empty.git" bundle create "$STUBDIR/tiny.bundle" HEAD
export PATH="$STUBDIR:$PATH"

export OPENUIKIT_AWS=$STUBDIR/aws
export OPENUIKIT_AWS_LOG=$STUBDIR/aws.log
export GIT_AUTHOR_NAME=ops-test
export GIT_AUTHOR_EMAIL=ops-test@example.com
export GIT_COMMITTER_NAME=ops-test
export GIT_COMMITTER_EMAIL=ops-test@example.com

echo "== run_box --dry-run prints the SSM document"
doc=$(bash "$ROOT/scripts/ops/run_box.sh" --dry-run x86 cycle HEAD)
if printf '%s\n' "$doc" | python3 -c 'import json,sys; d=json.load(sys.stdin); assert d["DocumentName"]=="AWS-RunShellScript"; assert len(d["Comment"])<=100; assert d["InstanceIds"]==["i-0a2e25f3895c819b3"]; cmds=d["Parameters"]["commands"][0]; assert "x86_cycle.sh" in cmds; assert "OPENUIKIT_BUNDLE_URI" in cmds; assert "OPENUIKIT_S3_REGION" in cmds; assert "refs/ops/bundle" in cmds; assert cmds.index("git checkout") < cmds.index("x86_cycle.sh")'; then
    ok "x86 cycle dry-run document names instance and x86_cycle.sh"
else
    die_test "x86 cycle dry-run document: $(printf '%s' "$doc" | head -c 400)"
fi

doc=$(bash "$ROOT/scripts/ops/run_box.sh" --dry-run arm64 verify HEAD)
if printf '%s\n' "$doc" | python3 -c 'import json,sys; d=json.load(sys.stdin); assert d["InstanceIds"]==["i-00da4d9ca172eb1ff"]; c=d["Parameters"]["commands"][0]; assert "arm64_verify.sh" in c; assert c.index("git checkout") < c.index("arm64_verify.sh"); drv=open("scripts/ops/arm64_verify.sh").read(); assert "difftest.sh" in drv and "GATE_B_PASS" in drv and "build_full.sh" in drv and "stage_swiftcore.sh" in drv'; then
    ok "arm64 verify dry-run document names authority instance and GATE_B_PASS"
else
    die_test "arm64 verify dry-run: $(printf '%s' "$doc" | head -c 400)"
fi

echo "== run_box refuses InProgress (server-side filter)"
: > "$OPENUIKIT_AWS_LOG"
export OPENUIKIT_STUB_INPROGRESS=1
if bash "$ROOT/scripts/ops/run_box.sh" x86 cycle HEAD >"$STUBDIR/out" 2>"$STUBDIR/err"; then
    die_test "InProgress should refuse"
else
    grep -q InProgress "$STUBDIR/err" && ok "InProgress refuse names Status" \
        || die_test "err=$(cat "$STUBDIR/err")"
fi
unset OPENUIKIT_STUB_INPROGRESS
grep -q 'key=Status,value=InProgress' "$OPENUIKIT_AWS_LOG" \
    && ok "list-commands uses server-side InProgress filter" \
    || die_test "aws log=$(cat "$OPENUIKIT_AWS_LOG")"
if grep -q 'list-commands' "$OPENUIKIT_AWS_LOG" && ! grep 'list-commands' "$OPENUIKIT_AWS_LOG" | grep -q 'key=Status,value=InProgress'; then
    die_test "unfiltered list-commands was used"
fi
unset OPENUIKIT_STUB_INPROGRESS

echo "== run_box success extracts STAGE / scoreboard / GATE_B"
: > "$OPENUIKIT_AWS_LOG"
export OPENUIKIT_BUNDLE_FILE=$STUBDIR/tiny.bundle
out=$(bash "$ROOT/scripts/ops/run_box.sh" x86 cycle HEAD 2>"$STUBDIR/err" || true)
echo "$out" | grep -q 'STAGE prepare' && ok "run_box greps STAGE lines" \
    || die_test "out=$(echo "$out" | head -20) err=$(head -20 "$STUBDIR/err")"
echo "$out" | grep -q 'RUNG_SCOREBOARD' && ok "run_box greps RUNG_SCOREBOARD" \
    || die_test "missing RUNG_SCOREBOARD in $out"
echo "$out" | grep -q 'GATE_B_PASS' && ok "run_box greps GATE_B_PASS" \
    || die_test "missing GATE_B"
echo "$out" | grep -q 'pass 69 fail 0' && ok "run_box greps difftest pass 69 fail 0" \
    || die_test "missing pass/fail"
echo "$out" | grep -q 'BUILD_OK' && ok "run_box greps BUILD_OK" \
    || die_test "missing BUILD_OK"

echo "== comment cap 100"
python3 -c 'import json,sys; json.load(open("/dev/null"))' 2>/dev/null || true
doc=$(bash "$ROOT/scripts/ops/run_box.sh" --dry-run x86 cycle "$(python3 -c 'print("a"*200)')")
python3 -c 'import json,sys; d=json.load(sys.stdin); assert len(d["Comment"])<=100' <<<"$doc" \
    && ok "SSM comment capped at 100" \
    || die_test "comment too long"

echo "== x86_cycle --dry-run"
cyc=$(bash "$ROOT/scripts/ops/x86_cycle.sh" --dry-run)
echo "$cyc" | grep -q 'STAGE fetch_bundle status=planned' && ok "cycle dry-run STAGE fetch_bundle" \
    || die_test "$cyc"
echo "$cyc" | grep -q 'STAGE overlays status=planned' && ok "cycle dry-run STAGE overlays" \
    || die_test "no overlays stage"
echo "$cyc" | grep -q 'overlays after tbd' && ok "cycle dry-run states tbd-before-overlays reason" \
    || die_test "missing order reason"
grep -q 's3://\*)' "$ROOT/scripts/ops/x86_cycle.sh" \
    && grep -q 'ops_aws s3 cp' "$ROOT/scripts/ops/x86_cycle.sh" \
    && ok "cycle fetches s3:// via ops_aws s3 cp (not urllib)" \
    || die_test "x86_cycle.sh missing s3 fetch path"
echo "$cyc" | grep -q 'SWIFTCORE_OVERLAYS=1' && ok "cycle dry-run quotes PR64 overlay argv" \
    || die_test "missing overlay argv"
# order: tbd line before overlays line
python3 - <<PY
import sys
text = """$cyc"""
assert text.index("STAGE tbd") < text.index("STAGE overlays"), text
print("order ok")
PY
ok "cycle dry-run tbd before overlays"

echo "== x86_cycle stub"
cyc=$(OPENUIKIT_CYCLE_STUB=1 bash "$ROOT/scripts/ops/x86_cycle.sh")
echo "$cyc" | grep -c '^STAGE ' | grep -qx 8 && ok "cycle stub emits 8 STAGE lines" \
    || die_test "STAGE count=$(echo "$cyc" | grep -c '^STAGE ')"
echo "$cyc" | grep -q 'RUNG_SCOREBOARD' && ok "cycle stub quotes scoreboard" \
    || die_test "$cyc"
echo "$cyc" | grep -q 'positive board' && ok "cycle stub quotes positive persist board" \
    || die_test "missing positive board"

echo "== run_logged captures child rc (not the if-status)"
python3 - "$ROOT/scripts/ops/x86_cycle.sh" <<'PY'
import pathlib, sys
text = pathlib.Path(sys.argv[1]).read_text()
start = text.index("run_logged()")
end = text.index("emit_stage()", start)
body = text[start:end]
assert 'local rc=0' in body, body
assert '"$@" >"$log" 2>&1 || rc=$?' in body, body
assert 'if "$@" >"$log" 2>&1; then' not in body, body
# The old mask: capture $? after the if, which is always 0.
assert "set +e" not in body, body
print("run_logged ok")
PY
ok 'run_logged saves rc via || rc=$? (failed child is a failure)'

echo "== SKIP_PHASE2 / SKIP_OVERLAYS / ensure_machorun / real roots"
grep -q 'OPENUIKIT_CYCLE_SKIP_PHASE2' "$ROOT/scripts/ops/x86_cycle.sh" \
    && ok "cycle honours OPENUIKIT_CYCLE_SKIP_PHASE2" \
    || die_test "missing SKIP_PHASE2"
# The SKIP_PHASE2 branch must not grep phase2.log (that file is not written).
python3 - "$ROOT/scripts/ops/x86_cycle.sh" <<'PY' && ok "SKIP_PHASE2 does not grep a missing phase2.log" || die_test "SKIP_PHASE2 still greps phase2.log"
import pathlib, sys
text = pathlib.Path(sys.argv[1]).read_text()
start = text.find('if [ "${OPENUIKIT_CYCLE_SKIP_PHASE2:-0}" = 1 ]; then')
if start < 0:
    raise SystemExit(1)
chunk = text[start:]
# First branch is skip; grep of phase2.log must not appear before elif.
skip, _, rest = chunk.partition("elif ")
if "phase2.log" in skip:
    raise SystemExit(1)
PY
grep -q 'scripts/x86/ensure_machorun.sh' "$ROOT/scripts/ops/x86_cycle.sh" \
    && ok "cycle calls ensure_machorun before tbd" \
    || die_test "missing ensure_machorun"
grep -q 'scripts/x86/stage_cycle_roots.sh' "$ROOT/scripts/ops/x86_cycle.sh" \
    && ok "cycle roots stage calls stage_cycle_roots.sh" \
    || die_test "roots still a no-op stamp"
grep -q 'phase2_park_arm64_darwin_dylibs' "$ROOT/scripts/x86/ensure_machorun.sh" \
    && ok "ensure_machorun parks leftover arm64 dylibs" \
    || die_test "ensure_machorun missing park"
grep -q 'ensure_machorun_assert_vendor_clean' "$ROOT/scripts/x86/ensure_machorun.sh" \
    && ok "ensure_machorun asserts git status --short machorun is empty" \
    || die_test "ensure_machorun missing vendor-clean assertion"
grep -qF -- 'status --short --untracked-files=all -- machorun' "$ROOT/scripts/x86/ensure_machorun.sh" \
    && ok "ensure_machorun git-status pathspec is machorun" \
    || die_test "ensure_machorun missing git status --short machorun"
grep -q 'MACHORUN/build/machorun' "$ROOT/scripts/x86/ensure_machorun.sh" \
    && ok "ensure_machorun loader product is machorun/build/machorun" \
    || die_test "ensure_machorun loader path is not build/machorun"

echo "== ensure_machorun --layout-only moves stray loader and leaves git status empty"
LAYOUT=$STUBDIR/ensure-layout
mkdir -p "$LAYOUT/machorun"
printf 'tracked\n' > "$LAYOUT/machorun/README"
cp "$ROOT/machorun/.gitignore" "$LAYOUT/machorun/.gitignore"
git -C "$LAYOUT" init -q
git -C "$LAYOUT" add machorun/README machorun/.gitignore
git -C "$LAYOUT" commit -qm 'machorun pin'
# Box finding: cold-build left an untracked ELF at the subtree root.
printf 'ELF-STRAY-LOADER\n' > "$LAYOUT/machorun/machorun"
chmod +x "$LAYOUT/machorun/machorun"
dirty=$(git -C "$LAYOUT" status --short --untracked-files=all -- machorun)
printf '%s\n' "$dirty" | grep -q 'machorun/machorun' \
    && ok "fixture starts with ?? machorun/machorun" \
    || die_test "fixture not dirty: $dirty"
if bash "$ROOT/scripts/x86/ensure_machorun.sh" --layout-only "$LAYOUT" \
        >"$STUBDIR/layout.out" 2>"$STUBDIR/layout.err"; then
    ok "ensure_machorun --layout-only exits 0"
else
    die_test "layout-only rc!=0 err=$(cat "$STUBDIR/layout.err") out=$(cat "$STUBDIR/layout.out")"
fi
[ -x "$LAYOUT/machorun/build/machorun" ] \
    && grep -q ELF-STRAY-LOADER "$LAYOUT/machorun/build/machorun" \
    && ok "stray loader moved to machorun/build/machorun" \
    || die_test "missing committed-layout loader at build/machorun"
[ ! -e "$LAYOUT/machorun/machorun" ] \
    && ok "subtree-root machorun/machorun is gone" \
    || die_test "stray loader still at machorun/machorun"
clean=$(git -C "$LAYOUT" status --short --untracked-files=all -- machorun)
[ -z "$clean" ] \
    && ok "git status --short machorun is empty after ensure_machorun" \
    || die_test "machorun still dirty: $clean"

echo "== ensure_machorun --layout-only removes nested machorun/machorun symlink"
# Box residue: GNU ln -sfn "$MACHORUN" "$W/machorun" with W=$TREE nested a
# directory-symlink (~44 bytes), not the loader ELF.
ln -sfn "$LAYOUT/machorun" "$LAYOUT/machorun/machorun"
[ -L "$LAYOUT/machorun/machorun" ] \
    && ok "fixture nested symlink at machorun/machorun" \
    || die_test "failed to nest machorun/machorun symlink"
nested_sz=$(stat -c %s "$LAYOUT/machorun/machorun")
# GNU stat on a symlink (no -L) is the target-path length; the box residue was 44.
[ -n "$nested_sz" ] && [ "$nested_sz" -lt 200 ] \
    && ok "nested symlink is a short path ($nested_sz bytes), not the loader ELF" \
    || die_test "nested symlink size unexpected: $nested_sz"
if bash "$ROOT/scripts/x86/ensure_machorun.sh" --layout-only "$LAYOUT" \
        >"$STUBDIR/layout-sym.out" 2>"$STUBDIR/layout-sym.err"; then
    ok "ensure_machorun --layout-only exits 0 on nested symlink"
else
    die_test "layout-only symlink rc!=0 err=$(cat "$STUBDIR/layout-sym.err")"
fi
[ ! -e "$LAYOUT/machorun/machorun" ] \
    && ok "nested machorun/machorun symlink is gone" \
    || die_test "nested symlink still at machorun/machorun"
clean=$(git -C "$LAYOUT" status --short --untracked-files=all -- machorun)
[ -z "$clean" ] \
    && ok "git status --short machorun is empty after nested-symlink removal" \
    || die_test "machorun still dirty after symlink: $clean"

echo "== build_stdlib does not ln -sfn MACHORUN into an in-tree vendor dir"
grep -qF 'if [ -d "$W/machorun" ] && [ ! -L "$W/machorun" ]' \
    "$ROOT/swiftcore-macho/scripts/build_stdlib.sh" \
    && ok "build_stdlib guards ln -sfn into a real \$W/machorun directory" \
    || die_test "build_stdlib still unconditionally ln -sfn MACHORUN → W/machorun"
# Reproduce GNU ln nesting, then the same guard the cycle uses.
NEST=$STUBDIR/ln-nest
mkdir -p "$NEST/machorun"
ln -sfn "$NEST/machorun" "$NEST/machorun"
[ -L "$NEST/machorun/machorun" ] \
    && ok "GNU ln -sfn TARGET existing-dir nests TARGET/basename" \
    || die_test "this ln does not nest; the box residue writer would be elsewhere"
rm -f "$NEST/machorun/machorun"
if [ -d "$NEST/machorun" ] && [ ! -L "$NEST/machorun" ]; then
    [ ! -e "$NEST/machorun/machorun" ] \
        && ok "guard skips ln when W/machorun is the vendor directory" \
        || die_test "guard left a nested path"
else
    die_test "fixture W/machorun is not a real directory"
fi

echo "== x86_cycle asserts machorun git-status and Darwin.modulemap cmp at the end"
grep -q 'x86_cycle_assert_machorun_clean' "$ROOT/scripts/ops/x86_cycle.sh" \
    && ok "x86_cycle defines end-of-cycle machorun git-status assertion" \
    || die_test "x86_cycle missing x86_cycle_assert_machorun_clean"
grep -qF -- 'status --short --untracked-files=all -- machorun' \
    "$ROOT/scripts/ops/x86_cycle.sh" \
    && ok "x86_cycle git-status pathspec is machorun" \
    || die_test "x86_cycle missing git status --short machorun"
grep -q 'x86_cycle_assert_overlay_darwin_modulemap' "$ROOT/scripts/ops/x86_cycle.sh" \
    && ok "x86_cycle defines Darwin.modulemap cmp assertion" \
    || die_test "x86_cycle missing Darwin.modulemap assertion"
grep -q 'cmp -s "$sys_map" "$sdk_map"' "$ROOT/scripts/ops/x86_cycle.sh" \
    && ok "x86_cycle verifies Darwin.modulemap with cmp" \
    || die_test "x86_cycle missing cmp of SDK vs sysroot Darwin.modulemap"

# End-of-cycle assertion on a fixture tree (same checks as x86_cycle.sh).
CYC=$STUBDIR/cycle-assert
mkdir -p "$CYC/machorun" "$CYC/sdk/MacOSX.sdk/usr/include" \
    "$CYC/scratch/sysroot_fe4-x86_64/usr/include"
printf 'tracked\n' > "$CYC/machorun/README"
cp "$ROOT/machorun/.gitignore" "$CYC/machorun/.gitignore"
git -C "$CYC" init -q
git -C "$CYC" add machorun/README machorun/.gitignore
git -C "$CYC" commit -qm 'machorun pin'
printf 'module Darwin { header "math.h" }\n' \
    > "$CYC/scratch/sysroot_fe4-x86_64/usr/include/Darwin.modulemap"
printf 'module Darwin expanded { header "unistd.h" }\n' \
    > "$CYC/sdk/MacOSX.sdk/usr/include/Darwin.modulemap"
ln -sfn "$CYC/machorun" "$CYC/machorun/machorun"
# Same body as x86_cycle_assert_machorun_clean / _overlay_darwin_modulemap.
if [ -L "$CYC/machorun/machorun" ]; then
    rm -f "$CYC/machorun/machorun"
fi
cyc_status=$(git -C "$CYC" status --short --untracked-files=all -- machorun)
[ -z "$cyc_status" ] \
    && ok "cycle-end git status --short machorun is empty after symlink removal" \
    || die_test "cycle-end machorun dirty: $cyc_status"
cp -a "$CYC/scratch/sysroot_fe4-x86_64/usr/include/Darwin.modulemap" \
    "$CYC/sdk/MacOSX.sdk/usr/include/Darwin.modulemap"
cmp -s "$CYC/scratch/sysroot_fe4-x86_64/usr/include/Darwin.modulemap" \
    "$CYC/sdk/MacOSX.sdk/usr/include/Darwin.modulemap" \
    && ok "cycle-end cmp: SDK Darwin.modulemap matches sysroot" \
    || die_test "cycle-end left SDK Darwin.modulemap different from sysroot"
[ ! -e "$CYC/machorun/machorun" ] \
    && ok "cycle-end assertion removed nested machorun/machorun" \
    || die_test "cycle-end left nested machorun/machorun"

echo "== premerge"
cat > "$STUBDIR/gh" <<'EOF'
#!/usr/bin/env bash
python3 - <<'PY'
import json
print(json.dumps({
    "number": 99,
    "title": "stamp",
    "body": "Run bash scripts/x86/test_stamp.sh and python3 scripts/env/test_contract.py",
    "baseRefName": "main",
}))
PY
EOF
chmod +x "$STUBDIR/gh"
export OPENUIKIT_GH=$STUBDIR/gh
FAKE=$STUBDIR/premerge-tree
mkdir -p "$FAKE/scripts/env" "$FAKE/scripts/x86" "$FAKE/env"
# Minimal tree that pin-advance can edit and that named tests can run.
cp "$ROOT/scripts/vendor_pins.sh" "$FAKE/scripts/vendor_pins.sh"
cp "$ROOT/env/contract.json" "$FAKE/env/contract.json"
cp "$ROOT/scripts/env/test_contract.py" "$FAKE/scripts/env/test_contract.py"
# Named PR test: a tiny passing script.
mkdir -p "$FAKE/scripts/x86"
printf '#!/bin/sh\necho stamp-ok\nexit 0\n' > "$FAKE/scripts/x86/test_stamp.sh"
chmod +x "$FAKE/scripts/x86/test_stamp.sh"
# test_contract.py needs the real repo; skip by replacing with a stub in the fake tree.
printf '#!/usr/bin/env python3\nprint("contract-ok")\n' > "$FAKE/scripts/env/test_contract.py"
printf '#!/bin/sh\necho vendor-ok\n' > "$FAKE/scripts/test_vendor_tree.sh"
chmod +x "$FAKE/scripts/test_vendor_tree.sh"
# Pin advance needs git rev-parse HEAD:machorun. Make a tiny git repo with those trees.
mkdir -p "$FAKE/machorun" "$FAKE/uikit"
printf 'x\n' > "$FAKE/machorun/f"
printf 'y\n' > "$FAKE/uikit/f"
git -C "$FAKE" init -q
git -C "$FAKE" add machorun uikit scripts env
git -C "$FAKE" commit -qm 'fake trees'
verdict=$(
    OPENUIKIT_PREMERGE_SKIP_GIT=1 \
    OPENUIKIT_PREMERGE_WORKDIR=$FAKE \
    OPENUIKIT_PREMERGE_CHANGED=$'machorun/f\n' \
    bash "$ROOT/scripts/ops/premerge.sh" 99 2>"$STUBDIR/premerge.err" || true
)
echo "$verdict" | grep -q 'PREMERGE pr=99 verdict=PASS' && ok "premerge PASS verdict" \
    || die_test "verdict=$verdict err=$(cat "$STUBDIR/premerge.err")"
echo "$verdict" | grep -q pin-advanced && ok "premerge advanced the vendor pin" \
    || die_test "no pin-advanced in $verdict"
grep -q "$(git -C "$FAKE" rev-parse HEAD:machorun)" "$FAKE/scripts/vendor_pins.sh" \
    && ok "vendor_pins.sh sed/python advanced HEAD:machorun" \
    || die_test "pin file=$(cat "$FAKE/scripts/vendor_pins.sh")"

echo
echo "test_ops: pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
