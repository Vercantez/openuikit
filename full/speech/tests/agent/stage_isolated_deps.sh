#!/usr/bin/env bash
# Stage isolated CoreMedia + AVFoundation modules for the Speech fan-out gate.
# This is not the EC2 integrated run: that run must build the real guest
# Foundation, AVFoundation, and CoreMedia dylibs first.
set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
FRAMEWORK_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd -P)
REPO_ROOT=$(git -C "$FRAMEWORK_ROOT" rev-parse --show-toplevel)
SWIFTC=${SPEECH_DEP_SWIFTC:-/usr/bin/swiftc}

if [ -n "${SPEECH_DEP_STAGE:-}" ]; then
    STAGE=$SPEECH_DEP_STAGE
    mkdir -p "$STAGE/bin"
    rm -f "$STAGE"/libCoreMedia.dylib "$STAGE"/libAVFoundation.dylib
    rm -f "$STAGE"/CoreMedia.swiftmodule "$STAGE"/AVFoundation.swiftmodule
else
    STAGE=$(mktemp -d "${TMPDIR:-/tmp}/speech-isolated-deps.XXXXXX")
    mkdir -p "$STAGE/bin"
fi

"$SWIFTC" -warnings-as-errors -parse-as-library -emit-library -emit-module \
    -module-name CoreMedia \
    -emit-module-path "$STAGE/CoreMedia.swiftmodule" \
    -o "$STAGE/libCoreMedia.dylib" \
    "$REPO_ROOT/full/coremedia/CoreMedia.swift" \
    "$SCRIPT_DIR/isolated-deps/CoreMediaSampleBuffer.swift"

"$SWIFTC" -warnings-as-errors -parse-as-library -emit-library -emit-module \
    -module-name AVFoundation \
    -I "$STAGE" \
    -emit-module-path "$STAGE/AVFoundation.swiftmodule" \
    -o "$STAGE/libAVFoundation.dylib" \
    "$STAGE/libCoreMedia.dylib" \
    "$SCRIPT_DIR/isolated-deps/AVFoundation.swift"

cat > "$STAGE/bin/swiftc" <<EOF
#!/usr/bin/env bash
set -euo pipefail
exec $(printf '%q' "$SWIFTC") -I $(printf '%q' "$STAGE") \\
    $(printf '%q' "$STAGE/libCoreMedia.dylib") \\
    $(printf '%q' "$STAGE/libAVFoundation.dylib") \\
    "\$@"
EOF
chmod +x "$STAGE/bin/swiftc"

printf 'SPEECH_DEP_STAGE=%s\n' "$STAGE"
