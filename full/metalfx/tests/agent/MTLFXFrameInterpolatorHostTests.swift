import Foundation
import MetalFX

func testFrameInterpolatorHostSnapshotsDescriptor() {
    let descriptor = MTLFXFrameInterpolatorDescriptor()
    descriptor.colorTextureFormat = .rgba8Unorm
    descriptor.depthTextureFormat = .depth32Float
    descriptor.motionTextureFormat = .rg16Float
    descriptor.outputTextureFormat = .bgra8Unorm
    descriptor.uiTextureFormat = .bgra8Unorm
    descriptor.inputWidth = 16
    descriptor.inputHeight = 9
    descriptor.outputWidth = 32
    descriptor.outputHeight = 18
    let interpolator = descriptor.host_makeSoftwareFrameInterpolator()
    precondition(interpolator.colorTextureFormat == .rgba8Unorm)
    precondition(interpolator.depthTextureFormat == .depth32Float)
    precondition(interpolator.motionTextureFormat == .rg16Float)
    precondition(interpolator.outputTextureFormat == .bgra8Unorm)
    precondition(interpolator.uiTextureFormat == .bgra8Unorm)
    precondition(interpolator.inputWidth == 16)
    precondition(interpolator.inputHeight == 9)
    precondition(interpolator.outputWidth == 32)
    precondition(interpolator.outputHeight == 18)
    precondition(interpolator.colorTextureUsage == .unknown)
    precondition(interpolator.depthTextureUsage == .unknown)
    precondition(interpolator.motionTextureUsage == .unknown)
    precondition(interpolator.outputTextureUsage == .unknown)
    precondition(interpolator.uiTextureUsage == .unknown)
    precondition(interpolator.aspectRatio == 1)
    precondition(interpolator.deltaTime == 0)
    precondition(interpolator.nearPlane == 0)
    precondition(interpolator.farPlane == 0)
    precondition(interpolator.fieldOfView == 0)
    precondition(interpolator.shouldResetHistory == false)
    precondition(interpolator.isDepthReversed == false)
    precondition(interpolator.isUITextureComposited == false)
}

func testFrameInterpolatorHostMutableState() {
    var interpolator: any MTLFXFrameInterpolator =
        MTLFXFrameInterpolatorDescriptor().host_makeSoftwareFrameInterpolator()
    let color = MetalFXHostTexture(width: 4, height: 4, pixelFormat: .rgba8Unorm)
    let prev = MetalFXHostTexture(width: 4, height: 4, pixelFormat: .rgba8Unorm)
    let depth = MetalFXHostTexture(width: 4, height: 4, pixelFormat: .depth32Float)
    let motion = MetalFXHostTexture(width: 4, height: 4, pixelFormat: .rg16Float)
    let ui = MetalFXHostTexture(width: 8, height: 8, pixelFormat: .bgra8Unorm)
    let output = MetalFXHostTexture(width: 8, height: 8, pixelFormat: .bgra8Unorm)
    let fence = MetalFXHostFence()
    interpolator.colorTexture = color
    interpolator.prevColorTexture = prev
    interpolator.depthTexture = depth
    interpolator.motionTexture = motion
    interpolator.uiTexture = ui
    interpolator.outputTexture = output
    interpolator.fence = fence
    interpolator.aspectRatio = 1.777
    interpolator.deltaTime = 0.016
    interpolator.nearPlane = 0.1
    interpolator.farPlane = 100
    interpolator.fieldOfView = 1.2
    interpolator.jitterOffsetX = 0.3
    interpolator.jitterOffsetY = 0.4
    interpolator.motionVectorScaleX = 6
    interpolator.motionVectorScaleY = 7
    interpolator.shouldResetHistory = true
    interpolator.isDepthReversed = true
    interpolator.isUITextureComposited = true
    precondition(interpolator.colorTexture === color)
    precondition(interpolator.prevColorTexture === prev)
    precondition(interpolator.depthTexture === depth)
    precondition(interpolator.motionTexture === motion)
    precondition(interpolator.uiTexture === ui)
    precondition(interpolator.outputTexture === output)
    precondition(interpolator.fence === fence)
    precondition(interpolator.aspectRatio == 1.777)
    precondition(interpolator.deltaTime == 0.016)
    precondition(interpolator.nearPlane == 0.1)
    precondition(interpolator.farPlane == 100)
    precondition(interpolator.fieldOfView == 1.2)
    precondition(interpolator.jitterOffsetX == 0.3)
    precondition(interpolator.jitterOffsetY == 0.4)
    precondition(interpolator.motionVectorScaleX == 6)
    precondition(interpolator.motionVectorScaleY == 7)
    precondition(interpolator.shouldResetHistory)
    precondition(interpolator.isDepthReversed)
    precondition(interpolator.isUITextureComposited)
}

func testFrameInterpolatorHostEncodeInert() {
    var interpolator: any MTLFXFrameInterpolator =
        MTLFXFrameInterpolatorDescriptor().host_makeSoftwareFrameInterpolator()
    let output = MetalFXHostTexture(width: 2, height: 2, pixelFormat: .bgra8Unorm, fill: 77)
    interpolator.outputTexture = output
    let commandBuffer = MetalFXHostCommandBuffer(device: MetalFXHostDevice())
    interpolator.encode(commandBuffer: commandBuffer)
    precondition(commandBuffer.encodeCallCount == 1)
    precondition(output.mutationCount == 0)
    precondition(output.bytes.allSatisfy { $0 == 77 })
}

func testMetal4FrameInterpolatorHostEncodeInert() {
    var interpolator: any MTL4FXFrameInterpolator =
        MTLFXFrameInterpolatorDescriptor().host_makeSoftwareMetal4FrameInterpolator()
    let output = MetalFXHostTexture(width: 2, height: 2, pixelFormat: .bgra8Unorm, fill: 12)
    interpolator.outputTexture = output
    let commandBuffer = MetalFXHostMTL4CommandBuffer(device: MetalFXHostDevice())
    interpolator.encode(commandBuffer: commandBuffer)
    precondition(commandBuffer.encodeCallCount == 1)
    precondition(output.mutationCount == 0)
    precondition(interpolator.uiTextureFormat == .invalid)
    precondition(interpolator.aspectRatio == 1)
}
