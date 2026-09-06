import Foundation
import MetalPerformanceShadersGraph

func testUnaryArithmetic() {
    let graph = MPSGraph()
    let x = mpsgPlaceholder(graph, 2, name: "x")
    let feeds = [x: mpsgFloatData([-4, 9], shape: [2])]
    mpsgClose(mpsgRun(graph, feeds: feeds, graph.absolute(with: x, name: nil)), [4, 9])
    mpsgClose(mpsgRun(graph, feeds: feeds, graph.negative(with: x, name: nil)), [4, -9])
    mpsgClose(mpsgRun(graph, feeds: feeds, graph.square(with: x, name: nil)), [16, 81])
    mpsgClose(mpsgRun(graph, feeds: [x: mpsgFloatData([4, 9], shape: [2])], graph.squareRoot(with: x, name: nil)), [2, 3])
    mpsgClose(mpsgRun(graph, feeds: [x: mpsgFloatData([2, 4], shape: [2])], graph.reciprocal(with: x, name: nil)), [0.5, 0.25])
    mpsgClose(mpsgRun(graph, feeds: [x: mpsgFloatData([4, 16], shape: [2])], graph.reciprocalSquareRoot(x, name: nil)), [0.5, 0.25])
    mpsgClose(mpsgRun(graph, feeds: [x: mpsgFloatData([4, 16], shape: [2])], graph.reverseSquareRoot(with: x, name: nil)), [0.5, 0.25])
    mpsgClose(mpsgRun(graph, feeds: [x: mpsgFloatData([2, 4], shape: [2])], graph.inverse(input: x, name: nil)), [0.5, 0.25])
    mpsgClose(mpsgRun(graph, feeds: [x: mpsgFloatData([1.2, -1.8], shape: [2])], graph.ceil(with: x, name: nil)), [2, -1])
    mpsgClose(mpsgRun(graph, feeds: [x: mpsgFloatData([1.8, -1.2], shape: [2])], graph.floor(with: x, name: nil)), [1, -2])
    mpsgClose(mpsgRun(graph, feeds: [x: mpsgFloatData([1.4, -1.4], shape: [2])], graph.round(with: x, name: nil)), [1, -1])
    mpsgClose(mpsgRun(graph, feeds: [x: mpsgFloatData([1.4, -1.4], shape: [2])], graph.rint(with: x, name: nil)), [1, -1])
    mpsgClose(mpsgRun(graph, feeds: [x: mpsgFloatData([1.8, -1.8], shape: [2])], graph.truncate(x, name: nil)), [1, -1])
}

func testExponentsAndLogs() {
    let graph = MPSGraph()
    let x = mpsgPlaceholder(graph, 1, name: "x")
    mpsgClose(mpsgRun(graph, feeds: [x: mpsgFloatData([0], shape: [1])], graph.exponent(with: x, name: nil)), [1], eps: 1e-5)
    mpsgClose(mpsgRun(graph, feeds: [x: mpsgFloatData([3], shape: [1])], graph.exponentBase2(with: x, name: nil)), [8], eps: 1e-5)
    mpsgClose(mpsgRun(graph, feeds: [x: mpsgFloatData([2], shape: [1])], graph.exponentBase10(with: x, name: nil)), [100], eps: 1e-3)
    mpsgClose(mpsgRun(graph, feeds: [x: mpsgFloatData([1], shape: [1])], graph.logarithm(with: x, name: nil)), [0], eps: 1e-5)
    mpsgClose(mpsgRun(graph, feeds: [x: mpsgFloatData([8], shape: [1])], graph.logarithmBase2(with: x, name: nil)), [3], eps: 1e-5)
    mpsgClose(mpsgRun(graph, feeds: [x: mpsgFloatData([100], shape: [1])], graph.logarithmBase10(with: x, name: nil)), [2], eps: 1e-5)
}

func testTrig() {
    let graph = MPSGraph()
    let x = mpsgPlaceholder(graph, 1, name: "x")
    mpsgClose(mpsgRun(graph, feeds: [x: mpsgFloatData([0], shape: [1])], graph.sin(with: x, name: nil)), [0])
    mpsgClose(mpsgRun(graph, feeds: [x: mpsgFloatData([0], shape: [1])], graph.cos(with: x, name: nil)), [1])
    mpsgClose(mpsgRun(graph, feeds: [x: mpsgFloatData([0], shape: [1])], graph.tan(with: x, name: nil)), [0])
    mpsgClose(mpsgRun(graph, feeds: [x: mpsgFloatData([0], shape: [1])], graph.sinh(with: x, name: nil)), [0])
    mpsgClose(mpsgRun(graph, feeds: [x: mpsgFloatData([0], shape: [1])], graph.cosh(with: x, name: nil)), [1])
    mpsgClose(mpsgRun(graph, feeds: [x: mpsgFloatData([0], shape: [1])], graph.tanh(with: x, name: nil)), [0])
    mpsgClose(mpsgRun(graph, feeds: [x: mpsgFloatData([0], shape: [1])], graph.asin(with: x, name: nil)), [0])
    mpsgClose(mpsgRun(graph, feeds: [x: mpsgFloatData([1], shape: [1])], graph.acos(with: x, name: nil)), [0])
    mpsgClose(mpsgRun(graph, feeds: [x: mpsgFloatData([0], shape: [1])], graph.atan(with: x, name: nil)), [0])
    mpsgClose(mpsgRun(graph, feeds: [x: mpsgFloatData([0], shape: [1])], graph.asinh(with: x, name: nil)), [0])
    mpsgClose(mpsgRun(graph, feeds: [x: mpsgFloatData([1], shape: [1])], graph.acosh(with: x, name: nil)), [0], eps: 1e-5)
    mpsgClose(mpsgRun(graph, feeds: [x: mpsgFloatData([0], shape: [1])], graph.atanh(with: x, name: nil)), [0])
    let y = mpsgPlaceholder(graph, 1, name: "y")
    mpsgClose(
        mpsgRun(graph, feeds: [x: mpsgFloatData([0], shape: [1]), y: mpsgFloatData([1], shape: [1])], graph.atan2(withPrimaryTensor: y, secondaryTensor: x, name: nil)),
        [Float.pi / 2],
        eps: 1e-5
    )
    mpsgClose(mpsgRun(graph, feeds: [x: mpsgFloatData([0], shape: [1])], graph.erf(with: x, name: nil)), [0])
}

func testActivations() {
    let graph = MPSGraph()
    let x = mpsgPlaceholder(graph, 2, name: "x")
    let feeds = [x: mpsgFloatData([-2, 3], shape: [2])]
    mpsgClose(mpsgRun(graph, feeds: feeds, graph.sign(with: x, name: nil)), [-1, 1])
    mpsgClose(mpsgRun(graph, feeds: feeds, graph.signbit(with: x, name: nil)), [1, 0])
    mpsgClose(mpsgRun(graph, feeds: feeds, graph.reLU(with: x, name: nil)), [0, 3])
    mpsgClose(mpsgRun(graph, feeds: feeds, graph.leakyReLU(with: x, alpha: 0.1, name: nil)), [-0.2, 3], eps: 1e-5)
    let alpha = graph.constant(0.1, dataType: .float32)
    mpsgClose(mpsgRun(graph, feeds: feeds, graph.leakyReLU(with: x, alphaTensor: alpha, name: nil)), [-0.2, 3], eps: 1e-5)
    let sig = mpsgRun(graph, feeds: [x: mpsgFloatData([0, 0], shape: [2])], graph.sigmoid(with: x, name: nil))
    mpsgClose(sig, [0.5, 0.5])
    _ = graph.reLUGradient(withIncomingGradient: x, sourceTensor: x, name: nil)
    _ = graph.sigmoidGradient(withIncomingGradient: x, sourceTensor: x, name: nil)
    _ = graph.leakyReLUGradient(withIncomingGradient: x, sourceTensor: x, alphaTensor: alpha, name: nil)
}

func testPredicatesAndCast() {
    let graph = MPSGraph()
    let x = mpsgPlaceholder(graph, 2, name: "x")
    mpsgClose(mpsgRun(graph, feeds: [x: mpsgFloatData([1, .infinity], shape: [2])], graph.isFinite(with: x, name: nil)), [1, 0])
    mpsgClose(mpsgRun(graph, feeds: [x: mpsgFloatData([1, .infinity], shape: [2])], graph.isInfinite(with: x, name: nil)), [0, 1])
    mpsgClose(mpsgRun(graph, feeds: [x: mpsgFloatData([1, .nan], shape: [2])], graph.isNaN(with: x, name: nil)), [0, 1])
    mpsgClose(mpsgRun(graph, feeds: [x: mpsgFloatData([3, 4], shape: [2])], graph.identity(with: x, name: nil)), [3, 4])
    mpsgClose(mpsgRun(graph, feeds: [x: mpsgFloatData([3, 4], shape: [2])], graph.cast(x, to: .float32, name: nil)), [3, 4])
    mpsgClose(mpsgRun(graph, feeds: [x: mpsgFloatData([3, 4], shape: [2])], graph.reinterpretCast(x, to: .float32, name: nil)), [3, 4])
    mpsgClose(mpsgRun(graph, feeds: [x: mpsgFloatData([3, 4], shape: [2])], graph.conjugate(tensor: x, name: nil)), [3, 4])
    mpsgClose(mpsgRun(graph, feeds: [x: mpsgFloatData([3, 4], shape: [2])], graph.absoluteSquare(tensor: x, name: nil)), [9, 16])
    let imag = graph.constant(0, shape: mpsgShape(2), dataType: .float32)
    _ = graph.complexTensor(realTensor: x, imaginaryTensor: imag, name: nil)
    _ = graph.realPartOfTensor(tensor: x, name: nil)
    _ = graph.imaginaryPartOfTensor(tensor: x, name: nil)
}
