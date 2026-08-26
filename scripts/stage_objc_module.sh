#!/bin/bash
# stage_objc_module.sh -- add an `ObjectiveC` clang module to scratch/sysroot
# so rung 4 (@objc / #selector) can be compiled for arm64-apple-macos.
#
# The headers come from ~/machorun/vendor/objc4 (Apple's own OSS release, the
# same source machorun compiles into darwin/usr/lib/libobjc.A.dylib) -- NOT
# from Xcode. The modulemap is ours: Apple's ObjectiveC.modulemap uses
# `umbrella "objc"`, which would drag in every private header in the vendored
# tree, so this one lists exactly what the Swift ObjectiveC overlay needs.
set -euo pipefail
[ "$(uname -s)" = "Darwin" ] || { echo "macOS only (reads ~/machorun)" >&2; exit 1; }
ROOT=$(cd "$(dirname "$0")/.." && pwd)
OBJC4=${OBJC4:-$HOME/machorun/vendor/objc4/runtime}
INC="$ROOT/scratch/sysroot/usr/include"
for h in NSObject.h NSObjCRuntime.h Protocol.h; do
    cp "$OBJC4/$h" "$INC/objc/$h"
done
cat > "$INC/module.modulemap" <<'EOF'
module ObjectiveC [system] {
  header "objc/objc.h"
  header "objc/objc-api.h"
  header "objc/runtime.h"
  header "objc/message.h"
  export *
  module NSObject  { header "objc/NSObject.h"      export * }
  module Protocol  { header "objc/Protocol.h"      export * }
  module Runtime   { header "objc/NSObjCRuntime.h" export * }
}
EOF
echo "staged objc module: $(ls "$INC/objc" | tr '\n' ' ')"

# Apple's API notes for the ObjectiveC module. objc4's published NSObject.h --
# and, measured, Apple's SDK copy of the same header -- carries no nullability
# annotations at all: `- (instancetype)init` is line 66 of both, unaudited.
# Every bit of the nullability Swift sees comes from this YAML sidecar, which
# clang picks up as <ModuleName>.apinotes next to the module map. Without it
# `View()` imports as `View!` and ordinary Swift stops compiling.
# It is data, not code, and small enough to reimplement clean-room later.
cp "$(xcrun --show-sdk-path --sdk macosx)/usr/include/ObjectiveC.apinotes" "$INC/ObjectiveC.apinotes"
echo "staged ObjectiveC.apinotes ($(wc -l < "$INC/ObjectiveC.apinotes") lines)"
