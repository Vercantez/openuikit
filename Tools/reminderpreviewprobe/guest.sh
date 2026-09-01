#!/bin/zsh
# Cold end-to-end proof for the untouched 22-source Reminder application.
# This script owns only the Preview host/target artifact preparation and
# composes the canonical support core-package and application drivers.

set -euo pipefail
umask 077

candidate_root=${0:A:h:h:h}
if (( $# != 5 )); then
  print -u2 -- "usage: $0 <pinned-swift-macho-linux> <staged-input-root> <pinned-machorun> <pinned-reminder-repo> <project-inventory.json>"
  exit 2
fi
support_root=${1:A}
staged_input_root=${2:A}
machorun_root=${3:A}
reminder_root=${4:A}
inventory=${5:A}

base_commit=83fbcbe2204eb836968d4e73ecfecec7b20c68ef
support_commit=39643c4cf824f5ef6b62eb1d24c253e7290c0e50
support_tree=3bf0334c0dd264ec07e77d7b33aff10436be812d
machorun_commit=e6b1745bef09ac8f1e2d6e6c83f7c70d6dbe49a5
machorun_tree=1b41ede32d9a3ba2a5ec2d37685dc64b4eee9b43
reminder_commit=2edfc88c386b8dec1683339f58e05054c5e9ce1f
reminder_tree=66474f2d47cc80ee551da990d748ddcc1b32aa1b
inventory_sha256=2e099b5f7b67e7f48deb9bc59219d2fede6cd138daf00a3e2f7d078822006e2b
plan_sha256=9d8f727b088a93514342aca4f056df8add9dcb40823bd526439f8301c6515cca
bootstrap_sha256=224c87feb842c5a7bced67f6ce6a4fd1512f458f6b61090e3f11db754f424859
source_list_sha256=964801e9db1d7e690d0bdce18c5993e23879b7f2cb3a8d2fb055108b66fd0e01
prepared_inputs_sha256=0d100cac034975110e64b5c162cbc88debf178d3c6002498b7cde940e0291df8
swift_syntax_revision=4799286537280063c85a32f09884cfbca301b1a1
swift_syntax_tree=4c96b84ec6f59391ca70d18191500c14854d3d91
swiftc_sha256=5a7209655c37a4f4937ea5219a4af59a7c9fc52dd13c615f26682642bc3a83ff
image=${SWIFT_MACHO_IMAGE:-swift-macho-spike:noble}
image_id=sha256:85f9d4c5089ef811c53c55be5e8683f0f582cc9b158f9d9c5348331f3dec4044
container_name=openuikit-reminder-preview-artifacts

die() { print -u2 -- "reminderpreviewguest: $*"; exit 2; }
hash_file() { shasum -a 256 "$1" | awk '{print $1}'; }

assert_clean_commit() {
  local repo=$1 expected_commit=$2 expected_tree=$3 label=$4
  [[ -d $repo/.git ]] || die "$label is not a Git checkout: $repo"
  [[ $(git -C $repo rev-parse --verify HEAD^{commit}) == $expected_commit ]] \
    || die "$label commit drifted"
  [[ $(git -C $repo rev-parse --verify HEAD^{tree}) == $expected_tree ]] \
    || die "$label tree drifted"
  [[ -z $(git -C $repo status --porcelain=v1 --untracked-files=all) ]] \
    || die "$label checkout is not clean"
}

for tool in docker git python3 shasum file cmp find awk tee; do
  command -v $tool >/dev/null || die "required host tool is missing: $tool"
done
for directory in $candidate_root $support_root $staged_input_root \
    $machorun_root $reminder_root; do
  [[ -d $directory && ! -L $directory ]] \
    || die "input is not a real directory: $directory"
done
[[ -f $inventory && ! -L $inventory ]] \
  || die "inventory is not a regular file: $inventory"
[[ $(hash_file $inventory) == $inventory_sha256 ]] \
  || die "Reminder inventory hash drifted"

candidate_head=$(git -C $candidate_root rev-parse --verify HEAD^{commit})
candidate_tree=$(git -C $candidate_root rev-parse --verify HEAD^{tree})
[[ $(git -C $candidate_root show -s --format=%P HEAD) == $base_commit ]] \
  || die "candidate does not have the exact Preview base as its sole parent"
[[ $(git -C $candidate_root rev-list --count $base_commit..HEAD) == 1 ]] \
  || die "candidate is not exactly one commit beyond the Preview base"
[[ -z $(git -C $candidate_root status --porcelain=v1 --untracked-files=all) ]] \
  || die "candidate must be committed and clean"

expected_paths=$'Package.swift\nSources/DeveloperToolsSupport/Preview.swift\nSources/OpenUIKitPreviewMacros/OpenUIKitPreviewMacrosPlugin.swift\nSources/OpenUIKitPreviewMacros/UIKitPreviewMacro.swift\nSources/UIKitShim/UIKit.swift\nTHIRD_PARTY_LICENSES/OpenSwiftUI.txt\nTools/previewprobe/Fixture/Package.swift\nTools/previewprobe/Fixture/Sources/BodyNegative/BodyNegative.swift\nTools/previewprobe/Fixture/Sources/NamedNegative/NamedNegative.swift\nTools/previewprobe/Fixture/Sources/PreviewClient/Client.swift\nTools/previewprobe/Fixture/Sources/PreviewRuntime/Runtime.swift\nTools/previewprobe/Fixture/Sources/SPINegative/SPINegative.swift\nTools/previewprobe/expected.txt\nTools/previewprobe/run.sh\nTools/reminderpreviewprobe/EntryPointShim.swift\nTools/reminderpreviewprobe/guest.sh\nTools/reminderpreviewprobe/run.py\ndocs/APP_COMPAT.md\ndocs/ARCHITECTURE.md\ndocs/KNOWN_GAPS.md\ndocs/PORTABILITY.md\ndocs/PREVIEW.md\ndocs/ROADMAP.md'
actual_paths=$(git -C $candidate_root diff --name-only $base_commit..HEAD \
  | LC_ALL=C sort)
[[ $actual_paths == $expected_paths ]] \
  || die "candidate changed-path boundary drifted"

assert_clean_commit $support_root $support_commit $support_tree support
assert_clean_commit $machorun_root $machorun_commit $machorun_tree machorun
assert_clean_commit $reminder_root $reminder_commit $reminder_tree Reminder
[[ -d $reminder_root/Reminder && ! -L $reminder_root/Reminder ]] \
  || die "Reminder project root is missing"
for relative in sysroot_fe4 mrroot mrroot_fe swift-foundation \
    swift-collections opencombine-core-durable-20260828-r2; do
  [[ -d $staged_input_root/$relative && ! -L $staged_input_root/$relative ]] \
    || die "staged input is missing or a symlink: $relative"
done
[[ -x $support_root/full/frameworks/run_core_guest_package_docker.sh ]] \
  || die "canonical core-package host wrapper is missing"
[[ -x $support_root/full/xcodeplan/build_portable_application_guest.sh ]] \
  || die "canonical application driver is missing"

python3 -B $candidate_root/Tools/reminderpreviewprobe/run.py \
  --static-candidate --reminder $reminder_root \
  --candidate-uikit $candidate_root

docker info >/dev/null
[[ $(docker image inspect --format '{{.Id}}' $image) == $image_id ]] \
  || die "Docker image drifted"
[[ -z $(docker ps -aq --filter name=^/$container_name$) ]] \
  || die "reserved Preview artifact container name is already in use"

output_root=$(mktemp -d /private/tmp/reminder-preview-guest.XXXXXX)
[[ $output_root == /private/tmp/reminder-preview-guest.* ]] \
  || die "unexpected temporary output path"
keep=${REMINDER_PREVIEW_GUEST_KEEP_OUTPUT:-0}
success=0
cleanup() {
  docker rm -f $container_name >/dev/null 2>&1 || true
  if [[ $keep == 1 ]]; then
    print -u2 -- "REMINDER_PREVIEW_GUEST_OUTPUT=$output_root"
  else
    rm -rf -- $output_root
  fi
}
trap cleanup EXIT

mkdir $output_root/prebuild
docker run --rm --platform linux/arm64 --name $container_name \
  -e EXPECTED_SWIFT_SYNTAX_REVISION=$swift_syntax_revision \
  -e EXPECTED_SWIFT_SYNTAX_TREE=$swift_syntax_tree \
  -e EXPECTED_SWIFTC_SHA256=$swiftc_sha256 \
  -v $candidate_root:/uikit:ro \
  -v $staged_input_root/sysroot_fe4:/target-sdk:ro \
  -v $output_root/prebuild:/out:rw \
  -w /out $image_id bash -lc '
set -euo pipefail
die() { echo "preview-artifacts: $*" >&2; exit 2; }
hash_file() { sha256sum "$1" | awk "{print \$1}"; }
for tool in swift swiftc git cp file readelf llvm-otool-18 sha256sum; do
  command -v "$tool" >/dev/null || die "required tool is missing: $tool"
done
swiftc --version > /out/swift-version.txt
grep -Fx "Swift version 6.2.4 (swift-6.2.4-RELEASE)" \
  /out/swift-version.txt >/dev/null
grep -Fx "Target: aarch64-unknown-linux-gnu" \
  /out/swift-version.txt >/dev/null
[[ "$(hash_file "$(command -v swiftc)")" == $EXPECTED_SWIFTC_SHA256 ]] \
  || die "swiftc bytes drifted"

cp -R /uikit/Tools/previewprobe/Fixture /out/fixture
OPENUIKIT_PREVIEW_ROOT=/uikit swift build \
  --package-path /out/fixture --scratch-path /out/plugin-build \
  --target PreviewClient --disable-index-store -Xswiftc -gnone \
  > /out/plugin-build.stdout 2> /out/plugin-build.stderr
bin_path=$(OPENUIKIT_PREVIEW_ROOT=/uikit swift build \
  --package-path /out/fixture --scratch-path /out/plugin-build \
  --show-bin-path | tail -1)
plugin=$bin_path/OpenUIKitPreviewMacros-tool
[[ -x $plugin ]] || die "Linux-host Preview macro plugin is missing"
syntax=/out/plugin-build/checkouts/swift-syntax
[[ $(git -C $syntax rev-parse --verify HEAD^{commit}) \
  == $EXPECTED_SWIFT_SYNTAX_REVISION ]] \
  || die "resolved SwiftSyntax revision drifted"
[[ $(git -C $syntax rev-parse --verify HEAD^{tree}) \
  == $EXPECTED_SWIFT_SYNTAX_TREE ]] \
  || die "resolved SwiftSyntax tree drifted"
[[ -z $(git -C $syntax status --porcelain=v1 --untracked-files=all) ]] \
  || die "resolved SwiftSyntax checkout is dirty"
cp /out/fixture/Package.resolved /out/plugin-Package.resolved
cp $plugin /out/OpenUIKitPreviewMacros-tool
chmod 0755 /out/OpenUIKitPreviewMacros-tool
file /out/OpenUIKitPreviewMacros-tool > /out/plugin.file.txt
grep -Eq "ELF 64-bit.*(ARM aarch64|aarch64)" /out/plugin.file.txt \
  || die "host plugin is not Linux aarch64 ELF"
readelf -h /out/OpenUIKitPreviewMacros-tool > /out/plugin.elf-header.txt
grep -Eq "Machine:[[:space:]]+AArch64" /out/plugin.elf-header.txt \
  || die "host plugin ELF machine drifted"

mkdir /out/dts-module-cache
swiftc -target arm64-apple-macos15.0 -sdk /target-sdk \
  -module-cache-path /out/dts-module-cache \
  -runtime-compatibility-version none -wmo -parse-as-library \
  -Xfrontend -disable-implicit-string-processing-module-import \
  -module-name DeveloperToolsSupport \
  -emit-module -emit-module-path /out/DeveloperToolsSupport.swiftmodule \
  -emit-object -o /out/developertoolsupport.o \
  /uikit/Sources/DeveloperToolsSupport/Preview.swift \
  > /out/dts-build.stdout 2> /out/dts-build.stderr
[[ ! -s /out/dts-build.stdout && ! -s /out/dts-build.stderr ]] \
  || die "DeveloperToolsSupport target compile emitted output"
file /out/developertoolsupport.o > /out/dts-object.file.txt
grep -F "Mach-O 64-bit arm64 object" /out/dts-object.file.txt >/dev/null \
  || die "DeveloperToolsSupport object is not ARM64 Mach-O"
llvm-otool-18 -hv /out/developertoolsupport.o \
  > /out/dts-object.macho-header.txt
grep -Eq "MH_MAGIC_64[[:space:]]+ARM64.*[[:space:]]OBJECT" \
  /out/dts-object.macho-header.txt \
  || die "DeveloperToolsSupport Mach-O header drifted"
{
  printf "format\tpreview-artifacts-v1\n"
  printf "swiftc\t%s\n" "$(hash_file "$(command -v swiftc)")"
  printf "swift-syntax\tcommit=%s\ttree=%s\n" \
    "$EXPECTED_SWIFT_SYNTAX_REVISION" "$EXPECTED_SWIFT_SYNTAX_TREE"
  printf "plugin\t%s\n" "$(hash_file /out/OpenUIKitPreviewMacros-tool)"
  printf "dts-module\t%s\n" "$(hash_file /out/DeveloperToolsSupport.swiftmodule)"
  printf "dts-object\t%s\n" "$(hash_file /out/developertoolsupport.o)"
} > /out/artifacts.tsv
' 2>&1 | tee $output_root/prebuild.log

plugin=$output_root/prebuild/OpenUIKitPreviewMacros-tool
dts_module=$output_root/prebuild/DeveloperToolsSupport.swiftmodule
dts_object=$output_root/prebuild/developertoolsupport.o
for artifact in $plugin $dts_module $dts_object; do
  [[ -f $artifact && ! -L $artifact ]] \
    || die "prepared Preview artifact is missing: $artifact"
done
plugin_sha=$(hash_file $plugin)
dts_module_sha=$(hash_file $dts_module)
dts_object_sha=$(hash_file $dts_object)

core_package=$output_root/core-package
IMAGE=$image_id \
  $support_root/full/frameworks/run_core_guest_package_docker.sh \
  --support-checkout $support_root \
  --expected-support-commit $support_commit \
  --expected-support-tree $support_tree \
  --staged-input-root $staged_input_root \
  --uikit-checkout $candidate_root \
  --expected-uikit-commit $candidate_head \
  --expected-uikit-tree $candidate_tree \
  --machorun-checkout $machorun_root \
  --output-root $core_package \
  --developer-tools-support-module $dts_module \
  --developer-tools-support-object $dts_object \
  --preview-macro-plugin $plugin \
  2>&1 | tee $output_root/core-package.log

application=$output_root/application
$support_root/full/xcodeplan/build_portable_application_guest.sh \
  --inventory $inventory \
  --source-root $reminder_root/Reminder \
  --platform-package $core_package \
  --preview-plugin $plugin \
  --output-root $application \
  2>&1 | tee $output_root/application.log

[[ $(hash_file $application/application-build-plan.json) == $plan_sha256 ]] \
  || die "application plan hash drifted"
[[ $(hash_file $application/GeneratedSceneBootstrap.swift) == $bootstrap_sha256 ]] \
  || die "generated scene bootstrap hash drifted"
[[ $(hash_file $application/app-sources.nul) == $source_list_sha256 ]] \
  || die "ordered source list hash drifted"
[[ $(hash_file $application/prepared-inputs.json) == $prepared_inputs_sha256 ]] \
  || die "prepared application inputs hash drifted"
[[ $(tr -cd '\0' < $application/app-sources.nul | wc -c | tr -d '[:space:]') == 22 ]] \
  || die "application source count drifted"

python3 - $application/app-macro-expansions.stderr <<'PY'
from pathlib import Path
import re
import sys

text = Path(sys.argv[1]).read_text(encoding="utf-8")
if re.search(r"^.+:\d+:\d+:\s+(?:error|warning):", text, re.MULTILINE):
    raise SystemExit("application emitted a source diagnostic")
required = (
    '"Reminder/CreateViewController.swift"',
    "static var line: Int {\n        355\n    }",
    "static var column: Int {\n        1\n    }",
    ": DeveloperToolsSupport.PreviewRegistry",
    "static func makePreview() throws -> DeveloperToolsSupport.Preview",
    "DeveloperToolsSupport.Preview(body: {",
    "return __b_buildContent {",
    "CreateViewController(initialDate: Date())",
)
for spelling in required:
    if spelling not in text:
        raise SystemExit(f"Reminder Preview expansion drifted: {spelling!r}")
if text.count("DeveloperToolsSupport.PreviewRegistry") != 1:
    raise SystemExit("Reminder must emit exactly one PreviewRegistry")
if text.count("CreateViewController(initialDate: Date())") != 1:
    raise SystemExit("Reminder Preview body count drifted")
print("REMINDER_PREVIEW_EXPANSION_OK registry=1 line=355 column=1")
PY

[[ $(grep -c $'^app_object\t' $application/application-link-objects.tsv) == 1 ]] \
  || die "application object link record drifted"
[[ $(grep -c $'^developer_tools_support_object\t' \
  $application/application-link-objects.tsv) == 1 ]] \
  || die "DeveloperToolsSupport must be linked exactly once"
[[ $(wc -l < $application/application-link-objects.tsv | tr -d '[:space:]') == 2 ]] \
  || die "application link-object ledger contains an extra object"
grep -F $'developer_tools_support_object\t'$dts_object_sha$'\t' \
  $application/application-link-objects.tsv >/dev/null \
  || die "linked DeveloperToolsSupport object hash drifted"

PYTHONPATH=$support_root/full/xcodeplan python3 - \
  $core_package $plugin $dts_module_sha $dts_object_sha $plugin_sha <<'PY'
from pathlib import Path
import core_guest_package
import json
import sys

root, _manifest = core_guest_package.validate(Path(sys.argv[1]))
document = json.loads(
    (root / "attestation/core-package.json").read_text(encoding="utf-8")
)
preview = document.get("preview")
if not isinstance(preview, dict):
    raise SystemExit("core package has no Preview contract")
if preview["plugin_sha256"] != sys.argv[5]:
    raise SystemExit("core package plugin identity drifted")
if preview["developer_tools_support_object_sha256"] != sys.argv[4]:
    raise SystemExit("core package DTS object identity drifted")
module = preview["developer_tools_support_module"]
if module["sha256"] != sys.argv[3]:
    raise SystemExit("core package DTS module identity drifted")
print("REMINDER_PREVIEW_CORE_IDENTITY_OK")
PY

[[ -z $(find $core_package -type f \
  \( -name OpenUIKitPreviewMacros-tool -o -name 'SwiftSyntax*' \) -print) ]] \
  || die "core package contains host-only plugin/SwiftSyntax artifacts"
[[ -z $(find $application/Reminder.app -type f \
  \( -name OpenUIKitPreviewMacros-tool -o -name developertoolsupport.o \
     -o -name 'SwiftSyntax*' \) -print) ]] \
  || die "application bundle contains build-host or loose DTS artifacts"
file $plugin $dts_object $application/application.o \
  $application/Reminder.app/Contents/MacOS/Reminder \
  > $output_root/final-files.txt
grep -Eq "OpenUIKitPreviewMacros-tool:.*ELF 64-bit.*(ARM aarch64|aarch64)" \
  $output_root/final-files.txt || die "final plugin format drifted"
grep -F "developertoolsupport.o: Mach-O 64-bit arm64 object" \
  $output_root/final-files.txt >/dev/null || die "final DTS object format drifted"
grep -F "application.o: Mach-O 64-bit arm64 object" \
  $output_root/final-files.txt >/dev/null || die "application object format drifted"
grep -F "Reminder: Mach-O 64-bit executable arm64" \
  $output_root/final-files.txt >/dev/null || die "application executable format drifted"
grep -F "CORE_GUEST_PACKAGE_MACHO_OK notification=shared combine=delivered resources=loaded fonts=system,bold preview=enabled" \
  $core_package/attestation/runtime.log >/dev/null \
  || die "core Preview runtime marker is missing"
grep -Fx "PORTABLE_UIKIT_HOST_ACTIVE windows=1" \
  $application/runtime.log >/dev/null \
  || die "packaged Reminder did not activate one window"
grep -Fx "PORTABLE_UIKIT_HOST_LOOP_OK turns=3 paced=true" \
  $application/runtime.log >/dev/null \
  || die "packaged Reminder did not complete three paced turns"

assert_clean_commit $candidate_root $candidate_head $candidate_tree post-candidate
assert_clean_commit $support_root $support_commit $support_tree post-support
assert_clean_commit $machorun_root $machorun_commit $machorun_tree post-machorun
assert_clean_commit $reminder_root $reminder_commit $reminder_tree post-Reminder
[[ $(hash_file $inventory) == $inventory_sha256 ]] \
  || die "Reminder inventory changed during the gate"
[[ $(hash_file $plugin) == $plugin_sha \
   && $(hash_file $dts_module) == $dts_module_sha \
   && $(hash_file $dts_object) == $dts_object_sha ]] \
  || die "prepared Preview artifacts changed during the gate"
[[ $(docker image inspect --format '{{.Id}}' $image) == $image_id ]] \
  || die "Docker image changed during the gate"
[[ ! -e $candidate_root/.build && ! -e $candidate_root/Package.resolved ]] \
  || die "gate left build/resolution residue in the candidate"

(
  cd $output_root
  shasum -a 256 prebuild/artifacts.tsv prebuild/plugin-Package.resolved \
    prebuild.log core-package.log application.log final-files.txt \
    core-package/attestation/core-package.json \
    application/application-build-plan.json \
    application/app-macro-expansions.stderr \
    application/application-build-artifacts.sha256 \
    application/runtime.log > guest-evidence.sha256
)

# The fresh SwiftPM checkout and object cache are build intermediates, not
# evidence inputs. Remove them only after every consumer and post-bracket has
# succeeded; the copied plugin, resolution record, logs and hashes remain.
rm -rf -- $output_root/prebuild/plugin-build \
  $output_root/prebuild/fixture $output_root/prebuild/dts-module-cache
success=1
print -- "candidate_commit=$candidate_head"
print -- "candidate_tree=$candidate_tree"
print -- "support_commit=$support_commit"
print -- "support_tree=$support_tree"
print -- "preview_plugin_sha256=$plugin_sha"
print -- "developer_tools_support_module_sha256=$dts_module_sha"
print -- "developer_tools_support_object_sha256=$dts_object_sha"
print -- "sources=22 resources=2 app_edits=0 diagnostics=1->0"
print -- "package=Reminder.app host_turns=3"
print -- "REMINDER_PREVIEW_GUEST_OK"
