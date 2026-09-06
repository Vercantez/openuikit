# ColorSync (Linux starting point)

This directory is a clean-room Linux starting point for Apple's public
`ColorSync` module, seeded from the Xcode 26.1 iPhoneOS 26.1 symbol graph
and API digester. It implements ICC.1 profile parse/serialize, named
matrix RGB profiles, tag mutation, and 8-bit RGB matrix transforms.

## What is real

- **207 / 207** public precise IDs are `implemented`, each cited to a
  focused `test*` (see Depth pass below).
- `ColorSyncAlphaInfo` / `ColorSyncDataDepth` raw values match
  ColorSyncTransform.h (`kColorSyncAlphaNone = 0` … SkipFirst = 6;
  `kColorSync1BitGamut = 1` … `kColorSync10BitInteger = 8`).
- Byte-order masks match the documented shifts (`0x1F`, `0x7000`,
  `1<<12` … `4<<12`).
- Named profile CFStrings use the `com.apple.ColorSync.*` payloads from
  ColorSyncProfile.h comments. ICC `kColorSyncSig*` constants are the
  four-character ICC.1 codes (`desc`, `rXYZ`, `RGB `, …).
- `ColorSyncProfileCreate` parses ICC `acsp` files. `CreateWithName`
  builds matrix RGB (sRGB, Display P3, Adobe RGB, BT.709/2020, …),
  gray TRC, Lab/XYZ space, and a minimal CMYK printer profile.
- `ColorSyncProfileGetMD5` follows the ICC Profile ID rule (flags,
  rendering intent, and Profile ID fields zeroed).
- `ColorSyncTransformConvert` performs 8-bit integer RGB matrix
  conversion (identity sRGB round-trips; sRGB→Display P3 stays red).

## Fail-closed boundaries

- `ColorSyncCreateCodeFragment` and
  `kColorSyncTransformFullConversionData` return nil: Apple CMM JIT
  fragments are not fabricated.
- Non-8-bit `ColorSyncTransformConvert` depths return `false`.
- Missing URLs and truncated ICC data set
  `com.apple.ColorSync.error` (portable codes; Darwin domain is an
  oracle question).
- No display-device or ColorSync-daemon profiles.

## Depth pass 2026-09

Implemented count: **207 / 207**.

Top-5 evidence distribution (implemented rows citing each test):

1. `testICCSignatureConstantPayloads` — 40
2. `testTransformKeyConstantPayloads` — 31
3. `testCMMCodeFragmentConstantPayloads` — 20
4. `testNamedProfileConstantPayloads` — 15
5. `testColorSyncDataDepthRawValues` — 15

Enum/option-set members and C `k…` constants share table-driven value
tests. Remaining function/type rows use focused tests well below a
40% bulk-relabel share.

## Still deferred / oracle

See `oracle-questions.tsv`: Darwin CFString payloads for transform
option keys without CFSTR comments, Apple CMM code-fragment shape,
exact `EstimateGamma` / `IsWideGamut` thresholds, and CFError domain.

## Sealed gate

`bash tests/acceptance/test_host.sh` in this Linux environment ended:

```
FRAMEWORK_FANOUT_DELIVERABLE_OK module=ColorSync lane=medium-full symbols=207
FRAMEWORK_FANOUT_REFERENCE_OK
COLORSYNC_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=ColorSync dylib=libColorSync.dylib
```

`swiftc` is Swift 6.2.4 / `x86_64-unknown-linux-gnu`. The campaign
inventory stamp `CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean`
is a host-inventory token. `.cursor/verify-cloud-environment.sh` on this
snapshot fails earlier (`missing corpus checkout: scratch/ladder-corpus/focus-ios`;
Cursor Build `bld-20260906-253cd433-7a30-4d11-aad2-8b209b7b2d21` vs seed
`bld-20260901-d3266600-d87b-438f-94c1-d1aa48036e87`). The sealed gate
compiled with a clean product tree and did not weaken the host script.

Run `bash tests/acceptance/test_host.sh` from this directory. Keep
generated products out of the tree.
