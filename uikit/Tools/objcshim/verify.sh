#!/bin/zsh
# Proves @objc + #selector compile AND run on Linux (no ObjC runtime, no
# compiler patch). Run from the repo root; requires Docker.
set -e
cd "$(dirname "$0")/../.."
W=$(mktemp -d)
cp Tools/objcshim/objc_stub.c Tools/objcshim/ObjectiveC.swift "$W/"
cat > "$W/run.sh" <<'INNER'
set -e
cd /w
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
docker run --rm -v "$W":/w swift:6.2-noble bash /w/run.sh
echo "OK: @objc/#selector work on Linux with the shim"
rm -rf "$W"
