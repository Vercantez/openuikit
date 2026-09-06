import Foundation
import MetalFX

func testSpatialScalerHostSnapshotsDescriptor() {
    let descriptor = MTLFXSpatialScalerDescriptor()
    descriptor.colorProcessingMode = .linear
    descriptor.colorTextureFormat = .rgba8Unorm
    descriptor.outputTextureFormat = .bgra8Unorm
    descriptor.inputWidth = 320
    descriptor.inputHeight = 180
    descriptor.outputWidth = 640
    descriptor.outputHeight = 360
    let scaler = descriptor.host_makeSoftwareSpatialScaler()
    precondition(scaler.colorProcessingMode == .linear)
    precondition(scaler.colorTextureFormat == .rgba8Unorm)
    precondition(scaler.outputTextureFormat == .bgra8Unorm)
    precondition(scaler.inputWidth == 320)
    precondition(scaler.inputHeight == 180)
    precondition(scaler.outputWidth == 640)
    precondition(scaler.outputHeight == 360)
    precondition(scaler.colorTextureUsage == .unknown)
    precondition(scaler.outputTextureUsage == .unknown)
    precondition(scaler.inputContentWidth == 320)
    precondition(scaler.inputContentHeight == 180)
    precondition(scaler.colorTexture == nil)
    precondition(scaler.outputTexture == nil)
    precondition(scaler.fence == nil)
}

func testSpatialScalerHostMutableState() {
    var scaler: any MTLFXSpatialScaler = MTLFXSpatialScalerDescriptor().host_makeSoftwareSpatialScaler()
    let color = MetalFXHostTexture(width: 8, height: 8, pixelFormat: .rgba8Unorm, fill: 3)
    let output = MetalFXHostTexture(width: 16, height: 16, pixelFormat: .bgra8Unorm, fill: 9)
    let fence = MetalFXHostFence()
    fence.label = "spatial-fence"
    scaler.colorTexture = color
    scaler.outputTexture = output
    scaler.fence = fence
    scaler.inputContentWidth = 7
    scaler.inputContentHeight = 5
    precondition(scaler.colorTexture === color)
    precondition(scaler.outputTexture === output)
    precondition(scaler.fence === fence)
    precondition((scaler.fence as? MetalFXHostFence)?.label == "spatial-fence")
    precondition(scaler.inputContentWidth == 7)
    precondition(scaler.inputContentHeight == 5)
}

func testSpatialScalerHostEncodeInert() {
    var scaler: any MTLFXSpatialScaler = MTLFXSpatialScalerDescriptor().host_makeSoftwareSpatialScaler()
    let output = MetalFXHostTexture(width: 4, height: 4, pixelFormat: .rgba8Unorm, fill: 17)
    scaler.outputTexture = output
    let device = MetalFXHostDevice()
    let commandBuffer = MetalFXHostCommandBuffer(device: device)
    let before = output.bytes
    let mutations = output.mutationCount
    scaler.encode(commandBuffer: commandBuffer)
    precondition(commandBuffer.encodeCallCount == 1)
    precondition(output.mutationCount == mutations)
    precondition(output.bytes == before)
}

func testMetal4SpatialScalerHostEncodeInert() {
    var scaler: any MTL4FXSpatialScaler =
        MTLFXSpatialScalerDescriptor().host_makeSoftwareMetal4SpatialScaler()
    let output = MetalFXHostTexture(width: 2, height: 2, pixelFormat: .rgba8Unorm, fill: 4)
    scaler.outputTexture = output
    let device = MetalFXHostDevice()
    let commandBuffer = MetalFXHostMTL4CommandBuffer(device: device)
    scaler.encode(commandBuffer: commandBuffer)
    precondition(commandBuffer.encodeCallCount == 1)
    precondition(output.mutationCount == 0)
    precondition(output.bytes.allSatisfy { $0 == 4 })
    precondition(scaler.colorTextureFormat == .invalid)
    precondition(scaler.outputTextureUsage == .unknown)
}
