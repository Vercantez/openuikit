import Foundation

extension vImage.Planar8: PixelFormat, SinglePlanePixelFormat, StaticPixelFormat, InitializableFromCGImage {}
extension vImage.PlanarF: PixelFormat, SinglePlanePixelFormat, StaticPixelFormat, InitializableFromCGImage {}
extension vImage.Planar16F: PixelFormat, SinglePlanePixelFormat, StaticPixelFormat, InitializableFromCGImage {}
extension vImage.Planar16U: PixelFormat, SinglePlanePixelFormat, StaticPixelFormat {}
extension vImage.Planar8x2: PixelFormat, MultiplePlanePixelFormat {}
extension vImage.Planar8x3: PixelFormat, MultiplePlanePixelFormat {}
extension vImage.Planar8x4: PixelFormat, MultiplePlanePixelFormat {}
extension vImage.PlanarFx2: PixelFormat, MultiplePlanePixelFormat {}
extension vImage.PlanarFx3: PixelFormat, MultiplePlanePixelFormat {}
extension vImage.PlanarFx4: PixelFormat, MultiplePlanePixelFormat {}
extension vImage.Interleaved8x2: PixelFormat, SinglePlanePixelFormat {}
extension vImage.Interleaved8x3: PixelFormat, SinglePlanePixelFormat, InitializableFromCGImage {}
extension vImage.Interleaved8x4: PixelFormat, SinglePlanePixelFormat, InitializableFromCGImage {}
extension vImage.InterleavedFx2: PixelFormat, SinglePlanePixelFormat {}
extension vImage.InterleavedFx3: PixelFormat, SinglePlanePixelFormat, InitializableFromCGImage {}
extension vImage.InterleavedFx4: PixelFormat, SinglePlanePixelFormat, InitializableFromCGImage {}
extension vImage.Interleaved16Fx2: PixelFormat, SinglePlanePixelFormat {}
extension vImage.Interleaved16Fx4: PixelFormat, SinglePlanePixelFormat, InitializableFromCGImage {}
extension vImage.Interleaved16Ux2: PixelFormat, SinglePlanePixelFormat, InitializableFromCGImage {}
extension vImage.Interleaved16Ux4: PixelFormat, SinglePlanePixelFormat, InitializableFromCGImage {}
extension vImage.DynamicPixelFormat: PixelFormat {}
