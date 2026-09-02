#!/usr/bin/env bash
# Proves @objc + #selector compile AND run on Linux (no ObjC runtime, no
# compiler patch). Run from the repo root; requires Docker or an attested
# Cursor cloud environment whose toolchain matches swift:6.2-noble.
set -e
cd "$(dirname "$0")/../.."
W=$(mktemp -d)
cp Tools/objcshim/objc_stub.c Tools/objcshim/ObjectiveC.swift "$W/"
cat > "$W/run.sh" <<'INNER'
set -e
cd "${TOOLCHAIN_ROOT:-/w}"
clang -c objc_stub.c -o objc_stub.o
mkdir -p objclib && ar rcs objclib/libobjc.a objc_stub.o
mkdir -p shim
swiftc -Xfrontend -enable-objc-interop -emit-module -emit-library -static \
  -module-name ObjectiveC ObjectiveC.swift -o shim/libObjectiveC.a \
  -emit-module-path shim/ObjectiveC.swiftmodule
cat > t.swift <<'X'
import ObjectiveC
class Handler {
    @objc func tapped() {}
    @objc func valueChanged(_ sender: AnyObject) {}
}
for sel in [#selector(Handler.tapped), #selector(Handler.valueChanged(_:))] {
    print("recovered:", String(cString: UnsafePointer<CChar>(sel.ptr)))
}
X
swiftc -Xfrontend -enable-objc-interop \
       -Xfrontend -disable-objc-attr-requires-foundation-module \
       -I shim -L shim -lObjectiveC -L objclib t.swift -o t
./t
INNER
# Docker exists only to pin stock swift:6.2-noble. This VM already is that
# toolchain (same FROM digest as harness/Dockerfile); attestation is sufficient
# because the inner program is a Linux ELF, not arm64 Mach-O execution.
REPO_ROOT=$(git rev-parse --show-toplevel)
. "$REPO_ROOT/.cursor/cursor-env.sh"
mode=$(cursor_env_toolchain_mode) || exit 2
if [ "$mode" = docker ]; then
  docker run --rm -v "$W":/w swift:6.2-noble bash /w/run.sh
else
  echo "CURSOR_ENV_TOOLCHAIN_ATTESTED running objcshim verify in-VM (docker pins swift:6.2-noble only)"
  TOOLCHAIN_ROOT=$W bash "$W/run.sh"
fi
echo "OK: @objc/#selector work on Linux with the shim"
rm -rf "$W"
