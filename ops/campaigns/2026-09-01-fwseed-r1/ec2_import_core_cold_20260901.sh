#!/usr/bin/env bash
set -euo pipefail

work_root=/opt/openuikit/transfers/core-cold-20260901
archive=$work_root/openuikit-core-cold-transfer-20260901.tar.zst
extract_root=$work_root/extracted
target=/opt/openuikit/core-cold/baseline-r22-20260901
evidence=/var/lib/openuikit/audits/core-cold-r22-20260901/import

expected_archive_sha=${EXPECTED_ARCHIVE_SHA:?EXPECTED_ARCHIVE_SHA is required}
expected_payload_manifest_sha=411564985c20d661746ef82593ac627e49e0afd928b68b2a551758bad605be43
expected_symlink_mode_translations=17
expected_support_commit=d2f98a9ced0c9130b606e035cc912008ab5f8760
expected_support_tree=474f5cba39d79c219da8dfd1c0f04dd4c033b251
expected_uikit_commit=0315f997eba28e87f3d12e8590b2a19bdb2ce06d
expected_uikit_tree=ebc52d14509398e659b592eff7e520c284fc5e9f
expected_machorun_commit=edb99a8574255ddc4c979b2f0cf2615033ff14fd
expected_machorun_tree=19b2308f300ef4006acf526e599fad9265e7664c
expected_support_bundle_sha=0076bb7c1124959c68c6d82c47a83f2cd6809ad0975680dbd80dae889c31fc69
expected_uikit_bundle_sha=e5aecf630d49c1ebbc674ec535b25b5b234e21a0e564f6b718ce1e3caa6843f9
expected_machorun_bundle_sha=8fa6197b65e3309a1a3b3ee1afdc1c911294918d4e55bf963165657bee1c38b6
expected_loader_sha=7a56841c97ee0de74815d940d9f56447e6e658f6a80031dac9d3c52164a0204f
expected_swift_core_sha=dd01686e06c81a21755bb864b43dad446c011e6c60c6b387b3b332c0a12708cb
expected_objc_sha=9b5ca00ca17e8bd030f75c32ffe651dfe4c29a90ad57115e69c6d5b7eea5950c

target_ready=0
quarantine_failure() {
    status=$?
    trap - EXIT
    if [ "$target_ready" -ne 1 ] && [ -d "$target" ] && [ ! -L "$target" ]; then
        invalid=${target}.INVALID-DO-NOT-USE
        if [ -e "$invalid" ] || [ -L "$invalid" ]; then
            invalid=${invalid}.$(date -u +%Y%m%dT%H%M%SZ)
        fi
        mv -- "$target" "$invalid"
        printf 'EC2_CORE_IMPORT_QUARANTINED path=%s\n' "$invalid" >&2
    fi
    exit "$status"
}
trap quarantine_failure EXIT

for tool in cmp git python3 sha256sum tar zstd; do
    command -v "$tool" >/dev/null
done
test ! -e "$target"
test ! -L "$target"
test ! -e "$extract_root"
test ! -L "$extract_root"
install -d -m 0755 "$work_root" "$(dirname "$target")" "$evidence"

test -f "$archive"
test ! -L "$archive"
printf '%s  %s\n' "$expected_archive_sha" "$archive" | sha256sum -c -
zstd -t "$archive"

install -d -m 0755 "$extract_root"
tar --no-same-owner -xpf "$archive" -C "$extract_root"
printf '%s  %s\n' "$expected_payload_manifest_sha" \
    "$extract_root/payload-manifest.jsonl" | sha256sum -c -

support_bundle=$extract_root/payload/bundles/support.bundle
uikit_bundle=$extract_root/payload/bundles/uikit.bundle
machorun_bundle=$extract_root/payload/bundles/machorun.bundle
printf '%s  %s\n' "$expected_support_bundle_sha" "$support_bundle" | sha256sum -c -
printf '%s  %s\n' "$expected_uikit_bundle_sha" "$uikit_bundle" | sha256sum -c -
printf '%s  %s\n' "$expected_machorun_bundle_sha" "$machorun_bundle" | sha256sum -c -

install -d -m 0755 "$target"
git clone --quiet "$support_bundle" "$target/support"
git clone --quiet "$uikit_bundle" "$target/uikit"
git clone --quiet "$machorun_bundle" "$target/machorun"
physical_replay=$target/support/full/frameworks/physical_replay.py
test -f "$physical_replay"
test ! -L "$physical_replay"

verify_checkout() {
    checkout=$1
    expected_commit=$2
    expected_tree=$3
    label=$4
    actual_commit=$(git -C "$checkout" rev-parse --verify HEAD^{commit})
    actual_tree=$(git -C "$checkout" rev-parse --verify HEAD^{tree})
    status=$(git -C "$checkout" status --porcelain=v1 --untracked-files=all)
    test "$actual_commit" = "$expected_commit"
    test "$actual_tree" = "$expected_tree"
    test -z "$status"
    printf 'checkout\t%s\tcommit=%s\ttree=%s\n' \
        "$label" "$actual_commit" "$actual_tree"
}

python3 -B "$physical_replay" snapshot \
    --root "$extract_root/payload" \
    --output "$work_root/payload-manifest.remote.jsonl"
python3 -B - \
    "$extract_root/payload-manifest.jsonl" \
    "$work_root/payload-manifest.remote.jsonl" \
    "$expected_symlink_mode_translations" <<'PY'
import itertools
import json
import sys

local_path, remote_path, expected_text = sys.argv[1:]
expected = int(expected_text)
translations = 0
entries = 0
with open(local_path, encoding="utf-8") as local_file, open(
    remote_path, encoding="utf-8"
) as remote_file:
    for line_number, pair in enumerate(
        itertools.zip_longest(local_file, remote_file), start=1
    ):
        local_line, remote_line = pair
        if local_line is None or remote_line is None:
            raise SystemExit(f"manifest length differs at line {line_number}")
        local_record = json.loads(local_line)
        remote_record = json.loads(remote_line)
        entries += 1
        if local_record == remote_record:
            continue
        local_copy = dict(local_record)
        remote_copy = dict(remote_record)
        local_mode = local_copy.pop("mode", None)
        remote_mode = remote_copy.pop("mode", None)
        if (
            local_copy != remote_copy
            or local_copy.get("type") != "symlink"
            or local_mode != "0755"
            or remote_mode != "0777"
        ):
            raise SystemExit(f"payload manifest differs at line {line_number}")
        translations += 1
if translations != expected:
    raise SystemExit(
        f"symlink mode translation count {translations}, expected {expected}"
    )
print(
    f"TRANSFER_PAYLOAD_MANIFEST_OK entries={entries} "
    f"symlink_mode_translations={translations}"
)
PY

verify_checkout "$target/support" "$expected_support_commit" \
    "$expected_support_tree" support | tee "$evidence/source-identities.tsv"
verify_checkout "$target/uikit" "$expected_uikit_commit" \
    "$expected_uikit_tree" OpenUIKit | tee -a "$evidence/source-identities.tsv"
verify_checkout "$target/machorun" "$expected_machorun_commit" \
    "$expected_machorun_tree" machorun | tee -a "$evidence/source-identities.tsv"
git -C "$target/support" bundle verify "$support_bundle"
git -C "$target/uikit" bundle verify "$uikit_bundle"
git -C "$target/machorun" bundle verify "$machorun_bundle"

install -d -m 0755 "$target/machorun/build" "$target/machorun/darwin"
python3 -B "$physical_replay" copy-file \
    --source "$extract_root/payload/machorun-assets/build/machorun" \
    --destination "$target/machorun/build/machorun" \
    --label machorun-loader \
    --output "$evidence/copy-machorun-loader.json"
python3 -B "$physical_replay" copy-tree \
    --source "$extract_root/payload/machorun-assets/darwin/usr" \
    --destination "$target/machorun/darwin/usr" \
    --label machorun-runtime \
    --output "$evidence/copy-machorun-runtime.json"
printf '%s  %s\n' "$expected_loader_sha" "$target/machorun/build/machorun" \
    | sha256sum -c -
printf '%s  %s\n' "$expected_swift_core_sha" \
    "$target/machorun/darwin/usr/lib/swift/libswiftCore.dylib" | sha256sum -c -
printf '%s  %s\n' "$expected_objc_sha" \
    "$target/machorun/darwin/usr/lib/libobjc.A.dylib" | sha256sum -c -
verify_checkout "$target/machorun" "$expected_machorun_commit" \
    "$expected_machorun_tree" staged-machorun >> "$evidence/source-identities.tsv"

install -d -m 0755 "$target/inputs"
for relative in \
    sysroot_fe4 mrroot mrroot_fe swift-foundation swift-foundation-icu \
    swift-collections opencombine-core-durable-20260828-r2; do
    mv -- "$extract_root/payload/inputs/$relative" "$target/inputs/$relative"
done

install -m 0444 "$extract_root/payload-manifest.jsonl" \
    "$evidence/payload-manifest.local.jsonl"
install -m 0444 "$work_root/payload-manifest.remote.jsonl" \
    "$evidence/payload-manifest.remote.jsonl"
cp -a "$extract_root/payload/copy-reports/." "$evidence/"

{
    printf 'format\tcore-cold-import-v1\n'
    printf 'archive\tsha256=%s\n' "$expected_archive_sha"
    printf 'payload-manifest\tsha256=%s\tentries=%s\n' \
        "$expected_payload_manifest_sha" \
        "$(wc -l < "$extract_root/payload-manifest.jsonl")"
    printf 'symlink-mode-translation\tmacos-0755-to-linux-0777\tcount=%s\n' \
        "$expected_symlink_mode_translations"
    printf 'loader\tsha256=%s\n' "$expected_loader_sha"
    printf 'swift-core\tsha256=%s\n' "$expected_swift_core_sha"
    printf 'objc\tsha256=%s\n' "$expected_objc_sha"
    printf 'target\t%s\n' "$target"
} > "$evidence/import-provenance.tsv"

printf '%s\n' "$expected_archive_sha" > "$target/TRANSFER_ARCHIVE_SHA256"
printf '%s\n' "$expected_payload_manifest_sha" > "$target/PAYLOAD_MANIFEST_SHA256"
printf '%s\n' "$expected_support_commit" > "$target/SUPPORT_COMMIT"
printf '%s\n' "$expected_uikit_commit" > "$target/UIKIT_COMMIT"
printf '%s\n' "$expected_machorun_commit" > "$target/MACHORUN_COMMIT"
printf 'EC2_CORE_IMPORT_OK target=%s entries=%s\n' \
    "$target" "$(wc -l < "$extract_root/payload-manifest.jsonl")" \
    | tee "$target/READY"
target_ready=1

find "$extract_root" -depth -delete
find "$archive" -delete
find "$work_root/payload-manifest.remote.jsonl" -delete
trap - EXIT
