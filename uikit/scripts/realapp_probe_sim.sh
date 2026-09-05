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
    -e 's/^        OpenUIKitRuntime.nibSearchPaths = \[directory\]$/        _ = directory/' \
    -e 's/^        UIImage.clearNamedCache()$//' \
    -e 's/^        RealAppNibClasses.register()$//' \
    -e 's/^        super.init()$/        super.init(nibName: nil, bundle: nil)/' \
    -e 's/^    public override func viewDidLoad() {$/    required init?(coder: NSCoder) { fatalError() }\n    public override func viewDidLoad() {/' \
    Sources/RealAppProbe/RealAppScreen.swift > "$TMPSRC/RealAppScreen.swift"
sed -e 's/^import OpenUIKit$/import UIKit/' Sources/RealAppProbe/Shims.swift > "$TMPSRC/Shims.swift"
# The vendored file's two ADAPTED(objc-runtime) lines are the ledger's own
# `Selector.named` spelling for native ELF; on Darwin compile the UPSTREAM
# `#selector` text (pocket-casts-ios podcasts/SimpleActionView.swift:106,137).
mkdir -p "$TMPSRC/Vendored"
# Interface Builder mangles a custom class with the module it was set in, so
# the compiled xibs name `_TtC8podcasts14ThemeableTable` and friends. The port
# resolves those through UINibClassRegistry, which keys on the DEMANGLED name;
# real UIKit calls NSClassFromString and would get nil (this module is
# `realappprobe`, not `podcasts`) and silently fall back to UIOriginalClassName
# — a plain UITableView, i.e. a different screen from the one the port renders.
# `@objc(<mangled>)` gives the Objective-C runtime the name the nib asks for,
# so both oracles instantiate the same class.
objc_alias() {   # class name -> @objc(_TtC8podcasts<len><name>)
  printf 's/^class %s: /@objc(_TtC8podcasts%d%s) class %s: /\n' "$1" "${#1}" "$1" "$1"
}
ALIASES=$(for c in ThemeableView ThemeableLabel ThemeableTable ThemeableCell \
                   TintableImageView SwitchCell DisclosureCell \
                   StorageAndDataUseViewController; do objc_alias "$c"; done)
for f in Sources/RealAppProbe/Vendored/*.swift; do
  sed -e 's/action: Selector.named("switchToggled:")/action: #selector(switchToggled(_:))/' \
      -e 's/action: Selector.named("actionTapped")/action: #selector(actionTapped)/' \
      -e 's/^    func switchToggled(_ sender: AnyObject?) {$/    @objc private func switchToggled(_ sender: UISwitch) {/' \
      -e 's/^    func actionTapped() {$/    @objc private func actionTapped() {/' \
      -e 's/action: Selector.named("warnWhenNotOnWifiToggled:")/action: #selector(warnWhenNotOnWifiToggled(_:))/' \
      -e 's/^    func warnWhenNotOnWifiToggled(_ sender: UISwitch) {$/    @objc private func warnWhenNotOnWifiToggled(_ sender: UISwitch) {/' \
      -e 's/selector: Selector.named("themeDidChange")/selector: #selector(themeDidChange)/' \
      -e 's/^    func themeDidChange() {$/    @objc private func themeDidChange() {/' \
      -e 's/^    var cellLabel: /    @IBOutlet var cellLabel: /' \
      -e 's/^    var cellImage: /    @IBOutlet var cellImage: /' \
      -e 's/^    var cellSwitch: /    @IBOutlet var cellSwitch: /' \
      -e 's/^    var cellSecondaryLabel: /    @IBOutlet var cellSecondaryLabel: /' \
      -e 's/^    var disclosureImage: /    @IBOutlet var disclosureImage: /' \
      -e 's/^    var cellTextToImageConstraint: /    @IBOutlet var cellTextToImageConstraint: /' \
      -e 's/^    var cellTextToMarginConstraint: /    @IBOutlet var cellTextToMarginConstraint: /' \
      -e 's/^    var cellSecondaryTextWidthConstraint: /    @IBOutlet var cellSecondaryTextWidthConstraint: /' \
      -e 's/^    var settingsTable: /    @IBOutlet var settingsTable: /' \
      -e "$ALIASES" \
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
# The compiled xibs, at the bundle root where both `UINib(nibName:bundle:nil)`
# and UIViewController's class-named nib lookup expect them. These are the same
# fixtures the port reads (scripts/compile_realapp_nibs.sh), so neither oracle
# gets a differently-compiled archive.
cp fixtures/realapp/nibs/*.nib "$APP/"
rm -rf "$TMPSRC"

# iPhone 16 is the golden device (393x852 @3x); REALAPP_DEVICE exists so a
# probe can re-capture the same screens at another width without disturbing
# it — the layout dumps carry `layoutMargins`, and a margin that varies with
# width can only be caught by asking twice. A non-default device writes to
# whatever outdir the caller names; it must not be the golden one.
#
# Pad rows (`realapp_settings_light_ipad`, `realapp_history_light_ipad`,
# `realapp_storage_light_ipad`) capture on a private
# "iPad (A16)" (820×1180 @2x). The probe itself skips rows whose idiom
# does not match the booted device, so the two launches do not overwrite
# each other's goldens.
boot_and_capture() {
  local DEVTYPE_SHORT=$1
  local NAME_INFIX=$2
  local DEVNAME="OpenUIKit-Chrome${NAME_INFIX:+-$NAME_INFIX}${SIM_DEVICE_SUFFIX:-}"
  local DEVTYPE="com.apple.CoreSimulator.SimDeviceType.${DEVTYPE_SHORT}"
  local RUNTIME
  RUNTIME=$(xcrun simctl list runtimes | grep -o 'com.apple.CoreSimulator.SimRuntime.iOS-26[0-9-]*' | tail -1)
  local UDID
  UDID=$(xcrun simctl list devices | grep "$DEVNAME" | grep -o '[0-9A-F-]\{36\}' | head -1)
  if [[ -z "$UDID" ]]; then
    UDID=$(xcrun simctl create "$DEVNAME" "$DEVTYPE" "$RUNTIME")
  fi
  local STATE
  STATE=$(xcrun simctl list devices | grep "$UDID" | grep -o '(Booted)' || true)
  if [[ -z "$STATE" ]]; then
    xcrun simctl boot "$UDID"
    xcrun simctl bootstatus "$UDID"
  fi
  xcrun simctl uninstall "$UDID" com.openuikit.realappprobe 2>/dev/null || true
  xcrun simctl install "$UDID" "$APP"
  local CONTAINER
  CONTAINER=$(xcrun simctl get_app_container "$UDID" com.openuikit.realappprobe data)
  rm -f "$CONTAINER"/Documents/* 2>/dev/null || true
  xcrun simctl launch --console-pty "$UDID" com.openuikit.realappprobe >/dev/null || true
  local i
  for i in {1..90}; do [[ -f "$CONTAINER/Documents/DONE" ]] && break; sleep 1; done
  [[ -f "$CONTAINER/Documents/DONE" ]] || { echo "realapp_probe_sim: no DONE marker on $DEVNAME"; exit 1; }
  cp "$CONTAINER"/Documents/*.png "$CONTAINER"/Documents/*.json "$OUTDIR"/
  echo "goldens from $DEVNAME -> $OUTDIR"
}

if [[ -n "${REALAPP_DEVICE:-}" ]]; then
  boot_and_capture "$REALAPP_DEVICE" "$REALAPP_DEVICE"
else
  boot_and_capture "iPhone-16" ""
  boot_and_capture "iPad-A16" "iPad-A16"
fi
echo "goldens in $OUTDIR:"; ls "$OUTDIR"
