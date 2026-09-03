#!/usr/bin/env bash

set -euo pipefail

started_ns=$(date +%s%N)
phase_ns=$started_ns
cleanup_ms=0
tools_ms=0
evidence_ms=0
corpus_ms=0
products_ms=0
swift_ms=0
finish_phase() {
    current_ns=$(date +%s%N)
    elapsed_ms=$(( (current_ns - phase_ns) / 1000000 ))
    phase_ns=$current_ns
}

repo_root=$(git rev-parse --show-toplevel)
case "$repo_root" in
    ''|/) printf 'cursor-environment: unsafe repository root: %s\n' "$repo_root" >&2; exit 1 ;;
esac
[ -f "$repo_root/harness/Dockerfile" ] \
    || { printf 'cursor-environment: OpenUIKit repository marker is missing\n' >&2; exit 1; }

# Wipe per-agent SwiftPM trees (.build). Do NOT wipe scratch/. Do NOT wipe
# build/full-x86_64: that is the phase2 FE object tree install snapshots so a
# PHASE2_RUNGS=a rerun is stamp reuse. Other build/ children are still cleared.
for relative in .build; do
    tracked_paths=$(git -C "$repo_root" ls-files -- "$relative") \
        || { printf 'cursor-environment: cannot inspect tracked cleanup paths\n' >&2; exit 1; }
    if [ -n "$tracked_paths" ]; then
        printf 'cursor-environment: refusing to clean tracked path: %s\n' "$relative" >&2
        exit 1
    fi
    generated_root=$repo_root/$relative
    if [ -e "$generated_root" ] || [ -L "$generated_root" ]; then
        rm -rf -- "$generated_root"
    fi
done
tracked_build=$(git -C "$repo_root" ls-files -- build) \
    || { printf 'cursor-environment: cannot inspect tracked build path\n' >&2; exit 1; }
[ -z "$tracked_build" ] \
    || { printf 'cursor-environment: refusing to treat tracked build/ as generated\n' >&2; exit 1; }
if [ -d "$repo_root/build" ] && [ ! -L "$repo_root/build" ]; then
    find "$repo_root/build" -mindepth 1 -maxdepth 1 ! -name 'full-x86_64' \
        -exec rm -rf -- {} +
fi
tracked_scratch=$(git -C "$repo_root" ls-files -- scratch) \
    || { printf 'cursor-environment: cannot inspect tracked scratch path\n' >&2; exit 1; }
[ -z "$tracked_scratch" ] \
    || { printf 'cursor-environment: refusing to treat tracked scratch/ as generated\n' >&2; exit 1; }
finish_phase
cleanup_ms=$elapsed_ms

for tool in \
    swift swiftc \
    clang clang++ clang-18 clang++-18 \
    ld64.lld ld64.lld-18 \
    llvm-nm llvm-nm-18 \
    llvm-otool llvm-otool-18 \
    llvm-objdump llvm-objdump-18 \
    perl patch jq sha256sum shasum cmp file git python3 pkg-config
do
    command -v "$tool" >/dev/null \
        || { printf 'cursor-environment: missing tool: %s\n' "$tool" >&2; exit 1; }
done

# Consumers invoke both spellings. Refuse an image where an unversioned LLVM
# name resolves to a different toolchain instead of the pinned Ubuntu LLVM 18
# binary installed above.
for llvm_tool in llvm-nm llvm-otool llvm-objdump; do
    unversioned_path=$(command -v "$llvm_tool")
    versioned_path=$(command -v "${llvm_tool}-18")
    [ "$(readlink -f "$unversioned_path")" = "$(readlink -f "$versioned_path")" ] \
        || { printf 'cursor-environment: %s does not resolve to %s-18\n' \
            "$llvm_tool" "$llvm_tool" >&2; exit 1; }
done
if command -v llvm-readtapi-18 >/dev/null; then
    command -v llvm-readtapi >/dev/null \
        || { printf 'cursor-environment: missing tool: llvm-readtapi\n' >&2; exit 1; }
    [ "$(readlink -f "$(command -v llvm-readtapi)")" = \
        "$(readlink -f "$(command -v llvm-readtapi-18)")" ] \
        || { printf 'cursor-environment: llvm-readtapi does not resolve to llvm-readtapi-18\n' >&2; exit 1; }
fi
finish_phase
tools_ms=$elapsed_ms

evidence_lock=$repo_root/full/framework-fanout/external-evidence-sources.json
[ -f "$evidence_lock" ] \
    || { printf 'cursor-environment: external evidence lock is missing\n' >&2; exit 1; }
[ "${OPENUIKIT_MACIOS_ROOT:-}" = /opt/openuikit-evidence/dotnet-macios ] \
    || { printf 'cursor-environment: OPENUIKIT_MACIOS_ROOT differs\n' >&2; exit 1; }
if [ ! -d "$OPENUIKIT_MACIOS_ROOT/.git" ] || [ -L "$OPENUIKIT_MACIOS_ROOT" ]; then
    printf 'cursor-environment: macios evidence checkout is missing\n' >&2
    exit 1
fi
expected_macios_commit=$(jq -er \
    '.sources[] | select(.id == "dotnet-macios") | .commit' "$evidence_lock")
expected_macios_repository=$(jq -er \
    '.sources[] | select(.id == "dotnet-macios") | .repository' "$evidence_lock")
expected_license_path=$(jq -er \
    '.sources[] | select(.id == "dotnet-macios") | .licensePath' "$evidence_lock")
expected_license_sha256=$(jq -er \
    '.sources[] | select(.id == "dotnet-macios") | .licenseSHA256' "$evidence_lock")
[[ "$expected_macios_repository" =~ ^https://github\.com/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+\.git$ ]] \
    || { printf 'cursor-environment: macios repository URL is invalid\n' >&2; exit 1; }
[[ "$expected_license_path" =~ ^[A-Za-z0-9._/-]+$ ]] \
    || { printf 'cursor-environment: macios license path is invalid\n' >&2; exit 1; }
case "/$expected_license_path/" in
    *'/../'*|*'/./'*|'//'*) printf 'cursor-environment: macios license path is unsafe\n' >&2; exit 1 ;;
esac
git_macios() {
    git -c safe.directory="$OPENUIKIT_MACIOS_ROOT" \
        -C "$OPENUIKIT_MACIOS_ROOT" "$@"
}
origin_guard=$repo_root/.cursor/validate-static-evidence-origin.sh
if [ ! -f "$origin_guard" ] || [ -L "$origin_guard" ]; then
    printf 'cursor-environment: repository origin guard is missing or unsafe\n' >&2
    exit 1
fi
[ "$(git_macios rev-parse HEAD)" = "$expected_macios_commit" ] \
    || { printf 'cursor-environment: macios evidence commit differs\n' >&2; exit 1; }
bash "$origin_guard" "$OPENUIKIT_MACIOS_ROOT" "$expected_macios_repository"
macios_sparse_paths=$(git_macios sparse-checkout list) \
    || { printf 'cursor-environment: cannot inspect macios sparse checkout\n' >&2; exit 1; }
[ "$macios_sparse_paths" = src ] \
    || { printf 'cursor-environment: macios sparse checkout differs from required src corpus\n' >&2; exit 1; }
if [ ! -d "$OPENUIKIT_MACIOS_ROOT/src" ] || [ -L "$OPENUIKIT_MACIOS_ROOT/src" ]; then
    printf 'cursor-environment: required macios src corpus is missing\n' >&2
    exit 1
fi
[ "$(sha256sum "$OPENUIKIT_MACIOS_ROOT/$expected_license_path" | awk '{print $1}')" = "$expected_license_sha256" ] \
    || { printf 'cursor-environment: macios evidence license differs\n' >&2; exit 1; }
macios_status=$(git_macios --no-optional-locks status \
    --porcelain=v1 --untracked-files=all --ignored) \
    || { printf 'cursor-environment: cannot inspect macios checkout status\n' >&2; exit 1; }
[ -z "$macios_status" ] \
    || { printf 'cursor-environment: macios evidence checkout is dirty\n' >&2; exit 1; }
[ "$(stat -c '%U:%G:%a' "$(dirname "$OPENUIKIT_MACIOS_ROOT")")" = root:root:755 ] \
    || { printf 'cursor-environment: evidence parent ownership or mode differs\n' >&2; exit 1; }
macios_nonroot=$(find "$OPENUIKIT_MACIOS_ROOT" \
    \( -type f -o -type d \) ! -user root -print -quit) \
    || { printf 'cursor-environment: cannot inspect macios ownership\n' >&2; exit 1; }
[ -z "$macios_nonroot" ] \
    || { printf 'cursor-environment: macios evidence is not root-owned\n' >&2; exit 1; }
macios_writable=$(find "$OPENUIKIT_MACIOS_ROOT" \
    \( -type f -o -type d \) -perm /222 -print -quit) \
    || { printf 'cursor-environment: cannot inspect macios modes\n' >&2; exit 1; }
[ -z "$macios_writable" ] \
    || { printf 'cursor-environment: macios evidence remains writable\n' >&2; exit 1; }
macios_symlink=$(find "$OPENUIKIT_MACIOS_ROOT" -type l -print -quit) \
    || { printf 'cursor-environment: cannot inspect macios links\n' >&2; exit 1; }
[ -z "$macios_symlink" ] \
    || { printf 'cursor-environment: macios evidence contains a symbolic link\n' >&2; exit 1; }
finish_phase
evidence_ms=$elapsed_ms

corpus_lock=$repo_root/.cursor/scratch-corpus-pins.json
cloner=$repo_root/.cursor/clone-pinned-repo.sh
[ -f "$corpus_lock" ] && [ ! -L "$corpus_lock" ] \
    || { printf 'cursor-environment: scratch corpus lock is missing\n' >&2; exit 1; }
[ -f "$cloner" ] && [ ! -L "$cloner" ] \
    || { printf 'cursor-environment: scratch corpus cloner is missing\n' >&2; exit 1; }
corpus_ids=$(jq -er '.sources[].id' "$corpus_lock")
corpus_count=0
corpus_ok=0
while IFS= read -r corpus_id; do
    [ -n "$corpus_id" ] || continue
    corpus_count=$((corpus_count + 1))
    destination=$(jq -er --arg id "$corpus_id" \
        '.sources[] | select(.id == $id) | .destination' "$corpus_lock")
    commit=$(jq -er --arg id "$corpus_id" \
        '.sources[] | select(.id == $id) | .commit' "$corpus_lock")
    tree=$(jq -er --arg id "$corpus_id" \
        '.sources[] | select(.id == $id) | .tree' "$corpus_lock")
    repository=$(jq -er --arg id "$corpus_id" \
        '.sources[] | select(.id == $id) | .repository' "$corpus_lock")
    dest=$repo_root/$destination
    [ -d "$dest/.git" ] && [ ! -L "$dest" ] \
        || { printf 'cursor-environment: missing corpus checkout: %s\n' "$destination" >&2; exit 1; }
    git_corpus() { git -c safe.directory="$dest" -C "$dest" "$@"; }
    [ "$(git_corpus rev-parse HEAD)" = "$commit" ] \
        || { printf 'cursor-environment: %s commit differs\n' "$corpus_id" >&2; exit 1; }
    [ "$(git_corpus rev-parse 'HEAD^{tree}')" = "$tree" ] \
        || { printf 'cursor-environment: %s tree differs\n' "$corpus_id" >&2; exit 1; }
    bash "$origin_guard" "$dest" "$repository"
    corpus_status=$(git_corpus --no-optional-locks status \
        --porcelain=v1 --untracked-files=all --ignored) \
        || { printf 'cursor-environment: cannot inspect %s status\n' "$corpus_id" >&2; exit 1; }
    [ -z "$corpus_status" ] \
        || { printf 'cursor-environment: %s checkout is dirty\n' "$corpus_id" >&2; exit 1; }
    corpus_ok=$((corpus_ok + 1))
done <<EOF
$corpus_ids
EOF
[ "$corpus_count" -gt 0 ] && [ "$corpus_ok" -eq "$corpus_count" ] \
    || { printf 'cursor-environment: corpus pins %s/%s\n' "$corpus_ok" "$corpus_count" >&2; exit 1; }

# Same two checkouts the install path clones from env/contract.json (not the
# corpus pin file). A checkout cannot be locked in two places.
contract_rows=$(python3 - "$repo_root" <<'PY'
import sys
from pathlib import Path

root = Path(sys.argv[1])
sys.path.insert(0, str(root / "scripts"))
from env.contract import checkouts_by_id, load_contract

ids = ("swift-foundation-icu", "swift-corelibs-foundation")
by_id = checkouts_by_id(load_contract(root))
for ident in ids:
    row = by_id[ident]
    print(
        "\t".join(
            [
                ident,
                row["repository"],
                row["commit"],
                row["tree"],
                row["destination"],
            ]
        )
    )
PY
)
contract_count=0
contract_ok=0
while IFS=$'\t' read -r corpus_id repository commit tree destination; do
    [ -n "$corpus_id" ] || continue
    contract_count=$((contract_count + 1))
    dest=$repo_root/$destination
    [ -d "$dest/.git" ] && [ ! -L "$dest" ] \
        || { printf 'cursor-environment: missing contract checkout: %s\n' "$destination" >&2; exit 1; }
    git_corpus() { git -c safe.directory="$dest" -C "$dest" "$@"; }
    [ "$(git_corpus rev-parse HEAD)" = "$commit" ] \
        || { printf 'cursor-environment: %s commit differs\n' "$corpus_id" >&2; exit 1; }
    [ "$(git_corpus rev-parse 'HEAD^{tree}')" = "$tree" ] \
        || { printf 'cursor-environment: %s tree differs\n' "$corpus_id" >&2; exit 1; }
    bash "$origin_guard" "$dest" "$repository"
    corpus_status=$(git_corpus --no-optional-locks status \
        --porcelain=v1 --untracked-files=all --ignored) \
        || { printf 'cursor-environment: cannot inspect %s status\n' "$corpus_id" >&2; exit 1; }
    [ -z "$corpus_status" ] \
        || { printf 'cursor-environment: %s checkout is dirty\n' "$corpus_id" >&2; exit 1; }
    contract_ok=$((contract_ok + 1))
done <<EOF
$contract_rows
EOF
[ "$contract_count" -eq 2 ] && [ "$contract_ok" -eq "$contract_count" ] \
    || { printf 'cursor-environment: contract checkouts %s/%s\n' "$contract_ok" "$contract_count" >&2; exit 1; }
pinned_inputs=$repo_root/full/foundation/pinned_inputs.pl
if [ -f "$pinned_inputs" ] && [ ! -L "$pinned_inputs" ]; then
    perl "$pinned_inputs" verify \
        --swift-foundation "$repo_root/scratch/swift-foundation" \
        --swift-collections "$repo_root/scratch/swift-collections" >/dev/null
fi
finish_phase
corpus_ms=$elapsed_ms

products_manifest=$repo_root/scratch/.cursor-built-products.json
unavailable_log=$repo_root/scratch/.cursor-unavailable.txt
[ -f "$products_manifest" ] && [ ! -L "$products_manifest" ] \
    || { printf 'cursor-environment: built-product manifest is missing\n' >&2; exit 1; }
[ -f "$unavailable_log" ] && [ ! -L "$unavailable_log" ] \
    || { printf 'cursor-environment: unavailable-product log is missing\n' >&2; exit 1; }
python3 - "$products_manifest" "$repo_root" <<'PY'
import hashlib, json, os, sys
from pathlib import Path

manifest_path = Path(sys.argv[1])
repo = Path(sys.argv[2])
payload = json.loads(manifest_path.read_text(encoding="utf-8"))
sys.path.insert(0, str(repo / ".cursor"))
import importlib.util
spec = importlib.util.spec_from_file_location("tree_digest", repo / ".cursor" / "tree-digest.py")
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as fh:
        for chunk in iter(lambda: fh.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()

for label, info in sorted(payload["files"].items()):
    path = Path(info["path"])
    if not path.is_file() or path.is_symlink():
        raise SystemExit(f"cursor-environment: missing built product: {label}")
    digest = sha256(path)
    if digest != info["sha256"]:
        raise SystemExit(f"cursor-environment: {label} hash differs: {digest}")
    if path.stat().st_size != info["bytes"]:
        raise SystemExit(f"cursor-environment: {label} size differs")

sysroot = Path(payload["sysrootFe4"])
mrroot = Path(payload["mrrootFull"])
if not sysroot.is_dir() or sysroot.is_symlink():
    raise SystemExit("cursor-environment: sysroot_fe4 is missing")
if not mrroot.is_dir() or mrroot.is_symlink():
    raise SystemExit("cursor-environment: mrroot_full is missing")
if mod.tree_digest(sysroot) != payload["sysrootFe4TreeSha256"]:
    raise SystemExit("cursor-environment: sysroot_fe4 tree hash differs")
if mod.tree_digest(mrroot) != payload["mrrootFullTreeSha256"]:
    raise SystemExit("cursor-environment: mrroot_full tree hash differs")
if payload.get("loaderBuilt"):
    loader = mrroot / "machorun"
    if not os.access(loader, os.X_OK):
        raise SystemExit("cursor-environment: stamp claims loader but machorun is not executable")
empty_tbds = [p for p in sysroot.rglob("*.tbd") if p.is_file() and p.stat().st_size == 0]
if empty_tbds:
    raise SystemExit(f"cursor-environment: empty .tbd is a linker lie: {empty_tbds[0]}")
if not payload.get("tbdGenerated"):
    leftover = next(sysroot.rglob("*.tbd"), None)
    if leftover is not None:
        raise SystemExit(f"cursor-environment: .tbd present without loader CHECK 1: {leftover}")
for label in ("libSystem.B.dylib", "libobjc.A.dylib", "libquartz.dylib"):
    dylib = sysroot / "usr/lib" / label
    if not dylib.is_file():
        raise SystemExit(f"cursor-environment: sysroot_fe4 missing {label}")
PY
unavailable_count=$(grep -c '^CURSOR_ENV_CANNOT_' "$unavailable_log" || true)
finish_phase
products_ms=$elapsed_ms

swift_version=$(swiftc --version)
case "$swift_version" in
    *'Swift version 6.2.4'*'Target: '*'linux'*) ;;
    *) printf 'cursor-environment: unexpected Swift toolchain:\n%s\n' "$swift_version" >&2; exit 1 ;;
esac

printf 'import Foundation\nfunc probeFoundation() {\n    let value = Data([0x4f, 0x4b])\n    _ = value.count\n}\n' \
    | swiftc -parse-as-library -typecheck -module-name CursorEnvironmentProbe -
finish_phase
swift_ms=$elapsed_ms
finished_ns=$phase_ns
total_ms=$(( (finished_ns - started_ns) / 1000000 ))

fingerprint_tool=$repo_root/.cursor/toolchain-fingerprint.sh
[ -f "$fingerprint_tool" ] && [ ! -L "$fingerprint_tool" ] \
    || { printf 'cursor-environment: fingerprint tool is missing\n' >&2; exit 1; }
fingerprint_text=$(bash "$fingerprint_tool")
fingerprint_sha=$(printf '%s\n' "$fingerprint_text" | sha256sum | awk '{print $1}')
stamp=$repo_root/scratch/.cursor-env-attestation.json
python3 - "$stamp" "$fingerprint_sha" "$fingerprint_text" <<'PY'
import json, sys
from pathlib import Path
stamp, sha, text = sys.argv[1], sys.argv[2], sys.argv[3]
payload = {
    "fingerprintSha256": sha,
    "fingerprint": text,
    "pinnedImageDigest": "sha256:29b983751c605c2d3102d2ab93438c6e0cadf110d9d2aa6e929b6dec9dcb7cbc",
    "swiftEnvironmentOk": True,
}
Path(stamp).write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
PY

can_execute=0
host_arch=$(uname -m)
loader_built=$(jq -r '.loaderBuilt | tostring' "$products_manifest")
tbd_generated=$(jq -r '.tbdGenerated | tostring' "$products_manifest")
file_count=$(jq -r '.files | length | tostring' "$products_manifest")
product_arch=$(jq -r '.arch // empty' "$products_manifest")
if [ "$host_arch" = aarch64 ] || [ "$host_arch" = arm64 ]; then
    can_execute=1
elif [ "$host_arch" = x86_64 ] && [ "$loader_built" = true ]; then
    can_execute=1
fi

printf 'CURSOR_TOOLCHAIN_INVENTORY_OK swift=swift,swiftc clang=clang,clang++,clang-18,clang++-18 linker=ld64.lld,ld64.lld-18 llvm=llvm-nm,llvm-nm-18,llvm-otool,llvm-otool-18,llvm-objdump,llvm-objdump-18 utilities=perl,patch,jq,sha256sum,shasum,cmp,file,git,python3,pkg-config\n'
printf 'CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=scratch-corpus evidence=dotnet-macios\n'
printf 'CURSOR_SCRATCH_CORPUS_VERIFIED sources=%s/%s\n' "$corpus_ok" "$corpus_count"
printf 'CURSOR_BUILT_PRODUCTS_VERIFIED files=%s sysroot_fe4=tree mrroot_full=tree loader=%s tbd=%s arch=%s\n' \
    "$file_count" "$loader_built" "$tbd_generated" "${product_arch:-unknown}"
printf 'CURSOR_ENV_PROOF_SPLIT compile_link_static=in-vm execution=host-arch macos_oracle=local-only\n'
sysroot_surface=sysroot-headers+dylibs+swiftcore-module
if [ "$tbd_generated" = true ]; then
    sysroot_surface=sysroot-headers+tbd+dylibs+swiftcore-module
fi

phase2_ms=0
if [ "$host_arch" = x86_64 ] && [ "$can_execute" -eq 1 ]; then
    printf 'CURSOR_ENV_CAN_EXECUTE arch=x86_64 loader=%s\n' \
        "$(sha256sum "$repo_root/machorun/build/machorun" | awk '{print substr($1,1,12)}')"

    fixtures_bin=$repo_root/machorun/tests/bin-x86_64
    [ -s "$fixtures_bin/.built_count" ] \
        || { printf 'cursor-environment: missing x86 fixtures at %s\n' "$fixtures_bin" >&2; exit 1; }
    fixtures_built=$(tr -d '[:space:]' < "$fixtures_bin/.built_count")
    [ "$fixtures_built" -gt 0 ] \
        || { printf 'cursor-environment: x86 fixtures built=0\n' >&2; exit 1; }
    printf 'CURSOR_ENV_X86_FIXTURES_OK built=%s out=%s\n' "$fixtures_built" "$fixtures_bin"

    ud=$repo_root/scratch/ud-guest-x86_64
    [ -d "$ud/cfobjc/obj" ] && ls "$ud/cfobjc/obj"/*.o >/dev/null 2>&1 \
        || { printf 'cursor-environment: missing %s/cfobjc/obj\n' "$ud" >&2; exit 1; }
    [ -f "$ud/lib/libCFTest.dylib" ] \
        || { printf 'cursor-environment: missing %s/lib/libCFTest.dylib\n' "$ud" >&2; exit 1; }
    [ -x "$ud/bin/ud_guest" ] \
        || { printf 'cursor-environment: missing %s/bin/ud_guest\n' "$ud" >&2; exit 1; }
    [ -x "$ud/bin/ud_score_guest" ] \
        || { printf 'cursor-environment: missing %s/bin/ud_score_guest\n' "$ud" >&2; exit 1; }
    [ -d "$repo_root/scratch/mrroot_full-x86_64" ] \
        || { printf 'cursor-environment: missing scratch/mrroot_full-x86_64\n' >&2; exit 1; }
    printf 'CURSOR_ENV_UD_PRODUCTS_OK cfobjc_obj=1 libCFTest=1 ud_guest=1 ud_score_guest=1 mrroot_full-x86_64=1\n'

    echo "== phase2 rung a (PHASE2_RUNGS=a; expected stamp reuse after install)"
    phase2_start_ns=$(date +%s%N)
    set +e
    PHASE2_RUNGS=a bash "$repo_root/scripts/x86/phase2.sh" "$repo_root" \
        > "$repo_root/scratch/phase2-verify-rung-a.log" 2>&1
    phase2_rc=$?
    set -e
    cat "$repo_root/scratch/phase2-verify-rung-a.log"
    phase2_ms=$(( ( $(date +%s%N) - phase2_start_ns ) / 1000000 ))
    grep -E 'ENV_PREPARE_SUMMARY|RUNG_SCOREBOARD|GUEST SCOREBOARD|CANNOT_|reused=1 stamp=' \
        "$repo_root/scratch/phase2-verify-rung-a.log" || true
    reuse_n=$(grep -c 'reused=1 stamp=' "$repo_root/scratch/phase2-verify-rung-a.log" || true)
    printf 'CURSOR_ENV_PHASE2_REUSE_LINES=%s rc=%s\n' "$reuse_n" "$phase2_rc"
    [ "$reuse_n" -ge 1 ] \
        || { printf 'cursor-environment: PHASE2_RUNGS=a rerun had no reused=1 stamp= lines\n' >&2; exit 1; }
    if [ "$phase2_rc" -ne 0 ] && [ "$phase2_rc" -ne 2 ]; then
        printf 'cursor-environment: phase2 rung a failed rc=%s (scoreboard quoted above)\n' \
            "$phase2_rc" >&2
        exit 1
    fi
    if grep -q '^RUNG_SCOREBOARD a=PASS' "$repo_root/scratch/phase2-verify-rung-a.log"; then
        printf 'CURSOR_ENV_RUNG_A=PASS\n'
        if [ "$phase2_rc" -ne 0 ]; then
            printf 'cursor-environment: rung a PASS but phase2 rc=%s\n' "$phase2_rc" >&2
            exit 1
        fi
    elif grep -q '^RUNG_SCOREBOARD a=CANNOT' "$repo_root/scratch/phase2-verify-rung-a.log"; then
        printf 'CURSOR_ENV_RUNG_A=CANNOT (compile products present; scoreboard quoted above)\n'
    else
        printf 'cursor-environment: phase2 rung a did not print RUNG_SCOREBOARD a=PASS|CANNOT\n' >&2
        exit 1
    fi
fi

printf 'CURSOR_ENV_OK=1 arch=%s fixtures=%s ud_products=1\n' \
    "$host_arch" "${fixtures_built:-n/a}"
printf 'CURSOR_ENV_SUMMARY can=toolchain,corpus-pins[%s/%s],%s-macho-emit,%s,darwin-userland-dylibs cannot=arm64-macho-execute-on-%s,simruntime-overlay-dylibs,opencombine-export,modcache-swiftui-guest,macos-oracle unavailable=%s fingerprint=%s\n' \
    "$corpus_ok" "$corpus_count" "$host_arch" "$sysroot_surface" "$host_arch" "$unavailable_count" "$fingerprint_sha"
if [ "$host_arch" != aarch64 ] && [ "$host_arch" != arm64 ]; then
    printf 'CURSOR_ENV_CANNOT_EXECUTE_ARM64_MACHO host=%s needed=arm64 can_execute_x86_64=%s split=compile-link-static-in-vm/execution-host-arch/macos-oracle-local-only\n' \
        "$host_arch" "$can_execute"
fi
printf 'CURSOR_ENVIRONMENT_METRICS total_ms=%d cleanup_ms=%d tools_ms=%d evidence_ms=%d corpus_ms=%d products_ms=%d swift_ms=%d phase2_ms=%d\n' \
    "$total_ms" "$cleanup_ms" "$tools_ms" "$evidence_ms" "$corpus_ms" "$products_ms" "$swift_ms" "$phase2_ms"
