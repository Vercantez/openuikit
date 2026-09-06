import Foundation
import MetalPerformanceShadersGraph

func testReshapeBroadcastConcat() {
    let graph = MPSGraph()
    let x = mpsgPlaceholder(graph, 2, 2, name: "x")
    let y = mpsgPlaceholder(graph, 2, 2, name: "y")
    let feeds = [
        x: mpsgFloatData([1, 2, 3, 4], shape: [2, 2]),
        y: mpsgFloatData([5, 6, 7, 8], shape: [2, 2])
    ]
    mpsgClose(mpsgRun(graph, feeds: feeds, graph.reshape(x, shape: mpsgShape(4), name: nil)), [1, 2, 3, 4])
    _ = graph.reshape(x, shapeTensor: graph.constant(4, dataType: .int32), name: nil)
    mpsgClose(mpsgRun(graph, feeds: feeds, graph.broadcast(x, shape: mpsgShape(2, 2), name: nil)), [1, 2, 3, 4])
    _ = graph.broadcast(x, shapeTensor: x, name: nil)
    mpsgClose(mpsgRun(graph, feeds: feeds, graph.concatTensor(x, with: y, dimension: 0, name: nil)), [1, 2, 3, 4, 5, 6, 7, 8])
    mpsgClose(mpsgRun(graph, feeds: feeds, graph.concatTensors([x, y], dimension: 0, name: nil)), [1, 2, 3, 4, 5, 6, 7, 8])
    _ = graph.concatTensors([x, y], dimension: 0, interleave: false, name: nil)
    mpsgClose(mpsgRun(graph, feeds: feeds, graph.stack([x, y], axis: 0, name: nil)), [1, 2, 3, 4, 5, 6, 7, 8])
    let squeezed = graph.squeeze(graph.expandDims(x, axis: 0, name: nil), axis: 0, name: nil)
    mpsgClose(mpsgRun(graph, feeds: feeds, squeezed), [1, 2, 3, 4])
    _ = graph.squeeze(x, axes: mpsgShape(0), name: nil)
    _ = graph.squeeze(x, axesTensor: x, name: nil)
    _ = graph.squeeze(x, name: nil)
    _ = graph.expandDims(x, axes: mpsgShape(0), name: nil)
    _ = graph.expandDims(x, axesTensor: x, name: nil)
    _ = graph.flatten2D(x, axis: 1, name: nil)
    _ = graph.flatten2D(x, axisTensor: x, name: nil)
    let parts = graph.split(x, numSplits: 2, axis: 0, name: nil)
    precondition(parts.count == 2)
    _ = graph.split(x, splitSizes: mpsgShape(1, 1), axis: 0, name: nil)
    _ = graph.split(x, splitSizesTensor: x, axis: 0, name: nil)
}

func testTransposeSlicePad() {
    let graph = MPSGraph()
    let x = mpsgPlaceholder(graph, 2, 2, name: "x")
    let feeds = [x: mpsgFloatData([1, 2, 3, 4], shape: [2, 2])]
    mpsgClose(mpsgRun(graph, feeds: feeds, graph.transpose(x, permutation: mpsgShape(1, 0), name: nil)), [1, 3, 2, 4])
    _ = graph.transposeTensor(x, dimension: 0, withDimension: 1, name: nil)
    mpsgClose(mpsgRun(graph, feeds: feeds, graph.sliceTensor(x, dimension: 0, start: 0, length: 2, name: nil)), [1, 2, 3, 4])
    _ = graph.sliceTensor(x, starts: mpsgShape(0, 0), ends: mpsgShape(2, 2), strides: mpsgShape(1, 1), name: nil)
    _ = graph.sliceTensor(x, starts: mpsgShape(0, 0), ends: mpsgShape(2, 2), strides: mpsgShape(1, 1), startMask: 0, endMask: 0, squeezeMask: 0, name: nil)
    _ = graph.sliceTensor(x, start: x, end: x, strideTensor: x, startMask: 0, endMask: 0, squeezeMask: 0, name: nil)
    _ = graph.sliceTensor(x, start: x, sizeTensor: x, squeezeMask: 0, name: nil)
    _ = graph.sliceGradientTensor(x, fwdInShapeTensor: x, starts: mpsgShape(0, 0), ends: mpsgShape(2, 2), strides: mpsgShape(1, 1), name: nil)
    _ = graph.sliceGradientTensor(x, fwdInShapeTensor: x, starts: mpsgShape(0, 0), ends: mpsgShape(2, 2), strides: mpsgShape(1, 1), startMask: 0, endMask: 0, squeezeMask: 0, name: nil)
    _ = graph.sliceGradientTensor(x, fwdInShapeTensor: x, start: x, end: x, strideTensor: x, startMask: 0, endMask: 0, squeezeMask: 0, name: nil)
    _ = graph.sliceGradientTensor(x, fwdInShapeTensor: x, start: x, sizeTensor: x, squeezeMask: 0, name: nil)
    _ = graph.sliceUpdateDataTensor(x, update: x, starts: mpsgShape(0, 0), ends: mpsgShape(1, 1), strides: mpsgShape(1, 1), name: nil)
    _ = graph.sliceUpdateDataTensor(x, update: x, starts: mpsgShape(0, 0), ends: mpsgShape(1, 1), strides: mpsgShape(1, 1), startMask: 0, endMask: 0, squeezeMask: 0, name: nil)
    _ = graph.sliceUpdateDataTensor(x, update: x, startsTensor: x, endsTensor: x, stridesTensor: x, name: nil)
    _ = graph.sliceUpdateDataTensor(x, update: x, startsTensor: x, endsTensor: x, stridesTensor: x, startMask: 0, endMask: 0, squeezeMask: 0, name: nil)
    mpsgClose(mpsgRun(graph, feeds: feeds, graph.padTensor(x, with: .zero, leftPadding: mpsgShape(0, 0), rightPadding: mpsgShape(0, 0), constantValue: 0, name: nil)), [1, 2, 3, 4])
    _ = graph.padGradient(withIncomingGradientTensor: x, sourceTensor: x, paddingMode: .zero, leftPadding: mpsgShape(0, 0), rightPadding: mpsgShape(0, 0), name: nil)
    _ = graph.tileTensor(x, withMultiplier: mpsgShape(1, 1), name: nil)
    _ = graph.tileGradient(withIncomingGradientTensor: x, sourceTensor: x, withMultiplier: mpsgShape(1, 1), name: nil)
    _ = graph.reverse(x, name: nil)
    _ = graph.reverse(x, axes: mpsgShape(0), name: nil)
    _ = graph.reverse(x, axesTensor: x, name: nil)
    _ = graph.shapeOf(x, name: nil)
}

func testReductionsAndSoftmax() {
    let graph = MPSGraph()
    let x = mpsgPlaceholder(graph, 4, name: "x")
    let feeds = [x: mpsgFloatData([1, 2, 3, 4], shape: [4])]
    mpsgClose(mpsgRun(graph, feeds: feeds, graph.reductionSum(with: x, axes: nil, name: nil)), [10])
    _ = graph.reductionSum(with: x, axis: 0, name: nil)
    mpsgClose(mpsgRun(graph, feeds: feeds, graph.reductionMaximum(with: x, axes: nil, name: nil)), [4])
    _ = graph.reductionMaximum(with: x, axis: 0, name: nil)
    mpsgClose(mpsgRun(graph, feeds: feeds, graph.reductionMinimum(with: x, axes: nil, name: nil)), [1])
    _ = graph.reductionMinimum(with: x, axis: 0, name: nil)
    mpsgClose(mpsgRun(graph, feeds: feeds, graph.reductionProduct(with: x, axes: nil, name: nil)), [24])
    _ = graph.reductionProduct(with: x, axis: 0, name: nil)
    _ = graph.reductionAnd(with: x, axes: nil, name: nil)
    _ = graph.reductionAnd(with: x, axis: 0, name: nil)
    _ = graph.reductionOr(with: x, axes: nil, name: nil)
    _ = graph.reductionOr(with: x, axis: 0, name: nil)
    _ = graph.reductionArgMaximum(with: x, axis: 0, name: nil)
    _ = graph.reductionArgMinimum(with: x, axis: 0, name: nil)
    _ = graph.reductionMaximumPropagateNaN(with: x, axes: nil, name: nil)
    _ = graph.reductionMaximumPropagateNaN(with: x, axis: 0, name: nil)
    _ = graph.reductionMinimumPropagateNaN(with: x, axes: nil, name: nil)
    _ = graph.reductionMinimumPropagateNaN(with: x, axis: 0, name: nil)
    mpsgClose(mpsgRun(graph, feeds: feeds, graph.mean(of: x, axes: mpsgShape(0), name: nil)), [2.5])
    let s = graph.placeholder(shape: mpsgShape(2), dataType: .float32, name: "sm")
    mpsgClose(mpsgRun(graph, feeds: [s: mpsgFloatData([0, 0], shape: [2])], graph.softMax(with: s, axis: 0, name: nil)), [0.5, 0.5])
    _ = graph.softMaxGradient(withIncomingGradient: x, sourceTensor: x, axis: 0, name: nil)
    _ = graph.softMaxCrossEntropy(x, labels: x, axis: 0, reuctionType: .none, name: nil)
    _ = graph.softMaxCrossEntropyGradient(x, source: x, labels: x, axis: 0, reuctionType: .mean, name: nil)
}

func testMatmul() {
    let graph = MPSGraph()
    let a = mpsgPlaceholder(graph, 2, 2, name: "a")
    let b = mpsgPlaceholder(graph, 2, 2, name: "b")
    let feeds = [
        a: mpsgFloatData([1, 2, 3, 4], shape: [2, 2]),
        b: mpsgFloatData([5, 6, 7, 8], shape: [2, 2])
    ]
    mpsgClose(
        mpsgRun(graph, feeds: feeds, graph.matrixMultiplication(primary: a, secondary: b, name: nil)),
        [19, 22, 43, 50]
    )
}

func testOneHotAndCoordinate() {
    let graph = MPSGraph()
    let idx = mpsgPlaceholder(graph, 1, name: "i")
    _ = graph.oneHot(withIndicesTensor: idx, depth: 3, name: nil)
    _ = graph.oneHot(withIndicesTensor: idx, depth: 3, dataType: .float32, name: nil)
    _ = graph.oneHot(withIndicesTensor: idx, depth: 3, axis: 0, name: nil)
    _ = graph.oneHot(withIndicesTensor: idx, depth: 3, axis: 0, dataType: .float32, name: nil)
    _ = graph.oneHot(withIndicesTensor: idx, depth: 3, dataType: .float32, onValue: 1, offValue: 0, name: nil)
    _ = graph.oneHot(withIndicesTensor: idx, depth: 3, axis: 0, dataType: .float32, onValue: 1, offValue: 0, name: nil)
    _ = graph.coordinate(alongAxis: 0, withShape: mpsgShape(3), name: nil)
    _ = graph.coordinate(alongAxis: 0, withShapeTensor: idx, name: nil)
    _ = graph.coordinate(alongAxisTensor: idx, withShape: mpsgShape(3), name: nil)
    _ = graph.coordinate(alongAxisTensor: idx, withShapeTensor: idx, name: nil)
}

func testCumulativeOps() {
    let graph = MPSGraph()
    let x = mpsgPlaceholder(graph, 3, name: "x")
    _ = graph.cumulativeSum(x, axis: 0, name: nil)
    _ = graph.cumulativeSum(x, axis: 0, exclusive: false, reverse: false, name: nil)
    _ = graph.cumulativeSum(x, axisTensor: x, name: nil)
    _ = graph.cumulativeSum(x, axisTensor: x, exclusive: false, reverse: false, name: nil)
    _ = graph.cumulativeProduct(x, axis: 0, name: nil)
    _ = graph.cumulativeProduct(x, axis: 0, exclusive: false, reverse: false, name: nil)
    _ = graph.cumulativeProduct(x, axisTensor: x, name: nil)
    _ = graph.cumulativeProduct(x, axisTensor: x, exclusive: false, reverse: false, name: nil)
    _ = graph.cumulativeMaximum(x, axis: 0, name: nil)
    _ = graph.cumulativeMaximum(x, axis: 0, exclusive: false, reverse: false, name: nil)
    _ = graph.cumulativeMaximum(x, axisTensor: x, name: nil)
    _ = graph.cumulativeMaximum(x, axisTensor: x, exclusive: false, reverse: false, name: nil)
    _ = graph.cumulativeMinimum(x, axis: 0, name: nil)
    _ = graph.cumulativeMinimum(x, axis: 0, exclusive: false, reverse: false, name: nil)
    _ = graph.cumulativeMinimum(x, axisTensor: x, name: nil)
    _ = graph.cumulativeMinimum(x, axisTensor: x, exclusive: false, reverse: false, name: nil)
}

func testBitwiseOps() {
    let graph = MPSGraph()
    let a = graph.placeholder(shape: mpsgShape(2), dataType: .int32, name: "a")
    let b = graph.placeholder(shape: mpsgShape(2), dataType: .int32, name: "b")
    let da = MPSGraphTensorData(
        device: MPSGraphDevice.hostDevice(),
        data: [Int32(6), Int32(3)].withUnsafeBytes { Data($0) },
        shape: mpsgShape(2),
        dataType: .int32
    )
    let db = MPSGraphTensorData(
        device: MPSGraphDevice.hostDevice(),
        data: [Int32(3), Int32(1)].withUnsafeBytes { Data($0) },
        shape: mpsgShape(2),
        dataType: .int32
    )
    _ = graph.run(feeds: [a: da, b: db], targetTensors: [
        graph.bitwiseAND(a, b, name: nil),
        graph.bitwiseOR(a, b, name: nil),
        graph.bitwiseXOR(a, b, name: nil),
        graph.bitwiseNOT(a, name: nil),
        graph.bitwiseLeftShift(a, b, name: nil),
        graph.bitwiseRightShift(a, b, name: nil),
        graph.bitwisePopulationCount(a, name: nil),
        graph.HammingDistance(primary: a, secondary: b, resultDataType: .int32, name: nil)
    ], targetOperations: nil)
}
