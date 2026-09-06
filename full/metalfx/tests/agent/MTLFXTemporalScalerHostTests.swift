import Foundation
import MetalFX

func testTemporalScalerHostSnapshotsDescriptor() {
    let descriptor = MTLFXTemporalScalerDescriptor()
    descriptor.colorTextureFormat = .rgba8Unorm
    descriptor.depthTextureFormat = .depth32Float
    descriptor.motionTextureFormat = .rg16Float
    descriptor.outputTextureFormat = .bgra8Unorm
    descriptor.reactiveMaskTextureFormat = .r8Unorm
    descriptor.inputWidth = 100
    descriptor.inputHeight = 50
    descriptor.outputWidth = 200
    descriptor.outputHeight = 100
    descriptor.inputContentMinScale = 1.1
    descriptor.inputContentMaxScale = 2.2
    let scaler = descriptor.host_makeSoftwareTemporalScaler()
    precondition(scaler.colorTextureFormat == .rgba8Unorm)
    precondition(scaler.depthTextureFormat == .depth32Float)
    precondition(scaler.motionTextureFormat == .rg16Float)
    precondition(scaler.outputTextureFormat == .bgra8Unorm)
    precondition(scaler.reactiveMaskTextureFormat == .r8Unorm)
    precondition(scaler.inputWidth == 100)
    precondition(scaler.inputHeight == 50)
    precondition(scaler.outputWidth == 200)
    precondition(scaler.outputHeight == 100)
    precondition(scaler.inputContentWidth == 100)
    precondition(scaler.inputContentHeight == 50)
    precondition(scaler.inputContentMinScale == 1.1)
    precondition(scaler.inputContentMaxScale == 2.2)
    precondition(scaler.colorTextureUsage == .unknown)
    precondition(scaler.depthTextureUsage == .unknown)
    precondition(scaler.motionTextureUsage == .unknown)
    precondition(scaler.outputTextureUsage == .unknown)
    precondition(scaler.reactiveTextureUsage == .unknown)
    precondition(scaler.preExposure == 1)
    precondition(scaler.reset == false)
    precondition(scaler.isDepthReversed == false)
    precondition(scaler.jitterOffsetX == 0)
    precondition(scaler.jitterOffsetY == 0)
    precondition(scaler.motionVectorScaleX == 1)
    precondition(scaler.motionVectorScaleY == 1)
}

func testTemporalScalerHostMutableState() {
    var scaler: any MTLFXTemporalScaler =
        MTLFXTemporalScalerDescriptor().host_makeSoftwareTemporalScaler()
    let color = MetalFXHostTexture(width: 4, height: 4, pixelFormat: .rgba8Unorm)
    let depth = MetalFXHostTexture(width: 4, height: 4, pixelFormat: .depth32Float)
    let motion = MetalFXHostTexture(width: 4, height: 4, pixelFormat: .rg16Float)
    let output = MetalFXHostTexture(width: 8, height: 8, pixelFormat: .bgra8Unorm)
    let exposure = MetalFXHostTexture(width: 1, height: 1, pixelFormat: .r16Float)
    let reactive = MetalFXHostTexture(width: 4, height: 4, pixelFormat: .r8Unorm)
    let fence = MetalFXHostFence()
    scaler.colorTexture = color
    scaler.depthTexture = depth
    scaler.motionTexture = motion
    scaler.outputTexture = output
    scaler.exposureTexture = exposure
    scaler.reactiveMaskTexture = reactive
    scaler.fence = fence
    scaler.inputContentWidth = 3
    scaler.inputContentHeight = 2
    scaler.jitterOffsetX = 0.25
    scaler.jitterOffsetY = -0.5
    scaler.motionVectorScaleX = 2
    scaler.motionVectorScaleY = 3
    scaler.preExposure = 1.5
    scaler.reset = true
    scaler.isDepthReversed = true
    precondition(scaler.colorTexture === color)
    precondition(scaler.depthTexture === depth)
    precondition(scaler.motionTexture === motion)
    precondition(scaler.outputTexture === output)
    precondition(scaler.exposureTexture === exposure)
    precondition(scaler.reactiveMaskTexture === reactive)
    precondition(scaler.fence === fence)
    precondition(scaler.inputContentWidth == 3)
    precondition(scaler.inputContentHeight == 2)
    precondition(scaler.jitterOffsetX == 0.25)
    precondition(scaler.jitterOffsetY == -0.5)
    precondition(scaler.motionVectorScaleX == 2)
    precondition(scaler.motionVectorScaleY == 3)
    precondition(scaler.preExposure == 1.5)
    precondition(scaler.reset)
    precondition(scaler.isDepthReversed)
}

func testTemporalScalerHostEncodeInert() {
    var scaler: any MTLFXTemporalScaler =
        MTLFXTemporalScalerDescriptor().host_makeSoftwareTemporalScaler()
    let output = MetalFXHostTexture(width: 3, height: 3, pixelFormat: .rgba8Unorm, fill: 22)
    scaler.outputTexture = output
    let commandBuffer = MetalFXHostCommandBuffer(device: MetalFXHostDevice())
    scaler.encode(commandBuffer: commandBuffer)
    precondition(commandBuffer.encodeCallCount == 1)
    precondition(output.mutationCount == 0)
    precondition(output.bytes.allSatisfy { $0 == 22 })
}

func testTemporalScalerConformsToFrameInterpolatable() {
    let scaler = MTLFXTemporalScalerDescriptor().host_makeSoftwareTemporalScaler()
    let interpolatable: any MTLFXFrameInterpolatableScaler = scaler
    precondition(interpolatable === scaler)
}

func testMetal4TemporalScalerHostEncodeInert() {
    var scaler: any MTL4FXTemporalScaler =
        MTLFXTemporalScalerDescriptor().host_makeSoftwareMetal4TemporalScaler()
    let output = MetalFXHostTexture(width: 1, height: 1, pixelFormat: .rgba8Unorm, fill: 1)
    scaler.outputTexture = output
    let commandBuffer = MetalFXHostMTL4CommandBuffer(device: MetalFXHostDevice())
    scaler.encode(commandBuffer: commandBuffer)
    precondition(commandBuffer.encodeCallCount == 1)
    precondition(output.mutationCount == 0)
    precondition(scaler.reset == false)
    precondition(scaler.preExposure == 1)
}
