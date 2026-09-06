import Foundation

public enum AccelerateLinuxError: Error, Sendable {
    case failClosed
}

@inline(__always)
internal func _accelerateDummyPointer() -> UnsafeMutableRawPointer {
    UnsafeMutableRawPointer(bitPattern: 1)!
}

public protocol OS_la_object: NSObjectProtocol {}

/// Dense LinearAlgebra object used by the Linux `la_*` starting point.
/// Operations evaluate eagerly and store row-major values.
public final class _OpenUIKitLAObject: NSObject, OS_la_object, @unchecked Sendable {
    enum Kind {
        case empty
        case float
        case double
        case splatFloat
        case splatDouble
    }
    var kind: Kind = .empty
    var rows: Int = 0
    var cols: Int = 0
    var floats: [Float] = []
    var doubles: [Double] = []
    var splatF: Float = 0
    var splatD: Double = 0
    var status: la_status_t = 0
    var attributes: la_attribute_t = 0
}

public typealias BLASParamErrorProc = (UnsafePointer<CChar>?, UnsafePointer<CChar>?, UnsafePointer<Int32>?, UnsafePointer<Int32>?) -> Void
public typealias BNNSAlloc = (UnsafeMutablePointer<UnsafeMutableRawPointer?>?, Int, Int) -> Int32
public typealias BNNSFilter = UnsafeMutableRawPointer
public typealias BNNSFree = (UnsafeMutableRawPointer?) -> Void
public typealias BNNSNearestNeighbors = UnsafeMutableRawPointer
public typealias BNNSRandomGenerator = UnsafeMutableRawPointer
public typealias COMPLEX = DSPComplex
public typealias COMPLEX_SPLIT = DSPSplitComplex
public typealias DOUBLE_COMPLEX = DSPDoubleComplex
public typealias DOUBLE_COMPLEX_SPLIT = DSPDoubleSplitComplex
public typealias FFTDirection = Int32
public typealias FFTRadix = Int32
public typealias FFTSetup = OpaquePointer
public typealias FFTSetupD = OpaquePointer
public typealias GammaFunction = UnsafeMutableRawPointer
public typealias Pixel_16F = UInt16
public typealias Pixel_16F16F = (UInt16, UInt16)
public typealias Pixel_16Q12 = Int16
public typealias Pixel_16S = Int16
public typealias Pixel_16S16S = (Int16, Int16)
public typealias Pixel_16U = UInt16
public typealias Pixel_16U16U = (UInt16, UInt16)
public typealias Pixel_32U = UInt32
public typealias Pixel_8 = UInt8
public typealias Pixel_88 = (UInt8, UInt8)
public typealias Pixel_8888 = (UInt8, UInt8, UInt8, UInt8)
public typealias Pixel_ARGB_16F = (UInt16, UInt16, UInt16, UInt16)
public typealias Pixel_ARGB_16S = (Int16, Int16, Int16, Int16)
public typealias Pixel_ARGB_16U = (UInt16, UInt16, UInt16, UInt16)
public typealias Pixel_F = Float
public typealias Pixel_FF = (Float, Float)
public typealias Pixel_FFFF = (Float, Float, Float, Float)
public typealias ResamplingFilter = UnsafeMutableRawPointer
public typealias bnns_graph_compile_message_fn_t = (BNNSGraphMessageLevel, UnsafePointer<CChar>, UnsafePointer<CChar>?, UnsafeMutablePointer<bnns_user_message_data_t>?) -> Void
public typealias bnns_graph_execute_message_fn_t = (BNNSGraphMessageLevel, UnsafePointer<CChar>, UnsafePointer<CChar>?, UnsafeMutablePointer<bnns_user_message_data_t>?) -> Void
public typealias bnns_graph_free_all_fn_t = (UnsafeMutableRawPointer?, Int) -> Void
public typealias bnns_graph_realloc_fn_t = (UnsafeMutableRawPointer?, Int, UnsafeMutablePointer<UnsafeMutableRawPointer?>, Int, Int) -> Int32
public typealias la_attribute_t = UInt
public typealias la_count_t = UInt
public typealias la_deallocator_t = (UnsafeMutableRawPointer?) -> Void
public typealias la_hint_t = UInt
public typealias la_index_t = Int
public typealias la_norm_t = UInt
public typealias la_object_t = any OS_la_object
public typealias la_scalar_type_t = UInt32
public typealias la_status_t = Int
public typealias quadrature_function_array = (UnsafeMutableRawPointer?, Int, UnsafePointer<Double>, UnsafeMutablePointer<Double>) -> Void
public typealias sparse_dimension = UInt64
public typealias sparse_index = Int64
public typealias sparse_matrix_double = OpaquePointer
public typealias sparse_matrix_double_complex = OpaquePointer
public typealias sparse_matrix_float = OpaquePointer
public typealias sparse_matrix_float_complex = OpaquePointer
public typealias sparse_stride = Int64
public typealias vBool32 = SIMD4<UInt32>
public typealias vDSP_DFT_Interleaved_Setup = OpaquePointer
public typealias vDSP_DFT_Interleaved_SetupD = OpaquePointer
public typealias vDSP_DFT_Setup = OpaquePointer
public typealias vDSP_DFT_SetupD = OpaquePointer
public typealias vDSP_Length = UInt
public typealias vDSP_Stride = Int
public typealias vDSP_biquad_Setup = OpaquePointer
public typealias vDSP_biquad_SetupD = OpaquePointer
public typealias vDSP_biquadm_Setup = OpaquePointer
public typealias vDSP_biquadm_SetupD = OpaquePointer
public typealias vDouble = SIMD2<Double>
public typealias vFloat = SIMD4<Float>
public typealias vFloatPacked = SIMD4<Float>
public typealias vImageBufferTypeCode = UInt32
public typealias vImageCVImageFormatError = Int
public typealias vImageMatrixType = UInt32
public typealias vImagePixelCount = UInt
public typealias vImage_Error = Int
public typealias vImage_Flags = UInt32
public typealias vImage_MultidimensionalTable = OpaquePointer
public typealias vImage_WarpInterpolation = Int32
public typealias vSInt16 = SIMD8<Int16>
public typealias vSInt32 = SIMD4<Int32>
public typealias vSInt64 = SIMD2<Int64>
public typealias vSInt8 = SIMD16<Int8>
public typealias vUInt16 = SIMD8<UInt16>
public typealias vUInt32 = SIMD4<UInt32>
public typealias vUInt64 = SIMD2<UInt64>
public typealias vUInt8 = SIMD16<UInt8>

public struct BLAS_THREADING: RawRepresentable, Equatable, Hashable, Sendable {
    public var rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public init(_ rawValue: UInt32) { self.rawValue = rawValue }
}
public struct CBLAS_DIAG: RawRepresentable, Equatable, Hashable, Sendable {
    public var rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public init(_ rawValue: UInt32) { self.rawValue = rawValue }
}
public struct CBLAS_ORDER: RawRepresentable, Equatable, Hashable, Sendable {
    public var rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public init(_ rawValue: UInt32) { self.rawValue = rawValue }
}
public struct CBLAS_SIDE: RawRepresentable, Equatable, Hashable, Sendable {
    public var rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public init(_ rawValue: UInt32) { self.rawValue = rawValue }
}
public struct CBLAS_TRANSPOSE: RawRepresentable, Equatable, Hashable, Sendable {
    public var rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public init(_ rawValue: UInt32) { self.rawValue = rawValue }
}
public struct CBLAS_UPLO: RawRepresentable, Equatable, Hashable, Sendable {
    public var rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public init(_ rawValue: UInt32) { self.rawValue = rawValue }
}
public struct BNNSActivationFunction: RawRepresentable, Equatable, Hashable, Sendable {
    public var rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public init(_ rawValue: UInt32) { self.rawValue = rawValue }
}
public struct BNNSArithmeticFunction: RawRepresentable, Equatable, Hashable, Sendable {
    public var rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public init(_ rawValue: UInt32) { self.rawValue = rawValue }
}
public struct BNNSBoxCoordinateMode: RawRepresentable, Equatable, Hashable, Sendable {
    public var rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public init(_ rawValue: UInt32) { self.rawValue = rawValue }
}
public struct BNNSDataLayout: RawRepresentable, Equatable, Hashable, Sendable {
    public var rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public init(_ rawValue: UInt32) { self.rawValue = rawValue }
}
public struct BNNSDataType: RawRepresentable, Equatable, Hashable, Sendable {
    public var rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public init(_ rawValue: UInt32) { self.rawValue = rawValue }
}
public struct BNNSDescriptorType: RawRepresentable, Equatable, Hashable, Sendable {
    public var rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public init(_ rawValue: UInt32) { self.rawValue = rawValue }
}
public struct BNNSEmbeddingFlags: RawRepresentable, Equatable, Hashable, Sendable {
    public var rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public init(_ rawValue: UInt32) { self.rawValue = rawValue }
}
public struct BNNSFilterType: RawRepresentable, Equatable, Hashable, Sendable {
    public var rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public init(_ rawValue: UInt32) { self.rawValue = rawValue }
}
public struct BNNSFlags: OptionSet, Hashable, Sendable {
    public var rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public init(_ rawValue: UInt32) { self.rawValue = rawValue }
}
public struct BNNSGraphArgumentIntent: RawRepresentable, Equatable, Hashable, Sendable {
    public var rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public init(_ rawValue: UInt32) { self.rawValue = rawValue }
}
public struct BNNSGraphArgumentType: RawRepresentable, Equatable, Hashable, Sendable {
    public var rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public init(_ rawValue: UInt32) { self.rawValue = rawValue }
}
public struct BNNSGraphMessageLevel: RawRepresentable, Equatable, Hashable, Sendable {
    public var rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public init(_ rawValue: UInt32) { self.rawValue = rawValue }
}
public struct BNNSGraphOptimizationPreference: RawRepresentable, Equatable, Hashable, Sendable {
    public var rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public init(_ rawValue: UInt32) { self.rawValue = rawValue }
}
public struct BNNSInterpolationMethod: RawRepresentable, Equatable, Hashable, Sendable {
    public var rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public init(_ rawValue: UInt32) { self.rawValue = rawValue }
}
public struct BNNSLayerFlags: RawRepresentable, Equatable, Hashable, Sendable {
    public var rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public init(_ rawValue: UInt32) { self.rawValue = rawValue }
}
public struct BNNSLinearSamplingMode: RawRepresentable, Equatable, Hashable, Sendable {
    public var rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public init(_ rawValue: UInt32) { self.rawValue = rawValue }
}
public struct BNNSLossFunction: RawRepresentable, Equatable, Hashable, Sendable {
    public var rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public init(_ rawValue: UInt32) { self.rawValue = rawValue }
}
public struct BNNSLossReductionFunction: RawRepresentable, Equatable, Hashable, Sendable {
    public var rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public init(_ rawValue: UInt32) { self.rawValue = rawValue }
}
public struct BNNSNDArrayFlags: RawRepresentable, Equatable, Hashable, Sendable {
    public var rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public init(_ rawValue: UInt32) { self.rawValue = rawValue }
}
public struct BNNSNormType: RawRepresentable, Equatable, Hashable, Sendable {
    public var rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public init(_ rawValue: UInt32) { self.rawValue = rawValue }
}
public struct BNNSOptimizerClippingFunction: RawRepresentable, Equatable, Hashable, Sendable {
    public var rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public init(_ rawValue: UInt32) { self.rawValue = rawValue }
}
public struct BNNSOptimizerFunction: RawRepresentable, Equatable, Hashable, Sendable {
    public var rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public init(_ rawValue: UInt32) { self.rawValue = rawValue }
}
public struct BNNSOptimizerRegularizationFunction: RawRepresentable, Equatable, Hashable, Sendable {
    public var rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public init(_ rawValue: UInt32) { self.rawValue = rawValue }
}
public struct BNNSOptimizerSGDMomentumVariant: RawRepresentable, Equatable, Hashable, Sendable {
    public var rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public init(_ rawValue: UInt32) { self.rawValue = rawValue }
}
public struct BNNSPaddingMode: RawRepresentable, Equatable, Hashable, Sendable {
    public var rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public init(_ rawValue: UInt32) { self.rawValue = rawValue }
}
public struct BNNSPointerSpecifier: RawRepresentable, Equatable, Hashable, Sendable {
    public var rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public init(_ rawValue: UInt32) { self.rawValue = rawValue }
}
public struct BNNSPoolingFunction: RawRepresentable, Equatable, Hashable, Sendable {
    public var rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public init(_ rawValue: UInt32) { self.rawValue = rawValue }
}
public struct BNNSQuantizerFunction: RawRepresentable, Equatable, Hashable, Sendable {
    public var rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public init(_ rawValue: UInt32) { self.rawValue = rawValue }
}
public struct BNNSRandomGeneratorMethod: RawRepresentable, Equatable, Hashable, Sendable {
    public var rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public init(_ rawValue: UInt32) { self.rawValue = rawValue }
}
public struct BNNSReduceFunction: RawRepresentable, Equatable, Hashable, Sendable {
    public var rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public init(_ rawValue: UInt32) { self.rawValue = rawValue }
}
public struct BNNSRelationalOperator: RawRepresentable, Equatable, Hashable, Sendable {
    public var rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public init(_ rawValue: UInt32) { self.rawValue = rawValue }
}
public struct BNNSShuffleType: RawRepresentable, Equatable, Hashable, Sendable {
    public var rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public init(_ rawValue: UInt32) { self.rawValue = rawValue }
}
public struct BNNSSparsityType: RawRepresentable, Equatable, Hashable, Sendable {
    public var rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public init(_ rawValue: UInt32) { self.rawValue = rawValue }
}
public struct BNNSTargetSystem: RawRepresentable, Equatable, Hashable, Sendable {
    public var rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public init(_ rawValue: UInt32) { self.rawValue = rawValue }
}
public struct SparseControl_t: RawRepresentable, Equatable, Hashable, Sendable {
    public var rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public init(_ rawValue: UInt32) { self.rawValue = rawValue }
}
public struct SparseFactorization_t: RawRepresentable, Equatable, Hashable, Sendable {
    public var rawValue: UInt8
    public init(rawValue: UInt8) { self.rawValue = rawValue }
    public init(_ rawValue: UInt8) { self.rawValue = rawValue }
}
public struct SparseGMRESVariant_t: RawRepresentable, Equatable, Hashable, Sendable {
    public var rawValue: UInt8
    public init(rawValue: UInt8) { self.rawValue = rawValue }
    public init(_ rawValue: UInt8) { self.rawValue = rawValue }
}
public struct SparseIterativeStatus_t: RawRepresentable, Equatable, Hashable, Sendable {
    public var rawValue: Int32
    public init(rawValue: Int32) { self.rawValue = rawValue }
    public init(_ rawValue: Int32) { self.rawValue = rawValue }
}
public struct SparseKind_t: RawRepresentable, Equatable, Hashable, Sendable {
    public var rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public init(_ rawValue: UInt32) { self.rawValue = rawValue }
}
public struct SparseLSMRConvergenceTest_t: RawRepresentable, Equatable, Hashable, Sendable {
    public var rawValue: Int32
    public init(rawValue: Int32) { self.rawValue = rawValue }
    public init(_ rawValue: Int32) { self.rawValue = rawValue }
}
public struct SparseOrder_t: RawRepresentable, Equatable, Hashable, Sendable {
    public var rawValue: UInt8
    public init(rawValue: UInt8) { self.rawValue = rawValue }
    public init(_ rawValue: UInt8) { self.rawValue = rawValue }
}
public struct SparsePreconditioner_t: RawRepresentable, Equatable, Hashable, Sendable {
    public var rawValue: Int32
    public init(rawValue: Int32) { self.rawValue = rawValue }
    public init(_ rawValue: Int32) { self.rawValue = rawValue }
}
public struct SparseScaling_t: RawRepresentable, Equatable, Hashable, Sendable {
    public var rawValue: UInt8
    public init(rawValue: UInt8) { self.rawValue = rawValue }
    public init(_ rawValue: UInt8) { self.rawValue = rawValue }
}
public struct SparseStatus_t: RawRepresentable, Equatable, Hashable, Sendable {
    public var rawValue: Int32
    public init(rawValue: Int32) { self.rawValue = rawValue }
    public init(_ rawValue: Int32) { self.rawValue = rawValue }
}
public struct SparseSubfactor_t: RawRepresentable, Equatable, Hashable, Sendable {
    public var rawValue: UInt8
    public init(rawValue: UInt8) { self.rawValue = rawValue }
    public init(_ rawValue: UInt8) { self.rawValue = rawValue }
}
public struct SparseTriangle_t: RawRepresentable, Equatable, Hashable, Sendable {
    public var rawValue: UInt8
    public init(rawValue: UInt8) { self.rawValue = rawValue }
    public init(_ rawValue: UInt8) { self.rawValue = rawValue }
}
public struct SparseUpdate_t: RawRepresentable, Equatable, Hashable, Sendable {
    public var rawValue: UInt8
    public init(rawValue: UInt8) { self.rawValue = rawValue }
    public init(_ rawValue: UInt8) { self.rawValue = rawValue }
}
public struct quadrature_integrator: RawRepresentable, Equatable, Hashable, Sendable {
    public var rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public init(_ rawValue: UInt32) { self.rawValue = rawValue }
}
public struct quadrature_status: RawRepresentable, Equatable, Hashable, Sendable {
    public var rawValue: Int32
    public init(rawValue: Int32) { self.rawValue = rawValue }
    public init(_ rawValue: Int32) { self.rawValue = rawValue }
}
public struct sparse_matrix_property: RawRepresentable, Equatable, Hashable, Sendable {
    public var rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public init(_ rawValue: UInt32) { self.rawValue = rawValue }
}
public struct sparse_norm: RawRepresentable, Equatable, Hashable, Sendable {
    public var rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public init(_ rawValue: UInt32) { self.rawValue = rawValue }
}
public struct sparse_status: RawRepresentable, Equatable, Hashable, Sendable {
    public var rawValue: Int32
    public init(rawValue: Int32) { self.rawValue = rawValue }
    public init(_ rawValue: Int32) { self.rawValue = rawValue }
}
public struct vImageARGBType: RawRepresentable, Equatable, Hashable, Sendable {
    public var rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public init(_ rawValue: UInt32) { self.rawValue = rawValue }
}
public struct vImageMDTableUsageHint: RawRepresentable, Equatable, Hashable, Sendable {
    public var rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public init(_ rawValue: UInt32) { self.rawValue = rawValue }
}
public struct vImageYpCbCrType: RawRepresentable, Equatable, Hashable, Sendable {
    public var rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public init(_ rawValue: UInt32) { self.rawValue = rawValue }
}
public struct vImage_InterpolationMethod: RawRepresentable, Equatable, Hashable, Sendable {
    public var rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public init(_ rawValue: UInt32) { self.rawValue = rawValue }
}

public enum vDSP_DCT_Type: Int32, Sendable {
    case II = 2
    case III = 3
    case IV = 4
}
public enum vDSP_DFT_Direction: Int32, Sendable {
    case FORWARD = 1
    case INVERSE = -1
}
public enum vDSP_DFT_RealtoComplex: Int32, Sendable {
    case interleaved_ComplextoComplex
    case interleaved_RealtoComplex
}

public struct DSPComplex {
    public var imag: Float
    public var real: Float
    public init() {
        self.imag = 0
        self.real = 0
    }
    public init(real: Float, imag: Float) { self.init(); self.real = real; self.imag = imag }
}

public struct DSPDoubleComplex {
    public var imag: Double
    public var real: Double
    public init() {
        self.imag = 0
        self.real = 0
    }
    public init(real: Double, imag: Double) { self.init(); self.real = real; self.imag = imag }
}

public struct DSPDoubleSplitComplex {
    public var imagp: UnsafeMutablePointer<Double>
    public var realp: UnsafeMutablePointer<Double>
    public init() {
        self.imagp = UnsafeMutablePointer<Double>.allocate(capacity: 1)
        self.realp = UnsafeMutablePointer<Double>.allocate(capacity: 1)
    }
    public init(realp: UnsafeMutablePointer<Double>, imagp: UnsafeMutablePointer<Double>) {
        self.realp = realp
        self.imagp = imagp
    }
    public init(fromInputArray inputArray: [Double], realParts: inout [Double], imaginaryParts: inout [Double]) {
        let n = inputArray.count / 2
        if realParts.count < n {
            realParts = [Double](repeating: 0, count: n)
        }
        if imaginaryParts.count < n {
            imaginaryParts = [Double](repeating: 0, count: n)
        }
        for i in 0..<n {
            realParts[i] = inputArray[2 * i]
            imaginaryParts[i] = inputArray[2 * i + 1]
        }
        self.realp = realParts.withUnsafeMutableBufferPointer { $0.baseAddress! }
        self.imagp = imaginaryParts.withUnsafeMutableBufferPointer { $0.baseAddress! }
    }
}

public struct DSPSplitComplex {
    public var imagp: UnsafeMutablePointer<Float>
    public var realp: UnsafeMutablePointer<Float>
    public init() {
        self.imagp = UnsafeMutablePointer<Float>.allocate(capacity: 1)
        self.realp = UnsafeMutablePointer<Float>.allocate(capacity: 1)
    }
    public init(realp: UnsafeMutablePointer<Float>, imagp: UnsafeMutablePointer<Float>) {
        self.realp = realp
        self.imagp = imagp
    }
    public init(fromInputArray inputArray: [Float], realParts: inout [Float], imaginaryParts: inout [Float]) {
        let n = inputArray.count / 2
        if realParts.count < n {
            realParts = [Float](repeating: 0, count: n)
        }
        if imaginaryParts.count < n {
            imaginaryParts = [Float](repeating: 0, count: n)
        }
        for i in 0..<n {
            realParts[i] = inputArray[2 * i]
            imaginaryParts[i] = inputArray[2 * i + 1]
        }
        self.realp = realParts.withUnsafeMutableBufferPointer { $0.baseAddress! }
        self.imagp = imaginaryParts.withUnsafeMutableBufferPointer { $0.baseAddress! }
    }
}

public struct vImageChannelDescription {
    public var full: CGFloat
    public var max: CGFloat
    public var min: CGFloat
    public var zero: CGFloat
    public init() {
        self.full = 0
        self.max = 0
        self.min = 0
        self.zero = 0
    }
    public init(min: CGFloat, zero: CGFloat, full: CGFloat, max: CGFloat) { self.init(); self.min = min; self.zero = zero; self.full = full; self.max = max }
}

public struct vImageRGBPrimaries {
    public var blue_x: Float
    public var blue_y: Float
    public var green_x: Float
    public var green_y: Float
    public var red_x: Float
    public var red_y: Float
    public var white_x: Float
    public var white_y: Float
    public init() {
        self.blue_x = 0
        self.blue_y = 0
        self.green_x = 0
        self.green_y = 0
        self.red_x = 0
        self.red_y = 0
        self.white_x = 0
        self.white_y = 0
    }
    public init(red_x: Float, green_x: Float, blue_x: Float, white_x: Float, red_y: Float, green_y: Float, blue_y: Float, white_y: Float) { self.init(); self.red_x = red_x; self.green_x = green_x; self.blue_x = blue_x; self.white_x = white_x; self.red_y = red_y; self.green_y = green_y; self.blue_y = blue_y; self.white_y = white_y }
}

public struct vImageTransferFunction {
    public var c0: CGFloat
    public var c1: CGFloat
    public var c2: CGFloat
    public var c3: CGFloat
    public var c4: CGFloat
    public var c5: CGFloat
    public var cutoff: CGFloat
    public var gamma: CGFloat
    public init() {
        self.c0 = 0
        self.c1 = 0
        self.c2 = 0
        self.c3 = 0
        self.c4 = 0
        self.c5 = 0
        self.cutoff = 0
        self.gamma = 0
    }
    public init(c0: CGFloat, c1: CGFloat, c2: CGFloat, c3: CGFloat, gamma: CGFloat, cutoff: CGFloat, c4: CGFloat, c5: CGFloat) { self.init(); self.c0 = c0; self.c1 = c1; self.c2 = c2; self.c3 = c3; self.gamma = gamma; self.cutoff = cutoff; self.c4 = c4; self.c5 = c5 }
}

public struct vImageWhitePoint {
    public var white_x: Float
    public var white_y: Float
    public init() {
        self.white_x = 0
        self.white_y = 0
    }
    public init(white_x: Float, white_y: Float) { self.init(); self.white_x = white_x; self.white_y = white_y }
}

public struct vImage_ARGBToYpCbCr {
    public var opaque: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8)
    public init() {
        self.opaque = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
    }
    public init(opaque: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8)) { self.init(); self.opaque = opaque }
}

public struct vImage_ARGBToYpCbCrMatrix {
    public var B_Cb_R_Cr: Float
    public var B_Cr: Float
    public var B_Yp: Float
    public var G_Cb: Float
    public var G_Cr: Float
    public var G_Yp: Float
    public var R_Cb: Float
    public var R_Yp: Float
    public init() {
        self.B_Cb_R_Cr = 0
        self.B_Cr = 0
        self.B_Yp = 0
        self.G_Cb = 0
        self.G_Cr = 0
        self.G_Yp = 0
        self.R_Cb = 0
        self.R_Yp = 0
    }
    public init(R_Yp: Float, G_Yp: Float, B_Yp: Float, R_Cb: Float, G_Cb: Float, B_Cb_R_Cr: Float, G_Cr: Float, B_Cr: Float) { self.init(); self.R_Yp = R_Yp; self.G_Yp = G_Yp; self.B_Yp = B_Yp; self.R_Cb = R_Cb; self.G_Cb = G_Cb; self.B_Cb_R_Cr = B_Cb_R_Cr; self.G_Cr = G_Cr; self.B_Cr = B_Cr }
}

public struct vImage_AffineTransform {
    public var a: Float
    public var b: Float
    public var c: Float
    public var d: Float
    public var tx: Float
    public var ty: Float
    public init() {
        self.a = 0
        self.b = 0
        self.c = 0
        self.d = 0
        self.tx = 0
        self.ty = 0
    }
    public init(a: CGFloat, b: CGFloat, c: CGFloat, d: CGFloat, tx: CGFloat, ty: CGFloat) {
        self.a = Float(a)
        self.b = Float(b)
        self.c = Float(c)
        self.d = Float(d)
        self.tx = Float(tx)
        self.ty = Float(ty)
    }
    public init(a: Float, b: Float, c: Float, d: Float, tx: Float, ty: Float) { self.init(); self.a = a; self.b = b; self.c = c; self.d = d; self.tx = tx; self.ty = ty }
}

public struct vImage_AffineTransform_Double {
    public var a: Double
    public var b: Double
    public var c: Double
    public var d: Double
    public var tx: Double
    public var ty: Double
    public init() {
        self.a = 0
        self.b = 0
        self.c = 0
        self.d = 0
        self.tx = 0
        self.ty = 0
    }
    public init(a: CGFloat, b: CGFloat, c: CGFloat, d: CGFloat, tx: CGFloat, ty: CGFloat) {
        self.a = Double(a)
        self.b = Double(b)
        self.c = Double(c)
        self.d = Double(d)
        self.tx = Double(tx)
        self.ty = Double(ty)
    }
    public init(a: Double, b: Double, c: Double, d: Double, tx: Double, ty: Double) { self.init(); self.a = a; self.b = b; self.c = c; self.d = d; self.tx = tx; self.ty = ty }
}

public struct vImage_Buffer {
    public var data: UnsafeMutableRawPointer!
    public var height: vImagePixelCount
    public var rowBytes: Int
    public var width: vImagePixelCount
    public init() {
        self.data = nil
        self.height = 0
        self.rowBytes = 0
        self.width = 0
    }
    public init(size: CGSize, bitsPerPixel: UInt32) throws {
        guard let width = Int(exactly: size.width), let height = Int(exactly: size.height), width >= 0, height >= 0 else {
            throw vImage.Error.invalidParameter
        }
        try self.init(width: width, height: height, bitsPerPixel: bitsPerPixel)
    }
    public init(width: Int, height: Int, bitsPerPixel: UInt32) throws {
        guard width >= 0, height >= 0 else { throw vImage.Error.invalidParameter }
        let rowBytes = (width * Int(bitsPerPixel) + 7) / 8
        let byteCount = rowBytes * height
        if byteCount == 0 {
            self.init(data: nil, height: vImagePixelCount(height), width: vImagePixelCount(width), rowBytes: rowBytes)
            return
        }
        let ptr = UnsafeMutableRawPointer.allocate(byteCount: max(byteCount, 1), alignment: 16)
        ptr.initializeMemory(as: UInt8.self, repeating: 0, count: byteCount)
        self.init(data: ptr, height: vImagePixelCount(height), width: vImagePixelCount(width), rowBytes: rowBytes)
    }
    public init(data: UnsafeMutableRawPointer!, height: vImagePixelCount, width: vImagePixelCount, rowBytes: Int) { self.init(); self.data = data; self.height = height; self.width = width; self.rowBytes = rowBytes }
}

public struct vImage_PerpsectiveTransform {
    public var a: Float
    public var b: Float
    public var c: Float
    public var d: Float
    public var tx: Float
    public var ty: Float
    public var v: Float
    public var vx: Float
    public var vy: Float
    public init() {
        self.a = 0
        self.b = 0
        self.c = 0
        self.d = 0
        self.tx = 0
        self.ty = 0
        self.v = 0
        self.vx = 0
        self.vy = 0
    }
    public init(a: Float, b: Float, c: Float, d: Float, tx: Float, ty: Float, vx: Float, vy: Float, v: Float) { self.init(); self.a = a; self.b = b; self.c = c; self.d = d; self.tx = tx; self.ty = ty; self.vx = vx; self.vy = vy; self.v = v }
}

public struct vImage_YpCbCrPixelRange {
    public var CbCrMax: Int32
    public var CbCrMin: Int32
    public var CbCrRangeMax: Int32
    public var CbCr_bias: Int32
    public var YpMax: Int32
    public var YpMin: Int32
    public var YpRangeMax: Int32
    public var Yp_bias: Int32
    public init() {
        self.CbCrMax = 0
        self.CbCrMin = 0
        self.CbCrRangeMax = 0
        self.CbCr_bias = 0
        self.YpMax = 0
        self.YpMin = 0
        self.YpRangeMax = 0
        self.Yp_bias = 0
    }
    public init(Yp_bias: Int32, CbCr_bias: Int32, YpRangeMax: Int32, CbCrRangeMax: Int32, YpMax: Int32, YpMin: Int32, CbCrMax: Int32, CbCrMin: Int32) { self.init(); self.Yp_bias = Yp_bias; self.CbCr_bias = CbCr_bias; self.YpRangeMax = YpRangeMax; self.CbCrRangeMax = CbCrRangeMax; self.YpMax = YpMax; self.YpMin = YpMin; self.CbCrMax = CbCrMax; self.CbCrMin = CbCrMin }
}

public struct vImage_YpCbCrToARGB {
    public var opaque: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8)
    public init() {
        self.opaque = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
    }
    public init(opaque: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8)) { self.init(); self.opaque = opaque }
}

public struct vImage_YpCbCrToARGBMatrix {
    public var Cb_B: Float
    public var Cb_G: Float
    public var Cr_G: Float
    public var Cr_R: Float
    public var Yp: Float
    public init() {
        self.Cb_B = 0
        self.Cb_G = 0
        self.Cr_G = 0
        self.Cr_R = 0
        self.Yp = 0
    }
    public init(Yp: Float, Cr_R: Float, Cr_G: Float, Cb_G: Float, Cb_B: Float) { self.init(); self.Yp = Yp; self.Cr_R = Cr_R; self.Cr_G = Cr_G; self.Cb_G = Cb_G; self.Cb_B = Cb_B }
}

public struct BNNSActivation {
    public var alpha: Float
    public var beta: Float
    public var function: BNNSActivationFunction
    public var ioffset: Int32
    public var ioffset_per_channel: UnsafePointer<Int32>?
    public var iscale: Int32
    public var iscale_per_channel: UnsafePointer<Int32>?
    public var ishift: Int32
    public var ishift_per_channel: UnsafePointer<Int32>?
    public init() {
        self.alpha = 0
        self.beta = 0
        self.function = BNNSActivationFunction(rawValue: 0)
        self.ioffset = 0
        self.ioffset_per_channel = nil
        self.iscale = 0
        self.iscale_per_channel = nil
        self.ishift = 0
        self.ishift_per_channel = nil
    }
    public init(function: BNNSActivationFunction, alpha: Float = .nan, beta: Float = .nan) { self.init(); self.function = function; self.alpha = alpha; self.beta = beta }
}

public struct BNNSArithmeticBinary {
    public var in1: BNNSNDArrayDescriptor
    public var in1_type: BNNSDescriptorType
    public var in2: BNNSNDArrayDescriptor
    public var in2_type: BNNSDescriptorType
    public var out: BNNSNDArrayDescriptor
    public var out_type: BNNSDescriptorType
    public init() {
        self.in1 = BNNSNDArrayDescriptor()
        self.in1_type = BNNSDescriptorType(rawValue: 0)
        self.in2 = BNNSNDArrayDescriptor()
        self.in2_type = BNNSDescriptorType(rawValue: 0)
        self.out = BNNSNDArrayDescriptor()
        self.out_type = BNNSDescriptorType(rawValue: 0)
    }
    public init(in1: BNNSNDArrayDescriptor, in1_type: BNNSDescriptorType, in2: BNNSNDArrayDescriptor, in2_type: BNNSDescriptorType, out: BNNSNDArrayDescriptor, out_type: BNNSDescriptorType) { self.init(); self.in1 = in1; self.in1_type = in1_type; self.in2 = in2; self.in2_type = in2_type; self.out = out; self.out_type = out_type }
}

public struct BNNSArithmeticTernary {
    public var in1: BNNSNDArrayDescriptor
    public var in1_type: BNNSDescriptorType
    public var in2: BNNSNDArrayDescriptor
    public var in2_type: BNNSDescriptorType
    public var in3: BNNSNDArrayDescriptor
    public var in3_type: BNNSDescriptorType
    public var out: BNNSNDArrayDescriptor
    public var out_type: BNNSDescriptorType
    public init() {
        self.in1 = BNNSNDArrayDescriptor()
        self.in1_type = BNNSDescriptorType(rawValue: 0)
        self.in2 = BNNSNDArrayDescriptor()
        self.in2_type = BNNSDescriptorType(rawValue: 0)
        self.in3 = BNNSNDArrayDescriptor()
        self.in3_type = BNNSDescriptorType(rawValue: 0)
        self.out = BNNSNDArrayDescriptor()
        self.out_type = BNNSDescriptorType(rawValue: 0)
    }
    public init(in1: BNNSNDArrayDescriptor, in1_type: BNNSDescriptorType, in2: BNNSNDArrayDescriptor, in2_type: BNNSDescriptorType, in3: BNNSNDArrayDescriptor, in3_type: BNNSDescriptorType, out: BNNSNDArrayDescriptor, out_type: BNNSDescriptorType) { self.init(); self.in1 = in1; self.in1_type = in1_type; self.in2 = in2; self.in2_type = in2_type; self.in3 = in3; self.in3_type = in3_type; self.out = out; self.out_type = out_type }
}

public struct BNNSArithmeticUnary {
    public var `in`: BNNSNDArrayDescriptor
    public var in_type: BNNSDescriptorType
    public var out: BNNSNDArrayDescriptor
    public var out_type: BNNSDescriptorType
    public init() {
        self.`in` = BNNSNDArrayDescriptor()
        self.in_type = BNNSDescriptorType(rawValue: 0)
        self.out = BNNSNDArrayDescriptor()
        self.out_type = BNNSDescriptorType(rawValue: 0)
    }
    public init(in: BNNSNDArrayDescriptor, in_type: BNNSDescriptorType, out: BNNSNDArrayDescriptor, out_type: BNNSDescriptorType) { self.init(); self.`in` = `in`; self.in_type = in_type; self.out = out; self.out_type = out_type }
}

public struct BNNSConvolutionLayerParameters {
    public var activation: BNNSActivation
    public var bias: BNNSLayerData
    public var in_channels: Int
    public var k_height: Int
    public var k_width: Int
    public var out_channels: Int
    public var weights: BNNSLayerData
    public var x_padding: Int
    public var x_stride: Int
    public var y_padding: Int
    public var y_stride: Int
    public init() {
        self.activation = BNNSActivation()
        self.bias = BNNSLayerData()
        self.in_channels = 0
        self.k_height = 0
        self.k_width = 0
        self.out_channels = 0
        self.weights = BNNSLayerData()
        self.x_padding = 0
        self.x_stride = 0
        self.y_padding = 0
        self.y_stride = 0
    }
    public init(x_stride: Int, y_stride: Int, x_padding: Int, y_padding: Int, k_width: Int, k_height: Int, in_channels: Int, out_channels: Int, weights: BNNSLayerData) { self.init(); self.x_stride = x_stride; self.y_stride = y_stride; self.x_padding = x_padding; self.y_padding = y_padding; self.k_width = k_width; self.k_height = k_height; self.in_channels = in_channels; self.out_channels = out_channels; self.weights = weights }
    public init(x_stride: Int, y_stride: Int, x_padding: Int, y_padding: Int, k_width: Int, k_height: Int, in_channels: Int, out_channels: Int, weights: BNNSLayerData, bias: BNNSLayerData, activation: BNNSActivation) { self.init(); self.x_stride = x_stride; self.y_stride = y_stride; self.x_padding = x_padding; self.y_padding = y_padding; self.k_width = k_width; self.k_height = k_height; self.in_channels = in_channels; self.out_channels = out_channels; self.weights = weights; self.bias = bias; self.activation = activation }
}

public struct BNNSFilterParameters {
    public var alloc_memory: BNNSAlloc?
    public var flags: UInt32
    public var free_memory: BNNSFree?
    public var n_threads: Int
    public init() {
        self.alloc_memory = nil
        self.flags = 0
        self.free_memory = nil
        self.n_threads = 0
    }
    public init(options: BNNSFlags, threadCount: Int, allocator: BNNSAlloc?, deallocator: BNNSFree?) { self.init(); _ = options; _ = threadCount; _ = allocator; _ = deallocator }
    public init(flags: UInt32, n_threads: Int, alloc_memory: BNNSAlloc?, free_memory: BNNSFree?) { self.init(); self.flags = flags; self.n_threads = n_threads; self.alloc_memory = alloc_memory; self.free_memory = free_memory }
}

public struct BNNSFullyConnectedLayerParameters {
    public var activation: BNNSActivation
    public var bias: BNNSLayerData
    public var in_size: Int
    public var out_size: Int
    public var weights: BNNSLayerData
    public init() {
        self.activation = BNNSActivation()
        self.bias = BNNSLayerData()
        self.in_size = 0
        self.out_size = 0
        self.weights = BNNSLayerData()
    }
    public init(in_size: Int, out_size: Int, weights: BNNSLayerData) { self.init(); self.in_size = in_size; self.out_size = out_size; self.weights = weights }
    public init(in_size: Int, out_size: Int, weights: BNNSLayerData, bias: BNNSLayerData, activation: BNNSActivation) { self.init(); self.in_size = in_size; self.out_size = out_size; self.weights = weights; self.bias = bias; self.activation = activation }
}

public struct BNNSImageStackDescriptor {
    public var channels: Int
    public var data_bias: Float
    public var data_scale: Float
    public var data_type: BNNSDataType
    public var height: Int
    public var image_stride: Int
    public var row_stride: Int
    public var width: Int
    public init() {
        self.channels = 0
        self.data_bias = 0
        self.data_scale = 0
        self.data_type = BNNSDataType(rawValue: 0)
        self.height = 0
        self.image_stride = 0
        self.row_stride = 0
        self.width = 0
    }
    public init(width: Int, height: Int, channels: Int, row_stride: Int, image_stride: Int, data_type: BNNSDataType) { self.init(); self.width = width; self.height = height; self.channels = channels; self.row_stride = row_stride; self.image_stride = image_stride; self.data_type = data_type }
    public init(width: Int, height: Int, channels: Int, row_stride: Int, image_stride: Int, data_type: BNNSDataType, data_scale: Float, data_bias: Float) { self.init(); self.width = width; self.height = height; self.channels = channels; self.row_stride = row_stride; self.image_stride = image_stride; self.data_type = data_type; self.data_scale = data_scale; self.data_bias = data_bias }
}

public struct BNNSLSTMDataDescriptor {
    public var cell_state_desc: BNNSNDArrayDescriptor
    public var data_desc: BNNSNDArrayDescriptor
    public var hidden_desc: BNNSNDArrayDescriptor
    public init() {
        self.cell_state_desc = BNNSNDArrayDescriptor()
        self.data_desc = BNNSNDArrayDescriptor()
        self.hidden_desc = BNNSNDArrayDescriptor()
    }
    public init(data_desc: BNNSNDArrayDescriptor, hidden_desc: BNNSNDArrayDescriptor, cell_state_desc: BNNSNDArrayDescriptor) { self.init(); self.data_desc = data_desc; self.hidden_desc = hidden_desc; self.cell_state_desc = cell_state_desc }
}

public struct BNNSLSTMGateDescriptor {
    public var activation: BNNSActivation
    public var b_desc: BNNSNDArrayDescriptor
    public var cw_desc: BNNSNDArrayDescriptor
    public var hw_desc: BNNSNDArrayDescriptor
    public var iw_desc: (BNNSNDArrayDescriptor, BNNSNDArrayDescriptor)
    public init() {
        self.activation = BNNSActivation()
        self.b_desc = BNNSNDArrayDescriptor()
        self.cw_desc = BNNSNDArrayDescriptor()
        self.hw_desc = BNNSNDArrayDescriptor()
        self.iw_desc = (BNNSNDArrayDescriptor(), BNNSNDArrayDescriptor())
    }
    public init(iw_desc: (BNNSNDArrayDescriptor, BNNSNDArrayDescriptor), hw_desc: BNNSNDArrayDescriptor, cw_desc: BNNSNDArrayDescriptor, b_desc: BNNSNDArrayDescriptor, activation: BNNSActivation) { self.init(); self.iw_desc = iw_desc; self.hw_desc = hw_desc; self.cw_desc = cw_desc; self.b_desc = b_desc; self.activation = activation }
}

public struct BNNSLayerData {
    public var data: UnsafeRawPointer?
    public var data_bias: Float
    public var data_scale: Float
    public var data_table: UnsafePointer<Float>?
    public var data_type: BNNSDataType
    public init() {
        self.data = nil
        self.data_bias = 0
        self.data_scale = 0
        self.data_table = nil
        self.data_type = BNNSDataType(rawValue: 0)
    }
    public init(data: UnsafeRawPointer?, data_type: BNNSDataType, data_scale: Float = 1, data_bias: Float = 0) { self.init(); self.data = data; self.data_type = data_type; self.data_scale = data_scale; self.data_bias = data_bias }
}

public struct BNNSLayerParametersActivation {
    public var activation: BNNSActivation
    public var axis_flags: UInt32
    public var i_desc: BNNSNDArrayDescriptor
    public var o_desc: BNNSNDArrayDescriptor
    public init() {
        self.activation = BNNSActivation()
        self.axis_flags = 0
        self.i_desc = BNNSNDArrayDescriptor()
        self.o_desc = BNNSNDArrayDescriptor()
    }
    public init(i_desc: BNNSNDArrayDescriptor, o_desc: BNNSNDArrayDescriptor, activation: BNNSActivation, axis_flags: UInt32) { self.init(); self.i_desc = i_desc; self.o_desc = o_desc; self.activation = activation; self.axis_flags = axis_flags }
}

public struct BNNSLayerParametersArithmetic {
    public var activation: BNNSActivation
    public var arithmetic_function: BNNSArithmeticFunction
    public var arithmetic_function_fields: UnsafeMutableRawPointer
    public init() {
        self.activation = BNNSActivation()
        self.arithmetic_function = BNNSArithmeticFunction(rawValue: 0)
        self.arithmetic_function_fields = _accelerateDummyPointer()
    }
    public init(arithmetic_function: BNNSArithmeticFunction, arithmetic_function_fields: UnsafeMutableRawPointer, activation: BNNSActivation) { self.init(); self.arithmetic_function = arithmetic_function; self.arithmetic_function_fields = arithmetic_function_fields; self.activation = activation }
}

public struct BNNSLayerParametersBroadcastMatMul {
    public var a_is_weights: Bool
    public var alpha: Float
    public var b_is_weights: Bool
    public var beta: Float
    public var iA_desc: BNNSNDArrayDescriptor
    public var iB_desc: BNNSNDArrayDescriptor
    public var o_desc: BNNSNDArrayDescriptor
    public var quadratic: Bool
    public var transA: Bool
    public var transB: Bool
    public init() {
        self.a_is_weights = false
        self.alpha = 0
        self.b_is_weights = false
        self.beta = 0
        self.iA_desc = BNNSNDArrayDescriptor()
        self.iB_desc = BNNSNDArrayDescriptor()
        self.o_desc = BNNSNDArrayDescriptor()
        self.quadratic = false
        self.transA = false
        self.transB = false
    }
    public init(alpha: Float, beta: Float, transA: Bool, transB: Bool, quadratic: Bool, a_is_weights: Bool, b_is_weights: Bool, iA_desc: BNNSNDArrayDescriptor, iB_desc: BNNSNDArrayDescriptor, o_desc: BNNSNDArrayDescriptor) { self.init(); self.alpha = alpha; self.beta = beta; self.transA = transA; self.transB = transB; self.quadratic = quadratic; self.a_is_weights = a_is_weights; self.b_is_weights = b_is_weights; self.iA_desc = iA_desc; self.iB_desc = iB_desc; self.o_desc = o_desc }
}

public struct BNNSLayerParametersConvolution {
    public var activation: BNNSActivation
    public var bias: BNNSNDArrayDescriptor
    public var groups: Int
    public var i_desc: BNNSNDArrayDescriptor
    public var o_desc: BNNSNDArrayDescriptor
    public var pad: (Int, Int, Int, Int)
    public var w_desc: BNNSNDArrayDescriptor
    public var x_dilation_stride: Int
    public var x_padding: Int
    public var x_stride: Int
    public var y_dilation_stride: Int
    public var y_padding: Int
    public var y_stride: Int
    public init() {
        self.activation = BNNSActivation()
        self.bias = BNNSNDArrayDescriptor()
        self.groups = 0
        self.i_desc = BNNSNDArrayDescriptor()
        self.o_desc = BNNSNDArrayDescriptor()
        self.pad = (0, 0, 0, 0)
        self.w_desc = BNNSNDArrayDescriptor()
        self.x_dilation_stride = 0
        self.x_padding = 0
        self.x_stride = 0
        self.y_dilation_stride = 0
        self.y_padding = 0
        self.y_stride = 0
    }
    public init(i_desc: BNNSNDArrayDescriptor, w_desc: BNNSNDArrayDescriptor, o_desc: BNNSNDArrayDescriptor, bias: BNNSNDArrayDescriptor, activation: BNNSActivation, x_stride: Int, y_stride: Int, x_dilation_stride: Int, y_dilation_stride: Int, x_padding: Int, y_padding: Int, groups: Int, pad: (Int, Int, Int, Int)) { self.init(); self.i_desc = i_desc; self.w_desc = w_desc; self.o_desc = o_desc; self.bias = bias; self.activation = activation; self.x_stride = x_stride; self.y_stride = y_stride; self.x_dilation_stride = x_dilation_stride; self.y_dilation_stride = y_dilation_stride; self.x_padding = x_padding; self.y_padding = y_padding; self.groups = groups; self.pad = pad }
}

public struct BNNSLayerParametersCropResize {
    public var box_coordinate_mode: BNNSBoxCoordinateMode
    public var extrapolation_value: Float
    public var method: BNNSInterpolationMethod
    public var normalized_coordinates: Bool
    public var sampling_mode: BNNSLinearSamplingMode
    public var spatial_scale: Float
    public init() {
        self.box_coordinate_mode = BNNSBoxCoordinateMode(rawValue: 0)
        self.extrapolation_value = 0
        self.method = BNNSInterpolationMethod(rawValue: 0)
        self.normalized_coordinates = false
        self.sampling_mode = BNNSLinearSamplingMode(rawValue: 0)
        self.spatial_scale = 0
    }
    public init(normalized_coordinates: Bool, spatial_scale: Float, extrapolation_value: Float, sampling_mode: BNNSLinearSamplingMode, box_coordinate_mode: BNNSBoxCoordinateMode, method: BNNSInterpolationMethod) { self.init(); self.normalized_coordinates = normalized_coordinates; self.spatial_scale = spatial_scale; self.extrapolation_value = extrapolation_value; self.sampling_mode = sampling_mode; self.box_coordinate_mode = box_coordinate_mode; self.method = method }
}

public struct BNNSLayerParametersDropout {
    public var control: UInt8
    public var i_desc: BNNSNDArrayDescriptor
    public var o_desc: BNNSNDArrayDescriptor
    public var rate: Float
    public var seed: UInt32
    public init() {
        self.control = 0
        self.i_desc = BNNSNDArrayDescriptor()
        self.o_desc = BNNSNDArrayDescriptor()
        self.rate = 0
        self.seed = 0
    }
    public init(i_desc: BNNSNDArrayDescriptor, o_desc: BNNSNDArrayDescriptor, rate: Float, seed: UInt32, control: UInt8) { self.init(); self.i_desc = i_desc; self.o_desc = o_desc; self.rate = rate; self.seed = seed; self.control = control }
}

public struct BNNSLayerParametersEmbedding {
    public var dictionary: BNNSNDArrayDescriptor
    public var flags: BNNSEmbeddingFlags
    public var i_desc: BNNSNDArrayDescriptor
    public var max_norm: Float
    public var norm_type: Float
    public var o_desc: BNNSNDArrayDescriptor
    public var padding_idx: Int
    public init() {
        self.dictionary = BNNSNDArrayDescriptor()
        self.flags = BNNSEmbeddingFlags(rawValue: 0)
        self.i_desc = BNNSNDArrayDescriptor()
        self.max_norm = 0
        self.norm_type = 0
        self.o_desc = BNNSNDArrayDescriptor()
        self.padding_idx = 0
    }
    public init(flags: BNNSEmbeddingFlags, i_desc: BNNSNDArrayDescriptor, o_desc: BNNSNDArrayDescriptor, dictionary: BNNSNDArrayDescriptor, padding_idx: Int, max_norm: Float, norm_type: Float) { self.init(); self.flags = flags; self.i_desc = i_desc; self.o_desc = o_desc; self.dictionary = dictionary; self.padding_idx = padding_idx; self.max_norm = max_norm; self.norm_type = norm_type }
}

public struct BNNSLayerParametersFullyConnected {
    public var activation: BNNSActivation
    public var bias: BNNSNDArrayDescriptor
    public var i_desc: BNNSNDArrayDescriptor
    public var o_desc: BNNSNDArrayDescriptor
    public var w_desc: BNNSNDArrayDescriptor
    public init() {
        self.activation = BNNSActivation()
        self.bias = BNNSNDArrayDescriptor()
        self.i_desc = BNNSNDArrayDescriptor()
        self.o_desc = BNNSNDArrayDescriptor()
        self.w_desc = BNNSNDArrayDescriptor()
    }
    public init(i_desc: BNNSNDArrayDescriptor, w_desc: BNNSNDArrayDescriptor, o_desc: BNNSNDArrayDescriptor, bias: BNNSNDArrayDescriptor, activation: BNNSActivation) { self.init(); self.i_desc = i_desc; self.w_desc = w_desc; self.o_desc = o_desc; self.bias = bias; self.activation = activation }
}

public struct BNNSLayerParametersGram {
    public var alpha: Float
    public var i_desc: BNNSNDArrayDescriptor
    public var o_desc: BNNSNDArrayDescriptor
    public init() {
        self.alpha = 0
        self.i_desc = BNNSNDArrayDescriptor()
        self.o_desc = BNNSNDArrayDescriptor()
    }
    public init(alpha: Float, i_desc: BNNSNDArrayDescriptor, o_desc: BNNSNDArrayDescriptor) { self.init(); self.alpha = alpha; self.i_desc = i_desc; self.o_desc = o_desc }
}

public struct BNNSLayerParametersLSTM {
    public var batch_size: Int
    public var candidate_gate: BNNSLSTMGateDescriptor
    public var dropout: Float
    public var forget_gate: BNNSLSTMGateDescriptor
    public var hidden_activation: BNNSActivation
    public var hidden_size: Int
    public var input_descriptor: BNNSLSTMDataDescriptor
    public var input_gate: BNNSLSTMGateDescriptor
    public var input_size: Int
    public var lstm_flags: UInt32
    public var num_layers: Int
    public var output_descriptor: BNNSLSTMDataDescriptor
    public var output_gate: BNNSLSTMGateDescriptor
    public var seq_len: Int
    public var sequence_descriptor: BNNSNDArrayDescriptor
    public init() {
        self.batch_size = 0
        self.candidate_gate = BNNSLSTMGateDescriptor()
        self.dropout = 0
        self.forget_gate = BNNSLSTMGateDescriptor()
        self.hidden_activation = BNNSActivation()
        self.hidden_size = 0
        self.input_descriptor = BNNSLSTMDataDescriptor()
        self.input_gate = BNNSLSTMGateDescriptor()
        self.input_size = 0
        self.lstm_flags = 0
        self.num_layers = 0
        self.output_descriptor = BNNSLSTMDataDescriptor()
        self.output_gate = BNNSLSTMGateDescriptor()
        self.seq_len = 0
        self.sequence_descriptor = BNNSNDArrayDescriptor()
    }
    public init(input_size: Int, hidden_size: Int, batch_size: Int, num_layers: Int, seq_len: Int, dropout: Float, lstm_flags: UInt32, sequence_descriptor: BNNSNDArrayDescriptor, input_descriptor: BNNSLSTMDataDescriptor, output_descriptor: BNNSLSTMDataDescriptor, input_gate: BNNSLSTMGateDescriptor, forget_gate: BNNSLSTMGateDescriptor, candidate_gate: BNNSLSTMGateDescriptor, output_gate: BNNSLSTMGateDescriptor, hidden_activation: BNNSActivation) { self.init(); self.input_size = input_size; self.hidden_size = hidden_size; self.batch_size = batch_size; self.num_layers = num_layers; self.seq_len = seq_len; self.dropout = dropout; self.lstm_flags = lstm_flags; self.sequence_descriptor = sequence_descriptor; self.input_descriptor = input_descriptor; self.output_descriptor = output_descriptor; self.input_gate = input_gate; self.forget_gate = forget_gate; self.candidate_gate = candidate_gate; self.output_gate = output_gate; self.hidden_activation = hidden_activation }
}

public struct BNNSLayerParametersLossBase {
    public var function: BNNSLossFunction
    public var i_desc: BNNSNDArrayDescriptor
    public var o_desc: BNNSNDArrayDescriptor
    public var reduction: BNNSLossReductionFunction
    public init() {
        self.function = BNNSLossFunction(rawValue: 0)
        self.i_desc = BNNSNDArrayDescriptor()
        self.o_desc = BNNSNDArrayDescriptor()
        self.reduction = BNNSLossReductionFunction(rawValue: 0)
    }
    public init(function: BNNSLossFunction, i_desc: BNNSNDArrayDescriptor, o_desc: BNNSNDArrayDescriptor, reduction: BNNSLossReductionFunction) { self.init(); self.function = function; self.i_desc = i_desc; self.o_desc = o_desc; self.reduction = reduction }
}

public struct BNNSLayerParametersLossHuber {
    public var function: BNNSLossFunction
    public var huber_delta: Float
    public var i_desc: BNNSNDArrayDescriptor
    public var o_desc: BNNSNDArrayDescriptor
    public var reduction: BNNSLossReductionFunction
    public init() {
        self.function = BNNSLossFunction(rawValue: 0)
        self.huber_delta = 0
        self.i_desc = BNNSNDArrayDescriptor()
        self.o_desc = BNNSNDArrayDescriptor()
        self.reduction = BNNSLossReductionFunction(rawValue: 0)
    }
    public init(function: BNNSLossFunction, i_desc: BNNSNDArrayDescriptor, o_desc: BNNSNDArrayDescriptor, reduction: BNNSLossReductionFunction, huber_delta: Float) { self.init(); self.function = function; self.i_desc = i_desc; self.o_desc = o_desc; self.reduction = reduction; self.huber_delta = huber_delta }
}

public struct BNNSLayerParametersLossSigmoidCrossEntropy {
    public var function: BNNSLossFunction
    public var i_desc: BNNSNDArrayDescriptor
    public var label_smooth: Float
    public var o_desc: BNNSNDArrayDescriptor
    public var reduction: BNNSLossReductionFunction
    public init() {
        self.function = BNNSLossFunction(rawValue: 0)
        self.i_desc = BNNSNDArrayDescriptor()
        self.label_smooth = 0
        self.o_desc = BNNSNDArrayDescriptor()
        self.reduction = BNNSLossReductionFunction(rawValue: 0)
    }
    public init(function: BNNSLossFunction, i_desc: BNNSNDArrayDescriptor, o_desc: BNNSNDArrayDescriptor, reduction: BNNSLossReductionFunction, label_smooth: Float) { self.init(); self.function = function; self.i_desc = i_desc; self.o_desc = o_desc; self.reduction = reduction; self.label_smooth = label_smooth }
}

public struct BNNSLayerParametersLossSoftmaxCrossEntropy {
    public var function: BNNSLossFunction
    public var i_desc: BNNSNDArrayDescriptor
    public var label_smooth: Float
    public var o_desc: BNNSNDArrayDescriptor
    public var reduction: BNNSLossReductionFunction
    public init() {
        self.function = BNNSLossFunction(rawValue: 0)
        self.i_desc = BNNSNDArrayDescriptor()
        self.label_smooth = 0
        self.o_desc = BNNSNDArrayDescriptor()
        self.reduction = BNNSLossReductionFunction(rawValue: 0)
    }
    public init(function: BNNSLossFunction, i_desc: BNNSNDArrayDescriptor, o_desc: BNNSNDArrayDescriptor, reduction: BNNSLossReductionFunction, label_smooth: Float) { self.init(); self.function = function; self.i_desc = i_desc; self.o_desc = o_desc; self.reduction = reduction; self.label_smooth = label_smooth }
}

public struct BNNSLayerParametersLossYolo {
    public var anchor_box_size: Int
    public var anchors_data: UnsafeMutablePointer<Float>
    public var function: BNNSLossFunction
    public var huber_delta: Float
    public var i_desc: BNNSNDArrayDescriptor
    public var no_object_maximum_iou: Float
    public var number_of_anchor_boxes: Int
    public var number_of_grid_columns: Int
    public var number_of_grid_rows: Int
    public var o_desc: BNNSNDArrayDescriptor
    public var object_minimum_iou: Float
    public var reduction: BNNSLossReductionFunction
    public var rescore: Bool
    public var scale_classification: Float
    public var scale_no_object: Float
    public var scale_object: Float
    public var scale_wh: Float
    public var scale_xy: Float
    public init() {
        self.anchor_box_size = 0
        self.anchors_data = UnsafeMutablePointer<Float>.allocate(capacity: 1)
        self.function = BNNSLossFunction(rawValue: 0)
        self.huber_delta = 0
        self.i_desc = BNNSNDArrayDescriptor()
        self.no_object_maximum_iou = 0
        self.number_of_anchor_boxes = 0
        self.number_of_grid_columns = 0
        self.number_of_grid_rows = 0
        self.o_desc = BNNSNDArrayDescriptor()
        self.object_minimum_iou = 0
        self.reduction = BNNSLossReductionFunction(rawValue: 0)
        self.rescore = false
        self.scale_classification = 0
        self.scale_no_object = 0
        self.scale_object = 0
        self.scale_wh = 0
        self.scale_xy = 0
    }
}

public struct BNNSLayerParametersMultiheadAttention {
    public var add_zero_attn: Bool
    public var dropout: Float
    public var key: BNNSMHAProjectionParameters
    public var key_attn_bias: BNNSNDArrayDescriptor
    public var output: BNNSMHAProjectionParameters
    public var query: BNNSMHAProjectionParameters
    public var seed: UInt32
    public var value: BNNSMHAProjectionParameters
    public var value_attn_bias: BNNSNDArrayDescriptor
    public init() {
        self.add_zero_attn = false
        self.dropout = 0
        self.key = BNNSMHAProjectionParameters()
        self.key_attn_bias = BNNSNDArrayDescriptor()
        self.output = BNNSMHAProjectionParameters()
        self.query = BNNSMHAProjectionParameters()
        self.seed = 0
        self.value = BNNSMHAProjectionParameters()
        self.value_attn_bias = BNNSNDArrayDescriptor()
    }
    public init(query: BNNSMHAProjectionParameters, key: BNNSMHAProjectionParameters, value: BNNSMHAProjectionParameters, add_zero_attn: Bool, key_attn_bias: BNNSNDArrayDescriptor, value_attn_bias: BNNSNDArrayDescriptor, output: BNNSMHAProjectionParameters, dropout: Float, seed: UInt32) { self.init(); self.query = query; self.key = key; self.value = value; self.add_zero_attn = add_zero_attn; self.key_attn_bias = key_attn_bias; self.value_attn_bias = value_attn_bias; self.output = output; self.dropout = dropout; self.seed = seed }
}

public struct BNNSLayerParametersNormalization {
    public var activation: BNNSActivation
    public var beta_desc: BNNSNDArrayDescriptor
    public var epsilon: Float
    public var gamma_desc: BNNSNDArrayDescriptor
    public var i_desc: BNNSNDArrayDescriptor
    public var momentum: Float
    public var moving_mean_desc: BNNSNDArrayDescriptor
    public var moving_variance_desc: BNNSNDArrayDescriptor
    public var normalization_axis: Int
    public var num_groups: Int
    public var o_desc: BNNSNDArrayDescriptor
    public init() {
        self.activation = BNNSActivation()
        self.beta_desc = BNNSNDArrayDescriptor()
        self.epsilon = 0
        self.gamma_desc = BNNSNDArrayDescriptor()
        self.i_desc = BNNSNDArrayDescriptor()
        self.momentum = 0
        self.moving_mean_desc = BNNSNDArrayDescriptor()
        self.moving_variance_desc = BNNSNDArrayDescriptor()
        self.normalization_axis = 0
        self.num_groups = 0
        self.o_desc = BNNSNDArrayDescriptor()
    }
    public init(i_desc: BNNSNDArrayDescriptor, o_desc: BNNSNDArrayDescriptor, beta_desc: BNNSNDArrayDescriptor, gamma_desc: BNNSNDArrayDescriptor, moving_mean_desc: BNNSNDArrayDescriptor, moving_variance_desc: BNNSNDArrayDescriptor, momentum: Float, epsilon: Float, activation: BNNSActivation, num_groups: Int, normalization_axis: Int) { self.init(); self.i_desc = i_desc; self.o_desc = o_desc; self.beta_desc = beta_desc; self.gamma_desc = gamma_desc; self.moving_mean_desc = moving_mean_desc; self.moving_variance_desc = moving_variance_desc; self.momentum = momentum; self.epsilon = epsilon; self.activation = activation; self.num_groups = num_groups; self.normalization_axis = normalization_axis }
}

public struct BNNSLayerParametersPadding {
    public var i_desc: BNNSNDArrayDescriptor
    public var o_desc: BNNSNDArrayDescriptor
    public var padding_mode: BNNSPaddingMode
    public var padding_size: ((Int, Int), (Int, Int), (Int, Int), (Int, Int), (Int, Int), (Int, Int), (Int, Int), (Int, Int))
    public var padding_value: UInt32
    public init() {
        self.i_desc = BNNSNDArrayDescriptor()
        self.o_desc = BNNSNDArrayDescriptor()
        self.padding_mode = BNNSPaddingMode(rawValue: 0)
        self.padding_size = ((0, 0), (0, 0), (0, 0), (0, 0), (0, 0), (0, 0), (0, 0), (0, 0))
        self.padding_value = 0
    }
    public init(i_desc: BNNSNDArrayDescriptor, o_desc: BNNSNDArrayDescriptor, padding_size: ((Int, Int), (Int, Int), (Int, Int), (Int, Int), (Int, Int), (Int, Int), (Int, Int), (Int, Int)), padding_mode: BNNSPaddingMode, padding_value: UInt32) { self.init(); self.i_desc = i_desc; self.o_desc = o_desc; self.padding_size = padding_size; self.padding_mode = padding_mode; self.padding_value = padding_value }
}

public struct BNNSLayerParametersPermute {
    public var i_desc: BNNSNDArrayDescriptor
    public var o_desc: BNNSNDArrayDescriptor
    public var permutation: (Int, Int, Int, Int, Int, Int, Int, Int)
    public init() {
        self.i_desc = BNNSNDArrayDescriptor()
        self.o_desc = BNNSNDArrayDescriptor()
        self.permutation = (0, 0, 0, 0, 0, 0, 0, 0)
    }
    public init(i_desc: BNNSNDArrayDescriptor, o_desc: BNNSNDArrayDescriptor, permutation: (Int, Int, Int, Int, Int, Int, Int, Int)) { self.init(); self.i_desc = i_desc; self.o_desc = o_desc; self.permutation = permutation }
}

public struct BNNSLayerParametersPooling {
    public var activation: BNNSActivation
    public var bias: BNNSNDArrayDescriptor
    public var i_desc: BNNSNDArrayDescriptor
    public var k_height: Int
    public var k_width: Int
    public var o_desc: BNNSNDArrayDescriptor
    public var pad: (Int, Int, Int, Int)
    public var pooling_function: BNNSPoolingFunction
    public var x_dilation_stride: Int
    public var x_padding: Int
    public var x_stride: Int
    public var y_dilation_stride: Int
    public var y_padding: Int
    public var y_stride: Int
    public init() {
        self.activation = BNNSActivation()
        self.bias = BNNSNDArrayDescriptor()
        self.i_desc = BNNSNDArrayDescriptor()
        self.k_height = 0
        self.k_width = 0
        self.o_desc = BNNSNDArrayDescriptor()
        self.pad = (0, 0, 0, 0)
        self.pooling_function = BNNSPoolingFunction(rawValue: 0)
        self.x_dilation_stride = 0
        self.x_padding = 0
        self.x_stride = 0
        self.y_dilation_stride = 0
        self.y_padding = 0
        self.y_stride = 0
    }
    public init(i_desc: BNNSNDArrayDescriptor, o_desc: BNNSNDArrayDescriptor, bias: BNNSNDArrayDescriptor, activation: BNNSActivation, pooling_function: BNNSPoolingFunction, k_width: Int, k_height: Int, x_stride: Int, y_stride: Int, x_dilation_stride: Int, y_dilation_stride: Int, x_padding: Int, y_padding: Int, pad: (Int, Int, Int, Int)) { self.init(); self.i_desc = i_desc; self.o_desc = o_desc; self.bias = bias; self.activation = activation; self.pooling_function = pooling_function; self.k_width = k_width; self.k_height = k_height; self.x_stride = x_stride; self.y_stride = y_stride; self.x_dilation_stride = x_dilation_stride; self.y_dilation_stride = y_dilation_stride; self.x_padding = x_padding; self.y_padding = y_padding; self.pad = pad }
}

public struct BNNSLayerParametersQuantization {
    public var axis_mask: Int
    public var bias: BNNSNDArrayDescriptor
    public var function: BNNSQuantizerFunction
    public var i_desc: BNNSNDArrayDescriptor
    public var o_desc: BNNSNDArrayDescriptor
    public var scale: BNNSNDArrayDescriptor
    public init() {
        self.axis_mask = 0
        self.bias = BNNSNDArrayDescriptor()
        self.function = BNNSQuantizerFunction(rawValue: 0)
        self.i_desc = BNNSNDArrayDescriptor()
        self.o_desc = BNNSNDArrayDescriptor()
        self.scale = BNNSNDArrayDescriptor()
    }
    public init(axis_mask: Int, function: BNNSQuantizerFunction, i_desc: BNNSNDArrayDescriptor, o_desc: BNNSNDArrayDescriptor, scale: BNNSNDArrayDescriptor, bias: BNNSNDArrayDescriptor) { self.init(); self.axis_mask = axis_mask; self.function = function; self.i_desc = i_desc; self.o_desc = o_desc; self.scale = scale; self.bias = bias }
}

public struct BNNSLayerParametersReduction {
    public var epsilon: Float
    public var i_desc: BNNSNDArrayDescriptor
    public var o_desc: BNNSNDArrayDescriptor
    public var reduce_func: BNNSReduceFunction
    public var w_desc: BNNSNDArrayDescriptor
    public init() {
        self.epsilon = 0
        self.i_desc = BNNSNDArrayDescriptor()
        self.o_desc = BNNSNDArrayDescriptor()
        self.reduce_func = BNNSReduceFunction(rawValue: 0)
        self.w_desc = BNNSNDArrayDescriptor()
    }
    public init(i_desc: BNNSNDArrayDescriptor, o_desc: BNNSNDArrayDescriptor, w_desc: BNNSNDArrayDescriptor, reduce_func: BNNSReduceFunction, epsilon: Float) { self.init(); self.i_desc = i_desc; self.o_desc = o_desc; self.w_desc = w_desc; self.reduce_func = reduce_func; self.epsilon = epsilon }
}

public struct BNNSLayerParametersResize {
    public var align_corners: Bool
    public var i_desc: BNNSNDArrayDescriptor
    public var method: BNNSInterpolationMethod
    public var o_desc: BNNSNDArrayDescriptor
    public init() {
        self.align_corners = false
        self.i_desc = BNNSNDArrayDescriptor()
        self.method = BNNSInterpolationMethod(rawValue: 0)
        self.o_desc = BNNSNDArrayDescriptor()
    }
    public init(method: BNNSInterpolationMethod, i_desc: BNNSNDArrayDescriptor, o_desc: BNNSNDArrayDescriptor, align_corners: Bool) { self.init(); self.method = method; self.i_desc = i_desc; self.o_desc = o_desc; self.align_corners = align_corners }
}

public struct BNNSLayerParametersTensorContraction {
    public var alpha: Float
    public var beta: Float
    public var iA_desc: BNNSNDArrayDescriptor
    public var iB_desc: BNNSNDArrayDescriptor
    public var o_desc: BNNSNDArrayDescriptor
    public var operation: UnsafePointer<CChar>
    public init() {
        self.alpha = 0
        self.beta = 0
        self.iA_desc = BNNSNDArrayDescriptor()
        self.iB_desc = BNNSNDArrayDescriptor()
        self.o_desc = BNNSNDArrayDescriptor()
        self.operation = UnsafePointer(UnsafeMutablePointer<CChar>.allocate(capacity: 1))
    }
}

public struct BNNSMHAProjectionParameters {
    public var bias: BNNSNDArrayDescriptor
    public var target_desc: BNNSNDArrayDescriptor
    public var weights: BNNSNDArrayDescriptor
    public init() {
        self.bias = BNNSNDArrayDescriptor()
        self.target_desc = BNNSNDArrayDescriptor()
        self.weights = BNNSNDArrayDescriptor()
    }
    public init(target_desc: BNNSNDArrayDescriptor, weights: BNNSNDArrayDescriptor, bias: BNNSNDArrayDescriptor) { self.init(); self.target_desc = target_desc; self.weights = weights; self.bias = bias }
}

public struct BNNSNDArrayDescriptor {
    public var data: UnsafeMutableRawPointer?
    public var data_bias: Float
    public var data_scale: Float
    public var data_type: BNNSDataType
    public var flags: BNNSNDArrayFlags
    public var layout: BNNSDataLayout
    public var size: (Int, Int, Int, Int, Int, Int, Int, Int)
    public var stride: (Int, Int, Int, Int, Int, Int, Int, Int)
    public var table_data: UnsafeMutableRawPointer?
    public var table_data_type: BNNSDataType
    public init() {
        self.data = nil
        self.data_bias = 0
        self.data_scale = 0
        self.data_type = BNNSDataType(rawValue: 0)
        self.flags = BNNSNDArrayFlags(rawValue: 0)
        self.layout = BNNSDataLayout(rawValue: 0)
        self.size = (0, 0, 0, 0, 0, 0, 0, 0)
        self.stride = (0, 0, 0, 0, 0, 0, 0, 0)
        self.table_data = nil
        self.table_data_type = BNNSDataType(rawValue: 0)
    }
    public init?(data: UnsafeMutableRawBufferPointer, scalarType: any BNNSScalar.Type, shape: BNNS.Shape, batchSize: Int) { self.init(); _ = data; _ = scalarType; _ = shape; _ = batchSize; return nil }
    public init?(data: UnsafeMutableRawBufferPointer, scalarType: any BNNSScalar.Type, shape: BNNS.Shape) { self.init(); _ = data; _ = scalarType; _ = shape; return nil }
    public init(dataType: BNNSDataType, shape: BNNS.Shape) { self.init(); _ = dataType; _ = shape }
    public init(flags: BNNSNDArrayFlags, layout: BNNSDataLayout, size: (Int, Int, Int, Int, Int, Int, Int, Int), stride: (Int, Int, Int, Int, Int, Int, Int, Int), data: UnsafeMutableRawPointer?, data_type: BNNSDataType, table_data: UnsafeMutableRawPointer?, table_data_type: BNNSDataType, data_scale: Float, data_bias: Float) { self.init(); self.flags = flags; self.layout = layout; self.size = size; self.stride = stride; self.data = data; self.data_type = data_type; self.table_data = table_data; self.table_data_type = table_data_type; self.data_scale = data_scale; self.data_bias = data_bias }
}

public struct BNNSOptimizerAdamFields {
    public var beta1: Float
    public var beta2: Float
    public var clip_gradients: Bool
    public var clip_gradients_max: Float
    public var clip_gradients_min: Float
    public var epsilon: Float
    public var gradient_scale: Float
    public var learning_rate: Float
    public var regularization_func: BNNSOptimizerRegularizationFunction
    public var regularization_scale: Float
    public var time_step: Float
    public init() {
        self.beta1 = 0
        self.beta2 = 0
        self.clip_gradients = false
        self.clip_gradients_max = 0
        self.clip_gradients_min = 0
        self.epsilon = 0
        self.gradient_scale = 0
        self.learning_rate = 0
        self.regularization_func = BNNSOptimizerRegularizationFunction(rawValue: 0)
        self.regularization_scale = 0
        self.time_step = 0
    }
    public init(learning_rate: Float, beta1: Float, beta2: Float, time_step: Float, epsilon: Float, gradient_scale: Float, regularization_scale: Float, clip_gradients: Bool, clip_gradients_min: Float, clip_gradients_max: Float, regularization_func: BNNSOptimizerRegularizationFunction) { self.init(); self.learning_rate = learning_rate; self.beta1 = beta1; self.beta2 = beta2; self.time_step = time_step; self.epsilon = epsilon; self.gradient_scale = gradient_scale; self.regularization_scale = regularization_scale; self.clip_gradients = clip_gradients; self.clip_gradients_min = clip_gradients_min; self.clip_gradients_max = clip_gradients_max; self.regularization_func = regularization_func }
}

public struct BNNSOptimizerAdamWithClippingFields {
    public var beta1: Float
    public var beta2: Float
    public var clip_gradients_max: Float
    public var clip_gradients_max_norm: Float
    public var clip_gradients_min: Float
    public var clip_gradients_use_norm: Float
    public var clipping_func: BNNSOptimizerClippingFunction
    public var epsilon: Float
    public var gradient_scale: Float
    public var learning_rate: Float
    public var regularization_func: BNNSOptimizerRegularizationFunction
    public var regularization_scale: Float
    public var time_step: Float
    public init() {
        self.beta1 = 0
        self.beta2 = 0
        self.clip_gradients_max = 0
        self.clip_gradients_max_norm = 0
        self.clip_gradients_min = 0
        self.clip_gradients_use_norm = 0
        self.clipping_func = BNNSOptimizerClippingFunction(rawValue: 0)
        self.epsilon = 0
        self.gradient_scale = 0
        self.learning_rate = 0
        self.regularization_func = BNNSOptimizerRegularizationFunction(rawValue: 0)
        self.regularization_scale = 0
        self.time_step = 0
    }
    public init(learning_rate: Float, beta1: Float, beta2: Float, time_step: Float, epsilon: Float, gradient_scale: Float, regularization_scale: Float, regularization_func: BNNSOptimizerRegularizationFunction, clipping_func: BNNSOptimizerClippingFunction, clip_gradients_min: Float, clip_gradients_max: Float, clip_gradients_max_norm: Float, clip_gradients_use_norm: Float) { self.init(); self.learning_rate = learning_rate; self.beta1 = beta1; self.beta2 = beta2; self.time_step = time_step; self.epsilon = epsilon; self.gradient_scale = gradient_scale; self.regularization_scale = regularization_scale; self.regularization_func = regularization_func; self.clipping_func = clipping_func; self.clip_gradients_min = clip_gradients_min; self.clip_gradients_max = clip_gradients_max; self.clip_gradients_max_norm = clip_gradients_max_norm; self.clip_gradients_use_norm = clip_gradients_use_norm }
}

public struct BNNSOptimizerRMSPropFields {
    public var alpha: Float
    public var centered: Bool
    public var clip_gradients: Bool
    public var clip_gradients_max: Float
    public var clip_gradients_min: Float
    public var epsilon: Float
    public var gradient_scale: Float
    public var learning_rate: Float
    public var momentum: Float
    public var regularization_func: BNNSOptimizerRegularizationFunction
    public var regularization_scale: Float
    public init() {
        self.alpha = 0
        self.centered = false
        self.clip_gradients = false
        self.clip_gradients_max = 0
        self.clip_gradients_min = 0
        self.epsilon = 0
        self.gradient_scale = 0
        self.learning_rate = 0
        self.momentum = 0
        self.regularization_func = BNNSOptimizerRegularizationFunction(rawValue: 0)
        self.regularization_scale = 0
    }
    public init(learning_rate: Float, alpha: Float, epsilon: Float, centered: Bool, momentum: Float, gradient_scale: Float, regularization_scale: Float, clip_gradients: Bool, clip_gradients_min: Float, clip_gradients_max: Float, regularization_func: BNNSOptimizerRegularizationFunction) { self.init(); self.learning_rate = learning_rate; self.alpha = alpha; self.epsilon = epsilon; self.centered = centered; self.momentum = momentum; self.gradient_scale = gradient_scale; self.regularization_scale = regularization_scale; self.clip_gradients = clip_gradients; self.clip_gradients_min = clip_gradients_min; self.clip_gradients_max = clip_gradients_max; self.regularization_func = regularization_func }
}

public struct BNNSOptimizerRMSPropWithClippingFields {
    public var alpha: Float
    public var centered: Bool
    public var clip_gradients_max: Float
    public var clip_gradients_max_norm: Float
    public var clip_gradients_min: Float
    public var clip_gradients_use_norm: Float
    public var clipping_func: BNNSOptimizerClippingFunction
    public var epsilon: Float
    public var gradient_scale: Float
    public var learning_rate: Float
    public var momentum: Float
    public var regularization_func: BNNSOptimizerRegularizationFunction
    public var regularization_scale: Float
    public init() {
        self.alpha = 0
        self.centered = false
        self.clip_gradients_max = 0
        self.clip_gradients_max_norm = 0
        self.clip_gradients_min = 0
        self.clip_gradients_use_norm = 0
        self.clipping_func = BNNSOptimizerClippingFunction(rawValue: 0)
        self.epsilon = 0
        self.gradient_scale = 0
        self.learning_rate = 0
        self.momentum = 0
        self.regularization_func = BNNSOptimizerRegularizationFunction(rawValue: 0)
        self.regularization_scale = 0
    }
    public init(learning_rate: Float, alpha: Float, epsilon: Float, centered: Bool, momentum: Float, gradient_scale: Float, regularization_scale: Float, regularization_func: BNNSOptimizerRegularizationFunction, clipping_func: BNNSOptimizerClippingFunction, clip_gradients_min: Float, clip_gradients_max: Float, clip_gradients_max_norm: Float, clip_gradients_use_norm: Float) { self.init(); self.learning_rate = learning_rate; self.alpha = alpha; self.epsilon = epsilon; self.centered = centered; self.momentum = momentum; self.gradient_scale = gradient_scale; self.regularization_scale = regularization_scale; self.regularization_func = regularization_func; self.clipping_func = clipping_func; self.clip_gradients_min = clip_gradients_min; self.clip_gradients_max = clip_gradients_max; self.clip_gradients_max_norm = clip_gradients_max_norm; self.clip_gradients_use_norm = clip_gradients_use_norm }
}

public struct BNNSOptimizerSGDMomentumFields {
    public var clip_gradients: Bool
    public var clip_gradients_max: Float
    public var clip_gradients_min: Float
    public var gradient_scale: Float
    public var learning_rate: Float
    public var momentum: Float
    public var nesterov: Bool
    public var regularization_func: BNNSOptimizerRegularizationFunction
    public var regularization_scale: Float
    public var sgd_momentum_variant: BNNSOptimizerSGDMomentumVariant
    public init() {
        self.clip_gradients = false
        self.clip_gradients_max = 0
        self.clip_gradients_min = 0
        self.gradient_scale = 0
        self.learning_rate = 0
        self.momentum = 0
        self.nesterov = false
        self.regularization_func = BNNSOptimizerRegularizationFunction(rawValue: 0)
        self.regularization_scale = 0
        self.sgd_momentum_variant = BNNSOptimizerSGDMomentumVariant(rawValue: 0)
    }
    public init(learning_rate: Float, momentum: Float, gradient_scale: Float, regularization_scale: Float, clip_gradients: Bool, clip_gradients_min: Float, clip_gradients_max: Float, nesterov: Bool, regularization_func: BNNSOptimizerRegularizationFunction, sgd_momentum_variant: BNNSOptimizerSGDMomentumVariant) { self.init(); self.learning_rate = learning_rate; self.momentum = momentum; self.gradient_scale = gradient_scale; self.regularization_scale = regularization_scale; self.clip_gradients = clip_gradients; self.clip_gradients_min = clip_gradients_min; self.clip_gradients_max = clip_gradients_max; self.nesterov = nesterov; self.regularization_func = regularization_func; self.sgd_momentum_variant = sgd_momentum_variant }
}

public struct BNNSOptimizerSGDMomentumWithClippingFields {
    public var clip_gradients_max: Float
    public var clip_gradients_max_norm: Float
    public var clip_gradients_min: Float
    public var clip_gradients_use_norm: Float
    public var clipping_func: BNNSOptimizerClippingFunction
    public var gradient_scale: Float
    public var learning_rate: Float
    public var momentum: Float
    public var nesterov: Bool
    public var regularization_func: BNNSOptimizerRegularizationFunction
    public var regularization_scale: Float
    public var sgd_momentum_variant: BNNSOptimizerSGDMomentumVariant
    public init() {
        self.clip_gradients_max = 0
        self.clip_gradients_max_norm = 0
        self.clip_gradients_min = 0
        self.clip_gradients_use_norm = 0
        self.clipping_func = BNNSOptimizerClippingFunction(rawValue: 0)
        self.gradient_scale = 0
        self.learning_rate = 0
        self.momentum = 0
        self.nesterov = false
        self.regularization_func = BNNSOptimizerRegularizationFunction(rawValue: 0)
        self.regularization_scale = 0
        self.sgd_momentum_variant = BNNSOptimizerSGDMomentumVariant(rawValue: 0)
    }
    public init(learning_rate: Float, momentum: Float, gradient_scale: Float, regularization_scale: Float, nesterov: Bool, regularization_func: BNNSOptimizerRegularizationFunction, sgd_momentum_variant: BNNSOptimizerSGDMomentumVariant, clipping_func: BNNSOptimizerClippingFunction, clip_gradients_min: Float, clip_gradients_max: Float, clip_gradients_max_norm: Float, clip_gradients_use_norm: Float) { self.init(); self.learning_rate = learning_rate; self.momentum = momentum; self.gradient_scale = gradient_scale; self.regularization_scale = regularization_scale; self.nesterov = nesterov; self.regularization_func = regularization_func; self.sgd_momentum_variant = sgd_momentum_variant; self.clipping_func = clipping_func; self.clip_gradients_min = clip_gradients_min; self.clip_gradients_max = clip_gradients_max; self.clip_gradients_max_norm = clip_gradients_max_norm; self.clip_gradients_use_norm = clip_gradients_use_norm }
}

public struct BNNSPoolingLayerParameters {
    public var activation: BNNSActivation
    public var bias: BNNSLayerData
    public var in_channels: Int
    public var k_height: Int
    public var k_width: Int
    public var out_channels: Int
    public var pooling_function: BNNSPoolingFunction
    public var x_padding: Int
    public var x_stride: Int
    public var y_padding: Int
    public var y_stride: Int
    public init() {
        self.activation = BNNSActivation()
        self.bias = BNNSLayerData()
        self.in_channels = 0
        self.k_height = 0
        self.k_width = 0
        self.out_channels = 0
        self.pooling_function = BNNSPoolingFunction(rawValue: 0)
        self.x_padding = 0
        self.x_stride = 0
        self.y_padding = 0
        self.y_stride = 0
    }
    public init(x_stride: Int, y_stride: Int, x_padding: Int, y_padding: Int, k_width: Int, k_height: Int, in_channels: Int, out_channels: Int, pooling_function: BNNSPoolingFunction) { self.init(); self.x_stride = x_stride; self.y_stride = y_stride; self.x_padding = x_padding; self.y_padding = y_padding; self.k_width = k_width; self.k_height = k_height; self.in_channels = in_channels; self.out_channels = out_channels; self.pooling_function = pooling_function }
    public init(x_stride: Int, y_stride: Int, x_padding: Int, y_padding: Int, k_width: Int, k_height: Int, in_channels: Int, out_channels: Int, pooling_function: BNNSPoolingFunction, bias: BNNSLayerData, activation: BNNSActivation) { self.init(); self.x_stride = x_stride; self.y_stride = y_stride; self.x_padding = x_padding; self.y_padding = y_padding; self.k_width = k_width; self.k_height = k_height; self.in_channels = in_channels; self.out_channels = out_channels; self.pooling_function = pooling_function; self.bias = bias; self.activation = activation }
}

public struct BNNSSparsityParameters {
    public var flags: UInt64
    public var sparsity_ratio: (UInt32, UInt32)
    public var sparsity_type: BNNSSparsityType
    public var target_system: BNNSTargetSystem
    public init() {
        self.flags = 0
        self.sparsity_ratio = (0, 0)
        self.sparsity_type = BNNSSparsityType(rawValue: 0)
        self.target_system = BNNSTargetSystem(rawValue: 0)
    }
    public init(flags: UInt64, sparsity_ratio: (UInt32, UInt32), sparsity_type: BNNSSparsityType, target_system: BNNSTargetSystem) { self.init(); self.flags = flags; self.sparsity_ratio = sparsity_ratio; self.sparsity_type = sparsity_type; self.target_system = target_system }
}

public struct BNNSTensor {
    public var data: UnsafeMutableRawPointer?
    public var data_size_in_bytes: Int
    public var data_type: BNNSDataType
    public var name: UnsafePointer<CChar>?
    public var rank: UInt8
    public var shape: (Int, Int, Int, Int, Int, Int, Int, Int)
    public var stride: (Int, Int, Int, Int, Int, Int, Int, Int)
    public init() {
        self.data = nil
        self.data_size_in_bytes = 0
        self.data_type = BNNSDataType(rawValue: 0)
        self.name = nil
        self.rank = 0
        self.shape = (0, 0, 0, 0, 0, 0, 0, 0)
        self.stride = (0, 0, 0, 0, 0, 0, 0, 0)
    }
    public init(data: UnsafeMutableRawBufferPointer, shape: [Int], stride: [Int], dataType: BNNSDataType) { self.init(); _ = data; _ = shape; _ = stride; _ = dataType }
    public init(shape: [Int], stride: [Int], dataType: BNNSDataType) { self.init(); _ = shape; _ = stride; _ = dataType }
    public init(dataType: BNNSDataType, shape: [Int], stride: [Int]) { self.init(); _ = dataType; _ = shape; _ = stride }
}

public struct BNNSVectorDescriptor {
    public var data_bias: Float
    public var data_scale: Float
    public var data_type: BNNSDataType
    public var size: Int
    public init() {
        self.data_bias = 0
        self.data_scale = 0
        self.data_type = BNNSDataType(rawValue: 0)
        self.size = 0
    }
    public init(size: Int, data_type: BNNSDataType) { self.init(); self.size = size; self.data_type = data_type }
    public init(size: Int, data_type: BNNSDataType, data_scale: Float, data_bias: Float) { self.init(); self.size = size; self.data_type = data_type; self.data_scale = data_scale; self.data_bias = data_bias }
}

public struct DenseMatrix_Complex_Double {
    public var attributes: SparseAttributesComplex_t
    public var columnCount: Int32
    public var columnStride: Int32
    public var data: OpaquePointer
    public var rowCount: Int32
    public init() {
        self.attributes = SparseAttributesComplex_t()
        self.columnCount = 0
        self.columnStride = 0
        self.data = OpaquePointer(bitPattern: 1)!
        self.rowCount = 0
    }
    public init(rowCount: Int32, columnCount: Int32, columnStride: Int32, attributes: SparseAttributesComplex_t, data: OpaquePointer) { self.init(); self.rowCount = rowCount; self.columnCount = columnCount; self.columnStride = columnStride; self.attributes = attributes; self.data = data }
}

public struct DenseMatrix_Complex_Float {
    public var attributes: SparseAttributesComplex_t
    public var columnCount: Int32
    public var columnStride: Int32
    public var data: OpaquePointer
    public var rowCount: Int32
    public init() {
        self.attributes = SparseAttributesComplex_t()
        self.columnCount = 0
        self.columnStride = 0
        self.data = OpaquePointer(bitPattern: 1)!
        self.rowCount = 0
    }
    public init(rowCount: Int32, columnCount: Int32, columnStride: Int32, attributes: SparseAttributesComplex_t, data: OpaquePointer) { self.init(); self.rowCount = rowCount; self.columnCount = columnCount; self.columnStride = columnStride; self.attributes = attributes; self.data = data }
}

public struct DenseMatrix_Double {
    public var attributes: SparseAttributes_t
    public var columnCount: Int32
    public var columnStride: Int32
    public var data: UnsafeMutablePointer<Double>
    public var rowCount: Int32
    public init() {
        self.attributes = SparseAttributes_t()
        self.columnCount = 0
        self.columnStride = 0
        self.data = UnsafeMutablePointer<Double>.allocate(capacity: 1)
        self.rowCount = 0
    }
    public init(
        rowCount: Int32,
        columnCount: Int32,
        columnStride: Int32,
        attributes: SparseAttributes_t,
        data: UnsafeMutablePointer<Double>
    ) {
        self.rowCount = rowCount
        self.columnCount = columnCount
        self.columnStride = columnStride
        self.attributes = attributes
        self.data = data
    }
}

public struct DenseMatrix_Float {
    public var attributes: SparseAttributes_t
    public var columnCount: Int32
    public var columnStride: Int32
    public var data: UnsafeMutablePointer<Float>
    public var rowCount: Int32
    public init() {
        self.attributes = SparseAttributes_t()
        self.columnCount = 0
        self.columnStride = 0
        self.data = UnsafeMutablePointer<Float>.allocate(capacity: 1)
        self.rowCount = 0
    }
    public init(
        rowCount: Int32,
        columnCount: Int32,
        columnStride: Int32,
        attributes: SparseAttributes_t,
        data: UnsafeMutablePointer<Float>
    ) {
        self.rowCount = rowCount
        self.columnCount = columnCount
        self.columnStride = columnStride
        self.attributes = attributes
        self.data = data
    }
}

public struct DenseVector_Complex_Double {
    public var count: Int32
    public var data: OpaquePointer
    public init() {
        self.count = 0
        self.data = OpaquePointer(bitPattern: 1)!
    }
    public init(count: Int32, data: OpaquePointer) { self.init(); self.count = count; self.data = data }
}

public struct DenseVector_Complex_Float {
    public var count: Int32
    public var data: OpaquePointer
    public init() {
        self.count = 0
        self.data = OpaquePointer(bitPattern: 1)!
    }
    public init(count: Int32, data: OpaquePointer) { self.init(); self.count = count; self.data = data }
}

public struct DenseVector_Double {
    public var count: Int32
    public var data: UnsafeMutablePointer<Double>
    public init() {
        self.count = 0
        self.data = UnsafeMutablePointer<Double>.allocate(capacity: 1)
    }
    public init(count: Int32, data: UnsafeMutablePointer<Double>) {
        self.count = count
        self.data = data
    }
}

public struct DenseVector_Float {
    public var count: Int32
    public var data: UnsafeMutablePointer<Float>
    public init() {
        self.count = 0
        self.data = UnsafeMutablePointer<Float>.allocate(capacity: 1)
    }
    public init(count: Int32, data: UnsafeMutablePointer<Float>) {
        self.count = count
        self.data = data
    }
}

public struct SparseAttributesComplex_t {
    public var conjugate_transpose: Bool
    public var kind: SparseKind_t
    public var transpose: Bool
    public var triangle: SparseTriangle_t
    public init() {
        self.conjugate_transpose = false
        self.kind = SparseKind_t(rawValue: 0)
        self.transpose = false
        self.triangle = SparseTriangle_t(rawValue: 0)
    }
}

public struct SparseAttributes_t {
    public var kind: SparseKind_t
    public var transpose: Bool
    public var triangle: SparseTriangle_t
    public init() {
        self.kind = SparseKind_t(rawValue: 0)
        self.transpose = false
        self.triangle = SparseTriangle_t(rawValue: 0)
    }
}

public struct SparseCGOptions {
    public var atol: Double
    public var maxIterations: Int32
    public var reportError: ((UnsafePointer<CChar>) -> Void)?
    public var reportStatus: ((UnsafePointer<CChar>) -> Void)?
    public var rtol: Double
    public init() {
        self.atol = 0
        self.maxIterations = 0
        self.reportError = nil
        self.reportStatus = nil
        self.rtol = 0
    }
}

public struct SparseGMRESOptions {
    public var atol: Double
    public var maxIterations: Int32
    public var nvec: Int32
    public var reportError: ((UnsafePointer<CChar>) -> Void)?
    public var reportStatus: ((UnsafePointer<CChar>) -> Void)?
    public var rtol: Double
    public var variant: SparseGMRESVariant_t
    public init() {
        self.atol = 0
        self.maxIterations = 0
        self.nvec = 0
        self.reportError = nil
        self.reportStatus = nil
        self.rtol = 0
        self.variant = SparseGMRESVariant_t(rawValue: 0)
    }
}

public struct SparseIterativeMethod {
    public var method: Int32
    public var options: UInt64
    public init() {
        self.method = 0
        self.options = 0
    }
}

public struct SparseLSMROptions {
    public var atol: Double
    public var btol: Double
    public var conditionLimit: Double
    public var convergenceTest: SparseLSMRConvergenceTest_t
    public var lambda: Double
    public var maxIterations: Int32
    public var nvec: Int32
    public var reportError: ((UnsafePointer<CChar>) -> Void)?
    public var reportStatus: ((UnsafePointer<CChar>) -> Void)?
    public var rtol: Double
    public init() {
        self.atol = 0
        self.btol = 0
        self.conditionLimit = 0
        self.convergenceTest = SparseLSMRConvergenceTest_t(rawValue: 0)
        self.lambda = 0
        self.maxIterations = 0
        self.nvec = 0
        self.reportError = nil
        self.reportStatus = nil
        self.rtol = 0
    }
}

public struct SparseMatrixStructure {
    public var attributes: SparseAttributes_t
    public var blockSize: UInt8
    public var columnCount: Int32
    public var columnStarts: UnsafeMutablePointer<Int>
    public var rowCount: Int32
    public var rowIndices: UnsafeMutablePointer<Int32>
    public init() {
        self.attributes = SparseAttributes_t()
        self.blockSize = 0
        self.columnCount = 0
        self.columnStarts = UnsafeMutablePointer<Int>.allocate(capacity: 1)
        self.rowCount = 0
        self.rowIndices = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
    }
}

public struct SparseMatrixStructureComplex {
    public var attributes: SparseAttributesComplex_t
    public var blockSize: UInt8
    public var columnCount: Int32
    public var columnStarts: UnsafeMutablePointer<Int>
    public var rowCount: Int32
    public var rowIndices: UnsafeMutablePointer<Int32>
    public init() {
        self.attributes = SparseAttributesComplex_t()
        self.blockSize = 0
        self.columnCount = 0
        self.columnStarts = UnsafeMutablePointer<Int>.allocate(capacity: 1)
        self.rowCount = 0
        self.rowIndices = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
    }
}

public struct SparseMatrix_Complex_Double {
    public var data: OpaquePointer
    public var structure: SparseMatrixStructureComplex
    public init() {
        self.data = OpaquePointer(bitPattern: 1)!
        self.structure = SparseMatrixStructureComplex()
    }
    public init(structure: SparseMatrixStructureComplex, data: OpaquePointer) { self.init(); self.structure = structure; self.data = data }
}

public struct SparseMatrix_Complex_Float {
    public var data: OpaquePointer
    public var structure: SparseMatrixStructureComplex
    public init() {
        self.data = OpaquePointer(bitPattern: 1)!
        self.structure = SparseMatrixStructureComplex()
    }
    public init(structure: SparseMatrixStructureComplex, data: OpaquePointer) { self.init(); self.structure = structure; self.data = data }
}

public struct SparseMatrix_Double {
    public var data: UnsafeMutablePointer<Double>
    public var structure: SparseMatrixStructure
    public init() {
        self.data = UnsafeMutablePointer<Double>.allocate(capacity: 1)
        self.structure = SparseMatrixStructure()
    }
}

public struct SparseMatrix_Float {
    public var data: UnsafeMutablePointer<Float>
    public var structure: SparseMatrixStructure
    public init() {
        self.data = UnsafeMutablePointer<Float>.allocate(capacity: 1)
        self.structure = SparseMatrixStructure()
    }
}

public struct SparseNumericFactorOptions {
    public var control: SparseControl_t
    public var pivotTolerance: Double
    public var scaling: UnsafeMutableRawPointer?
    public var scalingMethod: SparseScaling_t
    public var zeroTolerance: Double
    public init() {
        self.control = SparseControl_t(rawValue: 0)
        self.pivotTolerance = 0
        self.scaling = nil
        self.scalingMethod = SparseScaling_t(rawValue: 0)
        self.zeroTolerance = 0
    }
    public init(control: SparseControl_t, scalingMethod: SparseScaling_t, scaling: UnsafeMutableRawPointer?, pivotTolerance: Double, zeroTolerance: Double) { self.init(); self.control = control; self.scalingMethod = scalingMethod; self.scaling = scaling; self.pivotTolerance = pivotTolerance; self.zeroTolerance = zeroTolerance }
}

public struct SparseOpaqueFactorization_Complex_Double {
    public var attributes: SparseAttributesComplex_t
    public var numericFactorization: UnsafeMutableRawPointer?
    public var solveWorkspaceRequiredPerRHS: Int
    public var solveWorkspaceRequiredStatic: Int
    public var status: SparseStatus_t
    public var symbolicFactorization: SparseOpaqueSymbolicFactorization
    public var userFactorStorage: Bool
    public init() {
        self.attributes = SparseAttributesComplex_t()
        self.numericFactorization = nil
        self.solveWorkspaceRequiredPerRHS = 0
        self.solveWorkspaceRequiredStatic = 0
        self.status = SparseStatus_t(rawValue: 0)
        self.symbolicFactorization = SparseOpaqueSymbolicFactorization()
        self.userFactorStorage = false
    }
    public init(status: SparseStatus_t, attributes: SparseAttributesComplex_t, symbolicFactorization: SparseOpaqueSymbolicFactorization, userFactorStorage: Bool, numericFactorization: UnsafeMutableRawPointer?, solveWorkspaceRequiredStatic: Int, solveWorkspaceRequiredPerRHS: Int) { self.init(); self.status = status; self.attributes = attributes; self.symbolicFactorization = symbolicFactorization; self.userFactorStorage = userFactorStorage; self.numericFactorization = numericFactorization; self.solveWorkspaceRequiredStatic = solveWorkspaceRequiredStatic; self.solveWorkspaceRequiredPerRHS = solveWorkspaceRequiredPerRHS }
}

public struct SparseOpaqueFactorization_Complex_Float {
    public var attributes: SparseAttributesComplex_t
    public var numericFactorization: UnsafeMutableRawPointer?
    public var solveWorkspaceRequiredPerRHS: Int
    public var solveWorkspaceRequiredStatic: Int
    public var status: SparseStatus_t
    public var symbolicFactorization: SparseOpaqueSymbolicFactorization
    public var userFactorStorage: Bool
    public init() {
        self.attributes = SparseAttributesComplex_t()
        self.numericFactorization = nil
        self.solveWorkspaceRequiredPerRHS = 0
        self.solveWorkspaceRequiredStatic = 0
        self.status = SparseStatus_t(rawValue: 0)
        self.symbolicFactorization = SparseOpaqueSymbolicFactorization()
        self.userFactorStorage = false
    }
    public init(status: SparseStatus_t, attributes: SparseAttributesComplex_t, symbolicFactorization: SparseOpaqueSymbolicFactorization, userFactorStorage: Bool, numericFactorization: UnsafeMutableRawPointer?, solveWorkspaceRequiredStatic: Int, solveWorkspaceRequiredPerRHS: Int) { self.init(); self.status = status; self.attributes = attributes; self.symbolicFactorization = symbolicFactorization; self.userFactorStorage = userFactorStorage; self.numericFactorization = numericFactorization; self.solveWorkspaceRequiredStatic = solveWorkspaceRequiredStatic; self.solveWorkspaceRequiredPerRHS = solveWorkspaceRequiredPerRHS }
}

public struct SparseOpaqueFactorization_Double {
    public var attributes: SparseAttributes_t
    public var numericFactorization: UnsafeMutableRawPointer?
    public var solveWorkspaceRequiredPerRHS: Int
    public var solveWorkspaceRequiredStatic: Int
    public var status: SparseStatus_t
    public var symbolicFactorization: SparseOpaqueSymbolicFactorization
    public var userFactorStorage: Bool
    public init() {
        self.attributes = SparseAttributes_t()
        self.numericFactorization = nil
        self.solveWorkspaceRequiredPerRHS = 0
        self.solveWorkspaceRequiredStatic = 0
        self.status = SparseStatus_t(rawValue: 0)
        self.symbolicFactorization = SparseOpaqueSymbolicFactorization()
        self.userFactorStorage = false
    }
    public init(status: SparseStatus_t, attributes: SparseAttributes_t, symbolicFactorization: SparseOpaqueSymbolicFactorization, userFactorStorage: Bool, numericFactorization: UnsafeMutableRawPointer?, solveWorkspaceRequiredStatic: Int, solveWorkspaceRequiredPerRHS: Int) { self.init(); self.status = status; self.attributes = attributes; self.symbolicFactorization = symbolicFactorization; self.userFactorStorage = userFactorStorage; self.numericFactorization = numericFactorization; self.solveWorkspaceRequiredStatic = solveWorkspaceRequiredStatic; self.solveWorkspaceRequiredPerRHS = solveWorkspaceRequiredPerRHS }
}

public struct SparseOpaqueFactorization_Float {
    public var attributes: SparseAttributes_t
    public var numericFactorization: UnsafeMutableRawPointer?
    public var solveWorkspaceRequiredPerRHS: Int
    public var solveWorkspaceRequiredStatic: Int
    public var status: SparseStatus_t
    public var symbolicFactorization: SparseOpaqueSymbolicFactorization
    public var userFactorStorage: Bool
    public init() {
        self.attributes = SparseAttributes_t()
        self.numericFactorization = nil
        self.solveWorkspaceRequiredPerRHS = 0
        self.solveWorkspaceRequiredStatic = 0
        self.status = SparseStatus_t(rawValue: 0)
        self.symbolicFactorization = SparseOpaqueSymbolicFactorization()
        self.userFactorStorage = false
    }
    public init(status: SparseStatus_t, attributes: SparseAttributes_t, symbolicFactorization: SparseOpaqueSymbolicFactorization, userFactorStorage: Bool, numericFactorization: UnsafeMutableRawPointer?, solveWorkspaceRequiredStatic: Int, solveWorkspaceRequiredPerRHS: Int) { self.init(); self.status = status; self.attributes = attributes; self.symbolicFactorization = symbolicFactorization; self.userFactorStorage = userFactorStorage; self.numericFactorization = numericFactorization; self.solveWorkspaceRequiredStatic = solveWorkspaceRequiredStatic; self.solveWorkspaceRequiredPerRHS = solveWorkspaceRequiredPerRHS }
}

public struct SparseOpaquePreconditioner_Complex_Double {
    public var apply: (UnsafeMutableRawPointer, CBLAS_TRANSPOSE, DenseMatrix_Complex_Double, DenseMatrix_Complex_Double) -> Void
    public var mem: UnsafeMutableRawPointer
    public var type: SparsePreconditioner_t
    public init() {
        self.apply = { _, _, _, _ in }
        self.mem = _accelerateDummyPointer()
        self.type = SparsePreconditioner_t(rawValue: 0)
    }
    public init(type: SparsePreconditioner_t, mem: UnsafeMutableRawPointer, apply: (UnsafeMutableRawPointer, CBLAS_TRANSPOSE, DenseMatrix_Complex_Double, DenseMatrix_Complex_Double) -> Void) { self.init(); self.type = type; self.mem = mem; _ = apply }
}

public struct SparseOpaquePreconditioner_Complex_Float {
    public var apply: (UnsafeMutableRawPointer, CBLAS_TRANSPOSE, DenseMatrix_Complex_Float, DenseMatrix_Complex_Float) -> Void
    public var mem: UnsafeMutableRawPointer
    public var type: SparsePreconditioner_t
    public init() {
        self.apply = { _, _, _, _ in }
        self.mem = _accelerateDummyPointer()
        self.type = SparsePreconditioner_t(rawValue: 0)
    }
    public init(type: SparsePreconditioner_t, mem: UnsafeMutableRawPointer, apply: (UnsafeMutableRawPointer, CBLAS_TRANSPOSE, DenseMatrix_Complex_Float, DenseMatrix_Complex_Float) -> Void) { self.init(); self.type = type; self.mem = mem; _ = apply }
}

public struct SparseOpaquePreconditioner_Double {
    public var apply: (UnsafeMutableRawPointer, CBLAS_TRANSPOSE, DenseMatrix_Double, DenseMatrix_Double) -> Void
    public var mem: UnsafeMutableRawPointer
    public var type: SparsePreconditioner_t
    public init() {
        self.apply = { _, _, _, _ in }
        self.mem = _accelerateDummyPointer()
        self.type = SparsePreconditioner_t(rawValue: 0)
    }
    public init(type: SparsePreconditioner_t, mem: UnsafeMutableRawPointer, apply: (UnsafeMutableRawPointer, CBLAS_TRANSPOSE, DenseMatrix_Double, DenseMatrix_Double) -> Void) { self.init(); self.type = type; self.mem = mem; _ = apply }
}

public struct SparseOpaquePreconditioner_Float {
    public var apply: (UnsafeMutableRawPointer, CBLAS_TRANSPOSE, DenseMatrix_Float, DenseMatrix_Float) -> Void
    public var mem: UnsafeMutableRawPointer
    public var type: SparsePreconditioner_t
    public init() {
        self.apply = { _, _, _, _ in }
        self.mem = _accelerateDummyPointer()
        self.type = SparsePreconditioner_t(rawValue: 0)
    }
    public init(type: SparsePreconditioner_t, mem: UnsafeMutableRawPointer, apply: (UnsafeMutableRawPointer, CBLAS_TRANSPOSE, DenseMatrix_Float, DenseMatrix_Float) -> Void) { self.init(); self.type = type; self.mem = mem; _ = apply }
}

public struct SparseOpaqueSubfactor_Complex_Double {
    public var attributes: SparseAttributesComplex_t
    public var contents: SparseSubfactor_t
    public var factor: SparseOpaqueFactorization_Complex_Double
    public var workspaceRequiredPerRHS: Int
    public var workspaceRequiredStatic: Int
    public init() {
        self.attributes = SparseAttributesComplex_t()
        self.contents = SparseSubfactor_t(rawValue: 0)
        self.factor = SparseOpaqueFactorization_Complex_Double()
        self.workspaceRequiredPerRHS = 0
        self.workspaceRequiredStatic = 0
    }
    public init(attributes: SparseAttributesComplex_t, contents: SparseSubfactor_t, factor: SparseOpaqueFactorization_Complex_Double, workspaceRequiredStatic: Int, workspaceRequiredPerRHS: Int) { self.init(); self.attributes = attributes; self.contents = contents; self.factor = factor; self.workspaceRequiredStatic = workspaceRequiredStatic; self.workspaceRequiredPerRHS = workspaceRequiredPerRHS }
}

public struct SparseOpaqueSubfactor_Complex_Float {
    public var attributes: SparseAttributesComplex_t
    public var contents: SparseSubfactor_t
    public var factor: SparseOpaqueFactorization_Complex_Float
    public var workspaceRequiredPerRHS: Int
    public var workspaceRequiredStatic: Int
    public init() {
        self.attributes = SparseAttributesComplex_t()
        self.contents = SparseSubfactor_t(rawValue: 0)
        self.factor = SparseOpaqueFactorization_Complex_Float()
        self.workspaceRequiredPerRHS = 0
        self.workspaceRequiredStatic = 0
    }
    public init(attributes: SparseAttributesComplex_t, contents: SparseSubfactor_t, factor: SparseOpaqueFactorization_Complex_Float, workspaceRequiredStatic: Int, workspaceRequiredPerRHS: Int) { self.init(); self.attributes = attributes; self.contents = contents; self.factor = factor; self.workspaceRequiredStatic = workspaceRequiredStatic; self.workspaceRequiredPerRHS = workspaceRequiredPerRHS }
}

public struct SparseOpaqueSubfactor_Double {
    public var attributes: SparseAttributes_t
    public var contents: SparseSubfactor_t
    public var factor: SparseOpaqueFactorization_Double
    public var workspaceRequiredPerRHS: Int
    public var workspaceRequiredStatic: Int
    public init() {
        self.attributes = SparseAttributes_t()
        self.contents = SparseSubfactor_t(rawValue: 0)
        self.factor = SparseOpaqueFactorization_Double()
        self.workspaceRequiredPerRHS = 0
        self.workspaceRequiredStatic = 0
    }
    public init(attributes: SparseAttributes_t, contents: SparseSubfactor_t, factor: SparseOpaqueFactorization_Double, workspaceRequiredStatic: Int, workspaceRequiredPerRHS: Int) { self.init(); self.attributes = attributes; self.contents = contents; self.factor = factor; self.workspaceRequiredStatic = workspaceRequiredStatic; self.workspaceRequiredPerRHS = workspaceRequiredPerRHS }
}

public struct SparseOpaqueSubfactor_Float {
    public var attributes: SparseAttributes_t
    public var contents: SparseSubfactor_t
    public var factor: SparseOpaqueFactorization_Float
    public var workspaceRequiredPerRHS: Int
    public var workspaceRequiredStatic: Int
    public init() {
        self.attributes = SparseAttributes_t()
        self.contents = SparseSubfactor_t(rawValue: 0)
        self.factor = SparseOpaqueFactorization_Float()
        self.workspaceRequiredPerRHS = 0
        self.workspaceRequiredStatic = 0
    }
    public init(attributes: SparseAttributes_t, contents: SparseSubfactor_t, factor: SparseOpaqueFactorization_Float, workspaceRequiredStatic: Int, workspaceRequiredPerRHS: Int) { self.init(); self.attributes = attributes; self.contents = contents; self.factor = factor; self.workspaceRequiredStatic = workspaceRequiredStatic; self.workspaceRequiredPerRHS = workspaceRequiredPerRHS }
}

public struct SparseOpaqueSymbolicFactorization {
    public var attributes: SparseAttributes_t
    public var blockSize: UInt8
    public var columnCount: Int32
    public var factorSize_Double: Int
    public var factorSize_Float: Int
    public var factorization: UnsafeMutableRawPointer?
    public var rowCount: Int32
    public var status: SparseStatus_t
    public var type: SparseFactorization_t
    public var workspaceSize_Double: Int
    public var workspaceSize_Float: Int
    public init() {
        self.attributes = SparseAttributes_t()
        self.blockSize = 0
        self.columnCount = 0
        self.factorSize_Double = 0
        self.factorSize_Float = 0
        self.factorization = nil
        self.rowCount = 0
        self.status = SparseStatus_t(rawValue: 0)
        self.type = SparseFactorization_t(rawValue: 0)
        self.workspaceSize_Double = 0
        self.workspaceSize_Float = 0
    }
    public init(status: SparseStatus_t, rowCount: Int32, columnCount: Int32, attributes: SparseAttributes_t, blockSize: UInt8, type: SparseFactorization_t, factorization: UnsafeMutableRawPointer?, workspaceSize_Float: Int, workspaceSize_Double: Int, factorSize_Float: Int, factorSize_Double: Int) { self.init(); self.status = status; self.rowCount = rowCount; self.columnCount = columnCount; self.attributes = attributes; self.blockSize = blockSize; self.type = type; self.factorization = factorization; self.workspaceSize_Float = workspaceSize_Float; self.workspaceSize_Double = workspaceSize_Double; self.factorSize_Float = factorSize_Float; self.factorSize_Double = factorSize_Double }
}

public struct SparseSymbolicFactorOptions {
    public var control: SparseControl_t
    public var free: (UnsafeMutableRawPointer?) -> Void
    public var ignoreRowsAndColumns: UnsafeMutablePointer<Int32>?
    public var malloc: (Int) -> UnsafeMutableRawPointer?
    public var order: UnsafeMutablePointer<Int32>?
    public var orderMethod: SparseOrder_t
    public var reportError: ((UnsafePointer<CChar>) -> Void)?
    public init() {
        self.control = SparseControl_t(rawValue: 0)
        self.free = { _ in }
        self.ignoreRowsAndColumns = nil
        self.malloc = { _ in nil }
        self.order = nil
        self.orderMethod = SparseOrder_t(rawValue: 0)
        self.reportError = nil
    }
}

public struct bnns_graph_argument_t {
    public var data_ptr_size: Int
    public init() {
        self.data_ptr_size = 0
    }
}

public struct bnns_graph_compile_options_t {
    public var data: UnsafeMutableRawPointer?
    public var size: Int
    public init() {
        self.data = nil
        self.size = 0
    }
    public init(data: UnsafeMutableRawPointer?, size: Int) { self.init(); self.data = data; self.size = size }
}

public struct bnns_graph_context_t {
    public var data: UnsafeMutableRawPointer?
    public var size: Int
    public init() {
        self.data = nil
        self.size = 0
    }
    public init(data: UnsafeMutableRawPointer?, size: Int) { self.init(); self.data = data; self.size = size }
}

public struct bnns_graph_shape_t {
    public var rank: Int
    public var shape: UnsafeMutablePointer<UInt64>?
    public init() {
        self.rank = 0
        self.shape = nil
    }
}

public struct bnns_graph_t {
    public var data: UnsafeMutableRawPointer?
    public var size: Int
    public init() {
        self.data = nil
        self.size = 0
    }
    public init(data: UnsafeMutableRawPointer?, size: Int) { self.init(); self.data = data; self.size = size }
}

public struct bnns_user_message_data_t {
    public var data: UnsafeMutableRawPointer?
    public var size: Int
    public init() {
        self.data = nil
        self.size = 0
    }
    public init(size: Int, data: UnsafeMutableRawPointer?) { self.init(); self.size = size; self.data = data }
}

public struct quadrature_integrate_function {
    public var fun: quadrature_function_array
    public var fun_arg: UnsafeMutableRawPointer!
    public init() {
        self.fun = { _, _, _, _ in }
        self.fun_arg = nil
    }
    public init(fun: quadrature_function_array, fun_arg: UnsafeMutableRawPointer!) { self.init(); self.fun_arg = fun_arg; _ = fun }
}

public struct quadrature_integrate_options {
    public var abs_tolerance: Double
    public var integrator: quadrature_integrator
    public var max_intervals: Int
    public var qag_points_per_interval: Int
    public var rel_tolerance: Double
    public init() {
        self.abs_tolerance = 0
        self.integrator = quadrature_integrator(rawValue: 0)
        self.max_intervals = 0
        self.qag_points_per_interval = 0
        self.rel_tolerance = 0
    }
    public init(integrator: quadrature_integrator, abs_tolerance: Double, rel_tolerance: Double, qag_points_per_interval: Int, max_intervals: Int) { self.init(); self.integrator = integrator; self.abs_tolerance = abs_tolerance; self.rel_tolerance = rel_tolerance; self.qag_points_per_interval = qag_points_per_interval; self.max_intervals = max_intervals }
}

public struct vDSP_int24 {
    public var bytes: (UInt8, UInt8, UInt8)
    public init() {
        self.bytes = (0, 0, 0)
    }
    public init(bytes: (UInt8, UInt8, UInt8)) { self.init(); self.bytes = bytes }
}

public struct vDSP_uint24 {
    public var bytes: (UInt8, UInt8, UInt8)
    public init() {
        self.bytes = (0, 0, 0)
    }
    public init(bytes: (UInt8, UInt8, UInt8)) { self.init(); self.bytes = bytes }
}

public final class vImageCVImageFormat: @unchecked Sendable {
    public init() {}
}
public final class vImageConstCVImageFormat: @unchecked Sendable {
    public init() {}
}
public final class vImageConverter: @unchecked Sendable {
    public init() {}
}

import Foundation

public var BLAS_THREADING_MAX_OPTIONS: BLAS_THREADING { BLAS_THREADING(rawValue: 2) }
public var BLAS_THREADING_MULTI_THREADED: BLAS_THREADING { BLAS_THREADING(rawValue: 0) }
public var BLAS_THREADING_SINGLE_THREADED: BLAS_THREADING { BLAS_THREADING(rawValue: 1) }
public var CblasNonUnit: CBLAS_DIAG { CBLAS_DIAG(rawValue: 131) }
public var CblasUnit: CBLAS_DIAG { CBLAS_DIAG(rawValue: 132) }
public var CblasColMajor: CBLAS_ORDER { CBLAS_ORDER(rawValue: 102) }
public var CblasRowMajor: CBLAS_ORDER { CBLAS_ORDER(rawValue: 101) }
public var CblasLeft: CBLAS_SIDE { CBLAS_SIDE(rawValue: 141) }
public var CblasRight: CBLAS_SIDE { CBLAS_SIDE(rawValue: 142) }
public var AtlasConj: CBLAS_TRANSPOSE { CBLAS_TRANSPOSE(rawValue: 114) }
public var CblasConjTrans: CBLAS_TRANSPOSE { CBLAS_TRANSPOSE(rawValue: 113) }
public var CblasNoTrans: CBLAS_TRANSPOSE { CBLAS_TRANSPOSE(rawValue: 111) }
public var CblasTrans: CBLAS_TRANSPOSE { CBLAS_TRANSPOSE(rawValue: 112) }
public var CblasLower: CBLAS_UPLO { CBLAS_UPLO(rawValue: 122) }
public var CblasUpper: CBLAS_UPLO { CBLAS_UPLO(rawValue: 121) }
public var BNNSActivationFunctionCELU: BNNSActivationFunction { BNNSActivationFunction(rawValue: 0) }
public var BNNSActivationFunctionClampedLeakyRectifiedLinear: BNNSActivationFunction { BNNSActivationFunction(rawValue: 1) }
public var BNNSActivationFunctionELU: BNNSActivationFunction { BNNSActivationFunction(rawValue: 2) }
public var BNNSActivationFunctionErf: BNNSActivationFunction { BNNSActivationFunction(rawValue: 3) }
public var BNNSActivationFunctionGELU: BNNSActivationFunction { BNNSActivationFunction(rawValue: 4) }
public var BNNSActivationFunctionGELUApproximation: BNNSActivationFunction { BNNSActivationFunction(rawValue: 5) }
public var BNNSActivationFunctionGELUApproximation2: BNNSActivationFunction { BNNSActivationFunction(rawValue: 6) }
public var BNNSActivationFunctionGELUApproximationSigmoid: BNNSActivationFunction { BNNSActivationFunction(rawValue: 7) }
public var BNNSActivationFunctionGumbel: BNNSActivationFunction { BNNSActivationFunction(rawValue: 8) }
public var BNNSActivationFunctionGumbelMax: BNNSActivationFunction { BNNSActivationFunction(rawValue: 9) }
public var BNNSActivationFunctionHardShrink: BNNSActivationFunction { BNNSActivationFunction(rawValue: 10) }
public var BNNSActivationFunctionHardSigmoid: BNNSActivationFunction { BNNSActivationFunction(rawValue: 11) }
public var BNNSActivationFunctionHardSwish: BNNSActivationFunction { BNNSActivationFunction(rawValue: 12) }
public var BNNSActivationFunctionLinearWithBias: BNNSActivationFunction { BNNSActivationFunction(rawValue: 13) }
public var BNNSActivationFunctionLogSigmoid: BNNSActivationFunction { BNNSActivationFunction(rawValue: 14) }
public var BNNSActivationFunctionLogSoftmax: BNNSActivationFunction { BNNSActivationFunction(rawValue: 15) }
public var BNNSActivationFunctionPReLUPerChannel: BNNSActivationFunction { BNNSActivationFunction(rawValue: 16) }
public var BNNSActivationFunctionReLU6: BNNSActivationFunction { BNNSActivationFunction(rawValue: 17) }
public var BNNSActivationFunctionSELU: BNNSActivationFunction { BNNSActivationFunction(rawValue: 18) }
public var BNNSActivationFunctionSiLU: BNNSActivationFunction { BNNSActivationFunction(rawValue: 19) }
public var BNNSActivationFunctionSoftShrink: BNNSActivationFunction { BNNSActivationFunction(rawValue: 20) }
public var BNNSActivationFunctionSoftplus: BNNSActivationFunction { BNNSActivationFunction(rawValue: 21) }
public var BNNSActivationFunctionSoftsign: BNNSActivationFunction { BNNSActivationFunction(rawValue: 22) }
public var BNNSActivationFunctionTanhShrink: BNNSActivationFunction { BNNSActivationFunction(rawValue: 23) }
public var BNNSActivationFunctionThreshold: BNNSActivationFunction { BNNSActivationFunction(rawValue: 24) }
public var BNNSArithmeticAbs: BNNSArithmeticFunction { BNNSArithmeticFunction(rawValue: 0) }
public var BNNSArithmeticAcos: BNNSArithmeticFunction { BNNSArithmeticFunction(rawValue: 1) }
public var BNNSArithmeticAcosh: BNNSArithmeticFunction { BNNSArithmeticFunction(rawValue: 2) }
public var BNNSArithmeticAdd: BNNSArithmeticFunction { BNNSArithmeticFunction(rawValue: 3) }
public var BNNSArithmeticAsin: BNNSArithmeticFunction { BNNSArithmeticFunction(rawValue: 4) }
public var BNNSArithmeticAsinh: BNNSArithmeticFunction { BNNSArithmeticFunction(rawValue: 5) }
public var BNNSArithmeticAtan: BNNSArithmeticFunction { BNNSArithmeticFunction(rawValue: 6) }
public var BNNSArithmeticAtanh: BNNSArithmeticFunction { BNNSArithmeticFunction(rawValue: 7) }
public var BNNSArithmeticCeil: BNNSArithmeticFunction { BNNSArithmeticFunction(rawValue: 8) }
public var BNNSArithmeticCos: BNNSArithmeticFunction { BNNSArithmeticFunction(rawValue: 9) }
public var BNNSArithmeticCosh: BNNSArithmeticFunction { BNNSArithmeticFunction(rawValue: 10) }
public var BNNSArithmeticDivide: BNNSArithmeticFunction { BNNSArithmeticFunction(rawValue: 11) }
public var BNNSArithmeticDivideNoNaN: BNNSArithmeticFunction { BNNSArithmeticFunction(rawValue: 12) }
public var BNNSArithmeticErf: BNNSArithmeticFunction { BNNSArithmeticFunction(rawValue: 13) }
public var BNNSArithmeticExp: BNNSArithmeticFunction { BNNSArithmeticFunction(rawValue: 14) }
public var BNNSArithmeticExp2: BNNSArithmeticFunction { BNNSArithmeticFunction(rawValue: 15) }
public var BNNSArithmeticFloor: BNNSArithmeticFunction { BNNSArithmeticFunction(rawValue: 16) }
public var BNNSArithmeticFloorDivide: BNNSArithmeticFunction { BNNSArithmeticFunction(rawValue: 17) }
public var BNNSArithmeticLog: BNNSArithmeticFunction { BNNSArithmeticFunction(rawValue: 18) }
public var BNNSArithmeticLog2: BNNSArithmeticFunction { BNNSArithmeticFunction(rawValue: 19) }
public var BNNSArithmeticMaximum: BNNSArithmeticFunction { BNNSArithmeticFunction(rawValue: 20) }
public var BNNSArithmeticMinimum: BNNSArithmeticFunction { BNNSArithmeticFunction(rawValue: 21) }
public var BNNSArithmeticMultiply: BNNSArithmeticFunction { BNNSArithmeticFunction(rawValue: 22) }
public var BNNSArithmeticMultiplyAdd: BNNSArithmeticFunction { BNNSArithmeticFunction(rawValue: 23) }
public var BNNSArithmeticMultiplyNoNaN: BNNSArithmeticFunction { BNNSArithmeticFunction(rawValue: 24) }
public var BNNSArithmeticNegate: BNNSArithmeticFunction { BNNSArithmeticFunction(rawValue: 25) }
public var BNNSArithmeticPow: BNNSArithmeticFunction { BNNSArithmeticFunction(rawValue: 26) }
public var BNNSArithmeticReciprocal: BNNSArithmeticFunction { BNNSArithmeticFunction(rawValue: 27) }
public var BNNSArithmeticReciprocalSquareRoot: BNNSArithmeticFunction { BNNSArithmeticFunction(rawValue: 28) }
public var BNNSArithmeticRound: BNNSArithmeticFunction { BNNSArithmeticFunction(rawValue: 29) }
public var BNNSArithmeticSelect: BNNSArithmeticFunction { BNNSArithmeticFunction(rawValue: 30) }
public var BNNSArithmeticSign: BNNSArithmeticFunction { BNNSArithmeticFunction(rawValue: 31) }
public var BNNSArithmeticSin: BNNSArithmeticFunction { BNNSArithmeticFunction(rawValue: 32) }
public var BNNSArithmeticSinh: BNNSArithmeticFunction { BNNSArithmeticFunction(rawValue: 33) }
public var BNNSArithmeticSquare: BNNSArithmeticFunction { BNNSArithmeticFunction(rawValue: 34) }
public var BNNSArithmeticSquareRoot: BNNSArithmeticFunction { BNNSArithmeticFunction(rawValue: 35) }
public var BNNSArithmeticSubtract: BNNSArithmeticFunction { BNNSArithmeticFunction(rawValue: 36) }
public var BNNSArithmeticTan: BNNSArithmeticFunction { BNNSArithmeticFunction(rawValue: 37) }
public var BNNSArithmeticTanh: BNNSArithmeticFunction { BNNSArithmeticFunction(rawValue: 38) }
public var BNNSArithmeticTruncDivide: BNNSArithmeticFunction { BNNSArithmeticFunction(rawValue: 39) }
public var BNNSArithmeticTruncRemainder: BNNSArithmeticFunction { BNNSArithmeticFunction(rawValue: 40) }
public var BNNSCenterSizeHeightFirst: BNNSBoxCoordinateMode { BNNSBoxCoordinateMode(rawValue: 0) }
public var BNNSCenterSizeWidthFirst: BNNSBoxCoordinateMode { BNNSBoxCoordinateMode(rawValue: 1) }
public var BNNSCornersHeightFirst: BNNSBoxCoordinateMode { BNNSBoxCoordinateMode(rawValue: 2) }
public var BNNSCornersWidthFirst: BNNSBoxCoordinateMode { BNNSBoxCoordinateMode(rawValue: 3) }
public var BNNSDataLayout1DFirstMajor: BNNSDataLayout { BNNSDataLayout(rawValue: 0) }
public var BNNSDataLayout1DLastMajor: BNNSDataLayout { BNNSDataLayout(rawValue: 1) }
public var BNNSDataLayout2DFirstMajor: BNNSDataLayout { BNNSDataLayout(rawValue: 2) }
public var BNNSDataLayout2DLastMajor: BNNSDataLayout { BNNSDataLayout(rawValue: 3) }
public var BNNSDataLayout3DFirstMajor: BNNSDataLayout { BNNSDataLayout(rawValue: 4) }
public var BNNSDataLayout3DLastMajor: BNNSDataLayout { BNNSDataLayout(rawValue: 5) }
public var BNNSDataLayout4DFirstMajor: BNNSDataLayout { BNNSDataLayout(rawValue: 6) }
public var BNNSDataLayout4DLastMajor: BNNSDataLayout { BNNSDataLayout(rawValue: 7) }
public var BNNSDataLayout5DFirstMajor: BNNSDataLayout { BNNSDataLayout(rawValue: 8) }
public var BNNSDataLayout5DLastMajor: BNNSDataLayout { BNNSDataLayout(rawValue: 9) }
public var BNNSDataLayout6DFirstMajor: BNNSDataLayout { BNNSDataLayout(rawValue: 10) }
public var BNNSDataLayout6DLastMajor: BNNSDataLayout { BNNSDataLayout(rawValue: 11) }
public var BNNSDataLayout7DFirstMajor: BNNSDataLayout { BNNSDataLayout(rawValue: 12) }
public var BNNSDataLayout7DLastMajor: BNNSDataLayout { BNNSDataLayout(rawValue: 13) }
public var BNNSDataLayout8DFirstMajor: BNNSDataLayout { BNNSDataLayout(rawValue: 14) }
public var BNNSDataLayout8DLastMajor: BNNSDataLayout { BNNSDataLayout(rawValue: 15) }
public var BNNSDataLayoutColumnMajorMatrix: BNNSDataLayout { BNNSDataLayout(rawValue: 16) }
public var BNNSDataLayoutConvolutionWeightsIOHrWr: BNNSDataLayout { BNNSDataLayout(rawValue: 17) }
public var BNNSDataLayoutConvolutionWeightsOIHW: BNNSDataLayout { BNNSDataLayout(rawValue: 18) }
public var BNNSDataLayoutConvolutionWeightsOIHW_Pack32: BNNSDataLayout { BNNSDataLayout(rawValue: 19) }
public var BNNSDataLayoutConvolutionWeightsOIHrWr: BNNSDataLayout { BNNSDataLayout(rawValue: 20) }
public var BNNSDataLayoutFullyConnectedSparse: BNNSDataLayout { BNNSDataLayout(rawValue: 21) }
public var BNNSDataLayoutImageCHW: BNNSDataLayout { BNNSDataLayout(rawValue: 22) }
public var BNNSDataLayoutMHA_DHK: BNNSDataLayout { BNNSDataLayout(rawValue: 23) }
public var BNNSDataLayoutNSE: BNNSDataLayout { BNNSDataLayout(rawValue: 24) }
public var BNNSDataLayoutRowMajorMatrix: BNNSDataLayout { BNNSDataLayout(rawValue: 25) }
public var BNNSDataLayoutSNE: BNNSDataLayout { BNNSDataLayout(rawValue: 26) }
public var BNNSDataLayoutVector: BNNSDataLayout { BNNSDataLayout(rawValue: 27) }
public var BNNSDataTypeBFloat16: BNNSDataType { BNNSDataType(rawValue: 0) }
public var BNNSDataTypeBoolean: BNNSDataType { BNNSDataType(rawValue: 1) }
public var BNNSDataTypeIndexed1: BNNSDataType { BNNSDataType(rawValue: 2) }
public var BNNSDataTypeIndexed2: BNNSDataType { BNNSDataType(rawValue: 3) }
public var BNNSDataTypeIndexed4: BNNSDataType { BNNSDataType(rawValue: 4) }
public var BNNSDataTypeInt1: BNNSDataType { BNNSDataType(rawValue: 5) }
public var BNNSDataTypeInt2: BNNSDataType { BNNSDataType(rawValue: 6) }
public var BNNSDataTypeInt4: BNNSDataType { BNNSDataType(rawValue: 7) }
public var BNNSDataTypeInt64: BNNSDataType { BNNSDataType(rawValue: 8) }
public var BNNSDataTypeMiscellaneousBit: BNNSDataType { BNNSDataType(rawValue: 9) }
public var BNNSDataTypeUInt1: BNNSDataType { BNNSDataType(rawValue: 10) }
public var BNNSDataTypeUInt2: BNNSDataType { BNNSDataType(rawValue: 11) }
public var BNNSDataTypeUInt3: BNNSDataType { BNNSDataType(rawValue: 12) }
public var BNNSDataTypeUInt4: BNNSDataType { BNNSDataType(rawValue: 13) }
public var BNNSDataTypeUInt6: BNNSDataType { BNNSDataType(rawValue: 14) }
public var BNNSDataTypeUInt64: BNNSDataType { BNNSDataType(rawValue: 15) }
public var BNNSConstant: BNNSDescriptorType { BNNSDescriptorType(rawValue: 0) }
public var BNNSParameter: BNNSDescriptorType { BNNSDescriptorType(rawValue: 1) }
public var BNNSSample: BNNSDescriptorType { BNNSDescriptorType(rawValue: 2) }
public var BNNSEmbeddingFlagScaleGradientByFrequency: BNNSEmbeddingFlags { BNNSEmbeddingFlags(rawValue: 0) }
public var BNNSArithmetic: BNNSFilterType { BNNSFilterType(rawValue: 0) }
public var BNNSBatchNorm: BNNSFilterType { BNNSFilterType(rawValue: 1) }
public var BNNSConvolution: BNNSFilterType { BNNSFilterType(rawValue: 2) }
public var BNNSFullyConnected: BNNSFilterType { BNNSFilterType(rawValue: 3) }
public var BNNSGroupNorm: BNNSFilterType { BNNSFilterType(rawValue: 4) }
public var BNNSInstanceNorm: BNNSFilterType { BNNSFilterType(rawValue: 5) }
public var BNNSLayerNorm: BNNSFilterType { BNNSFilterType(rawValue: 6) }
public var BNNSQuantization: BNNSFilterType { BNNSFilterType(rawValue: 7) }
public var BNNSTransposedConvolution: BNNSFilterType { BNNSFilterType(rawValue: 8) }
public var BNNSGraphArgumentIntentIn: BNNSGraphArgumentIntent { BNNSGraphArgumentIntent(rawValue: 0) }
public var BNNSGraphArgumentIntentInOut: BNNSGraphArgumentIntent { BNNSGraphArgumentIntent(rawValue: 1) }
public var BNNSGraphArgumentIntentOut: BNNSGraphArgumentIntent { BNNSGraphArgumentIntent(rawValue: 2) }
public var BNNSGraphArgumentTypePointer: BNNSGraphArgumentType { BNNSGraphArgumentType(rawValue: 0) }
public var BNNSGraphArgumentTypeTensor: BNNSGraphArgumentType { BNNSGraphArgumentType(rawValue: 1) }
public var BNNSGraphMessageLevelError: BNNSGraphMessageLevel { BNNSGraphMessageLevel(rawValue: 0) }
public var BNNSGraphMessageLevelInfo: BNNSGraphMessageLevel { BNNSGraphMessageLevel(rawValue: 1) }
public var BNNSGraphMessageLevelUnsupported: BNNSGraphMessageLevel { BNNSGraphMessageLevel(rawValue: 2) }
public var BNNSGraphMessageLevelWarning: BNNSGraphMessageLevel { BNNSGraphMessageLevel(rawValue: 3) }
public var BNNSGraphOptimizationPreferenceIRSize: BNNSGraphOptimizationPreference { BNNSGraphOptimizationPreference(rawValue: 0) }
public var BNNSGraphOptimizationPreferencePerformance: BNNSGraphOptimizationPreference { BNNSGraphOptimizationPreference(rawValue: 1) }
public var BNNSInterpolationMethodLinear: BNNSInterpolationMethod { BNNSInterpolationMethod(rawValue: 0) }
public var BNNSInterpolationMethodNearest: BNNSInterpolationMethod { BNNSInterpolationMethod(rawValue: 1) }
public var BNNSLayerFlagsLSTMBidirectional: BNNSLayerFlags { BNNSLayerFlags(rawValue: 0) }
public var BNNSLayerFlagsLSTMDefaultActivations: BNNSLayerFlags { BNNSLayerFlags(rawValue: 1) }
public var BNNSLinearSamplingAlignCorners: BNNSLinearSamplingMode { BNNSLinearSamplingMode(rawValue: 0) }
public var BNNSLinearSamplingDefault: BNNSLinearSamplingMode { BNNSLinearSamplingMode(rawValue: 1) }
public var BNNSLinearSamplingOffsetCorners: BNNSLinearSamplingMode { BNNSLinearSamplingMode(rawValue: 2) }
public var BNNSLinearSamplingStrictAlignCorners: BNNSLinearSamplingMode { BNNSLinearSamplingMode(rawValue: 3) }
public var BNNSLinearSamplingUnalignCorners: BNNSLinearSamplingMode { BNNSLinearSamplingMode(rawValue: 4) }
public var BNNSLossFunctionCategoricalCrossEntropy: BNNSLossFunction { BNNSLossFunction(rawValue: 0) }
public var BNNSLossFunctionCosineDistance: BNNSLossFunction { BNNSLossFunction(rawValue: 1) }
public var BNNSLossFunctionHinge: BNNSLossFunction { BNNSLossFunction(rawValue: 2) }
public var BNNSLossFunctionHuber: BNNSLossFunction { BNNSLossFunction(rawValue: 3) }
public var BNNSLossFunctionLog: BNNSLossFunction { BNNSLossFunction(rawValue: 4) }
public var BNNSLossFunctionMeanAbsoluteError: BNNSLossFunction { BNNSLossFunction(rawValue: 5) }
public var BNNSLossFunctionMeanSquareError: BNNSLossFunction { BNNSLossFunction(rawValue: 6) }
public var BNNSLossFunctionSigmoidCrossEntropy: BNNSLossFunction { BNNSLossFunction(rawValue: 7) }
public var BNNSLossFunctionSoftmaxCrossEntropy: BNNSLossFunction { BNNSLossFunction(rawValue: 8) }
public var BNNSLossFunctionYolo: BNNSLossFunction { BNNSLossFunction(rawValue: 9) }
public var BNNSLossReductionMean: BNNSLossReductionFunction { BNNSLossReductionFunction(rawValue: 0) }
public var BNNSLossReductionNonZeroWeightMean: BNNSLossReductionFunction { BNNSLossReductionFunction(rawValue: 1) }
public var BNNSLossReductionNone: BNNSLossReductionFunction { BNNSLossReductionFunction(rawValue: 2) }
public var BNNSLossReductionSum: BNNSLossReductionFunction { BNNSLossReductionFunction(rawValue: 3) }
public var BNNSLossReductionWeightedMean: BNNSLossReductionFunction { BNNSLossReductionFunction(rawValue: 4) }
public var BNNSNDArrayFlagBackpropAccumulate: BNNSNDArrayFlags { BNNSNDArrayFlags(rawValue: 0) }
public var BNNSNDArrayFlagBackpropSet: BNNSNDArrayFlags { BNNSNDArrayFlags(rawValue: 1) }
public var BNNSL2Norm: BNNSNormType { BNNSNormType(rawValue: 0) }
public var BNNSOptimizerClippingByGlobalNorm: BNNSOptimizerClippingFunction { BNNSOptimizerClippingFunction(rawValue: 0) }
public var BNNSOptimizerClippingByNorm: BNNSOptimizerClippingFunction { BNNSOptimizerClippingFunction(rawValue: 1) }
public var BNNSOptimizerClippingByValue: BNNSOptimizerClippingFunction { BNNSOptimizerClippingFunction(rawValue: 2) }
public var BNNSOptimizerClippingNone: BNNSOptimizerClippingFunction { BNNSOptimizerClippingFunction(rawValue: 3) }
public var BNNSOptimizerFunctionAdam: BNNSOptimizerFunction { BNNSOptimizerFunction(rawValue: 0) }
public var BNNSOptimizerFunctionAdamAMSGrad: BNNSOptimizerFunction { BNNSOptimizerFunction(rawValue: 1) }
public var BNNSOptimizerFunctionAdamAMSGradWithClipping: BNNSOptimizerFunction { BNNSOptimizerFunction(rawValue: 2) }
public var BNNSOptimizerFunctionAdamW: BNNSOptimizerFunction { BNNSOptimizerFunction(rawValue: 3) }
public var BNNSOptimizerFunctionAdamWAMSGrad: BNNSOptimizerFunction { BNNSOptimizerFunction(rawValue: 4) }
public var BNNSOptimizerFunctionAdamWAMSGradWithClipping: BNNSOptimizerFunction { BNNSOptimizerFunction(rawValue: 5) }
public var BNNSOptimizerFunctionAdamWWithClipping: BNNSOptimizerFunction { BNNSOptimizerFunction(rawValue: 6) }
public var BNNSOptimizerFunctionAdamWithClipping: BNNSOptimizerFunction { BNNSOptimizerFunction(rawValue: 7) }
public var BNNSOptimizerFunctionRMSProp: BNNSOptimizerFunction { BNNSOptimizerFunction(rawValue: 8) }
public var BNNSOptimizerFunctionRMSPropWithClipping: BNNSOptimizerFunction { BNNSOptimizerFunction(rawValue: 9) }
public var BNNSOptimizerFunctionSGDMomentum: BNNSOptimizerFunction { BNNSOptimizerFunction(rawValue: 10) }
public var BNNSOptimizerFunctionSGDMomentumWithClipping: BNNSOptimizerFunction { BNNSOptimizerFunction(rawValue: 11) }
public var BNNSOptimizerRegularizationL1: BNNSOptimizerRegularizationFunction { BNNSOptimizerRegularizationFunction(rawValue: 0) }
public var BNNSOptimizerRegularizationL2: BNNSOptimizerRegularizationFunction { BNNSOptimizerRegularizationFunction(rawValue: 1) }
public var BNNSOptimizerRegularizationNone: BNNSOptimizerRegularizationFunction { BNNSOptimizerRegularizationFunction(rawValue: 2) }
public var BNNSSGDMomentumVariant0: BNNSOptimizerSGDMomentumVariant { BNNSOptimizerSGDMomentumVariant(rawValue: 0) }
public var BNNSSGDMomentumVariant1: BNNSOptimizerSGDMomentumVariant { BNNSOptimizerSGDMomentumVariant(rawValue: 1) }
public var BNNSSGDMomentumVariant2: BNNSOptimizerSGDMomentumVariant { BNNSOptimizerSGDMomentumVariant(rawValue: 2) }
public var BNNSPaddingModeConstant: BNNSPaddingMode { BNNSPaddingMode(rawValue: 0) }
public var BNNSPaddingModeReflect: BNNSPaddingMode { BNNSPaddingMode(rawValue: 1) }
public var BNNSPaddingModeSymmetric: BNNSPaddingMode { BNNSPaddingMode(rawValue: 2) }
public var BNNSPointerSpecifierAlpha: BNNSPointerSpecifier { BNNSPointerSpecifier(rawValue: 0) }
public var BNNSPointerSpecifierBeta: BNNSPointerSpecifier { BNNSPointerSpecifier(rawValue: 1) }
public var BNNSPoolingFunctionAverageCountExcludePadding: BNNSPoolingFunction { BNNSPoolingFunction(rawValue: 0) }
public var BNNSPoolingFunctionAverageCountIncludePadding: BNNSPoolingFunction { BNNSPoolingFunction(rawValue: 1) }
public var BNNSPoolingFunctionL2Norm: BNNSPoolingFunction { BNNSPoolingFunction(rawValue: 2) }
public var BNNSPoolingFunctionUnMax: BNNSPoolingFunction { BNNSPoolingFunction(rawValue: 3) }
public var BNNSQuantizerFunctionDequantize: BNNSQuantizerFunction { BNNSQuantizerFunction(rawValue: 0) }
public var BNNSQuantizerFunctionQuantize: BNNSQuantizerFunction { BNNSQuantizerFunction(rawValue: 1) }
public var BNNSRandomGeneratorMethodAES_CTR: BNNSRandomGeneratorMethod { BNNSRandomGeneratorMethod(rawValue: 0) }
public var BNNSReduceFunctionAll: BNNSReduceFunction { BNNSReduceFunction(rawValue: 0) }
public var BNNSReduceFunctionAny: BNNSReduceFunction { BNNSReduceFunction(rawValue: 1) }
public var BNNSReduceFunctionArgMax: BNNSReduceFunction { BNNSReduceFunction(rawValue: 2) }
public var BNNSReduceFunctionArgMin: BNNSReduceFunction { BNNSReduceFunction(rawValue: 3) }
public var BNNSReduceFunctionL1Norm: BNNSReduceFunction { BNNSReduceFunction(rawValue: 4) }
public var BNNSReduceFunctionL2Norm: BNNSReduceFunction { BNNSReduceFunction(rawValue: 5) }
public var BNNSReduceFunctionLogSum: BNNSReduceFunction { BNNSReduceFunction(rawValue: 6) }
public var BNNSReduceFunctionLogSumExp: BNNSReduceFunction { BNNSReduceFunction(rawValue: 7) }
public var BNNSReduceFunctionLogicalAnd: BNNSReduceFunction { BNNSReduceFunction(rawValue: 8) }
public var BNNSReduceFunctionLogicalOr: BNNSReduceFunction { BNNSReduceFunction(rawValue: 9) }
public var BNNSReduceFunctionMax: BNNSReduceFunction { BNNSReduceFunction(rawValue: 10) }
public var BNNSReduceFunctionMean: BNNSReduceFunction { BNNSReduceFunction(rawValue: 11) }
public var BNNSReduceFunctionMeanNonZero: BNNSReduceFunction { BNNSReduceFunction(rawValue: 12) }
public var BNNSReduceFunctionMin: BNNSReduceFunction { BNNSReduceFunction(rawValue: 13) }
public var BNNSReduceFunctionNone: BNNSReduceFunction { BNNSReduceFunction(rawValue: 14) }
public var BNNSReduceFunctionProduct: BNNSReduceFunction { BNNSReduceFunction(rawValue: 15) }
public var BNNSReduceFunctionSum: BNNSReduceFunction { BNNSReduceFunction(rawValue: 16) }
public var BNNSReduceFunctionSumLog: BNNSReduceFunction { BNNSReduceFunction(rawValue: 17) }
public var BNNSReduceFunctionSumSquare: BNNSReduceFunction { BNNSReduceFunction(rawValue: 18) }
public var BNNSRelationalOperatorEqual: BNNSRelationalOperator { BNNSRelationalOperator(rawValue: 0) }
public var BNNSRelationalOperatorGreater: BNNSRelationalOperator { BNNSRelationalOperator(rawValue: 1) }
public var BNNSRelationalOperatorGreaterEqual: BNNSRelationalOperator { BNNSRelationalOperator(rawValue: 2) }
public var BNNSRelationalOperatorLess: BNNSRelationalOperator { BNNSRelationalOperator(rawValue: 3) }
public var BNNSRelationalOperatorLessEqual: BNNSRelationalOperator { BNNSRelationalOperator(rawValue: 4) }
public var BNNSRelationalOperatorLogicalAND: BNNSRelationalOperator { BNNSRelationalOperator(rawValue: 5) }
public var BNNSRelationalOperatorLogicalNAND: BNNSRelationalOperator { BNNSRelationalOperator(rawValue: 6) }
public var BNNSRelationalOperatorLogicalNOR: BNNSRelationalOperator { BNNSRelationalOperator(rawValue: 7) }
public var BNNSRelationalOperatorLogicalNOT: BNNSRelationalOperator { BNNSRelationalOperator(rawValue: 8) }
public var BNNSRelationalOperatorLogicalOR: BNNSRelationalOperator { BNNSRelationalOperator(rawValue: 9) }
public var BNNSRelationalOperatorLogicalXOR: BNNSRelationalOperator { BNNSRelationalOperator(rawValue: 10) }
public var BNNSRelationalOperatorNotEqual: BNNSRelationalOperator { BNNSRelationalOperator(rawValue: 11) }
public var BNNSShuffleTypeDepthToSpaceNCHW: BNNSShuffleType { BNNSShuffleType(rawValue: 0) }
public var BNNSShuffleTypePixelShuffleNCHW: BNNSShuffleType { BNNSShuffleType(rawValue: 1) }
public var BNNSShuffleTypePixelUnshuffleNCHW: BNNSShuffleType { BNNSShuffleType(rawValue: 2) }
public var BNNSShuffleTypeSpaceToDepthNCHW: BNNSShuffleType { BNNSShuffleType(rawValue: 3) }
public var BNNSSparsityTypeUnstructured: BNNSSparsityType { BNNSSparsityType(rawValue: 0) }
public var BNNSTargetSystemGeneric: BNNSTargetSystem { BNNSTargetSystem(rawValue: 0) }
public var SparseDefaultControl: SparseControl_t { SparseControl_t(rawValue: 0) }
public var SparseFactorizationCholesky: SparseFactorization_t { SparseFactorization_t(rawValue: 0) }
public var SparseFactorizationCholeskyAtA: SparseFactorization_t { SparseFactorization_t(rawValue: 1) }
public var SparseFactorizationLDLT: SparseFactorization_t { SparseFactorization_t(rawValue: 2) }
public var SparseFactorizationLDLTSBK: SparseFactorization_t { SparseFactorization_t(rawValue: 3) }
public var SparseFactorizationLDLTTPP: SparseFactorization_t { SparseFactorization_t(rawValue: 4) }
public var SparseFactorizationLDLTUnpivoted: SparseFactorization_t { SparseFactorization_t(rawValue: 5) }
public var SparseFactorizationLU: SparseFactorization_t { SparseFactorization_t(rawValue: 6) }
public var SparseFactorizationLUSPP: SparseFactorization_t { SparseFactorization_t(rawValue: 7) }
public var SparseFactorizationLUTPP: SparseFactorization_t { SparseFactorization_t(rawValue: 8) }
public var SparseFactorizationLUUnpivoted: SparseFactorization_t { SparseFactorization_t(rawValue: 9) }
public var SparseFactorizationQR: SparseFactorization_t { SparseFactorization_t(rawValue: 10) }
public var SparseVariantDQGMRES: SparseGMRESVariant_t { SparseGMRESVariant_t(rawValue: 0) }
public var SparseVariantFGMRES: SparseGMRESVariant_t { SparseGMRESVariant_t(rawValue: 1) }
public var SparseVariantGMRES: SparseGMRESVariant_t { SparseGMRESVariant_t(rawValue: 2) }
public var SparseIterativeConverged: SparseIterativeStatus_t { SparseIterativeStatus_t(rawValue: 0) }
public var SparseIterativeIllConditioned: SparseIterativeStatus_t { SparseIterativeStatus_t(rawValue: 1) }
public var SparseIterativeInternalError: SparseIterativeStatus_t { SparseIterativeStatus_t(rawValue: 2) }
public var SparseIterativeMaxIterations: SparseIterativeStatus_t { SparseIterativeStatus_t(rawValue: 3) }
public var SparseIterativeParameterError: SparseIterativeStatus_t { SparseIterativeStatus_t(rawValue: 4) }
public var SparseHermitian: SparseKind_t { SparseKind_t(rawValue: 0) }
public var SparseOrdinary: SparseKind_t { SparseKind_t(rawValue: 1) }
public var SparseSymmetric: SparseKind_t { SparseKind_t(rawValue: 2) }
public var SparseTriangular: SparseKind_t { SparseKind_t(rawValue: 3) }
public var SparseUnitTriangular: SparseKind_t { SparseKind_t(rawValue: 4) }
public var SparseLSMRCTDefault: SparseLSMRConvergenceTest_t { SparseLSMRConvergenceTest_t(rawValue: 0) }
public var SparseLSMRCTFongSaunders: SparseLSMRConvergenceTest_t { SparseLSMRConvergenceTest_t(rawValue: 1) }
public var SparseOrderAMD: SparseOrder_t { SparseOrder_t(rawValue: 0) }
public var SparseOrderCOLAMD: SparseOrder_t { SparseOrder_t(rawValue: 1) }
public var SparseOrderDefault: SparseOrder_t { SparseOrder_t(rawValue: 2) }
public var SparseOrderMTMetis: SparseOrder_t { SparseOrder_t(rawValue: 3) }
public var SparseOrderMetis: SparseOrder_t { SparseOrder_t(rawValue: 4) }
public var SparseOrderUser: SparseOrder_t { SparseOrder_t(rawValue: 5) }
public var SparsePreconditionerDiagScaling: SparsePreconditioner_t { SparsePreconditioner_t(rawValue: 0) }
public var SparsePreconditionerDiagonal: SparsePreconditioner_t { SparsePreconditioner_t(rawValue: 1) }
public var SparsePreconditionerNone: SparsePreconditioner_t { SparsePreconditioner_t(rawValue: 2) }
public var SparsePreconditionerUser: SparsePreconditioner_t { SparsePreconditioner_t(rawValue: 3) }
public var SparseScalingDefault: SparseScaling_t { SparseScaling_t(rawValue: 0) }
public var SparseScalingEquilibriationInf: SparseScaling_t { SparseScaling_t(rawValue: 1) }
public var SparseScalingHungarianScalingAndOrdering: SparseScaling_t { SparseScaling_t(rawValue: 2) }
public var SparseScalingHungarianScalingOnly: SparseScaling_t { SparseScaling_t(rawValue: 3) }
public var SparseScalingUser: SparseScaling_t { SparseScaling_t(rawValue: 4) }
public var SparseFactorizationFailed: SparseStatus_t { SparseStatus_t(rawValue: 0) }
public var SparseInternalError: SparseStatus_t { SparseStatus_t(rawValue: 1) }
public var SparseMatrixIsSingular: SparseStatus_t { SparseStatus_t(rawValue: 2) }
public var SparseParameterError: SparseStatus_t { SparseStatus_t(rawValue: 3) }
public var SparseStatusOK: SparseStatus_t { SparseStatus_t(rawValue: 4) }
public var SparseStatusReleased: SparseStatus_t { SparseStatus_t(rawValue: 5) }
public var SparseSubfactorD: SparseSubfactor_t { SparseSubfactor_t(rawValue: 0) }
public var SparseSubfactorInvalid: SparseSubfactor_t { SparseSubfactor_t(rawValue: 1) }
public var SparseSubfactorL: SparseSubfactor_t { SparseSubfactor_t(rawValue: 2) }
public var SparseSubfactorP: SparseSubfactor_t { SparseSubfactor_t(rawValue: 3) }
public var SparseSubfactorPLPS: SparseSubfactor_t { SparseSubfactor_t(rawValue: 4) }
public var SparseSubfactorQ: SparseSubfactor_t { SparseSubfactor_t(rawValue: 5) }
public var SparseSubfactorR: SparseSubfactor_t { SparseSubfactor_t(rawValue: 6) }
public var SparseSubfactorRP: SparseSubfactor_t { SparseSubfactor_t(rawValue: 7) }
public var SparseSubfactorS: SparseSubfactor_t { SparseSubfactor_t(rawValue: 8) }
public var SparseSubfactorSc: SparseSubfactor_t { SparseSubfactor_t(rawValue: 9) }
public var SparseSubfactorSr: SparseSubfactor_t { SparseSubfactor_t(rawValue: 10) }
public var SparseLowerTriangle: SparseTriangle_t { SparseTriangle_t(rawValue: 0) }
public var SparseUpperTriangle: SparseTriangle_t { SparseTriangle_t(rawValue: 1) }
public var SparseUpdatePartialRefactor: SparseUpdate_t { SparseUpdate_t(rawValue: 0) }
public var QUADRATURE_INTEGRATE_QAG: quadrature_integrator { quadrature_integrator(rawValue: 0) }
public var QUADRATURE_INTEGRATE_QAGS: quadrature_integrator { quadrature_integrator(rawValue: 1) }
public var QUADRATURE_INTEGRATE_QNG: quadrature_integrator { quadrature_integrator(rawValue: 2) }
public var QUADRATURE_ALLOC_ERROR: quadrature_status { quadrature_status(rawValue: 0) }
public var QUADRATURE_ERROR: quadrature_status { quadrature_status(rawValue: 1) }
public var QUADRATURE_INTEGRATE_BAD_BEHAVIOUR_ERROR: quadrature_status { quadrature_status(rawValue: 2) }
public var QUADRATURE_INTEGRATE_MAX_EVAL_ERROR: quadrature_status { quadrature_status(rawValue: 3) }
public var QUADRATURE_INTERNAL_ERROR: quadrature_status { quadrature_status(rawValue: 4) }
public var QUADRATURE_INVALID_ARG_ERROR: quadrature_status { quadrature_status(rawValue: 5) }
public var QUADRATURE_SUCCESS: quadrature_status { quadrature_status(rawValue: 6) }
public var SPARSE_LOWER_SYMMETRIC: sparse_matrix_property { sparse_matrix_property(rawValue: 0) }
public var SPARSE_LOWER_TRIANGULAR: sparse_matrix_property { sparse_matrix_property(rawValue: 1) }
public var SPARSE_UPPER_SYMMETRIC: sparse_matrix_property { sparse_matrix_property(rawValue: 2) }
public var SPARSE_UPPER_TRIANGULAR: sparse_matrix_property { sparse_matrix_property(rawValue: 3) }
public var SPARSE_NORM_INF: sparse_norm { sparse_norm(rawValue: 0) }
public var SPARSE_NORM_ONE: sparse_norm { sparse_norm(rawValue: 1) }
public var SPARSE_NORM_R1: sparse_norm { sparse_norm(rawValue: 2) }
public var SPARSE_NORM_TWO: sparse_norm { sparse_norm(rawValue: 3) }
public var SPARSE_CANNOT_SET_PROPERTY: sparse_status { sparse_status(rawValue: 0) }
public var SPARSE_ILLEGAL_PARAMETER: sparse_status { sparse_status(rawValue: 1) }
public var SPARSE_SUCCESS: sparse_status { sparse_status(rawValue: 2) }
public var SPARSE_SYSTEM_ERROR: sparse_status { sparse_status(rawValue: 3) }
public var kvImageARGB16Q12: vImageARGBType { vImageARGBType(rawValue: 0) }
public var kvImageARGB16U: vImageARGBType { vImageARGBType(rawValue: 1) }
public var kvImageARGB8888: vImageARGBType { vImageARGBType(rawValue: 2) }
public var kvImageMDTableHint_16Q12: vImageMDTableUsageHint { vImageMDTableUsageHint(rawValue: 0) }
public var kvImageMDTableHint_Float: vImageMDTableUsageHint { vImageMDTableUsageHint(rawValue: 1) }
public var kvImage420Yp8_Cb8_Cr8: vImageYpCbCrType { vImageYpCbCrType(rawValue: 0) }
public var kvImage420Yp8_CbCr8: vImageYpCbCrType { vImageYpCbCrType(rawValue: 1) }
public var kvImage422CbYpCrYp16: vImageYpCbCrType { vImageYpCbCrType(rawValue: 2) }
public var kvImage422CbYpCrYp8: vImageYpCbCrType { vImageYpCbCrType(rawValue: 3) }
public var kvImage422CbYpCrYp8_AA8: vImageYpCbCrType { vImageYpCbCrType(rawValue: 4) }
public var kvImage422CrYpCbYpCbYpCbYpCrYpCrYp10: vImageYpCbCrType { vImageYpCbCrType(rawValue: 5) }
public var kvImage422YpCbYpCr8: vImageYpCbCrType { vImageYpCbCrType(rawValue: 6) }
public var kvImage444AYpCbCr16: vImageYpCbCrType { vImageYpCbCrType(rawValue: 7) }
public var kvImage444AYpCbCr8: vImageYpCbCrType { vImageYpCbCrType(rawValue: 8) }
public var kvImage444CbYpCrA8: vImageYpCbCrType { vImageYpCbCrType(rawValue: 9) }
public var kvImage444CrYpCb10: vImageYpCbCrType { vImageYpCbCrType(rawValue: 10) }
public var kvImage444CrYpCb8: vImageYpCbCrType { vImageYpCbCrType(rawValue: 11) }
public var kvImageFullInterpolation: vImage_InterpolationMethod { vImage_InterpolationMethod(rawValue: 1) }
public var kvImageHalfInterpolation: vImage_InterpolationMethod { vImage_InterpolationMethod(rawValue: 2) }
public var kvImageNoInterpolation: vImage_InterpolationMethod { vImage_InterpolationMethod(rawValue: 0) }
public var FFT_FORWARD: Int { 1 }
public var FFT_INVERSE: Int { -1 }
public var FFT_RADIX2: Int { 0 }
public var FFT_RADIX3: Int { 1 }
public var FFT_RADIX5: Int { 2 }
public var kFFTDirection_Forward: Int { 1 }
public var kFFTDirection_Inverse: Int { -1 }
public var kFFTRadix2: Int { 0 }
public var kFFTRadix3: Int { 1 }
public var kFFTRadix5: Int { 2 }
public var kRotate0DegreesClockwise: Int { 10 }
public var kRotate0DegreesCounterClockwise: Int { 11 }
public var kRotate180DegreesClockwise: Int { 12 }
public var kRotate180DegreesCounterClockwise: Int { 13 }
public var kRotate270DegreesClockwise: Int { 14 }
public var kRotate270DegreesCounterClockwise: Int { 15 }
public var kRotate90DegreesClockwise: Int { 16 }
public var kRotate90DegreesCounterClockwise: Int { 17 }
public var kvImageBufferTypeCode_Alpha: Int { 18 }
public var kvImageBufferTypeCode_CGFormat: Int { 19 }
public var kvImageBufferTypeCode_CMYK_Black: Int { 20 }
public var kvImageBufferTypeCode_CMYK_Cyan: Int { 21 }
public var kvImageBufferTypeCode_CMYK_Magenta: Int { 22 }
public var kvImageBufferTypeCode_CMYK_Yellow: Int { 23 }
public var kvImageBufferTypeCode_Cb: Int { 24 }
public var kvImageBufferTypeCode_Chroma: Int { 25 }
public var kvImageBufferTypeCode_Chunky: Int { 26 }
public var kvImageBufferTypeCode_ColorSpaceChannel1: Int { 27 }
public var kvImageBufferTypeCode_ColorSpaceChannel10: Int { 28 }
public var kvImageBufferTypeCode_ColorSpaceChannel11: Int { 29 }
public var kvImageBufferTypeCode_ColorSpaceChannel12: Int { 30 }
public var kvImageBufferTypeCode_ColorSpaceChannel13: Int { 31 }
public var kvImageBufferTypeCode_ColorSpaceChannel14: Int { 32 }
public var kvImageBufferTypeCode_ColorSpaceChannel15: Int { 33 }
public var kvImageBufferTypeCode_ColorSpaceChannel16: Int { 34 }
public var kvImageBufferTypeCode_ColorSpaceChannel2: Int { 35 }
public var kvImageBufferTypeCode_ColorSpaceChannel3: Int { 36 }
public var kvImageBufferTypeCode_ColorSpaceChannel4: Int { 37 }
public var kvImageBufferTypeCode_ColorSpaceChannel5: Int { 38 }
public var kvImageBufferTypeCode_ColorSpaceChannel6: Int { 39 }
public var kvImageBufferTypeCode_ColorSpaceChannel7: Int { 40 }
public var kvImageBufferTypeCode_ColorSpaceChannel8: Int { 41 }
public var kvImageBufferTypeCode_ColorSpaceChannel9: Int { 42 }
public var kvImageBufferTypeCode_Cr: Int { 43 }
public var kvImageBufferTypeCode_EndOfList: Int { 44 }
public var kvImageBufferTypeCode_Indexed: Int { 45 }
public var kvImageBufferTypeCode_LAB_A: Int { 46 }
public var kvImageBufferTypeCode_LAB_B: Int { 47 }
public var kvImageBufferTypeCode_LAB_L: Int { 48 }
public var kvImageBufferTypeCode_Luminance: Int { 49 }
public var kvImageBufferTypeCode_Monochrome: Int { 50 }
public var kvImageBufferTypeCode_RGB_Blue: Int { 51 }
public var kvImageBufferTypeCode_RGB_Green: Int { 52 }
public var kvImageBufferTypeCode_RGB_Red: Int { 53 }
public var kvImageBufferTypeCode_UniqueFormatCount: Int { 54 }
public var kvImageBufferTypeCode_XYZ_X: Int { 55 }
public var kvImageBufferTypeCode_XYZ_Y: Int { 56 }
public var kvImageBufferTypeCode_XYZ_Z: Int { 57 }
public var kvImageCVImageFormat_AlphaIsOneHint: Int { 58 }
public var kvImageCVImageFormat_ChromaSiting: Int { 59 }
public var kvImageCVImageFormat_ColorSpace: Int { 60 }
public var kvImageCVImageFormat_ConversionMatrix: Int { 61 }
public var kvImageCVImageFormat_NoError: Int { 62 }
public var kvImageCVImageFormat_VideoChannelDescription: Int { 63 }
public var kvImageGamma_11_over_5_half_precision: Int { 5 }
public var kvImageGamma_11_over_9_half_precision: Int { 8 }
public var kvImageGamma_5_over_11_half_precision: Int { 4 }
public var kvImageGamma_5_over_9_half_precision: Int { 2 }
public var kvImageGamma_9_over_11_half_precision: Int { 9 }
public var kvImageGamma_9_over_5_half_precision: Int { 3 }
public var kvImageGamma_BT709_forward_half_precision: Int { 10 }
public var kvImageGamma_BT709_reverse_half_precision: Int { 11 }
public var kvImageGamma_UseGammaValue: Int { 0 }
public var kvImageGamma_UseGammaValue_half_precision: Int { 1 }
public var kvImageGamma_sRGB_forward_half_precision: Int { 6 }
public var kvImageGamma_sRGB_reverse_half_precision: Int { 7 }
public var kvImageInterpolationLinear: Int { 1 }
public var kvImageInterpolationNearest: Int { 0 }
public var kvImageMatrixType_ARGBToYpCbCrMatrix: Int { 1 }
public var kvImageMatrixType_None: Int { 0 }
public var kvImageBufferSizeMismatch: Int { -21774 }
public var kvImageColorSyncIsAbsent: Int { -21779 }
public var kvImageCoreVideoIsAbsent: Int { -21783 }
public var kvImageInternalError: Int { -21776 }
public var kvImageInvalidCVImageFormat: Int { -21781 }
public var kvImageInvalidEdgeStyle: Int { -21768 }
public var kvImageInvalidImageFormat: Int { -21778 }
public var kvImageInvalidImageObject: Int { -21784 }
public var kvImageInvalidKernelSize: Int { -21767 }
public var kvImageInvalidOffset_X: Int { -21769 }
public var kvImageInvalidOffset_Y: Int { -21770 }
public var kvImageInvalidParameter: Int { -21773 }
public var kvImageInvalidRowBytes: Int { -21777 }
public var kvImageMemoryAllocationError: Int { -21771 }
public var kvImageNoError: Int { 0 }
public var kvImageNullPointerArgument: Int { -21772 }
public var kvImageOutOfPlaceOperationRequired: Int { -21780 }
public var kvImageRoiLargerThanInputBuffer: Int { -21766 }
public var kvImageUnknownFlagsBit: Int { -21775 }
public var kvImageUnsupportedConversion: Int { -21782 }
public var kvImageBackgroundColorFill: Int { 4 }
public var kvImageCopyInPlace: Int { 2 }
public var kvImageDoNotClamp: Int { 2048 }
public var kvImageDoNotTile: Int { 16 }
public var kvImageEdgeExtend: Int { 8 }
public var kvImageGetTempBufferSize: Int { 128 }
public var kvImageHDRContent: Int { 1024 }
public var kvImageHighQualityResampling: Int { 32 }
public var kvImageLeaveAlphaUnchanged: Int { 1 }
public var kvImageNoAllocate: Int { 512 }
public var kvImageNoFlags: Int { 0 }
public var kvImagePrintDiagnosticsToConsole: Int { 256 }
public var kvImageTruncateKernel: Int { 64 }
public var kvImageUseFP16Accumulator: Int { 4096 }
public var kvImage_PNG_FILTER_VALUE_AVG: Int { 3 }
public var kvImage_PNG_FILTER_VALUE_NONE: Int { 0 }
public var kvImage_PNG_FILTER_VALUE_PAETH: Int { 4 }
public var kvImage_PNG_FILTER_VALUE_SUB: Int { 1 }
public var kvImage_PNG_FILTER_VALUE_UP: Int { 2 }
public var vDSP_HALF_WINDOW: Int { 2 }
public var vDSP_HANN_DENORM: Int { 0 }
public var vDSP_HANN_NORM: Int { 1 }
public var kvImageDecodeArray_16Q12Format: Int { 64 }
public var kvImage_ARGBToYpCbCrMatrix_ITU_R_601_4: Int { 65 }
public var kvImage_ARGBToYpCbCrMatrix_ITU_R_709_2: Int { 66 }
public var kvImage_YpCbCrToARGBMatrix_ITU_R_601_4: Int { 67 }
public var kvImage_YpCbCrToARGBMatrix_ITU_R_709_2: Int { 68 }
public var kvImageConvert_DitherAtkinson: UInt32 { 4 }
public var kvImageConvert_DitherFloydSteinberg: UInt32 { 3 }
public var kvImageConvert_DitherNone: UInt32 { 0 }
public var kvImageConvert_DitherOrdered: UInt32 { 1 }
public var kvImageConvert_DitherOrderedReproducible: UInt32 { 2 }
public var kvImageConvert_OrderedGaussianBlue: UInt32 { 0 }
public var kvImageConvert_OrderedNoiseShapeMask: UInt32 { 1 }
public var kvImageConvert_OrderedUniformBlue: UInt32 { 2 }
public var LA_ATTRIBUTE_ENABLE_LOGGING: UInt32 { 3 }
public var LA_FEATURE_DIAGONALLY_DOMINANT: UInt32 { 4 }
public var LA_FEATURE_POSITIVE_DEFINITE: UInt32 { 5 }
public var LA_FEATURE_SYMMETRIC: UInt32 { 6 }
public var LA_NO_HINT: UInt32 { 7 }
public var LA_SHAPE_DIAGONAL: UInt32 { 8 }
public var LA_SHAPE_LOWER_TRIANGULAR: UInt32 { 9 }
public var LA_SHAPE_UPPER_TRIANGULAR: UInt32 { 10 }
public var BNNS_MAX_TENSOR_DIMENSION: Int32 { 0 }
public var LA_DEFAULT_ATTRIBUTES: Int32 { 1 }
public var LA_DIMENSION_MISMATCH_ERROR: Int32 { 2 }
public var LA_INTERNAL_ERROR: Int32 { 3 }
public var LA_INVALID_PARAMETER_ERROR: Int32 { 4 }
public var LA_L1_NORM: Int32 { 5 }
public var LA_L2_NORM: Int32 { 6 }
public var LA_LINF_NORM: Int32 { 7 }
public var LA_PRECISION_MISMATCH_ERROR: Int32 { 8 }
public var LA_SCALAR_TYPE_DOUBLE: Int32 { 9 }
public var LA_SCALAR_TYPE_FLOAT: Int32 { 10 }
public var LA_SINGULAR_ERROR: Int32 { 11 }
public var LA_SLICE_OUT_OF_BOUNDS_ERROR: Int32 { 12 }
public var LA_SUCCESS: Int32 { 0 }
public var LA_WARNING_POORLY_CONDITIONED: Int32 { 14 }
public var QUADRATURE_INTEGRATE_QAGS_WORKSPACE_PER_INTERVAL: Int32 { 15 }
public var QUADRATURE_INTEGRATE_QAG_WORKSPACE_PER_INTERVAL: Int32 { 16 }
public var USE_NON_APPLE_STANDARD_DATATYPES: Int32 { 17 }
public var VIMAGE_AFFINETRANSFORM_DOUBLE_IS_AVAILABLE: Int32 { 18 }
public var VIMAGE_CGAFFINETRANSFORM_IS_AVAILABLE: Int32 { 19 }
public var vDSP_Version0: Int32 { 20 }
public var vDSP_Version1: Int32 { 21 }
