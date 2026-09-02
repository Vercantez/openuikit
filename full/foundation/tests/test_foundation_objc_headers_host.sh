#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/../../.." && pwd)
PROOF=$(mktemp -d /private/tmp/foundation-objc-headers-host.XXXXXX)
cleanup() {
    /usr/bin/trash "$PROOF" 2>/dev/null || true
}
trap cleanup EXIT

HEADER_ROOT=$ROOT/full/foundation/include
MANIFEST=$ROOT/full/foundation/foundation_objc_headers.txt
PROBE=$ROOT/full/foundation/tests/FoundationObjCNSObjectHeaderProbe.m
ARPA_INET=$ROOT/full/sdk-gaps/usr/include/arpa/inet.h

python3 - "$HEADER_ROOT" "$MANIFEST" <<'PY'
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
manifest = pathlib.Path(sys.argv[2]).read_text().splitlines()
assert manifest == sorted(manifest)
assert len(manifest) == len(set(manifest)) == 4
assert set(manifest) == {
    "CoreFoundation/CoreFoundation.h",
    "Foundation/NSObject.h",
    "Foundation/NSObjCRuntime.h",
    "Foundation/NSZone.h",
}
for name in manifest:
    path = root / name
    assert path.is_file() and not path.is_symlink()
PY
test -f "$ARPA_INET" && test ! -L "$ARPA_INET"

xcrun clang -fno-objc-arc -std=gnu11 -O2 -Wall -Wextra -Werror \
    -I "$HEADER_ROOT" "$PROBE" -framework Foundation \
    -o "$PROOF/FoundationObjCNSObjectHeaderProbe"
"$PROOF/FoundationObjCNSObjectHeaderProbe" \
    | tee "$PROOF/runtime.log"
grep -Fxq \
    'FOUNDATION_OBJC_NSOBJECT_HEADER_OK protocols=copying,coding,secure-coding runtime=objc-root' \
    "$PROOF/runtime.log"

IPHONEOS_SDK=$(xcrun --sdk iphoneos --show-sdk-path)
xcrun clang -target arm64-apple-ios18.0 -isysroot "$IPHONEOS_SDK" \
    -fno-objc-arc -std=gnu11 -Wall -Wextra -Werror \
    -fsyntax-only "$PROBE"
xcrun clang -target arm64-apple-ios18.0 -isysroot "$IPHONEOS_SDK" \
    -fno-objc-arc -std=gnu11 -Wall -Wextra -Werror \
    -I "$HEADER_ROOT" -fsyntax-only "$PROBE"
xcrun clang -target arm64-apple-ios18.0 -isysroot "$IPHONEOS_SDK" \
    -fno-objc-arc -std=gnu11 -O2 -fvisibility=hidden \
    -Wall -Wextra -Werror -I "$ROOT/full/systemconfiguration/include" \
    -fsyntax-only "$ROOT/full/systemconfiguration/SystemConfiguration.m"

xcrun clang -fno-objc-arc -std=gnu11 -O2 \
    -fvisibility=hidden -Wall -Wextra -Werror \
    -I "$HEADER_ROOT" -I "$ROOT/full/sdk-gaps/usr/include" \
    -I "$ROOT/full/systemconfiguration/include" \
    -c "$ROOT/full/systemconfiguration/SystemConfiguration.m" \
    -o "$PROOF/SystemConfiguration.o"

printf 'FOUNDATION_OBJC_HEADERS_HOST_OK headers=4 sdk-forwarders=1 consumer=SystemConfiguration.m oracle=iphoneos26.1\n'
