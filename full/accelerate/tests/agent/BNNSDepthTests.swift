import Accelerate
import Foundation

private func _desc(_ data: UnsafeMutablePointer<Float>, _ count: Int) -> BNNSNDArrayDescriptor {
    var d = BNNSNDArrayDescriptor()
    d.data = UnsafeMutableRawPointer(data)
    d.data_type = BNNSDataTypeFloat32
    d.size.0 = count
    return d
}

func testBNNSDataLayoutRankAndAllCases() {
    precondition(BNNS.DataLayout.vector.rank == 1)
    precondition(BNNS.DataLayout.matrixRowMajor.rank == 2)
    precondition(BNNS.DataLayout.imageCHW.rank == 3)
    precondition(BNNS.DataLayout.tensor4DLastMajor.rank == 4)
    precondition(BNNS.DataLayout.convolutionWeightsOIHW.rank == 4)
    precondition(BNNS.DataLayout.allCases.count == 21)
    precondition(BNNSDataLayoutGetRank(BNNSDataLayoutVector) == 1)
    precondition(BNNSDataLayoutGetRank(BNNSDataLayoutRowMajorMatrix) == 2)
    precondition(BNNSDataLayoutGetRank(BNNSDataLayoutImageCHW) == 3)
    precondition(BNNS.ConvolutionPadding.zero == .symmetric(x: 0, y: 0))
}

func testBNNSShapeRankSizeStride() {
    let vector = BNNS.Shape.vector(4, stride: 1)
    precondition(vector.rank == 1)
    precondition(vector.size.0 == 4)
    precondition(vector.stride.0 == 1)
    precondition(vector.batchStride == 1)
    precondition(vector.layout == BNNSDataLayoutVector)
    let matrix: BNNS.Shape = [2, 3]
    precondition(matrix.rank == 2)
    precondition(matrix.size.0 == 2)
    precondition(matrix.size.1 == 3)
    let fromLayout = BNNS.Shape([2, 2], dataLayout: .matrixColumnMajor, stride: [1, 2])
    precondition(fromLayout.rank == 2)
    let t3 = BNNS.Shape([2, 3, 4])
    precondition(t3.rank == 3)
    let t4 = BNNS.Shape([1, 2, 3, 4])
    precondition(t4.rank == 4)
    let graph: BNNSGraph.Shape = [2, 4, 8]
    precondition(graph.dimensions == [2, 4, 8])
    let graph2 = BNNSGraph.Shape([1, 1])
    precondition(graph2.dimensions == [1, 1])
}

func testBNNSArithmeticAllCasesAndApply() {
    precondition(BNNS.ArithmeticUnaryFunction.allCases.count == 27)
    precondition(BNNS.ArithmeticBinaryFunction.allCases.count == 12)
    var srcVals: [Float] = [-2, 4, 9]
    var dstVals: [Float] = [0, 0, 0]
    var src = _desc(&srcVals, 3)
    var dst = _desc(&dstVals, 3)
    guard let layer = BNNS.UnaryArithmeticLayer(
        input: src,
        inputDescriptorType: .sample,
        output: dst,
        outputDescriptorType: .sample,
        function: .abs,
        activation: .identity,
        filterParameters: nil
    ) else {
        preconditionFailure("unary layer")
    }
    try! layer.apply(batchSize: 1, input: src, output: dst)
    precondition(dstVals == [2, 4, 9])
    var aVals: [Float] = [1, 2, 3]
    var bVals: [Float] = [4, 5, 6]
    var oVals: [Float] = [0, 0, 0]
    var a = _desc(&aVals, 3)
    var b = _desc(&bVals, 3)
    var o = _desc(&oVals, 3)
    guard let binary = BNNS.BinaryArithmeticLayer(
        inputA: a,
        inputADescriptorType: .sample,
        inputB: b,
        inputBDescriptorType: .sample,
        output: o,
        outputDescriptorType: .sample,
        function: .add,
        activation: .identity,
        filterParameters: nil
    ) else {
        preconditionFailure("binary layer")
    }
    try! binary.apply(batchSize: 1, inputA: a, inputB: b, output: o)
    precondition(oVals == [5, 7, 9])
}

func testBNNSOverlayCopyClipGatherTranspose() {
    var srcVals: [Float] = [1, 2, 3, 4]
    var dstVals: [Float] = [0, 0, 0, 0]
    var src = _desc(&srcVals, 4)
    var dst = _desc(&dstVals, 4)
    try! BNNS.copy(src, to: dst, filterParameters: nil)
    precondition(dstVals == srcVals)
    var clipSrc: [Float] = [-2, 0.5, 9]
    var clipDst: [Float] = [0, 0, 0]
    var csrc = _desc(&clipSrc, 3)
    var cdst = _desc(&clipDst, 3)
    try! BNNS.clip(to: Float(0)...Float(1), input: csrc, output: cdst)
    precondition(clipDst == [0, 0.5, 1])
    var gatherSrc: [Float] = [10, 20, 30]
    var gatherIdx: [Float] = [2, 0]
    var gatherDst: [Float] = [0, 0]
    var gsrc = _desc(&gatherSrc, 3)
    var gidx = _desc(&gatherIdx, 2)
    var gdst = _desc(&gatherDst, 2)
    try! BNNS.gather(input: gsrc, indices: gidx, output: gdst, axis: 0, filterParameters: nil)
    precondition(gatherDst == [30, 10])
    var tsrcVals: [Float] = [1, 2, 3, 4, 5, 6]
    var tdstVals: [Float] = [0, 0, 0, 0, 0, 0]
    tsrcVals.withUnsafeMutableBufferPointer { sp in
        tdstVals.withUnsafeMutableBufferPointer { dp in
            var tsrc = BNNSNDArrayDescriptor()
            tsrc.data = UnsafeMutableRawPointer(sp.baseAddress!)
            tsrc.size.0 = 2
            tsrc.size.1 = 3
            var tdst = BNNSNDArrayDescriptor()
            tdst.data = UnsafeMutableRawPointer(dp.baseAddress!)
            tdst.size.0 = 3
            tdst.size.1 = 2
            try! BNNS.transpose(
                input: tsrc,
                output: tdst,
                firstTransposeAxis: 0,
                secondTransposeAxis: 1,
                filterParameters: nil
            )
            precondition(Array(dp) == [1, 4, 2, 5, 3, 6])
        }
    }
    var gsrcVals: [Float] = [7, 8, 9]
    var gidxVals: [Float] = [1]
    var goutVals: [Float] = [0]
    gsrcVals.withUnsafeMutableBufferPointer { sp in
        gidxVals.withUnsafeMutableBufferPointer { ip in
            goutVals.withUnsafeMutableBufferPointer { op in
                var gsrc = BNNSNDArrayDescriptor()
                gsrc.data = UnsafeMutableRawPointer(sp.baseAddress!)
                gsrc.size.0 = 3
                var gidx = BNNSNDArrayDescriptor()
                gidx.data = UnsafeMutableRawPointer(ip.baseAddress!)
                gidx.size.0 = 1
                var gout = BNNSNDArrayDescriptor()
                gout.data = UnsafeMutableRawPointer(op.baseAddress!)
                gout.size.0 = 1
                precondition(BNNSGather(0, &gsrc, &gidx, &gout, nil) == 0)
                precondition(op[0] == 8)
            }
        }
    }
}

func testVDSPBiquadOverlayIdentity() {
    guard let filter = vDSP.Biquad(
        coefficients: [1, 0, 0, 0, 0],
        channelCount: 1,
        sectionCount: 1,
        ofType: Float.self
    ) else {
        preconditionFailure("biquad")
    }
    let input: [Float] = [1, 2, 3, 4]
    var output = [Float](repeating: 0, count: 4)
    filter.apply(input: input, output: &output)
    precondition(output == input)
    let copied = filter.apply(input: input)
    precondition(copied == input)
}
