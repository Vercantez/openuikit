import Foundation

public class CIKernel: @unchecked Sendable {
    public let name: String

    public init(name: String = "CIKernel") {
        self.name = name
    }

    public convenience init?(source string: String) {
        _ = string
        return nil
    }

    public convenience init?(string: String) {
        self.init(source: string)
    }

    public convenience init(functionName name: String, fromMetalLibraryData data: Data) throws {
        _ = (name, data)
        throw CIRenderError.unsupported
    }

    public convenience init(
        functionName name: String,
        fromMetalLibraryData data: Data,
        outputPixelFormat format: CIFormat
    ) throws {
        _ = format
        try self.init(functionName: name, fromMetalLibraryData: data)
    }

    public class func kernelNames(fromMetalLibraryData data: Data) -> [String] {
        _ = data
        return []
    }

    public class func kernels(withMetalString source: String) throws -> [CIKernel] {
        _ = source
        throw CIRenderError.unsupported
    }

    public class func makeKernels(source string: String) -> [CIKernel]? {
        _ = string
        return nil
    }

    public func apply(
        extent: CGRect,
        roiCallback callback: @escaping CIKernelROICallback,
        arguments args: [Any]
    ) -> CIImage? {
        _ = (extent, callback, args)
        return nil
    }
}

public class CIColorKernel: CIKernel, @unchecked Sendable {
    public convenience init?(source string: String) {
        _ = string
        return nil
    }

    public func apply(extent: CGRect, arguments args: [Any]) -> CIImage? {
        _ = (extent, args)
        return nil
    }
}

public class CIWarpKernel: CIKernel, @unchecked Sendable {
    public convenience init?(source string: String) {
        _ = string
        return nil
    }

    public func apply(
        extent: CGRect,
        roiCallback callback: @escaping CIKernelROICallback,
        image: CIImage,
        arguments args: [Any]
    ) -> CIImage? {
        _ = (extent, callback, image, args)
        return nil
    }
}

public class CIBlendKernel: CIKernel, @unchecked Sendable {
    public convenience init?(source string: String) {
        _ = string
        return nil
    }

    public func apply(foreground: CIImage, background: CIImage) -> CIImage? {
        if name == "sourceOver" {
            return foreground.composited(over: background)
        }
        return nil
    }

    public func apply(
        foreground: CIImage,
        background: CIImage,
        colorSpace: CGColorSpace
    ) -> CIImage? {
        _ = colorSpace
        return apply(foreground: foreground, background: background)
    }

    public static let clear = CIBlendKernel(name: "clear")
    public static let color = CIBlendKernel(name: "color")
    public static let colorBurn = CIBlendKernel(name: "colorBurn")
    public static let colorDodge = CIBlendKernel(name: "colorDodge")
    public static let componentAdd = CIBlendKernel(name: "componentAdd")
    public static let componentMax = CIBlendKernel(name: "componentMax")
    public static let componentMin = CIBlendKernel(name: "componentMin")
    public static let componentMultiply = CIBlendKernel(name: "componentMultiply")
    public static let darken = CIBlendKernel(name: "darken")
    public static let darkerColor = CIBlendKernel(name: "darkerColor")
    public static let destination = CIBlendKernel(name: "destination")
    public static let destinationAtop = CIBlendKernel(name: "destinationAtop")
    public static let destinationIn = CIBlendKernel(name: "destinationIn")
    public static let destinationOut = CIBlendKernel(name: "destinationOut")
    public static let destinationOver = CIBlendKernel(name: "destinationOver")
    public static let difference = CIBlendKernel(name: "difference")
    public static let divide = CIBlendKernel(name: "divide")
    public static let exclusion = CIBlendKernel(name: "exclusion")
    public static let exclusiveOr = CIBlendKernel(name: "exclusiveOr")
    public static let hardLight = CIBlendKernel(name: "hardLight")
    public static let hardMix = CIBlendKernel(name: "hardMix")
    public static let hue = CIBlendKernel(name: "hue")
    public static let lighten = CIBlendKernel(name: "lighten")
    public static let lighterColor = CIBlendKernel(name: "lighterColor")
    public static let linearBurn = CIBlendKernel(name: "linearBurn")
    public static let linearDodge = CIBlendKernel(name: "linearDodge")
    public static let linearLight = CIBlendKernel(name: "linearLight")
    public static let luminosity = CIBlendKernel(name: "luminosity")
    public static let multiply = CIBlendKernel(name: "multiply")
    public static let overlay = CIBlendKernel(name: "overlay")
    public static let pinLight = CIBlendKernel(name: "pinLight")
    public static let saturation = CIBlendKernel(name: "saturation")
    public static let screen = CIBlendKernel(name: "screen")
    public static let softLight = CIBlendKernel(name: "softLight")
    public static let source = CIBlendKernel(name: "source")
    public static let sourceAtop = CIBlendKernel(name: "sourceAtop")
    public static let sourceIn = CIBlendKernel(name: "sourceIn")
    public static let sourceOut = CIBlendKernel(name: "sourceOut")
    public static let sourceOver = CIBlendKernel(name: "sourceOver")
    public static let subtract = CIBlendKernel(name: "subtract")
    public static let vividLight = CIBlendKernel(name: "vividLight")
}

public class CIImageProcessorKernel: @unchecked Sendable {
    public class var outputFormat: CIFormat { .RGBA8 }
    public class var outputIsOpaque: Bool { false }
    public class var synchronizeInputs: Bool { true }

    public class func formatForInput(at inputIndex: Int32) -> CIFormat {
        _ = inputIndex
        return .RGBA8
    }

    public class func outputFormat(at outputIndex: Int32, arguments: [String: Any]?) -> CIFormat {
        _ = (outputIndex, arguments)
        return .RGBA8
    }

    public class func roi(
        forInput inputIndex: Int32,
        arguments: [String: Any]?,
        outputRect: CGRect
    ) -> CGRect {
        _ = (inputIndex, arguments)
        return outputRect
    }

    public class func roiTileArray(
        forInput inputIndex: Int32,
        arguments: [String: Any]?,
        outputRect: CGRect
    ) -> [CIVector] {
        _ = (inputIndex, arguments)
        return [CIVector(cgRect: outputRect)]
    }

    public class func apply(
        withExtent extent: CGRect,
        inputs: [CIImage]?,
        arguments: [String: Any]?
    ) throws -> CIImage {
        _ = (extent, inputs, arguments)
        throw CIRenderError.unsupported
    }

    public class func apply(
        withExtents extents: [CIVector],
        inputs: [CIImage]?,
        arguments: [String: Any]?
    ) throws -> [CIImage] {
        _ = (extents, inputs, arguments)
        throw CIRenderError.unsupported
    }
}
