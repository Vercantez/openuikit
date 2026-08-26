#!/bin/bash
# Stage a Darwin sysroot for cross-building the Swift stdlib on Linux.
#
# Inputs (all already on the box under ~/work):
#   machorun-sdk/   machorun's self-hosted header-only + .tbd SDK (375 headers)
#   objc4-runtime/  Apple objc4 runtime/ headers (NSObject.h, objc-internal.h, ...)
#   objc4-priv/     machorun's clean-room private-SPI headers
#   scf/            swift-corelibs-foundation (Apple's open-source CoreFoundation)
#   foundation/     our clean-room Foundation.h (written by hand, compiler-driven)
#
# Output: ~/work/sdk/MacOSX.sdk
set -euo pipefail
W=${W:-$HOME/work}
SDK=$W/sdk/MacOSX.sdk
rm -rf "$W/sdk"
mkdir -p "$SDK"

# 1. machorun's SDK is the base: usr/include + usr/lib/*.tbd
cp -a "$W/machorun-sdk/usr" "$SDK/usr"

# 2. objc4's public+private runtime headers. machorun's SDK ships only the four
#    objc4 headers *it* needed; the Swift stdlib reaches NSObject.h,
#    objc-internal.h, objc-abi.h, objc-exception.h, objc-sync.h and friends.
for h in NSObject.h NSObjCRuntime.h objc-internal.h objc-abi.h objc-exception.h \
         objc-sync.h objc-auto.h objc-class.h objc-load.h objc-runtime.h \
         objc.h runtime.h message.h objc-api.h hashtable.h hashtable2.h maptable.h \
         List.h Object.h Protocol.h objc-visibility.h; do
  [ -f "$W/objc4-runtime/$h" ] && cp -n "$W/objc4-runtime/$h" "$SDK/usr/include/objc/$h" || true
done

# 3. machorun's clean-room private SPI headers (TargetConditionals, ptrauth,
#    os/*, mach-o/dyld_priv.h, ...) sit at the sysroot root the same way
#    machorun's own builds consume them.
if [ -d "$W/objc4-priv" ]; then
  (cd "$W/objc4-priv" && find . -name '*.h' -exec install -D {} "$SDK/usr/include/{}" \; ) || true
fi
[ -f "$W/machorun-sdk/local/TargetConditionals.h" ] && \
  cp -f "$W/machorun-sdk/local/TargetConditionals.h" "$SDK/usr/include/TargetConditionals.h"

# 3b. Clean-room libc headers machorun's SDK does not carry because objc4 never
#     reached them (setjmp.h, signal.h, MacTypes.h). See sdk/libc/.
cp -f "$W/libc/"*.h "$SDK/usr/include/"

# 3c. libc++. A real macOS SDK ships Apple's libc++ at usr/include/c++/v1; the
#     stdlib's C++ half needs <new>, <atomic>, <type_traits>, ... machorun's
#     SDK_SURVEY §2.5 measured stock LLVM 18 libc++ as a drop-in for Apple's
#     (objc4 scored the same 41/44 and produced a byte-identical binary), so we
#     use Ubuntu's libc++-18 headers rather than fabricating 734 of our own.
mkdir -p "$SDK/usr/include/c++"
cp -a /usr/lib/llvm-18/include/c++/v1 "$SDK/usr/include/c++/v1"

# 4. CoreFoundation.framework — Apple's own open-source CF headers, verbatim.
CFH="$SDK/System/Library/Frameworks/CoreFoundation.framework/Headers"
mkdir -p "$CFH"
cp "$W/scf/Sources/CoreFoundation/include/"*.h "$CFH/"

#    swift-corelibs-foundation's CoreFoundation.h umbrella is not Apple's: it
#    appends two corelibs-internal headers. ForSwiftFoundationOnly.h is
#    swift-corelibs-foundation's private bridge to its *Swift* Foundation and
#    drags in fts/dirent; CFURLPriv.h drags in sys/mount.h. Neither is in the
#    real CoreFoundation.framework umbrella and neither is reachable from the
#    Swift stdlib. Drop them rather than fabricate filesystem headers to satisfy
#    code we do not compile.
sed -i -E '/#include "(ForSwiftFoundationOnly|CFURLPriv)\.h"/d' "$CFH/CoreFoundation.h"

# 5. Foundation.framework — clean-room umbrella (see foundation/Foundation.h).
FH="$SDK/System/Library/Frameworks/Foundation.framework/Headers"
mkdir -p "$FH"
cp "$W/foundation/"*.h "$FH/"

# 6. Module maps so `import Foundation`-style clang module lookups resolve, and
#    .tbd stubs so hard class references (NSObject, NSBundle) link.
for fw in CoreFoundation Foundation; do
  D="$SDK/System/Library/Frameworks/$fw.framework"
  mkdir -p "$D/Modules"
  cat > "$D/Modules/module.modulemap" <<EOF
framework module $fw [extern_c] [system] {
  umbrella header "$fw.h"
  export *
  module * { export * }
}
EOF
done

mkdir -p "$SDK/usr/share"
# configure_sdk_darwin hard-requires SDKSettings.plist to exist before it will
# accept a path; the JSON is what our patched version actually reads (Linux has
# no `defaults`).
cat > "$SDK/SDKSettings.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CanonicalName</key><string>macosx15.0</string>
  <key>DisplayName</key><string>macOS 15.0</string>
  <key>Version</key><string>15.0</string>
  <key>MaximumDeploymentTarget</key><string>15.0.99</string>
  <key>SupportedTargets</key>
  <dict><key>macosx</key><dict>
    <key>Archs</key><array><string>arm64</string></array>
    <key>LLVMTargetTripleSys</key><string>macos</string>
    <key>LLVMTargetTripleVendor</key><string>apple</string>
  </dict></dict>
</dict>
</plist>
EOF
cat > "$SDK/SDKSettings.json" <<'EOF'
{ "DefaultProperties": { "PLATFORM_NAME": "macosx" },
  "DisplayName": "macOS 15.0", "Version": "15.0",
  "MaximumDeploymentTarget": "15.0.99",
  "CanonicalName": "macosx15.0" }
EOF

echo "staged: $SDK"
find "$SDK" -name '*.h' | wc -l | sed 's/^/headers: /'
find "$SDK" -name '*.tbd' | wc -l | sed 's/^/tbds:    /'
