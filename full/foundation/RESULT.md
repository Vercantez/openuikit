# FoundationEssentials port — the measured result

**Everything here is a number someone can re-derive; the scripts that produce
each one are named beside it.**

## Configuration, stated because it is part of the measurement's identity

| | |
|---|---|
| target | `arm64-apple-macos15.0` — `Package.swift:92` declares `.macOS("15")`, and `Mutex` is `@available(macOS 15)`. **This raises the deployment floor of everything that links the module**; do not diff it against a macos13 binary. |
| swift-foundation | `release/6.2.2`, `c6793ef` (HEAD carries **both** `swift-6.2.1-RELEASE` and `swift-6.2.2-RELEASE` — the module did not change between them) |
| swift-collections | **1.1.3**, `9bf03ff` — from `utils/update_checkout/update-checkout-config.json` @ `swift-6.2.2-RELEASE`, `branch-schemes["release/6.2.2"]`. NOT the `from: "1.1.0"` range in Package.swift, which admits 1.2.x. |
| flags | upstream's own, copied: `-package-name SwiftFoundation`, seven feature flags, three `AvailabilityMacro=FoundationPreview`; and NOT `-disable-implicit-string-processing-module-import` |
| `_FoundationCShims` | swift-foundation's own, via `-Xcc -fmodule-map-file=` (it otherwise resolves from the **Linux toolchain's** `/usr/lib/swift`) |
| `os` | `full/foundation/os-module/` — ours, three declarations, not Apple's overlay |
| file surface | 36 symbols stubbed by `fm_unimplemented.c`: 3 implemented, 1 delegated to upstream's own fallback, 32 loud-abort. **URL never reaches them; a stub firing during a run is itself a finding.** |

## Compile — `build_fe.sh`

**202 files, 0 errors.** `FoundationEssentials.o`: Mach-O 64-bit arm64,
12,152,024 bytes, 19,776 defined external symbols (111 `_SwiftURL`).
Sequence, none of it by subtraction: 1 → 1,581 → 115 → 108 → 0.

## URL oracle — 809 real literals from four shipping apps

Run **both** ways, and the two outputs are **byte-identical**:

| route | what it is | script |
|---|---|---|
| host | same 202 sources, Apple toolchain, Apple SDK, native macOS | `build_fe_host.sh` |
| guest | Mach-O under machorun on Linux, guest root `scratch/mrroot_fe` | `build_url_runner.sh` + `stage_swift_overlays.sh` |

```
scored                 809 of 809
pass                   802 of 802 non-IDNA rows
fail                   0 of 802 non-IDNA rows
expected-fail (IDNA)   7 of 7 confirmed failing
IDNA rows that matched 0 of 7   (must be 0)
```

**What it means, stated precisely.** The golden came from Foundation's `URL`,
which on Darwin is runtime-flag-selected and normally `_BridgedURL`
(NSURL-backed). This is `_SwiftURL`. So 802/802 is a **cross-implementation
agreement**, not a self-test.

**What it is NOT.** The two binaries are different — different toolchains,
different SDKs, and the guest links `libswiftcompat` while the host does not.
So this is not a same-bytes-both-sides gate. **The golden JSON is the oracle**,
which is what makes the comparison meaningful without identical bytes.

**Teeth, both checked rather than assumed.** The same guest binary run WITHOUT
machorun gives `exec format error`, exit 255 — so that scoreboard could only
have come from the loader. And a truncated corpus makes the runner die
(exit 133) rather than print a scoreboard.
