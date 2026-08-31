// Portable CoreGraphics module identity for unchanged application imports.
//
// OpenCoreGraphics owns the software renderer and geometry implementation.
// This module deliberately re-exports that implementation under Apple's
// public framework name so application code never needs a source rewrite.

@_exported import OpenCoreGraphics

public typealias CGImage = OpenCoreGraphics.Bitmap
public typealias CGContext = OpenCoreGraphics.Canvas
public typealias CGPath = OpenCoreGraphics.Path
public typealias CGMutablePath = OpenCoreGraphics.Path
