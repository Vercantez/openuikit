import CoreImage
import Foundation

func testCIRenderDestinationPropertyState() {
    var storage = [UInt8](repeating: 0, count: 64)
    storage.withUnsafeMutableBytes { raw in
        let dest = CIRenderDestination(
            bitmapData: raw.baseAddress!,
            width: 4,
            height: 4,
            bytesPerRow: 16,
            format: .RGBA8
        )
        dest.blendKernel = .sourceOver
        precondition(dest.blendKernel?.name == "sourceOver")
        dest.blendsInDestinationColorSpace = true
        precondition(dest.blendsInDestinationColorSpace)
        dest.captureTraceURL = URL(fileURLWithPath: "/tmp/ci-trace.gputrace")
        precondition(dest.captureTraceURL?.lastPathComponent == "ci-trace.gputrace")
        dest.isClamped = true
        precondition(dest.isClamped)
        dest.colorSpace = .sRGB
        precondition(dest.colorSpace?.name == "sRGB")
        dest.isDithered = true
        precondition(dest.isDithered)
        dest.isFlipped = true
        precondition(dest.isFlipped)
    }
    let gl = CIRenderDestination(glTexture: 9, target: 3553, width: 8, height: 5)
    precondition(gl.width == 8 && gl.height == 5)
    let gl2 = CIRenderDestination(GLTexture: 9, target: 3553, width: 8, height: 5)
    precondition(gl2.width == 8)
}

func testCIRenderInfoAndTaskWait() {
    let info = CIRenderInfo(
        kernelCompileTime: 0.125,
        kernelExecutionTime: 0.5,
        passCount: 2,
        pixelsProcessed: 64
    )
    precondition(type(of: info) == CIRenderInfo.self)
    precondition(info.kernelCompileTime == 0.125)
    precondition(info.kernelExecutionTime == 0.5)
    precondition(info.passCount == 2)
    precondition(info.pixelsProcessed == 64)
    let task = CIRenderTask()
    precondition(type(of: task) == CIRenderTask.self)
    let finished = try! task.waitUntilCompleted()
    precondition(finished.passCount == 0)
    precondition(finished.pixelsProcessed == 0)
}

func testCIContextWriteFailClosedAppleCodecs() {
    let context = CIContext()
    let image = CIImage(color: .red).cropped(to: CGRect(x: 0, y: 0, width: 1, height: 1))
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("fw-ci-failclosed")
    do {
        try context.writeTIFFRepresentation(of: image, to: url, format: .RGBA8, colorSpace: .sRGB)
        preconditionFailure("tiff")
    } catch {
        precondition((error as? CIRenderError) == .unsupported)
    }
    do {
        try context.writeHEIFRepresentation(of: image, to: url, format: .RGBA8, colorSpace: .sRGB)
        preconditionFailure("heif")
    } catch {
        precondition((error as? CIRenderError) == .unsupported)
    }
    do {
        try context.writeHEIF10Representation(of: image, to: url, colorSpace: .sRGB)
        preconditionFailure("heif10")
    } catch {
        precondition((error as? CIRenderError) == .unsupported)
    }
    do {
        try context.writeOpenEXRRepresentation(of: image, to: url)
        preconditionFailure("exr")
    } catch {
        precondition((error as? CIRenderError) == .unsupported)
    }
}

func testCIImageProcessorKernelROIAndFormat() {
    precondition(CIImageProcessorKernel.formatForInput(at: 0) == .RGBA8)
    precondition(CIImageProcessorKernel.outputFormat(at: 1, arguments: ["a": 1]) == .RGBA8)
    let rect = CGRect(x: 2, y: 3, width: 5, height: 7)
    let roi = CIImageProcessorKernel.roi(forInput: 0, arguments: nil, outputRect: rect)
    precondition(roi.origin.x == 2 && roi.height == 7)
    let tiles = CIImageProcessorKernel.roiTileArray(forInput: 0, arguments: nil, outputRect: rect)
    precondition(tiles.count == 1)
    precondition(tiles[0].cgRectValue.width == 5)
    do {
        _ = try CIImageProcessorKernel.apply(
            withExtents: [CIVector(cgRect: rect)],
            inputs: nil,
            arguments: nil
        )
        preconditionFailure("processor apply")
    } catch {
        precondition((error as? CIRenderError) == .unsupported)
    }
}

func testCIWarpKernelInvokesROICallback() {
    let warp = CIWarpKernel()
    precondition(type(of: warp) == CIWarpKernel.self)
    precondition(warp.name == "CIKernel")
    var seen = CGRect.null
    let color = CIImage(color: .green).cropped(to: CGRect(x: 0, y: 0, width: 3, height: 3))
    let result = warp.apply(
        extent: color.extent,
        roiCallback: { _, rect in
            seen = rect
            return rect
        },
        image: color,
        arguments: []
    )
    precondition(result == nil)
    precondition(seen.width == 3 && seen.height == 3)
}

func testCIKernelNameAndProvideImageData() {
    precondition(CIKernel(name: "cpuKernel").name == "cpuKernel")
    var buffer = [UInt8](repeating: 9, count: 16)
    buffer.withUnsafeMutableBytes { raw in
        NSObject().provideImageData(
            raw.baseAddress!,
            bytesPerRow: 8,
            origin: 0,
            0,
            size: 2,
            2,
            userInfo: nil
        )
    }
    precondition(buffer[0] == 9)
}
