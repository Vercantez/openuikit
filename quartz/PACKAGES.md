# Agent packages

Each package owns a closed set of files. **Do not edit files owned by another package.** Shared files (`include/quartz/quartz.h`, `src/qz_internal.hpp`, `CMakeLists.txt`, `harness/main.cpp`) are frozen for package work unless the orchestrator updates them.

New CG/CA scenes: add `harness/scenes_<package>.cpp` and call `QZ_CG_SCENE` / `QZ_CA_SCENE` from `harness/registry.h`. Do not modify `harness/scenes.cpp` or `harness/scenes_ca.cpp`.

Pixel tests vs Apple: fill in `tests/test_<package>.mm`. Compare `CG*` / `CA*` against `QZ*` and print `PASS`/`FAIL`. Link already exists if the file is named `tests/test_*.mm`.

| Package | Own these files | Implement | Test vs Apple |
|---|---|---|---|
| **path-query** | `include/quartz/path_query.h`, `src/pkg_path_query.cpp`, `tests/test_path_query.mm`, `harness/scenes_path_query.cpp` (optional) | Bounding box, empty, current point, contains-point, copy, transform copy, equality | CGPath vs QZPath on the same commands |
| **color** | `include/quartz/color.h`, `src/pkg_color.cpp`, `tests/test_color.mm` | Color space (sRGB/DeviceRGB/Gray), CGColor-like objects, SetFill/StrokeColorWithColor | Fill a rect with QZColor vs CGColor |
| **image-ext** | `include/quartz/image_ext.h`, `src/pkg_image_ext.cpp`, `tests/test_image_ext.mm` | DrawTiledImage, ClipToMask, clip bounding box; honor nearest vs bilinear if you touch sampling | Tiled blit + mask clip vs CG |
| **layer-ext** | `include/quartz/layer_ext.h`, `src/pkg_layer_ext.cpp`, `tests/test_layer_ext.mm` | mask, contentsGravity, contentsRect/Scale, layer shadow, insert/remove sublayer, convertPoint | CALayer renderInContext vs QZLayer |
| **geom** | `include/quartz/geom.h`, `src/pkg_geom.cpp`, `tests/test_geom.mm` | CGRect/CGPoint/CGSize/CGAffine query algebra | Match CGGeometry numeric results |
| **path-stroke** | `include/quartz/path_stroke.h`, `src/pkg_path_stroke.cpp`, `tests/test_path_stroke.mm` | Copy by stroking/dashing, replace path with stroke, AddLines, StrokeLineSegments, FillRects | CGPathCreateCopyByStrokingPath pixel/bbox vs QZ |
| **shape-stroke** | `include/quartz/shape_stroke.h`, `src/pkg_shape_stroke.cpp`, `tests/test_shape_stroke.mm` | strokeStart/End, dash, miter on shape layers (hook paint in `qz_layer.cpp` only if required, keep localized) | CAShapeLayer vs QZShapeLayer |
| **gradient-ext** | `include/quartz/gradient_ext.h`, `src/pkg_gradient_ext.cpp`, `tests/test_gradient_ext.mm` | Conic gradient + gradient-layer conic flag | CGContextDrawConicGradient vs QZ |
| **context-misc** | `include/quartz/context_misc.h`, `src/pkg_context_misc.cpp`, `tests/test_context_misc.mm` | ResetClip, bitmap CreateImage, gray colors, user↔device convert, path query on context | CG vs QZ |
| **anim** | `include/quartz/animation.h`, `src/pkg_anim.cpp`, `tests/test_anim.mm` | CABasicAnimation-like from/to/duration; presentation copy at time t for opacity/position | CABasicAnimation + presentationLayer vs QZ |
| **text** | `include/quartz/text.h`, `src/pkg_text.cpp`, `tests/test_text.mm`, `harness/scenes_text.cpp` (optional) | SelectFont, text matrix/position, ShowTextAtPoint, CATextLayer. Fill glyph outlines via existing path rasterizer. May add `third_party/stb_truetype.h`. Hook `qz_pkg_paint_text_layer` already called from `qz_layer.cpp`. | CGContextShowTextAtPoint / CATextLayer renderInContext vs QZ. ASCII Helvetica. close≤8 ≥95% |
| **pattern** | `include/quartz/pattern.h`, `src/pkg_pattern.cpp`, `tests/test_pattern.mm`, `harness/scenes_pattern.cpp` (optional) | CGPattern tiling. Hook `qz_pkg_try_pattern_fill` already called from fill. Return true when a fill pattern is set. | CGContextSetFillPattern pixel match |
| **shading** | `include/quartz/shading.h`, `src/pkg_shading.cpp`, `tests/test_shading.mm` | CGFunction + axial/radial CGShading + DrawShading | CGContextDrawShading vs QZ |
| **path-apply** | `include/quartz/path_apply.h`, `src/pkg_path_apply.cpp`, `tests/test_path_apply.mm` | CGPathApply element enumeration, AddArcToPoint/AddLines on path objects | CGPathApply element types/points vs QZ |
| **replicator** | `include/quartz/replicator.h`, `src/pkg_replicator.cpp`, `tests/test_replicator.mm`, `harness/scenes_replicator.cpp` (optional) | CAReplicatorLayer instanceCount/transform/color offsets. Hook `qz_pkg_replicator_sublayers` already called. | CAReplicatorLayer renderInContext vs QZ |
| **timing** | `include/quartz/timing.h`, `src/pkg_timing.cpp`, `tests/test_timing.mm` | CAMediaTimingFunction cubic-bezier solve; keyframe values/keyTimes. Side-table on QZAnimationRef — do not edit pkg_anim.cpp. | CAMediaTimingFunction + presentation at t vs QZ |
| **cglayer** | `include/quartz/cglayer.h`, `src/pkg_cglayer.cpp`, `tests/test_cglayer.mm` | CGLayerCreateWithContext, DrawLayerAtPoint/InRect | CGLayer vs QZ pixel blit |
| **pdf** | `include/quartz/pdf.h`, `src/pkg_pdf.cpp`, `tests/test_pdf.mm` | PDF context write + document read of our simple files; DrawPDFPage | Apple CGPDFDocument drawing our PDF vs QZ |
| **gstate-get** | `include/quartz/gstate_get.h`, `src/pkg_gstate_get.cpp`, `tests/test_gstate_get.mm` | CGContextGetLineWidth/Alpha/BlendMode/… | numeric vs CG getters |
| **cmyk** | `include/quartz/cmyk.h`, `src/pkg_cmyk.cpp`, `tests/test_cmyk.mm` | DeviceCMYK + SetCMYKFill/Stroke | pixel vs CG SetCMYKFillColor |
| **image-io** | `include/quartz/image_io.h`, `src/pkg_image_io.cpp`, `tests/test_image_io.mm` | PNG/JPEG load via stb_image | CGImageSource vs QZ draw |
| **font-ext** | `include/quartz/font_ext.h`, `src/pkg_font_ext.cpp`, `tests/test_font_ext.mm` | CGFont metrics + ShowGlyphsAtPoint | CTFont/CGFont vs QZ |
| **transform-layer** | `include/quartz/transform_layer.h`, `src/pkg_transform_layer.cpp`, `tests/test_transform_layer.mm` | CATransformLayer flatten | renderInContext vs QZ |
| **color-p3** | `include/quartz/color_p3.h`, `src/pkg_color_p3.cpp`, `tests/test_color_p3.mm` | Display P3 → sRGB | CG DisplayP3 fills vs QZ |
| **trans-rect** | `include/quartz/trans_rect.h`, `src/pkg_trans_rect.cpp`, `tests/test_trans_rect.mm` | BeginTransparencyLayerWithRect | CG vs QZ |

`include/quartz/quartz.h` already `#include`s package headers. Implementations may use `src/qz_internal.hpp`.

Build: `cmake --build build -j`. Run package test: `./build/test_<package>`. Run painter suite: `./build/qzcompare --suite cg` / `--suite ca`.
