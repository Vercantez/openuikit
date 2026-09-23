// Portable CoreGraphics module identity for unchanged application imports.
//
// OpenCoreGraphics owns the software renderer and geometry implementation.
// This module deliberately re-exports that implementation under Apple's
// public framework name so application code never needs a source rewrite.

@_exported import OpenCoreGraphics

public typealias CGImage = OpenCoreGraphics.Bitmap
#if OPENUIKIT_GUEST
// The Linux-hosted Mach-O guest (full/scripts/build_full.sh, section
// "guest Apple-name Swift modules"): OpenUIKit already names the guest's
// CGContext (UIGraphicsRenderer.swift, `CGContext = Canvas` without Apple's
// CoreGraphics). A file that imports both UIKit and CoreGraphics must see ONE
// declaration, so it is re-exported, not re-declared (cg-unify phase 4,
// uikit/docs/agent_reports/cg-unify.md).
@_exported import typealias OpenUIKit.CGContext
#else
public typealias CGContext = OpenCoreGraphics.Canvas
#endif
public typealias CGPath = OpenCoreGraphics.Path
public typealias CGMutablePath = OpenCoreGraphics.Path
