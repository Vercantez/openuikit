import Foundation
import MetalPerformanceShadersGraph

func testArithmeticOps() {
    let graph = MPSGraph()
    let a = mpsgPlaceholder(graph, 2, name: "a")
    let b = mpsgPlaceholder(graph, 2, name: "b")
    let feeds = [
        a: mpsgFloatData([6, 9], shape: [2]),
        b: mpsgFloatData([2, 3], shape: [2])
    ]
    mpsgClose(mpsgRun(graph, feeds: feeds, graph.addition(a, b, name: nil)), [8, 12])
    mpsgClose(mpsgRun(graph, feeds: feeds, graph.subtraction(a, b, name: nil)), [4, 6])
    mpsgClose(mpsgRun(graph, feeds: feeds, graph.multiplication(a, b, name: nil)), [12, 27])
    mpsgClose(mpsgRun(graph, feeds: feeds, graph.division(a, b, name: nil)), [3, 3])
    mpsgClose(mpsgRun(graph, feeds: feeds, graph.divisionNoNaN(a, b, name: nil)), [3, 3])
    mpsgClose(mpsgRun(graph, feeds: feeds, graph.modulo(a, b, name: nil)), [0, 0])
    mpsgClose(mpsgRun(graph, feeds: feeds, graph.floorModulo(a, b, name: nil)), [0, 0])
    mpsgClose(mpsgRun(graph, feeds: feeds, graph.power(b, b, name: nil)), [4, 27])
}

func testMinMaxClamp() {
    let graph = MPSGraph()
    let a = mpsgPlaceholder(graph, 3, name: "a")
    let b = mpsgPlaceholder(graph, 3, name: "b")
    let lo = mpsgPlaceholder(graph, 3, name: "lo")
    let hi = mpsgPlaceholder(graph, 3, name: "hi")
    let feeds = [
        a: mpsgFloatData([-1, 0, 5], shape: [3]),
        b: mpsgFloatData([0, 0, 1], shape: [3]),
        lo: mpsgFloatData([0, 0, 0], shape: [3]),
        hi: mpsgFloatData([1, 1, 1], shape: [3])
    ]
    mpsgClose(mpsgRun(graph, feeds: feeds, graph.minimum(a, b, name: nil)), [-1, 0, 1])
    mpsgClose(mpsgRun(graph, feeds: feeds, graph.maximum(a, b, name: nil)), [0, 0, 5])
    mpsgClose(mpsgRun(graph, feeds: feeds, graph.minimumWithNaNPropagation(a, b, name: nil)), [-1, 0, 1])
    mpsgClose(mpsgRun(graph, feeds: feeds, graph.maximumWithNaNPropagation(a, b, name: nil)), [0, 0, 5])
    mpsgClose(mpsgRun(graph, feeds: feeds, graph.clamp(a, min: lo, max: hi, name: nil)), [0, 0, 1])
}

func testComparisons() {
    let graph = MPSGraph()
    let a = mpsgPlaceholder(graph, 3, name: "a")
    let b = mpsgPlaceholder(graph, 3, name: "b")
    let feeds = [
        a: mpsgFloatData([1, 2, 3], shape: [3]),
        b: mpsgFloatData([1, 0, 4], shape: [3])
    ]
    mpsgClose(mpsgRun(graph, feeds: feeds, graph.equal(a, b, name: nil)), [1, 0, 0])
    mpsgClose(mpsgRun(graph, feeds: feeds, graph.notEqual(a, b, name: nil)), [0, 1, 1])
    mpsgClose(mpsgRun(graph, feeds: feeds, graph.lessThan(a, b, name: nil)), [0, 0, 1])
    mpsgClose(mpsgRun(graph, feeds: feeds, graph.lessThanOrEqualTo(a, b, name: nil)), [1, 0, 1])
    mpsgClose(mpsgRun(graph, feeds: feeds, graph.greaterThan(a, b, name: nil)), [0, 1, 0])
    mpsgClose(mpsgRun(graph, feeds: feeds, graph.greaterThanOrEqualTo(a, b, name: nil)), [1, 1, 0])
}

func testLogicalOps() {
    let graph = MPSGraph()
    let a = mpsgPlaceholder(graph, 2, name: "a")
    let b = mpsgPlaceholder(graph, 2, name: "b")
    let feeds = [
        a: mpsgFloatData([1, 0], shape: [2]),
        b: mpsgFloatData([1, 1], shape: [2])
    ]
    mpsgClose(mpsgRun(graph, feeds: feeds, graph.logicalAND(a, b, name: nil)), [1, 0])
    mpsgClose(mpsgRun(graph, feeds: feeds, graph.logicalOR(a, b, name: nil)), [1, 1])
    mpsgClose(mpsgRun(graph, feeds: feeds, graph.logicalNAND(a, b, name: nil)), [0, 1])
    mpsgClose(mpsgRun(graph, feeds: feeds, graph.logicalNOR(a, b, name: nil)), [0, 0])
    mpsgClose(mpsgRun(graph, feeds: feeds, graph.logicalXOR(a, b, name: nil)), [0, 1])
    mpsgClose(mpsgRun(graph, feeds: feeds, graph.logicalXNOR(a, b, name: nil)), [1, 0])
    mpsgClose(mpsgRun(graph, feeds: feeds, graph.not(with: a, name: nil)), [0, 1])
    mpsgClose(mpsgRun(graph, feeds: feeds, graph.select(predicate: a, trueTensor: a, falseTensor: b, name: nil)), [1, 1])
}
