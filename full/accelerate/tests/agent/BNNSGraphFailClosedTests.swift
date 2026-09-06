import Accelerate
import Foundation

func testBNNSGraphMakeContextFailClosed() {
    do {
        _ = try BNNSGraph.makeContext(options: BNNSGraph.CompileOptions()) { builder in
            _ = builder
            return []
        }
        preconditionFailure("makeContext should throw")
    } catch let error as BNNSGraph.Error {
        precondition(error == .unableToCreateContext)
    } catch {
        preconditionFailure("unexpected error")
    }
}

func testBNNSGraphCFailClosed() {
    let graph = BNNSGraphCompileFromFile("missing.bnnsgraph", nil, BNNSGraphCompileOptionsMakeDefault())
    precondition(graph.data == nil)
    let options = BNNSGraphCompileOptionsMakeDefault()
    BNNSGraphCompileOptionsSetGenerateDebugInfo(options, true)
    BNNSGraphCompileOptionsSetTargetSingleThread(options, true)
    BNNSGraphCompileOptionsSetOptimizationPreference(options, BNNSGraphOptimizationPreference(rawValue: 0))
    BNNSGraphCompileOptionsSetOutputFD(options, -1)
    BNNSGraphCompileOptionsSetOutputPath(options, nil)
    BNNSGraphCompileOptionsSetMessageLogMask(options, 0)
    BNNSGraphCompileOptionsSetMessageLogCallback(options, { _, _, _, _ in }, nil)
    precondition(BNNSGraphCompileOptionsGetGenerateDebugInfo(options) == false)
    _ = BNNSGraphCompileOptionsGetOptimizationPreference(options)
    _ = BNNSGraphCompileOptionsGetOutputFD(options)
    _ = BNNSGraphCompileOptionsGetOutputPath(options)
    _ = BNNSGraphCompileOptionsGetTargetSingleThread(options)
    BNNSGraphCompileOptionsDestroy(options)
    let ctx = BNNSGraphContextMake(graph)
    precondition(ctx.data == nil)
    _ = BNNSGraphContextMakeStreaming(graph, nil, 0, nil)
    BNNSGraphContextEnableNanAndInfChecks(ctx, true)
    var arg = bnns_graph_argument_t()
    precondition(BNNSGraphContextExecute(ctx, nil, 0, &arg, 0, nil) == BNNSLinuxFailClosedStatus)
    var tensor = BNNSTensor()
    precondition(BNNSGraphContextGetTensor(ctx, nil, "x", false, &tensor) == BNNSLinuxFailClosedStatus)
    _ = BNNSGraphContextGetWorkspaceSize(ctx, nil)
    _ = BNNSGraphContextSetArgumentType(ctx, BNNSGraphArgumentType(rawValue: 0))
    _ = BNNSGraphContextSetBatchSize(ctx, nil, 1)
    var shape = bnns_graph_shape_t()
    _ = BNNSGraphContextSetDynamicShapes(ctx, nil, 0, &shape)
    _ = BNNSGraphContextSetMessageLogCallback(ctx, { _, _, _, _ in }, nil)
    _ = BNNSGraphContextSetMessageLogMask(ctx, 0)
    _ = BNNSGraphContextSetOutputAllocationCallback(ctx, nil, nil, 0, nil)
    _ = BNNSGraphContextSetStreamingAdvanceCount(ctx, 0)
    _ = BNNSGraphContextSetWorkspaceAllocationCallback(ctx, nil, nil, 0, nil)
    _ = BNNSGraphGetArgumentCount(graph, nil)
    var intent = BNNSGraphArgumentIntent(rawValue: 0)
    _ = BNNSGraphGetArgumentIntents(graph, nil, 0, &intent)
    var interleave: UnsafePointer<UInt16>? = nil
    var interleaveCount = 0
    _ = BNNSGraphGetArgumentInterleaveFactors(graph, nil, 0, &interleave, &interleaveCount)
    var name: UnsafePointer<CChar>? = nil
    _ = BNNSGraphGetArgumentNames(graph, nil, 0, &name)
    _ = BNNSGraphGetArgumentPosition(graph, nil, "x")
    _ = BNNSGraphGetFunctionCount(graph)
    _ = BNNSGraphGetFunctionNames(graph, 0, &name)
    _ = BNNSGraphGetInputCount(graph, nil)
    _ = BNNSGraphGetInputNames(graph, nil, 0, &name)
    _ = BNNSGraphGetOutputCount(graph, nil)
    _ = BNNSGraphGetOutputNames(graph, nil, 0, &name)
    _ = BNNSGraphTensorFillStrides(graph, nil, "x", &tensor)
    BNNSGraphContextDestroy(ctx)
    _ = options
}

func testSparseSolveParameterMismatch() {
    var rows: [Int32] = [0]
    var cols: [Int32] = [0]
    var vals: [Float] = [1]
    let A = SparseConvertFromCoordinate(1, 1, 1, 1, SparseAttributes_t(), &rows, &cols, &vals)
    var bdata: [Float] = [1, 1]
    var xdata: [Float] = [0, 0]
    let b = DenseVector_Float(count: 2, data: &bdata)
    let x = DenseVector_Float(count: 2, data: &xdata)
    let status = SparseSolve(SparseConjugateGradient(), A, b, x)
    precondition(status == SparseIterativeParameterError)
    SparseCleanup(A)
}
