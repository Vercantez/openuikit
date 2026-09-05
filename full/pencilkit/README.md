# PencilKit (Linux starting point)

This is a clean-room Linux implementation of Apple's public `PencilKit`
surface for OpenUIKit. It is not Apple PencilKit. Isolated-host evidence
covers value types, enums, drawing archives, stroke-path interpolation, and
in-process canvas/tool-picker state. UI chrome, Apple Pencil hardware, and
Apple drawing bytes stay fail-closed.

## What is real

- **Ink and tools.** `PKInk`, `PKInkingTool`, `PKEraserTool`, and `PKLassoTool`
  are value types with equality, width clamping to `1...50`, and content
  versions derived from overlay availability (classic inks v1, iOS 17 inks v2,
  reed v4). ObjC reference classes wrap the same state.
- **Strokes.** `PKStrokePoint` / `PKStrokePath` / `PKStroke` store control
  points, seeds, and affine transforms. `PKStrokePath` is a
  `RandomAccessCollection`. Interpolation is **linear between adjacent control
  points** on parametric domain `[0, count-1]`; distance/time strides walk that
  polyline. This is not Apple's ink spline.
- **Drawings.** `PKDrawing` appends, transforms, and computes bounds as the
  union of stroke `renderBounds`. `dataRepresentation()` emits an `OPK1` JSON
  archive that `init(data:)` round-trips. `Codable` encodes that archive.
- **Canvas / picker state.** `PKCanvasView` keeps drawing, policy, ruler, and
  tool in-process. `allowsFingerDrawing` maps to `.anyInput` / `.pencilOnly`.
  `PKToolPicker` notifies observers, tracks visibility per first responder, and
  memoizes `shared(for:)` by window identity. Custom/inking/eraser/lasso/ruler/
  scribble items construct the corresponding tools.

## Fail-closed / not observed here

- **Apple `PKDrawing` bytes.** Any payload that does not start with `OPK1`
  throws `PKDrawingDataError.appleFormatUnsupported`. `init(coder:)` returns
  `nil`.
- **Rasterization.** `image(from:scale:)` returns a blank image of
  `rect.size * scale`. `draw(in:frame:from:darkUserInterfaceStyle:)` is
  declared only; tests cannot await it and Linux does not invent ink pixels.
- **UI chrome.** `frameObscured(in:)` is `.zero`. Gesture recognizers do not
  recognize. There is no pencil hardware, no system tool-picker overlay, and
  no light/dark ink remapping (`convertColor` returns the input).
- **Combine.** `PKStrokePath.publisher` is unavailable; Combine is not a
  declared dependency.
- **Host typealiases.** Isolated compilation uses `PencilKitColor` /
  `PencilKitView` / `PencilKitTransform` stand-ins behind those names. Guest
  builds `canImport(UIKit)` / `canImport(CoreGraphics)` bind them to the real
  modules. The types are not named `UIColor` / `UIView` in this module.

## Coverage

443 public precise identifiers: 424 `implemented`, 17 `declared`, 2
`unavailable`. The leaf-full floor is 355 nondeferred.

A future EC2 run must build guest Foundation and UIKit first and run
`tests/agent/PencilKitDependencyIdentity.swift` so real `UIColor` / `UIView` /
`UIWindow` values cross the PencilKit ABI. The isolated host gate is not that
run.

## Depth pass 2026-09

Fresh seed: sources, `coverage.tsv`, and `tests/agent` were created in this
run. Implemented count: **424**.

Top-5 evidence distribution (424 implemented rows):

| Citations | Share | Test |
| --- | --- | --- |
| 29 | 6.8% | `testPKStrokePathSliceMapFilter` |
| 26 | 6.1% | `testControlOptionsOptionSet` (option-set family; sharing allowed) |
| 26 | 6.1% | `testPKStrokePointDefaultsAndLerp` |
| 21 | 5.0% | `testPKToolPickerCustomItem` |
| 21 | 5.0% | `testInkTypeRawValuesAndWidths` (enum family; sharing allowed) |

No non-enum/option-set test is cited by more than 40% of the remaining
implemented rows (max 8.5% after excluding shareable enum/option-set rows).
