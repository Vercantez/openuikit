# Merge `origin/agent/merge-focus3` onto main (Network link)

MERGE TASK, no new rules. Main (`bd3881e2`) already carries lists /
linux-test-hygiene / the guest-route hygiene. `origin/agent/merge-focus3`
(`20b8c5d2`) is Blockzilla vendored as a library under `Sources/Blockzilla`
+ BlockzillaPackage, SnapKit + tests, the WebKit guest stub, Sentry /
Glean / Fuzi / libkern / os guest modules, FocusLaunchCompat, and the
RealAppProbe launch harness (report `merge-focus3.md`, 413 files).

The operator's Catalyst gate on that merge was green. The next step —
`swift build --build-tests` on the merged tree after
`swift build -c release --product openrender` in the same `.build`,
exactly as `scripts/agent_merge.sh` does — died twice with:

```
Internal Error: DecodingError.dataCorrupted: Data was corrupted. Debug description: Corrupted JSON. Underlying error: unexpected end of file
error: link command failed with exit code 1
```

(`~/openuikit/scratch/merge_focus46-merged.log`, `merge_focus2m-merged.log`;
the second run was alone on the machine). `agent_merge.sh` greps `error:`
and prints that JSON line first. The JSON is a red herring. The link is
the failure.

## The JSON SwiftPM / the driver failed to decode

Not a tree artefact. Not `Package.resolved`, not a Blockzilla path, not a
resource, not `golden.layout.json`, not a truncated `llbuild` description.

`/tmp/agent_merge_tests.log` (the operator's first run, `/private/tmp/agent_merge.G17Q`):

| line | what |
|---|---|
| `[598/608] Linking OpenUIKitPreviewMacros-tool` | plugin binary |
| `[748/871] Emitting module SwiftUITests` | next jobs compile `#Preview`-using tests |
| immediately after | `Internal Error: DecodingError.dataCorrupted: … Corrupted JSON. Underlying error: unexpected end of file` |
| `[749/871]` … `[1079/1092] Linking openrender` | **compile continued** |

The decoder is SwiftSyntax's `SwiftCompilerPluginMessageHandling`
(pin `4799286537280063c85a32f09884cfbca301b1a1`):

- `StandardIOMessageConnection`: each plugin IPC message is an **8-byte
  little-endian `UInt64` length** plus that many bytes of UTF-8 JSON
  (`StandardIOMessageConnection.swift:34–36`, `:130–140`, `:143–157`).
- `decodeFromJSON` (`JSON/JSONDecoding.swift:23–34`) wraps `JSONError`
  as `DecodingError.dataCorrupted` with debug description `"Corrupted JSON"`.
- `JSONError.unexpectedEndOfFile.description` is the exact
  `"unexpected end of file"` string (`JSONDecoding.swift:179–186`).
- A **0-byte** payload (`count == 0` after the length header, or a
  scanner on an empty buffer) hits `JSONError.unexpectedEndOfFile` at
  the first `hasData` / `ptr == endPtr` check (`JSONDecoding.swift:226`).

That empty frame is plugin teardown. `full/frameworks/CORE_GUEST_PACKAGE.md`
already records it: this SwiftSyntax revision predates
`f537808000a69e5acfa0b42c5de1ae5793e2c0c5`, which treats a zero-length
framed message as termination; without that check the host prints
`Internal Error:` / `Corrupted JSON` / `unexpected end of file`
**despite a successful compiler exit**. Same class, not a new rule.

`agent_merge.sh` `grep -E 'error:'` matches `Underlying error: unexpected
end of file` and stops at `TEST BUNDLE RED` before a human reads the
linker lines.

## The actual red: Network stub compiled, not linked

Same log, `[1079/1092] Linking openrender` and `Linking openhost`:

```
Undefined symbols for architecture arm64:
  "Network.IPv4Address.init(Swift.String) -> Network.IPv4Address?", referenced from:
      (extension in Blockzilla):Foundation.URL.isIPv4.getter : Swift.Bool in URLExtensions.swift.o
  "Network.IPv6Address.init(Swift.String) -> Network.IPv6Address?", referenced from:
      (extension in Blockzilla):Foundation.URL.isIPv6.getter : Swift.Bool in URLExtensions.swift.o
```

`Sources/Blockzilla/Blockzilla/Extensions/URLExtensions.swift:6` is
`import Network`; `:317` / `:324` are `IPv4Address(host)` /
`IPv6Address(host)`. The fail-closed stub
`Sources/Network/Network.swift` **defines** those inits. `--build-tests`
builds every product, so `Network.swift` compiled at `[139/247]`.
Blockzilla did **not** list `"Network"` in its target dependencies
(unlike `"os"`, which merge-focus2 already added for the same pattern:
`import os.log` compiled against the package `os` product and the
executable did not link it).

`--product openrender` alone never built the `Network` target, so
`import Network` resolved to Apple's Network.framework and autolinked.
That is why release openrender was green and debug `--build-tests` was
not, including when the machine was otherwise idle — not a
cross-process race.

## File resolutions

| file | how it was resolved |
|---|---|
| `uikit/docs/REAL_APP_TEST.md` | Only conflict. Union, newest-first: this merge; lists; focus3 hygiene / merge-focus2; then main's pickers / textkit / … |
| `uikit/Package.swift` | Auto-merged (main unchanged since merge-focus3's merge-base). Then `"Network"` appended to Darwin `blockzillaTargets` Blockzilla `dependencies`, next to `"os"`, with the measurement comment. |
| `Sources/Network/Network.swift` | Comment only: cites `/tmp/agent_merge_tests.log` `[139/247]` and the empty plugin frame. |

No other Swift conflict. Incoming Blockzilla / SnapKit / WebKit / stubs
landed as-is. No files outside `uikit/`. No pin files. No
`Package.resolved`.

`swift package describe --type json`: Blockzilla
`target_dependencies` now includes `Network`. Network
`product_memberships` includes `openrender`, `openhost`, `Blockzilla`.

## Proof (this merge)

Mac (`SIM_DEVICE_SUFFIX=-merge-focus4`):

- `time swift package describe --type json > /dev/null`: **0.197 s** (bar <20 s)
- `swift build -c release --product openrender`: **Build of product complete (169.46 s)**
- then `swift build --build-tests -v`: **Build complete (34.50 s)** — no
  `undefined symbol`, no `link command failed`. (The empty plugin frame
  did not reproduce on this incremental debug rebuild; it is non-fatal
  when it does.)
- `nm` debug and release `openrender` both define
  `_$s7Network11IPv4AddressVyACSgSScfC` /
  `_$s7Network11IPv6AddressVyACSgSScfC`
- `swift build --target Blockzilla`: **0 errors** (4.21 s)
- SnapKit **31/31** (+ 2 OpenUIKit helpers = 33); Glean/Sentry/Libkern/Fuzi **8/8**
- Catalyst **124/124** (`/tmp/gate-merge-focus4`)
- iOS suite `SKIP_CAPTURE=1` **112/113** (`corner_radius` 99.411)
- Real-app 3x floors **99.137 / 98.535 / 98.548 / 99.469 / 98.639 /
  98.133 / 97.516 / 99.65 / 82.17 / 99.86 / 99.734 / 85.393**
- `openrender realapp` **15** PNGs. `FocusBrowserLaunch.makeRoot()`
  `URLBar [0, 59, 393, 56]`, wordmark `UIImageView [44, 364.667, 305, 65.333]`
  (`/tmp/app-merge-focus4/realapp_focus_browser_light.layout.json`).
  `WKWebView` present. Browser golden **N/A**.

`docker run --rm … swift:6.2-noble` (tree tarred to `/work`, exclude
`.build` / `Package.resolved`):

- `swift package describe`: **0.953 s**
- `swift build -c release --product openrender`: **183.75 s**
- `swift build --target OpenUIKitTests`: **24.47 s**, 0 `error:`

Darwin `blockzillaTargets` is `#if !os(Linux)`. The Network dependency
does not change the Linux / guest graph. `full/scripts/build_full.sh`
was not re-run here (no `scratch/sysroot_fe4` in this worktree); guest
real-app stays **14** screens as merge-focus3 (browser is Darwin-only).

No new rendering rules. Catalyst paths stay behind the existing iOS cut.
The focus-launch measurements (URLBar / wordmark) are unchanged.
