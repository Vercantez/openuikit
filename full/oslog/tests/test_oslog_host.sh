#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/../../.." && pwd)
REMOTE_CACHE=${1:-/private/tmp/icecubes-remote-cache-v3-20260831}
EXPANDED_GRAPH=${2:-/private/tmp/icecubes-c-family-proof-20260831.FASIwl/expanded-graph.json}
NUKE=$REMOTE_CACHE/objects/sha256/31/315e7c8887eb24506c2bed97c6b16f0bd2b85282a3e30d66e8d8ac2e44f09404/repository
BUTTONKIT=$REMOTE_CACHE/objects/sha256/5c/5c1869c1721b4d6875e028a73a2dd9bf40554677a49620123b58ecbf5ed9102b/repository
EMOJITEXT=$REMOTE_CACHE/objects/sha256/4e/4e8bb948530ed0763107bf2ac692d3a92e80aef501b18148cb65f87fa7ee4877/repository

EXPECTED_NUKE_COMMIT=30f7a7e72e0607d304fbf69c799474bd5fb6d1ce
EXPECTED_NUKE_LOG_SHA256=0e35bf6615af86e442d1cbc590939ad27a26f647ac10d7ada2c7164ee9d1afdd
EXPECTED_BUTTONKIT_COMMIT=8ea442e22cc396960aba246bf03d967842aeedb9
EXPECTED_BUTTONKIT_TRIGGER_SHA256=d8c160c3368dd9498483f48063d0dbaa70ac1469d9e266d298964e0e435f52f2
EXPECTED_EMOJITEXT_COMMIT=3b11459a19c9406176a08b0f0599b98f88113296
EXPECTED_EMOJITEXT_LOGGER_SHA256=6d97e6d0327daa65c03e0d5a33cfbc503eb1bb02e39722f163946d541e5c5d20
EXPECTED_GRAPH_SHA256=2fe70c06ce804451a5f6f4ba93251a5ecb4f094bbd482e753553ace0243ac592
FRONTIER_POLICY=$ROOT/full/oslog/tests/icecubes_oslog_frontier.tsv

[ "$(shasum -a 256 "$EXPANDED_GRAPH" | awk '{print $1}')" = \
    "$EXPECTED_GRAPH_SHA256" ] || {
    printf 'expanded graph drifted\n' >&2
    exit 2
}

# Recompute the complete OSLog/os import set from the exact expanded graph and
# its pinned remote materializations. The checked-in policy must be neither a
# sample nor a superset: every one of the 11 imports and hashes must agree.
python3 - "$EXPANDED_GRAPH" "$REMOTE_CACHE" "$FRONTIER_POLICY" <<'PY'
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys

graph_path, cache_path, policy_path = map(Path, sys.argv[1:])
graph = json.loads(graph_path.read_text(encoding="utf-8"))
materializations = {
    item["identity"]: item
    for item in graph["remote_materializations"]["packages"]
}
observed = []
repositories = set()
pattern = re.compile(r"^\s*import\s+(OSLog|os)\s*$", re.MULTILINE)
for target in graph["targets"]:
    package_path = target["package_path"]
    if not package_path.startswith("@remote/"):
        continue
    identity = package_path.split("/")[1]
    materialization = materializations[identity]
    repository_relative = materialization["repository_path"]
    repository = cache_path / repository_relative
    repositories.add((repository, materialization["commit"]))
    for source in target["sources"]:
        path = repository / source["path"]
        matches = sorted(set(pattern.findall(path.read_text(encoding="utf-8"))))
        for imported_module in matches:
            observed.append((
                identity,
                materialization["commit"],
                repository_relative,
                target["module"],
                source["path"],
                source["sha256"],
                imported_module,
            ))

expected = []
for line in policy_path.read_text(encoding="utf-8").splitlines():
    fields = line.split("\t")
    if fields[0] == "source":
        expected.append(tuple(fields[1:]))
if observed != expected:
    raise SystemExit(f"OSLog expanded-graph inventory drifted:\nobserved={observed!r}\nexpected={expected!r}")
if len(observed) != 11:
    raise SystemExit(f"OSLog expanded-graph source count {len(observed)}, expected 11")
for repository, commit in repositories:
    if subprocess.check_output(
        ["git", "-C", str(repository), "rev-parse", "HEAD"], text=True
    ).strip() != commit:
        raise SystemExit(f"remote materialization commit drifted: {repository}")
    if subprocess.check_output(
        ["git", "-C", str(repository), "status", "--short"], text=True
    ):
        raise SystemExit(f"remote materialization is not untouched: {repository}")
for record in expected:
    path = cache_path / record[2] / record[4]
    digest = hashlib.sha256(path.read_bytes()).hexdigest()
    if digest != record[5]:
        raise SystemExit(f"OSLog inventory source hash drifted: {path}")
PY

require_untouched_source() {
    local repository=$1 expected_commit=$2 relative=$3 expected_sha=$4 label=$5
    [ -d "$repository/.git" ] || {
        printf 'missing %s repository: %s\n' "$label" "$repository" >&2
        exit 2
    }
    [ "$(git -C "$repository" rev-parse HEAD)" = "$expected_commit" ] || {
        printf '%s commit drifted\n' "$label" >&2
        exit 2
    }
    [ -z "$(git -C "$repository" status --short)" ] || {
        printf '%s repository is not untouched\n' "$label" >&2
        exit 2
    }
    [ "$(shasum -a 256 "$repository/$relative" | awk '{print $1}')" = "$expected_sha" ] || {
        printf '%s source hash drifted\n' "$label" >&2
        exit 2
    }
}

require_untouched_source "$NUKE" "$EXPECTED_NUKE_COMMIT" \
    Sources/Nuke/Internal/Log.swift "$EXPECTED_NUKE_LOG_SHA256" Nuke
require_untouched_source "$BUTTONKIT" "$EXPECTED_BUTTONKIT_COMMIT" \
    Sources/ButtonKit/Trigger/Trigger+Environment.swift \
    "$EXPECTED_BUTTONKIT_TRIGGER_SHA256" ButtonKit
require_untouched_source "$EMOJITEXT" "$EXPECTED_EMOJITEXT_COMMIT" \
    Sources/EmojiText/Logger.swift "$EXPECTED_EMOJITEXT_LOGGER_SHA256" EmojiText

OUTPUT=$(mktemp -d /private/tmp/oslog-host-proof.XXXXXX)
trap 'rm -rf "$OUTPUT"' EXIT

xcrun swiftc -parse-as-library -module-name os \
    -emit-module -emit-module-path "$OUTPUT/os.swiftmodule" \
    -emit-library -Xlinker -install_name -Xlinker @rpath/libos.dylib \
    "$ROOT/full/foundation/os-module/os.swift" -o "$OUTPUT/libos.dylib"
xcrun swiftc -parse-as-library -module-name OSLog -I "$OUTPUT" \
    -emit-module -emit-module-path "$OUTPUT/OSLog.swiftmodule" \
    -emit-library -Xlinker -install_name -Xlinker @rpath/libOSLog.dylib \
    -Xlinker -reexport_library -Xlinker "$OUTPUT/libos.dylib" \
    "$ROOT/full/oslog/OSLog.swift" -o "$OUTPUT/libOSLog.dylib"

# Compile and run our framework gate together with EmojiText's exact untouched
# Logger extension. This proves OSLog re-exports one shared `os.Logger` identity.
xcrun swiftc -parse-as-library -I "$OUTPUT" -L "$OUTPUT" -lOSLog \
    "$ROOT/full/oslog/tests/OSLogHostRuntime.swift" \
    "$EMOJITEXT/Sources/EmojiText/Logger.swift" \
    -o "$OUTPUT/OSLogHostRuntime"
DYLD_LIBRARY_PATH="$OUTPUT" "$OUTPUT/OSLogHostRuntime" \
    > "$OUTPUT/oslog.stdout" 2> "$OUTPUT/oslog.stderr"
grep -Fxq \
    'OSLOG_HOST_RUNTIME_OK backend=standard-error signposts=visible identity=shared scope=process-local' \
    "$OUTPUT/oslog.stdout"
grep -Fq '[info] at.davidwalter.EmojiText:Text emoji logger identity=shared' \
    "$OUTPUT/oslog.stderr"
grep -Fq '[signpost-begin] PortableOSLog:HostGate host-work id=' \
    "$OUTPUT/oslog.stderr"
grep -Fq '[signpost-event] PortableOSLog:HostGate host-value id=' \
    "$OUTPUT/oslog.stderr"
grep -Fq 'format=%{public}s args=[visible]' "$OUTPUT/oslog.stderr"
grep -Fq '[signpost-end] PortableOSLog:HostGate host-work id=' \
    "$OUTPUT/oslog.stderr"
! grep -Fq 'must-not-appear' "$OUTPUT/oslog.stderr"

# Compile Nuke's exact untouched os-facing implementation into the executable,
# then exercise object events plus synchronous and asynchronous intervals.
xcrun swiftc -parse-as-library -I "$OUTPUT" -L "$OUTPUT" -los \
    "$ROOT/full/oslog/tests/NukeSignpostRuntime.swift" \
    "$NUKE/Sources/Nuke/Internal/Log.swift" \
    -o "$OUTPUT/NukeSignpostRuntime"
DYLD_LIBRARY_PATH="$OUTPUT" "$OUTPUT/NukeSignpostRuntime" \
    > "$OUTPUT/nuke.stdout" 2> "$OUTPUT/nuke.stderr"
grep -Fxq 'OSLOG_UNTOUCHED_NUKE_RUNTIME_OK sync=42 async=84' \
    "$OUTPUT/nuke.stdout"
grep -Fq '[signpost-event] com.github.kean.Nuke.ImagePipeline:Image Loading NukeEvent' \
    "$OUTPUT/nuke.stderr"
grep -Fq 'args=[image-ready]' "$OUTPUT/nuke.stderr"
for boundary in \
    '[signpost-begin] com.github.kean.Nuke.ImagePipeline:Image Loading NukeSync' \
    '[signpost-end] com.github.kean.Nuke.ImagePipeline:Image Loading NukeSync' \
    '[signpost-begin] com.github.kean.Nuke.ImagePipeline:Image Loading NukeAsync' \
    '[signpost-end] com.github.kean.Nuke.ImagePipeline:Image Loading NukeAsync'; do
    grep -Fq "$boundary" "$OUTPUT/nuke.stderr"
done

# Typecheck all 26 untouched ButtonKit sources with the local OSLog and
# AppIntents modules. Trigger+Environment is the exact OSLog consumer; this
# broader gate ensures its surrounding target still agrees with the overlay.
xcrun swiftc -parse-as-library -module-name AppIntents \
    -emit-module -emit-module-path "$OUTPUT/AppIntents.swiftmodule" \
    -emit-library -o "$OUTPUT/libAppIntents.dylib" \
    "$ROOT/full/appintents/AppIntents.swift"
mapfile -t BUTTONKIT_SOURCES < <(find "$BUTTONKIT/Sources/ButtonKit" \
    -type f -name '*.swift' -print | LC_ALL=C sort)
[ "${#BUTTONKIT_SOURCES[@]}" -eq 26 ]
xcrun swiftc -parse-as-library -suppress-warnings -typecheck -I "$OUTPUT" \
    "${BUTTONKIT_SOURCES[@]}"

[ "$(xcrun otool -D "$OUTPUT/libOSLog.dylib" | grep -Fc '@rpath/libOSLog.dylib')" -eq 1 ]
[ "$(xcrun otool -l "$OUTPUT/libOSLog.dylib" | grep -Fc 'cmd LC_REEXPORT_DYLIB')" -eq 1 ]
! xcrun otool -L "$OUTPUT/libOSLog.dylib" \
    | grep -F '/System/Library/Frameworks/OSLog.framework/' >/dev/null

printf 'OSLOG_EXACT_CONSUMERS_OK nuke=%s:%s buttonkit=%s:%s:26 emojitext=%s:%s dylib=reexports-os\n' \
    "$EXPECTED_NUKE_COMMIT" "$EXPECTED_NUKE_LOG_SHA256" \
    "$EXPECTED_BUTTONKIT_COMMIT" "$EXPECTED_BUTTONKIT_TRIGGER_SHA256" \
    "$EXPECTED_EMOJITEXT_COMMIT" "$EXPECTED_EMOJITEXT_LOGGER_SHA256"
