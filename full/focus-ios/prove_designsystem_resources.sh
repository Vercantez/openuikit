#!/bin/bash
# Emit the exact four shipping Focus DesignSystem sources against a fresh build
# of committed OpenUIKit, using only the accessor produced by package_resources.py.
set -euo pipefail

# Re-exec once with every ambient GIT_* variable removed. This prevents work
# tree/index/object redirection and user configuration from changing any pin
# check, clone, checkout, or status command below.
if [ "${FOCUS_RESOURCE_CLEAN_ENV:-0}" != 1 ]; then
    exec python3 -c '
import os
import sys
environment = {
    name: value for name, value in os.environ.items() if not name.startswith("GIT_")
}
environment.update({
    "FOCUS_RESOURCE_CLEAN_ENV": "1",
    "GIT_CONFIG_GLOBAL": os.devnull,
    "GIT_CONFIG_NOSYSTEM": "1",
    "GIT_NO_REPLACE_OBJECTS": "1",
    "GIT_OPTIONAL_LOCKS": "0",
    "LANG": "C",
    "LC_ALL": "C",
})
script = os.path.abspath(sys.argv[1])
os.execve(script, [script, *sys.argv[2:]], environment)
' "$0" "$@"
fi

HERE=$(cd "$(dirname "$0")" && pwd)
SML=$(cd "$HERE/../.." && pwd)
FOCUS=${FOCUS:-$SML/scratch/ladder-corpus/focus-ios/focus-ios}
UIKIT_SRC=${UIKIT_SRC:-$SML/../uikit}
TARGET=${TARGET:-arm64-apple-macos13.0}
FOCUS_COMMIT=a2832521c1daa0c23419c73705ae043ed60c9791
POLICY=$HERE/package-resources.json

clean_git() {
    command git -c core.fsmonitor=false -c core.hooksPath=/dev/null "$@"
}

if [ "$#" -gt 1 ]; then
    printf 'usage: %s [NEW_OUTPUT_DIRECTORY]\n' "$0" >&2
    exit 2
fi
if [ "$#" -eq 1 ]; then
    OUT=$1
else
    PROOF_PARENT=$(mktemp -d /tmp/focus-designsystem-resource-proof.XXXXXX)
    OUT=$PROOF_PARENT/proof
fi
if [ -e "$OUT" ] || [ -L "$OUT" ]; then
    printf 'REFUSED: proof output already exists: %s\n' "$OUT" >&2
    exit 2
fi
mkdir "$OUT"

actual_focus=$(clean_git -C "$FOCUS" rev-parse --verify HEAD^{commit})
if [ "$actual_focus" != "$FOCUS_COMMIT" ]; then
    printf 'REFUSED: expected Focus %s, got %s\n' "$FOCUS_COMMIT" "$actual_focus" >&2
    exit 3
fi

STAGE=$OUT/stage
AUDIT=$OUT/package-resources-audit.json
python3 -B "$HERE/package_resources.py" stage \
    "$FOCUS" "$POLICY" "$STAGE" "$AUDIT" \
    > "$OUT/stage.log"
UIKIT_COMMIT=$(python3 - "$AUDIT" <<'PY'
import json
from pathlib import Path
import sys

print(json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))["module_proof"]["openuikit_commit"])
PY
)

# Clone without a work tree and detach at the policy-pinned object. UIKIT_SRC's
# branch may advance; its HEAD is deliberately irrelevant as long as it still
# contains the reviewed commit. Uncommitted source bytes cannot enter the clone.
UIKIT_CLONE=$OUT/uikit
clean_git clone -q --no-checkout --shared "$UIKIT_SRC" "$UIKIT_CLONE"
clean_git -C "$UIKIT_CLONE" checkout -q --detach "$UIKIT_COMMIT"
clone_commit=$(clean_git -C "$UIKIT_CLONE" rev-parse --verify HEAD^{commit})
if [ "$clone_commit" != "$UIKIT_COMMIT" ]; then
    printf 'REFUSED: cloned OpenUIKit pin changed: %s\n' "$clone_commit" >&2
    exit 4
fi
if [ -n "$(clean_git -C "$UIKIT_CLONE" status --porcelain)" ]; then
    printf 'REFUSED: fresh OpenUIKit clone is dirty\n' >&2
    exit 4
fi

( cd "$UIKIT_CLONE" && swift build -c release --product OpenUIKit ) \
    > "$OUT/openuikit-build.log" 2>&1
BIN=$(cd "$UIKIT_CLONE" && swift build -c release --show-bin-path)
if [ ! -f "$BIN/Modules/UIKit.swiftmodule" ]; then
    printf 'REFUSED: fresh OpenUIKit build did not emit UIKit.swiftmodule\n' >&2
    exit 4
fi

INCLUDES=(-I "$BIN/Modules" -I "$BIN")
while IFS= read -r -d '' modulemap; do
    INCLUDES+=(-Xcc -I -Xcc "$(dirname "$modulemap")")
done < <(find "$UIKIT_CLONE/Sources" -name module.modulemap -print0)

# Consume the attested source inventory from the audit rather than maintaining
# a second shell list that could drift from the resource policy.
SOURCES=()
while IFS= read -r -d '' source; do
    SOURCES+=("$FOCUS/$source")
done < <(
    python3 - "$AUDIT" <<'PY'
import json
from pathlib import Path
import sys

audit = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
proof = audit["module_proof"]
if proof["target"] != "DesignSystem" or len(proof["sources"]) != 4:
    raise SystemExit("audit does not describe the four-source DesignSystem proof")
for source in proof["sources"]:
    sys.stdout.buffer.write(source["path"].encode("utf-8") + b"\0")
PY
)
if [ "${#SOURCES[@]}" -ne 4 ]; then
    printf 'REFUSED: expected exactly four attested DesignSystem sources\n' >&2
    exit 5
fi

ACCESSOR=$STAGE/accessors/DesignSystem/Bundle+Module.swift
DIAGNOSTICS=$OUT/designsystem-diagnostics.log
if ! swiftc -emit-module \
    -emit-module-path "$OUT/DesignSystem.swiftmodule" \
    -parse-as-library -wmo -swift-version 5 \
    -target "$TARGET" -module-name DesignSystem \
    "${INCLUDES[@]}" "${SOURCES[@]}" "$ACCESSOR" \
    > "$DIAGNOSTICS" 2>&1; then
    printf 'FAILED: DesignSystem module emission; see %s\n' "$DIAGNOSTICS" >&2
    exit 5
fi
if [ ! -s "$OUT/DesignSystem.swiftmodule" ]; then
    printf 'FAILED: swiftc returned success without a DesignSystem module\n' >&2
    exit 5
fi
if [ -s "$DIAGNOSTICS" ]; then
    printf 'FAILED: module emitted with unexpected diagnostics; see %s\n' \
        "$DIAGNOSTICS" >&2
    exit 5
fi

# Close the source/resource bracket after swiftc has consumed the files.
python3 -B "$HERE/package_resources.py" verify \
    "$FOCUS" "$POLICY" "$STAGE" "$AUDIT" \
    > "$OUT/verify.log"
if [ "$(clean_git -C "$UIKIT_CLONE" rev-parse --verify HEAD^{commit})" != "$UIKIT_COMMIT" ] || \
   [ -n "$(clean_git -C "$UIKIT_CLONE" status --porcelain --untracked-files=no)" ]; then
    printf 'REFUSED: OpenUIKit source changed during the proof\n' >&2
    exit 6
fi

module_hash=$(shasum -a 256 "$OUT/DesignSystem.swiftmodule" | awk '{print $1}')
printf 'PROVED: four pinned shipping DesignSystem sources emitted cleanly\n'
printf '  Focus:     %s\n' "$FOCUS_COMMIT"
printf '  OpenUIKit: %s\n' "$UIKIT_COMMIT"
printf '  target:    %s (Swift language mode 5)\n' "$TARGET"
printf '  module:    %s bytes, sha256 %s\n' \
    "$(wc -c < "$OUT/DesignSystem.swiftmodule" | tr -d ' ')" "$module_hash"
printf '  output:    %s\n' "$OUT"
