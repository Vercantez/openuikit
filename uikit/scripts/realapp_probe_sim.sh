#!/bin/zsh
# Renders the REAL-APP screen (Sources/RealAppProbe: unmodified pocket-casts
# source) with REAL UIKit in the iOS 26 simulator and copies the goldens to
# <outdir>: <variant>.png (drawHierarchy at scale 2, the openrender scale) and
# <variant>.layout.json (the SceneKit dumpLayout shape). This is the oracle
# docs/REAL_APP_TEST.md "Where the render is wrong" item 4 said did not exist.
#
# The vendored app files compile unchanged. Two harness files are patched in
# a temp copy for the Darwin build only (import OpenUIKit -> UIKit; the
# OpenUIKit-only asset-path hooks removed; UIViewController's designated init).
# SelectorTables.swift is native-ELF-only and is not compiled here.
set -e
setopt null_glob
cd "$(dirname "$0")/.."
OUTDIR=${1:?usage: realapp_probe_sim.sh <outdir>}
mkdir -p "$OUTDIR"

SDK=$(xcrun --show-sdk-path --sdk iphonesimulator)
APP=Tools/oracle2/RealAppProbe.app
rm -rf "$APP"; mkdir -p "$APP"
TMPSRC=$(mktemp -d /tmp/realappprobe.XXXXXX)
sed -e 's/^import OpenUIKit$/import UIKit/' \
    -e 's/^        OpenUIKitRuntime.imageSearchPaths = \[directory\]$/        _ = directory/' \
    -e 's/^        UIImage.clearNamedCache()$//' \
    -e 's/^        super.init()$/        super.init(nibName: nil, bundle: nil)/' \
    -e 's/^    public override func viewDidLoad() {$/    required init?(coder: NSCoder) { fatalError() }\n    public override func viewDidLoad() {/' \
    Sources/RealAppProbe/RealAppScreen.swift > "$TMPSRC/RealAppScreen.swift"
sed -e 's/^import OpenUIKit$/import UIKit/' Sources/RealAppProbe/Shims.swift > "$TMPSRC/Shims.swift"
# The vendored file's two ADAPTED(objc-runtime) lines are the ledger's own
# `Selector.named` spelling for native ELF; on Darwin compile the UPSTREAM
# `#selector` text (pocket-casts-ios podcasts/SimpleActionView.swift:106,137).
mkdir -p "$TMPSRC/Vendored"
for f in Sources/RealAppProbe/Vendored/*.swift; do
  sed -e 's/action: Selector.named("switchToggled:")/action: #selector(switchToggled(_:))/' \
      -e 's/action: Selector.named("actionTapped")/action: #selector(actionTapped)/' \
      -e 's/^    func switchToggled(_ sender: AnyObject?) {$/    @objc private func switchToggled(_ sender: UISwitch) {/' \
      -e 's/^    func actionTapped() {$/    @objc private func actionTapped() {/' \
      "$f" > "$TMPSRC/Vendored/$(basename "$f")"
done
swiftc -O -swift-version 5 -Xfrontend -default-isolation -Xfrontend MainActor -target arm64-apple-ios26.0-simulator -sdk "$SDK" \
  -module-name realappprobe \
  Tools/oracle2/realappprobe/main.swift \
  "$TMPSRC/RealAppScreen.swift" "$TMPSRC/Shims.swift" \
  "$TMPSRC"/Vendored/*.swift \
  -o "$APP/realappprobe"
cp Tools/oracle2/RealAppProbe-Info.plist "$APP/Info.plist"
cp fixtures/realapp/assets/*.png "$APP/"
rm -rf "$TMPSRC"

DEVNAME="OpenUIKit-Chrome"
DEVTYPE="com.apple.CoreSimulator.SimDeviceType.iPhone-16"
RUNTIME=$(xcrun simctl list runtimes | grep -o 'com.apple.CoreSimulator.SimRuntime.iOS-26[0-9-]*' | tail -1)
UDID=$(xcrun simctl list devices | grep "$DEVNAME" | grep -o '[0-9A-F-]\{36\}' | head -1)
if [[ -z "$UDID" ]]; then
  UDID=$(xcrun simctl create "$DEVNAME" "$DEVTYPE" "$RUNTIME")
fi
STATE=$(xcrun simctl list devices | grep "$UDID" | grep -o '(Booted)' || true)
if [[ -z "$STATE" ]]; then
  xcrun simctl boot "$UDID"
  xcrun simctl bootstatus "$UDID"
fi
xcrun simctl uninstall "$UDID" com.openuikit.realappprobe 2>/dev/null || true
xcrun simctl install "$UDID" "$APP"
CONTAINER=$(xcrun simctl get_app_container "$UDID" com.openuikit.realappprobe data)
rm -f "$CONTAINER"/Documents/* 2>/dev/null || true
xcrun simctl launch --console-pty "$UDID" com.openuikit.realappprobe >/dev/null || true
for i in {1..60}; do [[ -f "$CONTAINER/Documents/DONE" ]] && break; sleep 1; done
[[ -f "$CONTAINER/Documents/DONE" ]] || { echo "realapp_probe_sim: no DONE marker"; exit 1; }
cp "$CONTAINER"/Documents/*.png "$CONTAINER"/Documents/*.json "$OUTDIR"/
echo "goldens in $OUTDIR:"; ls "$OUTDIR"
