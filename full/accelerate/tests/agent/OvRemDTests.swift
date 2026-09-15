import Accelerate
import Foundation

// Swift overlay remainder D: oracle-pinned value implementations and
// sink-setter coverage for fail-closed BNNS parameter structs.
// Trap-on-read getters stay referenced by keypath only in OvRemA/B/C;
// every precondition below executes real Linux behavior.

func testOvRemDOptionSetMutating() {
    var flags = BNNSFlags(rawValue: 0)
    flags.update(with: BNNSFlags(rawValue: 1))
    precondition(flags.rawValue == 1)
    flags.subtract(BNNSFlags(rawValue: 1))
    precondition(flags.rawValue == 0)
    var opts = vImage.Options.noFlags
    opts.update(with: .doNotTile)
    precondition(opts == .doNotTile)
    opts.subtract(.doNotTile)
    precondition(opts == .noFlags)
}

func testOvRemDFromSplitComplex() {
    var real: [Float] = [1, 2, 3, 4]
    var imag: [Float] = [5, 6, 7, 8]
    let single = real.withUnsafeMutableBufferPointer { rp in
        imag.withUnsafeMutableBufferPointer { ip in
            Array<Float>(
                fromSplitComplex: DSPSplitComplex(realp: rp.baseAddress!, imagp: ip.baseAddress!),
                scale: 2, count: 4)
        }
    }
    precondition(single == [2, 10, 4, 12])
    precondition(Array<Float>(fromSplitComplex: DSPSplitComplex(), scale: 1, count: 0) == [])
    var dreal: [Double] = [1, 2]
    var dimag: [Double] = [3, 4]
    let double = dreal.withUnsafeMutableBufferPointer { rp in
        dimag.withUnsafeMutableBufferPointer { ip in
            Array<Double>(
                fromSplitComplex: DSPDoubleSplitComplex(realp: rp.baseAddress!, imagp: ip.baseAddress!),
                scale: 0.5, count: 2)
        }
    }
    precondition(double == [0.5, 1.5])
}

func testOvRemDBufferTypeValues() {
    _ = vImage.BufferType.RawValue.self
    precondition(vImage.BufferType.RawValue.self == Int.self)
    precondition(vImage.BufferType.alpha.rawValue == 0)
    precondition(vImage.BufferType.chunky.rawValue == 10)
    precondition(vImage.BufferType.luminance.rawValue == 15)
    precondition(vImage.BufferType(rawValue: 10) == .chunky)
    precondition(vImage.BufferType(rawValue: 99) == nil)
    precondition(vImage.BufferType.chunky.bufferTypeCode == 25)
    precondition(vImage.BufferType.alpha.bufferTypeCode == 17)
    precondition(vImage.BufferType.luminance.bufferTypeCode == 20)
}

func testOvRemDFloodFillValues() {
    _ = vImage.FloodFillConnectivity.RawValue.self
    precondition(vImage.FloodFillConnectivity.RawValue.self == Int32.self)
    precondition(vImage.FloodFillConnectivity.edges.rawValue == 4)
    precondition(vImage.FloodFillConnectivity.edgesAndCorners.rawValue == 8)
    precondition(vImage.FloodFillConnectivity(rawValue: 4) == .edges)
    precondition(vImage.FloodFillConnectivity(rawValue: 8) == .edgesAndCorners)
    precondition(vImage.FloodFillConnectivity(rawValue: 0) == nil)
}

func testOvRemDMorphologyRelational() {
    let kernel = vImage.ConvolutionKernel2D<UInt8>(
        values: [1, 2, 3, 4], size: vImage.Size(width: 2, height: 2))
    let erode = vImage.MorphologyOperation<UInt8>.erode(structuringElement: kernel)
    precondition(erode.structuringElement?.values == [1, 2, 3, 4])
    precondition(erode.structuringElement?.width == 2)
    precondition(erode.width == 2 && erode.height == 2)
    let dilate = vImage.MorphologyOperation<UInt8>.dilate(structuringElement: kernel)
    precondition(dilate.structuringElement?.height == 2)
    precondition(dilate.width == 2 && dilate.height == 2)
    let maximize = vImage.MorphologyOperation<UInt8>.maximize(
        kernelSize: vImage.Size(width: 3, height: 5))
    precondition(maximize.structuringElement == nil)
    precondition(maximize.width == 3 && maximize.height == 5)
    _ = BNNS.RelationalOperator.self
    precondition(BNNS.RelationalOperator.greaterEqual.rawValue == BNNSRelationalOperatorGreaterEqual)
    precondition(BNNS.RelationalOperator.or.rawValue == BNNSRelationalOperatorLogicalOR)
    precondition(BNNS.RelationalOperator.and.rawValue == BNNSRelationalOperatorLogicalAND)
    precondition(BNNS.RelationalOperator.nor.rawValue == BNNSRelationalOperatorLogicalNOR)
    precondition(BNNS.RelationalOperator.not.rawValue == BNNSRelationalOperatorLogicalNOT)
    precondition(BNNS.RelationalOperator.xor.rawValue == BNNSRelationalOperatorLogicalXOR)
    precondition(BNNS.RelationalOperator.less.rawValue == BNNSRelationalOperatorLess)
    precondition(BNNS.RelationalOperator.nand.rawValue == BNNSRelationalOperatorLogicalNAND)
    precondition(BNNS.RelationalOperator.equal.rawValue == BNNSRelationalOperatorEqual)
    precondition(BNNS.RelationalOperator.greater.rawValue == BNNSRelationalOperatorGreater)
    precondition(BNNS.RelationalOperator.notEqual.rawValue == BNNSRelationalOperatorNotEqual)
    precondition(BNNS.RelationalOperator.lessEqual.rawValue == BNNSRelationalOperatorLessEqual)
}

func testOvRemDScalarDataTypes() {
    func scalarDataType<S: BNNSScalar>(_ scalar: S.Type) -> BNNSDataType {
        scalar.bnnsDataType
    }
    precondition(scalarDataType(Float.self) == BNNSDataTypeFloat32)
    precondition(scalarDataType(Int8.self) == BNNSDataTypeInt8)
    precondition(scalarDataType(Bool.self) == BNNSDataTypeBoolean)
    precondition(Bool.bnnsDataType.rawValue == 1048584)
    precondition(UInt8.bnnsDataType.rawValue == 262152)
    precondition(UInt16.bnnsDataType.rawValue == 262160)
    precondition(UInt32.bnnsDataType.rawValue == 262176)
    precondition(Int64.bnnsDataType.rawValue == 131136)
    precondition(UInt64.bnnsDataType.rawValue == 262208)
    precondition(Int8.bnnsDataType.rawValue == 131080)
    precondition(Float.bnnsDataType.rawValue == 65568)
}

func testOvRemDStaticPlaneWitnesses() {
    func bitCount<F: StaticPixelFormat>(_ format: F.Type) -> Int { format.bitCountPerPixel }
    precondition(bitCount(vImage.Planar8.self) == 8)
    precondition(bitCount(vImage.PlanarF.self) == 32)
    precondition(bitCount(vImage.Planar16F.self) == 16)
    precondition(bitCount(vImage.Planar16U.self) == 16)
    func planarBits<F: MultiplePlanePixelFormat>(_ format: F.Type) -> Int {
        format.bitCountPerPlanarPixel
    }
    precondition(planarBits(vImage.Planar8x2.self) == 8)
    precondition(planarBits(vImage.PlanarFx4.self) == 32)
    func planeCount<F: MultiplePlanePixelFormat>(_ format: F.Type) -> Int { format.planeCount }
    precondition(planeCount(vImage.Planar8x3.self) == 3)
    precondition(planeCount(vImage.PlanarFx2.self) == 2)
    func planarFormat<F: MultiplePlanePixelFormat>(_ format: F.Type) -> Any.Type {
        format.PlanarPixelFormat.self
    }
    precondition(planarFormat(vImage.Planar8x4.self) == vImage.Planar8.self)
    precondition(planarFormat(vImage.PlanarFx2.self) == vImage.PlanarF.self)
}

func testOvRemDScalarAssocWitnesses() {
    precondition(vDSP.VectorizableFloat.Scalar.self == Float.self)
    precondition(vDSP.VectorizableDouble.Scalar.self == Double.self)
    func dftScalar<F: vDSP_DFTFunctions>(_ functions: F.Type) -> Any.Type { F.Scalar.self }
    precondition(dftScalar(vDSP.VectorizableFloat.self) == Float.self)
    precondition(dftScalar(vDSP.VectorizableDouble.self) == Double.self)
    func biquadScalar<F: vDSP_BiquadFunctions>(_ functions: F.Type) -> Any.Type { F.Scalar.self }
    precondition(biquadScalar(vDSP.VectorizableFloat.self) == Float.self)
    precondition(biquadScalar(vDSP.VectorizableDouble.self) == Double.self)
    func splitComplex<F: vDSP_FourierTransformFunctions>(_ functions: F.Type) -> Any.Type {
        F.SplitComplex.self
    }
    precondition(splitComplex(vDSP_SplitComplexFloat.self) == DSPSplitComplex.self)
    precondition(splitComplex(vDSP_SplitComplexDouble.self) == DSPDoubleSplitComplex.self)
    func fftFunctions<T: vDSP_FourierTransformable>(_ value: T.Type) -> Any.Type {
        T.FFTFunctions.self
    }
    precondition(fftFunctions(DSPSplitComplex.self) == vDSP_SplitComplexFloat.self)
    precondition(fftFunctions(DSPDoubleSplitComplex.self) == vDSP_SplitComplexDouble.self)
    func biquadFunctions<T: vDSP_FloatingPointBiquadFilterable>(_ value: T.Type) -> Any.Type {
        T.BiquadFunctions.self
    }
    precondition(biquadFunctions(Float.self) == vDSP.VectorizableFloat.self)
    precondition(biquadFunctions(Double.self) == vDSP.VectorizableDouble.self)
    func dftFunctions<T: vDSP_FloatingPointDiscreteFourierTransformable>(
        _ value: T.Type
    ) -> Any.Type { T.DFTFunctions.self }
    precondition(dftFunctions(Float.self) == vDSP.VectorizableFloat.self)
    precondition(dftFunctions(Double.self) == vDSP.VectorizableDouble.self)
    func discreteFunctions<T: vDSP_DiscreteFourierTransformable>(
        _ value: T.Type
    ) -> Any.Type { T.DiscreteFourierTransformFunctions.self }
    precondition(
        discreteFunctions(Float.self) == vDSP.DFTSinglePrecisionSplitComplexFunctions.self)
    precondition(
        discreteFunctions(DSPComplex.self) == vDSP.DFTSinglePrecisionInterleavedFunctions.self)
}

func testOvRemDFusedSparseSetters() {
    var conv = BNNS.FusedConvolutionParameters()
    conv.type = .standard
    conv.dilationStride = (x: 1, y: 1)
    conv.padding = .zero
    conv.groupSize = 1
    var norm = BNNS.FusedNormalizationParameters()
    norm.type = .group(groupCount: 1)
    var ternary = BNNS.FusedTernaryArithmeticParameters()
    ternary.function = .multiplyAdd
    ternary.inputCDescriptorType = .sample
    var sparse = BNNS.SparseParameters()
    sparse.type = .unstructured
    sparse.ratio = (numerator: 1, denominator: 2)
    sparse.targetSystem = BNNSTargetSystem(rawValue: 0)
    _ = conv
    _ = norm
    _ = ternary
    _ = sparse
}

func testOvRemDLayerFilter() {
    let layer = BNNS.Layer()
    let raw = UnsafeMutableRawPointer.allocate(byteCount: 1, alignment: 1)
    layer.bnnsFilter = raw
    raw.deallocate()
}
