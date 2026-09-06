import Foundation

/// Linux starting point for Apple's public `Accelerate` module.
///
/// Host-compiled sources import Foundation only. The existing C box-convolve
/// implementation in `Accelerate.c` is preserved for guest/C oracles; the
/// isolated host gate compiles the Swift sources below, including a Swift
/// port of `vImageBoxConvolve_ARGB8888` that matches that C behavior.

public protocol AccelerateBuffer<Element> {
    associatedtype Element
    func withUnsafeBufferPointer<R>(
        _ body: (UnsafeBufferPointer<Element>) throws -> R
    ) rethrows -> R
}

extension AccelerateBuffer {
    public var count: Int {
        withUnsafeBufferPointer { $0.count }
    }
}

public protocol AccelerateMutableBuffer<Element>: AccelerateBuffer {
    mutating func withUnsafeMutableBufferPointer<R>(
        _ body: (inout UnsafeMutableBufferPointer<Element>) throws -> R
    ) rethrows -> R
}

public protocol AccelerateMatrixBuffer<Element> {
    associatedtype Element
    var rowCount: Int { get }
    var columnCount: Int { get }
    var leadingDimension: Int { get }
    var accelerateMatrixOrder: AccelerateMatrixOrder { get }
    func withUnsafeBufferPointer<R>(
        _ body: (UnsafeBufferPointer<Element>) throws -> R
    ) rethrows -> R
}

public protocol AccelerateMutableMatrixBuffer<Element>: AccelerateMatrixBuffer {
    mutating func withUnsafeMutableBufferPointer<R>(
        _ body: (inout UnsafeMutableBufferPointer<Element>) throws -> R
    ) rethrows -> R
}

@frozen public enum AccelerateMatrixOrder: Int, Sendable, Hashable {
    case rowMajor = 0
    case columnMajor = 1
}

public protocol BNNSScalar {
    static var bnnsDataType: BNNSDataType { get }
}

public protocol PixelFormat {
    associatedtype ComponentType: Equatable
    static var channelCount: Int { get }
}

extension PixelFormat {
    public static var channelCount: Int { 1 }
}

public protocol SinglePlanePixelFormat: PixelFormat {}

public protocol StaticPixelFormat: SinglePlanePixelFormat {}

public protocol MultiplePlanePixelFormat: PixelFormat {}

public protocol InitializableFromCGImage: SinglePlanePixelFormat {}

public protocol FusableLayerParameters {}

public protocol BNNSOptimizer {}

public protocol vDSP_IntegerConvertable {
    init<T: BinaryFloatingPoint>(_ value: T)
}
public protocol vDSP_FloatingPointConvertable {
    init<T: BinaryInteger>(_ value: T)
}
public protocol vDSP_FloatingPointGeneratable: BinaryFloatingPoint {}
public protocol vDSP_FourierTransformable {}
public protocol vDSP_DiscreteFourierTransformable {
    associatedtype DiscreteFourierTransformFunctions
}
public protocol vDSP_FloatingPointDiscreteFourierTransformable: BinaryFloatingPoint {
    associatedtype DiscreteFourierTransformFunctions
}
public protocol vDSP_FloatingPointBiquadFilterable: BinaryFloatingPoint {}
public protocol vDSP_DFTFunctions {
    static func destroySetup(_ setup: OpaquePointer)
}
public protocol vDSP_BiquadFunctions {}
public protocol vDSP_FourierTransformFunctions {}
public protocol vDSP_DiscreteTransformLifecycleFunctions {}

extension Array: AccelerateBuffer, AccelerateMutableBuffer {}
extension ArraySlice: AccelerateBuffer, AccelerateMutableBuffer {}
extension ContiguousArray: AccelerateBuffer, AccelerateMutableBuffer {}

extension UnsafeBufferPointer: AccelerateBuffer {
    public func withUnsafeBufferPointer<R>(
        _ body: (UnsafeBufferPointer<Element>) throws -> R
    ) rethrows -> R {
        try body(self)
    }
}

extension UnsafeMutableBufferPointer: AccelerateBuffer, AccelerateMutableBuffer {
    public func withUnsafeBufferPointer<R>(
        _ body: (UnsafeBufferPointer<Element>) throws -> R
    ) rethrows -> R {
        try body(UnsafeBufferPointer(self))
    }

    public mutating func withUnsafeMutableBufferPointer<R>(
        _ body: (inout UnsafeMutableBufferPointer<Element>) throws -> R
    ) rethrows -> R {
        var copy = self
        defer { self = copy }
        return try body(&copy)
    }
}

extension Int8: BNNSScalar, vDSP_IntegerConvertable {
    public static var bnnsDataType: BNNSDataType { BNNSDataTypeInt8 }
}
extension Int16: BNNSScalar, vDSP_IntegerConvertable {
    public static var bnnsDataType: BNNSDataType { BNNSDataTypeInt16 }
}
extension Int32: BNNSScalar, vDSP_IntegerConvertable {
    public static var bnnsDataType: BNNSDataType { BNNSDataTypeInt32 }
}
extension Int64: BNNSScalar {
    public static var bnnsDataType: BNNSDataType { BNNSDataTypeInt64 }
}
extension UInt8: BNNSScalar, vDSP_IntegerConvertable {
    public static var bnnsDataType: BNNSDataType { BNNSDataType(rawValue: 0x20008) }
}
extension UInt16: BNNSScalar, vDSP_IntegerConvertable {
    public static var bnnsDataType: BNNSDataType { BNNSDataType(rawValue: 0x20010) }
}
extension UInt32: BNNSScalar, vDSP_IntegerConvertable {
    public static var bnnsDataType: BNNSDataType { BNNSDataType(rawValue: 0x20020) }
}
extension UInt64: BNNSScalar {
    public static var bnnsDataType: BNNSDataType { BNNSDataTypeUInt64 }
}
extension Int: BNNSScalar {
    public static var bnnsDataType: BNNSDataType { BNNSDataTypeInt32 }
}
extension Float: BNNSScalar, vDSP_FloatingPointConvertable, vDSP_FloatingPointGeneratable,
    vDSP_FloatingPointBiquadFilterable, vDSP_FloatingPointDiscreteFourierTransformable,
    vDSP_DiscreteFourierTransformable
{
    public static var bnnsDataType: BNNSDataType { BNNSDataTypeFloat32 }
    public typealias DiscreteFourierTransformFunctions = vDSP.DFTSinglePrecisionSplitComplexFunctions
    public typealias DFTFunctions = vDSP.VectorizableFloat
    public typealias BiquadFunctions = vDSP.VectorizableFloat
    public typealias Element = Float
}
extension Double: BNNSScalar, vDSP_FloatingPointConvertable, vDSP_FloatingPointGeneratable,
    vDSP_FloatingPointBiquadFilterable, vDSP_FloatingPointDiscreteFourierTransformable,
    vDSP_DiscreteFourierTransformable
{
    public static var bnnsDataType: BNNSDataType { BNNSDataTypeFloat32 }
    public typealias DiscreteFourierTransformFunctions = vDSP.DFTDoublePrecisionSplitComplexFunctions
    public typealias DFTFunctions = vDSP.VectorizableDouble
    public typealias BiquadFunctions = vDSP.VectorizableDouble
}
extension Float16: BNNSScalar {
    public static var bnnsDataType: BNNSDataType { BNNSDataTypeFloat16 }
    public typealias Element = Float16
}

extension DSPComplex: vDSP_DiscreteFourierTransformable {
    public typealias DiscreteFourierTransformFunctions = vDSP.DFTSinglePrecisionInterleavedFunctions
}
extension DSPDoubleComplex: vDSP_DiscreteFourierTransformable {
    public typealias DiscreteFourierTransformFunctions = vDSP.DFTDoublePrecisionInterleavedFunctions
}
extension DSPSplitComplex: vDSP_FourierTransformable {
    public typealias FFTFunctions = vDSP_SplitComplexFloat
}
extension DSPDoubleSplitComplex: vDSP_FourierTransformable {
    public typealias FFTFunctions = vDSP_SplitComplexDouble
}
