# Focus guest Linux — fifteenth screen verified

Branch: `agent/focus-guest-linux`. Base: `71c8fc1e02271df7864a41d2687c368b7c1c0a08`.
Focus sources: `a2832521c1daa0c23419c73705ae043ed60c9791`.
The operator explicitly authorized `full/foundation/` and `full/dispatch/`
in addition to the original builder/appshim/focus scope. No vendor pin or
upstream application source was changed. The operator merges `full/` by hand.

**Complete:** the production guest build exits 0 and the verifier inside
`uikit-linux` renders **15** screens, preserves all **14/14** existing PNGs
byte-for-byte (including Ledger), and ends `REAL-APP SCREEN VERIFIED ON LINUX`.
The previous report's 53 primary Blockzilla diagnostics are resolved: all
131 vendored app/harness Swift files compile and link into the Mach-O guest.
The actual `AppDelegate` runs through `UIApplicationMain` and installs
`BrowserViewController`; the home-only fixture is not substituted.

## Guest graph and launch

`full/scripts/build_full.sh` now uses `compile_app_module` for SnapKit,
WebKit, Sentry, Fuzi, the adjunct framework/service boundaries, and Blockzilla.
The seven real BlockzillaPackage targets compile unchanged:

| target | shipping Swift files |
|---|---:|
| DesignSystem | 4 |
| Licenses | 2 |
| UIHelpers | 11 |
| UIComponents | 1 |
| Widget | 3 |
| AppShortcuts | 5 |
| Onboarding | 21 |

Preview Files are excluded. SnapKit's existing guest exclusion of
`Debugging.swift` is retained. Swift module aliases give Focus's real
DesignSystem and Licenses their own identities (`FocusDesignSystem`,
`FocusLicenses`), while the established fourteen-screen fixture modules keep
their identities. This also preserves Hackers' independent DesignSystem.
The real package object files are linked into the guest executable.

The builder stages the executable's existing `Sources/openrender/Info.plist`,
Focus's startup resources, the real package bundles, and the repository's
Swift 6.2.4 Observation runtime. The existing asset-catalog packager indexes
**63 DesignSystem assets, 0 unresolved, 44 payloads**, including the original
PDFs, which the existing CQuartz decoder rasterizes. The source catalogs are
copied byte-for-byte under `fixtures/realapp/focus-package`; no new painting
or layout rule was introduced.

Fuzi compiles its vendored sources and links unmodified libxml2 **2.9.13**
(archive SHA-256
`276130602d12fe484ecc03447ee5e759d0465558fbc9d6bd144e3745306ebf0e`).
The guest-local stateful hash-seed generator replaces the failed scratch
host-`rand_r` lookup. No loader boundary was weakened. The real parser matches
**64/64** native reference lines for every bundled default OpenSearch plugin.

## Foundation and Dispatch boundary

- Dispatch `sync` uses the existing checked host-queue bridge and real
  `dispatch_sync_f`. DispatchGroup owns a synchronized count, generation
  waiters, and notifications; timeout and reuse are exercised.
- The facade adds ObjCBool file-existence adaptation, sandbox-relative user
  search paths, temporary-directory lookup, UTF-16 NSRange conversion,
  Substring replacement, URL resource-value dictionaries, rectangle NSValue,
  scalar NSNumber copying, pasteboard URLs, and percent decoding.
- NSDictionary loads a schema-independent plist graph and participates in
  Swift Dictionary bridging. Its Objective-C subscript also supports the
  unchanged app's AnyObject lookup.
- UIKit exposes its Foundation-hidden activity-restoration/item-provider
  surfaces. Guest WebKit delivers its existing string-keypath notifications
  through the controller's overridable guest observer method. SwiftUI's final
  module exports the actual app-facing Foundation facade.
- Link-only NSDataDetector and the guest os_log spelling cover the called
  source surface. Keyed archive persistence explicitly throws Cocoa errors;
  file-backed item providers return nil. There is no haptic device and the
  system-sound boundary is silent. These are bounded unavailable services,
  not claims of full Apple Foundation/WebKit behavior.

The executable probes verify queue-specific sync, group notification/reuse/
timeout, plist load and bridge round-trip, scalar copying, directory lookup,
link matching, UTF-8 percent decoding, and rejected keyed archives.
`LaunchProbe` independently requires the real BrowserViewController root.
`BrowserInkProbe` calls the same `runRealApp` implementation as the production
renderer and enables missing-key logging only for the diagnostic process.

## Ink and image evidence

The earlier native harvest added **53** exact 2x keys. The Linux browser then
named three additional keys, harvested with `Tools/oracle2/inkprobe/main.swift`
on `OpenUIKit-2x-focus-guest-linux-ink`, iPhone SE 3rd generation, **iOS 26.1**:

| exact key | w, h, ox, oy |
|---|---|
| system-medium\|18\|light\|F0.0\|71 (G) | 23, 27, 2, -26 |
| system-medium\|18\|light\|F0.0\|87 (W) | 33, 26, 1, -26 |
| system-medium\|18\|light\|F0.5\|65 (A) | 23, 26, 1, -26 |

The probe reports **3/3**, `scale=2`, `calibration=opaque`, `skipped=[]`.
Final table: **9091 → 9147**. All original 9091 entries are unchanged.
The deliberate regular-17 F0.0 Q miss remains absent. Catalyst and 3x ink
files are untouched. The final guest browser census reports **0 misses**.

The Linux fixture is `fixtures/realapp/realapp_focus_browser_light.png`,
**786×1704**, screen **393×852 @2x**, containing URLBar and HomeViewToolbar.
This is launch/render evidence, not an Apple pixel-fidelity score. Existing
partly occluded chrome and the URL text canvas's non-finite coordinates remain
visible limitations shared with the earlier native launch. The realapp layout
serializer maps non-finite numbers to JSON null, matching native SceneIO;
it does not change view geometry or pixels.

`fixtures/realapp/linux-existing14.sha256` records the pre-change guest PNGs.
The verifier checks every one, including Ledger, without a comparison skip.
The browser fixture must also match the new guest run byte-for-byte.

## Verification

| check | result |
|---|---|
| final production `build_full.sh` | **exit 0**, `FOCUS_GUEST_BUILT`; source/resource and executable stamps written |
| `bash scripts/linux_realapp_verify.sh` inside `uikit-linux` | **15 screens**, **14/14 existing byte-identical**, browser fixture identical; `REAL-APP SCREEN VERIFIED ON LINUX` |
| Catalyst, final table | **124/124** |
| iOS 26.1 suite, final table | **112/113**, existing `corner_radius` **99.411** |
| native Linux `scripts/linux_verify.sh` | **178/178 byte-identical**, `PORTABILITY VERIFIED` |
| native corelibs realapp route, final inputs | **14 headless + 10 live**, success marker; **13+10** comparable PNGs identical |
| guest startup | `FOCUS_REAL_APPDELEGATE_LAUNCHED root=BrowserViewController` |
| guest boundary probes | passed |
| Fuzi default plugins | **64/64** native reference lines |
| post-harvest guest ink census | **0 misses** |

The native corelibs route remains fourteen headless screens plus ten live
frames; Objective-C Blockzilla runs through the full Mach-O guest route.
Its comparison now explicitly labels the browser as guest-only and Ledger's
Darwin/corelibs formatter comparison as omitted, instead of counting skipped
screens as byte-identical. The full guest verifier has neither omission.

## Reproduce

The existing private container support checkout is
`uikit-linux:/tmp/focus-guest-linux/support`. It contains the staged FE
sysroot, pinned swift-foundation/collections/ICU, OpenCombine, built machorun,
and Swift core runtime from the previous report. Build products are under
`build/full`, with runtime root `scratch/mrroot_full`. The previous setup used
clang/lld/LLVM 18 and the existing Foundation/Dispatch host-helper builders.
No Apple Foundation binary is loaded.

```sh
# inside uikit-linux, after staging this worktree's source inputs and committing
# the private uikit snapshot for the builder's vendor-tree preflight:
cd /tmp/focus-guest-linux/support
W=$PWD bash full/scripts/build_full.sh
cd uikit
bash scripts/linux_realapp_verify.sh /tmp/focus-guest-linux/final-verify
```

On Linux, the ordinary realapp script selects the full guest when its built
executable is present. `OPENUIKIT_REALAPP_MODE=native` retains the independent
corelibs route. External layouts can use `OPENUIKIT_REALAPP_GUEST_SUPPORT`,
`OPENUIKIT_REALAPP_GUEST_BUILD`, and `OPENUIKIT_REALAPP_GUEST_ROOT`.
The full verifier checks the build's source/resource digest and executable
SHA-256 before executing the probes and renderer. Production success stamps
are written only after the complete build passes its before/after checks.

Logs in the container: `final-production-build.log`, `final-verify/`,
`final-boundary.log`, `final-launch.log`, `final-fuzi.txt`, and `ink-final.log`
under `/tmp/focus-guest-linux/`. Native logs on the Mac use
`/tmp/focus-guest-linux-{catalyst-verified,ios-verified,native-portability,corelibs-final-inputs}.log`.

Final worktree and container source/resource digests are identical:
`f7118eb73aaa1259d23e297ff2b4d54d63f20b2100c01cf82f787a994ac8367a`.
No `Package.resolved` remains in the worktree. All changes are confined to
`uikit/` and the explicitly authorized `full/` paths.

Browser PNG SHA-256:
`831195a0d11d84aec434742fbce2ab7ce8164131a8043e7afcd4233fc543e21b`.
Final `render_full`: **36197152 bytes**, SHA-256
`6d705b2c8d82edfa73c560da59bfadb504b55fc2acefa7a6de7838ed7da45b32`.
