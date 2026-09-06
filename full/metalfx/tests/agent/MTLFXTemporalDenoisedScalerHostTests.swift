import Foundation
import MetalFX

func testTemporalDenoisedScalerHostSnapshotsDescriptor() {
    let descriptor = MTLFXTemporalDenoisedScalerDescriptor()
    descriptor.colorTextureFormat = .rgba16Float
    descriptor.depthTextureFormat = .depth32Float
    descriptor.motionTextureFormat = .rg16Float
    descriptor.diffuseAlbedoTextureFormat = .rgba8Unorm
    descriptor.specularAlbedoTextureFormat = .rgba8Unorm
    descriptor.normalTextureFormat = .rgba16Float
    descriptor.roughnessTextureFormat = .r16Float
    descriptor.specularHitDistanceTextureFormat = .r32Float
    descriptor.denoiseStrengthMaskTextureFormat = .r8Unorm
    descriptor.transparencyOverlayTextureFormat = .rgba8Unorm
    descriptor.outputTextureFormat = .rgba16Float
    descriptor.reactiveMaskTextureFormat = .r8Unorm
    descriptor.inputWidth = 48
    descriptor.inputHeight = 24
    descriptor.outputWidth = 96
    descriptor.outputHeight = 48
    let scaler = descriptor.host_makeSoftwareTemporalDenoisedScaler()
    precondition(scaler.colorTextureFormat == .rgba16Float)
    precondition(scaler.depthTextureFormat == .depth32Float)
    precondition(scaler.motionTextureFormat == .rg16Float)
    precondition(scaler.diffuseAlbedoTextureFormat == .rgba8Unorm)
    precondition(scaler.specularAlbedoTextureFormat == .rgba8Unorm)
    precondition(scaler.normalTextureFormat == .rgba16Float)
    precondition(scaler.roughnessTextureFormat == .r16Float)
    precondition(scaler.specularHitDistanceTextureFormat == .r32Float)
    precondition(scaler.denoiseStrengthMaskTextureFormat == .r8Unorm)
    precondition(scaler.transparencyOverlayTextureFormat == .rgba8Unorm)
    precondition(scaler.outputTextureFormat == .rgba16Float)
    precondition(scaler.reactiveMaskTextureFormat == .r8Unorm)
    precondition(scaler.inputWidth == 48)
    precondition(scaler.inputHeight == 24)
    precondition(scaler.outputWidth == 96)
    precondition(scaler.outputHeight == 48)
    precondition(scaler.inputContentMinScale == 1)
    precondition(scaler.inputContentMaxScale == 1)
    precondition(scaler.colorTextureUsage == .unknown)
    precondition(scaler.depthTextureUsage == .unknown)
    precondition(scaler.motionTextureUsage == .unknown)
    precondition(scaler.reactiveTextureUsage == .unknown)
    precondition(scaler.diffuseAlbedoTextureUsage == .unknown)
    precondition(scaler.specularAlbedoTextureUsage == .unknown)
    precondition(scaler.normalTextureUsage == .unknown)
    precondition(scaler.roughnessTextureUsage == .unknown)
    precondition(scaler.specularHitDistanceTextureUsage == .unknown)
    precondition(scaler.denoiseStrengthMaskTextureUsage == .unknown)
    precondition(scaler.transparencyOverlayTextureUsage == .unknown)
    precondition(scaler.outputTextureUsage == .unknown)
    precondition(scaler.preExposure == 1)
    precondition(scaler.shouldResetHistory == false)
    precondition(scaler.isDepthReversed == false)
    precondition(scaler.viewToClipMatrix == .identity)
    precondition(scaler.worldToViewMatrix == .identity)
}

func testTemporalDenoisedScalerHostMutableState() {
    let scaler: any MTLFXTemporalDenoisedScaler =
        MTLFXTemporalDenoisedScalerDescriptor().host_makeSoftwareTemporalDenoisedScaler()
    let color = MetalFXHostTexture(width: 2, height: 2, pixelFormat: .rgba16Float)
    let depth = MetalFXHostTexture(width: 2, height: 2, pixelFormat: .depth32Float)
    let motion = MetalFXHostTexture(width: 2, height: 2, pixelFormat: .rg16Float)
    let diffuse = MetalFXHostTexture(width: 2, height: 2, pixelFormat: .rgba8Unorm)
    let specular = MetalFXHostTexture(width: 2, height: 2, pixelFormat: .rgba8Unorm)
    let normal = MetalFXHostTexture(width: 2, height: 2, pixelFormat: .rgba16Float)
    let roughness = MetalFXHostTexture(width: 2, height: 2, pixelFormat: .r16Float)
    let hit = MetalFXHostTexture(width: 2, height: 2, pixelFormat: .r32Float)
    let mask = MetalFXHostTexture(width: 2, height: 2, pixelFormat: .r8Unorm)
    let overlay = MetalFXHostTexture(width: 2, height: 2, pixelFormat: .rgba8Unorm)
    let output = MetalFXHostTexture(width: 4, height: 4, pixelFormat: .rgba16Float)
    let exposure = MetalFXHostTexture(width: 1, height: 1, pixelFormat: .r16Float)
    let reactive = MetalFXHostTexture(width: 2, height: 2, pixelFormat: .r8Unorm)
    let fence = MetalFXHostFence()
    let custom = simd_float4x4(
        columns: (
            SIMD4<Float>(2, 0, 0, 0),
            SIMD4<Float>(0, 3, 0, 0),
            SIMD4<Float>(0, 0, 4, 0),
            SIMD4<Float>(0, 0, 0, 1)
        )
    )
    scaler.colorTexture = color
    scaler.depthTexture = depth
    scaler.motionTexture = motion
    scaler.diffuseAlbedoTexture = diffuse
    scaler.specularAlbedoTexture = specular
    scaler.normalTexture = normal
    scaler.roughnessTexture = roughness
    scaler.specularHitDistanceTexture = hit
    scaler.denoiseStrengthMaskTexture = mask
    scaler.transparencyOverlayTexture = overlay
    scaler.outputTexture = output
    scaler.exposureTexture = exposure
    scaler.reactiveMaskTexture = reactive
    scaler.fence = fence
    scaler.jitterOffsetX = 0.1
    scaler.jitterOffsetY = 0.2
    scaler.motionVectorScaleX = 4
    scaler.motionVectorScaleY = 5
    scaler.preExposure = 0.8
    scaler.shouldResetHistory = true
    scaler.isDepthReversed = true
    scaler.viewToClipMatrix = custom
    scaler.worldToViewMatrix = .zero
    precondition(scaler.colorTexture === color)
    precondition(scaler.depthTexture === depth)
    precondition(scaler.motionTexture === motion)
    precondition(scaler.diffuseAlbedoTexture === diffuse)
    precondition(scaler.specularAlbedoTexture === specular)
    precondition(scaler.normalTexture === normal)
    precondition(scaler.roughnessTexture === roughness)
    precondition(scaler.specularHitDistanceTexture === hit)
    precondition(scaler.denoiseStrengthMaskTexture === mask)
    precondition(scaler.transparencyOverlayTexture === overlay)
    precondition(scaler.outputTexture === output)
    precondition(scaler.exposureTexture === exposure)
    precondition(scaler.reactiveMaskTexture === reactive)
    precondition(scaler.fence === fence)
    precondition(scaler.jitterOffsetX == 0.1)
    precondition(scaler.jitterOffsetY == 0.2)
    precondition(scaler.motionVectorScaleX == 4)
    precondition(scaler.motionVectorScaleY == 5)
    precondition(scaler.preExposure == 0.8)
    precondition(scaler.shouldResetHistory)
    precondition(scaler.isDepthReversed)
    precondition(scaler.viewToClipMatrix == custom)
    precondition(scaler.worldToViewMatrix == .zero)
}

func testTemporalDenoisedScalerHostEncodeInert() {
    let scaler: any MTLFXTemporalDenoisedScaler =
        MTLFXTemporalDenoisedScalerDescriptor().host_makeSoftwareTemporalDenoisedScaler()
    let output = MetalFXHostTexture(width: 2, height: 2, pixelFormat: .rgba16Float, fill: 55)
    scaler.outputTexture = output
    let commandBuffer = MetalFXHostCommandBuffer(device: MetalFXHostDevice())
    scaler.encode(commandBuffer: commandBuffer)
    precondition(commandBuffer.encodeCallCount == 1)
    precondition(output.mutationCount == 0)
    precondition(output.bytes.allSatisfy { $0 == 55 })
}

func testTemporalDenoisedScalerConformsToFrameInterpolatable() {
    let scaler = MTLFXTemporalDenoisedScalerDescriptor().host_makeSoftwareTemporalDenoisedScaler()
    let interpolatable: any MTLFXFrameInterpolatableScaler = scaler
    precondition(interpolatable === scaler)
}

func testMetal4TemporalDenoisedScalerHostEncodeInert() {
    let scaler: any MTL4FXTemporalDenoisedScaler =
        MTLFXTemporalDenoisedScalerDescriptor().host_makeSoftwareMetal4TemporalDenoisedScaler()
    let output = MetalFXHostTexture(width: 1, height: 1, pixelFormat: .rgba16Float, fill: 8)
    scaler.outputTexture = output
    let commandBuffer = MetalFXHostMTL4CommandBuffer(device: MetalFXHostDevice())
    scaler.encode(commandBuffer: commandBuffer)
    precondition(commandBuffer.encodeCallCount == 1)
    precondition(output.mutationCount == 0)
    precondition(scaler.shouldResetHistory == false)
    precondition(scaler.viewToClipMatrix == .identity)
}
