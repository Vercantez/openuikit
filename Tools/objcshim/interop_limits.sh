#!/bin/zsh
# Measures WHY `-enable-objc-interop` cannot be used on Linux, so the claim in
# docs/OBJC_RUNTIME.md is reproducible rather than asserted. Companion to
# verify.sh, which shows the part that DOES work (@objc/#selector compile and
# a selector name is recoverable).
#
# Three measurements, all inside stock swift:6.2-noble:
#
#   1. Class metadata layout with interop off vs on. Interop inserts three
#      extra words (CacheData[2] + Data, the ObjC class header) between
#      Superclass and Flags.
#   2. A program with NO @objc anywhere, built without interop: works.
#   3. The same program built WITH interop and this directory's libobjc.a:
#      links, then segfaults inside libswiftCore on `type(of:)` -- because
#      libswiftCore.so is built with SWIFT_OBJC_INTEROP=0 and reads the
#      Description field at the non-interop offset.
#
# The blocker is therefore the Swift *standard library*, not the ObjC runtime,
# which is why GNUstep libobjc2 does not open this door either.
#
# Run from anywhere; requires Docker.
set -e
cd "$(dirname "$0")/../.."
W=$(mktemp -d)
cp Tools/objcshim/objc_stub.c Tools/objcshim/ObjectiveC.swift "$W/"
cat > "$W/run.sh" <<'INNER'
set -e
cd /w
clang -c objc_stub.c -o objc_stub.o
mkdir -p objclib && ar rcs objclib/libobjc.a objc_stub.o
F="-Xfrontend -enable-objc-interop -Xfrontend -disable-objc-attr-requires-foundation-module"
swiftc $F -emit-module -emit-library -static -module-name ObjectiveC \
  ObjectiveC.swift -o libObjectiveC.a -emit-module-path ObjectiveC.swiftmodule

echo "=== 1. class metadata object layout (address point is field [3]) ==="
cat > r.swift <<'X'
public class Root { public var x = 1 }
X
layout() { grep -E '^@"\$s1r4RootCN" = ' | grep -oE '<\{[^}]*\}>'; }
printf '  interop OFF: '
swiftc -emit-ir r.swift 2>/dev/null | layout
printf '  interop ON : '
swiftc -Xfrontend -enable-objc-interop -emit-ir r.swift 2>/dev/null | layout
echo "  (ON has three extra words -- ptr, ptr, i64 -- after Superclass:"
echo "   that is the ObjC class header the Linux runtime does not expect.)"

cat > p.swift <<'X'
import ObjectiveC
protocol P: AnyObject { func p() }
class Root { var x = 1 }
final class Leaf: Root, P { func p() {} }
let s = Leaf()
print("  type(of:)      ->", String(describing: type(of: s)))
let r: Root = s
print("  class downcast ->", (r as? Leaf) != nil)
print("  protocol cast  ->", (r as? P) != nil)
X

echo
echo "=== 2. no @objc anywhere, interop OFF (control) ==="
swiftc -I . -L . -lObjectiveC p.swift -o pOff
stdbuf -o0 ./pOff

echo
echo "=== 3. the same source, interop ON ==="
swiftc $F -I . -L . -lObjectiveC -L objclib p.swift -o pOn
SWIFT_BACKTRACE=enable=no stdbuf -o0 ./pOn || \
  echo "  ^^ CRASHED (expected): libswiftCore cannot read interop-layout metadata"
INNER
docker run --rm -v "$W":/w swift:6.2-noble bash /w/run.sh
rm -rf "$W"
