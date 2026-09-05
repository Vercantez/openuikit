# fw-coreimage — CoreImage SDK depth (`full/coreimage`)

Worktree branch `agent/fw-coreimage`. Isolated Linux module `CoreImage`.
Did not edit `uikit/Sources/CoreImage`. Did not touch pins / `env/`.

## Before / after

| | before | after |
|---|---|---|
| implemented | 546 | **765** |
| declared | 219 | **0** |
| deferred | 90 | **0** |
| unavailable | 0 | **90** (Metal / EAGL / IOSurface / CVPixelBuffer / AV depth-matte / `CIImageProcessorInput`·`Output`) |
| total IDs | 855 | 855 |
| host gate | (seed compiled on Linux) | **`FRAMEWORK_FANOUT_HOST_OK`** in `swift:6.2-noble` |

Target was fully nondeferred and implemented ≥ 760. Hardware types that are not declared dependencies are **unavailable**, not deferred, matching `full/usernotifications`.

## Pixel oracle (iPhone SE 2x / iOS 26.1, software renderer)

Private device `SIM_DEVICE_SUFFIX=-fw-coreimage`. Capture `/tmp/ciprobe/`.

| measurement | golden | Linux after |
|---|---|---|
| CIGaussianBlur 32×32 radius 2 extent | (−6, −6, 44, 44) = pad **3×radius** | same (matches uikit `ciblurprobe`) |
| Rotate 4×2 +π/2 | (−2, 0, 2, 4) | same (ε 0.001 for `cos(π/2)`) |
| ColorControls sat 0 Rec.709 | red **54**, green **182**, blue **18** | same |
| Sepia intensity 1 | red **(76, 47, 12)**; 0.5 mix **(165, 23, 6)** | same |
| Exposure EV+1 sRGB gray 0.5 | (255, 255, 255) | same |
| ColorMatrix zero R vector | red → (0,0,0); green unchanged | same |
| PhotoEffect | 5³ cubes (affine 3×4 maxDelta 14–70) | trilinear on measured cubes; Chrome red **(255, 29, 0)** |
| QR `"HELLO WORLD"` M | **23×23** (v1 + **1-module quiet**), mask 0 | same extent + finder |
| Code 128 `"ABC-123"` | **132×52**, quiet 10, height 32 | same |
| PNG round-trip | — | 2×2 red, decode extent 2, R=255 |
| JPEG representation | — | SOI `FF D8` (encode-only; not a byte oracle) |
| Aztec / PDF417 `outputImage` | exist, not encoded | **nil** |
| `CIKernel(source:)` | — | **nil** |

## Rules (each cited next to the code)

- Blur extent pad = `3 * inputRadius` (ciprobe + uikit ciblurprobe).
- Sepia is the measured 3×3 in sRGB, mixed with identity by intensity — not the Wikipedia matrix.
- ColorControls: Rec.709 luma, then `(c−0.5)*contrast+0.5`, then additive brightness.
- Exposure: multiply by `2^EV` in working-space (sRGB).
- QR: ISO 18004 alphanumeric/byte, quiet **1**, versions 1–10, mask picked by penalty; HELLO WORLD M is v1 mask 0.
- Code 128: ISO 15417 set B, Start 104, checksum, Stop 106.

## Divergences vs `uikit/Sources/CoreImage` (sibling, not edited)

- **Surface:** full/coreimage implements the named color/geometry/barcode filters and PNG/JPEG; the uikit module is constant color + Gaussian blur, QR fail-closed.
- **`CIFormat.RGBA8`:** full/coreimage **6** (dotnet/macios); uikit **24**. Open in `oracle-questions.tsv`.
- **CG types:** isolated host uses module-local `CGImage` / `CGColorSpace` / `CGAffineTransform`. Defining `CGImage` poisons Apple's CoreGraphics overlay on the Mac compiler; Linux Foundation already has Swift `CGRect`. Overlay restored under `#if !os(Linux)`.
- **JPEG/PNG:** in-module stored-deflate PNG + baseline JPEG vs uikit `QZImageEncode*`.
- **Hue / Vibrance:** ciprobe bytes listed; Linux formulas are directional, not byte-identical (not a parameter search).

## Unavailable (honest, not deferred)

`CIContext` Metal/EAGL/CGContext factories, `CVPixelBuffer` / IOSurface render, `CIImage` CV/IOSurface/MTL/depth/matte inits, `CIImageProcessorInput`/`Output`, `NSUserActivity.detectedBarcodeDescriptor`. Notes name the missing dependency; no lookalikes.

## Open questions

See `full/coreimage/oracle-questions.tsv`: ARGB8 ABI, hue matrix, vibrance skin formula, linear working-space EV+1 = 175, QR `CIDetector` decode, CFString intern.

## Gates not in this tree

No OpenUIKit pixel rule. Catalyst / iOS suite / real-app floors are unchanged by this framework directory. Linux `swift:6.2-noble` compiled `libCoreImage.dylib` and ran every implemented coverage test.
