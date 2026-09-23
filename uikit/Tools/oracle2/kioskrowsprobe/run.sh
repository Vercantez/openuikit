#!/bin/zsh
# kioskrowsprobe — the Apple side of Tests/KioskRowsTests.
#
# Builds scenario/OUKKioskRowsScenario.m (the same file OpenUIKit's test
# target compiles) into an app against the iOS 26.1 simulator's UIKit, with
# Artsy+UIFonts 3.1.3's EBGaramond12-Regular.ttf in the bundle, runs it on a
# throwaway iPad Pro 11-inch (M4) — Eidolon's golden device — and writes
# transcript-ios26.1.txt. The device is deleted; /tmp/conformance_sim.lock
# serialises simulator use across agents.   zsh run.sh [WORKDIR]
set -eu
HERE=${0:A:h}
UIKIT=${HERE:h:h:h}
WORK=${1:-${TMPDIR:-/tmp}/kioskrowsprobe}
SDK=$(xcrun --sdk iphonesimulator --show-sdk-path)
APP=$WORK/KioskRowsProbe.app
rm -rf "$APP"; mkdir -p "$APP"
xcrun --sdk iphonesimulator clang -fobjc-arc -fmodules -Wno-deprecated-declarations \
  -target arm64-apple-ios26.1-simulator -isysroot "$SDK" -I"$HERE/scenario/include" \
  "$HERE/main.m" "$HERE/scenario/OUKKioskRowsScenario.m" \
  -framework UIKit -framework Foundation -framework CoreText -framework QuartzCore -o "$APP/KioskRowsProbe"
cp "$UIKIT/Sources/EidolonPods/Pods/Artsy-OSSUIFonts/Pod/Assets/EBGaramond12-Regular.ttf" "$APP/"
cat > "$APP/Info.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleIdentifier</key><string>org.openuikit.kioskrowsprobe</string>
<key>CFBundleExecutable</key><string>KioskRowsProbe</string>
<key>CFBundleName</key><string>KioskRowsProbe</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleVersion</key><string>1</string>
<key>CFBundleShortVersionString</key><string>1.0</string>
<key>UIDeviceFamily</key><array><integer>1</integer><integer>2</integer></array>
<key>UILaunchScreen</key><dict/>
</dict></plist>
EOF
codesign -s - "$APP" 2>/dev/null || true
source "${HERE:h}/sim_lock.zsh"
sim_lock_acquire
DEV=$(xcrun simctl create "iPad-kioskrowsprobe" com.apple.CoreSimulator.SimDeviceType.iPad-Pro-11-inch-M4-8GB com.apple.CoreSimulator.SimRuntime.iOS-26-1)
trap 'xcrun simctl shutdown "$DEV" >/dev/null 2>&1; xcrun simctl delete "$DEV" >/dev/null 2>&1; sim_lock_release' EXIT
xcrun simctl boot "$DEV"
xcrun simctl bootstatus "$DEV" -b >/dev/null
xcrun simctl install "$DEV" "$APP"
timeout 120 xcrun simctl launch --console "$DEV" org.openuikit.kioskrowsprobe 2>/dev/null \
  | sed -n '/^# kioskrowsprobe/,/^DONE$/p' | grep -v '^DONE$' > "$HERE/transcript-ios26.1.txt"
cat "$HERE/transcript-ios26.1.txt"
