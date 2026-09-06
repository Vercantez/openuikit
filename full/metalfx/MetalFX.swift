import Foundation

/// Linux starting point for Apple's public `MetalFX` module.
///
/// Descriptor configuration, color-processing-mode raw values, and software
/// scaler *state* are real. Spatial/temporal upscale, denoising, frame
/// interpolation, and Metal 4 compiler paths require Apple GPU hardware and
/// stay fail-closed: `supportsDevice` / `supportsMetal4FX` are `false`,
/// factory methods return `nil`, and host software objects do not write
/// output textures.
public enum MTLFXSpatialScalerColorProcessingMode: Int, Equatable, Hashable, Sendable {
    case perceptual = 0
    case linear = 1
    case hdr = 2
}
